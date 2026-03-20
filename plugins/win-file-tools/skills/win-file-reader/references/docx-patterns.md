# DOCX Patterns — win-file-reader

Self-reinforcing pattern library for DOCX file reading on Windows.
New errors and proven solutions are added here over time.
Search this file BEFORE writing new DOCX reading code.

---

### Basic DOCX Text Extraction
- **Situation**: Standard DOCX text extraction
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  from docx import Document
  doc = Document("path/to/document.docx")
  text = "\n".join([p.text for p in doc.paragraphs])
  ```
- **Recorded**: 2026-03-20

---

### DOCX Table Extraction
- **Situation**: Need to extract table data from DOCX
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  from docx import Document
  doc = Document("path/to/document.docx")
  for table in doc.tables:
      for row in table.rows:
          row_data = [cell.text for cell in row.cells]
          print("\t".join(row_data))
  ```
- **Recorded**: 2026-03-20

---

### cp949 Encoding Crash on Print
- **Situation**: Printing Korean DOCX text to Windows terminal
- **Error**: `UnicodeEncodeError: 'cp949' codec can't encode character`
- **Cause**: Windows terminal default encoding is cp949, not UTF-8
- **Solution**:
  ```python
  import sys
  sys.stdout.reconfigure(encoding='utf-8')
  # or set environment variable before running:
  # PYTHONIOENCODING=utf-8 python script.py
  ```
- **Recorded**: 2026-03-20
