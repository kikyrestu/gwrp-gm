"""Build separate TXD files for phone frame and wallpaper."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image
from png_to_txd import build_txd, check_has_alpha

ROOT = os.path.join(os.path.dirname(__file__), '..')

# Phone frame: 128x256 (slim, transparent)
frame = Image.open(os.path.join(ROOT, 'phone-frame.png')).convert('RGBA')
frame = frame.resize((128, 256), Image.LANCZOS)
print(f'Frame: {frame.size}, alpha: {check_has_alpha(frame)}')

txd1 = build_txd([(frame, 'phoneframe')])
p1 = os.path.join(ROOT, 'models', 'phoneframe.txd')
with open(p1, 'wb') as f:
    f.write(txd1)
print(f'Created {p1} ({os.path.getsize(p1):,} bytes)')

# Wallpaper: 128x128
wp = Image.open(os.path.join(ROOT, 'wallpaper.png')).convert('RGBA')
wp = wp.resize((128, 128), Image.LANCZOS)
print(f'Wallpaper: {wp.size}, alpha: {check_has_alpha(wp)}')

txd2 = build_txd([(wp, 'phonewp')])
p2 = os.path.join(ROOT, 'models', 'phonewp.txd')
with open(p2, 'wb') as f:
    f.write(txd2)
print(f'Created {p2} ({os.path.getsize(p2):,} bytes)')

print('Done!')
