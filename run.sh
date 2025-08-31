#!/bin/bash
set -e

# Usage: ./run.sh [path_to_lexer] [test_directory] 
LEXER=$1
TEST_DIR=$2

if [ ! -f "$LEXER" ]; then
    echo "Error: executable '$LEXER' not found!"
    exit 1
fi


# Run lexer on each test file in tests/
for file in $TEST_DIR/*.cpp; do
    echo "=== Running lexer on $file ==="
    ./$LEXER "$file"
    echo
done
