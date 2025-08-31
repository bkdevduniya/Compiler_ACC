# Makefile for Flex and Bison

LEX = flex
YACC = bison -d
CC = gcc
CFLAGS = -Wall

# Output executable name
TARGET = parser

# Test cases directory (only .cpp files)
TESTS = $(wildcard tests/*.cpp)

all: $(TARGET)

$(TARGET): lex.yy.c parser.tab.c
	$(CC) $(CFLAGS) -o $(TARGET) lex.yy.c parser.tab.c -lfl

lex.yy.c: lex.l parser.tab.h
	$(LEX) lex.l

parser.tab.c parser.tab.h: parser.y
	$(YACC) parser.y

# Run on all .cpp test cases
run: $(TARGET)
	@if [ -z "$(TESTS)" ]; then \
		echo "No .cpp test files found in tests/"; \
	else \
		for t in $(TESTS); do \
			echo "Running on $$t:"; \
			./$(TARGET) < $$t; \
			echo ""; \
		done; \
	fi

# Run on a single .cpp test case: make run-one FILE=tests/case1.cpp
.PHONY: run-one
run-one: $(TARGET)
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make run-one FILE=tests/yourfile.cpp"; \
		exit 1; \
	fi
	@echo "Running on $(FILE):"
	@./$(TARGET) < $(FILE)

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h $(TARGET)
