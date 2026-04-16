# ETAS Docs

A documentation site built with [Astro](https://astro.build), [Starlight](https://starlight.astro.build), and [Keystatic](https://keystatic.com). Content is managed through a Git-backed admin panel.

## Tech Stack

- **Astro** — Server-rendered framework (`@astrojs/node`)
- **Starlight** — Documentation theme
- **Keystatic** — Git-based CMS at `/keystatic`
- **Docker** — Production deployment

## Content Collections

| Collection | Path | Description |
|------------|------|-------------|
| FAQs | `src/content/docs/faqs/` | Categorized FAQ articles |
| Releases | `src/content/docs/releases/` | Version release notes |

In production (GitHub mode), edits create pull requests. In development, changes write directly to disk.

## Documentation Export (Sphinx)
The project includes Sphinx integration to generate offline documentation in multiple formats. This allows distributing the docs as downloadable files or for printing.

### How It Works
1. **Content Preparation** — MDX files from `src/content/docs/` are converted to standard Markdown and copied to `docs/source/`
2. **Sphinx Processing** — Sphinx reads the Markdown files and builds the output using a configured theme and settings
3. **Output Generation** — Final documents are written to `docs/output/` in the requested format
   
### Configuration
Sphinx settings are defined in `docs/conf.py`:
- **Project metadata** — Title, author, version displayed in generated docs
- **Theme** — Visual styling for HTML output (uses `alabaster` by default but can be updated to match etas theme)
- **Extensions** — Plugins like `myst_parser` for Markdown support
  
### Available Formats
| Format | Command | Output | Use Case |
|--------|---------|--------|----------|
| PDF | `npm run docs:pdf` | `docs/output/latex/*.pdf` | Print-ready documentation |
| EPUB | `npm run docs:epub` | `docs/output/epub/*.epub` | E-readers and mobile devices |
| HTML | `npm run docs:html` | `docs/output/html/` | Standalone static site |
  
### Customization
To modify the output structure or add custom styling:
- Edit `docs/conf.py` for Sphinx configuration
- Modify `scripts/prepare-sphinx.js` to change how content is preprocessed
