#!/bin/bash

source ../version.txt

IFS='.' read -r -a version_parts <<< "$VERSION"
major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}

new_patch=$((patch + 1))
new_version="${major}.${minor}.${new_patch}"

sed -i '' "s/VERSION=.*/VERSION=$new_version/" ../version.txt

./sync-version.sh

echo "Bumped patch version from $VERSION to $new_version"