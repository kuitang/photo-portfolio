#!/bin/bash

# GitHub deployment script
# Copies build output to separate git repository and pushes to GitHub

set -e

# Configuration
BUILD_DIR="build"
DEPLOY_DIR="../photos_website"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

print_header "Photography Portfolio - GitHub Deployment"
echo "========================================================"

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    print_error "Build directory '$BUILD_DIR' does not exist."
    print_error "Please run './scripts/build.sh' first to generate the site."
    exit 1
fi

# Check if deployment directory exists
if [ ! -d "$DEPLOY_DIR" ]; then
    print_error "Deployment directory '$DEPLOY_DIR' does not exist."
    print_error "Please ensure the photos_website repository is cloned at '../photos_website'"
    exit 1
fi

# Check if deployment directory is a git repository
if [ ! -d "$DEPLOY_DIR/.git" ]; then
    print_error "Deployment directory '$DEPLOY_DIR' is not a git repository."
    exit 1
fi

print_status "Checking deployment repository status..."
cd "$DEPLOY_DIR"

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
    print_warning "Deployment repository has uncommitted changes."
    print_warning "Current status:"
    git status --short
    echo ""
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
fi

# Go back to source directory
cd - > /dev/null

print_status "Copying build files to deployment directory..."

# Remove existing files (except .git and .gitignore)
find "$DEPLOY_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' ! -name '.gitignore' ! -name 'README.md' -exec rm -rf {} +

# Copy build files, dereferencing symlinks
print_status "Copying files (dereferencing symlinks)..."
cp -rL "$BUILD_DIR"/* "$DEPLOY_DIR"/

# Ensure proper permissions
chmod -R 755 "$DEPLOY_DIR"
find "$DEPLOY_DIR" -type f -name "*.html" -o -name "*.css" -o -name "*.js" | xargs chmod 644
find "$DEPLOY_DIR" -type f -name "*.jpg" -o -name "*.png" -o -name "*.gif" | xargs chmod 644

print_status "Files copied successfully"

# Change to deployment directory
cd "$DEPLOY_DIR"

# Add all files
print_status "Staging files for commit..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    print_warning "No changes to commit. Site is already up to date."
    exit 0
fi

# Generate commit message
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
IMAGE_COUNT=$(find . -name "*.jpg" -type f | grep -E "(thumb|small|medium|large|xlarge)" | wc -l)
PAGE_COUNT=$(find . -name "*.html" -type f | wc -l)

COMMIT_MSG="Update photography portfolio - $TIMESTAMP

- $PAGE_COUNT HTML pages
- $((IMAGE_COUNT / 5)) photos with multiple sizes
- Generated from photos repository

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Create commit
print_status "Creating commit..."
git commit -m "$COMMIT_MSG"

# Push to GitHub
print_status "Pushing to GitHub..."
if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
    print_status "Successfully pushed to GitHub!"
else
    print_error "Failed to push to GitHub. Please check your remote configuration."
    print_error "You may need to run: git remote -v"
    exit 1
fi

# Get the repository URL for user reference
REPO_URL=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's/git@github\.com:/https:\/\/github.com\//')

print_header "Deployment Complete! 🎉"
echo ""
print_status "Your photography portfolio has been deployed to GitHub."
if [ -n "$REPO_URL" ]; then
    print_status "Repository: $REPO_URL"
    print_status "GitHub Pages: ${REPO_URL/github.com/}.github.io"
fi
echo ""
print_status "Changes committed: $(git rev-parse --short HEAD)"
print_status "Deployment completed at: $TIMESTAMP"

exit 0