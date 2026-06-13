#!/usr/bin/env python3
# Diagnostic: map the Arctis 7+ (1038:220e) USB interfaces exactly as pyusb
# sees them, show what the daemon's hardcoded interfaces()[7] resolves to on
# THIS unit, then read every HID interrupt-IN endpoint for ~15s and print any
# bytes received. Turn the ChatMix dial during the read window.
#
# Run as your normal user (NOT sudo) — same as the systemd --user daemon:
#   python3 /tmp/arctis_probe.py

import sys
import time
import usb.core
import usb.util

dev = usb.core.find(idVendor=0x1038, idProduct=0x220e)
if dev is None:
    print("FATAL: device 1038:220e not found")
    sys.exit(1)

cfg = dev[0]

print("=== Interface map (pyusb index order) ===")
intfs = cfg.interfaces()
for idx, intf in enumerate(intfs):
    eps = []
    for ep in intf.endpoints():
        d = "IN" if usb.util.endpoint_direction(ep.bEndpointAddress) == usb.util.ENDPOINT_IN else "OUT"
        t = {0: "ctrl", 1: "iso", 2: "bulk", 3: "intr"}[usb.util.endpoint_type(ep.bmAttributes)]
        eps.append(f"0x{ep.bEndpointAddress:02x}/{d}/{t}/mp{ep.wMaxPacketSize}")
    print(f"  index {idx}: bInterfaceNumber={intf.bInterfaceNumber} "
          f"class={intf.bInterfaceClass} alt={intf.bAlternateSetting} eps={eps}")

print("\n=== What the daemon's interfaces()[7] picks on THIS unit ===")
try:
    pick = intfs[7]
    pep = pick.endpoints()[0]
    print(f"  index 7 -> bInterfaceNumber={pick.bInterfaceNumber} "
          f"endpoint=0x{pep.bEndpointAddress:02x}")
except Exception as e:
    print(f"  index 7 unavailable: {e}")

# Collect every HID (class 3) interrupt-IN endpoint
targets = []
for intf in intfs:
    if intf.bInterfaceClass != 3:
        continue
    for ep in intf.endpoints():
        is_in = usb.util.endpoint_direction(ep.bEndpointAddress) == usb.util.ENDPOINT_IN
        is_intr = usb.util.endpoint_type(ep.bmAttributes) == usb.util.ENDPOINT_TYPE_INTR
        if is_in and is_intr:
            targets.append((intf.bInterfaceNumber, ep.bEndpointAddress,
                            ep.wMaxPacketSize or 64))

print(f"\n=== HID interrupt-IN endpoints to probe: "
      f"{[(i, hex(a)) for i, a, _ in targets]} ===")

detached = []
for ifnum, _, _ in targets:
    try:
        if dev.is_kernel_driver_active(ifnum):
            dev.detach_kernel_driver(ifnum)
            detached.append(ifnum)
    except Exception as e:
        print(f"  (note: could not query/detach IF{ifnum}: {e})")

print("\n>>> TURN THE DIAL NOW (fully Game -> fully Chat -> center). "
      "Reading 15s...\n")

seen = {}
deadline = time.time() + 15
try:
    while time.time() < deadline:
        for ifnum, addr, mp in targets:
            try:
                data = dev.read(addr, mp, timeout=120)
                b = list(bytes(data))
                key = ifnum
                if seen.get(key) != b:
                    seen[key] = b
                    ts = f"{deadline - time.time():5.1f}s"
                    hexs = " ".join(f"{x:02x}" for x in b[:12])
                    print(f"[{ts}] IF{ifnum} ep0x{addr:02x} len={len(b)}: {hexs}")
            except usb.core.USBError:
                pass  # timeout / no data on this endpoint this round
finally:
    for ifnum in detached:
        try:
            dev.attach_kernel_driver(ifnum)
        except Exception:
            pass

print("\n--- done. Endpoints that produced data:",
      sorted(seen.keys()) or "NONE", "---")
