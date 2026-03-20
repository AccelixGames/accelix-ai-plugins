# HWP Patterns — win-file-reader

Self-reinforcing pattern library for HWP/HWPX file reading on Windows.
New errors and proven solutions are added here over time.
Search this file BEFORE writing new HWP reading code.

---

### Format Detection (HWP vs HWPX)
- **Situation**: Need to determine if file is legacy HWP or modern HWPX
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  import olefile
  import zipfile

  def detect_hwp_format(path):
      if olefile.isOleFile(path):
          return "hwp"  # Legacy OLE2 binary
      elif zipfile.is_zipfile(path):
          return "hwpx"  # Modern ZIP+XML
      else:
          raise ValueError(f"Unknown format: {path}")
  ```
- **Recorded**: 2026-03-20

---

### HWP Text Extraction (olefile + zlib)
- **Situation**: Extract text from legacy .hwp file
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  import olefile
  import zlib
  import struct

  ole = olefile.OleFileIO("path/to/document.hwp")
  # Check if BodyText is compressed
  header = ole.openstream("FileHeader").read()
  is_compressed = (header[36] & 1) != 0

  raw = ole.openstream("BodyText/Section0").read()
  if is_compressed:
      raw = zlib.decompress(raw, -15)

  # Parse PARA_TEXT records (tag_id=67)
  text_parts = []
  offset = 0
  while offset < len(raw):
      header_val = struct.unpack_from("<I", raw, offset)[0]
      tag_id = header_val & 0x3FF
      level = (header_val >> 10) & 0x3FF
      size = (header_val >> 20) & 0xFFF
      offset += 4
      if size == 0xFFF:
          size = struct.unpack_from("<I", raw, offset)[0]
          offset += 4
      if tag_id == 67:  # PARA_TEXT
          text = raw[offset:offset+size].decode("utf-16-le", errors="replace")
          # Filter control characters
          text = "".join(c for c in text if ord(c) >= 32 or c in "\n\r\t")
          text_parts.append(text)
      offset += size

  ole.close()
  full_text = "\n".join(text_parts)
  ```
- **Recorded**: 2026-03-20

---

### HWPX Text Extraction (zipfile + XML)
- **Situation**: Extract text from modern .hwpx file
- **Error**: N/A (success pattern)
- **Cause**: N/A
- **Solution**:
  ```python
  import zipfile
  from xml.etree import ElementTree as ET

  def read_hwpx(path):
      text_parts = []
      with zipfile.ZipFile(path, 'r') as zf:
          for name in sorted(zf.namelist()):
              if name.startswith("Contents/section") and name.endswith(".xml"):
                  xml_data = zf.read(name)
                  root = ET.fromstring(xml_data)
                  for elem in root.iter():
                      if elem.text and elem.text.strip():
                          text_parts.append(elem.text.strip())
      return "\n".join(text_parts)
  ```
- **Recorded**: 2026-03-20

---

### HWP Text Encoding
- **Situation**: Confusion about HWP text encoding
- **Error**: Garbled Korean text when decoding as cp949
- **Cause**: Common misconception — HWP stores text as UTF-16LE in PARA_TEXT records, not cp949
- **Solution**:
  ```python
  text = raw[offset:offset+size].decode("utf-16-le", errors="replace")
  ```
- **Recorded**: 2026-03-20
