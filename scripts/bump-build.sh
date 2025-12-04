#!/bin/bash

source ../version.txt

new_build=$((BUILD + 1))

sed -i '' "s/BUILD=.*/BUILD=$new_build/" ../version.txt

./sync-version.sh

echo "Bumped build number from $BUILD to $new_build"