#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "Setting up local development environment for FoodLocker..."

# Configure git to use the tracked .githooks directory
echo "--> Configuring git hooks path..."
git config core.hooksPath .githooks

# Ensure all hooks in .githooks are executable
echo "--> Making git hooks executable..."
chmod +x .githooks/*

echo "Setup completed successfully! Git hooks are now active."
