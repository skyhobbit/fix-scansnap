#!/bin/bash

set -e

PERCENT=""
SIZE=""

usage() {
    echo "Usage:"
    echo "  $0 -p percent input.pdf"
    echo "  $0 -s size    input.pdf"
    echo
    echo "Options:"
    echo "  -p percent   Apply the same vertical scale to all pages"
    echo "               Example: -p 69.20"
    echo
    echo "  -s size      Adjust each page individually to the specified"
    echo "               paper aspect ratio"
    echo "               Supported: a4, b5"
    echo
    echo "Examples:"
    echo "  $0 -p 69.20 scan.pdf"
    echo "  $0 -s a4 scan.pdf"
    echo "  $0 -s b5 scan.pdf"
    exit 1
}

while getopts "p:s:h" opt; do
    case "$opt" in
        p)
            PERCENT="$OPTARG"
            ;;
        s)
            SIZE=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
    usage
fi

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo "Error: File not found: $INPUT" >&2
    exit 1
fi

# -p and -s are mutually exclusive
if [ -n "$PERCENT" ] && [ -n "$SIZE" ]; then
    echo "Error: -p and -s cannot be used together." >&2
    exit 1
fi

# Either -p or -s must be specified
if [ -z "$PERCENT" ] && [ -z "$SIZE" ]; then
    echo "Error: Specify either -p or -s." >&2
    exit 1
fi

#
# Paper size
#
if [ -n "$SIZE" ]; then
    case "$SIZE" in
        a4)
            PAPER_WIDTH=210
            PAPER_HEIGHT=297
            ;;
        b5)
            PAPER_WIDTH=182
            PAPER_HEIGHT=257
            ;;
        *)
            echo "Error: Unsupported paper size: $SIZE" >&2
            exit 1
            ;;
    esac
fi

DIR="$(dirname "$INPUT")"
FILENAME="$(basename "$INPUT")"
BASE="${FILENAME%.*}"
OUTPUT="${DIR}/${BASE}_corrected.pdf"

#
# -p mode
#
if [ -n "$PERCENT" ]; then

    echo "Mode:     fixed percentage"
    echo "Input:    $INPUT"
    echo "Output:   $OUTPUT"
    echo "Y scale:  ${PERCENT}%"

    magick -density 300 "$INPUT" \
        -resize "100%x${PERCENT}%" \
        "$OUTPUT"

    echo "Created: $OUTPUT"
    exit 0
fi

#
# -s mode
#
echo "Mode:     paper aspect ratio"
echo "Paper:    ${SIZE} (${PAPER_WIDTH}x${PAPER_HEIGHT} mm)"
echo "Input:    $INPUT"
echo "Output:   $OUTPUT"
echo

TMPDIR=$(mktemp -d)

cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

#
# Render PDF pages to PNG at 300 dpi
#
echo "Rendering PDF..."

magick -density 300 "$INPUT" \
    "$TMPDIR/page-%04d.png"

#
# Process each page independently
#
PAGE=1

for FILE in "$TMPDIR"/page-*.png; do

    DIMENSIONS=$(magick identify \
        -format "%w %h" \
        "$FILE")

    WIDTH=$(echo "$DIMENSIONS" | awk '{print $1}')
    HEIGHT=$(echo "$DIMENSIONS" | awk '{print $2}')

    #
    # Target height:
    #
    # width × paper_height / paper_width
    #
    TARGET_HEIGHT=$(awk \
        -v w="$WIDTH" \
        -v pw="$PAPER_WIDTH" \
        -v ph="$PAPER_HEIGHT" \
        'BEGIN {
            printf "%.4f", w * ph / pw
        }')

    #
    # Vertical scale percentage:
    #
    # target_height / current_height × 100
    #
    PAGE_PERCENT=$(awk \
        -v target="$TARGET_HEIGHT" \
        -v current="$HEIGHT" \
        'BEGIN {
            printf "%.4f", target / current * 100
        }')

    echo "Page $PAGE: ${WIDTH}x${HEIGHT} -> Y scale ${PAGE_PERCENT}%"

    magick "$FILE" \
        -resize "100%x${PAGE_PERCENT}%" \
        "$TMPDIR/fixed-$(printf "%04d" "$PAGE").png"

    PAGE=$((PAGE + 1))
done

#
# Combine corrected pages into PDF
#
echo
echo "Creating PDF..."

magick "$TMPDIR"/fixed-*.png "$OUTPUT"

echo "Created: $OUTPUT"
