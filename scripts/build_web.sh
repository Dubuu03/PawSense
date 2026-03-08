#!/bin/bash
set -e

echo "=== PawSense Web Build Script for Vercel ==="

# Step 1: Install Flutter SDK
echo ">>> Installing Flutter SDK..."
if [ ! -d "flutter" ]; then
  curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.5-stable.tar.xz -o flutter.tar.xz
  tar xf flutter.tar.xz
  rm flutter.tar.xz
fi
git config --global --add safe.directory "$(pwd)/flutter"
export PATH="$PATH:$(pwd)/flutter/bin"

echo ">>> Flutter version:"
flutter --version

# Step 2: Generate .env file from Vercel environment variables
echo ">>> Generating .env file from environment variables..."
cat > .env << EOF
FIREBASE_WEB_API_KEY=${FIREBASE_WEB_API_KEY}
FIREBASE_WEB_APP_ID=${FIREBASE_WEB_APP_ID}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET}
FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID}
FIREBASE_ANDROID_API_KEY=${FIREBASE_ANDROID_API_KEY:-unused}
FIREBASE_ANDROID_APP_ID=${FIREBASE_ANDROID_APP_ID:-unused}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_UPLOAD_PRESET=${CLOUDINARY_UPLOAD_PRESET}
EOF

echo ">>> .env file created with keys:"
grep -oP '^[^=]+' .env

# Step 3: Get dependencies
echo ">>> Getting Flutter dependencies..."
flutter pub get

# Step 4: Build Flutter web
echo ">>> Building Flutter web (release)..."
flutter build web --release --web-renderer canvaskit --no-tree-shake-icons

# Step 5: Remove unnecessary large assets from web build
# The ONNX model (99MB) is not used in the web admin pages
echo ">>> Removing unused model assets from web build..."
rm -rf build/web/assets/assets/models
echo ">>> Model assets removed to reduce deployment size."

# Step 6: Report build output size
echo ">>> Build output size:"
du -sh build/web
echo ">>> Build complete!"
