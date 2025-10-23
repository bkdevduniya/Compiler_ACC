%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

int yylex(void);
extern FILE *yyin;
extern int line_val;
extern char* yytext;
void yyerror(const char *s);

/* ==================== AST DATA STRUCTURES ==================== */

typedef enum {
    NODE_PROGRAM,
    NODE_FUNCTION_DECL,
    NODE_FUNCTION_DEF,
    NODE_VARIABLE_DECL,
    NODE_STRUCT_TYPE,
    NODE_STRUCT_DEF,
    NODE_TYPE,
    NODE_IDENTIFIER,
    NODE_LITERAL,
    NODE_BINARY_OP,
    NODE_UNARY_OP,
    NODE_ASSIGNMENT,
    NODE_CALL,
    NODE_INDEX,
    NODE_MEMBER_ACCESS,
    NODE_IF_STMT,
    NODE_ELSE_IF_STMT,
    NODE_ELSE_STMT,
    NODE_WHILE_STMT,
    NODE_DO_WHILE_STMT,
    NODE_FOR_STMT,
    NODE_RANGE_FOR_STMT,
    NODE_RETURN_STMT,
    NODE_BREAK_STMT,
    NODE_CONTINUE_STMT,
    NODE_COMPOUND_STMT,
    NODE_SWITCH_STMT,
    NODE_CASE_STMT,
    NODE_DEFAULT_STMT,
    NODE_LAMBDA_EXPR,
    NODE_PARAM_LIST,
    NODE_ARG_LIST,
    NODE_INIT_LIST,
    NODE_TERNARY_OP,
    NODE_EMPTY,
    NODE_DECLARATOR,
    NODE_MULTI_PTR,
    NODE_STRUCT_MEMBER_LIST,
    NODE_STMT_LIST,
    NODE_CASE_BLOCKS,
    NODE_LAMBDA_CAPTURE,
    NODE_LAMBDA_PARAMS,
    NODE_LAMBDA_RET,
    NODE_FOR_INIT,
    NODE_EXPR_OPT,
    NODE_INITIALIZER,
    NODE_VA_LIST,
    NODE_COUT_STMT,
    NODE_CIN_STMT
} NodeType;

typedef struct ASTNode {
    NodeType type;
    int line_number;
    char *value;
    char *operator;
    struct ASTNode *left;
    struct ASTNode *right;
    struct ASTNode *child;
    struct ASTNode *next;
} ASTNode;

/* ==================== AST CREATION FUNCTIONS ==================== */

ASTNode* create_ast_node(NodeType type, int line, char *value) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = type;
    node->line_number = line;
    node->value = value ? strdup(value) : NULL;
    node->operator = NULL;
    node->left = NULL;
    node->right = NULL;
    node->child = NULL;
    node->next = NULL;
    return node;
}

ASTNode* create_binary_node(NodeType type, int line, char *op, ASTNode *left, ASTNode *right) {
    ASTNode *node = create_ast_node(type, line, NULL);
    node->operator = op ? strdup(op) : NULL;
    node->left = left;
    node->right = right;
    return node;
}

ASTNode* create_unary_node(NodeType type, int line, char *op, ASTNode *operand) {
    ASTNode *node = create_ast_node(type, line, NULL);
    node->operator = op ? strdup(op) : NULL;
    node->left = operand;
    return node;
}

ASTNode* create_ternary_node(int line, ASTNode *cond, ASTNode *then_expr, ASTNode *else_expr) {
    ASTNode *node = create_ast_node(NODE_TERNARY_OP, line, NULL);
    node->left = then_expr;
    node->right = else_expr;
    node->child = cond;
    return node;
}

void ast_add_child(ASTNode *parent, ASTNode *child) {
    if (!parent || !child) return;
    
    if (!parent->child) {
        parent->child = child;
    } else {
        ASTNode *last = parent->child;
        while (last->next) {
            last = last->next;
        }
        last->next = child;
    }
}

void ast_add_sibling(ASTNode *first, ASTNode *sibling) {
    if (!first || !sibling) return;
    
    ASTNode *last = first;
    while (last->next) {
        last = last->next;
    }
    last->next = sibling;
}

/* ==================== AST PRINTING FUNCTIONS ==================== */

