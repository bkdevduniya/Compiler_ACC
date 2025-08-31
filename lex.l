%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

#define MAX_TOKENS 10000
#define MAX_STR    256

struct Token {
    char *type;
    char *value;
    int line;
};

struct Token tokens[MAX_TOKENS];
int tokenCount = 0;
int line_val = 1, preline = 0;
char preType[MAX_STR] = "";
char preValue[MAX_STR] = "";

/* Utility check function (unchanged from your previous version) */
int check(const char *t1, const char *t2, const char *v1, const char *v2) {
    // Conditional keywords (if, else, switch, case, default)
    if (strcmp(t1, "cond_keyword") == 0) {
        if (strcmp(v2, "(") == 0) return 1;                  // if (
        if (strcmp(v1, "else") == 0 && strcmp(t2, "cond_keyword") == 0) return 1; // else if
        if ((strcmp(v1, "case") == 0 || strcmp(v1, "default") == 0) && strcmp(v2, ":") == 0) return 1;
        return 0;
    }

    // Loop keywords (for, while, do)
    if (strcmp(t1, "loop_keyword") == 0) {
        if (strcmp(v2, "(") == 0) return 1;                  // for( or while(
        if (strcmp(v1, "do") == 0 && strcmp(v2, "{") == 0) return 1; // do {
        return 0;
    }

    // Jump keywords (break, continue, return)
    if (strcmp(t1, "jump_keyword") == 0) {
        if (strcmp(v2, ";") == 0) return 1;                 // break; continue;
        if (strcmp(v1, "return") == 0 &&
            (strcmp(t2, "literal") == 0 || strcmp(t2, "identifier") == 0 || strcmp(v2, "(") == 0))
            return 1;                                       // return expr;
        return 0;
    }

    // Data types
    if (strcmp(t1, "datatype_keyword") == 0) {
        if (strcmp(t2, "identifier") == 0 || strcmp(t2,"operator")==0) return 1;        // int x
        if ((strcmp(v1, "long") == 0||strcmp(v1, "const") == 0|| strcmp(v1,"static")==0||strcmp(v1,"unsigned")==0) && strcmp(t2, "datatype_keyword") == 0 && strcmp(v2, "double") != 0) return 1; // long x
        if (strcmp(v2, "*") == 0 || strcmp(v2, "&") == 0 ||
            strcmp(v2, "(") == 0 || strcmp(v2, ")") == 0 ||
            strcmp(v2, "[") == 0 || strcmp(v2, "]") == 0||
            strcmp(v2, ",")==0)
            return 1;
        return 0;
    }

    // Declaration keywords (class, struct, enum, public, etc.)
    if (strcmp(t1, "declaration_keyword") == 0) {
        if (strcmp(t2, "identifier") == 0 || strcmp(v2, "{") == 0) return 1;
        return 0;
    }

    // Operators
    if (strcmp(t1, "operator") == 0) {
        if (strcmp(t2, "literal") == 0 || strcmp(t2, "identifier") == 0||strcmp(v2,"(")==0 ||strcmp(t2,"datatype_keyword")==0 || strcmp(t2,"operator")==0) return 1; // x + y
        if ((strcmp(v1, "++") == 0 || strcmp(v1, "--") == 0 || strcmp(v1, ":") == 0||strcmp(v1, "*")==0) &&
            (strcmp(v2, ";") == 0 || strcmp(v2, ")") == 0 || strcmp(v2, "]") == 0))
            return 1;
        if (strcmp(v1, "?") == 0 && strcmp(v2, ":") == 0) return 1; // ternary
        if (strcmp(v1, "...") == 0 && (strcmp(v2, ")") == 0 || strcmp(v2, ",") == 0)) return 1;
        if(strcmp(v1,"*")==0&&strcmp(v2,"*")==0) return 1;
        return 0;
    }

    // Literals
    if (strcmp(t1, "literal") == 0) {
        if (strcmp(t2, "operator") == 0 ||
            strcmp(v2, ";") == 0 || strcmp(v2, "]") == 0 || strcmp(v2, ")") == 0 ||
            strcmp(v2, ",") == 0 || strcmp(v2, "}") == 0 || strcmp(v2, ":") == 0)
            return 1;
        return 0;
    }

    // Identifiers
    if (strcmp(t1, "identifier") == 0) {
        if (strcmp(t2, "operator") == 0 || strcmp(t2,"punctuator")==0)
            return 1;
        return 0;
    }

    // Default: any sequence not explicitly handled is considered valid
    return 1;
}


