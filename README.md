# IB Math Exam PDF Cleaner

Strips cover pages, instructions, and blank "do not write" pages from IB Math exam PDFs. Adds a small label (year, paper, TZ, level) to the first page for easy identification.

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

# 3. Drop your IB Math PDFs into this directory (or subdirectories)
#    The script scans recursively through all subdirectories

# 4. Run the script
./strip_intro.sh
```

Cleaned PDFs are saved to `output/` — originals are never modified.

---

## What It Does

1. **Recursively scans** the current directory and all subdirectories for `*.pdf` files
2. **Skips** the first 2 pages (cover + instructions) — configurable
3. **Detects** and removes blank "do not write" pages at the end of papers
4. **Skips** markschemes and non-exam PDFs automatically
5. **Adds** a small label to the top-left of the first page (e.g., `2024 AA Paper 1 TZ1 HL`)
6. **Saves** cleaned PDFs to `output/` with year-based filenames

---

## Compatibility

### Supported subjects:

| Subject | Code |
|---|---|
| Analysis & Approaches | AA |
| Applications & Interpretation | AI |
| Mathematical Studies | MS |
| Further Mathematics | FM |

### Supported fields:

| Field | Supported Values |
|---|---|
| **Paper** | 1, 2, 3 (any number) |
| **Timezone** | TZ1, TZ2, TZ3 (any number) |
| **Level** | HL, SL |
| **Language** | French, Spanish (when present in filename) |

The script handles **any combination** of the above. For example:
- `Mathematics_analysis_and_approaches_paper_2_TZ3_SL.pdf`
- `Mathematics_applications_and_interpretation_paper_1_TZ2_HL.pdf`
- `Mathematics_analysis_and_approaches_paper_1__HL_French.pdf`

### What gets skipped:

- **Markschemes** — any PDF with "markscheme" in the filename (case-insensitive)
- **Non-exam PDFs** — files without "paper N" in the name
- **Output directory** — cleaned PDFs are not re-processed

---

### How question detection works:

A page is kept as a "question page" if it has **>30 characters of text** AND contains at least one of:
- A numbered question (e.g., `1. `)
- Sub-questions (e.g., `(a) `, `(b) `)
- `[Maximum mark: X]`
- Action verbs: `find`, `show`, `calculate`, `determine`, `evaluate`, `prove`, `solve`, `express`, `sketch`, `state`, `hence`

Pages containing only "do not write" text (without actual questions) are correctly skipped because they lack question indicators.

---

## Usage

```bash
./strip_intro.sh [pages_to_remove]
```

| Argument | Default | Description |
|---|---|---|
| `pages_to_remove` | `2` | Number of intro pages to skip from the start |

**Output:** Cleaned PDFs are saved to `output/` with year-based filenames:

```
output/
├── 2024_AA_Paper1_TZ1_HL_clean.pdf
├── 2024_AA_Paper1_HL_French_clean.pdf
├── 2021_AA_Paper2_TZ2_SL_clean.pdf
├── 2019_MS_Paper1_TZ1_clean.pdf
└── ...
```

Original files are **never modified**.

### Example Run

```
$ rm -rf output && ./strip_intro.sh
 17 → 13 pages  Mathematics_analysis_and_approaches_paper_1_TZ1_HL.pdf
         (removed 2 blank page(s))
 17 → 12 pages  Mathematics/2024/Mathematics_analysis_and_approaches_paper_1__TZ1_HL.pdf
         (removed 2 blank page(s))
 17 → 14 pages  Mathematics/2021/Mathematics_analysis_and_approaches_paper_2__TZ1_HL.pdf
         (removed 2 blank page(s))
  6 →  4 pages  Mathematics/2024/Mathematics_analysis_and_approaches_paper_3__TZ1_HL.pdf
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

Place your IB exam PDFs anywhere in the directory tree. The script scans recursively:

```
./
├── Mathematics_analysis_and_approaches_paper_1_TZ1_HL.pdf
├── Mathematics/
│   ├── 2024/
│   │   ├── Mathematics_analysis_and_approaches_paper_1__TZ1_HL.pdf
│   │   └── Mathematics_analysis_and_approaches_paper_1__HL_French.pdf
│   └── 2021/
│       └── Mathematics_analysis_and_approaches_paper_2__TZ1_HL.pdf
```

Markschemes and non-exam PDFs are automatically skipped.

---

**Note:** This project was developed with the assistance of AI tools.
