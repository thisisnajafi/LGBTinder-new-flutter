#!/bin/sh
# Copies the flavor GoogleService-Info.plist into the built app and, when the
# real Firebase file contains them, writes the Google Sign-In URL scheme.
# Fails closed: a missing flavor or a placeholder plist stops the build.
set -e

if [ -z "${APP_FLAVOR}" ]; then
  echo "error: APP_FLAVOR is not set. Use --flavor development, staging, or production."
  exit 1
fi

SRC="${SRCROOT}/config/${APP_FLAVOR}/GoogleService-Info.plist"
if [ ! -f "${SRC}" ]; then
  echo "error: Missing ${SRC}"
  echo "error: Download it from Firebase and do not commit the real file."
  exit 1
fi

if grep -q "REPLACE_WITH_FIREBASE_PROJECT_ID" "${SRC}"; then
  echo "error: ${SRC} is still a placeholder."
  exit 1
fi

DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
mkdir -p "${DEST}"
cp "${SRC}" "${DEST}/GoogleService-Info.plist"

PLIST="${DEST}/Info.plist"
if [ ! -f "${PLIST}" ]; then
  echo "Copied GoogleService-Info.plist for ${APP_FLAVOR} (Info.plist not ready for URL scheme)."
  exit 0
fi

REVERSED=$(/usr/libexec/PlistBuddy -c 'Print :REVERSED_CLIENT_ID' "${SRC}" 2>/dev/null || true)
if [ -n "${REVERSED}" ]; then
  /usr/libexec/PlistBuddy -c 'Delete :CFBundleURLTypes' "${PLIST}" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes array' "${PLIST}"
  /usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0 dict' "${PLIST}"
  /usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLName string google-sign-in' "${PLIST}"
  /usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes array' "${PLIST}"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string ${REVERSED}" "${PLIST}"
fi

CLIENT_ID=$(/usr/libexec/PlistBuddy -c 'Print :CLIENT_ID' "${SRC}" 2>/dev/null || true)
if [ -n "${CLIENT_ID}" ]; then
  /usr/libexec/PlistBuddy -c 'Delete :GIDClientID' "${PLIST}" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :GIDClientID string ${CLIENT_ID}" "${PLIST}"
fi

echo "Copied GoogleService-Info.plist for ${APP_FLAVOR}"