const char* node_type_to_string(NodeType type) {
    switch (type) {
        case NODE_PROGRAM: return "PROGRAM";
        case NODE_FUNCTION_DECL: return "FUNCTION_DECL";
        case NODE_FUNCTION_DEF: return "FUNCTION_DEF";
        case NODE_VARIABLE_DECL: return "VARIABLE_DECL";
        case NODE_STRUCT_TYPE: return "STRUCT_TYPE";
        case NODE_STRUCT_DEF: return "STRUCT_DEF";
        case NODE_TYPE: return "TYPE";
        case NODE_IDENTIFIER: return "IDENTIFIER";
        case NODE_LITERAL: return "LITERAL";
        case NODE_BINARY_OP: return "BINARY_OP";
        case NODE_UNARY_OP: return "UNARY_OP";
        case NODE_ASSIGNMENT: return "ASSIGNMENT";
        case NODE_CALL: return "CALL";
        case NODE_INDEX: return "INDEX";
        case NODE_MEMBER_ACCESS: return "MEMBER_ACCESS";
        case NODE_IF_STMT: return "IF_STMT";
        case NODE_ELSE_IF_STMT: return "ELSE_IF_STMT";
        case NODE_ELSE_STMT: return "ELSE_STMT";
        case NODE_WHILE_STMT: return "WHILE_STMT";
        case NODE_DO_WHILE_STMT: return "DO_WHILE_STMT";
        case NODE_FOR_STMT: return "FOR_STMT";
        case NODE_RANGE_FOR_STMT: return "RANGE_FOR_STMT";
        case NODE_RETURN_STMT: return "RETURN_STMT";
        case NODE_BREAK_STMT: return "BREAK_STMT";
        case NODE_CONTINUE_STMT: return "CONTINUE_STMT";
        case NODE_COMPOUND_STMT: return "COMPOUND_STMT";
        case NODE_SWITCH_STMT: return "SWITCH_STMT";
        case NODE_CASE_STMT: return "CASE_STMT";
        case NODE_DEFAULT_STMT: return "DEFAULT_STMT";
        case NODE_LAMBDA_EXPR: return "LAMBDA_EXPR";
        case NODE_PARAM_LIST: return "PARAM_LIST";
        case NODE_ARG_LIST: return "ARG_LIST";
        case NODE_INIT_LIST: return "INIT_LIST";
        case NODE_TERNARY_OP: return "TERNARY_OP";
        case NODE_EMPTY: return "EMPTY";
        case NODE_DECLARATOR: return "DECLARATOR";
        case NODE_MULTI_PTR: return "MULTI_PTR";
        case NODE_STRUCT_MEMBER_LIST: return "STRUCT_MEMBER_LIST";
        case NODE_STMT_LIST: return "STMT_LIST";
        case NODE_CASE_BLOCKS: return "CASE_BLOCKS";
        case NODE_LAMBDA_CAPTURE: return "LAMBDA_CAPTURE";
        case NODE_LAMBDA_PARAMS: return "LAMBDA_PARAMS";
        case NODE_LAMBDA_RET: return "LAMBDA_RET";
        case NODE_FOR_INIT: return "FOR_INIT";
        case NODE_EXPR_OPT: return "EXPR_OPT";
        case NODE_INITIALIZER: return "INITIALIZER";
        case NODE_VA_LIST: return "VA_LIST";
        case NODE_COUT_STMT: return "COUT_STMT";
        case NODE_CIN_STMT: return "CIN_STMT";
        default: return "UNKNOWN";
    }
}

void print_ast(ASTNode *node, int depth) {
    if (!node) return;
    
    for (int i = 0; i < depth; i++) printf("  ");
    
    printf("%s", node_type_to_string(node->type));
    
    if (node->value) printf(" [%s]", node->value);
    if (node->operator) printf(" (op: %s)", node->operator);
    printf(" (line %d)\n", node->line_number);
    
    print_ast(node->child, depth + 1);
    print_ast(node->left, depth + 1);
    print_ast(node->right, depth + 1);
    print_ast(node->next, depth);
}

void check_semantics(ASTNode *node, int depth){

}

void free_ast(ASTNode *node) {
    if (!node) return;
    
    free_ast(node->child);
    free_ast(node->left);
    free_ast(node->right);
    free_ast(node->next);
    
    if (node->value) free(node->value);
    if (node->operator) free(node->operator);
    free(node);
}

/* ==================== GLOBAL AST ROOT ==================== */

ASTNode *ast_root = NULL;

%}

/* Semantic values */
%union {
    char* str;
    int   num;
    double fnum;
    struct ASTNode* ast;
}

/* ---------------- Tokens from lexer ---------------- */
%token IF ELSE SWITCH CASE DEFAULT
%token FOR WHILE DO
%token BREAK CONTINUE RETURN GOTO
%token INT FLOAT DOUBLE CHAR BOOL VOID LONG SHORT CONST STATIC UNSIGNED AUTO STRUCT STRING
%token CLASS ENUM PUBLIC PROTECTED PRIVATE
%token GT LT LE GE NEQ EQ
%token AND OR NOT
%token PLUS MINUS MUL DIV MOD
%token ASSIGN
%token PLUS_ASSIGN MINUS_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
%token PIPE_ASSIGN AMP_ASSIGN XOR_ASSIGN SHL_ASSIGN SHR_ASSIGN
%token AMP PIPE XOR SHL SHR
%token INC DEC QUESTION SCOPE ARROW DOT ELLIPSIS
%token SEMI LBRACK RBRACK LBRACE RBRACE LPAREN RPAREN COLON COMMA
%token <str> STRING_LITERAL CHAR_LITERAL IDENTIFIER
%token <num> INT_LITERAL
%token <fnum> FLOAT_LITERAL
%token STD_CIN STD_COUT STD_ENDL
%token VA_START VA_ARG VA_END VA_LIST
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
%right PIPE_ASSIGN AMP_ASSIGN XOR_ASSIGN SHL_ASSIGN SHR_ASSIGN
%left GREATER

%type <ast> program element_list element declaration function_dec function_def
%type <ast> struct_def struct_member_list struct_member
%type <ast> type type_val declarator multi_ptr
%type <ast> expression expression_stmt assignment_expr conditional_expr logical_or_expr
%type <ast> logical_and_expr bitwise_or_expr bitwise_xor_expr bitwise_and_expr
%type <ast> equality_expr relational_expr shift_expr additive_expr multiplicative_expr
%type <ast> unary_expr postfix_expr primary_expr lambda_expr lambda_capture lambda_capture_list
%type <ast> lambda_params lambda_ret params_opt param_list_dec param_decl
%type <ast> compound_stmt stmt_list statement case_blocks_opt case_blocks case_block
%type <ast> for_init_opt expression_opt initializer init_list args_opt args_list literal srtuct_ident
%type <ast> else_part cout_stmt cin_stmt

