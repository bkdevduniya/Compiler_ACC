%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int yylex(void);
extern FILE *yyin;
extern int line_val;
extern char* yytext;
void yyerror(const char *s);

void print_symbol_table();
typedef struct Symbol {
    char *name;
    char *type;
} Symbol;

char* current_type=NULL;
char* current_decl_mod = NULL;
#define MAX_SYMBOLS 1000
Symbol symtab[MAX_SYMBOLS];
int symcount = 0;

void add_symbol(const char *name, const char *type) {
    if (!name || !type) {
        fprintf(stderr, "add_symbol: NULL name/type\n");
        return;
    }
    if (symcount < MAX_SYMBOLS) {
        symtab[symcount].name = strdup(name);
        symtab[symcount].type = strdup(type);
        symcount++;
    }
}
%}

/* Semantic values */
%union {
    char* str;
    int   num;
    double fnum;
}

/* ---------------- Tokens from lexer ---------------- */
%token IF ELSE SWITCH CASE DEFAULT
%token FOR WHILE DO
%token BREAK CONTINUE RETURN
%token INT FLOAT DOUBLE CHAR BOOL VOID LONG SHORT CONST STATIC UNSIGNED AUTO
%token CLASS STRUCT ENUM PUBLIC PROTECTED PRIVATE
%token GT LT LE GE NEQ EQ
%token AND OR NOT
%token PLUS MINUS MUL DIV MOD
%token ASSIGN
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
%token PIPE_ASSIGN AMP_ASSIGN XOR_ASSIGN SHL_ASSIGN SHR_ASSIGN OR_ASSIGN AND_ASSIGN
%token AMP PIPE XOR SHL SHR
%token INC DEC QUESTION SCOPE ARROW DOT ELLIPSIS
%token SEMI LBRACK RBRACK LBRACE RBRACE LPAREN RPAREN COLON COMMA
%token <str> STRING CHAR_LITERAL IDENTIFIER
%token <num> INT_LITERAL
%token <fnum> FLOAT_LITERAL
%token STD_CIN STD_COUT
%token VA_START VA_ARG VA_END
%token ERROR

/* ---------------- Precedence & associativity ---------------- */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%left COMMA
%left OR
%left AND
%left PIPE
%left XOR
%left AMP
%left EQ NEQ
%left LT GT LE GE
%left SHL SHR
%left PLUS MINUS
%left MUL DIV MOD
%left DOT ARROW SCOPE
%right NOT UMINUS
%right QUESTION COLON
%right ASSIGN PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
%right OR_ASSIGN AMP_ASSIGN XOR_ASSIGN SHL_ASSIGN SHR_ASSIGN
%left GREATER  /* to handle >> in templates */

%type <str> type type_val declarator multi_ptr

%start program

%%

program
    :
    | program element
    ;

element
    : declaration
    | function_dec
    | function_def
    | statement
    | compound_stmt
    ;

/* ---------------- Declarations ---------------- */
multi_ptr
    :
    | multi_ptr MUL {
        char *old = $1;
        size_t n = old ? strlen(old) : 0;
        char *buf = malloc(n + 2);
        if(old) { strcpy(buf, old); free(old); } else buf[0]='\0';
        buf[n] = '*';
        buf[n+1] = '\0';
        $$ = buf;
      }
    ;

