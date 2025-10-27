# Makefile for Flex and Bison with LLVM integration

LEX = flex
YACC = bison -d
CC = gcc
CXX = g++
CFLAGS = -Wall -g
LLVM_CONFIG = llvm-config

# Output executable names
PARSER_TARGET = parser
COMPILER_TARGET = my_compiler

# Test cases directory (only .cpp files)
TESTS = $(wildcard tests/*.cpp)

# LLVM configuration
LLVM_CFLAGS = $(shell $(LLVM_CONFIG) --cflags 2>/dev/null || echo "")
LLVM_LDFLAGS = $(shell $(LLVM_CONFIG) --ldflags 2>/dev/null || echo "")
LLVM_LIBS = $(shell $(LLVM_CONFIG) --libs core 2>/dev/null || echo "")
LLVM_SYSLIBS = $(shell $(LLVM_CONFIG) --system-libs 2>/dev/null || echo "")

# Check if LLVM is available
LLVM_AVAILABLE = $(shell which $(LLVM_CONFIG) >/dev/null 2>&1 && echo "yes" || echo "no")

.PHONY: all parser compiler check-llvm install-llvm run run-one clean

all: check-llvm compiler

# Main compiler target with LLVM
compiler: check-llvm lex.yy.c parser.tab.c
	@echo "Building compiler with LLVM support..."
	$(CXX) $(CFLAGS) $(LLVM_CFLAGS) -o $(COMPILER_TARGET) lex.yy.c parser.tab.c \
		$(LLVM_LDFLAGS) $(LLVM_LIBS) $(LLVM_SYSLIBS) -lfl
	@echo "Compiler built successfully: $(COMPILER_TARGET)"

# Parser only (without LLVM)
parser: lex.yy.c parser.tab.c
	$(CC) $(CFLAGS) -o $(PARSER_TARGET) lex.yy.c parser.tab.c -lfl

lex.yy.c: lex.l parser.tab.h
	$(LEX) lex.l

parser.tab.c parser.tab.h: parser.y
	$(YACC) parser.y

# Check if LLVM is installed and install if needed
check-llvm:
	@if [ "$(LLVM_AVAILABLE)" = "no" ]; then \
		echo "LLVM not found. Please install it manually:"; \
		echo "  sudo apt install llvm clang llvm-dev libclang-dev"; \
		echo "Then run 'make' again."; \
		exit 1; \
	else \
		echo "LLVM found: $(shell $(LLVM_CONFIG) --version)"; \
	fi

# Manual installation for Ubuntu 24.04
install-llvm:
	@echo "Installing LLVM for Ubuntu 24.04..."
	sudo apt update
	sudo apt install -y llvm clang llvm-dev libclang-dev
	@echo "LLVM installation completed. Please run 'make' again."

# Check what LLVM packages are available
find-llvm:
	@echo "Searching for LLVM packages..."
	apt-cache search llvm | grep -E "^llvm-[0-9]+" | head -10
	@echo ""
	@echo "Searching for clang packages..."
	apt-cache search clang | grep -E "^clang-[0-9]+" | head -10

# Try to detect and install the correct version
auto-install-llvm:
	@echo "Attempting to auto-detect and install LLVM..."
	@if dpkg -l | grep -q "llvm-"; then \
		echo "Some LLVM packages are already installed:"; \
		dpkg -l | grep llvm | head -10; \
	fi
	@echo "Installing LLVM development packages..."
	sudo apt update
	sudo apt install -y build-essential
	sudo apt install -y llvm clang
	@if apt-cache show llvm-dev > /dev/null 2>&1; then \
		echo "Installing llvm-dev..."; \
		sudo apt install -y llvm-dev; \
	else \
		echo "llvm-dev not available, trying alternative..."; \
		sudo apt install -y libllvm-dev; \
	fi
	@if apt-cache show libclang-dev > /dev/null 2>&1; then \
		echo "Installing libclang-dev..."; \
		sudo apt install -y libclang-dev; \
	fi
	@echo "Installation completed. Please run 'make' again."

# Compile without LLVM (parser only)
no-llvm: parser
	@echo "Built parser without LLVM support: $(PARSER_TARGET)"

# Compile a C++ file to LLVM IR and executable
compile: compiler
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make compile FILE=yourfile.cpp"; \
		exit 1; \
	fi
	@echo "Compiling $(FILE) to LLVM IR and executable..."
	@./$(COMPILER_TARGET) < $(FILE) 2>/dev/null || true
	@if [ -f "output.ll" ]; then \
		echo "Generated output.ll"; \
		echo "Compiling LLVM IR to executable..."; \
		clang output.ll -o $(basename $(FILE)).out 2>/dev/null && \
		echo "Executable created: $(basename $(FILE)).out" || \
		echo "Failed to compile LLVM IR to executable"; \
	else \
		echo "No LLVM IR generated"; \
	fi

# Run the compiler on all test cases and generate executables
run-all: compiler
	@if [ -z "$(TESTS)" ]; then \
		echo "No .cpp test files found in tests/"; \
	else \
		for t in $(TESTS); do \
			echo "Processing $$t..."; \
			./$(COMPILER_TARGET) < $$t 2>/dev/null || true; \
			if [ -f "output.ll" ]; then \
				echo "  Generated LLVM IR"; \
				clang output.ll -o $$(basename $$t .cpp).out 2>/dev/null && \
				echo "  Created executable: $$(basename $$t .cpp).out" || \
				echo "  Failed to create executable"; \
				rm -f output.ll; \
			else \
				echo "  No LLVM IR generated"; \
			fi; \
			echo ""; \
		done; \
	fi

# Run on all .cpp test cases (parser only)
run: parser
	@if [ -z "$(TESTS)" ]; then \
		echo "No .cpp test files found in tests/"; \
	else \
		for t in $(TESTS); do \
			echo "Running parser on $$t:"; \
			./$(PARSER_TARGET) < $$t; \
			echo ""; \
		done; \
	fi

# Run on a single .cpp test case: make run-one FILE=tests/case1.cpp
run-one: parser
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make run-one FILE=tests/yourfile.cpp"; \
		exit 1; \
	fi
	@echo "Running parser on $(FILE):"
	@./$(PARSER_TARGET) < $(FILE)

# Test the full compilation pipeline
test: compiler
	@echo "Testing full compilation pipeline..."
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test FILE=yourfile.cpp"; \
		exit 1; \
	fi
	@echo "Step 1: Parsing and generating LLVM IR..."
	@./$(COMPILER_TARGET) < $(FILE) > /dev/null 2>&1
	@if [ -f "output.ll" ]; then \
		echo "✓ LLVM IR generated successfully"; \
		echo "Step 2: Compiling LLVM IR to executable..."; \
		clang output.ll -o test_executable 2>/dev/null; \
		if [ -f "test_executable" ]; then \
			echo "✓ Executable created successfully"; \
			echo "Step 3: Running the executable..."; \
			./test_executable; \
			rm -f test_executable output.ll; \
		else \
			echo "✗ Failed to create executable"; \
		fi; \
	else \
		echo "✗ Failed to generate LLVM IR"; \
	fi

# Show LLVM configuration info
llvm-info:
	@if [ "$(LLVM_AVAILABLE)" = "yes" ]; then \
		echo "LLVM Version: $(shell $(LLVM_CONFIG) --version)"; \
		echo "CFLAGS: $(LLVM_CFLAGS)"; \
		echo "LDFLAGS: $(LLVM_LDFLAGS)"; \
		echo "LIBS: $(LLVM_LIBS)"; \
		echo "SYSLIBS: $(LLVM_SYSLIBS)"; \
	else \
		echo "LLVM not available"; \
	fi

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h $(PARSER_TARGET) $(COMPILER_TARGET) output.ll *.out test_executable

# Help target
help:
	@echo "Available targets:"
	@echo "  all               - Build compiler with LLVM support (default)"
	@echo "  compiler          - Build compiler with LLVM support"
	@echo "  parser            - Build parser only (without LLVM)"
	@echo "  no-llvm           - Build parser without LLVM"
	@echo "  install-llvm      - Install LLVM for Ubuntu 24.04"
	@echo "  auto-install-llvm - Auto-detect and install LLVM"
	@echo "  find-llvm         - Search for available LLVM packages"
	@echo "  compile           - Compile a C++ file: make compile FILE=file.cpp"
	@echo "  run-all           - Process all test files and generate executables"
	@echo "  run               - Run parser on all test files"
	@echo "  run-one           - Run parser on single file: make run-one FILE=file.cpp"
	@echo "  test              - Full pipeline test: make test FILE=file.cpp"
	@echo "  llvm-info         - Show LLVM configuration"
	@echo "  clean             - Clean all generated files"
	@echo "  help              - Show this help message"
