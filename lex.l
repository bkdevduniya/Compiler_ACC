%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int line_val = 1;
extern char* yytext;
%}

%option noyywrap

DIGIT    [-]?[0-9]
ID       [a-zA-Z_][a-zA-Z0-9_]*
WS       [ \t\r]*

%%

"//".*      { /* Skip single line comments */ }
"/*"([^*]|(\*+[^*/]))*"*/" { /* Skip multi-line comments */ }

{WS}        { /* Skip whitespace */ }
\n          { line_val++; }

"if"        { return IF; }
"else"      { return ELSE; }
"switch"    { return SWITCH; }
"case"      { return CASE; }
"default"   { return DEFAULT; }
"for"       { return FOR; }
"while"     { return WHILE; }
"do"        { return DO; }
"break"     { return BREAK; }
"continue"  { return CONTINUE; }
"return"    { return RETURN; }
"goto"      { return GOTO; }

"int"       { return INT; }
"float"     { return FLOAT; }
"double"    { return DOUBLE; }
"char"      { return CHAR; }
"bool"      { return BOOL; }
"void"      { return VOID; }
"long"      { return LONG; }
"short"     { return SHORT; }
"const"     { return CONST; }
"static"    { return STATIC; }
"unsigned"  { return UNSIGNED; }
"auto"      { return AUTO; }
"struct"    { return STRUCT; }
"string"    { return STRING; }
"true"      {return TRUE;}
"false"     {return FALSE;}

"=="        { return EQ; }
"!="        { return NEQ; }
"<="        { return LE; }
">="        { return GE; }
"<"         { return LT; }
">"         { return GT; }

"&&"        { return AND; }
"||"        { return OR; }
"!"         { return NOT; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }
"%"         { return MOD; }

"="         { return ASSIGN; }
"+="        { return PLUS_ASSIGN; }
"-="        { return MINUS_ASSIGN; }
"*="        { return MUL_ASSIGN; }
"/="        { return DIV_ASSIGN; }
"%="        { return MOD_ASSIGN; }

"&"         { return AMP; }
"|"         { return PIPE; }
"^"         { return XOR; }
"<<"        { return SHL; }
">>"        { return SHR; }

"&="        { return AMP_ASSIGN; }
"|="        { return PIPE_ASSIGN; }
"^="        { return XOR_ASSIGN; }
"<<="       { return SHL_ASSIGN; }
">>="       { return SHR_ASSIGN; }

"++"        { return INC; }
"--"        { return DEC; }
"?"         { return QUESTION; }
"::"        { return SCOPE; }
"->"        { return ARROW; }
"."         { return DOT; }
"..."       { return ELLIPSIS; }

";"         { return SEMI; }
"["         { return LBRACK; }
"]"         { return RBRACK; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"("         { return LPAREN; }
")"         { return RPAREN; }
":"         { return COLON; }
","         { return COMMA; }

"cin"  { return STD_CIN; }
"cout" { return STD_COUT; }
"endl"      { return STD_ENDL; }

"va_start"  { return VA_START; }
"va_arg"    { return VA_ARG; }
"va_end"    { return VA_END; }




{DIGIT}+[uU]?[lL]?[lL]? {
    /* Parse integer with optional unsigned/long suffixes */
    char *endptr;
    char *text = strdup(yytext);
    char *ptr = text;
    int base = 10;
    
    /* Check for hexadecimal */
    if (strlen(ptr) > 2 && ptr[0] == '0' && (ptr[1] == 'x' || ptr[1] == 'X')) {
        base = 16;
        ptr += 2;
    }
    /* Check for octal */
    else if (strlen(ptr) > 1 && ptr[0] == '0') {
        base = 8;
        ptr += 1;
    }
    
    /* Remove suffix characters for conversion */
    int len = strlen(ptr);
    while (len > 0 && (ptr[len-1] == 'u' || ptr[len-1] == 'U' || 
                       ptr[len-1] == 'l' || ptr[len-1] == 'L')) {
        ptr[--len] = '\0';
    }
    
    yylval.num = strtol(ptr, &endptr, base);
    free(text);
    return INT_LITERAL;
}




{DIGIT}+"."{DIGIT}*([eE][+-]?{DIGIT}+)?[fFlL]? {
    char *endptr;
    char *text = strdup(yytext);
    
    /* Remove suffix characters */
    int len = strlen(text);
    if (len > 0 && (text[len-1] == 'f' || text[len-1] == 'F' || 
                    text[len-1] == 'l' || text[len-1] == 'L')) {
        text[len-1] = '\0';
    }
    
    yylval.fnum = strtod(text, &endptr);
    free(text);
    return FLOAT_LITERAL;
}



    

"'"([^'\\]|\\[nrt0'"\\])"'" {
    /* Character literal */
    char *str = strdup(yytext);
    yylval.str = str;
    return CHAR_LITERAL;
}

\"([^"\\]|\\[nrt0'"\\])*\" {
    /* String literal - properly handle escape sequences */
    char *str = strdup(yytext);
    yylval.str = str;
    return STRING_LITERAL;
}

{ID}        { 
    yylval.str = strdup(yytext); 
    return IDENTIFIER; 
}

.           { 
    fprintf(stderr, "Invalid character at line %d: '%c'\n", line_val, *yytext); 
    return ERROR; 
}

%%
