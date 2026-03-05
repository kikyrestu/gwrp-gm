"""Build phone_ui.txd with proper sizes for SA-MP."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
from png_to_txd import build_txd, check_has_alpha

ROOT = os.path.join(os.path.dirname(__file__), '..')

# Phone frame: 128x256 (slim ratio, transparent PNG)
frame = Image.open(os.path.join(ROOT, 'phone-frame.png')).convert('RGBA')
frame = frame.resize((128, 256), Image.LANCZOS)
print(f'Frame: {frame.size}, alpha: {check_has_alpha(frame)}')

# Wallpaper/logo: 128x128
wp = Image.open(os.path.join(ROOT, 'wallpaper.png')).convert('RGBA')
wp = wp.resize((128, 128), Image.LANCZOS)
print(f'Wallpaper: {wp.size}, alpha: {check_has_alpha(wp)}')

# Build TXD
txd_data = build_txd([(frame, 'phoneframe'), (wp, 'phonewp')])
out_path = os.path.join(ROOT, 'models', 'phone_ui.txd')
with open(out_path, 'wb') as f:
    f.write(txd_data)

fsize = os.path.getsize(out_path)
print(f'Output: {out_path} ({fsize:,} bytes)')
print('Done!')