declaration
    : type declarator SEMI {
        if (current_type) { free(current_type); current_type = NULL; }
        current_type = strdup($1);

        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod) > 0) {
            snprintf(classif, sizeof(classif), "%s%s", current_type, current_decl_mod);
        } else {
            snprintf(classif, sizeof(classif), "%s", current_type);
        }

        add_symbol($2, classif);

        if (current_decl_mod) { free(current_decl_mod); current_decl_mod = NULL; }
        free(current_type); current_type = NULL;
    }
    | type declarator ASSIGN expression SEMI {
        if (current_type) { free(current_type); current_type = NULL; }
        current_type = strdup($1);

        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod) > 0) {
            snprintf(classif, sizeof(classif), "%s%s", current_type, current_decl_mod);
        } else {
            snprintf(classif, sizeof(classif), "%s", current_type);
        }

        add_symbol($2, classif);

        if (current_decl_mod) { free(current_decl_mod); current_decl_mod = NULL; }
        free(current_type); current_type = NULL;
    }
    | type declarator ASSIGN initializer SEMI {
        if (current_type) { free(current_type); current_type = NULL; }
        current_type = strdup($1);

        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod) > 0) {
            snprintf(classif, sizeof(classif), "%s%s", current_type, current_decl_mod);
        } else {
            snprintf(classif, sizeof(classif), "%s", current_type);
        }

        add_symbol($2, classif);

        if (current_decl_mod) { free(current_decl_mod); current_decl_mod = NULL; }
        free(current_type); current_type = NULL;
    }
    ;

/* ---------------- Declarators ---------------- */
declarator
    : IDENTIFIER { $$ = $1; if (!current_decl_mod) current_decl_mod = NULL; }
    | multi_ptr IDENTIFIER {
        $$ = $2;
        int stars = strlen($1);
        free($1);

        if (stars > 0) {
            int needed = stars * 7 + 1;
            char *mod = malloc(needed);
            mod[0]='\0';
            for (int i=0;i<stars;i++) strcat(mod,"Pointer");
            if (current_decl_mod) {
                char *newmod = malloc(strlen(current_decl_mod)+strlen(mod)+1);
                strcpy(newmod,current_decl_mod);
                strcat(newmod,mod);
                free(current_decl_mod);
                free(mod);
                current_decl_mod = newmod;
            } else current_decl_mod = mod;
        }
    }
    | AMP IDENTIFIER {
        $$ = $2;
        if (current_decl_mod) {
            char *newmod = malloc(strlen(current_decl_mod)+strlen("Referenced")+1);
            strcpy(newmod,current_decl_mod);
            strcat(newmod,"Referenced");
            free(current_decl_mod);
            current_decl_mod = newmod;
        } else current_decl_mod = strdup("Referenced");
    }
    | declarator LBRACK expression RBRACK {
        $$ = $1;
        if (current_decl_mod) {
            char *newmod = malloc(strlen(current_decl_mod)+strlen("Array")+1);
            strcpy(newmod,current_decl_mod);
            strcat(newmod,"Array");
            free(current_decl_mod);
            current_decl_mod = newmod;
        } else current_decl_mod = strdup("Array");
    }
    ;

/* ---------------- Array initializer ---------------- */
initializer
    : expression
    | LBRACE init_list RBRACE
    ;

init_list
    : expression
    | init_list COMMA expression
    ;

/* ---------------- Types ---------------- */
type
    : type_val { $$ = $1; }
    | type type_val {
        const char *s1 = $1 ? $1 : "";
        const char *s2 = $2 ? $2 : "";
        char *buf = malloc(strlen(s1)+strlen(s2)+2);
        sprintf(buf,"%s %s",s1,s2);
        $$ = buf;
    }
    | type type_val type_val {
        char *buf = malloc(strlen($1)+strlen($2)+strlen($3)+3);
        sprintf(buf,"%s %s %s",$1,$2,$3);
        $$ = buf;
    }
    ;

