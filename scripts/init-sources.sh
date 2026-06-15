#!/bin/sh
# Clones all OnePam source repos into sources/.
#
# Usage:
#   sh scripts/init-sources.sh                        # clone from onepamkz (your repos)
#   ORG=jumpserver sh scripts/init-sources.sh         # clone originals from jumpserver
#   VERSION=v3.10.7 sh scripts/init-sources.sh
set -e

ORG="${ORG:-onepamkz}"
VERSION="${VERSION:-$(grep '^VERSION=' .env 2>/dev/null | cut -d= -f2)}"
VERSION="${VERSION:-v3.10.7}"

# Format: "github-repo-name:local-folder"
# onepamkz repos have renamed names -> map to original local folder names
if [ "$ORG" = "jumpserver" ]; then
    REPOS="jumpserver:core lina:lina luna:luna koko:koko lion:lion chen:chen"
else
    REPOS="core:core proxy:lina atlas:luna gateway:koko switch:lion relay:chen"
fi

mkdir -p sources

for entry in $REPOS; do
    repo=$(echo "$entry" | cut -d: -f1)
    dest="sources/$(echo "$entry" | cut -d: -f2)"
    url="https://github.com/$ORG/$repo.git"

    if [ -d "$dest/.git" ]; then
        echo "==> Updating $dest ..."
        git -C "$dest" fetch origin
        git -C "$dest" checkout "$VERSION" 2>/dev/null || true
    else
        echo "==> Cloning $url => $dest ..."
        git clone --depth 1 "$url" "$dest" 2>/dev/null || \
        git clone --depth 1 --branch "$VERSION" "$url" "$dest"
    fi
done

echo ""
echo "Done. sources/ ready."
echo "Next: docker compose up -d --build"
