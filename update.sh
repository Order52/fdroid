#!/bin/sh
# Adds the latest TinyKit release from GitHub to this F-Droid repo and publishes it.
# Needs: gh, fdroid (fdroidserver), JDK 21, config.yml and keystore.p12 next to this file.
set -e
cd "$(dirname "$0")"
export JAVA_HOME=${JAVA_HOME:-/opt/homebrew/opt/openjdk@21}
export PATH="$JAVA_HOME/bin:$PATH"
tag=$(gh release view -R Order52/tinykit --json tagName --jq .tagName)
ver=${tag#v}
apk="TinyKit-$ver.apk"
[ -f "repo/$apk" ] || gh release download "$tag" -R Order52/tinykit -p "$apk" -D repo
# Pull the store text and screenshots from TinyKit's own Fastlane folder.
rm -rf tmp-src && git clone -q --depth 1 --branch "$tag" https://github.com/Order52/tinykit.git tmp-src
code=$(sed -n 's/.*versionCode = \([0-9]*\).*/\1/p' tmp-src/app/build.gradle.kts)
rm -rf metadata/io.github.order52.tinykit && mkdir -p metadata/io.github.order52.tinykit
cp -R tmp-src/fastlane/metadata/android/. metadata/io.github.order52.tinykit/
rm -rf tmp-src
sed -i.bak "s/^CurrentVersion: .*/CurrentVersion: $ver/;s/^CurrentVersionCode: .*/CurrentVersionCode: $code/" metadata/io.github.order52.tinykit.yml && rm metadata/io.github.order52.tinykit.yml.bak
cp metadata/io.github.order52.tinykit/en-US/images/icon.png icon.png
mkdir -p repo/icons && cp icon.png repo/icons/icon.png
# Keep only the 3 newest APKs.
ls -1 repo/TinyKit-*.apk | sort -V | awk '{a[NR]=$0} END{for(i=1;i<=NR-3;i++)print a[i]}' | xargs -I{} rm -f {}
fdroid update
sed -i.bak "s#repo/TinyKit-[0-9.]*\.apk#repo/$apk#" index.html && rm index.html.bak
git add -A
git commit -m "TinyKit $ver" || true
git push
