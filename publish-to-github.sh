#!/bin/bash

# Script to publish the Homebrew tap to GitHub

set -e

echo "Publishing Homebrew tap to GitHub..."

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial Homebrew tap for UptimeSquirrel agent v1.2.9

- Formula for installing UptimeSquirrel agent on macOS
- Support for brew services
- Configuration management
- Network and disk monitoring configuration"

# Add remote
git remote add origin https://github.com/Scripted-Ventures-NZ/homebrew-uptimesquirrel.git

# Push to main branch
git branch -M main
git push -u origin main

echo ""
echo "✅ Published successfully!"
echo ""
echo "Users can now install with:"
echo "  brew tap scripted-ventures-nz/uptimesquirrel"
echo "  brew install uptimesquirrel-agent"