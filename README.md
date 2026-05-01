# IB Math Exam PDF Cleaner

Strips cover pages, instructions, and blank "do not write" pages from IB Math exam PDFs. Adds a small label (subject, paper, TZ, level) to the first page for easy identification.

## Platform

**Linux or WSL only.** This is a Bash script — it does not work on macOS or Windows natively. Use WSL2 on Windows.

---

## Quick Start

```bash
# 1. Clone and set up
git clone <repo-url>
cd ib-math-exam-cleaner

# 2. Create virtual environment and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install pypdf reportlab

# 3. Drop your IB Math PDFs into this directory
#    (e.g., Mathematics_analysis_and_approaches_paper_1_TZ1_HL.pdf)

# 4. Run the script
./strip_intro.sh
```

Cleaned PDFs are saved to `output/` — originals are never modified.

---

## What It Does

1. **Reads** all `*.pdf` files in the current directory
2. **Skips** the first 2 pages (cover + instructions) — configurable
3. **Detects** and removes blank "do not write" pages at the end of papers
4. **Adds** a small label to the top-left of the first page (e.g., `AA Paper 1 TZ1 HL`)
5. **Saves** cleaned PDFs to `output/` as `<original_name>_clean.pdf`

---

## Compatibility

### ✅ Works with these IB exam formats:

| Field | Supported Values |
|---|---|
| **Subject** | AA (Analysis & Approaches), AI (Applications & Interpretation) |
| **Paper** | 1, 2, 3 (any number) |
| **Timezone** | TZ1, TZ2, TZ3 (any number) |
| **Level** | HL, SL |

The script handles **any combination** of the above. For example:
- `Mathematics_analysis_and_approaches_paper_2_TZ3_SL.pdf`
- `Mathematics_applications_and_interpretation_paper_1_TZ2_HL.pdf`
- `Mathematics_analysis_and_approaches_paper_3_TZ1_SL.pdf`

### May not work with:

- **Non-math IB subjects** — the filename must contain `analysis_and_approaches` or `applications_and_interpretation`
- **Non-standard filenames** — if the filename doesn't follow the IB naming convention (paper/TZ/level embedded in the name), the label will show `?` for missing fields
- **Exams without TZ** — some IB subjects don't use timezones; the label will show `TZ?` for these

### How question detection works:

A page is kept as a "question page" if it has **>100 characters of text** AND contains at least one of:
- A numbered question (e.g., `1. `)
- Sub-questions (e.g., `(a) `, `(b) `)
- `[Maximum mark: X]`
- Action verbs: `find`, `show`, `calculate`, `determine`, `evaluate`, `prove`, `solve`, `express`, `sketch`, `write`, `state`, `hence`

---

## Usage

```bash
./strip_intro.sh [pages_to_remove]
```

| Argument | Default | Description |
|---|---|---|
| `pages_to_remove` | `2` | Number of intro pages to skip from the start |

**Output:** Cleaned PDFs are saved to `output/` with `_clean` appended to the filename. Original files are **never modified**.

```
output/
├── Mathematics_analysis_and_approaches_paper_1_TZ1_HL_clean.pdf
├── Mathematics_analysis_and_approaches_paper_2_TZ2_SL_clean.pdf
└── ...
```

### Example Run

```
$ rm -rf output && ./strip_intro.sh
 17 → 13 pages  Mathematics_analysis_and_approaches_paper_1_TZ1_HL.pdf
         (removed 2 blank page(s))
 17 → 12 pages  Mathematics_analysis_and_approaches_paper_1_TZ2_HL.pdf
         (removed 3 blank page(s))
 17 → 14 pages  Mathematics_analysis_and_approaches_paper_2_TZ1_HL.pdf
         (removed 1 blank page(s))
  6 →  4 pages  Mathematics_analysis_and_approaches_paper_3_TZ1_HL.pdf
```

---

## Requirements

- **Linux or WSL2** (this is a Bash script — does not work natively on macOS or Windows)
- Python 3.8+
- `pypdf` and `reportlab` libraries

### Setup

```bash
# 1. Create a virtual environment
python3 -m venv .venv

# 2. Activate it
source .venv/bin/activate

# 3. Install dependencies
pip install pypdf reportlab
```

After that, drop your IB Math PDFs into the directory and run `./strip_intro.sh` — the script auto-activates `.venv` if it exists.

### Adding Your PDFs

Place your IB exam PDFs in the same directory as `strip_intro.sh`. They must follow the standard IB naming convention:

```
Mathematics_analysis_and_approaches_paper_1_TZ1_HL.pdf
Mathematics_analysis_and_approaches_paper_2_TZ2_SL.pdf
Mathematics_applications_and_interpretation_paper_3_TZ1_HL.pdf
```

The script processes **all** `*.pdf` files it finds in the current directory.

---

**Note:** This project was developed with the assistance of AI tools.
