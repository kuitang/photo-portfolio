#!/bin/bash

# Image resizing script using ImageMagick
# Processes images from originals/ and creates multiple sizes in resized/

set -e

# Configuration
ORIGINALS_DIR="originals"
RESIZED_DIR="resized"
QUALITY=85

# Size definitions - ensure high resolution for mobile devices
declare -A SIZES=(
    ["thumb"]="600x1080"
    ["small"]="1200x1080"
    ["medium"]="1800x1600"
    ["large"]="2400x1800"
    ["xlarge"]="3200x2400"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    print_error "ImageMagick is not installed. Please install it first."
    echo "On Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "On macOS: brew install imagemagick"
    echo "On RHEL/CentOS: sudo yum install ImageMagick"
    exit 1
fi

# Check if originals directory exists
if [ ! -d "$ORIGINALS_DIR" ]; then
    print_error "Directory $ORIGINALS_DIR does not exist."
    exit 1
fi

# Count images to process
IMAGE_COUNT=$(find "$ORIGINALS_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | wc -l)

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
    for SIZE_NAME in "${!SIZES[@]}"; do
        SIZE_VALUE="${SIZES[$SIZE_NAME]}"
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
            -quality "$QUALITY" \
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
chmod -R 755 "$RESIZED_DIR"

exit 0