#!/bin/bash

# Image resizing script using ImageMagick
# Processes images from originals/ and creates multiple sizes in resized/

# Source common library
source "$(dirname "$0")/common.sh"

# Ensure we're in the project root
ensure_project_root

# Validation is now handled by build.sh, but we still check basic requirements
check_directory "$ORIGINALS_DIR" "Directory $ORIGINALS_DIR does not exist."

# Count images to process
IMAGE_COUNT=$(count_images)

if [ "$IMAGE_COUNT" -eq 0 ]; then
    print_warning "No JPEG images found in $ORIGINALS_DIR"
    exit 0
fi

print_status "Found $IMAGE_COUNT images to process"

# Process each image
PROCESSED=0
SKIPPED=0
ERRORS=0

# Use process substitution instead of pipe to avoid subshell
while read -r IMAGE; do
    BASENAME=$(basename "$IMAGE")
    print_status "Processing: $BASENAME"
    
    # Check if image is valid
    if ! identify "$IMAGE" &> /dev/null; then
        print_error "Invalid image: $BASENAME"
        ((ERRORS++))
        continue
    fi
    
    # Get image dimensions for aspect ratio
    DIMENSIONS=$(identify -format "%wx%h" "$IMAGE")
    WIDTH=$(echo $DIMENSIONS | cut -d'x' -f1)
    HEIGHT=$(echo $DIMENSIONS | cut -d'x' -f2)
    
    # Process each size
    for SIZE_NAME in "${!IMAGE_SIZES[@]}"; do
        SIZE_VALUE="${IMAGE_SIZES[$SIZE_NAME]}"
        OUTPUT_DIR="$RESIZED_DIR/$SIZE_NAME"
        OUTPUT_FILE="$OUTPUT_DIR/$BASENAME"
        
        # Create output directory if it doesn't exist
        mkdir -p "$OUTPUT_DIR"
        
        # Skip if output already exists and is newer than source
        if [ -f "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" -nt "$IMAGE" ]; then
            echo "  → Skipping $SIZE_NAME (already up to date)"
            continue
        fi
        
        echo -n "  → Creating $SIZE_NAME version... "
        
        # All sizes maintain aspect ratio with minimum 1080px vertical resolution
        convert "$IMAGE" \
            -auto-orient \
            -resize "$SIZE_VALUE>" \
            -quality "$IMAGE_QUALITY" \
            -strip \
            -interlace Plane \
            -sampling-factor 4:2:0 \
            "$OUTPUT_FILE" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "done"
        else
            echo "failed"
            print_error "Failed to create $SIZE_NAME version of $BASENAME"
            ERRORS=$((ERRORS + 1))
        fi
    done
    
    PROCESSED=$((PROCESSED + 1))
    echo ""
done < <(find "$ORIGINALS_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \))

# Print summary
echo "================================"
print_status "Processing complete!"
echo "  Processed: $PROCESSED images"
echo "  Skipped: $SKIPPED images"
if [ $ERRORS -gt 0 ]; then
    print_error "  Errors: $ERRORS"
fi
echo "================================"

# Set proper permissions
set_web_permissions "$RESIZED_DIR"

exit 0