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