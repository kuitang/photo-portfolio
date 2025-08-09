#!/bin/bash

# Master build script for the photography portfolio
# Orchestrates image resizing and HTML generation

# Source common library
source "$(dirname "$0")/common.sh"

# Ensure we're in the project root
ensure_project_root


# Main build process
main() {
    print_section_header "Photography Portfolio Build System"
    
    # Check dependencies
    if ! check_all_dependencies; then
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
    if ! run_with_timing "Image resizing" bash "scripts/resize_images.sh"; then
        print_error "Image resizing failed"
        exit 1
    fi
    
    echo ""
    
    # Step 2: Generate HTML
    print_status "Step 2: Generating HTML pages..."
    echo "========================================"
    if ! run_with_timing "HTML generation" bash "scripts/generate_html.sh"; then
        print_error "HTML generation failed"
        exit 1
    fi
    
    echo ""
    
    # Step 3: Create symlinks for easier serving (optional)
    if [ -d "$BUILD_DIR" ]; then
        # Create symlinks to image directories for the build
        print_status "Step 3: Creating symlinks..."
        ln -sfn "../$ORIGINALS_DIR" "$BUILD_DIR/$ORIGINALS_DIR" 2>/dev/null || true
        ln -sfn "../$RESIZED_DIR" "$BUILD_DIR/$RESIZED_DIR" 2>/dev/null || true
        print_status "Symlinks created"
    fi
    
    echo ""
    print_section_header "Build Complete! 🎉"
    echo "Your static site is ready in the '$BUILD_DIR/' directory"
    echo ""
    echo "To view the site locally, you can use:"
    echo "  cd $BUILD_DIR && python3 -m http.server 8000"
    echo "  Then open: http://localhost:8000"
    echo ""
    echo "Or with PHP:"
    echo "  cd $BUILD_DIR && php -S localhost:8000"
    echo ""
    echo "Or with Node.js (npx):"
    echo "  cd $BUILD_DIR && npx serve"
    echo ""
}

# Handle script arguments
case "${1:-}" in
    clean)
        print_status "Cleaning build artifacts..."
        rm -rf "$BUILD_DIR/"
        rm -rf "$RESIZED_DIR/"
        print_status "Clean complete"
        ;;
    images)
        print_section_header "Resizing Images Only"
        check_all_dependencies
        validate_csv
        run_with_timing "Image resizing" bash "scripts/resize_images.sh"
        ;;
    html)
        print_section_header "Generating HTML Only"
        check_envsubst
        validate_csv
        run_with_timing "HTML generation" bash "scripts/generate_html.sh"
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