%start program

%%

program
    : { 
        ast_root = create_ast_node(NODE_PROGRAM, line_val, "program"); 
        $$ = ast_root;
      }
    | program element { 
        ast_add_child($1, $2); 
        $$ = $1;
      }
    ;

element_list
    : { $$ = create_ast_node(NODE_EMPTY, line_val, "element_list"); }
    | element_list element { 
        ast_add_child($1, $2); 
        $$ = $1;
      }
    ;

element
    : declaration { $$ = $1; }
    | function_dec { $$ = $1; }
    | function_def { $$ = $1; }
    | statement { $$ = $1; }
    | compound_stmt { $$ = $1; }
    | struct_def { $$ = $1; }
    ;

srtuct_ident
: STRUCT {
    $$=create_ast_node(NODE_STRUCT_TYPE,line_val,"struct");
}
;

/*---------------- Struct definition ----------------*/
struct_def
    : srtuct_ident IDENTIFIER LBRACE struct_member_list RBRACE SEMI {
        ASTNode *struct_node = create_ast_node(NODE_STRUCT_DEF,line_val, $2);
        ast_add_child(struct_node, $4);
        $$ = struct_node;
    }
    | srtuct_ident IDENTIFIER SEMI {
        $$ = create_ast_node(NODE_STRUCT_DEF,line_val, $2);
    }
    | srtuct_ident LBRACE struct_member_list RBRACE SEMI {
        ASTNode *struct_node = create_ast_node(NODE_STRUCT_DEF,line_val, "anonymous");
        ast_add_child(struct_node, $3);
        $$ = struct_node;
    }
    ;

struct_member_list
    : { $$ = create_ast_node(NODE_STRUCT_MEMBER_LIST, line_val, NULL); }
    | struct_member_list struct_member {
        ast_add_child($1, $2);
        $$ = $1;
    }
    ;

struct_member
    : type declarator SEMI { 
        ASTNode *member = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(member, $1);
        ast_add_child(member, $2);
        $$ = member;
    }
    | type declarator LBRACK expression RBRACK SEMI { 
        ASTNode *member = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *array_decl = create_ast_node(NODE_INDEX, line_val, NULL);
        ast_add_child(array_decl, $2);
        ast_add_child(array_decl, $4);
        ast_add_child(member, $1);
        ast_add_child(member, array_decl);
        $$ = member;
    }
    | type SEMI { $$ = $1; }
    ;

/* ---------------- Declarations ---------------- */
multi_ptr
    :{$$= create_ast_node(NODE_MULTI_PTR, line_val, "empty");}
    |multi_ptr MUL {
        ASTNode *ptr_node = create_ast_node(NODE_MULTI_PTR, line_val, "*");
        if ($1->type != NODE_EMPTY) {
            ast_add_child(ptr_node, $1);
        }
        $$ = ptr_node;
    }
    ;

declaration
    : type declarator SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(decl, $1);
        ast_add_child(decl, $2);
        $$ = decl;
    }
    | type declarator ASSIGN expression SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $2, $4);
        ast_add_child(decl, $1);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    | type declarator ASSIGN initializer SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $2, $4);
        ast_add_child(decl, $1);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    | type declarator ASSIGN lambda_expr SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $2, $4);
        ast_add_child(decl, $1);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    | VA_LIST IDENTIFIER SEMI {
        ASTNode *decl = create_ast_node(NODE_VA_LIST, line_val, NULL);
        ast_add_child(decl, create_ast_node(NODE_IDENTIFIER, line_val, $2));
        $$ = decl;
    }
    | AUTO declarator ASSIGN expression SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *auto_type = create_ast_node(NODE_TYPE, line_val, "auto");
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $2, $4);
        ast_add_child(decl, auto_type);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    | AUTO declarator ASSIGN lambda_expr SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL,line_val, NULL);
        ASTNode *auto_type = create_ast_node(NODE_TYPE,line_val, "auto");
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT,line_val, "=", $2, $4);
        ast_add_child(decl, auto_type);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    | CONST type declarator ASSIGN expression SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *const_type = create_ast_node(NODE_TYPE, line_val, "const");
        ast_add_child(const_type, $2);
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $3, $5);
        ast_add_child(decl, const_type);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    ;

/*---------------- Declarators ----------------*/
declarator
    : IDENTIFIER { 
        $$ = create_ast_node(NODE_IDENTIFIER, line_val, $1);
      }
    | multi_ptr IDENTIFIER {
        ASTNode *decl = create_ast_node(NODE_DECLARATOR,line_val, NULL);
        ast_add_child(decl, $1);
        ASTNode *id = create_ast_node(NODE_IDENTIFIER,line_val, $2);
        ast_add_child(decl, id);
        $$ = decl;
    }
    | AMP IDENTIFIER {
        ASTNode *decl = create_ast_node(NODE_DECLARATOR, line_val, "&");
        ASTNode *id = create_ast_node(NODE_IDENTIFIER, line_val, $2);
        ast_add_child(decl, id);
        $$ = decl;
    }
    | declarator LBRACK expression RBRACK {
        ASTNode *array = create_ast_node(NODE_INDEX,line_val, NULL);
        ast_add_child(array, $1);
        ast_add_child(array, $3);
        $$ = array;
    }
    | declarator LBRACK RBRACK {
        ASTNode *array = create_ast_node(NODE_INDEX,line_val, NULL);
        ast_add_child(array, $1);
        $$ = array;
    }
    ;

