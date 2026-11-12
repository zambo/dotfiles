#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building NvimOpener.app..."

platypus \
  --name "NvimOpener" \
  --interface-type 'None' \
  --interpreter '/bin/bash' \
  --bundle-identifier 'com.henriquerodrigues.nvimopener' \
  --app-icon "$SCRIPT_DIR/nvim-opener.icns" \
  --document-icon "$SCRIPT_DIR/nvim-opener.icns" \
  --droppable \
  --background \
  --uniform-type-identifiers \
    'public.plain-text|public.source-code|net.daringfireball.markdown|public.json|public.yaml|org.toml-lang.toml' \
  --overwrite \
  "$SCRIPT_DIR/nvim-opener.sh" \
  "$HOME/Applications/NvimOpener.app"

echo "Signing..."
codesign --force --deep --sign - "$HOME/Applications/NvimOpener.app"

echo "Registering file associations..."
duti "$SCRIPT_DIR/nvim-opener.duti"

# Register by extension for types that may be contested or lack stable UTIs
echo "Registering extensions..."
for ext in toml sh lua fish conf env ts tsx js jsx; do
  duti -s com.henriquerodrigues.nvimopener ."$ext" all
done

echo "Done. NvimOpener installed and associations registered."
