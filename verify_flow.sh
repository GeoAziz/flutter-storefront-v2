#!/bin/bash
set -euo pipefail

echo "=== VERIFYING DATA FLOW ==="

# 1. Check provider returns correct repository type
echo "1. Checking provider configuration..."
if [ -f lib/repository/repository_providers.dart ]; then
  grep -n "FirestoreProductRepository" lib/repository/repository_providers.dart || true
fi
# also check the actual providers path
grep -n "FirestoreProductRepository" lib/providers/repository_providers.dart || true

# 2. Check FilterParams usage
echo "2. Checking FilterParams integration..."
grep -r "FilterParams" lib/screens/ | grep -v ".g.dart" || true

# 3. Check pagination provider
echo "3. Checking pagination provider..."
grep -n "Provider.family" lib/providers/ | head -5 || true

# 4. Run critical unit tests (if present)
echo "4. Running critical tests..."
flutter test test/route_test.dart test/cart_provider_test.dart || true

echo "=== VERIFICATION COMPLETE ==="
