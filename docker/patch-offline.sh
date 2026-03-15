#!/bin/bash
set -euo pipefail

# =============================================================================
# patch-offline.sh
# Patches the Vue.js docs for fully offline operation:
#   - Downloads CDN libraries locally
#   - Removes analytics, ads, external search
#   - Adds VitePress local search
# =============================================================================

PROJECT_DIR="${1:-.}"
PUBLIC_DIR="${PROJECT_DIR}/src/public"
OFFLINE_LIBS_DIR="${PUBLIC_DIR}/offline-libs"

echo "==> Patching project for offline mode..."

# -----------------------------------------------------------------------------
# 1. Download CDN libraries used in REPL import-maps
# -----------------------------------------------------------------------------
echo "==> Downloading CDN libraries for offline REPL..."
mkdir -p "${OFFLINE_LIBS_DIR}"

download_cdn() {
  local url="$1"
  local dest="$2"
  echo "    Downloading: ${url}"
  curl -sL --fail --retry 3 "${url}" -o "${dest}" || {
    echo "    WARNING: Failed to download ${url}"
    return 1
  }
}

download_cdn \
  "https://cdn.jsdelivr.net/npm/marked/+esm" \
  "${OFFLINE_LIBS_DIR}/marked.esm.js"

download_cdn \
  "https://cdn.jsdelivr.net/npm/lodash-es/+esm" \
  "${OFFLINE_LIBS_DIR}/lodash-es.esm.js"

download_cdn \
  "https://cdn.jsdelivr.net/npm/js-confetti/+esm" \
  "${OFFLINE_LIBS_DIR}/js-confetti.esm.js"

VUE_VERSION=$(node -e "
const pkg = require('${PROJECT_DIR}/node_modules/vue/package.json');
console.log(pkg.version);
")
echo "    Vue version detected: ${VUE_VERSION}"

download_cdn \
  "https://unpkg.com/vue@${VUE_VERSION}/dist/vue.esm-browser.js" \
  "${OFFLINE_LIBS_DIR}/vue.esm-browser.js"

# -----------------------------------------------------------------------------
# 2. Patch import-map.json files to use local paths
# -----------------------------------------------------------------------------
echo "==> Patching import-map.json files..."

cat > "${PROJECT_DIR}/src/examples/src/markdown/import-map.json" << 'EOF'
{
  "imports": {
    "marked": "/offline-libs/marked.esm.js",
    "lodash-es": "/offline-libs/lodash-es.esm.js"
  }
}
EOF

cat > "${PROJECT_DIR}/src/examples/src/list-transition/import-map.json" << 'EOF'
{
  "imports": {
    "lodash-es": "/offline-libs/lodash-es.esm.js"
  }
}
EOF

cat > "${PROJECT_DIR}/src/tutorial/src/step-15/import-map.json" << 'EOF'
{
  "imports": {
    "js-confetti": "/offline-libs/js-confetti.esm.js"
  }
}
EOF

# -----------------------------------------------------------------------------
# 3. Patch REPL components to use local Vue build
# -----------------------------------------------------------------------------
echo "==> Patching REPL components to use local Vue..."

sed -i 's|`https://unpkg.com/vue@${[^}]*}/dist/vue.esm-browser.js`|`/offline-libs/vue.esm-browser.js`|g' \
  "${PROJECT_DIR}/src/examples/ExampleRepl.vue" \
  "${PROJECT_DIR}/src/tutorial/TutorialRepl.vue"

# -----------------------------------------------------------------------------
# 4. Patch .vitepress/config.ts
# -----------------------------------------------------------------------------
echo "==> Patching VitePress config..."

CONFIG_FILE="${PROJECT_DIR}/.vitepress/config.ts"

node -e "
const fs = require('fs');
let c = fs.readFileSync('${CONFIG_FILE}', 'utf-8');

// Remove Fathom Analytics script block
c = c.replace(/,?\s*\[\s*'script',\s*\{[^}]*cdn\.usefathom\.com[^}]*\}\s*\]/s, '');

// Remove Bitterbrains ad script block
c = c.replace(/,?\s*\[\s*'script',\s*\{[^}]*media\.bitterbrains\.com[^}]*\}\s*\]/s, '');

// Remove preconnect to automation.vuejs.org
c = c.replace(/,?\s*\[\s*'link',\s*\{[^}]*automation\.vuejs\.org[^}]*\}\s*\]/s, '');

// Remove carbonAds config
c = c.replace(/,?\s*carbonAds:\s*\{[^}]*\}/s, '');

// Remove algolia config (multiline with nested object)
c = c.replace(/,?\s*algolia:\s*\{[^}]*searchParameters:\s*\{[^}]*\}\s*\}/s, '');

// Add local search provider (insert after extends: baseConfig,)
if (!c.includes(\"search:\")) {
  c = c.replace(
    'extends: baseConfig,',
    'extends: baseConfig,\\n\\n  search: {\\n    provider: \\'local\\'\\n  },'
  );
}

fs.writeFileSync('${CONFIG_FILE}', c, 'utf-8');
console.log('    Config patched successfully');
"

echo "==> Offline patching complete!"