int addToken(const char *type, const char *value, int line) {
    if (preType[0] != '\0') {
        if (!check(preType, type, preValue, value)) {
            fprintf(stderr, "INVALID TOKEN : [%s:%s] -> [%s:%s] at line %d\n",
                    preType, preValue, type, value, line);
            return 0;
        }
    }
    strncpy(preType, type, MAX_STR-1);
    strncpy(preValue, value, MAX_STR-1);
    preline = line;

    if (tokenCount < MAX_TOKENS) {
        tokens[tokenCount].type  = strdup(preType);
        tokens[tokenCount].value = strdup(preValue);
        tokens[tokenCount].line  = line;
        tokenCount++;
    }
   return 1;
}

%}
INVALID_COMMENTS ("/*"([^*]|[\r\n]|"*"[^/])*([^*][/]|[*][^/]|[^*][^/]))
INVALID_STR (\"([^"\\\n]|\\.)*[^\"])
%%

[ \t\r]+                { preType[0]='\0'; preValue[0]='\0'; }
\r?\n                   { line_val++; preType[0]='\0'; preValue[0]='\0'; }

"//".*                  {}
"/*"([^*]|[\r\n]|"*"[^/])*"*/"  {}
INVALID_COMMENTS         { printf("invalid_comment");return ERROR;}
INVALID_STR               {printf("invalid_string"); return ERROR;}
                                   
"if"                     { if(addToken("cond_keyword","if",line_val)) return IF; }
"else"                   { if(addToken("cond_keyword","else",line_val)) return ELSE; }
"switch"                 { if(addToken("cond_keyword","switch",line_val)) return SWITCH; }
"case"                   { if(addToken("cond_keyword","case",line_val)) return CASE; }
"default"                { if(addToken("cond_keyword","default",line_val)) return DEFAULT; }
"for"                    { if(addToken("loop_keyword","for",line_val)) return FOR; }
"while"                  { if(addToken("loop_keyword","while",line_val)) return WHILE; }
"do"                     { if(addToken("loop_keyword","do",line_val)) return DO; }
"break"                  { if(addToken("jump_keyword","break",line_val)) return BREAK; }
"continue"               { if(addToken("jump_keyword","continue",line_val)) return CONTINUE; }
"return"                 { if(addToken("jump_keyword","return",line_val)) return RETURN; }

"int"                    { if(addToken("datatype_keyword","int",line_val)) return INT; }
"float"                  { if(addToken("datatype_keyword","float",line_val)) return FLOAT; }
"double"                 { if(addToken("datatype_keyword","double",line_val)) return DOUBLE; }
"char"                   { if(addToken("datatype_keyword","char",line_val)) return CHAR; }
"bool"                   { if(addToken("datatype_keyword","bool",line_val)) return BOOL; }
"void"                   { if(addToken("datatype_keyword","void",line_val)) return VOID; }
"long"                   { if(addToken("datatype_keyword","long",line_val)) return LONG; }
"short"                  { if(addToken("datatype_keyword","short",line_val)) return SHORT; }
"const"                  { if(addToken("datatype_keyword","const",line_val)) return CONST; }
"static"                 { if(addToken("datatype_keyword","static",line_val)) return STATIC;else printf("lex fail"); }
"unsigned"               { if(addToken("datatype_keyword","unsigned",line_val)) return UNSIGNED;else printf("lex fail"); }
"auto"                   { if(addToken("datatype_keyword","auto",line_val)) return AUTO;else printf("lex fail"); }

"class"                  { if(addToken("declaration_keyword","class",line_val)) return CLASS; }
"struct"                 { if(addToken("declaration_keyword","struct",line_val)) return STRUCT; }
"enum"                   { if(addToken("declaration_keyword","enum",line_val)) return ENUM; }
"public"                 { if(addToken("declaration_keyword","public",line_val)) return PUBLIC; }
"protected"              { if(addToken("declaration_keyword","protected",line_val)) return PROTECTED; }
"private"                { if(addToken("declaration_keyword","private",line_val)) return PRIVATE; }

"std::cout"              { if(addToken("identifier","std::cout",line_val)) return STD_COUT; }
"std::cin"               { if(addToken("identifier","std::cin",line_val)) return STD_CIN; }

"va_arg"                { if(addToken("identifier","va_arg",line_val)) return VA_ARG; }
"va_end"                { if(addToken("identifier","va_end",line_val)) return VA_END; }
"va_start"              { if(addToken("identifier","va_start",line_val)) return VA_START; }

"++"                     { if(addToken("operator","++",line_val)) return INC; }
"--"                     { if(addToken("operator","--",line_val)) return DEC; }
"+"                      { if(addToken("operator","+",line_val)) return PLUS; }
"-"                      { if(addToken("operator","-",line_val)) return MINUS; }
"*="                     { if(addToken("operator","*=",line_val)) return MUL_ASSIGN; }
"/="                     { if(addToken("operator","/=",line_val)) return DIV_ASSIGN; }
"%="                     { if(addToken("operator","%=",line_val)) return MOD_ASSIGN; }
"+="                     { if(addToken("operator","+=",line_val)) return PLUS_ASSIGN; }
"-="                     { if(addToken("operator","-=",line_val)) return MINUS_ASSIGN; }
"*"                      { if(addToken("operator","*",line_val)) return MUL; }
"/"                      { if(addToken("operator","/",line_val)) return DIV; }
"%"                      { if(addToken("operator","%",line_val)) return MOD; }
"="                      { if(addToken("operator","=",line_val)) return ASSIGN; }
"=="                     { if(addToken("operator","==",line_val)) return EQ; }
"!="                     { if(addToken("operator","!=",line_val)) return NEQ; }
"<"                      { if(addToken("operator","<",line_val)) return LT; }
">"                      { if(addToken("operator",">",line_val)) return GT; }
"<="                     { if(addToken("operator","<=",line_val)) return LE; }
">="                     { if(addToken("operator",">=",line_val)) return GE; }
"&&"                     { if(addToken("operator","&&",line_val)) return AND; }
"||"                     { if(addToken("operator","||",line_val)) return OR; }
"!"                      { if(addToken("operator","!",line_val)) return NOT; }
"&"                      { if(addToken("operator","&",line_val)) return AMP; }
"|"                      { if(addToken("operator","|",line_val)) return PIPE; }
"^"                      { if(addToken("operator","^",line_val)) return XOR; }
"|="                     { if(addToken("operator","|=",line_val)) return PIPE_ASSIGN; }
"&="                     { if(addToken("operator","&=",line_val)) return AMP_ASSIGN; }
"^="                     { if(addToken("operator","^=",line_val)) return XOR_ASSIGN; }
"<<"                     { if(addToken("operator","<<",line_val)) return SHL; }
">>"                     { if(addToken("operator",">>",line_val)) return SHR; }
"<<="                    { if(addToken("operator","<<=",line_val)) return SHL_ASSIGN; }
">>="                     { if(addToken("operator",">>=",line_val)) return SHR_ASSIGN; }
"?"                      { if(addToken("operator","?",line_val)) return QUESTION; }
":"                      { if(addToken("punctuator",":",line_val)) return COLON; }
"."                      { if(addToken("operator",".",line_val)) return DOT; }
"->"                     { if(addToken("operator","->",line_val)) return ARROW; }
"::"                     { if(addToken("operator","::",line_val)) return SCOPE; }
"..."                    { if(addToken("operator","...",line_val)) return ELLIPSIS; }


";"                      { if(addToken("punctuator",";",line_val)) return SEMI; }
","                      { if(addToken("punctuator",",",line_val)) return COMMA; }
"("                      { if(addToken("punctuator","(",line_val)) return LPAREN; }
")"                      { if(addToken("punctuator",")",line_val)) return RPAREN; }
"{"                      { if(addToken("punctuator","{",line_val)) return LBRACE; }
"}"                      { if(addToken("punctuator","}",line_val)) return RBRACE; }
"["                      { if(addToken("punctuator","[",line_val)) return LBRACK; }
"]"                      { if(addToken("punctuator","]",line_val)) return RBRACK; }


\"([^"\\\n]|\\.)*\"      { if(addToken("literal", yytext, line_val)) return STRING; }
\'([^\\'\n]|\\.)\'       { if(addToken("literal", yytext, line_val)) return CHAR_LITERAL; }
([0-9]+|[0-9]+([eE][-+]?[0-9]+)|[0-9]+[L][L])                   { if(addToken("literal", yytext, line_val)) return INT_LITERAL; }
([0-9]+\.[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+|[0-9]+\.[0-9]*[L][L])? { if(addToken("literal", yytext, line_val)) return FLOAT_LITERAL; }


[a-zA-Z_][a-zA-Z0-9_]*   { yylval.str = strdup(yytext); if(addToken("identifier", yytext, line_val)) return IDENTIFIER; }


.                        {
                            fprintf(stderr,"Error: UNRECOGNIZED TOKEN %s at line %d\n", yytext,line_val);
                            preType[0]='\0'; preValue[0]='\0';
                            return ERROR;
                          }

%%


