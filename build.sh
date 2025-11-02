#!/bin/bash
set -e

# Debug info
echo "=== Starting Flutter Web Build ==="
echo "Current directory: $(pwd)"
echo "Home directory: $HOME"

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
  echo "Flutter is already installed"
  flutter --version
else
  echo "Installing Flutter..."
  # Use a more reliable installation path
  FLUTTER_INSTALL_DIR="$HOME/flutter"
  
  # Remove existing installation if it exists
  if [ -d "$FLUTTER_INSTALL_DIR" ]; then
    echo "Removing existing Flutter installation..."
    rm -rf "$FLUTTER_INSTALL_DIR"
  fi
  
  # Clone Flutter with error handling
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_INSTALL_DIR" || {
    echo "Failed to clone Flutter. Trying with full history..."
    rm -rf "$FLUTTER_INSTALL_DIR"
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_INSTALL_DIR"
  }
  
  export PATH="$PATH:$FLUTTER_INSTALL_DIR/bin"
  
  # Verify Flutter installation
  echo "Verifying Flutter installation..."
  flutter --version || {
    echo "ERROR: Flutter installation failed!"
    exit 1
  }
  
  # Accept licenses
  echo "Accepting Flutter licenses..."
  flutter doctor --android-licenses || true
  
  # Run Flutter doctor to check setup
  echo "Running Flutter doctor..."
  flutter doctor || true
fi

# Enable Flutter web
echo "Enabling Flutter web..."
flutter config --enable-web

# Install dependencies
echo "Getting Flutter dependencies..."
flutter pub get || {
  echo "ERROR: Failed to get dependencies!"
  exit 1
}

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean || true

# Build the web app with verbose output
echo "Building web app (this may take several minutes)..."
flutter build web --release --base-href / || {
  echo "ERROR: Build failed!"
  echo "Build logs:"
  flutter build web --release --base-href / --verbose 2>&1 | tail -50
  exit 1
}

# Verify build output
echo "=== Build completed successfully ==="
echo "Checking build output..."
if [ -d "build/web" ]; then
  echo "Contents of build/web:"
  ls -la build/web
  echo "Build output size:"
  du -sh build/web
else
  echo "ERROR: build/web directory not found!"
  exit 1
fi

echo "=== Build script completed ==="
