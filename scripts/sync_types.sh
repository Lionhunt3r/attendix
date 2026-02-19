#!/bin/bash
# Sync TypeScript types from Ionic project to Dart/Flutter
# 
# Usage:
#   ./scripts/sync_types.sh
#
# This script:
# 1. Converts TypeScript interfaces to Dart/Freezed models
# 2. Runs build_runner to generate freezed code
#
# Prerequisites:
# - The Ionic project should be at ../attendance relative to this project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IONIC_INTERFACES="../attendance/src/app/utilities/interfaces.ts"
OUTPUT_DIR="lib/data/models/generated"

cd "$PROJECT_DIR"

echo "🔄 Syncing TypeScript types to Dart..."
echo ""

# Check if TypeScript file exists
if [ ! -f "$IONIC_INTERFACES" ]; then
    echo "❌ Error: TypeScript interfaces file not found at $IONIC_INTERFACES"
    echo "   Make sure the Ionic project is at ../attendance"
    exit 1
fi

# Step 1: Convert TypeScript to Dart
echo "📝 Step 1: Converting TypeScript interfaces to Dart..."
dart run scripts/ts_to_dart_converter.dart "$IONIC_INTERFACES" "$OUTPUT_DIR"

# Step 2: Run build_runner
echo ""
echo "🔧 Step 2: Running build_runner to generate freezed code..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Type synchronization complete!"
echo ""
echo "Generated models are in: $OUTPUT_DIR"
echo ""
echo "Note: The generated models are separate from your existing models."
echo "You can use them as reference or replace your existing models."