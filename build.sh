#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Install Flutter if not found
if ! command -v flutter &> /dev/null
then
    echo "📥 Installing Flutter..."
    
    # Download Flutter SDK
    FLUTTER_VERSION="3.24.3"
    cd /tmp
    curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz
    tar xf flutter.tar.xz
    export PATH="$PATH:/tmp/flutter/bin"
    
    echo "✅ Flutter installed"
else
    echo "✅ Flutter found: $(flutter --version | head -n 1)"
fi

# Ensure Flutter is in PATH
export PATH="$PATH:/tmp/flutter/bin"

# Verify we're in the right directory
echo "📁 Current directory: $(pwd)"

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release --base-href /

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"
