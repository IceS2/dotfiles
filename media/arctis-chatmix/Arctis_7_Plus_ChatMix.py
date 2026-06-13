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
import traceback
import re
import time
import usb.core
import usb.util


class Arctis7PlusChatMix:
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
                self.log.error(f"USB enumeration error: {e}")
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

        self.VAC = self._init_VAC()


    def _init_log(self):
        log = logging.getLogger(__name__)
        log.setLevel(logging.DEBUG)
        stdout_handler = logging.StreamHandler()
        stdout_handler.setLevel(logging.DEBUG)
        stdout_handler.setFormatter(logging.Formatter('%(levelname)8s | %(message)s'))
        log.addHandler(stdout_handler)    
        return (log)

    def _init_VAC(self):
        """Get name of default sink, establish virtual sink
        and pipe its output to the default sink
        """

        # get the default sink id from pactl
        self.system_default_sink = os.popen("pactl get-default-sink").read().strip()
        self.log.info(f"default sink identified as {self.system_default_sink}")

        # attempt to identify an Arctis sink via pactl
        try:
            pactl_short_sinks = os.popen("pactl list short sinks").readlines()
            # grab any elements from list of pactl sinks that are Arctis 7
            arctis = re.compile('.*[aA]rctis.*7')
            arctis_sink = list(filter(arctis.match, pactl_short_sinks))[0] 

            # split the arctis line on tabs (which form table given by 'pactl short sinks')
            tabs_pattern = re.compile(r'\t')
            tabs_re = re.split(tabs_pattern, arctis_sink)

            # skip first element of tabs_re (sink's ID which is not persistent)
            arctis_device = tabs_re[1]
            self.log.info(f"Arctis sink identified as {arctis_device}")
            default_sink = arctis_device

        except Exception as e:
            self.log.error("""Something wrong with Arctis definition 
            in pactl list short sinks regex matching.
            Likely no match found for device, check traceback.
            """, exc_info=True)
            self.die_gracefully(trigger="No Arctis device match")

        # Destroy virtual sinks if they already existed incase of previous failure:
        try:
            destroy_a7p_game = os.system("pw-cli destroy Arctis_Game 2>/dev/null")
            destroy_a7p_chat = os.system("pw-cli destroy Arctis_Chat 2>/dev/null")
            if destroy_a7p_game == 0 or destroy_a7p_chat == 0:
                raise Exception
        except Exception as e:
            self.log.info("""Attempted to destroy old VAC sinks at init but none existed""")

        # Instantiate our virtual sinks - Arctis_Chat and Arctis_Game
        try:
            self.log.info("Creating VACS...")
            os.system("""pw-cli create-node adapter '{ 
                factory.name=support.null-audio-sink 
                node.name=Arctis_Game 
                node.description="Arctis 7+ Game" 
                media.class=Audio/Sink 
                monitor.channel-volumes=true 
                object.linger=true 
                audio.position=[FL FR]
                }' 1>/dev/null
            """)

            os.system("""pw-cli create-node adapter '{ 
                factory.name=support.null-audio-sink 
                node.name=Arctis_Chat 
                node.description="Arctis 7+ Chat" 
                media.class=Audio/Sink 
                monitor.channel-volumes=true 
                object.linger=true 
                audio.position=[FL FR]
                }' 1>/dev/null
            """)
        except Exception as E:
            self.log.error("""Failure to create node adapter - 
            Arctis_Chat virtual device could not be created""", exc_info=True)
            self.die_gracefully(sink_creation_fail=True, trigger="VAC node adapter")

        #route the virtual sink's L&R channels to the default system output's LR
        try:
            self.log.info("Assigning VAC sink monitors output to default device...")

            os.system(f'pw-link "Arctis_Game:monitor_FL" '
            f'"{default_sink}:playback_FL" 1>/dev/null')

            os.system(f'pw-link "Arctis_Game:monitor_FR" '
            f'"{default_sink}:playback_FR" 1>/dev/null')

            os.system(f'pw-link "Arctis_Chat:monitor_FL" '
            f'"{default_sink}:playback_FL" 1>/dev/null')

            os.system(f'pw-link "Arctis_Chat:monitor_FR" '
            f'"{default_sink}:playback_FR" 1>/dev/null')

        except Exception as e:
            self.log.error("""Couldn't create the links to 
            pipe LR from VAC to default device""", exc_info=True)
            self.die_gracefully(sink_fail=True, trigger="LR links")
        
        # Default-sink ownership belongs to arctis-auto-switch.sh, which routes
        # to Arctis_Game on a power-on edge and to the soundbar when the
        # headset is off. The daemon used to set Arctis_Game unconditionally
        # during init, which (a) stole audio away from the soundbar when its
        # delayed startup landed while the headset was off, and (b) defeated
        # any manual selection. Leave the default alone.

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

    def die_gracefully(self, sink_creation_fail=False, trigger=None):
        """Kill the process and remove the VACs
        on fatal exceptions or SIGTERM / SIGINT
        """
        
        self.log.info('Cleanup on shutdown')
        # No default-sink restore: we never set it in the first place (see
        # create_virtual_sinks). arctis-auto-switch.sh reconciles the default
        # within one tick after the Arctis_Game sink disappears.

        # Reattach the kernel HID driver we detached. Otherwise the interface
        # stays driverless after this daemon stops and headsetcontrol / hidraw
        # (which the audio auto-switch depends on) go blind until the dongle
        # is physically replugged.
        try:
            ifnum = getattr(self, "interface_num", None)
            if ifnum is not None and not self.dev.is_kernel_driver_active(ifnum):
                self.dev.attach_kernel_driver(ifnum)
                self.log.info(f"Reattached kernel driver to interface {ifnum}")
        except Exception as e:
            self.log.info(f"Could not reattach kernel driver: {e}")

        # cleanup virtual sinks if they exist
        if  sink_creation_fail == False:
            self.log.info("Destroying virtual sinks...")
            os.system("pw-cli destroy Arctis_Game 1>/dev/null")
            os.system("pw-cli destroy Arctis_Chat 1>/dev/null")

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
