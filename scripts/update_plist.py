#!/usr/bin/env python3

import sys
import plistlib
import xml.etree.ElementTree as ET

def update_plist_file(plist_path, version, build):
    try:
        with open(plist_path, 'rb') as f:
            plist_data = plistlib.load(f)

        plist_data['CFBundleVersion'] = version
        plist_data['CFBundleShortVersionString'] = version

        with open(plist_path, 'wb') as f:
            plistlib.dump(plist_data, f)

        print(f"Updated {plist_path} to version {version}")
        return True
    except Exception as e:
        print(f"Error updating {plist_path}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: update_plist.py <plist_file> <version> <build>")
        sys.exit(1)

    plist_file = sys.argv[1]
    version = sys.argv[2]
    build = sys.argv[3]

    success = update_plist_file(plist_file, version, build)
    sys.exit(0 if success else 1)