/* ---------------- Type values (including templates and long long) ---------------- */
type_val
    : INT       { $$ = strdup("int"); }
    | FLOAT     { $$ = strdup("float"); }
    | DOUBLE    { $$ = strdup("double"); }
    | CHAR      { $$ = strdup("char"); }
    | BOOL      { $$ = strdup("bool"); }
    | VOID      { $$ = strdup("void"); }
    | LONG      { $$ = strdup("long"); }
    | LONG LONG { $$ = strdup("long long"); }
    | SHORT     { $$ = strdup("short"); }
    | CONST     { $$ = strdup("const"); }
    | STATIC    { $$ = strdup("static"); }
    | UNSIGNED  { $$ = strdup("unsigned"); }
    | AUTO      { $$ = strdup("auto"); }
    | CLASS     { $$ = strdup("class"); }
    | STRUCT    { $$ = strdup("struct"); }
    | ENUM      { $$ = strdup("enum"); }
    | IDENTIFIER { $$ = $1; }
    | IDENTIFIER LT type GT {
        size_t len = strlen($1)+2+strlen($3)+1;
        char *buf = malloc(len);
        sprintf(buf,"%s<%s>",$1,$3);
        $$ = buf;
    }
    | IDENTIFIER LT  type COMMA type GT {
        size_t len = strlen($1)+strlen($3)+strlen($5)+5;
        char *buf = malloc(len);
        sprintf(buf,"%s<%s,%s>",$1,$3,$5);
        $$ = buf;
    }
    ;

/* ---------------- Functions ---------------- */
function_dec
    : type IDENTIFIER LPAREN params_opt RPAREN SEMI {
        char *base = strdup($1);
        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod)>0)
            snprintf(classif,sizeof(classif),"%s%sFunction",base,current_decl_mod);
        else snprintf(classif,sizeof(classif),"%sFunction",base);
        add_symbol($2,classif);
        if (current_decl_mod) { free(current_decl_mod); current_decl_mod=NULL; }
        free(base);
    }
    | type multi_ptr IDENTIFIER LPAREN params_opt RPAREN SEMI {
        char *base = strdup($1);
        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod)>0)
            snprintf(classif,sizeof(classif),"%s%sFunction",base,current_decl_mod);
        else snprintf(classif,sizeof(classif),"%sFunction",base);
        add_symbol($3,classif);
        if (current_decl_mod) { free(current_decl_mod); current_decl_mod=NULL; }
        free(base);
    }
    | type LPAREN multi_ptr IDENTIFIER RPAREN LPAREN params_opt RPAREN SEMI
    | type LPAREN multi_ptr IDENTIFIER LBRACK expression RBRACK RPAREN LPAREN params_opt RPAREN SEMI
    ;

/* ---------------- Function definitions ---------------- */
function_def
    : type IDENTIFIER LPAREN params_opt RPAREN {
        char *base = strdup($1);
        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod)>0)
            snprintf(classif,sizeof(classif),"%s%sFunction",base,current_decl_mod);
        else snprintf(classif,sizeof(classif),"%sFunction",base);
        add_symbol($2,classif);
        if (current_decl_mod) { free(current_decl_mod); current_decl_mod=NULL; }
        free(base);
    }
    | type multi_ptr IDENTIFIER LPAREN params_opt RPAREN compound_stmt {
        char *base = strdup($1);
        char classif[512];
        if (current_decl_mod && strlen(current_decl_mod)>0)
            snprintf(classif,sizeof(classif),"%s%sFunction",base,current_decl_mod);
        else snprintf(classif,sizeof(classif),"%sFunction",base);
        add_symbol($3,classif);
        if (current_decl_mod) { free(current_decl_mod); current_decl_mod=NULL; }
        free(base);
    }
    | type LPAREN multi_ptr IDENTIFIER RPAREN LPAREN params_opt RPAREN compound_stmt
    | type LPAREN multi_ptr IDENTIFIER LBRACK expression RBRACK RPAREN LPAREN params_opt RPAREN compound_stmt
    ;

/* ---------------- Parameters ---------------- */
params_opt
    :
    | param_list_dec
    ;

param_list_dec
    : param_decl
    | param_list_dec COMMA param_decl
    | param_list_dec COMMA ELLIPSIS
    | ELLIPSIS
    ;

param_decl
    : type IDENTIFIER
    | type multi_ptr IDENTIFIER
    | type AMP IDENTIFIER
    | type
    | type multi_ptr
    | type AMP
    ;

