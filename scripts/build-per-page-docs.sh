#!/bin/sh
# Builds individual PDF and EPUB files for each documentation page using Sphinx.
# Run after prepare-sphinx-content.sh has copied content to docs/.
set -e

DOCS_DIR="docs"
OUTPUT_DIR="docs/output/pages"
TEMP_DIR="docs/_temp_single_page"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Create a minimal conf.py for single-page builds
create_conf() {
  local title="$1"
  cat > "$TEMP_DIR/conf.py" << EOF
project = "$title"
author = "Keystatic Demo Team"
extensions = ["myst_parser"]

# Load rinohtype only when installed
try:
    import rinoh
    extensions.append("rinoh.frontend.sphinx")
except ImportError:
    pass

source_suffix = {".md": "markdown"}
exclude_patterns = ["_build"]

myst_enable_extensions = ["colon_fence", "fieldlist"]
myst_title_to_header = True

rinoh_documents = [dict(doc="index", target="page", template="article")]
epub_title = project
epub_author = author
EOF
}

# Build PDF and EPUB for a single page
build_page() {
  local section="$1"
  local filename="$2"
  local slug="${filename%.md}"
  local source_file="$DOCS_DIR/$section/$filename"
  local dest_dir="$OUTPUT_DIR/$section/$slug"

  # Skip if source doesn't exist
  [ -f "$source_file" ] || return 0

  # Extract title from frontmatter or use slug
  title=$(sed -n '/^---$/,/^---$/p' "$source_file" | grep '^title:' | sed 's/^title: *//' | tr -d '"' || echo "$slug")
  [ -z "$title" ] && title="$slug"

  echo "Building: $section/$slug ($title)"

  # Setup temp directory
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"

  # Create conf.py
  create_conf "$title"

  # Copy the source file as index.md
  cp "$source_file" "$TEMP_DIR/index.md"

  # Create output directory
  mkdir -p "$dest_dir"

  # Build PDF with rinohtype
  if sphinx-build -b rinoh "$TEMP_DIR" "$TEMP_DIR/_build/pdf" -q 2>/dev/null; then
    cp "$TEMP_DIR/_build/pdf/page.pdf" "$dest_dir/page.pdf" 2>/dev/null || true
  else
    echo "  Warning: PDF build failed for $section/$slug"
  fi

  # Build EPUB
  if sphinx-build -b epub "$TEMP_DIR" "$TEMP_DIR/_build/epub" -q 2>/dev/null; then
    cp "$TEMP_DIR/_build/epub/"*.epub "$dest_dir/page.epub" 2>/dev/null || true
  else
    echo "  Warning: EPUB build failed for $section/$slug"
  fi

  # Cleanup
  rm -rf "$TEMP_DIR"
}

# Process all sections
for section in faqs releases; do
  section_dir="$DOCS_DIR/$section"
  [ -d "$section_dir" ] || continue

  for file in "$section_dir"/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    build_page "$section" "$filename"
  done
done

echo "Per-page builds complete. Output in $OUTPUT_DIR/"
