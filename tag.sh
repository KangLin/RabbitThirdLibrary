#!/bin/bash

SOURCE_DIR=`pwd`

if [ -n "$1" ]; then
    VERSION=`git describe --tags`
    if [ -z "$VERSION" ]; then
        VERSION=` git rev-parse HEAD`
    fi
    
    echo "Current verion: $VERSION, The version to will be set: $1"
    read -t 30 -p "Be sure to input Y, not input N: " INPUT
    if [ "$INPUT" != "Y" -a "$INPUT" != "y" ]; then
        exit 0
    fi
    git tag -a $1 -m "Release $1"
    ./tag.sh
fi

VERSION=`git describe --tags`
if [ -z "$VERSION" ]; then
    VERSION=` git rev-parse HEAD`
fi

APPVERYOR_VERSION="version: '${VERSION}.{build}'"
sed -i "s/^version: '.*{build}'/${APPVERYOR_VERSION}/g" ${SOURCE_DIR}/appveyor.yml
sed -i "s/BUILD_VERSION:.*/BUILD_VERSION: ${VERSION}/g" ${SOURCE_DIR}/appveyor.yml
sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/${VERSION}/g" ${SOURCE_DIR}/README*.md

#git tag -a v${VERSION} -m "Release v${VERSION}"
#git push origin :refs/tags/v${VERSION}
#git push origin v${VERSION}

if [ -n "$1" ]; then
    git add .
    git commit -m "Release $1"
    git push
    git tag -d $1
    git tag -a $1 -m "Release $1"
    git push origin :refs/tags/$1
    git push origin $1
fi
