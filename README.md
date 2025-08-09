# Photography Portfolio Static Site Generator

A zero-dependency static photography portfolio website generator using only HTML, CSS, Bash, and ImageMagick.

## Features

- **No JavaScript Required**: Pure HTML/CSS frontend
- **Responsive Design**: Optimized for all devices including Apple Retina displays
- **Automatic Image Resizing**: Multiple resolutions generated from source images
- **Template-Based**: Simple templating using `envsubst`
- **Fast Static Site**: No server-side processing required
- **Clean Design**: Minimalist black, white, and grey aesthetic with Helvetica typography

## Prerequisites

Install these tools before using the site generator:

```bash
# Ubuntu/Debian
sudo apt-get install imagemagick gettext

# macOS
brew install imagemagick gettext

# RHEL/CentOS/Fedora
sudo yum install ImageMagick gettext
```

## Quick Start

### 1. Add Your Photos

Place your high-resolution JPEG images in the `originals/` directory:

```bash
cp /path/to/your/photos/*.jpg originals/
```

### 2. Create Metadata CSV

Edit `originals/metadata.csv` with your image information:

```csv
filename,title,year,location,camera,lens,film,developer,description,tags,category
IMG_001.jpg,Sunset at Beach,2024,Santa Monica CA,Canon R5,RF 24-70mm,Portra 400,C-41,Golden hour capture at the pier,sunset beach landscape,Landscapes
```

**CSV Columns:**
- `filename`: Image filename in originals/ directory (required)
- `title`: Display title for the image (required)
- `year`: Year taken (as string, e.g., "2024" or "2023-2024", optional)
- `location`: Where the photo was taken (optional)
- `camera`: Camera model used (optional)
- `lens`: Lens used (optional)
- `film`: Film stock or digital sensor info (optional)
- `developer`: Film developer or processing info (optional)
- `description`: Detailed description of the image (optional)
- `tags`: Space-separated tags (optional)
- `category`: Main category for organization (optional)

**Note:** All fields except filename and title can be left empty. Do not use quotes in the CSV unless the field itself contains a comma.

### 3. Build the Site

Run the build script to resize images and generate HTML:

```bash
./scripts/build.sh
```

This will:
1. Validate your CSV metadata
2. Resize all images to multiple sizes (thumbnail, small, medium, large, xlarge)
3. Generate all HTML pages
4. Create a complete static site in the `build/` directory

## Common Commands

### Full Build
```bash
./scripts/build.sh
```
Runs the complete build process: resizes images and generates HTML.

### Clean Build
```bash
./scripts/build.sh clean
./scripts/build.sh
```
Removes all generated files and rebuilds from scratch.

### Resize Images Only
```bash
./scripts/build.sh images
```
Only processes images without regenerating HTML.

### Generate HTML Only
```bash
./scripts/build.sh html
```
Only regenerates HTML without reprocessing images.

### View Help
```bash
./scripts/build.sh help
```

## Updating the Site

### Adding New Photos

1. Copy new photos to `originals/`:
```bash
cp new-photo.jpg originals/
```

2. Add metadata to `originals/metadata.csv`:
```bash
echo 'new-photo.jpg,Photo Title,2024,Location,Camera,Lens,Film,Developer,Description,tag1 tag2,Category' >> originals/metadata.csv
```

3. Rebuild the site:
```bash
./scripts/build.sh
```

### Updating Photo Information

1. Edit `originals/metadata.csv` with your changes
2. Regenerate HTML only (faster):
```bash
./scripts/build.sh html
```

### Removing Photos

1. Delete the image from `originals/`
2. Remove the corresponding line from `originals/metadata.csv`
3. Clean and rebuild:
```bash
./scripts/build.sh clean
./scripts/build.sh
```

## Viewing the Site Locally

After building, serve the site locally:

```bash
# Python 3
cd build && python3 -m http.server 8000

# PHP
cd build && php -S localhost:8000

# Node.js
cd build && npx serve
```

Then open http://localhost:8000 in your browser.

## Deployment

The `build/` directory contains your complete static website. Deploy it to any static hosting service:

### GitHub Pages (Automated)
Use the included deployment script to automatically publish to GitHub:

```bash
./scripts/deploy_github.sh
```

This script will:
1. Copy all build files to `../photos_website` directory (dereferencing symlinks)
2. Create an automated commit with photo/page counts
3. Push to GitHub automatically

**Prerequisites:**
- Clone your GitHub Pages repository to `../photos_website` 
- Ensure the repository has a configured remote origin

### GitHub Pages (Manual)
```bash
# Copy build contents to your github.io repository
cp -r build/* /path/to/username.github.io/
cd /path/to/username.github.io/
git add .
git commit -m "Update portfolio"
git push
```

### Netlify
1. Drag and drop the `build/` folder to Netlify
2. Or use Netlify CLI: `netlify deploy --dir=build`

### Traditional Web Hosting
Upload the contents of `build/` to your web server's public directory via FTP/SFTP.

## Customization

### Site Configuration

Edit variables in `scripts/generate_html.sh`:
```bash
export SITE_TITLE="Your Portfolio Name"
export SITE_DESCRIPTION="Your portfolio description"
```

### Styling

Modify `static/style.css` to customize:
- Colors
- Typography  
- Layout
- Responsive breakpoints

### Templates

Edit HTML templates in `templates/` directory:
- `base.html` - Main layout template
- `index.html.tmpl` - Homepage template
- `gallery.html.tmpl` - Gallery page template
- `image.html.tmpl` - Individual image page template

## Performance Tips

1. **Initial Build**: First build will take longer as all images need resizing
2. **Incremental Updates**: Subsequent builds skip unchanged images
3. **HTML-Only Updates**: Use `./scripts/build.sh html` when only updating metadata
4. **Image Optimization**: Source images around 3-5MB JPEG work best

## Troubleshooting

### Build Script Fails
- Check that ImageMagick and gettext are installed
- Ensure CSV format matches the template exactly
- Verify all images referenced in CSV exist in `originals/`

### Images Not Displaying
- Check browser console for 404 errors
- Verify symlinks were created: `ls -la build/`
- Ensure image filenames match exactly in CSV (case-sensitive)

### Site Looks Broken
- Clear browser cache
- Check that `style.css` copied to `build/`
- Verify all template variables are set correctly

## Project Structure

```
photos/
├── originals/              # Your original photos go here
│   └── metadata.csv        # Image metadata
├── resized/                # Auto-generated resized images
│   ├── thumb/
│   ├── small/
│   ├── medium/
│   ├── large/
│   └── xlarge/
├── templates/              # HTML templates
├── static/                 # CSS and static assets
│   └── style.css
├── scripts/                # Build scripts
│   ├── build.sh           # Main build orchestrator
│   ├── resize_images.sh   # Image processing
│   ├── generate_html.sh   # HTML generation
│   └── deploy_github.sh   # GitHub deployment
├── build/                  # Generated static site
└── CLAUDE.md              # Technical documentation
```

## License

This project is provided as-is for personal and commercial use.