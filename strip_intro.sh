#!/usr/bin/env bash
# Strip intro pages and blank "do not write" pages from IB Math exam PDFs.
# Adds a small label (year, paper, TZ, level) to the first page.
# Scans the current directory recursively, skipping markschemes and non-exam PDFs.
# Usage: ./strip_intro.sh [pages_to_remove]
#   pages_to_remove defaults to 2 (cover + instructions)

set -euo pipefail

PAGES_TO_REMOVE="${1:-2}"
export PAGES_TO_REMOVE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Activate venv if it exists
if [ -d "$SCRIPT_DIR/.venv" ]; then
    . "$SCRIPT_DIR/.venv/bin/activate"
fi

python3 << 'PYEOF'
import io, os, re
from pathlib import Path
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas as rl_canvas

pages_to_remove = int(os.environ.get("PAGES_TO_REMOVE", "2"))


def parse_filename(filepath):
    """Extract year, subject, paper, TZ, level, and language from an IB exam filename."""
    path = Path(filepath)
    base = path.stem
    parent_dirs = path.parts[:-1]

    # Extract year from directory structure (e.g., "2021", "May 2022")
    year = None
    for d in parent_dirs:
        m = re.search(r'\b(20\d{2})\b', d)
        if m:
            year = m.group(1)
            break

    bl = base.lower()
    # Determine subject
    if "analysis_and_approaches" in bl:
        subject = "AA"
    elif "applications_and_interpretation" in bl:
        subject = "AI"
    elif "mathematical_studies" in bl:
        subject = "MS"
    elif "further_mathematics" in bl:
        subject = "FM"
    elif re.search(r'Mathematics_paper', base, re.IGNORECASE):
        # Fallback for older naming: "Mathematics_paper_1__TZ1_HL.pdf"
        subject = "AA"
    else:
        subject = "?"

    # Extract paper number
    m = re.search(r'paper[_ ]*(\d+)', base, re.IGNORECASE)
    paper = m.group(1) if m else "?"

    # Extract TZ
    m = re.search(r'TZ(\d+)', base)
    tz = m.group(1) if m else "?"

    # Extract level (HL/SL) - use lookahead/lookbehind to avoid \b issues with _
    m = re.search(r'(?:^|[^a-zA-Z])(HL|SL)(?:[^a-zA-Z]|$)', base)
    level = m.group(1) if m else "?"

    # Extract language
    lang = ""
    if re.search(r'(?:^|[^a-zA-Z])French(?:[^a-zA-Z]|$)', base):
        lang = "French"
    elif re.search(r'(?:^|[^a-zA-Z])Spanish(?:[^a-zA-Z]|$)', base):
        lang = "Spanish"

    return year, subject, paper, tz, level, lang


def should_skip(filepath):
    """Check if a PDF should be skipped (markscheme, non-exam, etc.)."""
    base = Path(filepath).stem.lower()

    # Skip markschemes (various formats: markscheme, Markscheme, etc.)
    if "markscheme" in base:
        return True

    # Skip files that don't look like exam papers (no "paper N" in name)
    if not re.search(r'paper[_ ]*\d+', base, re.IGNORECASE):
        return True

    return False


def is_question_page(reader, page_idx):
    """Check if a page contains actual question content (not blank/instruction)."""
    text = reader.pages[page_idx].extract_text() or ""
    tl = text.lower()

    chars = len(text.replace(" ", "").replace("\n", ""))
    if chars < 30:
        return False

    has_question = bool(re.search(r'\b\d+\.\s', text)) or \
                   bool(re.search(r'\([abc]\)\s', tl)) or \
                   bool(re.search(r'\[Maximum mark', tl)) or \
                   bool(re.search(r'\bfind|show|calculate|determine|evaluate|prove|solve|express|sketch|state|hence\b', tl))

    return has_question


def add_label_to_first_page(writer, label):
    """Add a small label to the top-left corner using reportlab.

    Uses Helvetica (Base 14 PDF font) so the text renders on all devices
    without needing to embed or subset external font files.
    """
    first_page = writer.pages[0]
    pw = float(first_page.mediabox.width)
    ph = float(first_page.mediabox.height)

    buf = io.BytesIO()
    c = rl_canvas.Canvas(buf, pagesize=(pw, ph))

    c.setFont("Helvetica", 9)
    c.setFillColorRGB(0.3, 0.3, 0.3)  # subtle grey

    margin = 10
    c.drawString(margin, ph - margin, label)

    c.showPage()
    c.save()

    buf.seek(0)
    overlay_reader = PdfReader(buf)
    overlay_page = overlay_reader.pages[0]
    first_page.merge_page(overlay_page)


def process_pdf(filepath):
    """Process a single PDF."""
    reader = PdfReader(filepath)
    total = len(reader.pages)

    # Collect question pages (skip first N intro pages)
    keep_indices = []
    for i in range(pages_to_remove, total):
        if is_question_page(reader, i):
            keep_indices.append(i)

    if not keep_indices:
        print(f"SKIP {filepath}  (no question pages found)")
        return

    # Parse filename for label
    year, subject, paper, tz, level, lang = parse_filename(filepath)

    # Build label text
    parts = [subject, f"Paper {paper}"]
    if tz != "?":
        parts.append(f"TZ{tz}")
    if level != "?":
        parts.append(level)
    if lang:
        parts.append(lang)
    label = " ".join(parts)

    # Build output filename with year
    out_parts = []
    if year:
        out_parts.append(year)
    out_parts.append(f"{subject}_Paper{paper}")
    if tz != "?":
        out_parts.append(f"TZ{tz}")
    if level != "?":
        out_parts.append(level)
    if lang:
        out_parts.append(lang)
    out_name = "_".join(out_parts) + "_clean.pdf"

    # Build output PDF
    writer = PdfWriter()
    for idx in keep_indices:
        writer.add_page(reader.pages[idx])

    add_label_to_first_page(writer, label)

    # Write output
    out = os.path.join("output", out_name)
    os.makedirs("output", exist_ok=True)

    with open(out, "wb") as f:
        writer.write(f)

    kept = len(keep_indices)
    removed = total - pages_to_remove - kept
    rel = os.path.relpath(filepath)
    print(f"{total:3d} → {kept:2d} pages  {rel}")
    if removed > 0:
        print(f"         (removed {removed} blank page(s))")


# Main - scan recursively
for root, dirs, files in os.walk("."):
    for filename in sorted(files):
        if not filename.endswith(".pdf"):
            continue
        filepath = os.path.join(root, filename)

        # Skip markschemes and non-exam PDFs
        if should_skip(filepath):
            continue

        # Skip our own output
        if filepath.startswith("./output/"):
            continue

        process_pdf(filepath)

PYEOF
