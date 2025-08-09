#!/bin/bash

# Master build script for the photography portfolio
# Orchestrates image resizing and HTML generation

set -e

# Configuration
SCRIPTS_DIR="scripts"
ORIGINALS_DIR="originals"
CSV_FILE="$ORIGINALS_DIR/metadata.csv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Photography Portfolio Build System${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Function to validate CSV format
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
    
    # Check CSV header
    local expected_header="filename,title,year,location,camera,lens,film,developer,description,tags,category"
    local actual_header=$(head -n 1 "$CSV_FILE")
    
    if [ "$actual_header" != "$expected_header" ]; then
        print_warning "CSV header doesn't match expected format"
        echo "  Expected: $expected_header"
        echo "  Found:    $actual_header"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Check if CSV ends with newline
    if [ -n "$(tail -c 1 "$CSV_FILE")" ]; then
        print_error "CSV file is missing a newline at the end"
        echo "  This can cause the last record to be skipped during parsing"
        echo "  To fix: echo '' >> $CSV_FILE"
        return 1
    fi
    
    # Check for referenced images
    local missing_files=0
    while IFS=',' read -r filename rest; do
        if [ "$filename" != "filename" ] && [ -n "$filename" ]; then
            if [ ! -f "$ORIGINALS_DIR/$filename" ]; then
                print_warning "Image not found: $filename"
                ((missing_files++))
            fi
        fi
    done < "$CSV_FILE"
    
    if [ $missing_files -gt 0 ]; then
        print_warning "Found $missing_files missing image files"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    print_status "CSV validation complete"
    return 0
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=0
    
    # Check for ImageMagick
    if ! command -v convert &> /dev/null; then
        print_error "ImageMagick is not installed"
        echo "  Install with:"
        echo "    Ubuntu/Debian: sudo apt-get install imagemagick"
        echo "    macOS:         brew install imagemagick"
        echo "    RHEL/CentOS:   sudo yum install ImageMagick"
        ((missing_deps++))
    else
        echo "  ✓ ImageMagick found"
    fi
    
    # Check for envsubst
    if ! command -v envsubst &> /dev/null; then
        print_error "envsubst is not installed"
        echo "  Install with:"
        echo "    Ubuntu/Debian: sudo apt-get install gettext"
        echo "    macOS:         brew install gettext"
        echo "    RHEL/CentOS:   sudo yum install gettext"
        ((missing_deps++))
    else
        echo "  ✓ envsubst found"
    fi
    
    if [ $missing_deps -gt 0 ]; then
        print_error "Missing $missing_deps dependencies. Please install them first."
        return 1
    fi
    
    print_status "All dependencies satisfied"
    return 0
}

# Function to run with timing
run_with_timing() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi
    
    local start_time=$(date +%s)
    
    if bash "$script_path"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_status "Completed in ${duration} seconds"
        return 0
    else
        print_error "Script failed: $script_name"
        return 1
    fi
}

# Main build process
main() {
    print_header
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    echo ""
    
    # Validate CSV
    if ! validate_csv; then
        exit 1
    fi
    
    echo ""
    
    # Step 1: Resize images
    print_status "Step 1: Resizing images..."
    echo "========================================"
    if ! run_with_timing "resize_images.sh"; then
        print_error "Image resizing failed"
        exit 1
    fi
    
    echo ""
    
    # Step 2: Generate HTML
    print_status "Step 2: Generating HTML pages..."
    echo "========================================"
    if ! run_with_timing "generate_html.sh"; then
        print_error "HTML generation failed"
        exit 1
    fi
    
    echo ""
    
    # Step 3: Create symlinks for easier serving (optional)
    if [ -d "build" ]; then
        # Create symlinks to image directories for the build
        print_status "Step 3: Creating symlinks..."
        ln -sfn "../originals" "build/originals" 2>/dev/null || true
        ln -sfn "../resized" "build/resized" 2>/dev/null || true
        print_status "Symlinks created"
    fi
    
    echo ""
    print_header
    print_status "Build complete! 🎉"
    echo ""
    echo "Your static site is ready in the 'build/' directory"
    echo ""
    echo "To view the site locally, you can use:"
    echo "  cd build && python3 -m http.server 8000"
    echo "  Then open: http://localhost:8000"
    echo ""
    echo "Or with PHP:"
    echo "  cd build && php -S localhost:8000"
    echo ""
    echo "Or with Node.js (npx):"
    echo "  cd build && npx serve"
    echo ""
}

# Handle script arguments
case "${1:-}" in
    clean)
        print_status "Cleaning build artifacts..."
        rm -rf build/
        rm -rf resized/
        print_status "Clean complete"
        ;;
    images)
        print_header
        print_status "Resizing images only..."
        run_with_timing "resize_images.sh"
        ;;
    html)
        print_header
        print_status "Generating HTML only..."
        run_with_timing "generate_html.sh"
        ;;
    help|--help|-h)
        echo "Photography Portfolio Build System"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (none)    Run full build (resize images + generate HTML)"
        echo "  clean     Remove all build artifacts"
        echo "  images    Resize images only"
        echo "  html      Generate HTML only"
        echo "  help      Show this help message"
        echo ""
        ;;
    *)
        main
        ;;
esac

exit 0