#!/bin/bash

# Script to update the Homebrew formula with new version and SHA256

set -e

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.9"
    exit 1
fi

echo "Updating Homebrew formula for version $VERSION..."

# Download the agent file
AGENT_URL="https://app.uptimesquirrel.com/downloads/agent/uptimesquirrel_agent_macos.py"
TEMP_FILE="/tmp/uptimesquirrel_agent_macos.py"

echo "Downloading agent from $AGENT_URL..."
curl -sL "$AGENT_URL" -o "$TEMP_FILE"

# Calculate SHA256
SHA256=$(shasum -a 256 "$TEMP_FILE" | awk '{print $1}')
echo "SHA256: $SHA256"

# Update the formula
FORMULA_FILE="Formula/uptimesquirrel-agent.rb"

# Update version
sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$FORMULA_FILE"

# Update SHA256
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$FORMULA_FILE"

echo "Formula updated successfully!"
echo ""
echo "Next steps:"
echo "1. Test the formula locally:"
echo "   brew install --build-from-source ./Formula/uptimesquirrel-agent.rb"
echo ""
echo "2. Commit and push the changes:"
echo "   git add Formula/uptimesquirrel-agent.rb"
echo "   git commit -m \"Update to version $VERSION\""
echo "   git push"
echo ""
echo "3. Create a GitHub release with tag v$VERSION"

# Clean up
rm -f "$TEMP_FILE"