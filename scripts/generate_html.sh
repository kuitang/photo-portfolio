#!/bin/bash

# HTML generation script using envsubst for templating
# Reads metadata.csv and generates static HTML pages

set -e

# Configuration
ORIGINALS_DIR="originals"
TEMPLATES_DIR="templates"
BUILD_DIR="build"
STATIC_DIR="static"
CSV_FILE="$ORIGINALS_DIR/metadata.csv"

# Site configuration
export SITE_TITLE="kui.tang.photo"
export BASE_PATH="."
export CURRENT_YEAR=$(date +%Y)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if CSV exists
if [ ! -f "$CSV_FILE" ]; then
    print_error "Metadata file $CSV_FILE not found"
    exit 1
fi

# Check if envsubst is available
if ! command -v envsubst &> /dev/null; then
    print_error "envsubst is not installed. Please install gettext package."
    echo "On Ubuntu/Debian: sudo apt-get install gettext"
    echo "On macOS: brew install gettext"
    exit 1
fi

# Clean and create build directory
print_status "Preparing build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/images"

# Copy static assets
print_status "Copying static assets..."
cp -r "$STATIC_DIR"/* "$BUILD_DIR/" 2>/dev/null || true

# Function to escape HTML
escape_html() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Function to format year (just pass through as string)
format_year() {
    echo "$1"
}

# Function to combine location and year
format_location_year() {
    local location="$1"
    local year="$2"
    
    if [ -n "$location" ] && [ -n "$year" ]; then
        echo "$(escape_html "$location"), $year"
    elif [ -n "$location" ]; then
        echo "$(escape_html "$location")"
    elif [ -n "$year" ]; then
        echo "$year"
    else
        echo ""
    fi
}

# Function to generate navigation items
generate_navigation() {
    local categories=$(tail -n +2 "$CSV_FILE" | cut -d',' -f11 | sort -u | grep -v '^$')
    local nav_items=""
    
    nav_items='<li><a href="'$BASE_PATH'/gallery.html">All Photos</a></li>'
    
    while IFS= read -r category; do
        if [ -n "$category" ]; then
            category_slug=$(echo "$category" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
            nav_items="$nav_items"'<li><a href="'$BASE_PATH'/gallery-'$category_slug'.html">'$category'</a></li>'
        fi
    done <<< "$categories"
    
    echo "$nav_items"
}

# Function to create gallery item HTML
create_gallery_item() {
    local filename="$1"
    local title="$2"
    local location="$3"
    local year="$4"
    local tags="$5"
    local image_url="$BASE_PATH/images/${filename%.*}.html"
    
    export ITEM_URL="$image_url"
    export ITEM_FILENAME="$filename"
    export ITEM_TITLE="$(escape_html "$title")"
    export ITEM_LOCATION="$(escape_html "$location")"
    export ITEM_YEAR="$year"
    export ITEM_TAGS="$tags"
    
    # Generate location-year combination for gallery items
    export ITEM_LOCATION_YEAR="$(format_location_year "$location" "$year")"
    
    envsubst < "$TEMPLATES_DIR/gallery-item.html.tmpl"
}

# Arrays to store image data
declare -a ALL_IMAGES=()
declare -A IMAGE_DATA=()
declare -A CATEGORIES=()
declare -A TAGS=()

# Read CSV and store data
print_status "Reading metadata..."
while IFS=',' read -r filename title year location camera lens film developer description tags category; do
    # Skip header and empty lines
    if [ "$filename" = "filename" ] || [ -z "$filename" ]; then
        continue
    fi
    
    # Store image data
    key="${filename%.*}"
    IMAGE_DATA["${key}_filename"]="$filename"
    IMAGE_DATA["${key}_title"]="$title"
    IMAGE_DATA["${key}_year"]="$year"
    IMAGE_DATA["${key}_location"]="$location"
    IMAGE_DATA["${key}_camera"]="$camera"
    IMAGE_DATA["${key}_lens"]="$lens"
    IMAGE_DATA["${key}_film"]="$film"
    IMAGE_DATA["${key}_developer"]="$developer"
    IMAGE_DATA["${key}_description"]="$description"
    IMAGE_DATA["${key}_tags"]="$tags"
    IMAGE_DATA["${key}_category"]="$category"
    
    ALL_IMAGES+=("$key")
    
    # Track categories
    if [ -n "$category" ]; then
        CATEGORIES["$category"]+="$key "
    fi
    
    # Track tags
    if [ -n "$tags" ]; then
        IFS=' ' read -ra TAG_ARRAY <<< "$tags"
        for tag in "${TAG_ARRAY[@]}"; do
            tag=$(echo "$tag" | xargs) # Trim whitespace
            if [ -n "$tag" ]; then
                TAGS["$tag"]+="$key "
            fi
        done
    fi
done < "$CSV_FILE"

print_status "Found ${#ALL_IMAGES[@]} images in metadata"

# Generate individual image pages
print_status "Generating individual image pages..."
for i in "${!ALL_IMAGES[@]}"; do
    key="${ALL_IMAGES[$i]}"
    filename="${IMAGE_DATA["${key}_filename"]}"
    output_file="$BUILD_DIR/images/${key}.html"
    
    # Set BASE_PATH for image pages (they're in subdirectory)
    export BASE_PATH=".."
    
    # Determine previous and next images
    prev_key=""
    next_key=""
    if [ $i -gt 0 ]; then
        prev_key="${ALL_IMAGES[$((i-1))]}"
    fi
    if [ $i -lt $((${#ALL_IMAGES[@]} - 1)) ]; then
        next_key="${ALL_IMAGES[$((i+1))]}"
    fi
    
    # Set environment variables for template
    export PAGE_TITLE="${IMAGE_DATA["${key}_title"]}"
    export PAGE_DESCRIPTION="${IMAGE_DATA["${key}_description"]}"
    export OG_IMAGE="$BASE_PATH/resized/large/$filename"
    export NAVIGATION_ITEMS="$(generate_navigation)"
    
    export IMAGE_FILENAME="$filename"
    export IMAGE_TITLE="$(escape_html "${IMAGE_DATA["${key}_title"]}")"
    export IMAGE_YEAR="${IMAGE_DATA["${key}_year"]}"
    export IMAGE_YEAR_DISPLAY="${IMAGE_DATA["${key}_year"]}"
    export IMAGE_DESCRIPTION="$(escape_html "${IMAGE_DATA["${key}_description"]}")"
    export IMAGE_LOCATION="$(escape_html "${IMAGE_DATA["${key}_location"]}")"
    export IMAGE_CAMERA="$(escape_html "${IMAGE_DATA["${key}_camera"]}")"
    export IMAGE_LENS="$(escape_html "${IMAGE_DATA["${key}_lens"]}")"
    export IMAGE_FILM="$(escape_html "${IMAGE_DATA["${key}_film"]}")"
    export IMAGE_DEVELOPER="$(escape_html "${IMAGE_DATA["${key}_developer"]}")"
    export IMAGE_CATEGORY="$(escape_html "${IMAGE_DATA["${key}_category"]}")"
    
    # Generate tags HTML with clickable links
    tags_html=""
    IFS=' ' read -ra TAGS_ARRAY <<< "${IMAGE_DATA["${key}_tags"]}"
    for tag in "${TAGS_ARRAY[@]}"; do
        tag=$(echo "$tag" | xargs) # Trim whitespace
        if [ -n "$tag" ]; then
            tag_slug=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
            tags_html="$tags_html<li><a href=\"$BASE_PATH/tag-$tag_slug.html\">$(escape_html "$tag")</a></li>"
        fi
    done
    export IMAGE_TAGS="$tags_html"
    
    # Generate location-year combination
    location="${IMAGE_DATA["${key}_location"]}"
    year="${IMAGE_DATA["${key}_year"]}"
    export IMAGE_LOCATION_YEAR="$(format_location_year "$location" "$year")"
    
    # Set navigation URLs
    if [ -n "$prev_key" ]; then
        export PREV_IMAGE_URL="$BASE_PATH/images/${prev_key}.html"
    else
        export PREV_IMAGE_URL="#"
    fi
    
    if [ -n "$next_key" ]; then
        export NEXT_IMAGE_URL="$BASE_PATH/images/${next_key}.html"
    else
        export NEXT_IMAGE_URL="#"
    fi
    
    # Handle empty category field
    if [ -n "${IMAGE_DATA["${key}_category"]}" ]; then
        category_slug=$(echo "${IMAGE_DATA["${key}_category"]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        export CATEGORY_URL="$BASE_PATH/gallery-${category_slug}.html"
    else
        export CATEGORY_URL="$BASE_PATH/gallery.html"
    fi
    
    # Add JavaScript for keyboard navigation on image pages
    export ADDITIONAL_SCRIPTS='<script src="'$BASE_PATH'/image-nav.js"></script>'
    
    # Generate image page content
    export MAIN_CONTENT=$(envsubst < "$TEMPLATES_DIR/image.html.tmpl")
    
    # Generate full page
    envsubst < "$TEMPLATES_DIR/base.html" > "$output_file"
    
    echo "  → Generated: images/${key}.html"
done

# Reset BASE_PATH for root-level pages
export BASE_PATH="."

# Clear additional scripts for non-image pages
export ADDITIONAL_SCRIPTS=""

# Generate main gallery page
print_status "Generating main gallery page..."
export PAGE_TITLE="Gallery"
export GALLERY_TITLE="All Photos"
# Handle empty array case
if [ ${#ALL_IMAGES[@]} -gt 0 ]; then
    export OG_IMAGE="$BASE_PATH/resized/large/${IMAGE_DATA["${ALL_IMAGES[0]}_filename"]}"
else
    export OG_IMAGE=""
fi
export NAVIGATION_ITEMS="$(generate_navigation)"

# Generate gallery items HTML
GALLERY_ITEMS=""
for key in "${ALL_IMAGES[@]}"; do
    GALLERY_ITEMS="$GALLERY_ITEMS$(create_gallery_item \
        "${IMAGE_DATA["${key}_filename"]}" \
        "${IMAGE_DATA["${key}_title"]}" \
        "${IMAGE_DATA["${key}_location"]}" \
        "${IMAGE_DATA["${key}_year"]}" \
        "${IMAGE_DATA["${key}_tags"]}")"
done
export GALLERY_ITEMS

# Simple pagination (placeholder)
export PAGINATION='<span class="current">1</span>'

export MAIN_CONTENT=$(envsubst < "$TEMPLATES_DIR/gallery.html.tmpl")
envsubst < "$TEMPLATES_DIR/base.html" > "$BUILD_DIR/gallery.html"

# Generate category galleries
print_status "Generating category galleries..."
for category in "${!CATEGORIES[@]}"; do
    category_slug=$(echo "$category" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    export PAGE_TITLE="$category"
    export GALLERY_TITLE="$category"
    
    # Generate gallery items for this category
    GALLERY_ITEMS=""
    for key in ${CATEGORIES["$category"]}; do
        GALLERY_ITEMS="$GALLERY_ITEMS$(create_gallery_item \
            "${IMAGE_DATA["${key}_filename"]}" \
            "${IMAGE_DATA["${key}_title"]}" \
            "${IMAGE_DATA["${key}_location"]}" \
            "${IMAGE_DATA["${key}_year"]}" \
            "${IMAGE_DATA["${key}_tags"]}")"
    done
    export GALLERY_ITEMS
    
    export MAIN_CONTENT=$(envsubst < "$TEMPLATES_DIR/gallery.html.tmpl")
    envsubst < "$TEMPLATES_DIR/base.html" > "$BUILD_DIR/gallery-${category_slug}.html"
    
    echo "  → Generated: gallery-${category_slug}.html"
done

# Generate tag galleries
print_status "Generating tag galleries..."
for tag in "${!TAGS[@]}"; do
    tag_slug=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    export PAGE_TITLE="$tag"
    export GALLERY_TITLE="$tag"
    
    # Generate gallery items for this tag
    GALLERY_ITEMS=""
    for key in ${TAGS["$tag"]}; do
        GALLERY_ITEMS="$GALLERY_ITEMS$(create_gallery_item \
            "${IMAGE_DATA["${key}_filename"]}" \
            "${IMAGE_DATA["${key}_title"]}" \
            "${IMAGE_DATA["${key}_location"]}" \
            "${IMAGE_DATA["${key}_year"]}" \
            "${IMAGE_DATA["${key}_tags"]}")"
    done
    export GALLERY_ITEMS
    
    export MAIN_CONTENT=$(envsubst < "$TEMPLATES_DIR/gallery.html.tmpl")
    envsubst < "$TEMPLATES_DIR/base.html" > "$BUILD_DIR/tag-${tag_slug}.html"
    
    echo "  → Generated: tag-${tag_slug}.html"
done

# Generate index page
print_status "Generating index page..."
export PAGE_TITLE="Home"
# Handle empty array case
if [ ${#ALL_IMAGES[@]} -gt 0 ]; then
    export OG_IMAGE="$BASE_PATH/resized/large/${IMAGE_DATA["${ALL_IMAGES[0]}_filename"]}"
else
    export OG_IMAGE=""
fi
export NAVIGATION_ITEMS="$(generate_navigation)"

# Featured images (first 6)
FEATURED_IMAGES=""
for i in {0..5}; do
    if [ $i -lt ${#ALL_IMAGES[@]} ]; then
        key="${ALL_IMAGES[$i]}"
        FEATURED_IMAGES="$FEATURED_IMAGES$(create_gallery_item \
            "${IMAGE_DATA["${key}_filename"]}" \
            "${IMAGE_DATA["${key}_title"]}" \
            "${IMAGE_DATA["${key}_location"]}" \
            "${IMAGE_DATA["${key}_year"]}" \
            "${IMAGE_DATA["${key}_tags"]}")"
    fi
done
export FEATURED_IMAGES


export MAIN_CONTENT=$(envsubst < "$TEMPLATES_DIR/index.html.tmpl")
envsubst < "$TEMPLATES_DIR/base.html" > "$BUILD_DIR/index.html"

print_status "HTML generation complete!"
echo "  → Generated ${#ALL_IMAGES[@]} image pages"
echo "  → Generated ${#CATEGORIES[@]} category galleries"
echo "  → Generated main gallery and index pages"

exit 0