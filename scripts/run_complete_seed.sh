#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Flutter Storefront V2 - Complete Seeder${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}\n"

# Check if Firestore emulator is running
echo -e "${YELLOW}Checking Firestore emulator...${NC}"
EMULATOR_HOST="${EMULATOR_HOST:-127.0.0.1}"
EMULATOR_PORT="${EMULATOR_PORT:-8080}"

if ! curl -s "http://${EMULATOR_HOST}:${EMULATOR_PORT}" > /dev/null 2>&1; then
    echo -e "${RED}❌ Firestore emulator is not running!${NC}"
    echo -e "${YELLOW}Please start the emulator first:${NC}"
    echo -e "   firebase emulators:start --only firestore"
    echo -e "\nOr if running in the background:"
    echo -e "   firebase emulators:start --only firestore &"
    exit 1
fi

echo -e "${GREEN}✅ Firestore emulator is running${NC}\n"

# Detect dart executable
DART_CMD=""
if command -v dart &> /dev/null; then
    DART_CMD="dart"
elif command -v flutter &> /dev/null; then
    # Use Flutter's bundled Dart
    DART_CMD="flutter pub run"
    echo -e "${YELLOW}ℹ️  Using Flutter's bundled Dart${NC}"
else
    echo -e "${RED}❌ Neither 'dart' nor 'flutter' command found!${NC}"
    echo -e "${YELLOW}Please install Flutter or Dart SDK${NC}"
    exit 1
fi

# Get project ID
FIREBASE_PROJECT="${FIREBASE_PROJECT:-demo-project}"
if [ ! -z "$1" ]; then
    FIREBASE_PROJECT="$1"
fi

echo -e "${BLUE}Project:${NC} ${FIREBASE_PROJECT}"
echo -e "${BLUE}Emulator:${NC} ${EMULATOR_HOST}:${EMULATOR_PORT}\n"

# Run the seeder
echo -e "${YELLOW}Starting seeder...${NC}\n"

if [ "$DART_CMD" == "dart" ]; then
    dart scripts/seed_firestore_complete.dart --project="${FIREBASE_PROJECT}"
else
    # For flutter pub run, we need to be more careful
    flutter run --no-pub scripts/seed_firestore_complete.dart --project="${FIREBASE_PROJECT}"
fi

SEED_EXIT_CODE=$?

if [ $SEED_EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Seeding completed successfully!${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}\n"
else
    echo -e "\n${RED}════════════════════════════════════════${NC}"
    echo -e "${RED}❌ Seeding failed with exit code ${SEED_EXIT_CODE}${NC}"
    echo -e "${RED}════════════════════════════════════════${NC}\n"
    exit $SEED_EXIT_CODE
fi
