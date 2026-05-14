#!/usr/bin/env bash
#
# md2pdf.sh — Convert Markdown (with Mermaid diagrams) to PDF
# Zero extra dependencies: uses only pandoc + system Chrome/Chromium
#
# Usage:
#   md2pdf.sh input.md                    # → input.pdf
#   md2pdf.sh input.md output.pdf         # explicit output path
#   md2pdf.sh input.md -o ~/report.pdf    # -o flag
#
# Requirements:
#   - pandoc (brew install pandoc / apt install pandoc)
#   - Google Chrome or Chromium (any recent version)
#
# Features:
#   - Full CJK (Chinese/Japanese/Korean) support
#   - Mermaid diagram rendering via CDN
#   - GFM tables, blockquotes, code blocks
#   - Print-optimized A4 layout
#   - Pandoc HTML entity de-escaping for Mermaid compatibility

set -euo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
usage() {
  echo "Usage: $(basename "$0") <input.md> [-o <output.pdf>] [output.pdf]"
  echo ""
  echo "Convert Markdown with Mermaid diagrams to PDF."
  echo "Requires: pandoc, Google Chrome or Chromium."
  exit "${1:-0}"
}

INPUT=""
OUTPUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -*)  echo "Unknown option: $1"; usage 1 ;;
    *)
      if [[ -z "$INPUT" ]]; then INPUT="$1"
      elif [[ -z "$OUTPUT" ]]; then OUTPUT="$1"
      else echo "Too many arguments"; usage 1
      fi
      shift ;;
  esac
done

[[ -z "$INPUT" ]] && usage 1
[[ -z "$OUTPUT" ]] && OUTPUT="${INPUT%.md}.pdf"

# ---------------------------------------------------------------------------
# Locate dependencies
# ---------------------------------------------------------------------------
find_chrome() {
  # macOS paths
  local candidates=(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
    "$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  )
  # Linux paths
  candidates+=(
    "$(command -v google-chrome 2>/dev/null || true)"
    "$(command -v google-chrome-stable 2>/dev/null || true)"
    "$(command -v chromium-browser 2>/dev/null || true)"
    "$(command -v chromium 2>/dev/null || true)"
  )
  for c in "${candidates[@]}"; do
    [[ -n "$c" && -x "$c" ]] && echo "$c" && return 0
  done
  return 1
}

PANDOC="$(command -v pandoc 2>/dev/null || true)"
[[ -z "$PANDOC" ]] && echo "Error: pandoc not found. Install with: brew install pandoc" >&2 && exit 1

CHROME="$(find_chrome || true)"
[[ -z "$CHROME" ]] && echo "Error: Chrome/Chromium not found." >&2 && exit 1

[[ ! -f "$INPUT" ]] && echo "Error: $INPUT not found" >&2 && exit 1

# ---------------------------------------------------------------------------
# Temp files (cleaned up on exit)
# ---------------------------------------------------------------------------
TMPDIR_WORK=$(mktemp -d /tmp/md2pdf-XXXXXX)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

TMPHTML="$TMPDIR_WORK/output.html"
HEADER_FILE="$TMPDIR_WORK/header.html"
AFTER_FILE="$TMPDIR_WORK/after.html"

# ---------------------------------------------------------------------------
# HTML header: CSS + Mermaid CDN
# ---------------------------------------------------------------------------
cat > "$HEADER_FILE" <<'HEADER_EOF'
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
<style>
  @page { size: A4; margin: 18mm 15mm; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Noto Sans TC", "Noto Sans SC",
                 "Noto Sans JP", "Microsoft JhengHei", "PingFang TC", sans-serif;
    font-size: 13px; line-height: 1.7; color: #1a1a1a;
    max-width: 740px; margin: 0 auto; padding: 0 10px;
  }
  h1 { font-size: 22px; border-bottom: 2px solid #2563eb; padding-bottom: 6px; color: #1e3a5f; }
  h2 { font-size: 17px; margin-top: 24px; color: #2563eb; border-bottom: 1px solid #e5e7eb; padding-bottom: 4px; }
  h3 { font-size: 14px; margin-top: 18px; color: #374151; }
  table { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 11.5px; page-break-inside: auto; }
  th, td { border: 1px solid #d1d5db; padding: 5px 8px; text-align: left; }
  th { background: #f0f4ff; font-weight: 600; }
  tr { page-break-inside: avoid; }
  tr:nth-child(even) { background: #f9fafb; }
  blockquote { border-left: 3px solid #2563eb; margin: 10px 0; padding: 6px 14px; background: #f0f7ff; }
  strong { color: #1e3a5f; }
  code { background: #f3f4f6; padding: 1px 4px; border-radius: 3px; font-size: 11px; }
  pre { background: #f8f9fa; border: 1px solid #e5e7eb; border-radius: 4px; padding: 10px; overflow-x: auto; font-size: 11px; }
  hr { border: none; border-top: 1px solid #e5e7eb; margin: 20px 0; }
  .mermaid { margin: 14px 0; text-align: center; page-break-inside: avoid; }
  img { max-width: 100%; }
</style>
HEADER_EOF

# ---------------------------------------------------------------------------
# After-body script: de-escape pandoc entities + init Mermaid
# ---------------------------------------------------------------------------
cat > "$AFTER_FILE" <<'AFTER_EOF'
<script>
document.querySelectorAll('pre.mermaid code, pre > code.language-mermaid').forEach(function(el) {
  var pre = el.parentElement;
  var raw = el.innerHTML
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&');
  var div = document.createElement('div');
  div.className = 'mermaid';
  div.textContent = raw;
  pre.replaceWith(div);
});
mermaid.initialize({ startOnLoad: true, theme: 'default' });
</script>
AFTER_EOF

# ---------------------------------------------------------------------------
# Step 1: pandoc  md → HTML
# ---------------------------------------------------------------------------
echo "1/2  pandoc: md → html ..."
"$PANDOC" "$INPUT" \
  --standalone \
  --from=gfm \
  --to=html5 \
  --include-in-header="$HEADER_FILE" \
  --include-after-body="$AFTER_FILE" \
  --metadata title=" " \
  -o "$TMPHTML"

# ---------------------------------------------------------------------------
# Step 2: Chrome headless  HTML → PDF
# ---------------------------------------------------------------------------
echo "2/2  Chrome: html → pdf ..."
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --disable-extensions \
  --run-all-compositor-stages-before-draw \
  --virtual-time-budget=10000 \
  --print-to-pdf="$OUTPUT" \
  --no-pdf-header-footer \
  "file://$TMPHTML" \
  2>/dev/null

SIZE=$(du -h "$OUTPUT" | cut -f1 | xargs)
echo "Done: $OUTPUT ($SIZE)"