/* ---------------- Compound statements ---------------- */
compound_stmt
    : LBRACE stmt_list RBRACE
    ;

stmt_list
    :
    | stmt_list statement
    ;

/* ---------------- Statements ---------------- */
statement
    : expression SEMI
    | declaration
    | compound_stmt
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    | IF LPAREN expression RPAREN statement ELSE statement
    | SWITCH LPAREN expression RPAREN LBRACE case_blocks_opt RBRACE
    | WHILE LPAREN expression RPAREN statement
    | DO statement WHILE LPAREN expression RPAREN SEMI
    | FOR LPAREN for_init_opt expression_opt SEMI expression_opt RPAREN statement
    | FOR LPAREN type declarator COLON expression RPAREN statement   /* range-based for */
    | RETURN expression SEMI
    | RETURN SEMI
    | BREAK SEMI
    | CONTINUE SEMI
    | VA_START LPAREN IDENTIFIER COMMA IDENTIFIER RPAREN SEMI
    | VA_ARG LPAREN IDENTIFIER COMMA type RPAREN SEMI
    | VA_END LPAREN IDENTIFIER RPAREN SEMI
    | error SEMI { yyerrok; }
    ;

/* ---------------- Switch cases ---------------- */
case_blocks_opt
    :
    | case_blocks
    ;

case_blocks
    : case_blocks case_block
    | case_block
    ;

case_block
    : CASE literal COLON stmt_list
    | DEFAULT COLON stmt_list
    ;

/* ---------------- For loop helpers ---------------- */
for_init_opt
    :
    | expression_stmt
    | declaration
    ;

expression_opt
    :
    | expression
    ;

expression_stmt
    : expression SEMI
    | SEMI
    ;

/* ---------------- Expressions ---------------- */
expression
    : assignment_expr
    | expression COMMA assignment_expr
    ;

/* ---------------- Assignment expressions ---------------- */
assignment_expr
    : conditional_expr
    | unary_expr ASSIGN assignment_expr
    | unary_expr PLUS_ASSIGN assignment_expr
    | unary_expr MINUS_ASSIGN assignment_expr
    | unary_expr MUL_ASSIGN assignment_expr
    | unary_expr DIV_ASSIGN assignment_expr
    | unary_expr MOD_ASSIGN assignment_expr
    | unary_expr AMP_ASSIGN assignment_expr
    | unary_expr OR_ASSIGN assignment_expr
    | unary_expr XOR_ASSIGN assignment_expr
    | unary_expr SHL_ASSIGN assignment_expr
    | unary_expr SHR_ASSIGN assignment_expr
    ;

/* ---------------- Conditional / ternary ---------------- */
conditional_expr
    : logical_or_expr
    | logical_or_expr QUESTION expression COLON conditional_expr
    | logical_or_expr QUESTION  COLON conditional_expr
    | logical_or_expr QUESTION expression COLON
    | logical_or_expr QUESTION  COLON
    ;

/* ---------------- Logical / Bitwise ---------------- */
logical_or_expr
    : logical_and_expr
    | logical_or_expr OR logical_and_expr
    ;

logical_and_expr
    : bitwise_or_expr
    | logical_and_expr AND bitwise_or_expr
    ;

bitwise_or_expr
    : bitwise_xor_expr
    | bitwise_or_expr PIPE bitwise_xor_expr
    ;

bitwise_xor_expr
    : bitwise_and_expr
    | bitwise_xor_expr XOR bitwise_and_expr
    ;

bitwise_and_expr
    : equality_expr
    | bitwise_and_expr AMP equality_expr
    ;

equality_expr
    : relational_expr
    | equality_expr EQ relational_expr
    | equality_expr NEQ relational_expr
    ;

relational_expr
    : shift_expr
    | relational_expr LT shift_expr
    | relational_expr GT shift_expr
    | relational_expr LE shift_expr
    | relational_expr GE shift_expr
    ;

