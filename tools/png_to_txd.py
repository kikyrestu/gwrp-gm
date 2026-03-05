#!/usr/bin/env python3
"""
PNG to TXD Converter for GTA San Andreas / SA-MP 0.3.DL
Converts PNG images to RenderWare Texture Dictionary (.txd) format.

Usage:
    python png_to_txd.py <input.png> <output.txd> [texture_name]

The image will be resized to the nearest power-of-2 dimensions.
Output is a valid GTA:SA TXD with D3D9 texture native format.
"""

import struct
import sys
import os
from PIL import Image

# ============================================================================
# RenderWare Constants
# ============================================================================

# GTA San Andreas RenderWare version stamp
RW_VERSION = 0x1803FFFF

# RW Section types
SECTION_STRUCT = 1
SECTION_STRING = 2
SECTION_EXTENSION = 3
SECTION_TEXTURE_NATIVE = 0x15   # 21
SECTION_TEXTURE_DICTIONARY = 0x16  # 22

# D3D9 Platform ID
PLATFORM_D3D9 = 9

# Raster format flags
RASTER_8888 = 0x0500       # 32-bit RGBA
RASTER_888 = 0x0600        # 24-bit RGB
RASTER_HAS_ALPHA = 0x0500  # When using 8888
RASTER_DEFAULT = 0x0500

# ============================================================================
# Helper Functions
# ============================================================================

def next_power_of_2(v):
    """Find next power of 2 >= v."""
    if v <= 0:
        return 1
    v -= 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    return v + 1


def make_section(section_type, data, version=RW_VERSION):
    """Create a RenderWare section with header."""
    header = struct.pack('<III', section_type, len(data), version)
    return header + data


def image_to_bgra(img):
    """Convert PIL Image to BGRA byte array (D3D9 format)."""
    img = img.convert('RGBA')
    w, h = img.size
    pixels = bytearray(w * h * 4)

    raw = img.tobytes()  # RGBA order
    for i in range(w * h):
        offset = i * 4
        r, g, b, a = raw[offset], raw[offset+1], raw[offset+2], raw[offset+3]
        pixels[offset] = b      # Blue
        pixels[offset+1] = g    # Green
        pixels[offset+2] = r    # Red
        pixels[offset+3] = a    # Alpha
    return bytes(pixels)


def check_has_alpha(img):
    """Check if image has meaningful alpha channel."""
    if img.mode != 'RGBA':
        return False
    extrema = img.getextrema()
    if len(extrema) >= 4:
        return extrema[3][0] < 255  # Min alpha < 255 means has transparency
    return False


# ============================================================================
# TXD Builder
# ============================================================================

def build_texture_native(img, texture_name='texture'):
    """
    Build a RenderWare Texture Native (D3D9) section.
    
    Structure:
    - Platform ID (uint32) = 9
    - Filter + UV flags (uint32)
    - Texture name (32 bytes, null-padded)
    - Mask name (32 bytes, null-padded)
    - Raster format (uint32)
    - D3D format (uint32, 0 for uncompressed)
    - Width (uint16)
    - Height (uint16)
    - Depth (uint8, bits per pixel)
    - Mipmap count (uint8)
    - Raster type (uint8)
    - Flags (uint8: alpha|cube|autoMip|notCompressed)
    - For each mipmap: dataSize (uint32) + pixel data
    """
    w, h = img.size
    has_alpha = check_has_alpha(img)
    pixel_data = image_to_bgra(img)

    # Build native struct
    data = bytearray()

    # Platform ID
    data += struct.pack('<I', PLATFORM_D3D9)

    # Filter flags: LINEAR filter (0x1106)
    # Bits: filterMode(8) | uAddressing(4) | vAddressing(4) | pad(16)
    # Filter=2 (LINEAR), uAddr=1 (WRAP), vAddr=1 (WRAP)
    filter_flags = 0x00001102  # linear + wrap
    data += struct.pack('<I', filter_flags)

    # Texture name (32 bytes, null-terminated, null-padded)
    name_bytes = texture_name.encode('ascii')[:31]
    data += name_bytes.ljust(32, b'\x00')

    # Mask/alpha name (32 bytes, empty)
    data += b'\x00' * 32

    # Raster format
    raster_format = RASTER_8888
    data += struct.pack('<I', raster_format)

    # D3D format (0 = uncompressed, use raster format)
    data += struct.pack('<I', 0)

    # Width, Height
    data += struct.pack('<HH', w, h)

    # Depth (32 bits per pixel)
    data += struct.pack('<B', 32)

    # Mipmap count
    data += struct.pack('<B', 1)

    # Raster type (4 = normal)
    data += struct.pack('<B', 4)

    # Flags
    # bit 0: hasAlpha, bit 1: cubeTexture, bit 2: autoMipMaps, bit 3: isNotRwCompressed
    flags = 0x08  # isNotRwCompressed = 1
    if has_alpha:
        flags |= 0x01
    data += struct.pack('<B', flags)

    # Mipmap data: size + pixels
    data += struct.pack('<I', len(pixel_data))
    data += pixel_data

    # Wrap in sections
    native_struct = make_section(SECTION_STRUCT, bytes(data))
    native_extension = make_section(SECTION_EXTENSION, b'')

    texture_native = make_section(
        SECTION_TEXTURE_NATIVE,
        native_struct + native_extension
    )
    return texture_native


