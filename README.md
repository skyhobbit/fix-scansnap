# fix-scansnap

A simple Bash script to correct the aspect ratio of scanned PDF documents.

Some document scanners, including ScanSnap, may produce PDF files with distorted proportions depending on the scanning settings or document handling. This tool corrects the vertical scaling of scanned PDF pages using ImageMagick.

It supports both fixed-percentage correction and automatic adjustment to standard paper aspect ratios.

## Features

- Correct vertical distortion in scanned PDF documents
- Preserve the original page width while adjusting page height
- Apply a fixed vertical scaling percentage to all pages
- Automatically adjust each page to A4 or B5 aspect ratios
- Process multi-page PDF documents
- Save the corrected PDF without overwriting the original

## Requirements

- Bash
- ImageMagick 7 (`magick` command)
- Ghostscript (for PDF processing with ImageMagick)

### macOS

Install the dependencies using Homebrew:

```bash
brew install imagemagick ghostscript
```

### Ubuntu / Debian

Install ImageMagick 7 and Ghostscript. Make sure the `magick` command is available.

> **Note:** Some ImageMagick installations restrict PDF reading and writing through security policies. PDF processing must be permitted in your environment.

## Installation

```bash
git clone https://github.com/skyhobbit/fix-scansnap.git
cd fix-scansnap
chmod +x fix-scansnap.sh
```

## Usage

### Fixed-percentage correction

```bash
./fix-scansnap.sh -p 69.20 scan.pdf
```

This example reduces the height of each page to 69.20% of its original height while keeping the width unchanged.

### Automatic A4 correction

```bash
./fix-scansnap.sh -s a4 scan.pdf
```

This adjusts each page independently to the A4 paper aspect ratio (210 × 297 mm).

### Automatic B5 correction

```bash
./fix-scansnap.sh -s b5 scan.pdf
```

This adjusts each page independently to the B5 paper aspect ratio (182 × 257 mm).

## Output

The corrected PDF is saved in the same directory as the input file with `_corrected` appended to the filename:

```text
scan.pdf
scan_corrected.pdf
```

The original file is not modified. However, an existing output file with the same name may be overwritten.

## How It Works

The script uses ImageMagick to process scanned PDF pages at 300 DPI.

In fixed-percentage mode (`-p`), it applies the specified vertical scaling directly to the PDF rendering.

In paper-size mode (`-s`), it:

1. Renders each PDF page as a PNG image.
2. Measures the width and height of each page.
3. Calculates the target height based on the selected paper aspect ratio.
4. Resizes each page vertically while preserving its width.
5. Combines the corrected page images into a new PDF.

The vertical scaling percentage is calculated as:

```text
target_height = current_width × paper_height / paper_width

vertical_scale (%) = target_height / current_height × 100
```

Each page is processed independently, allowing multi-page documents with different original dimensions to be corrected.

## Limitations

- PDF pages are rasterized at 300 DPI. Existing searchable text, vector graphics, and other PDF metadata may not be preserved.
- This tool adjusts the entire page, not individual objects or content regions.
- Automatic paper-size correction assumes that the scanned page should match the selected paper aspect ratio.
- Only portrait-oriented A4 and B5 aspect ratios are supported in paper-size mode.
- The script does not automatically detect page boundaries, crop margins, or deskew scanned images.
- Processing large or high-resolution PDFs may require significant memory and temporary disk space.

## License

No license has been specified. All rights are reserved unless the copyright holder grants permission separately.

## Author

[SkyHobbit Inc.](https://github.com/skyhobbit)
