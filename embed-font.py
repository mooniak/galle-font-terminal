#!/usr/bin/env python3
"""Embed a font file into index.html as a base64 data URI.

The font is NOT kept inline in the source you edit by hand — instead, keep the
real font file (e.g. GalleALPHA.otf) next to this script and run:

    python3 embed-font.py                       # GalleALPHA.otf -> index.html
    python3 embed-font.py MyFont.otf            # custom font
    python3 embed-font.py MyFont.otf page.html  # custom font + html

It finds the `src: url('data:font/...;base64,...')` line inside the first
@font-face block and rewrites it with the current bytes of the font file, so
re-embedding an updated font is a one-command step.
"""

import base64
import os
import re
import sys

DEFAULT_FONT = "GalleALPHA.otf"
DEFAULT_HTML = "index.html"

# Matches the data-URI src line and captures the indentation/prefix and suffix
# so we only replace the base64 payload, leaving formatting intact.
SRC_RE = re.compile(
    r"(?P<prefix>src:\s*url\(['\"]data:font/[^;]+;base64,)"
    r"[A-Za-z0-9+/=]*"
    r"(?P<suffix>['\"]\))"
)

MIME_BY_EXT = {
    ".otf": "font/opentype",
    ".ttf": "font/truetype",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
}

# Marks the BASE_GIDS literal the page uses to tell live shaping which glyphs
# come straight from the cmap (vs. produced by GSUB). Regenerated per embed.
GIDS_RE = re.compile(r"(/\*BASEGIDS\*/)\[.*?\](/\*/BASEGIDS\*/)", re.DOTALL)


def base_gids(font_path):
    """Return the sorted glyph IDs reachable directly from Unicode via cmap.

    These are the "base" glyphs; any shaped glyph NOT in this set was produced
    by a GSUB substitution (conjunct, ligature, reph, stylistic alternate),
    which is how the page counts substitutions live. Returns None if fontTools
    is unavailable.
    """
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        return None

    f = TTFont(font_path)
    idx = {name: i for i, name in enumerate(f.getGlyphOrder())}
    return sorted({idx[name] for name in f.getBestCmap().values()})


def main(argv):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    font_path = argv[1] if len(argv) > 1 else os.path.join(script_dir, DEFAULT_FONT)
    html_path = argv[2] if len(argv) > 2 else os.path.join(script_dir, DEFAULT_HTML)

    if not os.path.isfile(font_path):
        sys.exit(f"font not found: {font_path}")
    if not os.path.isfile(html_path):
        sys.exit(f"html not found: {html_path}")

    font_bytes = open(font_path, "rb").read()
    b64 = base64.b64encode(font_bytes).decode("ascii")

    ext = os.path.splitext(font_path)[1].lower()
    mime = MIME_BY_EXT.get(ext, "font/opentype")

    html = open(html_path, encoding="utf-8").read()

    def repl(m):
        # Rebuild the prefix so the MIME type matches the font being embedded.
        new_prefix = re.sub(
            r"data:font/[^;]+;base64,",
            f"data:font/{mime.split('/', 1)[1]};base64,",
            m.group("prefix"),
        )
        return new_prefix + b64 + m.group("suffix")

    new_html, n = SRC_RE.subn(repl, html, count=1)
    if n == 0:
        sys.exit(
            "could not find a `src: url('data:font/...;base64,...')` line in "
            f"{html_path} — is the @font-face data URI present?"
        )

    # Refresh the BASE_GIDS set used by live shaping (best effort).
    gids = base_gids(font_path)
    if gids is None:
        print("note: fontTools not installed — left BASE_GIDS as-is "
              "(pip install fonttools to auto-update it)")
    else:
        import json
        literal = json.dumps(gids, separators=(",", ":"))
        new_html, gn = GIDS_RE.subn(
            lambda m: m.group(1) + literal + m.group(2), new_html, count=1)
        if gn:
            print(f"BASE_GIDS: {len(gids)} cmap glyphs")
        else:
            print("warning: BASE_GIDS markers not found in HTML")

    if new_html == html:
        print(f"font already up to date in {os.path.basename(html_path)} "
              f"({len(font_bytes)} bytes)")
        return

    open(html_path, "w", encoding="utf-8").write(new_html)
    print(f"embedded {os.path.basename(font_path)} ({len(font_bytes)} bytes, "
          f"{mime}) into {os.path.basename(html_path)}")


if __name__ == "__main__":
    main(sys.argv)
