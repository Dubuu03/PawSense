#!/bin/bash

# Firebase Cloud Functions Deployment Script for PawSense

echo "🚀 Deploying PawSense Cloud Functions..."
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI is not installed."
    echo "📦 Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in
echo "🔐 Checking Firebase authentication..."
firebase projects:list &> /dev/null
if [ $? -ne 0 ]; then
    echo "❌ Not logged in to Firebase."
    echo "🔑 Please run: firebase login"
    exit 1
fi

echo "✅ Firebase CLI is ready"
echo ""

# Navigate to functions directory
cd functions

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed"
    echo ""
fi

# Go back to root
cd ..

# Deploy functions
echo "🚀 Deploying Cloud Functions to Firebase..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Test the password reset flow in your app"
    echo "2. Monitor function logs: firebase functions:log"
    echo "3. Check Firebase Console for function status"
    echo ""
else
    echo "❌ Deployment failed. Check the error messages above."
    exit 1
fi
