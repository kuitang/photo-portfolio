#!/bin/bash

# GitHub deployment script
# Copies build output to separate git repository and pushes to GitHub

# Source common library
source "$(dirname "$0")/common.sh"

# Ensure we're in the project root
ensure_project_root

print_section_header "Photography Portfolio - GitHub Deployment"

# Check directories and git repository
check_directory "$BUILD_DIR" "Build directory '$BUILD_DIR' does not exist. Please run './scripts/build.sh' first to generate the site."
check_directory "$DEPLOY_DIR" "Deployment directory '$DEPLOY_DIR' does not exist. Please ensure the photos_website repository is cloned at '../photos_website'"

if ! check_git_repo "$DEPLOY_DIR"; then
    print_error "Deployment directory '$DEPLOY_DIR' is not a git repository."
    exit 1
fi

print_status "Checking deployment repository status..."
cd "$DEPLOY_DIR"

# Check for uncommitted changes
if ! check_git_clean "$DEPLOY_DIR"; then
    print_error "Deployment repository has uncommitted changes."
    print_error "Current status:"
    git status --short
    print_error "Please commit or stash changes before deploying."
    exit 1
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
set_web_permissions "$DEPLOY_DIR"

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

print_section_header "Deployment Complete! 🎉"
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