# PDF Patterns — win-file-reader

Self-reinforcing pattern library for PDF file reading on Windows.
New errors and proven solutions are added here over time.
Search this file BEFORE writing new PDF reading code.

---

### PyMuPDF DLL Load Failure
- **Situation**: First time importing fitz on Windows
- **Error**: `ImportError: DLL load failed while importing _fitz`
- **Cause**: Missing Visual C++ Redistributable or incompatible PyMuPDF version
- **Solution**:
  ```python
  try:
      import fitz
  except ImportError:
      import pdfplumber
      # use pdfplumber as fallback
  ```
- **Recorded**: 2026-03-20

---

### Basic PDF Text Extraction (fitz)
- **Situation**: Standard PDF text extraction
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  import fitz
  doc = fitz.open("path/to/document.pdf")
  text = ""
  for page in doc:
      text += page.get_text()
  doc.close()
  ```
- **Recorded**: 2026-03-20

---

### Large PDF Token Limit
- **Situation**: PDF exceeds Claude Read tool token limit
- **Error**: `Token limit exceeded` or truncated output
- **Cause**: PDF too large to read at once
- **Solution**:
  ```python
  import fitz
  doc = fitz.open("path/to/document.pdf")
  # Read pages 0-4 only
  text = ""
  for i in range(min(5, len(doc))):
      text += doc[i].get_text()
  doc.close()
  ```
- **Recorded**: 2026-03-20
