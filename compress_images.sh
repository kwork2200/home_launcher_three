#!/bin/bash

# Image compression script for Flutter app
# This will compress images to reduce app size

IMAGES_DIR="assets/images"

echo "🖼️  Starting image compression..."
echo ""

# Function to compress PNG images
compress_png() {
    local file="$1"
    local original_size=$(du -k "$file" | cut -f1)
    
    echo "📦 Compressing: $(basename "$file")"
    echo "   Original size: ${original_size}KB"
    
    # Use sips (macOS built-in tool) to compress
    sips -s format png "$file" --out "${file}.tmp" > /dev/null 2>&1
    sips -Z 1024 "${file}.tmp" --out "${file}.compressed" > /dev/null 2>&1
    
    local compressed_size=$(du -k "${file}.compressed" | cut -f1)
    local savings=$((original_size - compressed_size))
    
    if [ $savings -gt 0 ]; then
        mv "${file}.compressed" "$file"
        echo "   ✅ New size: ${compressed_size}KB (Saved: ${savings}KB)"
    else
        rm -f "${file}.compressed"
        echo "   ⏭️  No savings, keeping original"
    fi
    
    rm -f "${file}.tmp"
    echo ""
}

# Function to compress JPG images
compress_jpg() {
    local file="$1"
    local original_size=$(du -k "$file" | cut -f1)
    
    echo "📦 Compressing: $(basename "$file")"
    echo "   Original size: ${original_size}KB"
    
    # Use sips to compress with 75% quality
    sips -s format jpeg -s formatOptions 75 "$file" --out "${file}.compressed" > /dev/null 2>&1
    
    local compressed_size=$(du -k "${file}.compressed" | cut -f1)
    local savings=$((original_size - compressed_size))
    
    if [ $savings -gt 0 ]; then
        mv "${file}.compressed" "$file"
        echo "   ✅ New size: ${compressed_size}KB (Saved: ${savings}KB)"
    else
        rm -f "${file}.compressed"
        echo "   ⏭️  No savings, keeping original"
    fi
    
    echo ""
}

# Get total size before compression
total_before=$(du -sk "$IMAGES_DIR" | cut -f1)
echo "📊 Total size before: ${total_before}KB"
echo "=================================="
echo ""

# Compress all PNG files
for file in "$IMAGES_DIR"/*.png; do
    if [ -f "$file" ]; then
        compress_png "$file"
    fi
done

# Compress all JPG/JPEG files
for file in "$IMAGES_DIR"/*.jpg "$IMAGES_DIR"/*.jpeg; do
    if [ -f "$file" ]; then
        compress_jpg "$file"
    fi
done

# Get total size after compression
total_after=$(du -sk "$IMAGES_DIR" | cut -f1)
total_saved=$((total_before - total_after))

echo "=================================="
echo "📊 Compression Complete!"
echo ""
echo "Before:  ${total_before}KB"
echo "After:   ${total_after}KB"
echo "Saved:   ${total_saved}KB ($(echo "scale=1; $total_saved * 100 / $total_before" | bc)%)"
echo ""
echo "🎉 All images compressed successfully!"
