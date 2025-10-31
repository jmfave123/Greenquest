#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release --base-href /

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web"

