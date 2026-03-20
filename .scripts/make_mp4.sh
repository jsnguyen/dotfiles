#!/bin/bash

# Defaults
FRAMERATE=30
DEFAULT_OUT="out.mp4"
DISABLE_OVERWRITE=false

usage() {
    echo "Usage: $0 [-p framerate] [-d] <input_glob> [output_filename]"
    echo ""
    echo "Options:"
    echo "  -p   Framerate (default: 30)"
    echo "  -d   Disable overwrite (increments filename if it exists)"
    echo ""
    echo "Examples:"
    echo "  $0 'img*.png'                 # Overwrites out.mp4"
    echo "  $0 -d 'img*.png'              # Saves to out.mp4 (or out_1.mp4 if exists)"
    echo "  $0 'img*.png' vid.mp4         # Overwrites vid.mp4"
    echo "  $0 -d 'img*.png' vid.mp4      # Saves to vid.mp4 (or vid_1.mp4 if exists)"
    exit 1
}

# 1. Parse optional flags
while getopts ":p:d" opt; do
  case ${opt} in
    p) FRAMERATE="$OPTARG" ;;
    d) DISABLE_OVERWRITE=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# 2. Handle Positional Arguments
INPUT_GLOB="$1"
OUTPUT_FILE="${2:-$DEFAULT_OUT}"

if [ -z "$INPUT_GLOB" ]; then
    echo "Error: Missing input glob pattern."
    usage
fi

# 3. Handle Overwrite Logic
# If -d is set AND file exists, we increment to find a safe name.
if [[ "$DISABLE_OVERWRITE" = true ]] && [[ -e "$OUTPUT_FILE" ]]; then
    extension="${OUTPUT_FILE##*.}"
    filename="${OUTPUT_FILE%.*}"

    # Handle files with no extension
    if [[ "$filename" == "$extension" ]]; then extension=""; else extension=".$extension"; fi

    counter=1
    new_name="${filename}_${counter}${extension}"
    while [[ -e "$new_name" ]]; do
        ((counter++))
        new_name="${filename}_${counter}${extension}"
    done
    
    echo "Output '$OUTPUT_FILE' exists (-d set). Saving to '$new_name' instead."
    OUTPUT_FILE="$new_name"
elif [[ -e "$OUTPUT_FILE" ]]; then
    echo "Overwriting '$OUTPUT_FILE'..."
fi

echo "Generating video from '$INPUT_GLOB' -> $OUTPUT_FILE @ $FRAMERATE fps..."

# 4. Execute FFmpeg
# -y forces overwrite.
# If -d was NOT used, this overwrites the existing file.
# If -d WAS used, we calculated a new unique filename above, so -y is harmless.
ffmpeg -y -framerate "$FRAMERATE" \
       -pattern_type glob -i "$INPUT_GLOB" \
       -vf "pad=iw+mod(iw\,2):ih+mod(ih\,2)" \
       -c:v libx264 \
       -pix_fmt yuv420p \
       "$OUTPUT_FILE"
