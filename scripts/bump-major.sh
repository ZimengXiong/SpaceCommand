#!/bin/bash

source ../version.txt

IFS='.' read -r -a version_parts <<< "$VERSION"
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

new_major=$((major + 1))
new_version="${new_major}.0.0"

sed -i '' "s/VERSION=.*/VERSION=$new_version/" ../version.txt

./sync-version.sh

echo "Bumped major version from $VERSION to $new_version"