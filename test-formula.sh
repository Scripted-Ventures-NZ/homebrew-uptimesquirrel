#!/bin/bash

# Test script for the Homebrew formula

set -e

echo "Testing UptimeSquirrel Homebrew formula..."

# Check if formula file exists
if [ ! -f "Formula/uptimesquirrel-agent.rb" ]; then
    echo "Error: Formula file not found!"
    exit 1
fi

# Validate Ruby syntax
echo "Checking Ruby syntax..."
ruby -c Formula/uptimesquirrel-agent.rb

# Check with brew
echo "Auditing formula with brew..."
brew audit --strict Formula/uptimesquirrel-agent.rb || true

echo ""
echo "Formula validation complete!"
echo ""
echo "To test installation:"
echo "  brew install --build-from-source ./Formula/uptimesquirrel-agent.rb"
echo ""
echo "To test as a tap:"
echo "  brew tap local/test $PWD"
echo "  brew install local/test/uptimesquirrel-agent"
echo "  brew untap local/test"