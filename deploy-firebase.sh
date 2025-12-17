#!/bin/bash

# Firebase Deploy Script for PoAFix E-Commerce App
# This script handles Firebase rule deployment and configuration

set -e

PROJECT_ID="poafix"
RULES_FILE="lib/config/firestore.rules"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Firebase Deployment Script for PoAFix E-Commerce          ║"
echo "║  Project ID: $PROJECT_ID"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed."
    echo ""
    echo "Install Firebase CLI with:"
    echo "  npm install -g firebase-tools"
    echo ""
    exit 1
fi

echo "✅ Firebase CLI found: $(firebase --version)"
echo ""

# Check if rules file exists
if [ ! -f "$RULES_FILE" ]; then
    echo "❌ Rules file not found: $RULES_FILE"
    exit 1
fi

echo "✅ Rules file found: $RULES_FILE"
echo ""

# Login to Firebase
echo "📝 Checking Firebase authentication..."
if ! firebase projects:list --token "$(firebase login:ci --interactive 2>/dev/null)" > /dev/null 2>&1; then
    echo "📝 Please log in to Firebase:"
    firebase login
fi

echo "✅ Firebase authenticated"
echo ""

# Select project
echo "🎯 Setting project to: $PROJECT_ID"
firebase use "$PROJECT_ID" || {
    echo "❌ Failed to select project. Available projects:"
    firebase projects:list
    exit 1
}

echo "✅ Project set to: $PROJECT_ID"
echo ""

# Deploy rules
echo "🚀 Deploying Firestore Security Rules..."
echo "   Rules file: $RULES_FILE"
echo ""

if firebase deploy --only firestore:rules; then
    echo ""
    echo "✅ Firestore Security Rules deployed successfully!"
    echo ""
else
    echo ""
    echo "❌ Failed to deploy Firestore Security Rules"
    echo ""
    exit 1
fi

# Create indexes
echo "📊 Checking for required indexes..."
echo ""
echo "ℹ️  If Firestore suggests creating indexes, you'll see them in the console:"
echo "   - Go to: https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo "   - Navigate to: Indexes → Composite Indexes"
echo "   - Create any suggested indexes for better query performance"
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT COMPLETE                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  Project ID: $PROJECT_ID"
echo "  Rules File: $RULES_FILE"
echo "  Status: ✅ Deployed"
echo ""
echo "Next Steps:"
echo "  1. Verify rules in Firebase Console"
echo "  2. Test authentication flows"
echo "  3. Monitor Firestore operations"
echo ""
echo "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
