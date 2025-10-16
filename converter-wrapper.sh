#!/bin/bash
# Wrapper script for gocesiumtiler that auto-generates output directory names
# based on input file names and converts LAZ to LAS automatically

set -e

# Temporary directory for LAZ conversions
TEMP_DIR="/tmp/las_conversion_$$"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Function to process a single file with gocesiumtiler
process_single_file() {
    local input_file="$1"
    local output_dir="$2"
    shift 2
    local extra_args=("$@")
    
    echo "========================================="
    echo "Processing: $(basename "$input_file")"
    echo "Output: $output_dir"
    echo "========================================="
    
    # Convert LAZ to LAS if needed
    local processed_file="$input_file"
    if [[ "$input_file" == *.laz ]]; then
        mkdir -p "$TEMP_DIR"
        local base_name=$(get_base_name "$input_file")
        processed_file="$TEMP_DIR/${base_name}.las"
        convert_laz_to_las "$input_file" "$processed_file"
    fi
    
    # Run gocesiumtiler
    gocesiumtiler file --out "$output_dir" "${extra_args[@]}" "$processed_file"
    
    echo "Completed: $(basename "$input_file")"
    echo ""
}

# Function to extract base filename without extension
get_base_name() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    # Remove .las or .laz extension
    echo "${filename%.*}"
}

# Function to convert LAZ to LAS
convert_laz_to_las() {
    local input_file="$1"
    local output_file="$2"
    echo "Converting LAZ to LAS: $(basename "$input_file") -> $(basename "$output_file")"
    laszip -i "$input_file" -o "$output_file"
}



# Check if we have arguments
if [ $# -eq 0 ]; then
    exec gocesiumtiler --help
    exit 0
fi

# Parse command to determine if it's file, folder, or batch mode
COMMAND="$1"
shift

# Handle batch mode separately
if [ "$COMMAND" = "batch" ]; then
    INPUT_DIR=""
    OUTPUT_BASE="/output"
    EXTRA_ARGS=()
    
    # Parse batch mode arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -o|--out)
                OUTPUT_BASE="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: batch [options] <input-directory>"
                echo ""
                echo "Process each LAS/LAZ file in a directory separately, creating individual output folders."
                echo ""
                echo "Options:"
                echo "  -o, --out <dir>          Base output directory (default: /output)"
                echo "  --crs, --epsg <code>     Input CRS (EPSG code)"
                echo "  --resolution <meters>    Grid cell size (default: 20)"
                echo "  --depth <levels>         Max tree depth (default: 10)"
                echo "  --min-points-per-tile <n> Min points per tile (default: 5000)"
                echo ""
                echo "Output structure:"
                echo "  <output-base>/"
                echo "    ├── file1/"
                echo "    │   └── tileset.json"
                echo "    ├── file2/"
                echo "    │   └── tileset.json"
                echo "    └── ..."
                exit 0
                ;;
            -*)
                # Collect other flags for passing to gocesiumtiler
                EXTRA_ARGS+=("$1")
                if [ $# -gt 1 ] && [[ ! "$2" =~ ^- ]]; then
                    EXTRA_ARGS+=("$2")
                    shift
                fi
                shift
                ;;
            *)
                INPUT_DIR="$1"
                shift
                ;;
        esac
    done
    
    # Validate input directory
    if [ -z "$INPUT_DIR" ] || [ ! -d "$INPUT_DIR" ]; then
        echo "Error: Valid input directory required for batch mode"
        exit 1
    fi
    
    # Find all LAS and LAZ files
    shopt -s nullglob
    FILES=("$INPUT_DIR"/*.las "$INPUT_DIR"/*.laz)
    shopt -u nullglob
    
    if [ ${#FILES[@]} -eq 0 ]; then
        echo "Error: No LAS or LAZ files found in $INPUT_DIR"
        exit 1
    fi
    
    echo "========================================"
    echo "BATCH MODE: Processing ${#FILES[@]} file(s)"
    echo "========================================"
    echo ""
    
    # Process each file
    for file in "${FILES[@]}"; do
        base_name=$(get_base_name "$file")
        output_dir="$OUTPUT_BASE/$base_name"
        process_single_file "$file" "$output_dir" "${EXTRA_ARGS[@]}"
    done
    
    echo "========================================"
    echo "BATCH COMPLETE: ${#FILES[@]} file(s) processed"
    echo "Output location: $OUTPUT_BASE"
    echo "========================================"
    
    exit 0
fi

# Variables to track
OUTPUT_SPECIFIED=false
OUTPUT_DIR=""
INPUT_PATH=""
ARGS=()

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -o|--out)
            OUTPUT_SPECIFIED=true
            OUTPUT_DIR="$2"
            ARGS+=("$1" "$2")
            shift 2
            ;;
        --help|-h)
            exec gocesiumtiler "$COMMAND" --help
            exit 0
            ;;
        -*)
            # Other flags
            ARGS+=("$1")
            if [ $# -gt 1 ] && [[ ! "$2" =~ ^- ]]; then
                ARGS+=("$2")
                shift
            fi
            shift
            ;;
        *)
            # This should be the input path
            INPUT_PATH="$1"
            ARGS+=("$1")
            shift
            ;;
    esac
done

# If output was not specified, generate it from input
if [ "$OUTPUT_SPECIFIED" = false ] && [ -n "$INPUT_PATH" ]; then
    if [ "$COMMAND" = "file" ]; then
        # For single file: use the filename without extension
        BASE_NAME=$(get_base_name "$INPUT_PATH")
        OUTPUT_DIR="/output/${BASE_NAME}"
        echo "Auto-generated output directory: $OUTPUT_DIR"
        ARGS=("--out" "$OUTPUT_DIR" "${ARGS[@]}")
    elif [ "$COMMAND" = "folder" ]; then
        # For folder: use the folder name
        FOLDER_NAME=$(basename "$INPUT_PATH")
        OUTPUT_DIR="/output/${FOLDER_NAME}"
        echo "Auto-generated output directory: $OUTPUT_DIR"
        ARGS=("--out" "$OUTPUT_DIR" "${ARGS[@]}")
    fi
fi

# Execute gocesiumtiler with all arguments
exec gocesiumtiler "$COMMAND" "${ARGS[@]}"
