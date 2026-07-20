#!/usr/bin/env python3
"""Generate AppIcon.icns for WubiTypingTrainer macOS app."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import subprocess
import os
import shutil

SIZE = 1024
CORNER = 180


def draw_rounded_rect(d, bbox, radius, fill):
    import math
    x0, y0, x1, y1 = bbox
    pts = []
    # Top-left corner
    for a in range(180, 271):
        rad = math.radians(a)
        pts.append((x0 + radius + radius * math.cos(rad), y0 + radius + radius * math.sin(rad)))
    # Top-right corner
    for a in range(270, 361):
        rad = math.radians(a)
        pts.append((x1 - radius + radius * math.cos(rad), y0 + radius + radius * math.sin(rad)))
    # Bottom-right corner
    for a in range(0, 91):
        rad = math.radians(a)
        pts.append((x1 - radius + radius * math.cos(rad), y1 - radius + radius * math.sin(rad)))
    # Bottom-left corner
    for a in range(90, 181):
        rad = math.radians(a)
        pts.append((x0 + radius + radius * math.cos(rad), y1 - radius + radius * math.sin(rad)))
    d.polygon(pts, fill=fill)


def create_icon():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # --- Deep blue to indigo gradient background (flipped) ---
    for y in range(SIZE):
        t = y / SIZE
        r = int(60 - t * 35)
        g = int(140 - t * 80)
        b = int(255 - t * 75)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

    # --- Rounded mask ---
    mask = Image.new("L", (SIZE, SIZE), 0)
    mask_draw = ImageDraw.Draw(mask)
    draw_rounded_rect(mask_draw, (0, 0, SIZE - 1, SIZE - 1), CORNER, 255)

    bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bg.paste(img, mask=mask)
    img = bg

    # --- Subtle diagonal lines texture ---
    lines = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    lines_draw = ImageDraw.Draw(lines)
    for offset in range(-SIZE, SIZE * 2, 40):
        lines_draw.line([(offset, 0), (offset + SIZE, SIZE)], fill=(255, 255, 255, 5), width=2)

    mask2 = Image.new("L", (SIZE, SIZE), 0)
    mask2_draw = ImageDraw.Draw(mask2)
    draw_rounded_rect(mask2_draw, (0, 0, SIZE - 1, SIZE - 1), CORNER, 255)

    lines_masked = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    lines_masked.paste(lines, mask=mask2)
    img = Image.alpha_composite(img, lines_masked)

    # --- Decorative circles in upper part (masked to icon shape, excluding keyboard) ---
    circles_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    circles_draw = ImageDraw.Draw(circles_layer)
    circles_draw.ellipse([100, 110, 300, 310], fill=(255, 255, 255, 20))
    circles_draw.ellipse([760, 200, 900, 340], fill=(255, 255, 255, 15))
    circles_draw.ellipse([80, 750, 280, 950], fill=(255, 255, 255, 25))
    circles_draw.ellipse([820, 620, 920, 720], fill=(255, 255, 255, 18))
    # Mask: icon shape minus keyboard area
    circles_mask = Image.new("L", (SIZE, SIZE), 0)
    circles_mask_draw = ImageDraw.Draw(circles_mask)
    draw_rounded_rect(circles_mask_draw, (0, 0, SIZE - 1, SIZE - 1), CORNER, 255)
    # Cut out keyboard area
    kb_mask_cx, kb_mask_cy = SIZE // 2, SIZE // 2 + 160
    kb_mask_w, kb_mask_h = 720, 390
    kb_mask_x0 = kb_mask_cx - kb_mask_w // 2
    kb_mask_y0 = kb_mask_cy - kb_mask_h // 2
    draw_rounded_rect(circles_mask_draw, (kb_mask_x0, kb_mask_y0, kb_mask_x0 + kb_mask_w, kb_mask_y0 + kb_mask_h), 36, 0)
    circles_masked = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    circles_masked.paste(circles_layer, mask=circles_mask)
    img = Image.alpha_composite(img, circles_masked)

    # --- Stylized keyboard icon (tilted, center) ---
    kb = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    kb_draw = ImageDraw.Draw(kb)

    # Keyboard body (rounded rect, white, semi-transparent)
    kb_cx, kb_cy = SIZE // 2, SIZE // 2 + 160
    kb_w, kb_h = 720, 390
    kb_r = 36
    kb_x0 = kb_cx - kb_w // 2
    kb_y0 = kb_cy - kb_h // 2
    kb_body_color = (255, 255, 255, 140)
    draw_rounded_rect(kb_draw, (kb_x0, kb_y0, kb_x0 + kb_w, kb_y0 + kb_h), kb_r, kb_body_color)

    # Key layout: 3 rows of keys
    key_color = (255, 255, 255, 250)
    key_color_accent = (100, 200, 255, 250)  # space bar highlight
    key_gap = 18
    key_h = 56
    key_pad = 50  # horizontal padding from keyboard edge

    row1_keys = 10
    row2_keys = 9
    row3_keys = 9

    # Single key width based on row 1 (most keys)
    key_w = (kb_w - 2 * key_pad - (row1_keys - 1) * key_gap) // row1_keys

    # Row 1 (top) - centered
    row1_total_w = row1_keys * key_w + (row1_keys - 1) * key_gap
    row1_start_x = kb_cx - row1_total_w // 2
    row1_y = kb_y0 + 50
    for i in range(row1_keys):
        kx = row1_start_x + i * (key_w + key_gap)
        draw_rounded_rect(kb_draw, (kx, row1_y, kx + key_w, row1_y + key_h), 6, key_color)

    # Row 2 (middle) - centered
    row2_total_w = row2_keys * key_w + (row2_keys - 1) * key_gap
    row2_start_x = kb_cx - row2_total_w // 2
    row2_y = row1_y + key_h + key_gap
    mid_key_idx = row2_keys // 2
    for i in range(row2_keys):
        kx = row2_start_x + i * (key_w + key_gap)
        if i == mid_key_idx:
            # Special key: draw on separate layer to avoid keyboard background interference
            # Key shadow
            key_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
            key_shadow_draw = ImageDraw.Draw(key_shadow)
            draw_rounded_rect(key_shadow_draw, (kx + 8, row2_y + key_h - 5, kx + key_w + 8, row2_y + key_h + 15), 6, (0, 0, 0, 80))
            key_shadow = key_shadow.filter(ImageFilter.GaussianBlur(radius=10))
            kb = Image.alpha_composite(kb, key_shadow)
            kb_draw = ImageDraw.Draw(kb)  # recreate draw context
            # Store key position for bubble connection
            special_key_x = kx
            special_key_y = row2_y
            # Draw key on separate layer (will be composited after keyboard)
            special_key_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
            special_key_draw = ImageDraw.Draw(special_key_layer)
            draw_rounded_rect(special_key_draw, (kx, row2_y, kx + key_w, row2_y + key_h), 6, (255, 255, 255, 255))
        else:
            draw_rounded_rect(kb_draw, (kx, row2_y, kx + key_w, row2_y + key_h), 6, key_color)

    # Row 3 (bottom) - centered
    row3_total_w = row3_keys * key_w + (row3_keys - 1) * key_gap
    row3_start_x = kb_cx - row3_total_w // 2
    row3_y = row2_y + key_h + key_gap
    for i in range(row3_keys):
        kx = row3_start_x + i * (key_w + key_gap)
        draw_rounded_rect(kb_draw, (kx, row3_y, kx + key_w, row3_y + key_h), 6, key_color)

    # Space bar (wide, bottom center)
    space_w = kb_w - 2 * key_pad - 2 * (key_w + key_gap)
    space_x = kb_cx - space_w // 2
    space_y = row3_y + key_h + key_gap
    space_h = 48
    draw_rounded_rect(kb_draw, (space_x, space_y, space_x + space_w, space_y + space_h), 8, key_color_accent)

    # Apply strong drop shadow to keyboard for突出 effect
    kb_shadow = kb.filter(ImageFilter.GaussianBlur(radius=45))
    kb_shadow_tinted = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    kb_shadow_draw = ImageDraw.Draw(kb_shadow_tinted)
    kb_shadow_draw.rectangle([0, 0, SIZE, SIZE], fill=(0, 0, 0, 180))
    kb_shadow_tinted = Image.composite(kb_shadow_tinted, Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)), kb_shadow.split()[3])

    # Offset shadow more for depth
    shadow_offset = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_offset.paste(kb_shadow_tinted, (15, 25))
    img = Image.alpha_composite(img, shadow_offset)

    # Draw keyboard
    img = Image.alpha_composite(img, kb)

    # Draw special key on top (separate layer for correct color)
    img = Image.alpha_composite(img, special_key_layer)

    # --- Speech bubble with "五" above middle key of row 2 ---
    # Calculate middle key position (index 4 of 9 keys)
    mid_key_idx = row2_keys // 2
    mid_key_x = row2_start_x + mid_key_idx * (key_w + key_gap)
    mid_key_cx = mid_key_x + key_w // 2
    bubble_bottom_y = row2_y - 10  # just above the key

    # Bubble dimensions
    bubble_w = 360
    bubble_h = 360
    bubble_r = 100
    pointer_w = 160
    pointer_h = 120
    bubble_cx = mid_key_cx
    bubble_cy = bubble_bottom_y - bubble_h // 2 + 2 - pointer_h + 30
    bubble_x0 = bubble_cx - bubble_w // 2
    bubble_y0 = bubble_cy - bubble_h // 2

    # Create bubble layer (render at2x for smoother edges)
    BUBBLE_SCALE = 2
    bubble_layer = Image.new("RGBA", (SIZE * BUBBLE_SCALE, SIZE * BUBBLE_SCALE), (0, 0, 0, 0))
    bubble_draw = ImageDraw.Draw(bubble_layer)

    # Scale bubble coordinates
    bs = BUBBLE_SCALE
    bubble_x0_s = bubble_x0 * bs
    bubble_y0_s = bubble_y0 * bs
    bubble_w_s = bubble_w * bs
    bubble_h_s = bubble_h * bs
    bubble_r_s = bubble_r * bs
    bubble_cx_s = bubble_cx * bs
    bubble_cy_s = bubble_cy * bs
    pointer_w_s = pointer_w * bs
    pointer_h_s = pointer_h * bs

    # Bubble shadow (clipped at neck connection)
    bubble_shadow = Image.new("RGBA", (SIZE * bs, SIZE * bs), (0, 0, 0, 0))
    bubble_shadow_draw = ImageDraw.Draw(bubble_shadow)
    # Shadow only for the bubble body
    shadow_bottom_y = bubble_y0_s + bubble_h_s + 15
    draw_rounded_rect(bubble_shadow_draw, (bubble_x0_s + 15, bubble_y0_s + 30, bubble_x0_s + bubble_w_s + 15, shadow_bottom_y), bubble_r_s, (0, 0, 0, 200))
    # Neck side shadows
    neck_shadow_offset_x = 15
    neck_shadow_offset_y = 15
    # Top of neck shadow (inside bubble)
    neck_shadow_top_y = bubble_y0_s + bubble_h_s - bubble_r_s + neck_shadow_offset_y
    # Bottom of neck shadow (inside key)
    neck_shadow_bottom_y = special_key_y * BUBBLE_SCALE + 6 + neck_shadow_offset_y
    # Left side shadow
    pointer_shadow_pts = [
        (bubble_x0_s + bubble_r_s - 12, neck_shadow_top_y),
        (bubble_x0_s + bubble_r_s + 3, neck_shadow_top_y),
        (bubble_cx_s - key_w * BUBBLE_SCALE // 2 + 3, neck_shadow_bottom_y),
        (bubble_cx_s - key_w * BUBBLE_SCALE // 2 - 12, neck_shadow_bottom_y),
    ]
    bubble_shadow_draw.polygon(pointer_shadow_pts, fill=(0, 0, 0, 180))
    # Right side shadow
    pointer_shadow_pts = [
        (bubble_x0_s + bubble_w_s - bubble_r_s - 3, neck_shadow_top_y),
        (bubble_x0_s + bubble_w_s - bubble_r_s + 12, neck_shadow_top_y),
        (bubble_cx_s + key_w * BUBBLE_SCALE // 2 + 12, neck_shadow_bottom_y),
        (bubble_cx_s + key_w * BUBBLE_SCALE // 2 - 3, neck_shadow_bottom_y),
    ]
    bubble_shadow_draw.polygon(pointer_shadow_pts, fill=(0, 0, 0, 180))
    bubble_shadow = bubble_shadow.filter(ImageFilter.GaussianBlur(radius=40))
    bubble_layer = Image.alpha_composite(bubble_layer, bubble_shadow)
    bubble_draw = ImageDraw.Draw(bubble_layer)

    # Bubble neck (extends from bubble bottom to key, edges blend)
    pointer_cx_s = bubble_cx_s
    # Start inside key to blend with rounded corners
    neck_bottom_y_s = special_key_y * BUBBLE_SCALE + 6  # extend into key
    # End well inside bubble to ensure full coverage by rounded corners
    pointer_top_y_s = bubble_y0_s + bubble_h_s - bubble_r_s
    # Top width matches bubble width (full bottom edge)
    neck_top_w = bubble_w_s
    # Bottom width matches key width
    neck_bottom_w = key_w * BUBBLE_SCALE
    pointer_points = [
        (bubble_x0_s + bubble_r_s, pointer_top_y_s),  # left side inside bubble
        (bubble_x0_s + bubble_w_s - bubble_r_s, pointer_top_y_s),  # right side inside bubble
        (pointer_cx_s + neck_bottom_w // 2, neck_bottom_y_s),  # right edge of key
        (pointer_cx_s - neck_bottom_w // 2, neck_bottom_y_s),  # left edge of key
    ]
    # Draw neck first, then bubble on top for seamless blend
    bubble_draw.polygon(pointer_points, fill=(255, 255, 255, 255))
    draw_rounded_rect(bubble_draw, (bubble_x0_s, bubble_y0_s, bubble_x0_s + bubble_w_s, bubble_y0_s + bubble_h_s), bubble_r_s, (255, 255, 255, 255))

    # Downscale for smooth edges
    bubble_layer = bubble_layer.resize((SIZE, SIZE), Image.LANCZOS)

    # Draw "五" character in bubble (centered with anchor)
    bubble_draw_final = ImageDraw.Draw(bubble_layer)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 280)
    except Exception:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 280)
        except Exception:
            font = ImageFont.load_default()

    text = "五"
    bubble_draw_final.text((bubble_cx, bubble_cy), text, font=font, fill=(60, 120, 220, 255), anchor="mm")

    img = Image.alpha_composite(img, bubble_layer)

    # --- Top-left shine effect (matching light source, masked to icon shape) ---
    shine = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shine_draw = ImageDraw.Draw(shine)
    for y in range(SIZE):
        for x in range(SIZE):
            # Distance from top-left corner (normalized 0-1)
            dist = ((x / SIZE) ** 2 + (y / SIZE) ** 2) ** 0.5
            alpha = int(40 * max(0, 1 - dist))
            if alpha > 0:
                shine_draw.point((x, y), fill=(255, 255, 255, alpha))
    shine_mask = Image.new("L", (SIZE, SIZE), 0)
    shine_mask_draw = ImageDraw.Draw(shine_mask)
    draw_rounded_rect(shine_mask_draw, (0, 0, SIZE - 1, SIZE - 1), CORNER, 255)
    shine_masked = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shine_masked.paste(shine, mask=shine_mask)
    img = Image.alpha_composite(img, shine_masked)

    return img


def main():
    icon_img = create_icon()

    iconset_dir = "/tmp/AppIcon.iconset"
    if os.path.exists(iconset_dir):
        shutil.rmtree(iconset_dir)
    os.makedirs(iconset_dir)

    sizes = [
        (16, "16x16"), (32, "16x16@2x"),
        (32, "32x32"), (64, "32x32@2x"),
        (128, "128x128"), (256, "128x128@2x"),
        (256, "256x256"), (512, "256x256@2x"),
        (512, "512x512"), (1024, "512x512@2x"),
    ]

    for s, name in sizes:
        resized = icon_img.resize((s, s), Image.LANCZOS)
        resized.save(os.path.join(iconset_dir, f"icon_{name}.png"))

    output_path = "/Users/wei/Code.localized/WubiTypingTrainer/Resources/AppIcon.icns"
    result = subprocess.run(
        ["iconutil", "-c", "icns", iconset_dir, "-o", output_path],
        capture_output=True, text=True
    )

    if result.returncode == 0:
        size_kb = os.path.getsize(output_path) / 1024
        print(f"Generated: {output_path} ({size_kb:.1f} KB)")
    else:
        print(f"Error: {result.stderr}")


if __name__ == "__main__":
    main()