/* ---------------- Array initializer ---------------- */
initializer
    : expression { $$ = create_ast_node(NODE_INITIALIZER,line_val, NULL); ast_add_child($$, $1); }
    | LBRACE init_list RBRACE { $$ = $2; }
    | LBRACE RBRACE { $$ = create_ast_node(NODE_INIT_LIST, line_val, "empty"); }
    ;

init_list
    : expression { 
        $$ = create_ast_node(NODE_INIT_LIST,line_val, NULL);
        ast_add_child($$, $1);
    }
    | init_list COMMA expression {
        ast_add_child($1, $3);
        $$ = $1;
    }
    ;

/* ---------------- Types ---------------- */

type
    : INT       { $$ = create_ast_node(NODE_TYPE, line_val, "int"); }
    | FLOAT     { $$ = create_ast_node(NODE_TYPE, line_val, "float"); }
    | DOUBLE    { $$ = create_ast_node(NODE_TYPE, line_val, "double"); }
    | CHAR      { $$ = create_ast_node(NODE_TYPE, line_val, "char"); }
    | BOOL      { $$ = create_ast_node(NODE_TYPE, line_val, "bool"); }
    | VOID      { $$ = create_ast_node(NODE_TYPE, line_val, "void"); }
    | LONG      { $$ = create_ast_node(NODE_TYPE, line_val, "long");}
    | LONG LONG { $$ = create_ast_node(NODE_TYPE, line_val, "long long");}
    | LONG INT  { $$ = create_ast_node(NODE_TYPE, line_val, "long int");}
    | LONG  FLOAT { $$ = create_ast_node(NODE_TYPE, line_val, "long float");}
    | CONST CHAR { $$ = create_ast_node(NODE_TYPE, line_val, "const char");}
    | CONST STRING { $$ = create_ast_node(NODE_TYPE, line_val, "const string");}
    | CONST INT    { $$ = create_ast_node(NODE_TYPE, line_val, "const int");}
    | CONST FLOAT  { $$ = create_ast_node(NODE_TYPE, line_val, "const float");}
    | CONST DOUBLE  { $$ = create_ast_node(NODE_TYPE, line_val, "const double");}
    | CONST BOOL    { $$ = create_ast_node(NODE_TYPE, line_val, "const bool");}
    | CONST SHORT   { $$ = create_ast_node(NODE_TYPE, line_val, "const short");}
    | CONST LONG    { $$ = create_ast_node(NODE_TYPE, line_val, "const long");}
    | STATIC INT    { $$ = create_ast_node(NODE_TYPE, line_val, "static int");}
    | STATIC FLOAT  { $$ = create_ast_node(NODE_TYPE, line_val, "static float");}
    | STATIC DOUBLE  { $$ = create_ast_node(NODE_TYPE, line_val, "static double");}
    | STATIC BOOL    { $$ = create_ast_node(NODE_TYPE, line_val, "static bool");}
    | STATIC SHORT   { $$ = create_ast_node(NODE_TYPE, line_val, "static short");}
    | STATIC STRING  { $$ = create_ast_node(NODE_TYPE, line_val, "static string");}
    | STATIC CHAR    { $$ = create_ast_node(NODE_TYPE, line_val, "static char");}
    | STATIC LONG    { $$ = create_ast_node(NODE_TYPE, line_val, "static long");}
    | UNSIGNED INT    { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned int");}
    | UNSIGNED FLOAT  { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned float");}
    | UNSIGNED DOUBLE  { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned double");}
    | UNSIGNED CHAR    { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned char");}
    | UNSIGNED LONG    { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned long");}

    
    | SHORT     { $$ = create_ast_node(NODE_TYPE, line_val, "short"); }
    | CONST     { $$ = create_ast_node(NODE_TYPE, line_val, "const"); }
    | STATIC    { $$ = create_ast_node(NODE_TYPE, line_val, "static"); }
    | UNSIGNED  { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned"); }
    | AUTO      { $$ = create_ast_node(NODE_TYPE, line_val, "auto"); }
    | STRUCT    { $$ = create_ast_node(NODE_TYPE, line_val, "struct"); }
    | STRING    { $$ = create_ast_node(NODE_TYPE, line_val, "string"); }
    | CLASS     { $$ = create_ast_node(NODE_TYPE, line_val, "class"); }
    | ENUM      { $$ = create_ast_node(NODE_TYPE, line_val, "enum"); }
    | VA_LIST   { $$ = create_ast_node(NODE_TYPE, line_val, "va_list"); }
    | IDENTIFIER { $$ = create_ast_node(NODE_TYPE, line_val, $1); }
    | IDENTIFIER LT type GT {
        ASTNode *templ_type = create_ast_node(NODE_TYPE, line_val, $1);
        ast_add_child(templ_type, $3);
        $$ = templ_type;
    }
    ;

/* ---------------- Functions ---------------- */

function_dec
    : type declarator LPAREN params_opt RPAREN SEMI {
        ASTNode *func = create_ast_node(NODE_FUNCTION_DECL, line_val, NULL);
        ast_add_child(func, $1);  // return type
        ast_add_child(func, $2);  // function name (as declarator)
        ast_add_child(func, $4);  // parameters
        $$ = func;
    }
    | AUTO IDENTIFIER LPAREN params_opt RPAREN SEMI {
        ASTNode *func = create_ast_node(NODE_FUNCTION_DECL, line_val, $2);
        ASTNode *auto_type = create_ast_node(NODE_TYPE, line_val, "auto");
        ast_add_child(func, auto_type);
        ast_add_child(func, $4);
        $$ = func;
    }
    ;

function_def
    : type declarator LPAREN params_opt RPAREN compound_stmt { 
        ASTNode *func = create_ast_node(NODE_FUNCTION_DEF, line_val, NULL);
        ast_add_child(func, $1);  // return type
        ast_add_child(func, $2);  // function name (as declarator)
        ast_add_child(func, $4);  // parameters
        ast_add_child(func, $6);  // function body
        $$ = func;
      }
    | AUTO IDENTIFIER LPAREN params_opt RPAREN compound_stmt {
        ASTNode *func = create_ast_node(NODE_FUNCTION_DEF, line_val, $2);
        ASTNode *auto_type = create_ast_node(NODE_TYPE, line_val, "auto");
        ast_add_child(func, auto_type);
        ast_add_child(func, $4);
        ast_add_child(func, $6);
        $$ = func;
      }
    ;

/* ---------------- Parameters ---------------- */
params_opt
    : { $$ = create_ast_node(NODE_PARAM_LIST, line_val, "empty"); }
    | param_list_dec { $$ = $1; }
    ;

param_list_dec
    : param_decl { 
        $$ = create_ast_node(NODE_PARAM_LIST, line_val, NULL);
        ast_add_child($$, $1);
      }
    | param_list_dec COMMA param_decl {
        ast_add_child($1, $3);
        $$ = $1;
      }
    | param_list_dec COMMA ELLIPSIS {
        ASTNode *ellipsis = create_ast_node(NODE_TYPE, line_val, "...");
        ast_add_child($1, ellipsis);
        $$ = $1;
      }
    | ELLIPSIS {
        $$ = create_ast_node(NODE_PARAM_LIST, line_val, NULL);
        ASTNode *ellipsis = create_ast_node(NODE_TYPE, line_val, "...");
        ast_add_child($$, ellipsis);
      }
    ;

param_decl
    : type declarator { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(param, $1);  // parameter type
        ast_add_child(param, $2);  // parameter name (as declarator)
        $$ = param;
      }
    | type { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(param, $1);  // parameter type only (no name)
        $$ = param;
      }
    | type multi_ptr { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *ptr_type = create_ast_node(NODE_TYPE, line_val, NULL);
        ast_add_child(ptr_type, $1);
        ast_add_child(ptr_type, $2);
        ast_add_child(param, ptr_type);
        $$ = param;
      }
    | type AMP { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *ref_type = create_ast_node(NODE_TYPE, line_val, "&");
        ast_add_child(ref_type, $1);
        ast_add_child(param, ref_type);
        $$ = param;
      }
    | AUTO IDENTIFIER { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(param, create_ast_node(NODE_TYPE, line_val, "auto"));
        ast_add_child(param, create_ast_node(NODE_IDENTIFIER, line_val, $2));
        $$ = param;
      }
    ;
/* ---------------- Compound statements ---------------- */
compound_stmt
    : LBRACE stmt_list RBRACE { 
        ASTNode *compound = create_ast_node(NODE_COMPOUND_STMT,line_val, NULL);
        ast_add_child(compound, $2);
        $$ = compound;
      }
    ;

stmt_list
    : { $$ = create_ast_node(NODE_STMT_LIST, line_val, "empty"); }
    | stmt_list statement { 
        ast_add_child($1, $2);
        $$ = $1;
      }
    | stmt_list declaration { 
        ast_add_child($1, $2);
        $$ = $1;
      }
    ;

/* ---------------- If-Else Statements ---------------- */
else_part
    : ELSE statement {
        ASTNode *else_node = create_ast_node(NODE_ELSE_STMT, line_val, NULL);
        ast_add_child(else_node, $2);
        $$ = else_node;
    }
    | ELSE IF LPAREN expression RPAREN statement else_part {
        ASTNode *else_if_node = create_ast_node(NODE_ELSE_IF_STMT, line_val, NULL);
        ast_add_child(else_if_node, $4);  // condition
        ast_add_child(else_if_node, $6);  // then statement
        if ($7) {
            ast_add_child(else_if_node, $7);  // next else/else-if part
        }
        $$ = else_if_node;
    }
    | ELSE IF LPAREN expression RPAREN statement {
        ASTNode *else_if_node = create_ast_node(NODE_ELSE_IF_STMT, line_val, NULL);
        ast_add_child(else_if_node, $4);  // condition
        ast_add_child(else_if_node, $6);  // then statement
        $$ = else_if_node;
    }
    | {
        $$ = NULL;  // No else part
    }
    ;

/* ---------------- Cout and Cin Statements ---------------- */
cout_stmt
    : STD_COUT LPAREN args_opt RPAREN SEMI {
        ASTNode *cout_node = create_ast_node(NODE_COUT_STMT, line_val, NULL);
        ast_add_child(cout_node, $3);
        $$ = cout_node;
    }
    ;

cin_stmt
    : STD_CIN LPAREN args_opt RPAREN SEMI {
        ASTNode *cin_node = create_ast_node(NODE_CIN_STMT, line_val, NULL);
        ast_add_child(cin_node, $3);
        $$ = cin_node;
    }
    ;

/* ---------------- Statements ---------------- */
statement
    : expression SEMI { $$ = $1; }
    | declaration { $$ = $1; }
    | compound_stmt { $$ = $1; }
    | cout_stmt { $$ = $1; }
    | cin_stmt { $$ = $1; }
    | IF LPAREN expression RPAREN statement else_part {
        ASTNode *if_node = create_ast_node(NODE_IF_STMT,line_val, NULL);
        ast_add_child(if_node, $3);  // condition
        ast_add_child(if_node, $5);  // then statement
        if ($6) {
            ast_add_child(if_node, $6);  // else/else-if part
        }
        $$ = if_node;
    }
    | SWITCH LPAREN expression RPAREN LBRACE case_blocks_opt RBRACE {
        ASTNode *switch_node = create_ast_node(NODE_SWITCH_STMT,line_val, NULL);
        ast_add_child(switch_node, $3);
        ast_add_child(switch_node, $6);
        $$ = switch_node;
    }
    | WHILE LPAREN expression RPAREN statement {
        ASTNode *while_node = create_ast_node(NODE_WHILE_STMT,line_val, NULL);
        ast_add_child(while_node, $3);
        ast_add_child(while_node, $5);
        $$ = while_node;
    }
    | DO statement WHILE LPAREN expression RPAREN SEMI {
        ASTNode *do_while = create_ast_node(NODE_DO_WHILE_STMT, line_val, NULL);
        ast_add_child(do_while, $2);
        ast_add_child(do_while, $5);
        $$ = do_while;
    }
    | FOR LPAREN for_init_opt expression_opt SEMI expression_opt RPAREN statement {
        ASTNode *for_node = create_ast_node(NODE_FOR_STMT,line_val, NULL);
        ast_add_child(for_node, $3);
        ast_add_child(for_node, $4);
        ast_add_child(for_node, $6);
        ast_add_child(for_node, $8);
        $$ = for_node;
    }
    | FOR LPAREN type declarator COLON expression RPAREN statement {
        ASTNode *for_node = create_ast_node(NODE_RANGE_FOR_STMT,line_val, NULL);
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(decl, $3);
        ast_add_child(decl, $4);
        ast_add_child(for_node, decl);
        ast_add_child(for_node, $6);
        ast_add_child(for_node, $8);
        $$ = for_node;
    }
    | FOR LPAREN AUTO declarator COLON expression RPAREN statement {
        ASTNode *for_node = create_ast_node(NODE_RANGE_FOR_STMT,line_val, NULL);
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ast_add_child(decl, create_ast_node(NODE_TYPE, line_val, "auto"));
        ast_add_child(decl, $4);
        ast_add_child(for_node, decl);
        ast_add_child(for_node, $6);
        ast_add_child(for_node, $8);
        $$ = for_node;
    }
    | RETURN expression SEMI { 
        $$ = create_unary_node(NODE_RETURN_STMT,line_val, "return", $2);
      }
    | RETURN SEMI { 
        $$ = create_ast_node(NODE_RETURN_STMT, line_val, NULL);
      }
    | BREAK SEMI { $$ = create_ast_node(NODE_BREAK_STMT, line_val, NULL); }
    | CONTINUE SEMI { $$ = create_ast_node(NODE_CONTINUE_STMT, line_val, NULL); }
    | GOTO IDENTIFIER SEMI { 
        $$ = create_ast_node(NODE_IDENTIFIER, line_val, $2);
      }
    | VA_START LPAREN IDENTIFIER COMMA IDENTIFIER RPAREN SEMI {
        ASTNode *va_start = create_ast_node(NODE_CALL, line_val, "va_start");
        ast_add_child(va_start, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        ast_add_child(va_start, create_ast_node(NODE_IDENTIFIER, line_val, $5));
        $$ = va_start;
      }
    | VA_ARG LPAREN IDENTIFIER COMMA type RPAREN SEMI {
        ASTNode *va_arg = create_ast_node(NODE_CALL, line_val, "va_arg");
        ast_add_child(va_arg, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        ast_add_child(va_arg, $5);
        $$ = va_arg;
      }
    | VA_END LPAREN IDENTIFIER RPAREN SEMI {
        ASTNode *va_end = create_ast_node(NODE_CALL, line_val, "va_end");
        ast_add_child(va_end, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        $$ = va_end;
      }
    | SEMI { $$ = create_ast_node(NODE_EMPTY, line_val, "empty_stmt"); }
    | error SEMI { yyerrok; $$ = create_ast_node(NODE_EMPTY, line_val, "error_recovery"); }
    ;

/* ---------------- Switch cases ---------------- */
case_blocks_opt
    : { $$ = create_ast_node(NODE_CASE_BLOCKS, line_val, "empty"); }
    | case_blocks { $$ = $1; }
    ;

case_blocks
    : case_block { 
        $$ = create_ast_node(NODE_CASE_BLOCKS, line_val, NULL);
        ast_add_child($$, $1);
      }
    | case_blocks case_block {
        ast_add_child($1, $2);
        $$ = $1;
      }
    ;

case_block
    : CASE expression COLON stmt_list {
        ASTNode *case_node = create_ast_node(NODE_CASE_STMT, line_val, NULL);
        ast_add_child(case_node, $2);
        ast_add_child(case_node, $4);
        $$ = case_node;
    }
    | DEFAULT COLON stmt_list {
        ASTNode *default_node = create_ast_node(NODE_DEFAULT_STMT, line_val, NULL);
        ast_add_child(default_node, $3);
        $$ = default_node;
    }
    ;

/* ---------------- For loop parts ---------------- */
for_init_opt
    : SEMI { $$ = create_ast_node(NODE_FOR_INIT, line_val, "empty"); }
    | expression SEMI{ $$ = $1; }
    | declaration { $$ = $1; }
    ;

expression_opt
    : { $$ = create_ast_node(NODE_EXPR_OPT, line_val, "empty"); }
    | expression { $$ = $1; }
    ;

/* ---------------- Expressions ---------------- */
expression
    : assignment_expr { $$ = $1; }
    | expression COMMA assignment_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, ",", $1, $3);
    }
    ;

assignment_expr
    : conditional_expr { $$ = $1; }
    | unary_expr ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $1, $3);
    }
    | unary_expr PLUS_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "+=", $1, $3);
    }
    | unary_expr MINUS_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "-=", $1, $3);
    }
    | unary_expr MUL_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "*=", $1, $3);
    }
    | unary_expr DIV_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "/=", $1, $3);
    }
    | unary_expr MOD_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "%=", $1, $3);
    }
    | unary_expr PIPE_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "|=", $1, $3);
    }
    | unary_expr AMP_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "&=", $1, $3);
    }
    | unary_expr XOR_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "^=", $1, $3);
    }
    | unary_expr SHL_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, "<<=", $1, $3);
    }
    | unary_expr SHR_ASSIGN expression {
        $$ = create_binary_node(NODE_ASSIGNMENT, line_val, ">>=", $1, $3);
    }
    ;

