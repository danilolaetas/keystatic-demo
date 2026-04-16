"""Sphinx configuration for keystatic-demo documentation."""

project = "Keystatic Demo"
author = "Keystatic Demo Team"
copyright = "2026, Keystatic Demo Team"

# -- Extensions ---------------------------------------------------------------

extensions = [
    "myst_parser",
]

# Load rinohtype only when installed (CI has it, local dev may not)
try:
    import rinoh  # noqa: F401
    extensions.append("rinoh.frontend.sphinx")
except ImportError:
    pass

# -- Source settings ----------------------------------------------------------

# Treat .mdx files as Markdown (Keystatic outputs .mdx)
source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
    ".mdx": "markdown",
}

# Content lives in _source/ (populated by the prep script)
# We keep the Sphinx root here in docs/ for index.md and conf.py,
# and include the prepared content via toctree references.

exclude_patterns = ["_build", "_source", "requirements.txt"]

# -- MyST-Parser settings ----------------------------------------------------

myst_enable_extensions = [
    "colon_fence",
    "fieldlist",
]

# Use title from YAML frontmatter as the page heading
myst_title_to_header = True

# -- HTML output (optional, for previewing) -----------------------------------

html_theme = "sphinx_rtd_theme"

# -- LaTeX / PDF output -------------------------------------------------------

latex_elements = {
    "papersize": "a4paper",
    "pointsize": "11pt",
    "preamble": r"""
\usepackage{enumitem}
\setlistdepth{9}
""",
}

latex_documents = [
    ("index", "keystatic-demo.tex", project, author, "manual"),
]

# -- rinohtype PDF output (no LaTeX needed) -----------------------------------

rinoh_documents = [
    dict(
        doc="index",
        target="keystatic-demo",
        title=project,
        template="article",
    ),
]

# -- EPUB output --------------------------------------------------------------

epub_title = project
epub_author = author
