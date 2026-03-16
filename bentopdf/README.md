# BentoPDF for Home Assistant

<div align="left">
  <img src="logo.png" alt="BentoPDF" width="100" height="100"/>
</div>



A privacy-first PDF toolkit running entirely in your browser — no uploads, no cloud, no tracking. All processing happens locally via WebAssembly. This add-on serves the BentoPDF web app from your Home Assistant instance so you can access it from anywhere on your network.

---

## Features

### Organize & Edit
| Tool | Tool | Tool |
|------|------|------|
| Merge PDF | Split PDF | Organize PDF |
| Delete Pages | Extract Pages | Reverse Pages |
| Rotate PDF | Rotate Custom | Crop PDF |
| Add Blank Page | Divide Pages | N-Up PDF |
| Alternate Merge | Combine Single Page | PDF Booklet |
| PDF Merge & Split | Fix Page Size | |

### Convert TO PDF
| Tool | Tool | Tool |
|------|------|------|
| Word to PDF | Excel to PDF | PowerPoint to PDF |
| Image to PDF | JPG to PDF | PNG to PDF |
| BMP to PDF | TIFF to PDF | WEBP to PDF |
| HEIC to PDF | SVG to PDF | PSD to PDF |
| Markdown to PDF | HTML / Email to PDF | RTF to PDF |
| TXT to PDF | CSV to PDF | JSON to PDF |
| XML to PDF | ODT to PDF | ODS to PDF |
| ODP to PDF | ODG to PDF | EPUB to PDF |
| MOBI to PDF | FB2 to PDF | CBZ to PDF |
| XPS to PDF | VSD to PDF | PUB to PDF |
| WPS to PDF | WPD to PDF | Pages to PDF |

### Convert FROM PDF
| Tool | Tool | Tool |
|------|------|------|
| PDF to DOCX | PDF to Excel | PDF to JPG |
| PDF to PNG | PDF to BMP | PDF to TIFF |
| PDF to WEBP | PDF to SVG | PDF to Text |
| PDF to Markdown | PDF to JSON | PDF to CSV |
| PDF to PDF/A | PDF to ZIP | PDF to Greyscale |

### Security & Metadata
| Tool | Tool | Tool |
|------|------|------|
| Encrypt PDF | Decrypt PDF | Change Permissions |
| Remove Restrictions | Sign PDF | Digital Sign PDF |
| Validate Signature | Edit Metadata | View Metadata |
| Remove Metadata | Sanitize PDF | Flatten PDF |
| Remove Annotations | Repair PDF | |

### Enhance & Process
| Tool | Tool | Tool |
|------|------|------|
| Compress PDF | OCR PDF | Deskew PDF |
| Rasterize PDF | Linearize PDF | PDF to PDF/A |
| Adjust Colors | Invert Colors | Text Color |
| Background Color | Bates Numbering | Page Numbers |
| Header & Footer | Add Watermark | Add Stamps |
| Scanner Effect | Posterize PDF | Font to Outline |
| PDF Layers | Compare PDFs | Prepare for AI |

### Forms & More
| Tool | Tool | Tool |
|------|------|------|
| Form Creator | Form Filler | Table of Contents |
| Bookmark | PDF Editor | Extract Images |
| Extract Tables | Extract Attachments | Edit Attachments |
| Add Attachments | Page Dimensions | PDF Workflow |

---

## Installation

1. Go to **Settings → Add-ons → Add-on Store** in Home Assistant.
2. Open the menu (`···`) → **Repositories**.
3. Add: `https://github.com/ToledoEM/BentoPDF_HA_app`
4. Find **BentoPDF** in the store and install it.
5. Start the add-on — the web UI is available at `http://<your-HA-IP>:8080`.

---

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `log_level` | `info` | Log verbosity: `info`, `debug`, `warn`, `error` |

No other configuration is needed. Drop your files in and go.

---

## Privacy

- All PDF processing runs **in-browser via WebAssembly** (PyMuPDF, Ghostscript, Tesseract, LibreOffice, CPDF)
- Files are **never uploaded** to any server — not even the one running this add-on
- No telemetry, no analytics, no external requests
- Works fully **offline** once loaded

---

## Support

- Add-on issues → [github.com/ToledoEM/BentoPDF_HA_app](https://github.com/ToledoEM/BentoPDF_HA_app/issues)
- BentoPDF upstream → [github.com/alam00000/bentopdf](https://github.com/alam00000/bentopdf)