conditional_expr
    : logical_or_expr { $$ = $1; }
    | logical_or_expr QUESTION expression COLON conditional_expr {
        $$ = create_ternary_node(line_val, $1, $3, $5);
    }
    ;

logical_or_expr
    : logical_and_expr { $$ = $1; }
    | logical_or_expr OR logical_and_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "||", $1, $3);
    }
    ;

logical_and_expr
    : bitwise_or_expr { $$ = $1; }
    | logical_and_expr AND bitwise_or_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "&&", $1, $3);
    }
    ;

bitwise_or_expr
    : bitwise_xor_expr { $$ = $1; }
    | bitwise_or_expr PIPE bitwise_xor_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "|", $1, $3);
    }
    ;

bitwise_xor_expr
    : bitwise_and_expr { $$ = $1; }
    | bitwise_xor_expr XOR bitwise_and_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "^", $1, $3);
    }
    ;

bitwise_and_expr
    : equality_expr { $$ = $1; }
    | bitwise_and_expr AMP equality_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "&", $1, $3);
    }
    ;

equality_expr
    : relational_expr { $$ = $1; }
    | equality_expr EQ relational_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "==", $1, $3);
    }
    | equality_expr NEQ relational_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "!=", $1, $3);
    }
    ;

relational_expr
    : shift_expr { $$ = $1; }
    | relational_expr LT shift_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "<", $1, $3);
    }
    | relational_expr GT shift_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, ">", $1, $3);
    }
    | relational_expr LE shift_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "<=", $1, $3);
    }
    | relational_expr GE shift_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, ">=", $1, $3);
    }
    ;

