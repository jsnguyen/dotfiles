#!/bin/bash
# Defaults
FRAMERATE=30
DEFAULT_OUT="out.mp4"
DISABLE_OVERWRITE=false
REVERSE=false
LOOP_COUNT=1

usage() {
    echo "Usage: $0 [-p framerate] [--framerate framerate] [-d] [--reverse] [--loop N] <input_files...> [output_filename]"
    echo ""
    echo "Options:"
    echo "  -p, --framerate   Framerate (default: 30)"
    echo "  -d                Disable overwrite (increments filename if it exists)"
    echo "  --reverse         Ping-pong: append frames in reverse for a bounce effect"
    echo "  --loop N          Repeat the sequence N times (default: 1)"
    echo ""
    echo "Examples:"
    echo "  $0 img*.png                                  # Overwrites out.mp4"
    echo "  $0 -d img*.png                               # Saves to out.mp4 (or out_1.mp4 if exists)"
    echo "  $0 --framerate 24 img*.png vid.mp4            # Overwrites vid.mp4 at 24fps"
    echo "  $0 -p 24 -d img*.png vid.mp4                  # Saves to vid.mp4 (or vid_1.mp4 if exists)"
    echo "  $0 --reverse img*.png bounce.mp4              # Forward then backward"
    echo "  $0 --reverse --loop 3 img*.png bounce.mp4     # Ping-pong 3 times"
    exit 1
}

# 1. Pre-process long options
args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --framerate) FRAMERATE="$2"; shift 2 ;;
        --reverse)   REVERSE=true; shift ;;
        --loop)      LOOP_COUNT="$2"; shift 2 ;;
        *) args+=("$1"); shift ;;
    esac
done
set -- "${args[@]}"

# 2. Parse short flags
while getopts ":p:d" opt; do
  case ${opt} in
    p) FRAMERATE="$OPTARG" ;;
    d) DISABLE_OVERWRITE=true ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# 3. Handle positional arguments
if [[ "${@: -1}" == *.mp4 ]]; then
    OUTPUT_FILE="${@: -1}"
    INPUT_FILES=("${@:1:$#-1}")
else
    OUTPUT_FILE="$DEFAULT_OUT"
    INPUT_FILES=("$@")
fi

if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    echo "Error: No input files provided."
    usage
fi

# 4. Handle overwrite logic
if [[ "$DISABLE_OVERWRITE" = true ]] && [[ -e "$OUTPUT_FILE" ]]; then
    extension="${OUTPUT_FILE##*.}"
    filename="${OUTPUT_FILE%.*}"
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

# 5. Apply reverse (ping-pong) if requested
if [[ "$REVERSE" = true ]]; then
    reversed=()
    for (( i=${#INPUT_FILES[@]}-2; i>=0; i-- )); do
        reversed+=("${INPUT_FILES[$i]}")
    done
    INPUT_FILES+=("${reversed[@]}")
    echo "Reverse enabled: ${#INPUT_FILES[@]} total frames (forward + backward)"
fi

# 6. Apply looping if requested
if [[ "$LOOP_COUNT" -gt 1 ]]; then
    original=("${INPUT_FILES[@]}")
    for (( l=1; l<LOOP_COUNT; l++ )); do
        INPUT_FILES+=("${original[@]}")
    done
    echo "Looping ${LOOP_COUNT}x: ${#INPUT_FILES[@]} total frames"
fi

echo "Generating video from ${#INPUT_FILES[@]} files -> $OUTPUT_FILE @ $FRAMERATE fps..."

TMPLIST=$(mktemp /tmp/ffmpeg_list_XXXXXX)
for f in "${INPUT_FILES[@]}"; do
    echo "file '$(realpath "$f")'" >> "$TMPLIST"
done

# 7. Execute ffmpeg
ffmpeg -y \
       -r "$FRAMERATE" \
       -f concat \
       -safe 0 \
       -i "$TMPLIST" \
       -vf "pad=iw+mod(iw\,2):ih+mod(ih\,2)" \
       -c:v libx264 \
       -pix_fmt yuv420p \
       "$OUTPUT_FILE"

rm "$TMPLIST"