shift_expr
    : additive_expr
    | shift_expr SHL additive_expr
    | shift_expr SHR additive_expr
    ;

additive_expr
    : multiplicative_expr
    | additive_expr PLUS multiplicative_expr
    | additive_expr MINUS multiplicative_expr
    ;

multiplicative_expr
    : unary_expr
    | multiplicative_expr MUL unary_expr
    | multiplicative_expr DIV unary_expr
    | multiplicative_expr MOD unary_expr
    ;

/* ---------------- Unary expressions ---------------- */
unary_expr
    : postfix_expr
    | NOT unary_expr
    | MINUS unary_expr %prec UMINUS
    | INC unary_expr
    | DEC unary_expr
    | AMP unary_expr
    | MUL unary_expr
    ;

/* ---------------- Postfix expressions ---------------- */
postfix_expr
    : primary_expr
    | postfix_expr LPAREN argument_expression_list RPAREN
    | postfix_expr LPAREN RPAREN
    | postfix_expr DOT IDENTIFIER
    | postfix_expr ARROW IDENTIFIER
    | postfix_expr SCOPE IDENTIFIER
    | postfix_expr INC
    | postfix_expr DEC
    | postfix_expr LBRACK expression RBRACK
    ;

/* ---------------- Function call arguments ---------------- */
argument_expression_list
    : assignment_expr
    | argument_expression_list COMMA assignment_expr
    ;

/* ---------------- Primary expressions ---------------- */
primary_expr
    : IDENTIFIER
    | multi_ptr IDENTIFIER
    | literal
    | LPAREN expression RPAREN
    | lambda_expr
    | variadic_cout_expr
    | function_call_expr
    | va_arg_expr
    ;

/* ---------------- Variadic cout ---------------- */
variadic_cout_expr
    : STD_COUT LPAREN cout_args RPAREN
    ;

cout_args
    : expression
    | cout_args COMMA expression
    ;

/* ---------------- General function calls ---------------- */
function_call_expr
    : IDENTIFIER LPAREN argument_expression_list RPAREN
    | IDENTIFIER LPAREN RPAREN
    | LPAREN multi_ptr IDENTIFIER RPAREN LPAREN RPAREN
    | LPAREN multi_ptr IDENTIFIER RPAREN LPAREN argument_expression_list RPAREN
    ;

/* ---------------- Variadic helper ---------------- */
va_arg_expr
    : VA_ARG LPAREN IDENTIFIER COMMA type RPAREN
    | VA_ARG LPAREN IDENTIFIER COMMA type MUL RPAREN
    | VA_ARG LPAREN IDENTIFIER COMMA type AMP RPAREN
    ;

/* ---------------- Lambda expressions ---------------- */
lambda_expr
    : LBRACK capture_list_opt RBRACK lambda_params_opt lambda_ret_opt compound_stmt
    ;

capture_list_opt
    : capture_list
    |
    ;

capture_list
    : /* list of identifiers, comma-separated */
    | capture_list COMMA IDENTIFIER
    | IDENTIFIER
    ;

lambda_params_opt
    :
    | LPAREN param_list_dec RPAREN
    ;

lambda_ret_opt
    :
    | ARROW type
    ;

/* ---------------- Literals ---------------- */
literal
    : INT_LITERAL
    | FLOAT_LITERAL
    | CHAR_LITERAL
    | STRING
    ;

/* ---------------- Error ---------------- */
%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s near '%s'\n", line_val, s, yytext);
}

int main(int argc, char **argv) {
    if(argc>1) {
        FILE *f = fopen(argv[1],"r");
        if(!f) { perror("fopen"); return 1; }
        yyin = f;
    }
    yyparse();
    print_symbol_table();
    return 0;
}

void print_symbol_table() {
    printf("\nSymbol Table:\n");
    for(int i=0;i<symcount;i++) {
        printf("%s : %s\n", symtab[i].name, symtab[i].type);
    }
}