shift_expr
    : additive_expr { $$ = $1; }
    | shift_expr SHL additive_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "<<", $1, $3);
    }
    | shift_expr SHR additive_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, ">>", $1, $3);
    }
    ;

additive_expr
    : multiplicative_expr { $$ = $1; }
    | additive_expr PLUS multiplicative_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "+", $1, $3);
    }
    | additive_expr MINUS multiplicative_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "-", $1, $3);
    }
    ;

multiplicative_expr
    : unary_expr { $$ = $1; }
    | multiplicative_expr MUL unary_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "*", $1, $3);
    }
    | multiplicative_expr DIV unary_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "/", $1, $3);
    }
    | multiplicative_expr MOD unary_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "%", $1, $3);
    }
    ;

unary_expr
    : postfix_expr { $$ = $1; }
    | INC unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "++", $2);
    }
    | DEC unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "--", $2);
    }
    | PLUS unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "+", $2);
    }
    | MINUS unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "-", $2);
    }
    | NOT unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "!", $2);
    }
    | AMP unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "&", $2);
    }
    | MUL unary_expr {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "*", $2);
    }
    ;

postfix_expr
    : primary_expr { $$ = $1; }
    | postfix_expr LPAREN args_opt RPAREN {
        ASTNode *call = create_ast_node(NODE_CALL, line_val, NULL);
        ast_add_child(call, $1);
        ast_add_child(call, $3);
        $$ = call;
    }
    | postfix_expr LBRACK expression RBRACK {
        ASTNode *index = create_ast_node(NODE_INDEX, line_val, NULL);
        ast_add_child(index, $1);
        ast_add_child(index, $3);
        $$ = index;
    }
    | postfix_expr DOT IDENTIFIER {
        ASTNode *member = create_ast_node(NODE_MEMBER_ACCESS, line_val, ".");
        ast_add_child(member, $1);
        ast_add_child(member, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        $$ = member;
    }
    | postfix_expr ARROW IDENTIFIER {
        ASTNode *member = create_ast_node(NODE_MEMBER_ACCESS, line_val, "->");
        ast_add_child(member, $1);
        ast_add_child(member, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        $$ = member;
    }
    | postfix_expr SHL expression {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "<<", $1, $3);
    }
    | postfix_expr INC {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "++", $1);
    }
    | postfix_expr DEC {
        $$ = create_unary_node(NODE_UNARY_OP, line_val, "--", $1);
    }
    ;

