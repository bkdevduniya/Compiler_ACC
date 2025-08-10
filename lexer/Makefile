# Compiler and tools
CXX = g++
CXXFLAGS = -std=c++17 -Wall
LEX = flex

# Files
LEX_FILE = lex.l
LEX_CPP = lex.cpp
EXEC = lexer
TEST_DIR= tests

# Default target: build
all: $(EXEC)
compile:$(EXEC)

# Link executable from lex.cpp
$(EXEC): $(LEX_CPP)
	$(CXX) $(CXXFLAGS) -o $@ $<

# Generate lex.cpp from lex.l
$(LEX_CPP): $(LEX_FILE)
	$(LEX) --c++ -o $@ $<

# Run all tests
test: compile
	@echo "Running all tests..."
	@./run.sh $(EXEC) $(TEST_DIR)

# Run individual test
test-%: compile
	@echo "Running $*..."
	@./$(EXEC) $(TEST_DIR)/$*.cpp

# Clean generated files
clean:
	rm -f $(EXEC) $(LEX_CPP)

.PHONY: all clean
