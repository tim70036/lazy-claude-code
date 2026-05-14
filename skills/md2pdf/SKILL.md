---
name: md2pdf
description: Convert Markdown files (with Mermaid diagrams) to PDF. Use when the user wants to export, print, or share a markdown report as PDF, or mentions converting markdown to a portable format.
---

# Markdown to PDF Conversion

Convert any Markdown file — including Mermaid diagrams, CJK text, and GFM tables — to a print-ready A4 PDF. Zero extra dependencies beyond `pandoc` and system Chrome.

## How to Use

Run the bundled script:

```bash
~/.claude/skills/md2pdf/scripts/md2pdf.sh input.md output.pdf
```

Or with the `-o` flag:

```bash
~/.claude/skills/md2pdf/scripts/md2pdf.sh input.md -o ~/Desktop/report.pdf
```

If `output.pdf` is omitted, it defaults to `input.pdf` in the same directory.

## Requirements

| Tool | Install |
|------|---------|
| pandoc | `brew install pandoc` (macOS) / `apt install pandoc` (Linux) |
| Chrome or Chromium | Any recent version already installed on the system |

No npm/bun/pip install needed. No puppeteer. No LaTeX.

## How It Works

```
input.md  →  pandoc (md→html)  →  Chrome headless (--print-to-pdf)  →  output.pdf
                 ↑                        ↑
          injects CSS +            --virtual-time-budget=10s
          mermaid.js CDN           gives JS time to render diagrams
```

1. **pandoc** converts GFM markdown to standalone HTML, injecting a `<style>` block (A4-optimized typography) and mermaid.js from CDN.
2. A post-body `<script>` de-escapes HTML entities that pandoc applies inside code blocks (`&lt;` → `<`, `&quot;` → `"`, etc.), so Mermaid can parse the diagram source.
3. **Chrome headless** opens the HTML with `--virtual-time-budget=10000` (10 seconds of simulated time for JS execution), then prints to PDF.

## Supported Features

- Mermaid diagrams: flowchart, pie, xychart-beta, sequence, etc.
- `<br/>` line breaks inside Mermaid node labels
- CJK (Chinese, Japanese, Korean) text
- GFM tables, blockquotes, fenced code blocks
- Print-friendly: page-break-inside:avoid on table rows and diagrams

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Mermaid shows "Syntax error" | Check that diagram uses `<br/>` not `\n` for line breaks in node labels. Pandoc escapes HTML inside code blocks; the script de-escapes them, but only standard entities. |
| Chrome not found | Script auto-detects macOS and Linux Chrome paths. Set `CHROME` env var to override: `CHROME=/path/to/chrome md2pdf.sh input.md` |
| Diagrams missing / blank | Increase virtual-time-budget: edit the script's `--virtual-time-budget=10000` to a higher value (milliseconds). |
| Tables cut off at page break | Already handled with `page-break-inside: avoid` on `<tr>`. For very long tables, some splitting is unavoidable. |

## Customization

To adjust styling, edit the CSS in the `HEADER_FILE` heredoc inside the script. Key variables:

- Font size: `body { font-size: 13px; }` 
- Page margins: `@page { margin: 18mm 15mm; }`
- Max content width: `body { max-width: 740px; }`
- Mermaid theme: `mermaid.initialize({ theme: 'default' })` — options: `default`, `dark`, `forest`, `neutral`
