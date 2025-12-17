#!/bin/bash

###############################################################################
# Phase 1: Firebase Auth + E2E Tests Runner
# Run this script locally in a terminal where emulators are accessible
###############################################################################

set -e  # Exit on any error

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Phase 1: Firebase Auth E2E Test Runner             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if emulators are running
echo "📋 Checking Firebase Emulator status..."
if ! nc -z 127.0.0.1 8080 2>/dev/null; then
    echo "⚠️  Firestore Emulator not running on 127.0.0.1:8080"
    echo "    Start emulators in another terminal:"
    echo "    firebase emulators:start --only firestore,auth --project demo-no-project"
    exit 1
fi

if ! nc -z 127.0.0.1 9099 2>/dev/null; then
    echo "⚠️  Auth Emulator not running on 127.0.0.1:9099"
    echo "    Start emulators in another terminal:"
    echo "    firebase emulators:start --only firestore,auth --project demo-no-project"
    exit 1
fi

echo "✅ Emulators running (Firestore:8080, Auth:9099)"
echo ""

# Run static analysis
echo "📊 Running static analysis..."
if flutter analyze --no-pub 2>&1 | grep -q "error"; then
    echo "❌ Compilation errors found"
    flutter analyze --no-pub
    exit 1
fi
echo "✅ No compilation errors"
echo ""

# Run E2E tests
echo "🧪 Running E2E tests (10 flows)..."
echo "   Timeout: 120s per test"
echo ""

if flutter test test/e2e_user_flows_test.dart --timeout=120s -r expanded; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ ALL TESTS PASSED                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Phase 1 Implementation Verified:"
    echo "  ✅ Firebase Authentication (email/password)"
    echo "  ✅ User document creation (users/{uid})"
    echo "  ✅ Auth state persistence"
    echo "  ✅ Protected routes (cart guard)"
    echo "  ✅ UI error handling (friendly messages)"
    echo "  ✅ E2E flows 1-10 all pass"
    echo ""
    exit 0
else
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   ❌ SOME TESTS FAILED                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Copy the failing test output above"
    echo "  2. Paste it in the GitHub discussion or share with developer"
    echo "  3. Developer will fix the test/rule and push an update"
    echo ""
    exit 1
fi
