#!/usr/bin/env python3
"""
catppuccin26.py — Generate a 26-color Catppuccin-compatible palette from a seed.

Takes a hex seed color, computes the hue offset from Catppuccin Mocha's
`mauve` (#cba6f7), and rotates every accent color by that offset in CIELAB
LCH space.  Surface/text colors keep their Catppuccin lightness but get
the seed's hue tint (replacing Mocha's cool purple).

Same perceptually-uniform LCH rotation as dank16.py, extended to 26 colors.

Usage:  python3 catppuccin26.py '#7ea7c1'
Output: JSON {"rosewater": "#RRGGBB", ...}  (26 Catppuccin names)
"""

import math
import json
import sys

# ── sRGB ↔ linear light ──────────────────────────────────────────────────────

def _to_linear(c):
    c = max(0.0, min(1.0, c))
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def _to_srgb(c):
    c = max(0.0, min(1.0, c))
    return c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1.0 / 2.4)) - 0.055

# ── sRGB ↔ XYZ (D65) ↔ CIELAB ↔ LCH ────────────────────────────────────────

_WN = (0.95047, 1.00000, 1.08883)

def _rgb_to_xyz(r, g, b):
    r, g, b = _to_linear(r), _to_linear(g), _to_linear(b)
    return (0.4124564*r + 0.3575761*g + 0.1804375*b,
            0.2126729*r + 0.7151522*g + 0.0721750*b,
            0.0193339*r + 0.1191920*g + 0.9503041*b)

def _f(t):
    delta = 6.0 / 29.0
    return t ** (1.0/3.0) if t > delta**3 else t / (3*delta*delta) + 4.0/29.0

def _xyz_to_lab(X, Y, Z):
    fx, fy, fz = _f(X/_WN[0]), _f(Y/_WN[1]), _f(Z/_WN[2])
    return 116*fy - 16, 500*(fx - fy), 200*(fy - fz)

def _finv(t):
    delta = 6.0 / 29.0
    return t**3 if t > delta else 3*delta*delta*(t - 4.0/29.0)

def _lab_to_xyz(L, a, b):
    fy = (L + 16) / 116
    return _WN[0]*_finv(a/500 + fy), _WN[1]*_finv(fy), _WN[2]*_finv(fy - b/200)

def _xyz_to_rgb255(X, Y, Z):
    r = _to_srgb( 3.2404542*X - 1.5371385*Y - 0.4985314*Z)
    g = _to_srgb(-0.9692660*X + 1.8760108*Y + 0.0415560*Z)
    b = _to_srgb( 0.0556434*X - 0.2040259*Y + 1.0572252*Z)
    return max(0, min(255, round(r*255))), max(0, min(255, round(g*255))), max(0, min(255, round(b*255)))

def _lab_to_lch(L, a, b):
    return L, math.sqrt(a*a + b*b), math.degrees(math.atan2(b, a)) % 360

def _lch_to_lab(L, C, H):
    h = math.radians(H)
    return L, C*math.cos(h), C*math.sin(h)

def _hex_to_lch(s):
    h = s.lstrip('#')
    return _lab_to_lch(*_xyz_to_lab(*_rgb_to_xyz(
        int(h[0:2],16)/255, int(h[2:4],16)/255, int(h[4:6],16)/255)))

def _lch_to_hex(L, C, H):
    r, g, b = _xyz_to_rgb255(*_lab_to_xyz(*_lch_to_lab(L, C, H)))
    return '#{:02X}{:02X}{:02X}'.format(r, g, b)

# ── Catppuccin Mocha reference ───────────────────────────────────────────────

# 14 chromatic accents — hue-rotated with seed
ACCENTS = {
    "rosewater": "#f5e0dc",
    "flamingo":  "#f2cdcd",
    "pink":      "#f5c2e7",
    "mauve":     "#cba6f7",   # anchor — seed maps here
    "red":       "#f38ba8",
    "maroon":    "#eba0ac",
    "peach":     "#fab387",
    "yellow":    "#f9e2af",
    "green":     "#a6e3a1",
    "teal":      "#94e2d5",
    "sky":       "#89dceb",
    "sapphire":  "#74c7ec",
    "blue":      "#89b4fa",
    "lavender":  "#b4befe",
}

# 12 neutral/surface colors — tinted with seed hue, low chroma
NEUTRALS = {
    "text":     "#cdd6f4",
    "subtext1": "#bac2de",
    "subtext0": "#a6adc8",
    "overlay2": "#9399b2",
    "overlay1": "#7f849c",
    "overlay0": "#6c7086",
    "surface2": "#585b70",
    "surface1": "#45475a",
    "surface0": "#313244",
    "base":     "#1e1e2e",
    "mantle":   "#181825",
    "crust":    "#11111b",
}

ANCHOR_HEX = ACCENTS["mauve"]

# ── Generator ────────────────────────────────────────────────────────────────

def generate(seed_hex):
    _, C_seed, H_seed = _hex_to_lch(seed_hex)
    _, C_anchor, H_anchor = _hex_to_lch(ANCHOR_HEX)

    # Hue rotation: shift so seed lands at mauve's position
    hue_offset = (H_seed - H_anchor) % 360

    result = {}

    # Accents: rotate hue, keep reference lightness + chroma.
    # Each Catppuccin color's chroma was designed for its role (rosewater
    # is soft C≈8, red is punchy C≈43) — preserving it keeps readability
    # and visual variety.  Same approach as dank16.py's fixed chroma floor.
    for name, ref_hex in ACCENTS.items():
        L, C, H = _hex_to_lch(ref_hex)
        new_H = (H + hue_offset) % 360
        result[name] = _lch_to_hex(L, C, new_H)

    # Neutrals: rotate hue by same offset as accents, keep L and C.
    # Catppuccin Mocha neutrals sit at ~285° with C≈7-16 — rotating
    # (not replacing) preserves the identity case and keeps the subtle
    # tonal shift proportional to the seed distance.
    for name, ref_hex in NEUTRALS.items():
        L, C, H = _hex_to_lch(ref_hex)
        new_H = (H + hue_offset) % 360
        result[name] = _lch_to_hex(L, C, new_H)

    return result


if __name__ == '__main__':
    seed = sys.argv[1] if len(sys.argv) > 1 else '#cba6f7'
    print(json.dumps(generate(seed)))
