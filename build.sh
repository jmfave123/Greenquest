#!/bin/bash
set -e

# Debug info
echo "Starting build process..."
echo "Current directory: $(pwd)"
ls -la

# Install Flutter
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation
echo "Flutter version:"
flutter --version

# Install dependencies
echo "Getting dependencies..."
flutter pub get

# Build the web app
echo "Building web app..."
flutter build web --release

# Verify build output
echo "Build completed. Contents of build/web:"
ls -la build/web