primary_expr
    : IDENTIFIER { $$ = create_ast_node(NODE_IDENTIFIER, line_val, $1); }
    | literal { $$ = $1; }
    | LPAREN expression RPAREN { $$ = $2; }
    | lambda_expr { $$ = $1; }
    | STD_CIN { $$ = create_ast_node(NODE_IDENTIFIER, line_val, "cin"); }
    | STD_COUT { $$ = create_ast_node(NODE_IDENTIFIER, line_val, "cout"); }
    | STD_ENDL { $$ = create_ast_node(NODE_IDENTIFIER, line_val, "endl"); }
    ;

/* ---------------- Literals ---------------- */
literal
    : INT_LITERAL { 
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%d", $1);
        $$ = create_ast_node(NODE_LITERAL, line_val, buffer);
    }
    | FLOAT_LITERAL { 
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%f", $1);
        $$ = create_ast_node(NODE_LITERAL, line_val, buffer);
    }
    | CHAR_LITERAL { 
        $$ = create_ast_node(NODE_LITERAL, line_val, $1);
    }
    | STRING_LITERAL { 
        $$ = create_ast_node(NODE_LITERAL, line_val, $1);
    }
    ;

/* ---------------- Lambda expressions ---------------- */
lambda_expr
    : LBRACK lambda_capture RBRACK lambda_params lambda_ret compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, $2);
        ast_add_child(lambda, $4);
        ast_add_child(lambda, $5);
        ast_add_child(lambda, $6);
        $$ = lambda;
    }
    | LBRACK lambda_capture RBRACK lambda_params compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, $2);
        ast_add_child(lambda, $4);
        ast_add_child(lambda, $5);
        $$ = lambda;
    }
    | LBRACK lambda_capture RBRACK lambda_ret compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, $2);
        ast_add_child(lambda, $4);
        ast_add_child(lambda, $5);
        $$ = lambda;
    }
    | LBRACK lambda_capture RBRACK compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, $2);
        ast_add_child(lambda, $4);
        $$ = lambda;
    }
    | LBRACK RBRACK lambda_params lambda_ret compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "empty"));
        ast_add_child(lambda, $3);
        ast_add_child(lambda, $4);
        ast_add_child(lambda, $5);
        $$ = lambda;
    }
    | LBRACK RBRACK lambda_params compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "empty"));
        ast_add_child(lambda, $3);
        ast_add_child(lambda, $4);
        $$ = lambda;
    }
    | LBRACK RBRACK lambda_ret compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "empty"));
        ast_add_child(lambda, $3);
        ast_add_child(lambda, $4);
        $$ = lambda;
    }
    | LBRACK RBRACK compound_stmt {
        ASTNode *lambda = create_ast_node(NODE_LAMBDA_EXPR, line_val, NULL);
        ast_add_child(lambda, create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "empty"));
        ast_add_child(lambda, $3);
        $$ = lambda;
    }
    ;

