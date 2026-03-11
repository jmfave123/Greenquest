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
SEMAPHORE_API_KEY=${SEMAPHORE_API_KEY}
VERCEL_BASE_URL=${VERCEL_BASE_URL}
EMAILJS_SERVICE_ID=${EMAILJS_SERVICE_ID}
EMAILJS_TEMPLATE_APPROVED_ID=${EMAILJS_TEMPLATE_APPROVED_ID}
EMAILJS_TEMPLATE_REJECTED_ID=${EMAILJS_TEMPLATE_REJECTED_ID}
EMAILJS_PUBLIC_KEY=${EMAILJS_PUBLIC_KEY}
EMAILJS_PRIVATE_KEY=${EMAILJS_PRIVATE_KEY}
RESEND_API_KEY=${RESEND_API_KEY}

EOF

echo ".env file created"

# Install API dependencies
echo "Installing API dependencies..."
cd api && npm install --production && cd ..

# Install dependencies  
echo "Getting dependencies..."
flutter pub get

# Build the web app
echo "Building web app..."
flutter build web --release

# Verify build output
echo "Build completed. Contents of build/web:"
ls -la build/web
