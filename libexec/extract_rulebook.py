#!/usr/bin/env python3
"""Extract a rulebook PDF's text (in reading order) as a single JSON document.

Usage: extract_rulebook.py /path/to/book.pdf

Writes one JSON document to stdout on success (exit 0). Writes diagnostics and
errors to stderr only, on any failure (exit non-zero). Never writes logs or
progress output to stdout.
"""

import json
import sys
from pathlib import Path

SCHEMA_VERSION = 1


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        fail(f'usage: {sys.argv[0]} <path/to/book.pdf>')

    path = Path(sys.argv[1])
    if not path.exists():
        fail(f'file not found: {path.name}')
    if not path.is_file():
        fail(f'not a regular file: {path.name}')

    try:
        import pymupdf
        import pymupdf4llm
    except ImportError as e:
        fail(f'required Python package not importable: {e}')

    try:
        chunks = pymupdf4llm.to_markdown(str(path), page_chunks=True, show_progress=False)
    except Exception as e:  # noqa: BLE001 - any extraction failure is reported to stderr, not raised
        fail(f'extraction failed: {e}')

    pages = []
    for chunk in chunks:
        pages.append({
            'page_number': chunk['metadata']['page_number'],
            'text': chunk['text'],
            'page_boxes': chunk.get('page_boxes', []),
        })
    pages.sort(key=lambda p: p['page_number'])

    document = {
        'schema_version': SCHEMA_VERSION,
        'pymupdf4llm_version': pymupdf4llm.__version__,
        'pymupdf_version': pymupdf.__version__,
        'page_count': len(pages),
        'pages': pages,
    }

    json.dump(document, sys.stdout)


if __name__ == '__main__':
    main()