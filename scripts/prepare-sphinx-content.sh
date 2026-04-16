#!/bin/sh
# Copies Keystatic MDX content into docs/ for Sphinx consumption.
# Strips JSX imports and component tags so MyST-Parser sees clean Markdown.
set -e

CONTENT_DIR="src/content/docs"
DOCS_DIR="docs"

for section in faqs releases; do
  src="${CONTENT_DIR}/${section}"
  dest="${DOCS_DIR}/${section}"

  # skip if source section doesn't exist
  [ -d "$src" ] || continue

  rm -rf "$dest"
  mkdir -p "$dest"

  for file in "$src"/*.mdx; do
    [ -f "$file" ] || continue
    basename="$(basename "$file" .mdx).md"

    # 1. Remove import lines (import ... from '...')
    # 2. Remove self-closing JSX tags  <Component ... />
    # 3. Remove opening JSX tags       <Component ...>
    # 4. Remove closing JSX tags       </Component>
    sed -E \
      -e '/^import .+/d' \
      -e 's/<[A-Z][A-Za-z]+ [^/]*\/>//g' \
      -e 's/<[A-Z][A-Za-z]+[^>]*>//g' \
      -e 's/<\/[A-Z][A-Za-z]+>//g' \
      "$file" > "$dest/$basename"
  done
done

echo "Content prepared in ${DOCS_DIR}/"
