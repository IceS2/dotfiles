#!/usr/bin/env python3
"""
dank16.py — Generate 16 ANSI terminal colors from a hex seed color.

The seed hue is placed at the ANSI blue position (index 4/12); all other
hues are rotated offsets from that anchor.  Colors are computed in CIELAB
LCH so the rotation is perceptually uniform.

Pure Python stdlib — no dependencies.

Usage:  python3 dank16.py '#5740a2'
Output: {"ansi": ["#rrggbb", ...]}  (16 values, dark-background terminal)
"""

import math
import json
import sys

# ── sRGB ↔ linear light ──────────────────────────────────────────────────────

def _to_linear(c):
    """sRGB channel [0, 1] → linear light [0, 1]."""
    c = max(0.0, min(1.0, c))
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def _to_srgb(c):
    """Linear light [0, 1] → sRGB channel [0, 1]."""
    c = max(0.0, min(1.0, c))
    if c <= 0.0031308:
        return c * 12.92
    return 1.055 * (c ** (1.0 / 2.4)) - 0.055


# ── sRGB → XYZ (D65) → CIELAB ───────────────────────────────────────────────

# D65 white point
_WN = (0.95047, 1.00000, 1.08883)


def _rgb_to_xyz(r, g, b):
    """sRGB [0, 1] → CIE XYZ (D65 illuminant)."""
    r, g, b = _to_linear(r), _to_linear(g), _to_linear(b)
    X = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    Y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    Z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    return X, Y, Z


def _f(t):
    delta = 6.0 / 29.0
    if t > delta ** 3:
        return t ** (1.0 / 3.0)
    return t / (3 * delta * delta) + 4.0 / 29.0


def _xyz_to_lab(X, Y, Z):
    fx = _f(X / _WN[0])
    fy = _f(Y / _WN[1])
    fz = _f(Z / _WN[2])
    L = 116 * fy - 16
    a = 500 * (fx - fy)
    b = 200 * (fy - fz)
    return L, a, b


# ── CIELAB → XYZ → sRGB ──────────────────────────────────────────────────────

def _finv(t):
    delta = 6.0 / 29.0
    if t > delta:
        return t ** 3
    return 3 * delta * delta * (t - 4.0 / 29.0)


def _lab_to_xyz(L, a, b):
    fy = (L + 16) / 116
    fx = a / 500 + fy
    fz = fy - b / 200
    return _WN[0] * _finv(fx), _WN[1] * _finv(fy), _WN[2] * _finv(fz)


def _xyz_to_rgb255(X, Y, Z):
    """CIE XYZ (D65) → sRGB [0, 255] (gamut-clamped)."""
    r_lin =  3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z
    g_lin = -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z
    b_lin =  0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z
    r = max(0, min(255, round(_to_srgb(r_lin) * 255)))
    g = max(0, min(255, round(_to_srgb(g_lin) * 255)))
    b = max(0, min(255, round(_to_srgb(b_lin) * 255)))
    return r, g, b


# ── CIELAB ↔ LCH (cylindrical) ───────────────────────────────────────────────

def _lab_to_lch(L, a, b):
    C = math.sqrt(a * a + b * b)
    H = math.degrees(math.atan2(b, a)) % 360
    return L, C, H


def _lch_to_lab(L, C, H):
    h_rad = math.radians(H)
    return L, C * math.cos(h_rad), C * math.sin(h_rad)


# ── Hex ↔ LCH convenience ────────────────────────────────────────────────────

def _hex_to_lch(hex_str):
    h = hex_str.lstrip('#')
    r, g, b = int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255
    return _lab_to_lch(*_xyz_to_lab(*_rgb_to_xyz(r, g, b)))


def _lch_to_hex(L, C, H):
    r, g, b = _xyz_to_rgb255(*_lab_to_xyz(*_lch_to_lab(L, C, H)))
    return '#{:02X}{:02X}{:02X}'.format(r, g, b)


# ── ANSI chromatic hue targets (LCH approximate angles) ──────────────────────

# Index → semantic hue angle.  Blue (4) is the anchor — seed maps here.
_ANSI_HUES = {
    1: 30.0,    # red
    2: 140.0,   # green
    3: 85.0,    # yellow
    4: 265.0,   # blue  ← seed anchor
    5: 320.0,   # magenta
    6: 195.0,   # cyan
}


# ── Main generator ────────────────────────────────────────────────────────────

def generate(seed_hex):
    """Return list of 16 ANSI hex color strings derived from seed_hex."""
    _, C_seed, H_seed = _hex_to_lch(seed_hex)

    # Rotate all hues so seed lands at blue (265°)
    offset = (265.0 - H_seed) % 360.0

    # Clamp chroma: vibrant but not neon; ensure minimum punch
    chroma = max(35.0, min(C_seed, 55.0))

    palette = [''] * 16

    # Achromatics: slightly tinted with seed hue for a warm/cool character
    palette[0]  = _lch_to_hex(20.0, 4.0, H_seed)   # black
    palette[8]  = _lch_to_hex(32.0, 5.0, H_seed)   # bright black
    palette[7]  = _lch_to_hex(78.0, 5.0, H_seed)   # white
    palette[15] = _lch_to_hex(92.0, 4.0, H_seed)   # bright white

    # Chromatic normals (L* = 62) and brights (L* = 72)
    for idx, base_hue in _ANSI_HUES.items():
        hue = (base_hue + offset) % 360.0
        palette[idx]     = _lch_to_hex(62.0, chroma, hue)
        palette[idx + 8] = _lch_to_hex(72.0, chroma, hue)

    return palette


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == '__main__':
    seed = sys.argv[1] if len(sys.argv) > 1 else '#5740a2'
    print(json.dumps({'ansi': generate(seed)}))
