# Photography Portfolio - Design & Implementation Plan

## Design Specifications

### Visual Design
- **Background**: Pure white (#FFFFFF)
- **Typography**: 
  - Font family: Helvetica, Arial, sans-serif
  - Text colors: Black (#000000) for primary text, Grey (#666666) for secondary
  - Text style: Small caps for headers and navigation
  - Font sizes: Responsive scaling (16px base, 14px mobile)
- **Layout**:
  - Minimal grid-based gallery layout
  - Single image view with metadata display
  - Responsive breakpoints: 320px, 768px, 1024px, 1440px, 2560px
- **Navigation**: 
  - Top navigation bar with portfolio sections
  - Previous/Next navigation for single image view
  - Breadcrumb navigation

### Responsive Image Strategy
- **Breakpoints & Resolutions**:
  - Mobile: 320px, 375px, 414px (1x, 2x, 3x for retina)
  - Tablet: 768px, 1024px (1x, 2x for retina)
  - Desktop: 1440px, 1920px, 2560px (1x, 2x for retina)
  - Special handling for Apple Retina displays using srcset and sizes attributes
- **Image Formats**:
  - JPEG for all images (optimized quality: 85%)
  - Thumbnail: 300x300 (square crop)
  - Small: 600px wide
  - Medium: 1200px wide
  - Large: 1920px wide
  - XLarge: 2880px wide (for retina displays)
  - Original: preserved for download

## Directory Structure
```
photos/
├── CLAUDE.md                 # This file
├── originals/               # User uploads images here
│   └── metadata.csv         # CSV with image metadata
├── resized/                 # Generated resized images
│   ├── thumb/
│   ├── small/
│   ├── medium/
│   ├── large/
│   └── xlarge/
├── templates/               # HTML templates
│   ├── base.html
│   ├── index.html.tmpl
│   ├── gallery.html.tmpl
│   └── image.html.tmpl
├── static/                  # Static assets
│   └── style.css
├── build/                   # Generated HTML output
│   ├── index.html
│   ├── gallery.html
│   └── images/
│       └── [image-name].html
└── scripts/                 # Build scripts
    ├── resize_images.sh
    ├── generate_html.sh
    └── build.sh

```

## CSV Metadata Format
The metadata.csv file will contain:
```csv
filename,title,year,location,camera,lens,film,developer,description,tags,category
IMG_001.jpg,Sunset at Beach,2024,Santa Monica CA,Canon R5,RF 24-70mm,Portra 400,C-41,Golden hour capture at the pier,sunset beach landscape,Landscapes
```

Columns:
- **filename**: Original filename (required)
- **title**: Image title for display (required)
- **year**: Year taken as string (e.g., "2024" or "2023-2024", optional)
- **location**: Location where photo was taken (optional)
- **camera**: Camera model (optional)
- **lens**: Lens used (optional)
- **film**: Film stock or digital sensor info (optional)
- **developer**: Film developer or processing info (optional)
- **description**: Longer description of the image (optional)
- **tags**: Space-separated tags for categorization (optional)
- **category**: Main category for gallery organization (optional)

**Note:** No quotes needed in CSV unless field contains commas. All fields except filename and title can be empty.

## Implementation Components

### 1. Image Processing (resize_images.sh)
- Scan originals/ directory for new images
- For each image, generate all required sizes using ImageMagick
- Optimize JPEG quality (85% for web display)
- Maintain aspect ratios
- Create square thumbnails with center crop

### 2. HTML Generation (generate_html.sh)
- Parse metadata.csv
- Use envsubst to populate HTML templates
- Generate:
  - Index page with featured images
  - Gallery pages by category
  - Individual image pages with full metadata
- Create navigation links between pages

### 3. CSS Styling (style.css)
- Mobile-first responsive design
- CSS Grid for gallery layout
- Flexbox for navigation and image metadata
- Media queries for all breakpoints
- Picture element support for responsive images
- Small caps text transformation

### 4. Build System (build.sh)
- Master script that:
  1. Validates CSV format
  2. Runs image resizing
  3. Generates all HTML pages
  4. Copies static assets
  5. Creates sitemap (optional)

## HTML Template Variables
Templates will use these environment variables:
- `$SITE_TITLE` - Main site title
- `$SITE_DESCRIPTION` - Site description
- `$IMAGE_TITLE` - Individual image title
- `$IMAGE_PATH_*` - Paths to different image sizes
- `$IMAGE_YEAR` - Year as string
- `$IMAGE_FILM` - Film stock or sensor info
- `$IMAGE_DEVELOPER` - Film developer or processing info
- `$IMAGE_METADATA` - Formatted metadata block
- `$GALLERY_ITEMS` - Generated gallery grid items
- `$NAVIGATION` - Generated navigation menu

## Responsive Image Implementation
```html
<picture>
  <source media="(max-width: 414px)" 
          srcset="resized/small/image.jpg 1x,
                  resized/medium/image.jpg 2x,
                  resized/large/image.jpg 3x">
  <source media="(max-width: 1024px)" 
          srcset="resized/medium/image.jpg 1x,
                  resized/large/image.jpg 2x">
  <source media="(min-width: 1025px)" 
          srcset="resized/large/image.jpg 1x,
                  resized/xlarge/image.jpg 2x">
  <img src="resized/medium/image.jpg" alt="$IMAGE_TITLE">
</picture>
```

## Performance Optimizations
- Lazy loading for images below the fold
- Preload critical CSS
- Minimal JavaScript (none required for basic functionality)
- Optimized image sizes for each breakpoint
- Browser caching headers in .htaccess (if using Apache)

## Future Enhancements (Optional)
- Dark mode support via CSS custom properties
- Image EXIF data extraction
- RSS feed generation
- Search functionality (via static JSON index)
- Print stylesheet for photo printing

---

# ARCHITECTURE SUMMARY

## Current Implementation Status (2025-08-09)

This is a **complete, production-ready** static photography portfolio generator built with bash scripts, HTML templates, and minimal JavaScript. The system is fully functional with the following features implemented:

### ✅ Completed Features

#### Core Functionality
- **Static site generation** using bash scripts and envsubst templating
- **Responsive image processing** with 5 sizes (thumb/small/medium/large/xlarge)
- **CSV-based metadata management** with comprehensive validation
- **Gallery organization** by categories and tags
- **Individual image pages** with full metadata display
- **Keyboard navigation** (arrow keys) on image pages
- **Mobile-first responsive design** with Inter font and uppercase styling

#### Gallery Types Generated
1. **Main gallery** (`gallery.html`) - All photos
2. **Category galleries** (`gallery-[category].html`) - Photos grouped by category field
3. **Tag galleries** (`tag-[tag].html`) - Photos grouped by individual tags
4. **Index page** (`index.html`) - Featured photos (first 6)

#### Navigation Features
- **Clickable navigation** between images (HTML links, no JS required)
- **Keyboard navigation** (left/right arrows) with minimal JavaScript
- **Breadcrumb navigation** on all pages
- **Tag links** on image pages that navigate to tag galleries
- **Category navigation** in main navigation bar

### Technical Architecture

#### Build System (`scripts/build.sh`)
**Master orchestrator** that runs in this order:
1. **Dependency validation** (ImageMagick, envsubst)
2. **CSV validation** (format, missing newlines)
3. **Image processing** (`resize_images.sh`)
4. **HTML generation** (`generate_html.sh`)
5. **Asset copying** and symlink creation

#### Image Processing (`scripts/resize_images.sh`)
- **ImageMagick-based** processing with quality optimization (85%)
- **Incremental processing** - only resizes changed images
- **5 image sizes** generated: 300px thumb (square), 600px small, 1200px medium, 1920px large, 2880px xlarge
- **Atomic operations** with proper error handling

#### HTML Generation (`scripts/generate_html.sh`)
**Core templating engine** with these key features:
- **CSV parsing** using bash associative arrays for data storage
- **Tag and category tracking** with automatic gallery generation
- **envsubst templating** for variable substitution
- **Dynamic navigation** generation based on available categories
- **Responsive image markup** with picture elements
- **Clickable tag links** that navigate to tag-specific galleries

#### Template System
- **`base.html`** - Master template with conditional JavaScript loading
- **`image.html.tmpl`** - Individual image page with metadata display
- **`gallery.html.tmpl`** - Gallery grid layout (reused for all gallery types)
- **`gallery-item.html.tmpl`** - Individual gallery item component
- **`index.html.tmpl`** - Homepage with featured images

#### CSS Architecture (`static/style.css`)
- **Inter font** with `text-transform: uppercase` for consistent branding
- **CSS Grid** for gallery layouts with responsive breakpoints
- **Mobile-first design** (14px on mobile, 16px desktop)
- **Square thumbnail constraint** (400px max-width prevents stretching)
- **Flexible grid system** with `auto-fill` to prevent single-item stretching

#### JavaScript (`static/image-nav.js`)
- **Minimal implementation** (14 lines) for keyboard navigation
- **Only loaded on image pages** via conditional template variable
- **No dependencies** - pure vanilla JavaScript
- **Graceful fallback** - site works completely without JavaScript

### Data Flow Architecture

```
originals/metadata.csv 
    ↓ (CSV parsing)
BASH ASSOCIATIVE ARRAYS
    ↓ (data processing)
├── IMAGE_DATA["key_field"] (individual image metadata)
├── CATEGORIES["category"] (images by category)  
└── TAGS["tag"] (images by tag)
    ↓ (template generation)
HTML TEMPLATES + envsubst
    ↓ (output)
build/ directory (deployable static site)
```

### Key Design Decisions

#### 1. **Static-First Architecture**
- **No server-side processing** required for deployment
- **Fast loading** with optimized images and minimal assets
- **Easy deployment** to any web server or CDN

#### 2. **Bash + envsubst Templating**
- **No build tool dependencies** (Node.js, Python, etc.)
- **Simple variable substitution** that's easy to understand and debug
- **Shell-native** approach leveraging existing Unix tools

#### 3. **CSV-Based Content Management**
- **Non-technical friendly** - photographers can edit in Excel/Google Sheets
- **Version control friendly** - CSV diffs are readable
- **Flexible schema** - empty fields handled gracefully

#### 4. **Responsive Image Strategy**
- **5 size variants** cover all common screen sizes and pixel densities
- **Picture elements** with srcset for optimal loading
- **Square thumbnails** for consistent gallery grid appearance

#### 5. **Tag + Category System**
- **Categories** for broad grouping (Street, Landscape, etc.)
- **Tags** for specific attributes (high-contrast, shadows, etc.)
- **Both generate separate galleries** for flexible organization

---

# DEVELOPER GUIDE

## Working with This Codebase

### Understanding the Architecture

This is a **static site generator**, not a dynamic web application. The workflow is:
1. **Content creation**: Add images to `originals/` and update `metadata.csv`
2. **Build process**: Run `./scripts/build.sh` to generate site
3. **Deployment**: Copy `build/` directory to web server

### Essential Files to Understand

**Start here when making changes:**

1. **`CLAUDE.md`** (this file) - Complete project documentation
2. **`scripts/generate_html.sh`** - Core templating logic, data processing
3. **`templates/base.html`** - Master page template
4. **`static/style.css`** - All styling and responsive behavior
5. **`originals/metadata.csv`** - Content schema and sample data

### Common Development Tasks

#### Adding New Template Variables
1. **Export variable** in `generate_html.sh` (e.g., `export NEW_VARIABLE="value"`)
2. **Use in template** with `$NEW_VARIABLE` syntax
3. **Test** by running `./scripts/build.sh`

#### Modifying Gallery Layout
1. **CSS changes** go in `static/style.css` 
2. **Grid behavior** controlled by `.gallery-grid` and `.featured-grid` classes
3. **Individual items** styled with `.gallery-item` class
4. **Remember**: Changes affect all gallery types (main, category, tag)

#### Adding New Page Types
1. **Follow the pattern** in `generate_html.sh` after line 317 (tag galleries)
2. **Create data tracking** array (like `TAGS` or `CATEGORIES`)
3. **Generate navigation** links if needed
4. **Export template variables** and use `envsubst` to generate HTML

#### Modifying CSV Schema  
1. **Update parsing** in `generate_html.sh` (line 135 IFS read statement)
2. **Add data storage** to IMAGE_DATA associative array
3. **Export new variables** for templates
4. **Update validation** in `build.sh` if field is required

### Architecture Rules to Follow

#### 1. **Keep It Static**
- **Never add** server-side processing requirements
- **Avoid** dynamic JavaScript that requires build tools
- **Prefer** HTML/CSS solutions over JavaScript

#### 2. **Maintain Bash Compatibility**  
- **Test on** bash 4.0+ (associative array requirement)
- **Use** `set -e` for error handling
- **Validate** all external dependencies (ImageMagick, envsubst)

#### 3. **Responsive Design First**
- **Mobile-first** CSS with progressive enhancement  
- **Test** at breakpoints: 414px, 768px, 1024px, 1440px+
- **Optimize** images for each breakpoint

#### 4. **Data Flow Integrity**
- **CSV** is the source of truth for all metadata
- **Bash arrays** are the intermediate data store  
- **Templates** are pure presentation layer
- **Never** hardcode content in templates

### Testing Your Changes

#### Local Development
```bash
# Full rebuild
./scripts/build.sh

# Test locally
cd build && python3 -m http.server 8000
# Open: http://localhost:8000
```

#### Validation Checklist
- [ ] **CSV parsing** works with your metadata
- [ ] **All gallery types** generate correctly (main, category, tag)
- [ ] **Image navigation** works (prev/next links)
- [ ] **Responsive design** works on mobile/desktop
- [ ] **Build process** completes without errors

### Common Pitfalls to Avoid

#### 1. **CSV Formatting Issues**
- **Always end CSV** with newline (build.sh validates this)
- **No quotes needed** unless field contains commas
- **Empty fields** are OK, but don't leave trailing commas

#### 2. **Template Variable Scope**
- **envsubst sees all** exported environment variables
- **Clear variables** between page types (see line 268 in generate_html.sh)
- **Quote variables** that might contain special characters

#### 3. **Path Handling**
- **BASE_PATH changes** between root pages (`.`) and image pages (`..`)
- **Always use** `$BASE_PATH` in templates for asset references
- **Test** both gallery and image pages after path changes

#### 4. **Associative Array Management**
- **Bash 4.0+ required** for associative arrays
- **Initialize arrays** with `declare -A ARRAY_NAME=()`
- **Keys can't contain** spaces or special characters without quoting

### Performance Considerations

#### Image Optimization
- **85% JPEG quality** balances file size vs. quality
- **Incremental processing** only resizes changed images  
- **5 size variants** cover all screen sizes without over-generating

#### Build Performance
- **Parallel processing** where possible (use `&` for background tasks)
- **Skip unchanged** images in resize script
- **Minimize** string concatenation in bash (expensive)

#### Runtime Performance  
- **Lazy loading** for images below fold
- **Minimal JavaScript** (only 14 lines for keyboard nav)
- **No runtime dependencies** - pure static files

### Future Development Notes

#### Safe to Modify
- **CSS styling** in `static/style.css`
- **Template layout** in `templates/*.tmpl` files
- **CSV schema** (with corresponding code changes)
- **Image sizes** in `resize_images.sh`

#### Modify with Caution
- **Core parsing logic** in `generate_html.sh`
- **Build orchestration** in `build.sh`
- **Base template structure** in `templates/base.html`

#### Avoid Changing
- **ImageMagick commands** (well-tested for quality/performance)
- **envsubst approach** (simple and reliable)
- **Static-first architecture** (fundamental design principle)

This codebase prioritizes **simplicity, maintainability, and performance** over complex features. When adding functionality, always ask: "Can this be done with pure HTML/CSS?" before reaching for JavaScript or additional dependencies.