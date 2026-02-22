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

# Create .env file from Vercel environment variables
echo "Creating .env file from environment variables..."
cat > .env << EOF
SMS_CHEF_API_KEY=${SMS_CHEF_API_KEY}
DEVICE_ID=${DEVICE_ID}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY}
CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET}
ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}
EOF

echo ".env file created"

# Install dependencies  
echo "Getting dependencies..."
flutter pub get

# Build the web app
echo "Building web app..."
flutter build web --release

# Verify build output
echo "Build completed. Contents of build/web:"
ls -la build/web
