CC = gcc
CFLAGS = -g -Wall
LEX = flex
YACC = bison
TARGET = compiler

SOURCES = lex.yy.c parser.tab.c 
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS)

# Generate parser first (creates parser.tab.h)
parser.tab.c parser.tab.h: parser.y
	$(YACC) -d -o parser.tab.c $<

# Then generate lexer (needs parser.tab.h)
lex.yy.c: lex.l parser.tab.h
	$(LEX) -o $@ $<

# Object file dependencies
lex.yy.o: lex.yy.c parser.tab.h
	$(CC) $(CFLAGS) -c -o $@ $<

parser.tab.o: parser.tab.c
	$(CC) $(CFLAGS) -c -o $@ $<


clean:
	rm -f $(TARGET) $(OBJECTS) lex.yy.c parser.tab.c parser.tab.h
	rm -rf ir_output

test: $(TARGET)
	./run.sh

.PHONY: all clean test
