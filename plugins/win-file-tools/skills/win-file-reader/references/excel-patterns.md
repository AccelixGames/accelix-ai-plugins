# Excel Patterns — win-file-reader

Self-reinforcing pattern library for Excel file reading on Windows.
New errors and proven solutions are added here over time.
Search this file BEFORE writing new Excel reading code.

---

### openpyxl vs xlrd Selection
- **Situation**: Choosing library for Excel reading
- **Error**: N/A (success pattern)
- **Cause**: Different libraries are required for different formats
- **Solution**:
  ```python
  # .xlsx files -> openpyxl
  # .xls files (legacy) -> xlrd
  import openpyxl  # pip install openpyxl
  # import xlrd  # pip install xlrd (for .xls only)
  ```
- **Recorded**: 2026-03-20

---

### Basic Excel Reading (openpyxl)
- **Situation**: Standard xlsx text extraction
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  import openpyxl
  wb = openpyxl.load_workbook("path/to/spreadsheet.xlsx", read_only=True)
  for sheet_name in wb.sheetnames:
      ws = wb[sheet_name]
      for row in ws.iter_rows(values_only=True):
          print("\t".join(str(cell) if cell is not None else "" for cell in row))
  wb.close()
  ```
- **Recorded**: 2026-03-20

---

### Large File Memory Issue
- **Situation**: Opening large xlsx file causes memory spike
- **Error**: `MemoryError` or very slow loading
- **Cause**: openpyxl loads entire workbook into memory by default
- **Solution**:
  ```python
  import openpyxl
  # read_only=True streams rows instead of loading all into memory
  wb = openpyxl.load_workbook("path/to/large.xlsx", read_only=True, data_only=True)
  ws = wb.active
  for row in ws.iter_rows(values_only=True, max_row=1000):
      print(row)
  wb.close()
  ```
- **Recorded**: 2026-03-20