lambda_capture
    : AMP { $$ = create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "&"); }
    | ASSIGN { $$ = create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "="); }
    | lambda_capture_list { $$ = $1; }
    | AMP lambda_capture_list {
        ASTNode *capture = create_ast_node(NODE_LAMBDA_CAPTURE, line_val, "&");
        ast_add_child(capture, $2);
        $$ = capture;
    }
    ;

lambda_capture_list
    : IDENTIFIER { 
        $$ = create_ast_node(NODE_LAMBDA_CAPTURE, line_val, NULL);
        ast_add_child($$, create_ast_node(NODE_IDENTIFIER, line_val, $1));
    }
    | lambda_capture_list COMMA IDENTIFIER {
        ast_add_child($1, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        $$ = $1;
    }
    | AMP IDENTIFIER { 
        $$ = create_ast_node(NODE_LAMBDA_CAPTURE, line_val, NULL);
        ASTNode *ref = create_ast_node(NODE_IDENTIFIER, line_val, $2);
        ASTNode *amp = create_ast_node(NODE_TYPE, line_val, "&");
        ast_add_child($$, amp);
        ast_add_child($$, ref);
    }
    | lambda_capture_list COMMA AMP IDENTIFIER {
        ASTNode *ref = create_ast_node(NODE_IDENTIFIER, line_val, $4);
        ASTNode *amp = create_ast_node(NODE_TYPE, line_val, "&");
        ast_add_child($1, amp);
        ast_add_child($1, ref);
        $$ = $1;
    }
    ;

lambda_params
    : LPAREN params_opt RPAREN { $$ = $2; }
    ;

lambda_ret
    : ARROW type { 
        ASTNode *ret = create_ast_node(NODE_LAMBDA_RET, line_val, NULL);
        ast_add_child(ret, $2);
        $$ = ret;
    }
    ;

/* ---------------- Function arguments ---------------- */
args_opt
    : { $$ = create_ast_node(NODE_ARG_LIST, line_val, "empty"); }
    | args_list { $$ = $1; }
    ;

args_list
    : expression { 
        $$ = create_ast_node(NODE_ARG_LIST, line_val, NULL);
        ast_add_child($$, $1);
      }
    | args_list COMMA expression {
        ast_add_child($1, $3);
        $$ = $1;
      }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s near '%s'\n", line_val, s, yytext);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Cannot open file: %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }
    
    printf("Starting parser...\n");
    int result = yyparse();
    
    if (result == 0) {
        printf("\n=== Abstract Syntax Tree ===\n");
        print_ast(ast_root, 0);
        printf("\nParsing completed successfully!\n");
    } else {
        printf("\nParsing failed with errors.\n");
    }
    
    if (ast_root) {
        free_ast(ast_root);
    }
    
    if (yyin != stdin) {
        fclose(yyin);
    }
    
    return result;
}
