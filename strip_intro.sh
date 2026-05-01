#!/usr/bin/env bash
# Strip intro pages and blank "do not write" pages from IB Math exam PDFs.
# Adds a small label (paper/TZ/level) to the first page.
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
import io, os, glob, re
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas as rl_canvas
from reportlab.lib.pagesizes import A4

pages_to_remove = int(os.environ.get("PAGES_TO_REMOVE", "2"))


def parse_filename(filename):
    """Extract paper, TZ, and level from IB exam filename."""
    base = os.path.splitext(os.path.basename(filename))[0]

    if "analysis_and_approaches" in base:
        subject = "AA"
    elif "applications_and_interpretation" in base:
        subject = "AI"
    else:
        subject = "?"

    m = re.search(r"paper_(\d+)", base)
    paper = m.group(1) if m else "?"

    m = re.search(r"TZ(\d+)", base)
    tz = m.group(1) if m else "?"

    m = re.search(r"(HL|SL)", base)
    level = m.group(1) if m else "?"

    return subject, paper, tz, level


def is_question_page(reader, page_idx):
    """Check if a page contains actual question content (not blank/instruction)."""
    text = reader.pages[page_idx].extract_text() or ""
    tl = text.lower()

    # Pages with very little text are blank/instruction pages
    chars = len(text.replace(" ", "").replace("\n", ""))
    if chars < 100:
        return False

    # Check for question indicators
    has_question = bool(re.search(r"\b\d+\.\s", text)) or \
                   bool(re.search(r"\([abc]\)\s", tl)) or \
                   bool(re.search(r"\[Maximum mark", tl)) or \
                   bool(re.search(r"\bfind|show|calculate|determine|evaluate|prove|solve|express|sketch|prove|write|state|hence\b", tl))

    return has_question


def add_label_to_first_page(writer, label):
    """Add a small label to the top-left corner of the first page using reportlab.

    Uses Helvetica (Base 14 PDF font) so the text renders on all devices
    without needing to embed or subset external font files.
    """
    first_page = writer.pages[0]
    pw = float(first_page.mediabox.width)
    ph = float(first_page.mediabox.height)

    # Create a transparent overlay PDF in memory
    buf = io.BytesIO()
    c = rl_canvas.Canvas(buf, pagesize=(pw, ph))

    # Helvetica is a Base 14 PDF font — guaranteed to exist in every PDF viewer
    c.setFont("Helvetica", 9)
    c.setFillColorRGB(0.3, 0.3, 0.3)  # subtle grey

    # Top-left corner with small margin
    margin = 10
    c.drawString(margin, ph - margin, label)

    c.showPage()
    c.save()

    # Seek to start and read the overlay
    buf.seek(0)
    overlay_reader = PdfReader(buf)
    overlay_page = overlay_reader.pages[0]

    # Merge the overlay onto the first page
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
    subject, paper, tz, level = parse_filename(filepath)
    label = f"{subject} Paper {paper} TZ{tz} {level}"

    # Get dimensions from first question page
    first_idx = keep_indices[0]
    pw = float(reader.pages[first_idx].mediabox.width)
    ph = float(reader.pages[first_idx].mediabox.height)

    # Add label to first page

    # Build output PDF
    writer = PdfWriter()

    # Add all question pages directly from reader (no clone)
    for idx in keep_indices:
        writer.add_page(reader.pages[idx])

    # Add label to the first page
    add_label_to_first_page(writer, label)

    # Write output
    base = os.path.splitext(filepath)[0]
    out = os.path.join("output", f"{os.path.basename(base)}_clean.pdf")
    os.makedirs("output", exist_ok=True)

    with open(out, "wb") as f:
        writer.write(f)

    kept = len(keep_indices)
    removed = total - pages_to_remove - kept
    print(f"{total:3d} → {kept:2d} pages  {os.path.basename(filepath)}")
    if removed > 0:
        print(f"         (removed {removed} blank page(s))")


# Main
for filepath in sorted(glob.glob("*.pdf")):
    process_pdf(filepath)

PYEOF
