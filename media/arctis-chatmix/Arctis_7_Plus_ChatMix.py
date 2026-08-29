"""   Copyright (C) 2022  birdybirdonline & awth13 - see LICENSE.md
    @ https://github.com/birdybirdonline/Linux-Arctis-7-Plus-ChatMix
    
    Contact via Github in the first instance
    https://github.com/birdybirdonline
    https://github.com/awth13
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
    """

import os
import sys
import signal
import logging
import time
import subprocess
import usb.core
import usb.util


class Arctis7PlusChatMix:

    # The physical headset sink both virtual sinks loop into.
    HEADSET = 'alsa_output.usb-SteelSeries_Arctis_7_-00.analog-stereo'
    # (sink_name, node.description) for the two ChatMix virtual sinks.
    SINKS = (('Arctis_Game', 'Arctis 7+ Game'),
             ('Arctis_Chat', 'Arctis 7+ Chat'))

    def __init__(self):

        # set to receive signal from systemd for termination
        signal.signal(signal.SIGTERM, self.__handle_sigterm)

        self.log = self._init_log()
        self.log.info("Initializing ac7pcm...")

        # Wait for the dongle. usb.core.find() returns None (no exception) when
        # absent; the original code then crashed on self.dev[0]. The service is
        # WantedBy=default.target with Restart=always and no device-unit gate,
        # so it must tolerate the dongle being unplugged at start and simply
        # wait for it to appear.
        self.dev = None
        while self.dev is None:
            try:
                self.dev = usb.core.find(idVendor=0x1038, idProduct=0x220e)
            except Exception as e:
                self.log.error("USB enumeration error: %s", e)
                self.dev = None
            if self.dev is None:
                self.log.info("Arctis 7+ dongle not found; waiting 5s...")
                time.sleep(5)
        self.log.info("Arctis 7+ dongle found")

        # The ChatMix dial is delivered on the HID interface whose
        # bInterfaceNumber == 5 (its interrupt-IN endpoint). Upstream hardcoded
        # dev[0].interfaces()[7] — a pyusb *list index* that shifts when the
        # audio function exposes extra altsettings. On some Arctis 7+ revisions
        # index 7 lands on the wrong (silent) HID interface, so dev.read() times
        # out forever and the dial does nothing. Select by the stable interface
        # NUMBER instead (re-probe with media/arctis-chatmix/probe.py if a
        # future revision differs).
        DIAL_INTERFACE_NUMBER = 5
        try:
            self.interface = None
            self.endpoint = None
            for intf in self.dev[0].interfaces():
                if intf.bInterfaceClass != 3:                 # HID only
                    continue
                if intf.bInterfaceNumber != DIAL_INTERFACE_NUMBER:
                    continue
                for ep in intf.endpoints():
                    is_in = usb.util.endpoint_direction(
                        ep.bEndpointAddress) == usb.util.ENDPOINT_IN
                    is_intr = usb.util.endpoint_type(
                        ep.bmAttributes) == usb.util.ENDPOINT_TYPE_INTR
                    if is_in and is_intr:
                        self.interface = intf
                        self.endpoint = ep
                        break
                if self.interface is not None:
                    break

            if self.interface is None:
                raise RuntimeError(
                    f"no HID interrupt-IN endpoint on interface "
                    f"{DIAL_INTERFACE_NUMBER}")

            self.interface_num = self.interface.bInterfaceNumber
            self.addr = self.endpoint.bEndpointAddress
            self.log.info(
                f"ChatMix dial on interface {self.interface_num}, "
                f"endpoint 0x{self.addr:02x}")

        except Exception as e:
            self.log.error(
                f"Failure to identify the ChatMix HID interface/endpoint: "
                f"{e}. Shutting down...")
            self.die_gracefully(trigger="identification of USB endpoint")

        # detach if the device is active
        if self.dev.is_kernel_driver_active(self.interface_num):
            self.dev.detach_kernel_driver(self.interface_num)

        # Create the Arctis_Game / Arctis_Chat sinks now that the headset is
        # present. This daemon owns their lifecycle (see _ensure_sinks): the
        # previous declarative pipewire.conf.d loopback instantiated ONCE at
        # PipeWire startup and never returned after the headset auto-slept and
        # tore the loopback down — leaving ChatMix dead until a full PipeWire
        # restart. __init__ re-runs on every dongle reconnect (systemd restarts
        # the unit when start_modulator_signal exits on USB disconnect), so
        # rebuilding the sinks here restores them automatically on every
        # power-cycle.
        self._ensure_sinks()


    def _pactl(self, *args):
        """Run pactl and return stdout (empty string on failure)."""
        try:
            return subprocess.run(
                ['pactl', *args], capture_output=True, text=True, timeout=10
            ).stdout
        except Exception as e:
            self.log.error("pactl %s failed: %s", " ".join(args), e)
            return ''

    def _wait_for_headset_sink(self, timeout=10):
        """The USB HID dial can enumerate a beat before the ALSA sink node is
        registered. Wait (briefly) for the headset sink so the loopback binds to
        a real target instead of failing / falling back to the default sink."""
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self.HEADSET in self._pactl('list', 'sinks', 'short'):
                return True
            time.sleep(0.5)
        self.log.error(
            f"Headset sink {self.HEADSET} did not appear within {timeout}s; "
            "creating sinks anyway (loopback will reconnect when it does).")
        return False

    def _unload_existing(self):
        """Unload any Arctis_Game/Arctis_Chat null-sink/loopback modules left
        from a previous run, so a reconnect rebuilds a clean topology instead of
        stacking duplicates or keeping a half-broken loopback."""
        for line in self._pactl('list', 'modules', 'short').splitlines():
            if 'Arctis_Game' in line or 'Arctis_Chat' in line:
                mod_id = line.split('\t', 1)[0].strip()
                if mod_id:
                    self._pactl('unload-module', mod_id)

    def _ensure_sinks(self):
        """(Re)create the two ChatMix virtual sinks and route them to the
        headset. Each sink is a null-sink (the app-facing Audio/Sink) whose
        monitor is carried to the headset by a module-loopback. The loopback
        reconnects to the target by name — unlike the old manual pw-link, which
        raced the device at boot and silently dropped the routing."""
        self._unload_existing()
        self._wait_for_headset_sink()
        for name, desc in self.SINKS:
            self._pactl(
                'load-module', 'module-null-sink',
                f'sink_name={name}',
                f'sink_properties=node.description="{desc}"')
            self._pactl(
                'load-module', 'module-loopback',
                f'source={name}.monitor',
                f'sink={self.HEADSET}',
                'latency_msec=50',
                'source_dont_move=true',
                'sink_dont_move=true')
            self.log.info("ChatMix sink ready: %s -> %s", name, self.HEADSET)

    def _init_log(self):
        log = logging.getLogger(__name__)
        log.setLevel(logging.DEBUG)
        stdout_handler = logging.StreamHandler()
        stdout_handler.setLevel(logging.DEBUG)
        stdout_handler.setFormatter(logging.Formatter('%(levelname)8s | %(message)s'))
        log.addHandler(stdout_handler)
        return (log)

    def start_modulator_signal(self):
        """Listen to the USB device for modulator knob's signal 
        and adjust volume accordingly
        """
        
        self.log.info("Reading modulator USB input started")
        self.log.info("-"*45)
        self.log.info("Arctis 7+ ChatMix Enabled!")
        self.log.info("-"*45)
        while True:
            try:
                # read the input of the USB signal. Signal is sent in 64-bit interrupt packets.
                # read_input[1] returns value to use for default device volume
                # read_input[2] returns the value to use for virtual device volume
                read_input = self.dev.read(self.addr, 64)
                # Dial reports are [0x45, game_vol, chat_vol, ...]. Other
                # reports arrive on this endpoint too (status/keepalive, e.g.
                # starting 0xb9) — acting on those would slam the volumes to
                # garbage, so ignore anything without the 0x45 report id.
                if len(read_input) < 3 or read_input[0] != 0x45:
                    continue
                game_vol = min(100, max(0, read_input[1]))
                chat_vol = min(100, max(0, read_input[2]))

                # os.system calls to issue the commands directly to pactl
                os.system(f'pactl set-sink-volume Arctis_Game {game_vol}%')
                os.system(f'pactl set-sink-volume Arctis_Chat {chat_vol}%')
            except usb.core.USBTimeoutError:
                pass
            except usb.core.USBError:
                self.log.fatal("USB input/output error - likely disconnect")
                break

    def __handle_sigterm(self, sig, frame):
        self.die_gracefully()

    def die_gracefully(self, trigger=None):
        """Kill the process on fatal exceptions or SIGTERM / SIGINT.

        The virtual sinks are intentionally NOT torn down here — they persist so
        apps stay pointed at Arctis_Game/Arctis_Chat across a dial-reader restart
        (the null-sink survives even a headset disconnect). _ensure_sinks unloads
        and rebuilds them cleanly on the next start, so nothing stacks up.
        """

        self.log.info('Cleanup on shutdown')

        # Reattach the kernel HID driver we detached. Otherwise the interface
        # stays driverless after this daemon stops and headsetcontrol / hidraw
        # (which the audio auto-switch depends on) go blind until the dongle
        # is physically replugged.
        try:
            ifnum = getattr(self, "interface_num", None)
            if ifnum is not None and not self.dev.is_kernel_driver_active(ifnum):
                self.dev.attach_kernel_driver(ifnum)
                self.log.info("Reattached kernel driver to interface %s", ifnum)
        except Exception as e:
            self.log.info("Could not reattach kernel driver: %s", e)

        if trigger is not None:
            self.log.info("-"*45)
            self.log.fatal("Failure reason: " + trigger)
            self.log.info("-"*45)
            sys.exit(1)
        else:
            self.log.info("-"*45)
            self.log.info("Artcis 7+ ChatMix shut down gracefully... Bye Bye!")
            self.log.info("-"*45)
            sys.exit(0)

# init
if __name__ == '__main__':
    a7pcm_service = Arctis7PlusChatMix()
    a7pcm_service.start_modulator_signal()
