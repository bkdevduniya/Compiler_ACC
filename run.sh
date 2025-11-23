#!/bin/bash
set -e

# Build the compiler first
echo "=== Building compiler ==="
make

if [ ! -f "./compiler" ]; then
    echo "Error: compiler executable not found!"
    exit 1
fi

# Create output directory for IR results
mkdir -p ir_output

# Run compiler on each test file
echo "=== Running compiler on test files ==="

# Check different possible test locations
TEST_DIRS=("tests" "../tests" "./tests" "../test")
FOUND_TESTS=0

for TEST_DIR in "${TEST_DIRS[@]}"; do
    if [ -d "$TEST_DIR" ]; then
        echo "Found test directory: $TEST_DIR"
        for file in "$TEST_DIR"/*.cpp; do
            if [ -f "$file" ]; then
                filename=$(basename "$file" .cpp)
                echo "=== Processing $file ==="
                ./compiler "$file" > "ir_output/${filename}.ir" 2>&1
                
                # Also display the IR output
                echo "=== Generated IR for $filename ==="
                cat "ir_output/${filename}.ir"
                echo "======================================"
                echo
                FOUND_TESTS=1
            fi
        done
        break
    fi
done

if [ $FOUND_TESTS -eq 0 ]; then
    echo "No test files found! Creating sample tests..."
    
    # Create sample test files
    mkdir -p tests
    
    cat > tests/simple.cpp << 'EOF'
int main() {
    int a = 5;
    int b = 3;
    int c = a + b;
    return c;
}
EOF

    cat > tests/arithmetic.cpp << 'EOF'
int main() {
    int x = 10;
    int y = 20;
    int z = x * y + 5;
    return z;
}
EOF

    # Now run the tests we just created
    for file in tests/*.cpp; do
        if [ -f "$file" ]; then
            filename=$(basename "$file" .cpp)
            echo "=== Processing $file ==="
            ./compiler "$file" > "ir_output/${filename}.ir" 2>&1
            
            echo "=== Generated IR for $filename ==="
            cat "ir_output/${filename}.ir"
            echo "======================================"
            echo
        fi
    done
fi

echo "All tests completed! IR files saved in ir_output/"
