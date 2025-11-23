#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/yauneyz/owl.git"
REPO_BRANCH="master"
NIX_FILE="$HOME/nixos-config/pkgs/thinky/default.nix"

echo -e "${BLUE}🔍 Fetching latest source hash from GitHub...${NC}"

# Use nix-prefetch-git to get the latest hash
echo -e "${BLUE}📦 Prefetching git repository...${NC}"
PREFETCH_OUTPUT=$(nix-prefetch-git --url "$REPO_URL" --ref "$REPO_BRANCH" --quiet 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error: Failed to prefetch git repository${NC}"
    echo -e "${YELLOW}💡 Make sure you have SSH access to $REPO_URL${NC}"
    exit 1
fi

# Extract hash and revision from output
GIT_HASH=$(echo "$PREFETCH_OUTPUT" | grep -oP '"hash": "\K[^"]+' || echo "")
GIT_REV=$(echo "$PREFETCH_OUTPUT" | grep -oP '"rev": "\K[^"]+' || echo "")

if [ -z "$GIT_HASH" ]; then
    echo -e "${RED}❌ Error: Could not extract hash from prefetch output${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Latest commit: ${GIT_REV:0:8}${NC}"
echo -e "${GREEN}✓ Source hash: ${GIT_HASH:0:20}...${NC}"

# Get current hash from nix file
CURRENT_HASH=$(grep -oP 'hash = (lib\.fakeHash|"\K[^"]+)' "$NIX_FILE" | sed 's/lib\.fakeHash//' || echo "")

# Update source hash in nix file
if [ "$CURRENT_HASH" != "$GIT_HASH" ]; then
    echo -e "${BLUE}📝 Updating source hash in $NIX_FILE...${NC}"
    sed -i "s|hash = .*|hash = \"$GIT_HASH\";|" "$NIX_FILE"
    echo -e "${GREEN}✅ Updated source hash${NC}"
else
    echo -e "${YELLOW}ℹ  Source hash unchanged${NC}"
fi

# Check if we need to update npmDepsHash
CURRENT_NPM_HASH=$(grep -oP 'npmDepsHash = "\K[^"]+' "$NIX_FILE" || echo "")

if [[ "$CURRENT_NPM_HASH" == "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" ]] || \
   [[ -z "$CURRENT_NPM_HASH" ]]; then
    echo -e "${YELLOW}⚠  npmDepsHash needs to be calculated${NC}"
    echo -e "${YELLOW}💡 You'll need to run a build to get the correct hash:${NC}"
    echo -e "   1. The build will fail with the expected hash"
    echo -e "   2. Copy the hash from the error message"
    echo -e "   3. Update npmDepsHash in $NIX_FILE"
fi

echo -e "${GREEN}✅ Successfully updated derivation${NC}"
echo -e "${YELLOW}💡 Run 'rebuild' to apply changes${NC}"
