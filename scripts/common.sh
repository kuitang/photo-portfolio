#!/bin/bash

# Common library for photography portfolio scripts
# Source this file in other scripts: source "$(dirname "$0")/common.sh"

# Exit on error by default
set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

# User data directories (configurable)
ORIGINALS_DIR="originals"
RESIZED_DIR="resized"
BUILD_DIR="build"
DEPLOY_DIR="../photos_website"

# Files
CSV_FILE="$ORIGINALS_DIR/metadata.csv"

# Site configuration
SITE_TITLE="kui.tang.photo"
CURRENT_YEAR=$(date +%Y)

# Image processing settings
IMAGE_QUALITY=85
declare -A IMAGE_SIZES=(
    ["thumb"]="600x1080"
    ["small"]="1200x1080"
    ["medium"]="1800x1600"
    ["large"]="2400x1800"
    ["xlarge"]="3200x2400"
)

# ============================================================================
# COLOR OUTPUT
# ============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[${1:-INFO}]${NC} ${2:-}"
}

print_section_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================

check_command() {
    local cmd="$1"
    local install_msg="$2"
    
    if ! command -v "$cmd" &> /dev/null; then
        print_error "$cmd is not installed"
        if [ -n "$install_msg" ]; then
            echo "$install_msg"
        fi
        return 1
    fi
    return 0
}

check_imagemagick() {
    check_command "convert" \
        "  Install with:
    Ubuntu/Debian: sudo apt-get install imagemagick
    macOS:         brew install imagemagick
    RHEL/CentOS:   sudo yum install ImageMagick"
}

check_envsubst() {
    check_command "envsubst" \
        "  Install with:
    Ubuntu/Debian: sudo apt-get install gettext
    macOS:         brew install gettext
    RHEL/CentOS:   sudo yum install gettext"
}

check_all_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=0
    
    if check_imagemagick; then
        echo "  ✓ ImageMagick found"
    else
        ((missing_deps++))
    fi
    
    if check_envsubst; then
        echo "  ✓ envsubst found"
    else
        ((missing_deps++))
    fi
    
    if [ $missing_deps -gt 0 ]; then
        print_error "Missing $missing_deps dependencies. Please install them first."
        return 1
    fi
    
    print_status "All dependencies satisfied"
    return 0
}

# ============================================================================
# CSV VALIDATION
# ============================================================================

validate_csv_header() {
    local expected_header="filename,title,year,location,camera,lens,film,developer,description,tags,category"
    local actual_header=$(head -n 1 "$CSV_FILE")
    
    if [ "$actual_header" != "$expected_header" ]; then
        print_error "CSV header doesn't match expected format"
        echo "  Expected: $expected_header"
        echo "  Found:    $actual_header"
        return 1
    fi
    return 0
}

validate_csv_newline() {
    if [ -n "$(tail -c 1 "$CSV_FILE")" ]; then
        print_error "CSV file is missing a newline at the end"
        echo "  This can cause the last record to be skipped during parsing"
        echo "  To fix: echo '' >> $CSV_FILE"
        return 1
    fi
    return 0
}

validate_csv_images() {
    local missing_files=0
    
    while IFS=',' read -r filename rest; do
        if [ "$filename" != "filename" ] && [ -n "$filename" ]; then
            if [ ! -f "$ORIGINALS_DIR/$filename" ]; then
                print_error "Image not found: $filename"
                ((missing_files++))
            fi
        fi
    done < "$CSV_FILE"
    
    if [ $missing_files -gt 0 ]; then
        print_error "Found $missing_files missing image files"
        return 1
    fi
    return 0
}

validate_csv() {
    print_status "Validating CSV metadata..."
    
    if [ ! -f "$CSV_FILE" ]; then
        print_error "Metadata file $CSV_FILE not found"
        echo ""
        echo "Please create a CSV file at: $CSV_FILE"
        echo "With the following columns:"
        echo "  filename,title,year,location,camera,lens,film,developer,description,tags,category"
        echo ""
        echo "Example:"
        echo '  IMG_001.jpg,Sunset at Beach,2024,Santa Monica CA,Canon R5,RF 24-70mm,Portra 400,D-76,Golden hour capture,sunset beach,Landscapes'
        return 1
    fi
    
    validate_csv_header
    validate_csv_newline
    validate_csv_images
    
    print_status "CSV validation complete"
    return 0
}

# ============================================================================
# DIRECTORY VALIDATION
# ============================================================================

check_directory() {
    local dir="$1"
    local error_msg="$2"
    
    if [ ! -d "$dir" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

check_file() {
    local file="$1"
    local error_msg="$2"
    
    if [ ! -f "$file" ]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Run a command with timing information
run_with_timing() {
    local description="$1"
    shift
    local start_time=$(date +%s)
    
    if "$@"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "$description completed in ${duration} seconds"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Count files of specific types
count_images() {
    local dir="${1:-$ORIGINALS_DIR}"
    find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | wc -l
}

# Escape HTML entities
escape_html() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Convert string to slug (lowercase, spaces to dashes)
to_slug() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

# Set proper file permissions for web serving
set_web_permissions() {
    local dir="$1"
    chmod -R 755 "$dir"
    find "$dir" -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) -exec chmod 644 {} \;
    find "$dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) -exec chmod 644 {} \; 2>/dev/null || true
}

# ============================================================================
# GIT UTILITIES
# ============================================================================

check_git_repo() {
    local dir="${1:-.}"
    [ -d "$dir/.git" ]
}

check_git_clean() {
    local dir="${1:-.}"
    cd "$dir"
    git diff --quiet && git diff --staged --quiet
    local result=$?
    cd - > /dev/null
    return $result
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Ensure we're in the project root
ensure_project_root() {
    # If we're in the scripts directory, go up one level
    if [[ "$PWD" == */scripts ]]; then
        cd ..
    fi
    
    # Verify we're in the right place by checking for key directories
    if [ ! -d "scripts" ] || [ ! -d "$ORIGINALS_DIR" ] || [ ! -d "templates" ]; then
        print_error "Must run from project root directory"
        return 1
    fi
}