def build_txd(textures):
    """
    Build a complete TXD file.
    textures: list of (PIL.Image, texture_name) tuples
    """
    # Dictionary struct: texture count + device ID
    dict_struct_data = struct.pack('<HH', len(textures), 0)
    dict_struct = make_section(SECTION_STRUCT, dict_struct_data)

    # Build all texture natives
    texture_sections = b''
    for img, name in textures:
        texture_sections += build_texture_native(img, name)

    # Dictionary extension
    dict_extension = make_section(SECTION_EXTENSION, b'')

    # Complete TXD
    dict_data = dict_struct + texture_sections + dict_extension
    txd = make_section(SECTION_TEXTURE_DICTIONARY, dict_data)
    return txd


# ============================================================================
# Main
# ============================================================================

def convert_png_to_txd(png_path, txd_path, texture_name='texture'):
    """Convert a single PNG to TXD."""
    print(f"Loading: {png_path}")
    img = Image.open(png_path).convert('RGBA')
    orig_w, orig_h = img.size
    print(f"  Original size: {orig_w}x{orig_h}")

    # Resize to power of 2
    new_w = next_power_of_2(orig_w)
    new_h = next_power_of_2(orig_h)

    if new_w != orig_w or new_h != orig_h:
        print(f"  Resizing to: {new_w}x{new_h} (power of 2)")
        img = img.resize((new_w, new_h), Image.LANCZOS)
    else:
        print(f"  Size OK (already power of 2)")

    # Check alpha
    has_alpha = check_has_alpha(img)
    print(f"  Has alpha: {has_alpha}")

    # Build TXD
    txd_data = build_txd([(img, texture_name)])

    # Write
    with open(txd_path, 'wb') as f:
        f.write(txd_data)

    file_size = os.path.getsize(txd_path)
    print(f"  Output: {txd_path} ({file_size:,} bytes)")
    print(f"  Texture name: '{texture_name}'")
    print("  Done!")
    return True


def convert_multiple(inputs, txd_path):
    """
    Convert multiple PNGs into a single TXD.
    inputs: list of (png_path, texture_name) tuples
    """
    textures = []
    for png_path, tex_name in inputs:
        print(f"Loading: {png_path} -> '{tex_name}'")
        img = Image.open(png_path).convert('RGBA')
        w, h = img.size

        new_w = next_power_of_2(w)
        new_h = next_power_of_2(h)
        if new_w != w or new_h != h:
            print(f"  Resizing {w}x{h} -> {new_w}x{new_h}")
            img = img.resize((new_w, new_h), Image.LANCZOS)

        textures.append((img, tex_name))

    txd_data = build_txd(textures)
    with open(txd_path, 'wb') as f:
        f.write(txd_data)

    print(f"\nCreated {txd_path} with {len(textures)} texture(s)")
    return True


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python png_to_txd.py <input.png> <output.txd> [texture_name]")
        print("       python png_to_txd.py --multi <output.txd> <img1.png:name1> <img2.png:name2> ...")
        sys.exit(1)

    if sys.argv[1] == '--multi':
        txd_out = sys.argv[2]
        inputs = []
        for arg in sys.argv[3:]:
            parts = arg.split(':', 1)
            png = parts[0]
            name = parts[1] if len(parts) > 1 else os.path.splitext(os.path.basename(png))[0]
            inputs.append((png, name))
        convert_multiple(inputs, txd_out)
    else:
        png_in = sys.argv[1]
        txd_out = sys.argv[2]
        tex_name = sys.argv[3] if len(sys.argv) > 3 else 'texture'
        convert_png_to_txd(png_in, txd_out, tex_name)
