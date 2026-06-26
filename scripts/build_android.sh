#!/usr/bin/env bash
# Production Android build script for LGBTFinder (Linux/macOS/CI).
# Usage: ./scripts/build_android.sh [--skip-tests] [--skip-analyze]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

SKIP_TESTS=false
SKIP_ANALYZE=false
DO_CLEAN=false
for arg in "$@"; do
  case "${arg}" in
    --skip-tests) SKIP_TESTS=true ;;
    --skip-analyze) SKIP_ANALYZE=true ;;
    --clean) DO_CLEAN=true ;;
    *) echo "Unknown option: ${arg}" >&2; exit 1 ;;
  esac
done

BUILD_START=$(date +%s)
SUMMARY_FILE="${PROJECT_ROOT}/build/releases/build-summary.txt"
mkdir -p "${PROJECT_ROOT}/build/releases/apk" "${PROJECT_ROOT}/build/releases/aab"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { log "ERROR: $*"; exit 1; }

# Optional China mirrors (set PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL in env if needed)
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.dev}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.googleapis.com}"

log "=== LGBTFinder Android Build ==="
log "Project: ${PROJECT_ROOT}"

FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -n 1 || echo "unknown")
log "Flutter: ${FLUTTER_VERSION}"

log "Step 1/7: Clean"
if [[ "${DO_CLEAN}" == "true" ]]; then
  flutter clean
else
  log "Skipping clean (pass --clean to enable)"
fi

log "Step 2/7: Dependencies"
flutter pub get

ANALYZE_STATUS="skipped"
if [[ "${SKIP_ANALYZE}" == "false" ]]; then
  log "Step 3/7: Static analysis (lib/)"
  if flutter analyze lib/ --no-fatal-infos --no-fatal-warnings; then
    ANALYZE_STATUS="passed"
  else
    ANALYZE_STATUS="completed with issues (non-blocking)"
    log "WARN: flutter analyze reported issues"
  fi
else
  log "Step 3/7: Static analysis skipped"
fi

TEST_STATUS="skipped"
TEST_DETAILS=""
if [[ "${SKIP_TESTS}" == "false" ]]; then
  log "Step 4/7: Unit tests"
  set +e
  TEST_OUTPUT=$(flutter test test/unit/ 2>&1)
  TEST_EXIT=$?
  set -e
  echo "${TEST_OUTPUT}"
  TEST_DETAILS=$(echo "${TEST_OUTPUT}" | tail -n 3)
  if [[ ${TEST_EXIT} -eq 0 ]]; then
    TEST_STATUS="passed"
  else
    TEST_STATUS="failed (${TEST_DETAILS})"
    fail "Unit tests failed"
  fi
else
  log "Step 4/7: Unit tests skipped"
fi

log "Step 5/7: Split release APKs (armeabi-v7a, arm64-v8a, x86_64)"
flutter build apk --release --split-per-abi

log "Step 6/7: Release App Bundle"
flutter build appbundle --release

log "Step 7/7: Collect artifacts"
APK_SRC="${PROJECT_ROOT}/build/app/outputs/flutter-apk"
AAB_SRC="${PROJECT_ROOT}/build/app/outputs/bundle/release"

cp -f "${APK_SRC}"/app-*-release.apk "${PROJECT_ROOT}/build/releases/apk/" 2>/dev/null || true
if [[ -f "${APK_SRC}/app-release.apk" ]]; then
  cp -f "${APK_SRC}/app-release.apk" "${PROJECT_ROOT}/build/releases/apk/"
fi
cp -f "${AAB_SRC}/app-release.aab" "${PROJECT_ROOT}/build/releases/aab/"

BUILD_END=$(date +%s)
DURATION=$((BUILD_END - BUILD_START))

{
  echo "LGBTFinder Android Build Summary"
  echo "================================"
  echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Flutter: ${FLUTTER_VERSION}"
  echo "Duration: ${DURATION}s"
  echo "Analyze: ${ANALYZE_STATUS}"
  echo "Tests: ${TEST_STATUS}"
  echo ""
  echo "APK artifacts:"
  ls -lh "${PROJECT_ROOT}/build/releases/apk/" 2>/dev/null || echo "  (none)"
  echo ""
  echo "AAB artifacts:"
  ls -lh "${PROJECT_ROOT}/build/releases/aab/" 2>/dev/null || echo "  (none)"
} | tee "${SUMMARY_FILE}"

log "Build complete in ${DURATION}s"
log "Artifacts: build/releases/apk/ and build/releases/aab/"
log "Summary: ${SUMMARY_FILE}"
