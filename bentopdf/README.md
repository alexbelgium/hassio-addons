# Home assistant add-on: BentoPDF

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbentopdf%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbentopdf%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbentopdf%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

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

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI at `https://<your-HA-IP>:8443`.

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

Create an issue on [github](https://github.com/alexbelgium/hassio-addons/issues) and tag @ToledoEM

- BentoPDF upstream → [github.com/alam00000/bentopdf](https://github.com/alam00000/bentopdf)
