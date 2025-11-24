%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>

#include <llvm-c/Core.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>

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
    NODE_POSTFIX_EXPR,
    NODE_VA_LIST,
    NODE_VA_START,
    NODE_VA_ARG,
    NODE_VA_END,
    NODE_VA_LIST_TYPE,
    NODE_ELLIPSIS,
    NODE_VAR_ARGS,
    NODE_CAST_EXPR,
    NODE_SIZEOF_EXPR,
    NODE_GOTO_STMT,
    NODE_ACCESS_SPEC,
    NODE_STATIC_ASSERT,
    NODE_ATTR_EXPR,
    NODE_ATOMIC_EXPR
} NodeType;

typedef struct ASTNode {
    NodeType type;
    int line_number;
    char *value;
    char *op;
    char* datatype;

    /* ========== LLVM IR Generation Fields ========== */
    bool is_array;
    int array_dimensions;
    int* array_sizes;
    int init_list_dimentions;
    int *init_list_sizes;
    bool is_pointer;
    int pointer_depth;
    bool is_reference;
    bool is_function;
    bool is_parameter;
    int param_count;
    bool has_ellipsis;
    int size;
    int max_array_dim;
    bool is_const;
    bool is_static;
    bool is_unsigned;
    char* struct_name;
    bool is_inline;
    bool is_constexpr;
    bool is_consteval;
    bool is_constinit;
    bool is_postfix;
    bool is_volatile;           // Whether type is volatile
    bool is_va_list;            // Whether this is a va_list type
    bool is_va_arg;             // Whether this is a va_arg expression
    char* va_list_name;         // Name of va_list variable
    char* va_arg_type;          // Type requested in va_arg

    struct ASTNode *left;
    struct ASTNode *right;
    struct ASTNode *child;
    struct ASTNode *next;
} ASTNode;
void generate_global_static_declaration(ASTNode* node);

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
        case NODE_VA_START: return "VA_START";
        case NODE_VA_ARG: return "VA_ARG";
        case NODE_VA_END: return "VA_END";
        case NODE_VA_LIST_TYPE: return "VA_LIST_TYPE";
        case NODE_ELLIPSIS: return "ELLIPSIS";

        default: return "UNKNOWN";
    }
}

/* ==================== SEMANTIC ANALYSIS STRUCTURES ==================== */

typedef struct semantic_info {
    char* type;
    char* identifier;
    char* value;
    int size;
    bool isarray;
    bool isfunction;
    bool ispointer;
    bool isparam;
    bool isref;
    int pointerdepth;
    int param_count;
    bool has_ellipsis;
    int init_list_dimentions;
    int * init_list_sizes;

    /* ========== Additional fields for complete LLVM info ========== */
    int array_dimensions;
    int max_array_dim;   // Number of array dimensions
    int* array_sizes;           // Array sizes for each dimension
    bool is_const;              // Whether type is const
    bool is_static;             // Whether storage is static
    bool is_unsigned;           // Whether type is unsigned
    bool is_volatile;           // Whether type is volatile
    bool is_extern;             // Whether storage is extern
    bool is_register;           // Whether storage is register
    bool is_thread_local;       // Whether storage is thread_local
    bool is_mutable;            // Whether member is mutable (C++)
    bool is_virtual;            // Whether function is virtual (C++)
    bool is_pure_virtual;       // Whether function is pure virtual (C++)
    bool is_override;           // Whether function is override (C++)
    bool is_final;              // Whether function/class is final (C++)
    bool is_explicit;           // Whether constructor is explicit (C++)
    bool is_inline;             // Whether function is inline
    bool is_constexpr;          // Whether variable/function is constexpr
    bool is_consteval;          // Whether function is consteval (C++20)
    bool is_constinit;          // Whether variable is constinit (C++20)
    char* struct_name;          // For struct types
    char* class_name;           // For class types
    char* enum_name;            // For enum types
    char* namespace_name;       // For namespace
    char* template_params;      // For template parameters
    /* ============================================================== */

    struct semantic_info* next;
    struct semantic_info* prev;
    struct semantic_info* params;
} semantic_info;

typedef struct lambda_capture_info {
    char* identifier;
    bool by_reference;  // true for & capture, false for = or explicit capture
    bool is_implicit;   // true for [=] or [&], false for explicit captures
    struct lambda_capture_info* next;
} lambda_capture_info;

typedef struct lambda_scope_info {
    semantic_info* captured_vars;  // Variables captured from outer scope
    semantic_info* lambda_params;  // Lambda parameters
    char* return_type;             // Lambda return type
    struct lambda_scope_info* parent; // Parent scope for nested lambdas
} lambda_scope_info;

/* ==================== AST CREATION FUNCTIONS ==================== */

ASTNode* create_ast_node(NodeType type, int line, char *value) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = type;
    node->line_number = line;
    node->value = value ? strdup(value) : NULL;
    node->op = NULL;
    node->datatype = NULL;

    /* Initialize LLVM IR fields */
    node->is_array = false;
    node->array_dimensions = 0;
    node->max_array_dim=0;
    node->init_list_dimentions=0;
    node->array_sizes = NULL;
    node->init_list_sizes=  NULL;
    node->is_pointer = false;
    node->pointer_depth = 0;
    node->is_reference = false;
    node->is_function = false;
    node->is_parameter = false;
    node->param_count = 0;
    node->has_ellipsis = false;
    node->size = 0;
    node->is_const = false;
    node->is_static = false;
    node->is_unsigned = false;
    node->is_inline = false;
    node->is_constexpr = false;
    node->is_consteval = false;
    node->is_constinit = false;
    node->struct_name = NULL;
    node->is_volatile = false;
    node->is_va_list = false;
    node->is_va_arg = false;
    node->va_list_name = NULL;
    node->va_arg_type = NULL;

    node->left = NULL;
    node->right = NULL;
    node->child = NULL;
    node->next = NULL;
    return node;
}

ASTNode* create_binary_node(NodeType type, int line, char *op, ASTNode *left, ASTNode *right) {
    ASTNode *node = create_ast_node(type, line, NULL);
    node->op = op ? strdup(op) : NULL;
    node->left = left;
    node->right = right;
    return node;
}

ASTNode* create_unary_node(NodeType type, int line, char *op, ASTNode *operand) {
    ASTNode *node = create_ast_node(type, line, NULL);
    node->op= op ? strdup(op) : NULL;
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

/* ==================== HELPER FUNCTIONS FOR LLVM FIELDS ==================== */

void set_type_modifiers(ASTNode* node, char* type_name) {
    if (!node || !type_name) return;

    // Check for type modifiers
    node->is_const = (strstr(type_name, "const") != NULL);
    node->is_static = (strstr(type_name, "static") != NULL);
    node->is_unsigned = (strstr(type_name, "unsigned") != NULL);
    node->is_inline = (strstr(type_name, "inline") != NULL);
    node->is_constexpr = (strstr(type_name, "constexpr") != NULL);
    node->is_consteval = (strstr(type_name, "consteval") != NULL);
    node->is_constinit = (strstr(type_name, "constinit") != NULL);


    // Set size based on type
    if (strcmp(type_name, "int") == 0 || strcmp(type_name, "unsigned int") == 0) {
        node->size = 4;
    } else if (strcmp(type_name, "float") == 0 ||strcmp(type_name, "static float") == 0 ) {
        node->size = 4;
    } else if (strcmp(type_name, "double") == 0 || strcmp(type_name, "static double") == 0) {
        node->size = 8;
    } else if (strcmp(type_name, "char") == 0 || strcmp(type_name, "unsigned char") == 0) {
        node->size = 1;
    } else if (strcmp(type_name, "short") == 0) {
        node->size = 2;
    } else if (strcmp(type_name, "long") == 0) {
        node->size = 8;
    } else if (strcmp(type_name, "long long") == 0) {
        node->size = 8;
    } else if (strcmp(type_name, "bool") == 0) {
        node->size = 1;
    } 
    else if (strcmp(type_name, "long int") == 0) {
    node->size = 8;
   }
   else if (strcmp(type_name, "string") == 0) {
    node->size = 8;
    node->is_pointer = true;
    node->pointer_depth = 1;
   }
    else if (strstr(type_name, "struct") != NULL) {
        // Struct size will be calculated during struct processing
        node->size = 0; // To be calculated
    } else if (strstr(type_name, "class") != NULL) {
        // Class size will be calculated during class processing
        node->size = 0; // To be calculated
    }
}

void set_type_modifiers_semantic(semantic_info* info, char* type_name) {
    if (!info || !type_name) return;

    // Check for type modifiers
    info->is_const = (strstr(type_name, "const") != NULL);
    info->is_static = (strstr(type_name, "static") != NULL);
    info->is_unsigned = (strstr(type_name, "unsigned") != NULL);
    info->is_volatile = (strstr(type_name, "volatile") != NULL);
    info->is_extern = (strstr(type_name, "extern") != NULL);
    info->is_register = (strstr(type_name, "register") != NULL);
    info->is_thread_local = (strstr(type_name, "thread_local") != NULL);
    info->is_mutable = (strstr(type_name, "mutable") != NULL);
    info->is_virtual = (strstr(type_name, "virtual") != NULL);
    info->is_inline = (strstr(type_name, "inline") != NULL);
    info->is_constexpr = (strstr(type_name, "constexpr") != NULL);
    info->is_consteval = (strstr(type_name, "consteval") != NULL);
    info->is_constinit = (strstr(type_name, "constinit") != NULL);
    info->is_explicit = (strstr(type_name, "explicit") != NULL);

     // Set size based on type
    if (strcmp(type_name, "int") == 0 || strcmp(type_name, "unsigned int") == 0) {
        info->size = 4;
    } else if (strcmp(type_name, "float") == 0 ||strcmp(type_name, "static float") == 0 ) {
        info->size = 4;
    } else if (strcmp(type_name, "double") == 0 || strcmp(type_name, "static double") == 0) {
        info->size = 8;
    } else if (strcmp(type_name, "char") == 0 || strcmp(type_name, "unsigned char") == 0) {
        info->size = 1;
    } else if (strcmp(type_name, "short") == 0) {
        info->size = 2;
    } else if (strcmp(type_name, "long") == 0) {
        info->size = 8;
    } else if (strcmp(type_name, "long long") == 0) {
        info->size = 8;
    } else if (strcmp(type_name, "bool") == 0) {
        info->size = 1;
    } 
    else if (strcmp(type_name, "long int") == 0) {
     info->size = 8;
   }
   else if (strcmp(type_name, "string") == 0) {
    info->size = 8;
    info->ispointer = true;
    info->pointerdepth = 1;
   }
    else if (strstr(type_name, "struct") != NULL) {
        // Struct size will be calculated during struct processing
        info->size = 0; // To be calculated
    } else if (strstr(type_name, "class") != NULL) {
        // Class size will be calculated during class processing
        info->size = 0; // To be calculated
    }
}

void copy_llvm_fields(ASTNode* dest, ASTNode* src) {
    if (!dest || !src) return;

    dest->is_array = src->is_array;
    dest->pointer_depth = src->pointer_depth;
    dest->is_pointer = src->is_pointer;
    dest->is_reference = src->is_reference;
    dest->is_function = src->is_function;
    dest->is_parameter = src->is_parameter;
    dest->param_count = src->param_count;
    dest->has_ellipsis = src->has_ellipsis;
    dest->size = src->size;
    dest->max_array_dim=src->max_array_dim;
    dest->is_const = src->is_const;
    dest->is_static = src->is_static;
    dest->is_unsigned = src->is_unsigned;
    dest->is_inline = src->is_inline;
    dest->is_constexpr = src->is_constexpr;
    dest->is_consteval = src->is_consteval;
    dest->is_constinit = src->is_constinit;

    // Copy array dimensions and sizes
    dest->array_dimensions = src->array_dimensions;
    if (src->array_sizes && src->array_dimensions > 0) {
        dest->array_sizes =(int*) malloc(src->array_dimensions * sizeof(int));
        memcpy(dest->array_sizes, src->array_sizes, src->array_dimensions * sizeof(int));
    }

    // Copy struct name
    if (src->struct_name) {
        dest->struct_name = strdup(src->struct_name);
    }
}

void copy_semantic_to_ast(ASTNode* dest, semantic_info* src) {
    if (!dest || !src) return;

    // Copy all semantic info fields to AST node
    dest->is_array = src->isarray;
    dest->is_pointer = src->ispointer;
    dest->pointer_depth = src->pointerdepth;
    dest->is_reference = src->isref;
    dest->is_function = src->isfunction;
    dest->is_parameter = src->isparam;
    dest->param_count = src->param_count;
    dest->has_ellipsis = src->has_ellipsis;
    dest->size = src->size;
    dest->max_array_dim=src->max_array_dim;
    // Copy the new extended fields
    dest->is_const = src->is_const;
    dest->is_static = src->is_static;
    dest->is_unsigned = src->is_unsigned;
    dest->is_inline = src->is_inline;
    dest->is_constexpr = src->is_constexpr;
    dest->is_consteval = src->is_consteval;
    dest->is_constinit = src->is_constinit;
    dest->array_dimensions = src->array_dimensions;

    // Copy array sizes if available
    if (src->array_sizes && src->array_dimensions > 0) {
        dest->array_sizes = (int*)malloc(src->array_dimensions * sizeof(int));
        memcpy(dest->array_sizes, src->array_sizes, src->array_dimensions * sizeof(int));
    }

    // Copy struct name
    if (src->struct_name) {
        dest->struct_name = strdup(src->struct_name);
    }
}

/* ==================== SEMANTIC ANALYSIS FUNCTIONS ==================== */

semantic_info* create_semantic_info(char* type, char* identifier, bool isfunction, bool ispointer,bool isparam,bool is_refrence, int pointerdepth, bool isarray, int param_count, bool has_ellipsis) {
    semantic_info* info = (semantic_info*)malloc(sizeof(semantic_info));
    info->type = type ? strdup(type) : NULL;
    info->identifier = identifier ? strdup(identifier) : NULL;
    info->value = NULL;
    info->size = 0;
    info->isarray = isarray;
    info->isparam = isparam;
    info->isref = is_refrence;
    info->isfunction = isfunction;
    info->ispointer = ispointer;
    info->pointerdepth = pointerdepth;
    info->param_count = param_count;
    info->has_ellipsis = has_ellipsis;

    /* Initialize extended LLVM fields */
    info->array_dimensions = 0;
    info->array_sizes = NULL;
    info->array_sizes = NULL;
    info->init_list_sizes=  NULL;
    info->is_const = false;
    info->is_static = false;
    info->is_unsigned = false;
    info->is_volatile = false;
    info->is_extern = false;
    info->is_register = false;
    info->is_thread_local = false;
    info->is_mutable = false;
    info->is_virtual = false;
    info->is_pure_virtual = false;
    info->is_override = false;
    info->is_final = false;
    info->is_explicit = false;
    info->is_inline = false;
    info->is_constexpr = false;
    info->is_consteval = false;
    info->is_constinit = false;
    info->struct_name = NULL;
    info->class_name = NULL;
    info->enum_name = NULL;
    info->namespace_name = NULL;
    info->template_params = NULL;

    // Set type modifiers and size based on type
    if (type) {
        set_type_modifiers_semantic(info, type);
    }

    info->next = NULL;
    info->prev = NULL;
    info->params = NULL;
    return info;
}

void free_semantic_info(semantic_info* info) {
    if (!info) return;
    if (info->type) free(info->type);
    if (info->identifier) free(info->identifier);
    if (info->value) free(info->value);
    if (info->array_sizes) free(info->array_sizes);
     if(info->init_list_sizes) free(info->init_list_sizes);
    if (info->struct_name) free(info->struct_name);
    if (info->class_name) free(info->class_name);
    if (info->enum_name) free(info->enum_name);
    if (info->namespace_name) free(info->namespace_name);
    if (info->template_params) free(info->template_params);
    free(info);
}

void free_semantic_scope(semantic_info* scope) {
    semantic_info* current = scope;
    while (current) {
        semantic_info* next = current->next;
        free_semantic_info(current);
        current = next;
    }
}

semantic_info* find_in_scope(semantic_info* scope, char* identifier) {
    semantic_info* current = scope;

    while (current) {
        if (current->identifier && strcmp(current->identifier, identifier) == 0) {
            return current;
        }
        current = current->next;
    }
    return NULL;
}

bool function_has_ellipsis(ASTNode* param_list) {
    if (!param_list) return false;
    ASTNode* current = param_list->child;
    while (current) {
        if (current->type == NODE_ELLIPSIS) {
            return true;
        }
        current = current->next;
    }
    return false;
}

// Fix the count_function_params function
int count_function_params(ASTNode* param_list) {
    if (!param_list) return 0;
    int count = 0;
    ASTNode* current = param_list->child;
    while (current) {
        if (current->type != NODE_ELLIPSIS && current->type != NODE_VAR_ARGS) {
            count++;
        }
        current = current->next;
    }
    return count;
}

// Fix get_type_info_from_declarator
void get_type_info_from_declarator(ASTNode* declarator, bool* is_pointer, int* pointer_depth, bool* is_array, bool* is_refrence, int** array_sizes, int* array_dimensions) {
    *is_pointer = false;
    *pointer_depth = 0;
    *is_array = false;
    *is_refrence = false;
    *array_dimensions = 0;
    *array_sizes = NULL;

    if (!declarator) return;

    ASTNode* current = declarator;
    int dim_count = 0;
    int sizes[10] = {0};

    while (current) {
        if (current->type == NODE_DECLARATOR && current->value && strcmp(current->value, "*") == 0) {
            *is_pointer = true;
            (*pointer_depth)++;
        }
        else if (current->type == NODE_MULTI_PTR && current->value && strcmp(current->value, "*") == 0) {
            *is_pointer = true;
            (*pointer_depth)++;
        }
         else if (current->type == NODE_INDEX) {
            *is_array = true;
            dim_count++;
            if (current->child && current->child->next) {
                ASTNode* size_expr = current->child->next;
                if (size_expr->type == NODE_LITERAL && size_expr->value) {
                    sizes[dim_count-1] = atoi(size_expr->value);
                } else {
                    sizes[dim_count-1] = -1;
                }
            } else {
                sizes[dim_count-1] = -1;
            }
        } else if (current->type == NODE_DECLARATOR && current->value && strcmp(current->value, "&") == 0) {
            *is_refrence = true;
        }

        if (current->child) {
            current = current->child;
        } else {
            break;
        }
    }

    *array_dimensions = dim_count;
    if (dim_count > 0) {
        for (int i = 0, j = dim_count - 1; i < j; i++, j--) {
            int temp = sizes[i];
            sizes[i] = sizes[j];
            sizes[j] = temp;
        }
        *array_sizes = (int*)malloc(dim_count * sizeof(int));
        memcpy(*array_sizes, sizes, dim_count * sizeof(int));

        declarator->is_array = true;
        declarator->array_dimensions = dim_count;
        declarator->array_sizes = (int*)malloc(dim_count * sizeof(int));
        memcpy(declarator->array_sizes, sizes, dim_count * sizeof(int));
    }
}

// Fix is_valid_lvalue function
bool is_valid_lvalue(ASTNode* node) {
    if (!node) return false;

    switch (node->type) {
        case NODE_IDENTIFIER:
            return true;
        case NODE_INDEX:
            return true;
        case NODE_MEMBER_ACCESS:
            return true;
        case NODE_UNARY_OP:
            if (node->op && strcmp(node->op, "*") == 0) {
                return true;
            }
            return false;
        case NODE_CALL:
            return false;
        case NODE_BINARY_OP:
            return false;
        case NODE_TERNARY_OP:
            return false;
        case NODE_LITERAL:
        case NODE_INIT_LIST:
            return false;
        case NODE_CAST_EXPR:
            return false;
        default:
            return false;
    }
}

char* get_identifier_from_declarator(ASTNode* declarator) {
    if (!declarator) return NULL;

    ASTNode* current = declarator;
    while (current) {
        if (current->type == NODE_IDENTIFIER) {
            return strdup(current->value);
        }
        if (current->type == NODE_DECLARATOR && current->child) {
            current = current->child;
        } else if (current->type == NODE_INDEX && current->child) {
            current = current->child;
        }
        else if (current->type == NODE_MULTI_PTR) {
            current = current->next;
        }
        else {
            break;
        }
    }
    return NULL;
}


void print_scope(semantic_info* scope) {
    semantic_info * cur = scope;
    while (cur) {
        printf("node type %s \n", cur->type);
        printf("node identifier %s \n", cur->identifier);
        cur = cur->next;
    }
    return;
}


bool is_type_compatible(char* t1, char* t2) {
    if (!t1 || !t2) return false;

    // Handle lambda types
    if (strcmp(t1, "lambda_function") == 0) {
        // Lambda can be assigned to function pointers and auto
        return (strstr(t2, "(*") != NULL || strstr(t2, "function") != NULL ||
                strcmp(t2, "auto") == 0);
    }

    if (strcmp(t2, "lambda_function") == 0) {
        // Function pointers and auto can be assigned to lambda
        return (strstr(t1, "(*") != NULL || strstr(t1, "function") != NULL ||
                strcmp(t1, "auto") == 0);
    }

    // Handle va_list type
        if (strcmp(t1, "va_list") == 0 || strcmp(t2, "va_list") == 0) {
            // va_list is only compatible with itself
            return strcmp(t1, t2) == 0;
        }


    // Handle auto type (can be assigned anything)
    if (strcmp(t1, "auto") == 0 || strcmp(t2, "auto") == 0) {
        return true;
    }

    // Handle void pointer compatibility
    if ((strcmp(t1, "void*") == 0 && t2 && strstr(t2, "*") != NULL) ||
        (strcmp(t2, "void*") == 0 && t1 && strstr(t1, "*") != NULL)) {
        return true;
    }

    // Original numeric type compatibility check
    char* numeric[] = {"int", "float", "double", "long", "unsigned int", "unsigned float", "unsigned double", "unsigned long",
                      "long int", "long float", "long double", "long long","bool"};
    bool isnumeric1 = false;
    bool isnumeric2 = false;
    for (int i = 0; i <13; i++) {
        if (strcmp(numeric[i], t1) == 0) {
            isnumeric1 = true;
        }
        if (strcmp(numeric[i], t2) == 0) {
            isnumeric2 = true;
        }
    }

    if ((strcmp(t1, "bool") == 0 && strcmp(t2, "bool") == 0) ||
    (strcmp(t1, "bool") == 0 && isnumeric2) ||
    (isnumeric1 && strcmp(t2, "bool") == 0)) {
    return true;
}

    if (isnumeric1 && isnumeric2) return true;

    if ((strcmp(t1, "string") == 0 && strcmp(t2, "string") == 0) ||
        (strcmp(t1, "char") == 0 && strcmp(t2, "char") == 0) ||
        (strcmp(t1, "bool") == 0 && strcmp(t2, "bool") == 0) ||
         (strcmp(t1, "string") == 0 && strcmp(t2, "char") == 0) ||
         (strcmp(t1, "char") == 0 && strcmp(t2, "string") == 0)){
        return true;
    }

    // Struct type compatibility
    if (strstr(t1, "struct") != NULL && strstr(t2, "struct") != NULL) {
        // Extract struct names and compare
        // This is simplified - in practice you'd need proper struct name extraction
        return strcmp(t1, t2) == 0;
    }

    // Class type compatibility
    if (strstr(t1, "class") != NULL && strstr(t2, "class") != NULL) {
        return strcmp(t1, t2) == 0;
    }

    // Enum type compatibility
    if (strstr(t1, "enum") != NULL && strstr(t2, "enum") != NULL) {
        return strcmp(t1, t2) == 0;
    }

    return false;
}

int precedence(char *t) {
    if (!t) return -1;

    if (strcmp(t, "bool") == 0) return 0;
    if (strcmp(t, "char") == 0) return 1;
    if (strcmp(t, "short") == 0) return 2;
    if (strcmp(t, "string") == 0) return 3;
    if (strcmp(t, "int") == 0) return 4;
    if (strcmp(t, "float") == 0) return 5;
    if (strcmp(t, "double") == 0) return 6;
    if (strcmp(t, "long") == 0) return 7;
    if (strcmp(t, "unsigned int") == 0) return 8;
    if (strcmp(t, "unsigned float") == 0) return 9;
    if (strcmp(t, "unsigned double") == 0) return 10;
    if (strcmp(t, "unsigned long") == 0) return 11;
    if (strcmp(t, "long int") == 0) return 12;
    if (strcmp(t, "long double") == 0) return 13;
    if (strcmp(t, "long long") == 0) return 14;

    return -1;
}

bool is_assignment_compatible(char* t1, char* t2, bool isptr1, bool isptr2, bool isarr1, bool isarr2,
                             int ptrdepth1, int ptrdepth2, int dim1, int dim2, ASTNode * left, ASTNode* right) {
    if (isptr1 && isptr2) {
        if (strcmp(t1, "string") == 0 || strcmp(t2, "string") == 0) {
            return false;
        } else if (!is_type_compatible(t1, t2)) {
            return false;
        } else if (ptrdepth1 != ptrdepth2) {
            return false;
        }
        return true;
    }

    // Add more conditions as needed
    return false;
}


/* ==================== LAMBDA HELPER FUNCTIONS ==================== */

lambda_capture_info* create_lambda_capture_info(char* identifier, bool by_reference, bool is_implicit) {
    lambda_capture_info* capture = (lambda_capture_info*)malloc(sizeof(lambda_capture_info));
    capture->identifier = identifier ? strdup(identifier) : NULL;
    capture->by_reference = by_reference;
    capture->is_implicit = is_implicit;
    capture->next = NULL;
    return capture;
}

void free_lambda_capture_info(lambda_capture_info* capture) {
    if (!capture) return;
    if (capture->identifier) free(capture->identifier);
    free_lambda_capture_info(capture->next);
    free(capture);
}

lambda_scope_info* create_lambda_scope_info(lambda_scope_info* parent) {
    lambda_scope_info* scope = (lambda_scope_info*)malloc(sizeof(lambda_scope_info));
    scope->captured_vars = NULL;
    scope->lambda_params = NULL;
    scope->return_type = NULL;
    scope->parent = parent;
    return scope;
}

void free_lambda_scope_info(lambda_scope_info* scope) {
    if (!scope) return;
    free_semantic_scope(scope->captured_vars);
    free_semantic_scope(scope->lambda_params);
    if (scope->return_type) free(scope->return_type);
    free(scope);
}

// Function to process lambda capture list
lambda_capture_info* process_lambda_capture(ASTNode* capture_node, semantic_info* current_scope) {
    if (!capture_node) return NULL;

    lambda_capture_info* capture_list = NULL;
    lambda_capture_info* last_capture = NULL;

    switch (capture_node->type) {
        case NODE_LAMBDA_CAPTURE:
            if (capture_node->value) {
                // Handle implicit captures [=] or [&]
                if (strcmp(capture_node->value, "=") == 0) {
                    // Capture all by value
                    capture_list = create_lambda_capture_info(NULL, false, true);
                } else if (strcmp(capture_node->value, "&") == 0) {
                    // Capture all by reference
                    capture_list = create_lambda_capture_info(NULL, true, true);
                } else if (strcmp(capture_node->value, "empty") == 0) {
                    // Empty capture list [] - capture nothing
                    return NULL;
                }
            } else {
                // Process explicit capture list
                ASTNode* child = capture_node->child;
                while (child) {
                    if (child->type == NODE_IDENTIFIER) {
                        // Simple capture by value: [var]
                        lambda_capture_info* capture = create_lambda_capture_info(
                            child->value, false, false);

                        if (!capture_list) {
                            capture_list = capture;
                        } else {
                            last_capture->next = capture;
                        }
                        last_capture = capture;
                    } else if (child->type == NODE_TYPE && child->value && strcmp(child->value, "&") == 0) {
                        // Capture by reference: [&var]
                        ASTNode* next_child = child->next;
                        if (next_child && next_child->type == NODE_IDENTIFIER) {
                            lambda_capture_info* capture = create_lambda_capture_info(
                                next_child->value, true, false);

                            if (!capture_list) {
                                capture_list = capture;
                            } else {
                                last_capture->next = capture;
                            }
                            last_capture = capture;
                        }
                    }
                    child = child->next;
                }
            }
            break;

        default:
            break;
    }

    return capture_list;
}

// Function to validate captured variables
void validate_captured_variables(lambda_capture_info* capture_list, semantic_info* current_scope, int line_number) {
    if (!capture_list) return;

    lambda_capture_info* current = capture_list;
    while (current) {
        if (current->identifier && !current->is_implicit) {
            // Check if the variable exists in the current scope
            semantic_info* var_info = find_in_scope(current_scope, current->identifier);
            if (!var_info) {
                printf("Semantic Error at line %d: Cannot capture undeclared variable '%s'\n",
                       line_number, current->identifier);
            } else {
                // Check capture restrictions
                if (var_info->is_static) {
                    printf("Semantic Warning at line %d: Capturing static variable '%s' may not work as expected\n",
                           line_number, current->identifier);
                }

                if (var_info->is_const && current->by_reference) {
                    printf("Semantic Warning at line %d: Capturing const variable '%s' by reference\n",
                           line_number, current->identifier);
                }
            }
        }
        current = current->next;
    }
}

// Function to create captured variables scope
semantic_info* create_captured_scope(lambda_capture_info* capture_list, semantic_info* outer_scope) {
    if (!capture_list || !outer_scope) return NULL;

    semantic_info* captured_scope = NULL;
    lambda_capture_info* current = capture_list;

    while (current) {
        if (current->identifier && !current->is_implicit) {
            // Find the variable in outer scope
            semantic_info* outer_var = find_in_scope(outer_scope, current->identifier);
            if (outer_var) {
                // Create a copy for the captured scope
                semantic_info* captured_var = create_semantic_info(
                    outer_var->type, outer_var->identifier,
                    outer_var->isfunction, outer_var->ispointer,
                    false, // Not a parameter in lambda context
                    current->by_reference, // Use capture method for reference
                    outer_var->pointerdepth, outer_var->isarray,
                    0, false
                );

                // Copy extended fields
                captured_var->array_dimensions = outer_var->array_dimensions;
                if (outer_var->array_sizes && outer_var->array_dimensions > 0) {
                    captured_var->array_sizes = (int*) malloc(outer_var->array_dimensions * sizeof(int));
                    memcpy(captured_var->array_sizes, outer_var->array_sizes,
                           outer_var->array_dimensions * sizeof(int));
                }
                captured_var->is_const = outer_var->is_const;
                captured_var->is_static = outer_var->is_static;
                captured_var->is_unsigned = outer_var->is_unsigned;
                captured_var->struct_name = outer_var->struct_name ? strdup(outer_var->struct_name) : NULL;
                captured_var->size = outer_var->size;

                // Add to captured scope
                if (!captured_scope) {
                    captured_scope = captured_var;
                } else {
                    semantic_info* last = captured_scope;
                    while (last->next) last = last->next;
                    last->next = captured_var;
                    captured_var->prev = last;
                }
            }
        }
        current = current->next;
    }

    return captured_scope;
}

bool is_type_compatible_with_lambda(char* t1, char* t2, ASTNode* lambda_node) {
    // If one type is a lambda, check if it's compatible with function pointer
    if (lambda_node && lambda_node->type == NODE_LAMBDA_EXPR) {
        // Lambdas are compatible with function pointers that match their signature
        if (strstr(t2, "(*") != NULL || strstr(t2, "function") != NULL) {
            // Basic signature matching - in practice, you'd need more detailed checking
            return true;
        }

        // Lambdas can be assigned to auto types
        if (strcmp(t2, "auto") == 0) {
            return true;
        }
    }

    return is_type_compatible(t1, t2);
}

/* ==================== STRUCT/CLASS HELPER FUNCTIONS ==================== */

bool is_struct_or_class_type(char* type_name) {
    if (!type_name) return false;
    return (strstr(type_name, "struct") != NULL || strstr(type_name, "class") != NULL);
}

char* extract_struct_name(char* type_name) {
    if (!type_name) return NULL;

    char* struct_pos = strstr(type_name, "struct ");
    if (struct_pos) {
        return strdup(struct_pos + 7); // Skip "struct "
    }

    char* class_pos = strstr(type_name, "class ");
    if (class_pos) {
        return strdup(class_pos + 6); // Skip "class "
    }

    return strdup(type_name);
}


/* ==================== CORRECTED DIMENSION ANALYSIS FUNCTION ==================== */

void analyze_init_list_dimensions(ASTNode* node, int* dimensions, int* current_dim, bool* has_nested_lists, int depth) {
    if (!node || depth >= 3) {
        return; // Max 3 dimensions
    }

    ASTNode* child = node->child;
    int element_count = 0;
    bool has_any_nested_lists = false;
    int first_nested_size = -1;
    bool consistent_nested_sizes = true;

    // First pass: count elements and check for nested lists
    while (child) {
        element_count++;

        if (child->type == NODE_INIT_LIST) {
            has_any_nested_lists = true;
            *has_nested_lists = true;

            // Count elements in this nested list
            ASTNode* nested_child = child->child;
            int nested_element_count = 0;
            while (nested_child) {
                nested_element_count++;
                nested_child = nested_child->next;
            }

            if (first_nested_size == -1) {
                first_nested_size = nested_element_count;
            } else if (nested_element_count != first_nested_size) {
                consistent_nested_sizes = false;
                printf("Warning at line %d: Inconsistent nested list sizes at depth %d. Expected %d, got %d\n",
                       child->line_number, depth, first_nested_size, nested_element_count);
            }
        }
        child = child->next;
    }

    printf("DEBUG: Depth %d: %d elements, has_nested=%d\n", depth, element_count, has_any_nested_lists);

    // Set current dimension size
    dimensions[depth] = element_count;
    if (depth >= *current_dim) {
        *current_dim = depth + 1;
    }

    // If we have nested lists, set the next dimension and analyze recursively
    if (has_any_nested_lists && depth < 2) {
        // Set next dimension size based on nested lists
        if (first_nested_size > 0) {
            dimensions[depth + 1] = first_nested_size;
            if (depth + 1 >= *current_dim) {
                *current_dim = depth + 2;
            }
            printf("DEBUG: Set dimension %d size to %d\n", depth + 1, first_nested_size);
        }

        // Recursively analyze nested lists for deeper dimensions
        child = node->child;
        while (child) {
            if (child->type == NODE_INIT_LIST) {
                int nested_dims[3] = {0};
                int nested_current_dim = 0;
                bool nested_has_nested = false;

                analyze_init_list_dimensions(child, nested_dims, &nested_current_dim, &nested_has_nested, depth + 1);

                // If nested list has deeper dimensions, update our dimensions
                if (nested_current_dim > (depth + 1)) {
                    for (int i = depth + 1; i < nested_current_dim && i < 3; i++) {
                        dimensions[i] = nested_dims[i];
                    }
                    if (nested_current_dim > *current_dim) {
                        *current_dim = nested_current_dim;
                    }
                }
            }
            child = child->next;
        }
    }
}

/* ==================== COMPREHENSIVE INIT LIST DIMENSION VALIDATION ==================== */

bool validate_init_list_dimensions(ASTNode* init_list, int* expected_sizes, int dimensions, int current_dim, char* identifier, int line_number) {
    if (!init_list || current_dim >= dimensions) {
        return true;
    }

    ASTNode* child = init_list->child;
    int element_count = 0;

    // Count elements at current level
    while (child) {
        element_count++;
        child = child->next;
    }

    // Check if element count matches expected size for this dimension
    if (expected_sizes && expected_sizes[current_dim] > 0) {
        if (element_count != expected_sizes[current_dim]) {
            printf("Semantic Error at line %d: Dimension %d size mismatch for '%s'. Expected %d elements, got %d\n",
                   line_number, current_dim, identifier, expected_sizes[current_dim], element_count);
            return false;
        }
    }

    // If we have more dimensions to check, validate nested lists
    if (current_dim < dimensions - 1) {
        child = init_list->child;
        int child_index = 0;

        while (child) {
            if (child->type == NODE_INIT_LIST) {
                // Recursively validate the nested list
                if (!validate_init_list_dimensions(child, expected_sizes, dimensions, current_dim + 1, identifier, line_number)) {
                    return false;
                }
            } else {
                // If we expect nested lists but found a scalar, it's an error
                if (current_dim < dimensions - 1) {
                    printf("Semantic Error at line %d: Expected nested list at dimension %d for '%s', but found scalar value\n",
                           line_number, current_dim + 1, identifier);
                    return false;
                }
            }
            child = child->next;
            child_index++;
        }

        // Check if all nested lists have consistent structure
        child = init_list->child;
        ASTNode* first_nested = NULL;

        // Find first nested list
        while (child && !first_nested) {
            if (child->type == NODE_INIT_LIST) {
                first_nested = child;
            }
            child = child->next;
        }

        if (first_nested) {
            // Verify all nested lists have the same structure
            child = init_list->child;
            while (child) {
                if (child->type == NODE_INIT_LIST) {
                    // Compare element counts at next dimension
                    ASTNode* nested_child1 = first_nested->child;
                    ASTNode* nested_child2 = child->child;
                    int count1 = 0, count2 = 0;

                    while (nested_child1) { count1++; nested_child1 = nested_child1->next; }
                    while (nested_child2) { count2++; nested_child2 = nested_child2->next; }

                    if (count1 != count2) {
                        printf("Semantic Error at line %d: Inconsistent nested list sizes at dimension %d for '%s'. Expected %d elements in all nested lists\n",
                               line_number, current_dim + 1, identifier, count1);
                        return false;
                    }
                }
                child = child->next;
            }
        }
    }

    return true;
}

char* find_return_type_in_node(ASTNode* node) {
    if (!node) return NULL;

    // Check if this is a return statement with expression
    if (node->type == NODE_RETURN_STMT && node->left) {
        if (node->left->datatype) {
            printf("DEBUG: Found return statement with type '%s'\n", node->left->datatype);
            return strdup(node->left->datatype);
        }
    }

    // Recursively search in children
    char* type = NULL;

    if (node->child) {
        type = find_return_type_in_node(node->child);
        if (type) return type;
    }

    if (node->left) {
        type = find_return_type_in_node(node->left);
        if (type) return type;
    }

    if (node->right) {
        type = find_return_type_in_node(node->right);
        if (type) return type;
    }

    if (node->next) {
        type = find_return_type_in_node(node->next);
        if (type) return type;
    }

    return NULL;
}
char* infer_lambda_return_type(ASTNode* body) {
    if (!body) return NULL;

    // Look for return statements in the body
    return find_return_type_in_node(body);
}

/* ==================== VARIABLE ARGUMENTS HELPER FUNCTIONS ==================== */

// Check if current function has variable arguments
bool current_function_has_varargs(semantic_info* current_scope) {
    semantic_info* scope = current_scope;
    while (scope) {
        if (scope->isfunction && scope->has_ellipsis) {
            return true;
        }
        scope = scope->next;
    }
    return false;
}

// Validate va_list usage
void validate_va_list_usage(ASTNode* node, semantic_info* current_scope, int line_number) {
    if (!current_function_has_varargs(current_scope)) {
        printf("Semantic Error at line %d: va_list used in function without variable arguments\n",
               line_number);
    }
}

// Get the last named parameter for va_start
char* get_last_named_parameter(semantic_info* func_info) {
    if (!func_info || !func_info->params) return NULL;

    semantic_info* last_param = func_info->params;
    while (last_param->next) {
        last_param = last_param->next;
    }
    return last_param->identifier;
}

// Validate type for va_arg
bool is_valid_va_arg_type(char* type_name) {
    if (!type_name) return false;

    // va_arg can only be used with fundamental types that don't require special handling
    char* valid_types[] = {
        "int", "unsigned int", "long", "unsigned long",
        "double", "float", "char", "unsigned char",
        "short", "unsigned short", "bool", "void*", "char*"
    };
    int num_types = sizeof(valid_types) / sizeof(valid_types[0]);

    for (int i = 0; i < num_types; i++) {
        if (strcmp(type_name, valid_types[i]) == 0) {
            return true;
        }
    }

    // Check for pointer types
    if (strstr(type_name, "*") != NULL) {
        return true;
    }

    return false;
}

/* ==================== COMPLETE SEMANTIC CHECKING FUNCTION ==================== */

void check_semantics(ASTNode* node, semantic_info** parent_scope) {
    if (!node) return;

    semantic_info* current_scope = *parent_scope;
    semantic_info* last_added = NULL;
    //printf("entering the scope of %s \n", node_type_to_string(node->type));
    //print_scope(current_scope);
    semantic_info * scope_start_ptr = NULL;

    switch (node->type) {

        case NODE_FUNCTION_DECL:
        case NODE_FUNCTION_DEF: {
            ASTNode* type_node = node->child;
            ASTNode* declarator_node = type_node ? type_node->next : NULL;
            ASTNode* param_list = declarator_node && declarator_node->next && declarator_node->next->type == NODE_PARAM_LIST ? declarator_node->next : NULL;

            if (type_node && declarator_node) {
                char* identifier = get_identifier_from_declarator(declarator_node);
                if (identifier) {
                    // Check for redeclaration in current scope
                    semantic_info* existing = find_in_scope(current_scope, identifier);
                    if (existing) {
                        printf("Semantic Error at line %d: Redeclaration of '%s'\n", node->line_number, identifier);
                        return;
                    }

                    bool is_pointer = false;
                    int pointer_depth = 0;
                    bool is_array = false;
                    bool is_refrence = false;
                    int* array_sizes = NULL;
                    int array_dimensions = 0;

                    get_type_info_from_declarator(declarator_node, &is_pointer, &pointer_depth, &is_array, &is_refrence, &array_sizes, &array_dimensions);

                    int param_count = param_list ? count_function_params(param_list) : 0;
                    bool has_ellipsis = param_list ? function_has_ellipsis(param_list) : false;

                    // Set ALL LLVM fields in the function node
                    if (node->datatype) free(node->datatype);
                    node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                    node->is_function = true;
                    node->is_pointer = is_pointer;
                    node->pointer_depth = pointer_depth;
                    node->is_array = is_array;
                    node->is_reference = is_refrence;
                    node->param_count = param_count;
                    node->has_ellipsis = has_ellipsis;
                    set_type_modifiers(node, type_node->value);

                    if (array_sizes) {
                        node->array_sizes = array_sizes;
                        node->array_dimensions = array_dimensions;
                    }

                    // Set fields in type node
                    if (type_node->datatype) free(type_node->datatype);
                    type_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                    type_node->is_function = true;
                    type_node->is_pointer = is_pointer;
                    type_node->pointer_depth = pointer_depth;
                    type_node->is_array = is_array;
                    type_node->is_reference = is_refrence;
                    type_node->param_count = param_count;
                    type_node->has_ellipsis = has_ellipsis;
                    set_type_modifiers(type_node, type_node->value);

                    // Set fields in declarator node
                    if (declarator_node->datatype) free(declarator_node->datatype);
                    declarator_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                    declarator_node->is_function = true;
                    declarator_node->is_pointer = is_pointer;
                    declarator_node->pointer_depth = pointer_depth;
                    declarator_node->is_array = is_array;
                    declarator_node->is_reference = is_refrence;
                    declarator_node->param_count = param_count;
                    declarator_node->has_ellipsis = has_ellipsis;
                    set_type_modifiers(declarator_node, type_node->value);

                    if (array_sizes) {
                        declarator_node->array_sizes = array_sizes;
                        declarator_node->array_dimensions = array_dimensions;
                    }

                    // Create function info and add to current scope
                    semantic_info* func_info = create_semantic_info(
                        type_node->value, identifier, true, is_pointer, false, is_refrence, pointer_depth,
                        is_array, param_count, has_ellipsis
                    );

                    // Set extended fields in semantic info
                    func_info->array_dimensions = array_dimensions;
                    if (array_sizes) {
                        func_info->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                        memcpy(func_info->array_sizes, array_sizes, array_dimensions * sizeof(int));
                    }
                    set_type_modifiers_semantic(func_info, type_node->value);

                    // Add to scope
                    if (!current_scope) {
                        current_scope = func_info;
                        *parent_scope = current_scope;
                    } else {
                        semantic_info* last = current_scope;
                        while (last->next) last = last->next;
                        last->next = func_info;
                        func_info->prev = last;
                    }
                    last_added = func_info;
                    scope_start_ptr = last_added;

                    // Create new scope for function parameters and body
                    semantic_info* func_scope = NULL;
                    semantic_info* last_func_param = NULL;

                    // CORRECTED: Properly initialize func_info->params as a linked list
                    semantic_info* func_params_list = NULL;
                    semantic_info* last_func_param_info = NULL;

                    // Check parameters and add them to function scope
                    if (param_list) {
                        // Set fields in param_list node - FIXED: removed is_parameter_list
                        param_list->param_count = param_count;

                        ASTNode* param = param_list->child;
                        while (param) {
                            if (param->type == NODE_VARIABLE_DECL) {
                                ASTNode* param_type = param->child;
                                ASTNode* param_declarator = param_type ? param_type->next : NULL;
                                if (param_declarator) {
                                    char* param_id = get_identifier_from_declarator(param_declarator);
                                    if (param_id) {
                                        // Check parameter redeclaration in function scope
                                        semantic_info* existing_param = find_in_scope(current_scope, param_id);
                                        if (existing_param) {
                                            printf("Semantic Error at line %d: Redeclaration of parameter '%s'\n", node->line_number, param_id);
                                        } else {
                                            bool param_is_ptr = false;
                                            int param_ptr_depth = 0;
                                            bool param_is_array = false;
                                            bool isparam = true;
                                            bool is_ref = false;
                                            int* param_array_sizes = NULL;
                                            int param_array_dimensions = 0;

                                            get_type_info_from_declarator(param_declarator, &param_is_ptr, &param_ptr_depth, &param_is_array, &is_ref, &param_array_sizes, &param_array_dimensions);

                                            // Set ALL LLVM fields in parameter AST node
                                            if (param->datatype) free(param->datatype);
                                            param->datatype = param_type->value ? strdup(param_type->value) : NULL;
                                            param->is_parameter = true;
                                            param->is_pointer = param_is_ptr;
                                            param->pointer_depth = param_ptr_depth;
                                            param->is_array = param_is_array;
                                            param->is_reference = is_ref;
                                            param->param_count = 0; // Parameters don't have parameters
                                            param->has_ellipsis = false;
                                            set_type_modifiers(param, param_type->value);

                                            if (param_array_sizes) {
                                                param->array_sizes = param_array_sizes;
                                                param->array_dimensions = param_array_dimensions;
                                            }

                                            // Set fields in parameter type node
                                            if (param_type->datatype) free(param_type->datatype);
                                            param_type->datatype = param_type->value ? strdup(param_type->value) : NULL;
                                            param_type->is_parameter = true;
                                            param_type->is_pointer = param_is_ptr;
                                            param_type->pointer_depth = param_ptr_depth;
                                            param_type->is_array = param_is_array;
                                            param_type->is_reference = is_ref;
                                            set_type_modifiers(param_type, param_type->value);

                                            // Also set in the declarator node itself
                                            if (param_declarator->datatype) free(param_declarator->datatype);
                                            param_declarator->datatype = param_type->value ? strdup(param_type->value) : NULL;
                                            param_declarator->is_parameter = true;
                                            param_declarator->is_pointer = param_is_ptr;
                                            param_declarator->pointer_depth = param_ptr_depth;
                                            param_declarator->is_array = param_is_array;
                                            param_declarator->is_reference = is_ref;
                                            set_type_modifiers(param_declarator, param_type->value);

                                            if (param_array_sizes) {
                                                param_declarator->array_sizes = (int*)malloc(param_array_dimensions * sizeof(int));
                                                memcpy(param_declarator->array_sizes, param_array_sizes, param_array_dimensions * sizeof(int));
                                                param_declarator->array_dimensions = param_array_dimensions;
                                            }

                                            // Create parameter semantic info for function scope
                                            semantic_info* param_info = create_semantic_info(
                                                param_type->value, param_id, false, param_is_ptr, isparam, is_ref,
                                                param_ptr_depth, param_is_array, 0, false
                                            );

                                            // Set extended fields in parameter semantic info
                                            param_info->array_dimensions = param_array_dimensions;
                                            if (param_array_sizes) {
                                                param_info->array_sizes = (int*)malloc(param_array_dimensions * sizeof(int));
                                                memcpy(param_info->array_sizes, param_array_sizes, param_array_dimensions * sizeof(int));
                                            }
                                            set_type_modifiers_semantic(param_info, param_type->value);

                                            // CORRECTED: Add parameter to function scope (for body analysis)
                                            if (!func_scope) {
                                                func_scope = param_info;
                                                last_func_param = param_info;
                                            } else {
                                                last_func_param->next = param_info;
                                                param_info->prev = last_func_param;
                                                last_func_param = param_info;
                                            }

                                            // CORRECTED: Create a separate copy for func_info->params (for function signature)
                                            semantic_info* param_info_for_func = create_semantic_info(
                                                param_type->value, param_id, false, param_is_ptr, isparam, is_ref,
                                                param_ptr_depth, param_is_array, 0, false
                                            );

                                            // Set extended fields in the copy
                                            param_info_for_func->array_dimensions = param_array_dimensions;
                                            if (param_array_sizes) {
                                                param_info_for_func->array_sizes = (int*) malloc(param_array_dimensions * sizeof(int));
                                                memcpy(param_info_for_func->array_sizes, param_array_sizes, param_array_dimensions * sizeof(int));
                                            }
                                            set_type_modifiers_semantic(param_info_for_func, param_type->value);

                                            // Add to func_info->params linked list
                                            if (!func_params_list) {
                                                func_params_list = param_info_for_func;
                                                last_func_param_info = param_info_for_func;
                                            } else {
                                                last_func_param_info->next = param_info_for_func;
                                                param_info_for_func->prev = last_func_param_info;
                                                last_func_param_info = param_info_for_func;
                                            }


                                        }
                                    } else {
                                        printf("Semantic Error at line %d: Parameter missing identifier in function '%s'\n", node->line_number, identifier);
                                    }
                                }
                            }
                            param = param->next;
                        }
                    }

                    // CORRECTED: Set the complete parameters list to func_info->params
                    func_info->params = func_params_list;

                    // Link function scope to the main scope chain
                    if (last_added) {
                        last_added->next = func_scope;
                    }
                    if (func_scope) {
                        func_scope->prev = last_added;
                    }

                    // Update last_added to the end of function scope
                    semantic_info* last_func_scope = func_scope;
                    while (last_func_scope && last_func_scope->next) {
                        last_func_scope = last_func_scope->next;
                    }
                    if (last_func_scope) {
                        last_added = last_func_scope;
                    }

                    // Check function body if it's a definition
                    if (node->type == NODE_FUNCTION_DEF) {
                        ASTNode* body = param_list ? param_list->next : declarator_node->next;
                        if (body && body->type == NODE_COMPOUND_STMT) {

                            check_semantics(body, parent_scope);
                        }
                    }
                }
            }

            if (scope_start_ptr && scope_start_ptr->next) {
                scope_start_ptr = scope_start_ptr->next;
            }
            break;
        }



case NODE_RETURN_STMT: {


    // Check if we're in a lambda context first
    bool in_lambda = false;
    ASTNode* parent = node; // In real implementation, you'd need parent pointers
    // For now, we'll detect by context - if we have expression but no function in scope

    // Find the current function or lambda in scope
    semantic_info* current_func = NULL;
    semantic_info* temp_scope = current_scope;

    // Traverse the scope chain to find the nearest enclosing function or lambda
    while (temp_scope) {
        if (temp_scope->isfunction) {
            current_func = temp_scope;
        }
        temp_scope = temp_scope->next;
    }

    if (!current_func) {
        // This might be in a lambda - use more lenient checking

        in_lambda = true;

        // For lambda, just check the expression and set type
        if (node->left) {
            check_semantics(node->left, parent_scope);

            if (node->left->datatype) {
                if (node->datatype) free(node->datatype);
                node->datatype = strdup(node->left->datatype);
                copy_llvm_fields(node, node->left);

            }
        } else {
            // return without expression in lambda
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("void");

        }
        break;
    }


            // Find the current function in scope by traversing up the scope chain




            // Check if return has an expression
            if (node->left) {
                // return with expression

                check_semantics(node->left, parent_scope);

                // Set return node's datatype and LLVM fields from the expression
                if (node->left->datatype) {
                    if (node->datatype) free(node->datatype);
                    node->datatype = strdup(node->left->datatype);
                    copy_llvm_fields(node, node->left);
                }

                // Check return type compatibility with function return type
                if (strcmp(current_func->type, "void") == 0) {
                    printf("Semantic Error at line %d: Void function '%s' should not return a value\n",
                           node->line_number, current_func->identifier);
                } else if (node->left->datatype) {
                    bool return_type_compatible = false;

                    // Handle special cases for type compatibility
                    if ((!node->left->is_pointer&&node->left->pointer_depth==0)&&(!current_func->ispointer&&current_func->pointerdepth==0)
                    && (!node->left->is_array&&node->left->array_dimensions==0)&&(!current_func->isarray&&current_func->array_dimensions==0)
                    && is_type_compatible(node->left->datatype, current_func->type)) {
                        return_type_compatible = true;
                    }

                    // Handle array decay to pointer for return types
                    else if (node->left->is_array && current_func->ispointer && node->left->array_dimensions==current_func->pointerdepth&&
                             is_type_compatible(node->left->datatype, current_func->type)) {
                        return_type_compatible = true;
                        printf("DEBUG: Array decay to pointer in return statement\n");
                    }

                    else if (((node->left->is_array && node->left->array_dimensions==0) || (node->left->is_pointer&&node->left->pointer_depth==0))&& (!current_func->ispointer||current_func->pointerdepth==0)
                            &&(!current_func->isarray||current_func->array_dimensions==0) &&is_type_compatible(node->left->datatype, current_func->type)) {
                        return_type_compatible = true;
                        printf("DEBUG: Array decay to pointer in return statement\n");
                    }

                    // Handle pointer compatibility
                    else if (node->left->is_pointer && current_func->ispointer) {
                        if (node->left->pointer_depth == current_func->pointerdepth &&
                            is_type_compatible(node->left->datatype, current_func->type)) {
                            return_type_compatible = true;
                        } else {
                            printf("Semantic Error at line %d: Return pointer type mismatch in function '%s'. Expected pointer depth %d, got %d\n",
                                   node->line_number, current_func->identifier, current_func->pointerdepth, node->left->pointer_depth);
                        }
                    }

                    if (!return_type_compatible) {
                        printf("Semantic Error at line %d: Return type mismatch in function '%s'. Expected '%s', got '%s'\n",
                               node->line_number, current_func->identifier, current_func->type, node->left->datatype);
                    }

                    // Additional checks for struct/class types
                    if (node->left->struct_name || current_func->struct_name) {
                        if (node->left->struct_name && current_func->struct_name) {
                            if (strcmp(node->left->struct_name, current_func->struct_name) != 0) {
                                printf("Semantic Error at line %d: Return struct type mismatch in function '%s'. Expected '%s', got '%s'\n",
                                       node->line_number, current_func->identifier, current_func->struct_name, node->left->struct_name);
                            }
                        } else if ((node->left->struct_name && !current_func->struct_name) ||
                                  (!node->left->struct_name && current_func->struct_name)) {
                            printf("Semantic Error at line %d: Return type struct/non-struct mismatch in function '%s'\n",
                                   node->line_number, current_func->identifier);
                        }
                    }

                    // Check for const correctness in return types
                    if (current_func->is_const && !node->left->is_const) {
                        printf("Warning at line %d: Returning non-const value from const function '%s'\n",
                               node->line_number, current_func->identifier);
                    }
                }
            } else {
                // return without expression


                // Set return node as void type
                if (node->datatype) free(node->datatype);
                node->datatype = strdup("void");
                node->is_pointer = false;
                node->pointer_depth = 0;
                node->is_array = false;
                node->array_dimensions = 0;
                if (node->array_sizes) {
                    free(node->array_sizes);
                    node->array_sizes = NULL;
                }
                node->is_reference = false;
                node->is_function = false;
                node->param_count = 0;
                node->has_ellipsis = false;
                node->size = 0;
                node->is_const = false;
                node->is_static = false;
                node->is_unsigned = false;

                // Check if non-void function returns without value
                if (strcmp(current_func->type, "void") != 0) {
                    printf("Semantic Error at line %d: Non-void function '%s' must return a value\n",
                           node->line_number, current_func->identifier);
                }
            }

            // Store return type information for control flow analysis
            node->is_function = true;
            node->param_count = 0;


            break;
        }

case NODE_VARIABLE_DECL: {
            ASTNode* type_node = node->child;
            ASTNode* declarator_node = type_node ? type_node->next : NULL;
            ASTNode* assignment_node = NULL;

            // Handle assignment case
            if (declarator_node && declarator_node->type == NODE_ASSIGNMENT) {
                assignment_node = declarator_node;
                declarator_node = declarator_node->left;
            }

            if (type_node && declarator_node) {
                char* identifier = get_identifier_from_declarator(declarator_node);
                if (identifier) {
                    printf("got the identifier '%s' \n", identifier);
                    // Check for redeclaration in current scope
                    semantic_info* existing = find_in_scope(current_scope, identifier);
                    if (existing) {
                        printf("Semantic Error at line %d: Redeclaration of '%s'\n", node->line_number, identifier);
                        free(identifier);
                        return;
                    }

                    bool is_pointer = false;
                    int pointer_depth = 0;
                    bool is_array = false;
                    bool is_ref = false;
                    int* array_sizes = NULL;
                    int array_dimensions = 0;
                    bool is_function = false;
                    int param_count = 0;

                    // Extract array dimension and size information from declarator
                    get_type_info_from_declarator(declarator_node, &is_pointer, &pointer_depth, &is_array, &is_ref, &array_sizes, &array_dimensions);

                    // Process initializer expression if present (BEFORE setting AST fields)
                    ASTNode* init_expr = NULL;
                    if (assignment_node) {
                        init_expr = assignment_node->right;
                        check_semantics(init_expr, parent_scope);
                    }

                    // NEW: Handle static type modifiers from composite types
                    bool is_static_type = false;
                    bool is_const_type = false;
                    bool is_unsigned_type = false;
                    
                    // Check for composite type modifiers in type_node
                    if (type_node->value) {
                        is_static_type = (strstr(type_node->value, "static") != NULL);
                        is_const_type = (strstr(type_node->value, "const") != NULL);
                        is_unsigned_type = (strstr(type_node->value, "unsigned") != NULL);
                    }

                    // Handle auto type inference
                    bool is_auto_type = (type_node->value && strcmp(type_node->value, "auto") == 0);

                    if (is_auto_type && init_expr) {
                        // AUTO TYPE: Infer type from initializer expression

                        // SPECIAL CASE: If initializer is a lambda, treat as function
                        if (init_expr->type == NODE_LAMBDA_EXPR) {
                            // Set type to function pointer with lambda's signature
                            if (type_node->value) free(type_node->value);
                            type_node->value = strdup(init_expr->datatype);

                            // Mark as function
                            is_function = true;
                            is_pointer = true;
                            pointer_depth = 1;
                            param_count = init_expr->param_count;
                        } else {
                            // Regular auto type inference for non-lambda expressions
                            if (type_node->value) free(type_node->value);
                            type_node->value = init_expr->datatype ? strdup(init_expr->datatype) : NULL;
                        }

                        // For arrays with init lists, infer array properties
                        if (init_expr->type == NODE_INIT_LIST && init_expr->is_array) {
                            is_array = true;
                            array_dimensions = init_expr->array_dimensions;
                            if (init_expr->array_sizes && array_dimensions > 0) {
                                array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                                memcpy(array_sizes, init_expr->array_sizes, array_dimensions * sizeof(int));
                            }
                        }
                    } else if (init_expr) {
                        // REGULAR TYPE: Check type compatibility

                        // Handle array decay to pointer compatibility
                        bool types_compatible = false;
                        if (is_array && init_expr->is_pointer && (array_dimensions == init_expr->pointer_depth) &&
                            is_type_compatible(type_node->value, init_expr->datatype)) {
                            // Array can decay to pointer - check if base types are compatible
                            types_compatible = true;
                        }
                        else if (is_pointer && init_expr->is_pointer && (pointer_depth == init_expr->pointer_depth) &&
                            is_type_compatible(type_node->value, init_expr->datatype)) {
                            types_compatible = true;
                        }
                        else if (is_pointer && init_expr->is_array && (pointer_depth == init_expr->array_dimensions) &&
                            is_type_compatible(type_node->value, init_expr->datatype)) {
                            types_compatible = true;
                        }
                        else {
                            // Regular type compatibility check
                            types_compatible = is_type_compatible(type_node->value, init_expr->datatype);
                        }

                        if (!types_compatible) {
                            printf("Semantic Error at line %d: Type mismatch for '%s'. Declaration type '%s' is incompatible with initializer type '%s'\n",
                                   node->line_number, identifier, type_node->value, init_expr->datatype);
                        }

                        // Handle array initialization with init list - COMPREHENSIVE VALIDATION
                        if (is_array && init_expr->type == NODE_INIT_LIST) {
                            // Check if array dimensions match
                            if (array_dimensions != init_expr->init_list_dimentions) {
                                printf("Semantic Error at line %d: Array dimension mismatch for '%s'. Declaration has %d dimensions, initializer has %d dimensions\n",
                                       node->line_number, identifier, array_dimensions, init_expr->init_list_dimentions);
                            } else {
                                // COMPREHENSIVE DIMENSION VALIDATION
                                bool validation_passed = validate_init_list_dimensions(init_expr, array_sizes, array_dimensions, 0, identifier, node->line_number);

                                if (!validation_passed) {
                                    printf("Semantic Error at line %d: Initializer list structure does not match array declaration for '%s'\n",
                                           node->line_number, identifier);
                                }
                            }
                        }
                        
                        if (init_expr->type != NODE_INIT_LIST) {
                            if (is_array && array_dimensions > 0 && (!init_expr->is_array || init_expr->array_dimensions == 0) && (!init_expr->is_pointer || init_expr->pointer_depth == 0)) {
                                printf("Semantic Error: invalid assignment to pointer '%s'\n", identifier);
                            }
                            else if (is_pointer && pointer_depth > 0 && (!init_expr->is_array || init_expr->array_dimensions == 0) && (!init_expr->is_pointer || init_expr->pointer_depth == 0)) {
                                printf("Semantic Error: invalid assignment to pointer '%s'\n", identifier);
                            }
                            else if (init_expr->is_array && init_expr->array_dimensions > 0 && (!is_array || array_dimensions == 0) && (!is_pointer || pointer_depth == 0)) {
                                printf("Semantic Error: invalid assignment of pointer '%s'\n", identifier);
                            }
                            else if (init_expr->is_pointer && init_expr->pointer_depth > 0 && (!is_array || array_dimensions == 0) && (!is_pointer || pointer_depth == 0)) {
                                printf("Semantic Error: invalid assignment of pointer '%s'\n", identifier);
                            }
                        }
                    }

                    // NOW SET ALL AST FIELDS AFTER ANALYSIS

                    // Set fields in main variable declaration node
                    if (node->datatype) free(node->datatype);
                    node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                    node->is_pointer = is_pointer;
                    node->pointer_depth = pointer_depth;
                    node->is_array = is_array;
                    node->is_reference = is_ref;
                    node->array_dimensions = array_dimensions;
                    if (array_sizes) {
                        node->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                        memcpy(node->array_sizes, array_sizes, array_dimensions * sizeof(int));
                    }
                    
                    // NEW: Set static/const/unsigned modifiers from composite types
                    node->is_static = is_static_type;
                    node->is_const = is_const_type;
                    node->is_unsigned = is_unsigned_type;
                    
                    set_type_modifiers(node, type_node->value);

                    // Set fields in type node
                    if (type_node->datatype) free(type_node->datatype);
                    type_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                    type_node->is_pointer = is_pointer;
                    type_node->pointer_depth = pointer_depth;
                    type_node->is_array = is_array;
                    type_node->is_reference = is_ref;
                    type_node->array_dimensions = array_dimensions;
                    if (array_sizes) {
                        type_node->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                        memcpy(type_node->array_sizes, array_sizes, array_dimensions * sizeof(int));
                    }
                    set_type_modifiers(type_node, type_node->value);

                    // Set fields in declarator node
                    if (declarator_node->datatype) free(declarator_node->datatype);
                    declarator_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                    declarator_node->is_pointer = is_pointer;
                    declarator_node->pointer_depth = pointer_depth;
                    declarator_node->is_array = is_array;
                    declarator_node->is_reference = is_ref;
                    declarator_node->array_dimensions = array_dimensions;
                    if (array_sizes) {
                        declarator_node->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                        memcpy(declarator_node->array_sizes, array_sizes, array_dimensions * sizeof(int));
                    }
                    set_type_modifiers(declarator_node, type_node->value);

                    ASTNode* identifier_node = declarator_node;
                    while (identifier_node) {
                        if (identifier_node->type == NODE_IDENTIFIER) break;
                        identifier_node = identifier_node->child;
                        if (identifier_node && identifier_node->type != NODE_IDENTIFIER && array_sizes && array_dimensions > 1) {
                            if (identifier_node->datatype) free(identifier_node->datatype);
                            identifier_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                            identifier_node->is_pointer = is_pointer;
                            identifier_node->pointer_depth = pointer_depth;
                            identifier_node->is_array = is_array;
                            identifier_node->is_reference = is_ref;
                            identifier_node->array_dimensions = array_dimensions;
                            if (array_sizes) {
                                identifier_node->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                                memcpy(identifier_node->array_sizes, array_sizes, array_dimensions * sizeof(int));
                            }
                            set_type_modifiers(identifier_node, type_node->value);
                        }
                    }

                    if (identifier_node && identifier_node->type == NODE_IDENTIFIER) {
                        if (identifier_node->datatype) free(identifier_node->datatype);
                        identifier_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                        identifier_node->is_pointer = is_pointer;
                        identifier_node->pointer_depth = pointer_depth;
                        identifier_node->is_array = is_array;
                        identifier_node->is_reference = is_ref;
                        identifier_node->array_dimensions = array_dimensions;
                        if (array_sizes) {
                            identifier_node->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                            memcpy(identifier_node->array_sizes, array_sizes, array_dimensions * sizeof(int));
                        }
                        set_type_modifiers(identifier_node, type_node->value);
                    }

                    // Set fields in assignment node if present
                    if (assignment_node) {
                        if (assignment_node->datatype) free(assignment_node->datatype);
                        assignment_node->datatype = type_node->value ? strdup(type_node->value) : NULL;
                        assignment_node->is_pointer = is_pointer;
                        assignment_node->pointer_depth = pointer_depth;
                        assignment_node->is_array = is_array;
                        assignment_node->is_reference = is_ref;
                        assignment_node->array_dimensions = array_dimensions;
                        if (array_sizes) {
                            assignment_node->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                            memcpy(assignment_node->array_sizes, array_sizes, array_dimensions * sizeof(int));
                        }
                        set_type_modifiers(assignment_node, type_node->value);
                    }

                    // Create variable info and add to current scope
                    semantic_info* var_info = create_semantic_info(
                        type_node->value, identifier, false, is_pointer, false, is_ref,
                        pointer_depth, is_array, 0, false
                    );

                    // NEW: Set static/const/unsigned modifiers in semantic info
                    var_info->is_static = is_static_type;
                    var_info->is_const = is_const_type;
                    var_info->is_unsigned = is_unsigned_type;

                    // Set extended fields in semantic info for LLVM
                    var_info->array_dimensions = array_dimensions;
                    if (array_sizes) {
                        var_info->array_sizes = (int*)malloc(array_dimensions * sizeof(int));
                        memcpy(var_info->array_sizes, array_sizes, array_dimensions * sizeof(int));
                    }
                    set_type_modifiers_semantic(var_info, type_node->value);

                    // Add to scope
                    if (!current_scope) {
                        current_scope = var_info;
                        *parent_scope = current_scope;
                    } else {
                        semantic_info* last = current_scope;
                        while (last->next) last = last->next;
                        last->next = var_info;
                        var_info->prev = last;
                    }
                    scope_start_ptr = var_info;

                    free(identifier);
                }
            }
            break;
}

case NODE_LAMBDA_EXPR: {


    // Step 1: Validate capture list variables exist in current scope
    lambda_capture_info* capture_list = NULL;
    ASTNode* capture_spec = NULL;
    ASTNode* params = NULL;
    ASTNode* ret_type = NULL;
    ASTNode* body = NULL;

    // Parse lambda components
    ASTNode* current = node->child;
    while (current) {
        switch (current->type) {
            case NODE_LAMBDA_CAPTURE: capture_spec = current; break;
            case NODE_LAMBDA_PARAMS: params = current; break;
            case NODE_LAMBDA_RET: ret_type = current; break;
            case NODE_COMPOUND_STMT: body = current; break;
            default: break;
        }
        current = current->next;
    }

    // Validate capture variables exist in current scope
    if (capture_spec) {
        capture_list = process_lambda_capture(capture_spec, current_scope);
        validate_captured_variables(capture_list, current_scope, node->line_number);

    }

    // Step 2: Create function-like scope for lambda
    // Add lambda as a function to current scope FIRST
    char lambda_name[64];
    snprintf(lambda_name, sizeof(lambda_name), "lambda_%d", node->line_number);

    // Create semantic info for the lambda function itself
    semantic_info* lambda_func_info = create_semantic_info(
        "auto", lambda_name, true, true, false, false, 1, false, 0, false
    );

    // Add lambda function to current scope
    if (!current_scope) {
        current_scope = lambda_func_info;
        *parent_scope = current_scope;
    } else {
        semantic_info* last = current_scope;
        while (last->next) last = last->next;
        last->next = lambda_func_info;
        lambda_func_info->prev = last;
    }


    // Step 3: Process parameters and add them to a NEW scope for lambda body
    semantic_info* lambda_body_scope = NULL;
    int param_count = 0;
    semantic_info* lambda_params_list = NULL;

    if (params && params->child && params->child->type == NODE_PARAM_LIST) {
        ASTNode* param_list = params->child;
        ASTNode* param = param_list->child;

        while (param) {
            if (param->type == NODE_VARIABLE_DECL) {
                param_count++;

                ASTNode* param_type = param->child;
                ASTNode* param_declarator = param_type ? param_type->next : NULL;

                if (param_type && param_declarator) {
                    char* param_name = get_identifier_from_declarator(param_declarator);
                    if (param_name) {
                        // Extract parameter type information
                        bool is_pointer = false;
                        int pointer_depth = 0;
                        bool is_array = false;
                        bool is_ref = false;
                        int* array_sizes = NULL;
                        int array_dimensions = 0;

                        get_type_info_from_declarator(param_declarator, &is_pointer, &pointer_depth,
                                                     &is_array, &is_ref, &array_sizes, &array_dimensions);

                        // Set LLVM fields in parameter AST nodes
                        if (param->datatype) free(param->datatype);
                        param->datatype = param_type->value ? strdup(param_type->value) : NULL;
                        param->is_parameter = true;
                        param->is_pointer = is_pointer;
                        param->pointer_depth = pointer_depth;
                        param->is_array = is_array;
                        param->is_reference = is_ref;
                        set_type_modifiers(param, param_type->value);

                        // Create parameter semantic info for lambda body scope
                        semantic_info* param_info = create_semantic_info(
                            param_type->value, param_name, false, is_pointer, true, is_ref,
                            pointer_depth, is_array, 0, false
                        );

                        // Add parameter to lambda body scope
                        if (!lambda_body_scope) {
                            lambda_body_scope = param_info;
                        } else {
                            semantic_info* last_param = lambda_body_scope;
                            while (last_param->next) last_param = last_param->next;
                            last_param->next = param_info;
                            param_info->prev = last_param;
                        }

                        // Also store in parameters list for function signature
                        semantic_info* param_sig = create_semantic_info(
                            param_type->value, param_name, false, is_pointer, true, is_ref,
                            pointer_depth, is_array, 0, false
                        );

                        if (!lambda_params_list) {
                            lambda_params_list = param_sig;
                        } else {
                            semantic_info* last_sig = lambda_params_list;
                            while (last_sig->next) last_sig = last_sig->next;
                            last_sig->next = param_sig;
                        }
                        free(param_name);
                    }
                }
            }
            param = param->next;
        }
    }

    // Step 4: Add captured variables to lambda body scope
    if (capture_list) {
        lambda_capture_info* current_capture = capture_list;
        while (current_capture) {
            if (current_capture->identifier && !current_capture->is_implicit) {
                semantic_info* outer_var = find_in_scope(current_scope, current_capture->identifier);
                if (outer_var) {
                    semantic_info* captured_var = create_semantic_info(
                        outer_var->type, outer_var->identifier,
                        outer_var->isfunction, outer_var->ispointer,
                        false, current_capture->by_reference,
                        outer_var->pointerdepth, outer_var->isarray, 0, false
                    );

                    // Add to lambda body scope
                    if (!lambda_body_scope) {
                        lambda_body_scope = captured_var;
                    } else {
                        semantic_info* last = lambda_body_scope;
                        while (last->next) last = last->next;
                        last->next = captured_var;
                        captured_var->prev = last;
                    }

                }
            }
            current_capture = current_capture->next;
        }
    }

    // Step 5: Process return type
    char* return_type = "void"; // Default
    if (ret_type && ret_type->child && ret_type->child->type == NODE_TYPE) {
        return_type = ret_type->child->value;

    }

    // Step 6: Process lambda body with the combined scope (parameters + captured vars)
    if (body && lambda_body_scope) {


        // Store the current scope to restore later
        semantic_info* old_scope = *parent_scope;

        // Set the lambda body scope for processing
        *parent_scope = lambda_body_scope;

        // Process the body
        check_semantics(body, parent_scope);

        // Infer return type from body if not explicitly specified
        if ((!ret_type || !ret_type->child) && body) {
            char* inferred_type = infer_lambda_return_type(body);
            if (inferred_type) {
                return_type = inferred_type;
                printf("DEBUG: Inferred lambda return type: '%s'\n", return_type);
            }
        }

        // Restore original scope
        *parent_scope = old_scope;
    }

    // Step 7: Set lambda node properties
    node->is_function = true;
    node->is_pointer = true;
    node->pointer_depth = 1;
    node->param_count = param_count;
    node->has_ellipsis = false;

    if (node->datatype) free(node->datatype);
    node->datatype = strdup(return_type);
    set_type_modifiers(node, return_type);

    // Store parameters in lambda function info for variable declaration processing
    lambda_func_info->params = lambda_params_list;
    lambda_func_info->param_count = param_count;
    lambda_func_info->type = strdup(return_type);

    // Store capture information
    if (capture_list) {
        char capture_info[256];
        int capture_count = 0;
        lambda_capture_info* temp = capture_list;
        while (temp) {
            if (temp->identifier) capture_count++;
            temp = temp->next;
        }

        if (capture_list->is_implicit) {
            snprintf(capture_info, sizeof(capture_info), "lambda_%s_capture",
                    capture_list->by_reference ? "ref" : "val");
        } else {
            snprintf(capture_info, sizeof(capture_info), "lambda_explicit_capture_%d", capture_count);
        }

        if (node->value) free(node->value);
        node->value = strdup(capture_info);
    }



    // Cleanup
    free_lambda_capture_info(capture_list);
    break;
}

case NODE_CALL: {
    printf("DEBUG: Processing function call\n");

    ASTNode* function_node = node->child;
    ASTNode* args_node = function_node ? function_node->next : NULL;

    if (!function_node) {
        printf("Semantic Error at line %d: Function call missing function expression\n", node->line_number);
        break;
    }

    // First, recursively check the function expression and arguments
    check_semantics(function_node, parent_scope);


    if (function_node->type == NODE_IDENTIFIER && function_node->value) {
        printf("DEBUG: Looking up function '%s' in scope\n", function_node->value);
        semantic_info* func_info = find_in_scope(current_scope, function_node->value);

        if (!func_info) {
            printf("Semantic Error at line %d: Call to undeclared function '%s'\n", node->line_number, function_node->value);
            // Set default type to avoid cascading errors
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("int");
            break;
        } else if (!func_info->isfunction) {
            printf("Semantic Error at line %d: '%s' is not a function\n", node->line_number, function_node->value);
            // Set default type to avoid cascading errors
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("int");
            break;
        } else {


            // Set LLVM fields for call node
            node->is_function = false; // Call result is not a function
            node->param_count = func_info->param_count;
            node->has_ellipsis = func_info->has_ellipsis;

            // Set return type and LLVM fields from function info
            if (node->datatype) free(node->datatype);
            node->datatype = func_info->type ? strdup(func_info->type) : strdup("int");
            node->is_pointer = func_info->ispointer;
            node->pointer_depth = func_info->pointerdepth;
            node->is_array = func_info->isarray;
            node->is_reference = func_info->isref;
            node->size = func_info->size;
            node->is_const = func_info->is_const;
            node->is_static = func_info->is_static;
            node->is_unsigned = func_info->is_unsigned;
            if (func_info->struct_name) {
                if (node->struct_name) free(node->struct_name);
                node->struct_name = strdup(func_info->struct_name);
            }

            // Check argument count and types
            int provided_args = 0;
            ASTNode* arg = args_node ? args_node->child : NULL;
            semantic_info* param_info = func_info->params;

            printf("DEBUG: Function expects %d parameters, has_ellipsis: %d\n",
                   func_info->param_count, func_info->has_ellipsis);

            // Check each argument against corresponding parameter
            while (arg && param_info) {
                provided_args++;


                if (arg->datatype) {
                    printf("type '%s'", arg->datatype);
                } else {
                    printf("undefined type");
                }

                if (param_info->type) {
                    printf(" against parameter type '%s'\n", param_info->type);
                } else {
                    printf(" against undefined parameter type\n");
                }

                // Check argument type compatibility with parameter
                if (arg->datatype && param_info->type) {
                    bool type_error = false;

                    // 1. Check basic type compatibility
                    if (!is_type_compatible(arg->datatype, param_info->type)) {
                        printf("Semantic Error at line %d: Argument %d type mismatch - expected '%s', got '%s'\n",
                               node->line_number, provided_args, param_info->type, arg->datatype);
                        type_error = true;
                    }

                    // 2. Handle array-to-pointer decay (special case)
                    bool array_to_pointer_decay = false;
                    if (arg->is_array && param_info->ispointer &&
                        !param_info->isarray &&
                        is_type_compatible(arg->datatype, param_info->type)) {
                        // Array decays to pointer - this is allowed in C/C++
                        array_to_pointer_decay = true;

                    }

                    // 3. Check pointer/array compatibility (with array decay consideration)
                    if (!array_to_pointer_decay) {
                        if (arg->is_pointer != param_info->ispointer) {
                            printf("Semantic Error at line %d: Argument %d pointer mismatch - expected %s, got %s\n",
                                   node->line_number, provided_args,
                                   param_info->ispointer ? "pointer" : "non-pointer",
                                   arg->is_pointer ? "pointer" : "non-pointer");
                            type_error = true;
                        } else if (arg->is_pointer && param_info->ispointer) {
                            if (arg->pointer_depth != param_info->pointerdepth) {
                                printf("Semantic Error at line %d: Argument %d pointer depth mismatch - expected %d, got %d\n",
                                       node->line_number, provided_args, param_info->pointerdepth, arg->pointer_depth);
                                type_error = true;
                            }
                        }

                        // 4. Check array compatibility (excluding array-to-pointer decay case)
                        if (arg->is_array != param_info->isarray) {
                            printf("Semantic Error at line %d: Argument %d array mismatch - expected %s, got %s\n",
                                   node->line_number, provided_args,
                                   param_info->isarray ? "array" : "non-array",
                                   arg->is_array ? "array" : "non-array");
                            type_error = true;
                        } else if (arg->is_array && param_info->isarray) {
                            if (arg->array_dimensions != param_info->array_dimensions) {
                                printf("Semantic Error at line %d: Argument %d array dimension mismatch - expected %d, got %d\n",
                                       node->line_number, provided_args, param_info->array_dimensions, arg->array_dimensions);
                                type_error = true;
                            }
                        }
                    }

                    // 5. Special case: boolean arguments
                    if (strcmp(arg->datatype, "bool") == 0 || strcmp(param_info->type, "bool") == 0) {

                        // Boolean can be passed to integer types and vice versa
                        if (!is_type_compatible(arg->datatype, param_info->type)) {
                            printf("Semantic Error at line %d: Argument %d boolean compatibility issue - expected '%s', got '%s'\n",
                                   node->line_number, provided_args, param_info->type, arg->datatype);
                            type_error = true;
                        }
                    }

                    // 6. Check struct type compatibility
                    if ((arg->struct_name != NULL) != (param_info->struct_name != NULL)) {
                        printf("Semantic Error at line %d: Argument %d struct mismatch - expected %s, got %s\n",
                               node->line_number, provided_args,
                               param_info->struct_name ? "struct" : "non-struct",
                               arg->struct_name ? "struct" : "non-struct");
                        type_error = true;
                    } else if (arg->struct_name && param_info->struct_name) {
                        if (strcmp(arg->struct_name, param_info->struct_name) != 0) {
                            printf("Semantic Error at line %d: Argument %d struct type mismatch - expected '%s', got '%s'\n",
                                   node->line_number, provided_args, param_info->struct_name, arg->struct_name);
                            type_error = true;
                        }
                    }

                } else {
                    if (!arg->datatype) {
                        printf("Semantic Error at line %d: Argument %d has undefined type\n",
                               node->line_number, provided_args);
                    }
                    if (!param_info->type) {
                        printf("Semantic Error at line %d: Parameter %d has undefined type\n",
                               node->line_number, provided_args);
                    }
                }

                arg = arg->next;
                param_info = param_info->next;
            }

            // Check for extra arguments if function has ellipsis
            while (arg) {
                provided_args++;

                arg = arg->next;
            }

            // Count total provided arguments
            int total_provided = 0;
            arg = args_node ? args_node->child : NULL;
            while (arg) {
                total_provided++;
                arg = arg->next;
            }

            printf("DEBUG: Total arguments provided: %d, expected: %d, has_ellipsis: %d\n",
                   total_provided, func_info->param_count, func_info->has_ellipsis);

            if (func_info->has_ellipsis) {
                if (total_provided < func_info->param_count) {
                    printf("Semantic Error at line %d: Function '%s' requires at least %d arguments, but %d provided\n",
                           node->line_number, function_node->value, func_info->param_count, total_provided);
                }
            } else {
                if (total_provided != func_info->param_count) {
                    printf("Semantic Error at line %d: Function '%s' expects %d arguments, but %d provided\n",
                           node->line_number, function_node->value, func_info->param_count, total_provided);
                }
            }

        }
    } else {
        // Handle complex function expressions (function pointers, etc.)


        // For complex function expressions, we can't do full type checking
        // but we can set basic LLVM fields from the function expression
        if (function_node && function_node->datatype) {
            if (node->datatype) free(node->datatype);
            node->datatype = strdup(function_node->datatype);
            copy_llvm_fields(node, function_node);
        } else {
            // Set default type for unknown function calls
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("int");
        }
    }
    break;
}

case NODE_BINARY_OP: {
    check_semantics(node->left, parent_scope);
    check_semantics(node->right, parent_scope);

    if (node->left && node->right && node->left->datatype && node->right->datatype) {
        // Free existing datatype if it exists
        if (node->datatype) free(node->datatype);

        // Handle comma operator separately (special case)
        if (node->op && strcmp(node->op, ",") == 0) {
            node->datatype = strdup(node->right->datatype);
            copy_llvm_fields(node, node->right);
            // NEW: Copy type modifiers for comma operator
            node->is_const = node->right->is_const;
            node->is_static = node->right->is_static;
            node->is_unsigned = node->right->is_unsigned;
            break; // Comma operator has different rules
        }

        // Check type compatibility based on operator
        bool types_compatible = is_type_compatible(node->left->datatype, node->right->datatype);
        printf("DEBUG: left type '%s', right type '%s' is compatible %d\n",
               node->left->datatype, node->right->datatype, (types_compatible == true ? 1 : 0));
        
        // Get operator for easier comparison
        char* op = node->op;

        // NEW: Enhanced type modifier handling
        bool left_is_unsigned = node->left->is_unsigned;
        bool right_is_unsigned = node->right->is_unsigned;
        bool left_is_const = node->left->is_const;
        bool right_is_const = node->right->is_const;

        // Arithmetic operators: +, -, *, /, %
        if (op && (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 ||
                   strcmp(op, "*") == 0 || strcmp(op, "/") == 0 || strcmp(op, "%") == 0)) {

            // Check if types support arithmetic operations
            if (!types_compatible) {
                printf("Semantic Error at line %d: Arithmetic operation '%s' between incompatible types '%s' and '%s'\n",
                       node->line_number, op, node->left->datatype, node->right->datatype);
            }

            // NEW: Enhanced pointer arithmetic with array decay support
            bool left_is_ptr_like = (node->left->is_pointer && node->left->pointer_depth > 0) || 
                                   (node->left->is_array && node->left->array_dimensions > 0);
            bool right_is_ptr_like = (node->right->is_pointer && node->right->pointer_depth > 0) || 
                                    (node->right->is_array && node->right->array_dimensions > 0);

            // Handle pointer arithmetic cases
            if (left_is_ptr_like || right_is_ptr_like) {
                if (strcmp(op, "%") == 0) {
                    printf("Semantic Error at line %d: Modulo operator '%%' not allowed with pointers/arrays\n",
                           node->line_number);
                }
                if (strcmp(op, "*") == 0 || strcmp(op, "/") == 0) {
                    printf("Semantic Error at line %d: Arithmetic operation '%s' not allowed between pointers/arrays\n",
                           node->line_number, op);
                }
                
                // Pointer addition/subtraction rules
                if (strcmp(op, "+") == 0 || strcmp(op, "-") == 0) {
                    // Only allow: pointer ± integer or integer ± pointer
                    bool valid_ptr_arithmetic = false;
                    
                    if (left_is_ptr_like && !right_is_ptr_like) {
                        // pointer + integer or pointer - integer
                        if (strcmp(node->right->datatype, "int") == 0 || 
                            strcmp(node->right->datatype, "long") == 0) {
                            valid_ptr_arithmetic = true;
                            // Result is pointer type
                            node->datatype = strdup(node->left->datatype);
                            copy_llvm_fields(node, node->left);
                            printf("DEBUG: Pointer arithmetic: %s %s integer\n", 
                                   node->left->datatype, op);
                        }
                    } else if (!left_is_ptr_like && right_is_ptr_like && strcmp(op, "+") == 0) {
                        // integer + pointer
                        if (strcmp(node->left->datatype, "int") == 0 || 
                            strcmp(node->left->datatype, "long") == 0) {
                            valid_ptr_arithmetic = true;
                            // Result is pointer type
                            node->datatype = strdup(node->right->datatype);
                            copy_llvm_fields(node, node->right);
                            printf("DEBUG: Pointer arithmetic: integer %s %s\n", 
                                   op, node->right->datatype);
                        }
                    } else if (left_is_ptr_like && right_is_ptr_like && strcmp(op, "-") == 0) {
                        // pointer - pointer (yields integer)
                        if (node->left->pointer_depth == node->right->pointer_depth &&
                            is_type_compatible(node->left->datatype, node->right->datatype)) {
                            valid_ptr_arithmetic = true;
                            // Result is integer (ptrdiff_t)
                            node->datatype = strdup("long");
                            node->is_pointer = false;
                            node->pointer_depth = 0;
                            node->is_array = false;
                            node->array_dimensions = 0;
                            node->size = 8;
                            printf("DEBUG: Pointer subtraction yields integer\n");
                        }
                    }
                    
                    if (!valid_ptr_arithmetic) {
                        printf("Semantic Error at line %d: Invalid pointer arithmetic with '%s'\n",
                               node->line_number, op);
                    } else {
                        break; // Skip normal type promotion for pointer arithmetic
                    }
                }
            }

            // String concatenation check for +
            if (strcmp(op, "+") == 0 &&
                (strcmp(node->left->datatype, "string") == 0 || strcmp(node->right->datatype, "string") == 0)) {
                // String concatenation is allowed
                node->datatype = strdup("string");
                node->is_pointer = true;
                node->pointer_depth = 1;
                node->size = 8; // Platform-dependent, typically pointer size
                // NEW: Set type modifiers for string result
                node->is_const = false;
                node->is_static = false;
                node->is_unsigned = false;
                break;
            }

            // NEW: Enhanced type promotion considering unsigned types and modifiers
            int prec1 = precedence(node->left->datatype);
            int prec2 = precedence(node->right->datatype);

            // Type promotion rules considering unsigned types
            if (prec1 == prec2) {
                // Same precedence - prefer unsigned type
                if (left_is_unsigned && !right_is_unsigned) {
                    node->datatype = strdup(node->left->datatype);
                    copy_llvm_fields(node, node->left);
                } else if (!left_is_unsigned && right_is_unsigned) {
                    node->datatype = strdup(node->right->datatype);
                    copy_llvm_fields(node, node->right);
                } else if (prec1 >= prec2) {
                    node->datatype = strdup(node->left->datatype);
                    copy_llvm_fields(node, node->left);
                } else {
                    node->datatype = strdup(node->right->datatype);
                    copy_llvm_fields(node, node->right);
                }
            } else if (prec1 >= prec2) {
                node->datatype = strdup(node->left->datatype);
                copy_llvm_fields(node, node->left);
            } else {
                node->datatype = strdup(node->right->datatype);
                copy_llvm_fields(node, node->right);
            }
            
            // NEW: Set unsigned flag if either operand is unsigned
            node->is_unsigned = left_is_unsigned || right_is_unsigned;
            // Const doesn't propagate to arithmetic results
            node->is_const = false;
            node->is_static = false;
        }

        // Comparison operators: ==, !=, <, >, <=, >=
        else if (op && (strcmp(op, "==") == 0 || strcmp(op, "!=") == 0 ||
                        strcmp(op, "<") == 0 || strcmp(op, ">") == 0 ||
                        strcmp(op, "<=") == 0 || strcmp(op, ">=") == 0)) {

            if (!types_compatible) {
                printf("Semantic Error at line %d: Comparison '%s' between incompatible types '%s' and '%s'\n",
                       node->line_number, op, node->left->datatype, node->right->datatype);
            }

            // NEW: Enhanced pointer/array comparison rules
            bool left_is_ptr_like = (node->left->is_pointer && node->left->pointer_depth > 0) || 
                                   (node->left->is_array && node->left->array_dimensions > 0);
            bool right_is_ptr_like = (node->right->is_pointer && node->right->pointer_depth > 0) || 
                                    (node->right->is_array && node->right->array_dimensions > 0);

            if (left_is_ptr_like && right_is_ptr_like) {
                // Pointer/array comparison
                if (node->left->pointer_depth != node->right->pointer_depth) {
                    printf("Semantic Error at line %d: Cannot compare pointers/arrays of different depths (%d vs %d)\n",
                           node->line_number, node->left->pointer_depth, node->right->pointer_depth);
                }
                // Check base type compatibility for pointers
                if (!is_type_compatible(node->left->datatype, node->right->datatype)) {
                    printf("Warning at line %d: Comparing pointers with incompatible base types '%s' and '%s'\n",
                           node->line_number, node->left->datatype, node->right->datatype);
                }
            } else if (left_is_ptr_like != right_is_ptr_like) {
                // Mixed pointer/non-pointer comparison
                printf("Warning at line %d: Comparing pointer with non-pointer type\n",
                       node->line_number);
            }

            // NEW: Struct comparison enhancement
            if (node->left->struct_name || node->right->struct_name) {
                if (node->left->struct_name && node->right->struct_name) {
                    if (strcmp(node->left->struct_name, node->right->struct_name) != 0) {
                        printf("Semantic Error at line %d: Cannot compare different struct types '%s' and '%s'\n",
                               node->line_number, node->left->struct_name, node->right->struct_name);
                    }
                } else if ((node->left->struct_name && !node->right->struct_name) ||
                          (!node->left->struct_name && node->right->struct_name)) {
                    printf("Semantic Error at line %d: Cannot compare struct with non-struct type\n",
                           node->line_number);
                }
            }

            // Result of comparison is always boolean
            node->datatype = strdup("bool");
            node->is_pointer = false;
            node->pointer_depth = 0;
            node->size = 1;
            node->is_array = false;
            node->array_dimensions = 0;
            node->is_const = false;
            node->is_static = false;
            node->is_unsigned = false;
            if (node->array_sizes) {
                free(node->array_sizes);
                node->array_sizes = NULL;
            }
        }

        // Logical operators: &&, ||
        else if (op && (strcmp(op, "&&") == 0 || strcmp(op, "||") == 0)) {
            // Check if types can be used in logical context
            if (strcmp(node->left->datatype, "bool") != 0) {
                printf("Warning at line %d: Left operand of '%s' is not boolean (type: %s)\n",
                       node->line_number, op, node->left->datatype);
            }
            if (strcmp(node->right->datatype, "bool") != 0) {
                printf("Warning at line %d: Right operand of '%s' is not boolean (type: %s)\n",
                       node->line_number, op, node->right->datatype);
            }

            // NEW: Check for null pointer in logical context
            if ((node->left->is_pointer && node->left->pointer_depth > 0) ||
                (node->right->is_pointer && node->right->pointer_depth > 0)) {
                printf("Warning at line %d: Pointer used in logical context '%s' (checking for null)\n",
                       node->line_number, op);
            }

            // Result is always boolean
            node->datatype = strdup("bool");
            node->is_pointer = false;
            node->pointer_depth = 0;
            node->size = 1;
            node->is_array = false;
            node->array_dimensions = 0;
            node->is_const = false;
            node->is_static = false;
            node->is_unsigned = false;
        }

        // Bitwise operators: &, |, ^, <<, >>
        else if (op && (strcmp(op, "&") == 0 || strcmp(op, "|") == 0 || strcmp(op, "^") == 0 ||
                        strcmp(op, "<<") == 0 || strcmp(op, ">>") == 0)) {

            if (!types_compatible) {
                printf("Semantic Error at line %d: Bitwise operation '%s' between incompatible types '%s' and '%s'\n",
                       node->line_number, op, node->left->datatype, node->right->datatype);
            }

            // Check for invalid types for bitwise operations
            if (strcmp(node->left->datatype, "float") == 0 || strcmp(node->left->datatype, "double") == 0 ||
                strcmp(node->right->datatype, "float") == 0 || strcmp(node->right->datatype, "double") == 0) {
                printf("Semantic Error at line %d: Bitwise operation '%s' not allowed on floating-point types\n",
                       node->line_number, op);
            }

            if (strcmp(node->left->datatype, "string") == 0 || strcmp(node->right->datatype, "string") == 0) {
                printf("Semantic Error at line %d: Bitwise operation '%s' not allowed on string types\n",
                       node->line_number, op);
            }

            // NEW: Enhanced pointer restrictions for bitwise operations
            if ((node->left->is_pointer && node->left->pointer_depth > 0) || 
                (node->right->is_pointer && node->right->pointer_depth > 0)) {
                printf("Semantic Error at line %d: Bitwise operation '%s' not allowed with pointers\n",
                       node->line_number, op);
            }
            
            if ((node->left->is_array && node->left->array_dimensions > 0) || 
                (node->right->is_array && node->right->array_dimensions > 0)) {
                printf("Semantic Error at line %d: Bitwise operation '%s' not allowed with arrays\n",
                       node->line_number, op);
            }

            // NEW: Shift operation specific checks
            if ((strcmp(op, "<<") == 0 || strcmp(op, ">>") == 0) && 
                strcmp(node->right->datatype, "bool") == 0) {
                printf("Warning at line %d: Shift count should be integer, not boolean\n",
                       node->line_number);
            }

            // Type promotion for bitwise operations
            int prec1 = precedence(node->left->datatype);
            int prec2 = precedence(node->right->datatype);

            if (prec1 >= prec2) {
                node->datatype = strdup(node->left->datatype);
                copy_llvm_fields(node, node->left);
            } else {
                node->datatype = strdup(node->right->datatype);
                copy_llvm_fields(node, node->right);
            }
            
            // NEW: Set unsigned flag for bitwise operations
            node->is_unsigned = left_is_unsigned || right_is_unsigned;
            node->is_const = false;
            node->is_static = false;
        }

        // NEW: Assignment operators handling (for completeness)
        else if (op && (strcmp(op, "=") == 0 || strcmp(op, "+=") == 0 || strcmp(op, "-=") == 0 ||
                        strcmp(op, "*=") == 0 || strcmp(op, "/=") == 0 || strcmp(op, "%=") == 0 ||
                        strcmp(op, "&=") == 0 || strcmp(op, "|=") == 0 || strcmp(op, "^=") == 0 ||
                        strcmp(op, "<<=") == 0 || strcmp(op, ">>=") == 0)) {
            // Assignment operators are handled in NODE_ASSIGNMENT case
            // This is just fallback handling
            if (types_compatible) {
                node->datatype = strdup(node->left->datatype);
                copy_llvm_fields(node, node->left);
            } else {
                printf("Semantic Error at line %d: Assignment '%s' between incompatible types\n",
                       node->line_number, op);
                node->datatype = strdup("unknown");
            }
        }

        // Array/pointer specific checks
        if ((node->left->is_array && node->left->array_dimensions > 0) || 
            (node->right->is_array && node->right->array_dimensions > 0)) {
            // Arrays decay to pointers in most expressions
            if (op && (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 ||
                       strcmp(op, "*") == 0 || strcmp(op, "/") == 0)) {
                printf("Warning at line %d: Array used in arithmetic operation '%s' (decays to pointer)\n",
                       node->line_number, op);
            }
        }

        // Const correctness
        if ((left_is_const || right_is_const) &&
            op && (strcmp(op, "=") == 0)) {
            printf("Semantic Error at line %d: Cannot assign to const operand\n",
                   node->line_number);
        }

        // NEW: Enhanced struct type operations
        if (node->left->struct_name || node->right->struct_name) {
            // Most operations on structs are not allowed
            if (op && !(strcmp(op, "==") == 0 || strcmp(op, "!=") == 0 ||
                        strcmp(op, "=") == 0)) {
                printf("Semantic Error at line %d: Operation '%s' not allowed on struct types\n",
                       node->line_number, op);
            }

            // Struct comparison requires same struct type
            if ((strcmp(op, "==") == 0 || strcmp(op, "!=") == 0) &&
                node->left->struct_name && node->right->struct_name) {
                if (strcmp(node->left->struct_name, node->right->struct_name) != 0) {
                    printf("Semantic Error at line %d: Cannot compare different struct types '%s' and '%s'\n",
                           node->line_number, node->left->struct_name, node->right->struct_name);
                }
            }
        }

        // Function type operations
        if (node->left->is_function || node->right->is_function) {
            printf("Semantic Error at line %d: Operation '%s' not allowed on function types\n",
                   node->line_number, op);
        }

        // Default case for unhandled operators or compatible types
        if (!node->datatype) {
            if (types_compatible) {
                int prec1 = precedence(node->left->datatype);
                int prec2 = precedence(node->right->datatype);

                // NEW: Enhanced type promotion with modifier consideration
                if (prec1 == prec2) {
                    if (left_is_unsigned && !right_is_unsigned) {
                        node->datatype = strdup(node->left->datatype);
                        copy_llvm_fields(node, node->left);
                    } else if (!left_is_unsigned && right_is_unsigned) {
                        node->datatype = strdup(node->right->datatype);
                        copy_llvm_fields(node, node->right);
                    } else if (prec1 >= prec2) {
                        node->datatype = strdup(node->left->datatype);
                        copy_llvm_fields(node, node->left);
                    } else {
                        node->datatype = strdup(node->right->datatype);
                        copy_llvm_fields(node, node->right);
                    }
                } else if (prec1 >= prec2) {
                    node->datatype = strdup(node->left->datatype);
                    copy_llvm_fields(node, node->left);
                } else {
                    node->datatype = strdup(node->right->datatype);
                    copy_llvm_fields(node, node->right);
                }
                
                // NEW: Set type modifiers for default case
                node->is_unsigned = left_is_unsigned || right_is_unsigned;
                node->is_const = false; // Operations don't preserve const
                node->is_static = false;
            } else {
                printf("Semantic Error at line %d: Operation '%s' between incompatible types '%s' and '%s'\n",
                       node->line_number, op, node->left->datatype, node->right->datatype);
                node->datatype = strdup("unknown");
                node->is_pointer = false;
                node->pointer_depth = 0;
                node->is_array = false;
                node->array_dimensions = 0;
                node->is_const = false;
                node->is_static = false;
                node->is_unsigned = false;
            }
        }
        
        // NEW: Debug output for complex operations
        if (op && (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 || 
                   strcmp(op, "*") == 0 || strcmp(op, "/") == 0)) {
            printf("DEBUG: Binary op '%s' - result: type=%s, unsigned=%d, pointer=%d\n",
                   op, node->datatype, node->is_unsigned, node->is_pointer);
        }
    } else {
        if (!node->left || !node->left->datatype) {
            printf("Semantic Error at line %d: Left operand of binary operator has undefined type\n",
                   node->line_number);
        }
        if (!node->right || !node->right->datatype) {
            printf("Semantic Error at line %d: Right operand of binary operator has undefined type\n",
                   node->line_number);
        }
    }
    break;
}

case NODE_UNARY_OP: {
    check_semantics(node->left, parent_scope);
    if (node->left && node->left->datatype) {
        // Free existing datatype if it exists
        if (node->datatype) free(node->datatype);
        node->datatype = strdup(node->left->datatype);
        copy_llvm_fields(node, node->left);

        // NEW: Enhanced type modifier propagation
        node->is_const = node->left->is_const;
        node->is_static = node->left->is_static;
        node->is_unsigned = node->left->is_unsigned;

        // Handle pointer dereferencing (* operator)
        if (node->op && strcmp(node->op, "*") == 0) {
            if (node->left->is_pointer && node->left->pointer_depth > 0) {
                // Valid pointer dereference
                node->is_pointer = (node->left->pointer_depth > 1);
                node->pointer_depth = node->left->pointer_depth - 1;
                node->is_array = false; // Dereferencing removes array property
                node->array_dimensions = 0;
                if (node->array_sizes) {
                    free(node->array_sizes);
                    node->array_sizes = NULL;
                }
                printf("DEBUG: Pointer dereference - depth %d -> %d\n", 
                       node->left->pointer_depth, node->pointer_depth);
            } else {
                printf("Semantic Error at line %d: Invalid pointer dereferencing '%s' - not a pointer\n",
                       node->line_number, node->op);
            }
        }

        // Handle address-of operator (&)
        else if (node->op && strcmp(node->op, "&") == 0) {
            // Check if we can take address of the operand
            if (is_valid_lvalue(node->left)) {
                node->is_pointer = true;
                node->pointer_depth = node->left->pointer_depth + 1;
                
                // Arrays decay to pointers when taking address
                if (node->left->is_array && node->left->array_dimensions > 0) {
                    printf("DEBUG: Array decay to pointer in address-of operation\n");
                    node->is_array = false;
                    node->array_dimensions = 0;
                    if (node->array_sizes) {
                        free(node->array_sizes);
                        node->array_sizes = NULL;
                    }
                }
                
                printf("DEBUG: Address-of operator - depth %d -> %d\n",
                       node->left->pointer_depth, node->pointer_depth);
            } else {
                printf("Semantic Error at line %d: Cannot take address of non-lvalue '%s'\n",
                       node->line_number, 
                       node->left->value ? node->left->value : node_type_to_string(node->left->type));
            }
        }

        // Handle increment/decrement operators (++ and --) - FIXED FOR PREFIX/POSTFIX
        else if (node->op && (strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0)) {
            // NEW: Enhanced prefix/postfix distinction
            bool is_prefix = !node->is_postfix;
            
            if (is_prefix) {
                printf("DEBUG: Prefix %s operator at line %d\n", node->op, node->line_number);
            } else {
                printf("DEBUG: Postfix %s operator at line %d\n", node->op, node->line_number);
            }

            // Check if operand is an identifier or valid lvalue
            if (!is_valid_lvalue(node->left)) {
                printf("Semantic Error at line %d: Operator '%s' expects an lvalue (identifier, pointer dereference, array element, or member access), got '%s'\n",
                       node->line_number, node->op,
                       node->left->value ? node->left->value : node_type_to_string(node->left->type));
            }

            // Check if the type supports increment/decrement
            if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char") == 0 ||
                strcmp(node->datatype, "bool") == 0) {
                printf("Semantic Error at line %d: Operation '%s' not defined on type '%s'\n",
                       node->line_number, node->op, node->datatype);
            }

            // NEW: Check for pointer arithmetic restrictions
            if (node->left->is_pointer && node->left->pointer_depth > 0) {
                printf("Semantic Error at line %d: Increment/decrement not allowed on pointers\n",
                       node->line_number);
            }
            
            if (node->left->is_array && node->left->array_dimensions > 0) {
                printf("Semantic Error at line %d: Increment/decrement not allowed on arrays\n",
                       node->line_number);
            }

            // Check for const correctness
            if (node->left->is_const) {
                printf("Semantic Error at line %d: Cannot modify const variable with '%s' operator\n",
                       node->line_number, node->op);
            }
            
            // NEW: For postfix operations, the result type should be the original type (rvalue)
            // For prefix operations, the result type is the modified lvalue
            // This distinction is important for expression evaluation
            if (!is_prefix) {
                // Postfix: result is the original value (rvalue)
                // The operation happens after value usage
                printf("DEBUG: Postfix %s - result is rvalue of type '%s'\n", 
                       node->op, node->datatype);
            } else {
                // Prefix: result is the modified lvalue  
                // The operation happens before value usage
                printf("DEBUG: Prefix %s - result is modified lvalue of type '%s'\n", 
                       node->op, node->datatype);
            }
        }

        // Handle unary plus/minus operators (+ and -)
        else if (node->op && (strcmp(node->op, "+") == 0 || strcmp(node->op, "-") == 0)) {
            // Check if the type supports arithmetic operations
            if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char") == 0 ||
                strcmp(node->datatype, "bool") == 0) {
                printf("Semantic Error at line %d: Operation '%s' not defined on type '%s'\n",
                       node->line_number, node->op, node->datatype);
            }
            
            // NEW: Handle unary minus with unsigned types
            if (strcmp(node->op, "-") == 0 && node->is_unsigned) {
                printf("Warning at line %d: Unary minus applied to unsigned type '%s'\n",
                       node->line_number, node->datatype);
            }
            
            // NEW: Pointer restrictions for unary operators
            if (node->left->is_pointer && node->left->pointer_depth > 0) {
                printf("Semantic Error at line %d: Unary '%s' not allowed on pointers\n",
                       node->line_number, node->op);
            }
            
            if (node->left->is_array && node->left->array_dimensions > 0) {
                printf("Semantic Error at line %d: Unary '%s' not allowed on arrays\n",
                       node->line_number, node->op);
            }
        }

        // Handle logical NOT operator (!)
        else if (node->op && strcmp(node->op, "!") == 0) {
            // Logical NOT can be applied to any type, but warn about non-boolean types
            if (strcmp(node->datatype, "bool") != 0) {
                printf("Warning at line %d: Logical NOT applied to non-boolean type '%s'\n",
                       node->line_number, node->datatype);
            }
            
            // NEW: Result of logical NOT is always boolean
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("bool");
            node->is_pointer = false;
            node->pointer_depth = 0;
            node->is_array = false;
            node->array_dimensions = 0;
            node->size = 1;
            node->is_unsigned = false;
            
            if (node->array_sizes) {
                free(node->array_sizes);
                node->array_sizes = NULL;
            }
        }

        // NEW: Handle bitwise NOT operator (~)
        else if (node->op && strcmp(node->op, "~") == 0) {
            // Check if type supports bitwise operations
            if (strcmp(node->datatype, "float") == 0 || strcmp(node->datatype, "double") == 0 ||
                strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "bool") == 0) {
                printf("Semantic Error at line %d: Bitwise NOT '~' not allowed on type '%s'\n",
                       node->line_number, node->datatype);
            }
            
            // Pointer restrictions
            if (node->left->is_pointer && node->left->pointer_depth > 0) {
                printf("Semantic Error at line %d: Bitwise NOT '~' not allowed on pointers\n",
                       node->line_number);
            }
            
            if (node->left->is_array && node->left->array_dimensions > 0) {
                printf("Semantic Error at line %d: Bitwise NOT '~' not allowed on arrays\n",
                       node->line_number);
            }
        }

        // Additional type compatibility checks for all unary operators
        if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char") == 0) {
            // Only allow certain operations on string/char types
            if (node->op && (strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0 ||
                                  strcmp(node->op, "+") == 0 || strcmp(node->op, "-") == 0 ||
                                  strcmp(node->op, "~") == 0)) {
                printf("Semantic Error at line %d: Operation '%s' not defined on string or character type\n",
                       node->line_number, node->op);
            }
        }

        // NEW: Enhanced const correctness for all modifying operations
        if (node->left->is_const && node->op &&
            (strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0)) {
            printf("Semantic Error at line %d: Cannot modify const variable with '%s' operator\n",
                   node->line_number, node->op);
        }

        // Validate pointer depth after operations
        if (node->pointer_depth < 0) {
            printf("Semantic Error at line %d: Invalid pointer depth after operation '%s'\n",
                   node->line_number, node->op);
        }
        
        // NEW: Validate array dimensions after operations
        if (node->array_dimensions < 0) {
            printf("Semantic Error at line %d: Invalid array dimensions after operation '%s'\n",
                   node->line_number, node->op);
        }
        
        // NEW: Debug output for complex operations
        if (node->op && (strcmp(node->op, "&") == 0 || strcmp(node->op, "*") == 0)) {
            printf("DEBUG: Unary op '%s' - result: type=%s, pointer=%d, depth=%d, array=%d, dims=%d\n",
                   node->op, node->datatype, node->is_pointer, node->pointer_depth, 
                   node->is_array, node->array_dimensions);
        }
    } else if (node->left && !node->left->datatype) {
        printf("Semantic Error at line %d: Operand of unary operator '%s' has undefined type\n",
               node->line_number, node->op ? node->op : "unknown");
    }
    break;
}

case NODE_POSTFIX_EXPR: {
            // This case should handle postfix increment/decrement specifically
            // but in our grammar, postfix inc/dec are handled in unary_expr with is_postfix flag
            // So we need to ensure they're properly processed
            
            ASTNode* primary = node->child;
            if (primary) {
                check_semantics(primary, parent_scope);
                
                // Inherit type from primary expression
                if (primary->datatype) {
                    if (node->datatype) free(node->datatype);
                    node->datatype = strdup(primary->datatype);
                    copy_llvm_fields(node, primary);
                }
                
                // Handle postfix operations that might be here
                // (array indexing, function calls, member access are already handled elsewhere)
            }
            break;
        }

case NODE_ASSIGNMENT: {
    semantic_info *left_info = NULL;
    semantic_info *last = current_scope;
    while (last->next) last = last->next;

    check_semantics(node->left, parent_scope);
    if (last->next) left_info = last->next;
    check_semantics(node->right, parent_scope);

    if (node->left && node->right && node->left->datatype && node->right->datatype) {
        // Free existing datatype if it exists
        if (node->datatype) free(node->datatype);

        // Get assignment operator
        char* op = node->op;
        bool is_simple_assign = (op && strcmp(op, "=") == 0);
        bool is_compound_assign = (op && (strcmp(op, "+=") == 0 || strcmp(op, "-=") == 0 ||
                                     strcmp(op, "*=") == 0 || strcmp(op, "/=") == 0 ||
                                     strcmp(op, "%=") == 0 || strcmp(op, "&=") == 0 ||
                                     strcmp(op, "|=") == 0 || strcmp(op, "^=") == 0 ||
                                     strcmp(op, "<<=") == 0 || strcmp(op, ">>=") == 0));

        // Check if left side is a valid lvalue
        if (!is_valid_lvalue(node->left)) {
            printf("Semantic Error at line %d: Left side of assignment must be an lvalue (identifier, array element, pointer dereference, or member access)\n",
                   node->line_number);
        }

        // Check const correctness
        if (node->left->is_const) {
            printf("Semantic Error at line %d: Cannot assign to const variable\n",
                   node->line_number);
        }

        // Handle auto type inference
        if (strcmp(node->left->datatype, "auto") == 0) {
            // Free existing datatype if it was dynamically allocated
            if (node->left->datatype && strcmp(node->left->datatype, "auto") != 0) {
                free(node->left->datatype);
            }
            node->left->datatype = strdup(node->right->datatype);

            // Copy LLVM fields from right to left
            copy_llvm_fields(node->left, node->right);

            if (left_info) {
                // Free existing type in scope info if it was dynamically allocated
                if (left_info->type && strcmp(left_info->type, "auto") != 0) {
                    free(left_info->type);
                }
                left_info->type = strdup(node->right->datatype);
                // Also copy LLVM fields to semantic info
                left_info->isarray = node->right->is_array;
                left_info->array_dimensions = node->right->array_dimensions;
                if (node->right->array_sizes && node->right->array_dimensions > 0) {
                    if (left_info->array_sizes) free(left_info->array_sizes);
                    left_info->array_sizes = (int*)malloc(node->right->array_dimensions * sizeof(int));
                    memcpy(left_info->array_sizes, node->right->array_sizes,
                           node->right->array_dimensions * sizeof(int));
                }
                left_info->ispointer = node->right->is_pointer;
                left_info->pointerdepth = node->right->pointer_depth;
                left_info->isref = node->right->is_reference;
                left_info->size = node->right->size;
                left_info->is_const = node->right->is_const;
                left_info->is_static = node->right->is_static;
                left_info->is_unsigned = node->right->is_unsigned;

                if (node->right->struct_name) {
                    if (left_info->struct_name) free(left_info->struct_name);
                    left_info->struct_name = strdup(node->right->struct_name);
                }
            }

            // Set result type
            node->datatype = strdup(node->left->datatype);
            copy_llvm_fields(node, node->left);
        }

        // Regular assignment with type checking
        else {
            bool types_compatible = is_type_compatible(node->left->datatype, node->right->datatype);

            // Simple assignment (=)
            if (is_simple_assign) {
                // ========== CRITICAL FIX: Check for array-to-pointer decay assignment ==========
                bool is_array_to_pointer_assignment = false;

                // Check if this is: pointer = array (array decay to pointer)
                if (node->left->is_pointer && node->right->is_array &&
                    !node->right->is_pointer && node->left->pointer_depth == 1) {



                    // Check if base types are compatible
                    if (is_type_compatible(node->left->datatype, node->right->datatype)) {
                        is_array_to_pointer_assignment = true;

                    } else {
                        printf("Semantic Error at line %d: Array type '%s' cannot decay to pointer type '%s'\n",
                               node->line_number, node->right->datatype, node->left->datatype);
                    }
                }

                // ========== ARRAY REFERENCE ASSIGNMENT CHECK ==========
                // Check for multi-dimensional array assignment to multi-level pointers
                if (node->left->is_pointer && node->right->is_array &&
                    node->left->pointer_depth >= 1 && node->right->array_dimensions >= 1) {



                    // For: int **ptr = arr; where arr is int[3][4]
                    // pointer_depth should equal array_dimensions
                    if (node->left->pointer_depth != node->right->array_dimensions) {
                        printf("Semantic Error at line %d: Pointer depth (%d) does not match array dimensions (%d) for assignment\n",
                               node->line_number, node->left->pointer_depth, node->right->array_dimensions);
                    } else if (!is_type_compatible(node->left->datatype, node->right->datatype)) {
                        printf("Semantic Error at line %d: Base type mismatch in multi-dimensional array assignment\n",
                               node->line_number);
                    }
                }

                if (!is_array_to_pointer_assignment && !types_compatible) {
                    printf("Semantic Error at line %d: Cannot assign type '%s' to type '%s'\n",
                           node->line_number, node->right->datatype, node->left->datatype);
                }

                // Removed debug printf statement


                // Pointer assignment rules (excluding array-to-pointer decay case)
                if (node->left->is_pointer && node->right->is_pointer && !node->right->is_array) {
                    if (node->left->pointer_depth != node->right->pointer_depth) {
                        printf("Semantic Error at line %d: Pointer depth mismatch in assignment (%d vs %d)\n",
                               node->line_number, node->left->pointer_depth, node->right->pointer_depth);
                    }

                    // Check if base types are compatible (excluding string which has special rules)
                    if (strcmp(node->left->datatype, "string") != 0 && strcmp(node->right->datatype, "string") != 0) {
                        if (!is_type_compatible(node->left->datatype, node->right->datatype)) {
                            printf("Semantic Error at line %d: Incompatible pointer types in assignment\n",
                                   node->line_number);
                        }
                    }
                }

                // ========== ADDITIONAL ARRAY-POINTER COMPATIBILITY CHECKS ==========

                // Array assignment restrictions (excluding array-to-pointer decay)
                if (node->left->is_array && node->right->is_array && !is_array_to_pointer_assignment) {
                    // Array to array assignment is generally not allowed in C
                    printf("Semantic Error at line %d: Array assignment not allowed (use memcpy or loop)\n",
                           node->line_number);
                }

                // Check for pointer to array assignment with compatible dimensions
                if (node->left->is_array && node->right->is_pointer &&
                    node->left->array_dimensions == node->right->pointer_depth) {

                    printf("DEBUG: Pointer-to-array assignment with matching dimensions\n");
                    if (!is_type_compatible(node->left->datatype, node->right->datatype)) {
                        printf("Semantic Error at line %d: Type mismatch in pointer-to-array assignment\n",
                               node->line_number);
                    }
                }

                if((node->left->is_pointer&&node->left->pointer_depth>0||node->left->is_array&&node->left->array_dimensions>0) && (!node->right->is_pointer&&(!node->right->is_array))){
                    printf("Semantuic Error : invalid assignemt  to pointer line n. '%d' , '%s' \n",node->left->line_number,node->left->value);
                }

                if((node->right->is_pointer&&node->right->pointer_depth>0||node->right->is_array&&node->right->array_dimensions>0) && (!node->left->is_pointer&&(!node->left->is_array))){
                    printf("Semantuic Error : invalid assignemt  to pointer line n. '%d' , '%s' \n",node->left->line_number,node->left->value);
                }

                // String assignment (special case)
                if (strcmp(node->left->datatype, "string") == 0 && strcmp(node->right->datatype, "string") == 0) {
                    // String assignment is allowed (pointer copy)
                }
                else if ((strcmp(node->left->datatype, "string") == 0 && !node->right->is_pointer) ||
                         (strcmp(node->right->datatype, "string") == 0 && !node->left->is_pointer)) {
                    printf("Semantic Error at line %d: String assignment requires pointer types\n",
                           node->line_number);
                }

                // Struct assignment
                if (node->left->struct_name || node->right->struct_name) {
                    if (node->left->struct_name && node->right->struct_name) {
                        if (strcmp(node->left->struct_name, node->right->struct_name) != 0) {
                            printf("Semantic Error at line %d: Cannot assign different struct types '%s' and '%s'\n",
                                   node->line_number, node->left->struct_name, node->right->struct_name);
                        }
                    } else if ((node->left->struct_name && !node->right->struct_name) ||
                              (!node->left->struct_name && node->right->struct_name)) {
                        printf("Semantic Error at line %d: Struct/non-struct type mismatch in assignment\n",
                               node->line_number);
                    }
                }

                // Function pointer assignment
                if (node->left->is_function || node->right->is_function) {
                    printf("Semantic Error at line %d: Function assignment not allowed\n",
                           node->line_number);
                }
            }

            // Compound assignment operators (+=, -=, *=, /=, %=, &=, |=, ^=, <<=, >>=)
            else if (is_compound_assign) {
                // First check if types are compatible for the base assignment
                if (!types_compatible) {
                    printf("Semantic Error at line %d: Compound assignment '%s' between incompatible types '%s' and '%s'\n",
                           node->line_number, op, node->left->datatype, node->right->datatype);
                }

                // Check if the operation is valid for the types
                char base_op[3] = {0};
                strncpy(base_op, op, strlen(op) - 1); // Remove the '=' to get base operator

                // Arithmetic compound assignments
                if (strcmp(base_op, "+") == 0 || strcmp(base_op, "-") == 0 ||
                    strcmp(base_op, "*") == 0 || strcmp(base_op, "/") == 0 || strcmp(base_op, "%") == 0) {

                    // Check for pointer arithmetic restrictions
                    if ((node->left->is_pointer&& node->left->pointer_depth>0) || (node->right->is_pointer&&node->left->pointer_depth>0)) {
                        printf("Semantic Error at line %d: Compound assignment '%s' not allowed between two pointers\n",
                               node->line_number, op);
                    }

                    // Check for invalid types
                    if (strcmp(node->left->datatype, "string") == 0 || strcmp(node->right->datatype, "string") == 0) {
                        printf("Semantic Error at line %d: Arithmetic compound assignment '%s' not allowed on string types\n",
                               node->line_number, op);
                    }

                    // Special case: string concatenation with +=
                    if (strcmp(op, "+=") == 0 && strcmp(node->left->datatype, "string") == 0) {
                        // String concatenation is allowed
                    }
                    else if (strcmp(node->left->datatype, "string") == 0) {
                        printf("Semantic Error at line %d: Only += is allowed for string concatenation\n",
                               node->line_number);
                    }
                }

                // Bitwise compound assignments
                else if (strcmp(base_op, "&") == 0 || strcmp(base_op, "|") == 0 ||
                         strcmp(base_op, "^") == 0 || strcmp(base_op, "<<") == 0 || strcmp(base_op, ">>") == 0) {

                    // Check for invalid types for bitwise operations
                    if (strcmp(node->left->datatype, "float") == 0 || strcmp(node->left->datatype, "double") == 0 ||
                        strcmp(node->right->datatype, "float") == 0 || strcmp(node->right->datatype, "double") == 0) {
                        printf("Semantic Error at line %d: Bitwise compound assignment '%s' not allowed on floating-point types\n",
                               node->line_number, op);
                    }

                    if (strcmp(node->left->datatype, "string") == 0 || strcmp(node->right->datatype, "string") == 0) {
                        printf("Semantic Error at line %d: Bitwise compound assignment '%s' not allowed on string types\n",
                               node->line_number, op);
                    }

                    // Pointer restrictions
                    if ((node->left->is_pointer && node->left->pointer_depth>0) || (node->right->is_pointer && node->right->pointer_depth>0)) {
                        printf("Semantic Error at line %d: Bitwise compound assignment '%s' not allowed with pointers\n",
                               node->line_number, op);
                    }
                }
            }

            // Set result type for the assignment expression
            node->datatype = strdup(node->left->datatype);
            copy_llvm_fields(node, node->left);

            // For compound assignments, the result should be the same as the left operand
            // but we need to ensure the operation itself is valid
            if (is_compound_assign) {
                // Additional validation for the implied operation
                if (!is_type_compatible(node->left->datatype, node->right->datatype)) {
                    printf("Semantic Error at line %d: Operands for compound assignment '%s' must have compatible types\n",
                           node->line_number, op);
                }
            }
        }

        // Check for array bounds if applicable
        if (node->left->is_array && node->left->array_sizes) {
            // In a complete implementation, you would check if the index is within bounds
            // This is a placeholder for array bounds checking
            printf("Warning at line %d: Array assignment - bounds checking not implemented\n",
                   node->line_number);
        }

        // Validate reference types
        if (node->left->is_reference) {
            // References must be initialized and cannot be reassigned to different objects
            // In C++, once a reference is bound, it cannot be rebound
            printf("Warning at line %d: Reference assignment - reference remains bound to original object\n",
                   node->line_number);
        }
    }

    break;
}
case NODE_COMPOUND_STMT:{
    semantic_info * last=current_scope;
    while(last->next)last=last->next;
    check_semantics(node->child,parent_scope);

    if(last->next){
        scope_start_ptr=last->next;
    }

    break;
    }

 case NODE_TERNARY_OP: {
            check_semantics(node->child, parent_scope);  // condition
            check_semantics(node->left, parent_scope);   // then expr
            check_semantics(node->right, parent_scope);  // else expr

            // Check condition type
            if (node->child && node->child->datatype) {
                if (strcmp(node->child->datatype, "bool") != 0) {
                    printf("Warning at line %d: Ternary condition should be boolean, got '%s'\n",
                           node->line_number, node->child->datatype);
                }
            }

            if (node->left && node->right && node->left->datatype && node->right->datatype) {
                if (node->datatype) free(node->datatype);

                if (is_type_compatible(node->left->datatype, node->right->datatype)) {
                    int prec1 = precedence(node->left->datatype);
                    int prec2 = precedence(node->right->datatype);

                    if (prec1 >= prec2) {
                        node->datatype = strdup(node->left->datatype);
                        copy_llvm_fields(node, node->left);
                    } else {
                        node->datatype = strdup(node->right->datatype);
                        copy_llvm_fields(node, node->right);
                    }

                    // Special case: handle pointer compatibility
                    if (node->left->is_pointer && node->right->is_pointer) {
                        if (node->left->pointer_depth != node->right->pointer_depth) {
                            printf("Semantic Error at line %d: Ternary operands have different pointer depths (%d vs %d)\n",
                                   node->line_number, node->left->pointer_depth, node->right->pointer_depth);
                        }
                    }

                    // Special case: handle struct compatibility
                    if (node->left->struct_name || node->right->struct_name) {
                        if (node->left->struct_name && node->right->struct_name) {
                            if (strcmp(node->left->struct_name, node->right->struct_name) != 0) {
                                printf("Semantic Error at line %d: Ternary operands have different struct types\n",
                                       node->line_number);
                            }
                            node->struct_name = strdup(node->left->struct_name);
                        } else if (node->left->struct_name && !node->right->struct_name) {
                            printf("Semantic Error at line %d: Ternary operands have struct/non-struct mismatch\n",
                                   node->line_number);
                        } else if (!node->left->struct_name && node->right->struct_name) {
                            printf("Semantic Error at line %d: Ternary operands have non-struct/struct mismatch\n",
                                   node->line_number);
                        }
                    }
                } else {
                    node->datatype = strdup("ambiguous");
                    printf("Semantic Error at line %d: Ternary operands have incompatible types '%s' and '%s'\n",
                           node->line_number, node->left->datatype, node->right->datatype);
                }
            }
            break;
        }


case NODE_INDEX: {


            // Check the array expression (child) and index expression (next sibling)
            check_semantics(node->child, parent_scope);

            // The index expression is stored as the next child of the index node
            ASTNode* index_expr = node->child ? node->child->next : NULL;

            if (node->child && node->child->datatype) {
                // Free existing datatype if it exists
                if (node->datatype) free(node->datatype);

                // Validate that we're indexing an array or pointer
                if (!node->child->is_array && !node->child->is_pointer) {
                    printf("Semantic Error at line %d: Subscripted value is neither array nor pointer (type: %s)\n",
                           node->line_number, node->child->datatype);
                    node->datatype = strdup("unknown");
                    break;
                }

                // Validate index expression
                if (!index_expr) {
                    printf("Semantic Error at line %d: Array index expression missing\n", node->line_number);
                    node->datatype = strdup("unknown");
                    break;
                }



                // Check index type - should be integer type
                if (index_expr->datatype) {
                    if (strcmp(index_expr->datatype, "int") != 0 &&
                        strcmp(index_expr->datatype, "unsigned int") != 0 &&
                        strcmp(index_expr->datatype, "short") != 0 &&
                        strcmp(index_expr->datatype, "long") != 0 &&
                        strcmp(index_expr->datatype, "char") != 0) {
                        printf("Semantic Error at line %d: Array index must be integer type, got '%s'\n",
                               node->line_number, index_expr->datatype);
                    }
                }

                // Handle nested index nodes for multi-dimensional arrays
                if (node->child->type == NODE_INDEX) {


                    // For nested index nodes, inherit properties from child index node
                    node->datatype = strdup(node->child->datatype);

                    // Copy ALL LLVM fields from child index node
                    copy_llvm_fields(node, node->child);

                    // For multi-dimensional arrays, each indexing reduces dimensions by 1
                    if (node->child->array_dimensions > 0) {
                        node->array_dimensions=node->child->array_dimensions-1;
                        // Copy array sizes for remaining dimensions
                        if (node->child->array_sizes && node->array_dimensions > 0) {
                            node->array_sizes = (int*)malloc(node->array_dimensions * sizeof(int));
                            for (int i = 0; i < node->array_dimensions; i++) {
                                node->array_sizes[i] = node->child->array_sizes[i + 1];
                            }
                        }
                    }

                    if(node->child->pointer_depth > 0){
                        node->pointer_depth=node->child->pointer_depth-1;
                    }

                else if(node->child->array_dimensions<=0||node->child->pointer_depth<=0){
                    printf("Semantic Error : invlaid indexing , incompatible dimations line no. '%d' , '%s' \n",node->line_number,node->value);
                }

                }
                // Handle base array identifier
                else if (node->child->type == NODE_IDENTIFIER) {

                    // Copy type from base array
                    node->datatype = strdup(node->child->datatype);

                    // Copy ALL LLVM fields from base array
                    copy_llvm_fields(node, node->child);

                    // For the first index operation, reduce dimensions by 1
                    if (node->child->array_dimensions > 0) {
                        node->array_dimensions = node->child->array_dimensions - 1;

                        // Copy array sizes for remaining dimensions
                        if (node->child->array_sizes && node->array_dimensions > 0) {
                            node->array_sizes = (int*)malloc(node->array_dimensions * sizeof(int));
                            for (int i = 0; i < node->array_dimensions; i++) {
                                node->array_sizes[i] = node->child->array_sizes[i + 1];
                            }
                        }
                    }


                    // Handle pointer conversion for arrays (array decay to pointer)
                    if (node->child->is_array && !node->child->is_pointer) {
                        node->is_pointer = true;
                        node->pointer_depth = node->array_dimensions;

                        node->is_array = (node->array_dimensions > 0);
                    }

                     if(node->child->pointer_depth > 0){
                        node->pointer_depth=node->child->pointer_depth-1;
                    }

                    printf("DEBUG: Base index - dims: %d->%d, array->pointer: %d\n",
                           node->child->array_dimensions, node->array_dimensions, node->is_pointer);
                }

                // Array bounds checking (if array sizes are known)
                if (node->child->array_sizes && node->child->array_dimensions > 0 && index_expr) {
                    // Check if index expression is a constant integer
                    if (index_expr->type == NODE_LITERAL && strcmp(index_expr->datatype,"int")==0) {
                        int index_value = atoi(index_expr->value);
                        int array_size = node->child->array_sizes[0];

                        if (array_size > 0 && (index_value < 0 || index_value >= array_size)) {
                            printf("Warning at line %d: Array index %d out of bounds [0, %d)\n",
                                   node->line_number, index_value, array_size);
                        }
                    }
                }
            }
            break;
        }

case NODE_LITERAL: {
    // Determine literal type based on value format
    if (node->value) {
        if (node->datatype) free(node->datatype);

        // Check if it's an integer literal
         if (isdigit((unsigned char)node->value[0]) || (node->value[0] == '-' && isdigit((unsigned char)node->value[1]))) {
            // Check for float indicators
            if (strchr(node->value, '.') || strchr(node->value, 'e') || strchr(node->value, 'E')) {
                node->datatype = strdup("float");
                node->size = 4;
            } else {
                node->datatype = strdup("int");
                node->size = 4;
            }
        }
        // Check if it's a character literal
        else if (node->value[0] == '\'' && node->value[strlen(node->value)-1] == '\'') {
            node->datatype = strdup("char");
            node->size = 1;
        }
        // Check if it's a string literal
        else if (node->value[0] == '\"' && node->value[strlen(node->value)-1] == '\"') {
            node->datatype = strdup("string");
            node->size = 8; // Pointer size
            node->is_pointer = true;
            node->pointer_depth = 1;
        }
        // Check if it's a boolean literal
        else if (strcmp(node->value, "true") == 0 || strcmp(node->value, "false") == 0) {
            node->datatype = strdup("bool");
            node->size = 1;
        }
        else {
            node->datatype = strdup("unknown");
            node->size = 0;
        }
    } else {
        node->datatype = strdup("unknown");
        node->size = 0;
    }

    // Set common literal properties
    node->is_array = false;
    node->array_dimensions = 0;
    node->is_reference = false;
    node->is_function = false;
    node->is_parameter = false;
    node->param_count = 0;
    node->has_ellipsis = false;
    node->is_const = true; // Literals are always const
    node->is_static = false;
    node->is_unsigned = false;

    break;
}

case NODE_INIT_LIST: {


            // Count dimensions and sizes of the initializer list
            int dimensions[3] = {0}; // Max 3 dimensions
            int current_dim = 0;
            bool has_nested_lists = false;

            // Analyze the structure of the initializer list
            analyze_init_list_dimensions(node, dimensions, &current_dim, &has_nested_lists, 0);

            // Store dimension information in the AST node for LLVM
            node->init_list_dimentions = current_dim;
            if (current_dim > 0) {
                node->init_list_sizes = (int*)malloc(current_dim * sizeof(int));
                for (int i = 0; i < current_dim; i++) {
                    node->init_list_sizes[i] = dimensions[i];
                }
            }

            for (int i = 0; i < current_dim; i++) {
                printf("%d", dimensions[i]);
                if (i < current_dim - 1) printf(", ");
            }
            printf("]\n");

            // Process all children (elements) in the initializer list
            ASTNode* child = node->child;
            char* first_type = NULL;
            ASTNode* first_element = NULL;
            int element_count = 0;
            int error_count = 0;

            check_semantics(child, parent_scope);

            while (child) {
                element_count++;

                // Recursively check semantics of each element


                // Check type consistency across all elements at this level
                if (!first_type && child->datatype) {
                    first_type = child->datatype;
                    first_element = child;
                } else if (child->datatype && first_type) {
                    if (!is_type_compatible(first_type, child->datatype)) {
                        printf("Error at line %d: Type mismatch in initialization list. Expected %s, got %s\n",
                               node->line_number, first_type, child->datatype);
                        error_count++;
                    }
                } else if (!child->datatype) {
                    printf("Error at line %d: Undefined data type in initialization list element\n",
                           node->line_number);
                    error_count++;
                }

                child = child->next;
            }

            // Set the type and ALL LLVM fields for the init list node
            if (first_type) {
                if (node->datatype) free(node->datatype);
                node->datatype = strdup(first_type);

                // Copy ALL LLVM fields from first element for LLVM generation
                if (first_element) {
                    node->is_array = true;
                    node->array_dimensions = current_dim;
                    if (current_dim > 0) {
                        node->array_sizes = (int*)malloc(current_dim * sizeof(int));
                        for (int i = 0; i < current_dim; i++) {
                            node->array_sizes[i] = dimensions[i];
                        }
                    }

                    // Copy all other LLVM fields
                    copy_llvm_fields(node, first_element);
                }
            } else {
                if (node->datatype) free(node->datatype);
                node->datatype = strdup("unknown");
            }

            break;
        }

case NODE_WHILE_STMT:
case NODE_DO_WHILE_STMT: {
            ASTNode* condition = node->child;
            // FIXED: removed unused variable 'body'
            ASTNode* body = condition ? condition->next : NULL;

            check_semantics(condition, parent_scope);

            // Check condition type
            if (condition && condition->datatype) {
                if (strcmp(condition->datatype, "bool") != 0) {
                    printf("Warning at line %d: Loop condition should be boolean, got '%s'\n",
                           node->line_number, condition->datatype);
                }
            }

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }

case NODE_IF_STMT: {
            ASTNode* condition = node->child;
            ASTNode* then_stmt = condition ? condition->next : NULL;
            // FIXED: removed unused variable 'else_stmt'
            ASTNode* else_stmt = then_stmt ? then_stmt->next : NULL;

            check_semantics(condition, parent_scope);

            // Check condition type
            if (condition && condition->datatype) {
                if (strcmp(condition->datatype, "bool") != 0) {
                    printf("Warning at line %d: If condition should be boolean, got '%s'\n",
                           node->line_number, condition->datatype);
                }
            }

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }
 case NODE_FOR_STMT: {

            semantic_info * last =current_scope;
            while(last->next){
                last=last->next;
            }

            ASTNode* init = node->child;
            ASTNode* condition = init ? init->next : NULL;
            ASTNode* increment = condition ? condition->next : NULL;
            // FIXED: removed unused variable 'body'
            ASTNode* body = increment ? increment->next : NULL;


            if (init) check_semantics(init, parent_scope);

           if(last->next){
            scope_start_ptr=last->next;
           }

            // Check condition type if present
            if (condition && condition->datatype) {
                if (strcmp(condition->datatype, "bool") != 0) {
                    printf("Warning at line %d: For loop condition should be boolean, got '%s'\n",
                           node->line_number, condition->datatype);
                }
            }

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }
case NODE_RANGE_FOR_STMT: {
            semantic_info * last =current_scope;
            while(last->next){
                last=last->next;
            }

            ASTNode* decl = node->child;
            ASTNode* range_expr = decl ? decl->next : NULL;
            // FIXED: removed unused variable 'body'
            ASTNode* body = range_expr ? range_expr->next : NULL;

            if (decl) check_semantics(decl, parent_scope);
            if(last->next)scope_start_ptr=last->next;

            // Check if range expression is iterable (array or has begin/end)
            if (range_expr && range_expr->datatype) {
                if (!range_expr->is_array && strcmp(range_expr->datatype, "string") != 0) {
                    printf("Warning at line %d: Range-based for loop requires array, string, or iterable type, got '%s'\n",
                           node->line_number, range_expr->datatype);
                }
            }

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }


case NODE_SWITCH_STMT: {
            ASTNode* expr = node->child;
            // FIXED: removed unused variable 'cases'
            ASTNode* cases = expr ? expr->next : NULL;

            check_semantics(expr, parent_scope);

            // Check switch expression type - should be integer or enum
            if (expr && expr->datatype) {
                if (strcmp(expr->datatype, "int") != 0 &&
                    strcmp(expr->datatype, "unsigned int") != 0 &&
                    strcmp(expr->datatype, "char") != 0 &&
                    strcmp(expr->datatype, "short") != 0 &&
                    strcmp(expr->datatype, "long") != 0) {
                    printf("Semantic Error at line %d: Switch expression must be integer type, got '%s'\n",
                           node->line_number, expr->datatype);
                }
            }

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }

case NODE_CASE_STMT: {
            ASTNode* case_expr = node->child;
            // FIXED: removed unused variable 'stmts'
            ASTNode* stmts = case_expr ? case_expr->next : NULL;

            if (case_expr) check_semantics(case_expr, parent_scope);

            // Check case expression type
            if (case_expr && case_expr->datatype) {
                if (strcmp(case_expr->datatype, "int") != 0 &&
                    strcmp(case_expr->datatype, "char") != 0) {
                    printf("Semantic Error at line %d: Case expression must be integer or character constant\n",
                           node->line_number);
                }
            }

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }

case NODE_DEFAULT_STMT: {
            ASTNode* stmts = node->child;
            if (stmts) check_semantics(stmts, parent_scope);

            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }

case NODE_BREAK_STMT:
case NODE_CONTINUE_STMT: {
            // Check if we're inside a loop or switch
            // FIXED: removed unused variable 'in_loop_or_switch'
            bool in_loop_or_switch = false;
            // In a complete implementation, you would traverse up the AST to check context


            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }

        // ==================== GOTO STATEMENT (FIXED) ====================
case NODE_GOTO_STMT: {
            if (node->value) {
                // Check if label exists (would need label tracking)
                printf("DEBUG: Goto label '%s' at line %d\n", node->value, node->line_number);
                
                // NEW: Set basic properties for GOTO statement
                node->datatype = strdup("void");
                node->is_pointer = false;
                node->pointer_depth = 0;
                node->is_array = false;
                node->array_dimensions = 0;
                node->is_reference = false;
                node->is_function = false;
                node->param_count = 0;
                node->has_ellipsis = false;
                node->size = 0;
                node->is_const = false;
                node->is_static = false;
                node->is_unsigned = false;
            } else {
                printf("Semantic Error at line %d: Goto statement missing label\n", node->line_number);
            }
            break;
        }




        // ==================== CAST EXPRESSIONS (NEW) ====================
        case NODE_CAST_EXPR: {
            ASTNode* type_node = node->child;
            ASTNode* expr = type_node ? type_node->next : NULL;

            if (type_node) check_semantics(type_node, parent_scope);
            if (expr) check_semantics(expr, parent_scope);

            // Set result type to cast type
            if (type_node && type_node->datatype) {
                if (node->datatype) free(node->datatype);
                node->datatype = strdup(type_node->datatype);
                
                // Copy LLVM fields from type node
                copy_llvm_fields(node, type_node);
                
                printf("DEBUG: Cast expression at line %d: casting '%s' to '%s'\n", 
                       node->line_number, 
                       expr ? (expr->datatype ? expr->datatype : "unknown") : "unknown",
                       type_node->datatype);
                
                // Validate cast compatibility
                if (expr && expr->datatype) {
                    if (!is_type_compatible(type_node->datatype, expr->datatype)) {
                        printf("Warning at line %d: Cast from '%s' to '%s' may lose precision or be invalid\n",
                               node->line_number, expr->datatype, type_node->datatype);
                    }
                    
                    // Check for invalid pointer casts
                    if ((type_node->is_pointer && !expr->is_pointer) || 
                        (!type_node->is_pointer && expr->is_pointer)) {
                        printf("Warning at line %d: Cast between pointer and non-pointer types\n",
                               node->line_number);
                    }
                    
                    // Check pointer depth compatibility
                    if (type_node->is_pointer && expr->is_pointer && 
                        type_node->pointer_depth != expr->pointer_depth) {
                        printf("Warning at line %d: Cast changes pointer depth from %d to %d\n",
                               node->line_number, expr->pointer_depth, type_node->pointer_depth);
                    }
                }
            }
            break;
        }

case NODE_IDENTIFIER: {
            printf("************* GOT IDENTIFIER" );

            if (!node->value) {
                printf("Semantic Error at line %d: Identifier has no name\n", node->line_number);
                break;
            }


            // Look up the identifier in the current scope
            semantic_info* info = find_in_scope(current_scope, node->value);


            if (!info) {
                printf("Semantic Error at line %d: Undeclared identifier '%s'\n",
                       node->line_number, node->value);

                // Create a placeholder to avoid cascading errors
                if (node->datatype) free(node->datatype);
                node->datatype = strdup("unknown");
                node->is_pointer = false;
                node->pointer_depth = 0;
                node->is_array = false;
                node->array_dimensions = 0;
                node->is_reference = false;
                node->is_parameter=false;
                node->is_function = false;
                node->param_count = 0;
                node->has_ellipsis = false;
                node->size = 0;
                node->is_const = false;
                node->is_static = false;
                node->is_unsigned = false;
                break;
            }

            if (info->isparam){
            printf("a function argument found \n");
            }
            // Copy ALL semantic information to the AST node
            if (node->datatype) free(node->datatype);
            node->datatype = info->type ? strdup(info->type) : NULL;

            // Copy basic type properties
            node->is_pointer = info->ispointer;
            node->pointer_depth = info->pointerdepth;
            node->is_array = info->isarray;
            node->is_reference = info->isref;
            node->is_function = info->isfunction;
            node->is_parameter = info->isparam;
            node->param_count = info->param_count;
            node->has_ellipsis = info->has_ellipsis;
            node->size = info->size;

            // Copy extended LLVM fields
            node->is_const = info->is_const;
            node->is_static = info->is_static;
            node->is_unsigned = info->is_unsigned;
            node->is_inline = info->is_inline;
            node->is_constexpr = info->is_constexpr;

            // Copy array information
            node->array_dimensions = info->array_dimensions;
            if (info->array_sizes && info->array_dimensions > 0) {
                node->array_sizes = (int*)malloc(info->array_dimensions * sizeof(int));
                memcpy(node->array_sizes, info->array_sizes, info->array_dimensions * sizeof(int));
            }

            // Copy struct information
            if (info->struct_name) {
                if (node->struct_name) free(node->struct_name);
                node->struct_name = strdup(info->struct_name);
            }

            printf("DEBUG: Identifier '%s' - type: %s, pointer: %d, array: %d, function: %d\n",
                   node->value, node->datatype, node->is_pointer, node->is_array, node->is_function);

            // Additional validation checks
            if (info->is_const && node->is_parameter) {
                printf("Warning at line %d: Parameter '%s' is const and cannot be modified\n",
                       node->line_number, node->value);
            }

            break;
        }

        // ==================== ARGUMENT LIST ====================
case NODE_ARG_LIST: {
            ASTNode* arg = node->child;
            int arg_count = 0;
            check_semantics(arg, parent_scope);
            while (arg) {
                arg_count++;
                arg = arg->next;
            }

            node->param_count = arg_count;

            break;
        }

        // ==================== PARAMETER LIST ====================
case NODE_PARAM_LIST: {
            ASTNode* param = node->child;
            int param_count = 0;
            bool has_varargs = false;
            check_semantics(param, parent_scope);
            while (param) {
                if (param->type == NODE_VAR_ARGS) {
                    has_varargs = true;
                    printf("DEBUG: Parameter list has variable arguments\n");
                } else {
                    param_count++;
                }
                param = param->next;
            }

            node->param_count = param_count;
            node->has_ellipsis = has_varargs;
            printf("DEBUG: Parameter list with %d parameters, varargs: %d\n",
                   param_count, has_varargs);
            break;
        }

        // ==================== VARIABLE ARGUMENTS ====================
case NODE_VAR_ARGS: {
            node->datatype = strdup("...");
            node->has_ellipsis = true;
            break;
        }


        // ==================== DECLARATOR ====================
case NODE_DECLARATOR: {

            // Declarators are handled in variable/function declarations
            // This case is for standalone declarator analysis
            if (node->child) {
                check_semantics(node->child, parent_scope);

                // Inherit type from child
                if (node->child->datatype) {
                    if (node->datatype) free(node->datatype);
                    node->datatype = strdup(node->child->datatype);
                    copy_llvm_fields(node, node->child);
                }
            }
            break;
        }

        // ==================== TYPE NODE ====================
        
case NODE_TYPE: {
            if (node->value) {
                if (node->datatype) free(node->datatype);
                node->datatype = strdup(node->value);

                // NEW: Enhanced type modifier detection for composite types
                node->is_static = (strstr(node->value, "static") != NULL);
                node->is_const = (strstr(node->value, "const") != NULL);
                node->is_unsigned = (strstr(node->value, "unsigned") != NULL);
                
                // Extract base type for size calculation
                char* base_type = node->value;
                if (node->is_static) {
                    // Skip "static " prefix for size calculation
                    base_type = strstr(node->value, "static ");
                    if (base_type) base_type += 7;
                    else base_type = node->value;
                }
                if (node->is_const) {
                    // Skip "const " prefix
                    char* const_pos = strstr(base_type, "const ");
                    if (const_pos) base_type = const_pos + 6;
                }
                if (node->is_unsigned) {
                    // Skip "unsigned " prefix  
                    char* unsigned_pos = strstr(base_type, "unsigned ");
                    if (unsigned_pos) base_type = unsigned_pos + 9;
                }

                // Set basic type properties using base_type
                if (strcmp(base_type, "void") == 0) {
                    node->size = 0;
                } else if (strcmp(base_type, "int") == 0) {
                    node->size = 4;
                } else if (strcmp(base_type, "float") == 0) {
                    node->size = 4;
                } else if (strcmp(base_type, "double") == 0) {
                    node->size = 8;
                } else if (strcmp(base_type, "char") == 0) {
                    node->size = 1;
                } else if (strcmp(base_type, "short") == 0) {
                    node->size = 2;
                } else if (strcmp(base_type, "long") == 0) {
                    node->size = 8;
                } else if (strcmp(base_type, "bool") == 0) {
                    node->size = 1;
                } else if (strstr(base_type, "struct") != NULL) {
                    // Struct size will be calculated during struct processing
                    node->size = 0;
                } else if (strcmp(base_type, "string") == 0) {
                    node->size = 8; // Pointer size
                    node->is_pointer = true;
                    node->pointer_depth = 1;
                } else if (strcmp(base_type, "auto") == 0) {
                    // Auto type - size determined later
                    node->size = 0;
                } else {
                    // Default size for unknown types
                    node->size = 4;
                }
                
                printf("DEBUG: Type node '%s' -> base_type '%s', size: %d, static: %d, const: %d, unsigned: %d\n",
                       node->value, base_type, node->size, node->is_static, node->is_const, node->is_unsigned);
            }
            break;
        }

        // ==================== EMPTY STATEMENT ====================
case NODE_EMPTY: {
            printf("DEBUG: Processing empty statement\n");
            node->datatype = strdup("void");
            node->size = 0;
            node->is_pointer = false;
            node->pointer_depth = 0;
            node->is_array = false;
            node->array_dimensions = 0;
            node->is_reference = false;
            node->is_function = false;
            node->param_count = 0;
            node->has_ellipsis = false;
            node->is_const = false;
            node->is_static = false;
            node->is_unsigned = false;
            break;
        }

        // ==================== LAMBDA RETURN ====================
case NODE_LAMBDA_RET: {

            if (node->child && node->child->type == NODE_TYPE) {
                check_semantics(node->child, parent_scope);

                // Set return type information
                if (node->child->datatype) {
                    if (node->datatype) free(node->datatype);
                    node->datatype = strdup(node->child->datatype);
                    copy_llvm_fields(node, node->child);
                }
            }
            break;
        }

        // ==================== ACCESS SPECIFIER ====================
case NODE_ACCESS_SPEC: {
            printf("DEBUG: Processing access specifier '%s'\n", node->value);
            // Access specifiers are mainly for C++ and don't affect type checking
            break;
        }

        // ==================== STATIC ASSERT ====================
case NODE_STATIC_ASSERT: {

            ASTNode* condition = node->child;
            ASTNode* message = condition ? condition->next : NULL;

            if (condition) check_semantics(condition, parent_scope);

            // Check that condition is a constant expression that evaluates to true
            if (condition && condition->datatype) {
                if (strcmp(condition->datatype, "bool") != 0) {
                    printf("Semantic Error at line %d: Static assertion condition must be boolean\n",
                           node->line_number);
                }
            }
            break;
        }

        // ==================== ATTRIBUTE EXPRESSION ====================
case NODE_ATTR_EXPR: {

            // Attributes don't affect type checking, just check the base expression
            if (node->child) {
                check_semantics(node->child, parent_scope);

                // Inherit type from child
                if (node->child->datatype) {
                    if (node->datatype) free(node->datatype);
                    node->datatype = strdup(node->child->datatype);
                    copy_llvm_fields(node, node->child);
                }
            }
            break;
        }

        // ==================== ATOMIC EXPRESSION ====================
case NODE_ATOMIC_EXPR: {

            if (node->child) {
                check_semantics(node->child, parent_scope);

                // Atomic expressions have the same type as their operand
                if (node->child->datatype) {
                    if (node->datatype) free(node->datatype);
                    node->datatype = strdup(node->child->datatype);
                    copy_llvm_fields(node, node->child);
                }
            }
            break;
        }

case NODE_VA_LIST: {
    printf("DEBUG: Processing va_list declaration\n");

    ASTNode* id_node = node->child;
    if (id_node && id_node->type == NODE_IDENTIFIER) {
        char* identifier = id_node->value;

        // Check for redeclaration
        semantic_info* existing = find_in_scope(current_scope, identifier);
        if (existing) {
            printf("Semantic Error at line %d: Redeclaration of '%s'\n", node->line_number, identifier);
            return;
        }

        // Validate va_list usage context
        validate_va_list_usage(node, current_scope, node->line_number);

        // Create semantic info for va_list
        semantic_info* va_info = create_semantic_info(
            "va_list", identifier, false, true, false, false,
            1, false, 0, false
        );

        // Set va_list specific properties
        va_info->size = 24; // Typical va_list size (platform dependent)
        va_info->is_const = false;
        va_info->is_volatile = true; // va_list should be treated as volatile

        // Add to scope
        if (!current_scope) {
            current_scope = va_info;
            *parent_scope = current_scope;
        } else {
            semantic_info* last = current_scope;
            while (last->next) last = last->next;
            last->next = va_info;
            va_info->prev = last;
        }

        // Set AST node properties for LLVM IR generation
        node->datatype = strdup("va_list");
        node->is_pointer = true;
        node->pointer_depth = 1;
        node->size = 24; // Platform-dependent va_list size
        node->is_volatile = true;

        printf("DEBUG: va_list '%s' declared at line %d\n", identifier, node->line_number);
    } else {
        printf("Semantic Error at line %d: va_list missing identifier\n", node->line_number);
    }
    break;
}

case NODE_VA_START: {
    printf("DEBUG: Processing va_start\n");

    ASTNode* va_list_node = node->child;
    ASTNode* last_param_node = va_list_node ? va_list_node->next : NULL;

    if (!va_list_node || !last_param_node) {
        printf("Semantic Error at line %d: va_start requires two arguments\n", node->line_number);
        break;
    }

    // Check semantics of arguments
    check_semantics(va_list_node, parent_scope);
    check_semantics(last_param_node, parent_scope);

    // Validate va_list argument
    if (va_list_node->type != NODE_IDENTIFIER) {
        printf("Semantic Error at line %d: va_start first argument must be a va_list identifier\n",
               node->line_number);
    } else {
        semantic_info* va_info = find_in_scope(current_scope, va_list_node->value);
        if (!va_info || strcmp(va_info->type, "va_list") != 0) {
            printf("Semantic Error at line %d: va_start first argument must be a va_list\n",
                   node->line_number);
        }
    }

    // Validate last parameter argument
    if (last_param_node->type != NODE_IDENTIFIER) {
        printf("Semantic Error at line %d: va_start second argument must be an identifier\n",
               node->line_number);
    } else {
        // Find the current function
        semantic_info* current_func = NULL;
        semantic_info* temp_scope = current_scope;
        while (temp_scope) {
            if (temp_scope->isfunction) {
                current_func = temp_scope;
                break;
            }
            temp_scope = temp_scope->next;
        }

        if (current_func) {
            char* last_param = get_last_named_parameter(current_func);
            if (!last_param || strcmp(last_param_node->value, last_param) != 0) {
                printf("Semantic Error at line %d: va_start second argument must be the last named parameter\n",
                       node->line_number);
                if (last_param) {
                    printf("  Expected '%s', got '%s'\n", last_param, last_param_node->value);
                }
            }
        }
    }

    // Validate context
    validate_va_list_usage(node, current_scope, node->line_number);

    // Set node properties for LLVM IR
    node->datatype = strdup("void");
    node->size = 0;
    node->is_function = true; // Treated as function call for IR generation

    printf("DEBUG: va_start processed at line %d\n", node->line_number);
    break;
}

case NODE_VA_ARG: {
    printf("DEBUG: Processing va_arg\n");

    ASTNode* va_list_node = node->child;
    ASTNode* type_node = va_list_node ? va_list_node->next : NULL;

    if (!va_list_node || !type_node) {
        printf("Semantic Error at line %d: va_arg requires two arguments\n", node->line_number);
        break;
    }

    // Check semantics of arguments
    check_semantics(va_list_node, parent_scope);
    check_semantics(type_node, parent_scope);

    // Validate va_list argument
    if (va_list_node->type != NODE_IDENTIFIER) {
        printf("Semantic Error at line %d: va_arg first argument must be a va_list identifier\n",
               node->line_number);
    } else {
        semantic_info* va_info = find_in_scope(current_scope, va_list_node->value);
        if (!va_info || strcmp(va_info->type, "va_list") != 0) {
            printf("Semantic Error at line %d: va_arg first argument must be a va_list\n",
                   node->line_number);
        }
    }

    // Validate type argument
    if (type_node->type != NODE_TYPE && type_node->type != NODE_VA_LIST_TYPE) {
        printf("Semantic Error at line %d: va_arg second argument must be a type\n",
               node->line_number);
    } else if (type_node->datatype) {
        if (!is_valid_va_arg_type(type_node->datatype)) {
            printf("Semantic Warning at line %d: Type '%s' may not work properly with va_arg\n",
                   node->line_number, type_node->datatype);
        }
    }

    // Validate context
    validate_va_list_usage(node, current_scope, node->line_number);

    // Set node properties for LLVM IR generation
    if (type_node->datatype) {
        node->datatype = strdup(type_node->datatype);
        // Copy LLVM fields from type node
        copy_llvm_fields(node, type_node);

        // For va_arg, the result is an rvalue, not a pointer
        node->is_pointer = false;
        node->pointer_depth = 0;
    } else {
        node->datatype = strdup("int"); // Default type
    }

    node->is_function = true; // Treated as function call for IR generation

    printf("DEBUG: va_arg returns type '%s' at line %d\n", node->datatype, node->line_number);
    break;
}

case NODE_VA_END: {
    printf("DEBUG: Processing va_end\n");

    ASTNode* va_list_node = node->child;

    if (!va_list_node) {
        printf("Semantic Error at line %d: va_end requires one argument\n", node->line_number);
        break;
    }

    // Check semantics of argument
    check_semantics(va_list_node, parent_scope);

    // Validate va_list argument
    if (va_list_node->type != NODE_IDENTIFIER) {
        printf("Semantic Error at line %d: va_end argument must be a va_list identifier\n",
               node->line_number);
    } else {
        semantic_info* va_info = find_in_scope(current_scope, va_list_node->value);
        if (!va_info || strcmp(va_info->type, "va_list") != 0) {
            printf("Semantic Error at line %d: va_end argument must be a va_list\n",
                   node->line_number);
        }
    }

    // Validate context
    validate_va_list_usage(node, current_scope, node->line_number);

    // Set node properties for LLVM IR
    node->datatype = strdup("void");
    node->size = 0;
    node->is_function = true; // Treated as function call for IR generation

    printf("DEBUG: va_end processed at line %d\n", node->line_number);
    break;
}

case NODE_VA_LIST_TYPE: {
    printf("DEBUG: Processing va_list type\n");

    if (node->value) {
        if (node->datatype) free(node->datatype);
        node->datatype = strdup("va_list");

        // Set va_list type properties for LLVM IR
        node->is_pointer = true;
        node->pointer_depth = 1;
        node->size = 24; // Platform-dependent va_list size
        node->is_volatile = true;
        node->is_const = false;
    }
    break;
}

        // Handle other node types with default recursive checking


     default:
            // Recursively check all children for other node types
            ASTNode* child = node->child;

                check_semantics(child, parent_scope);

            break;
    }

    // Remove the last added node from scope when returning (for local scopes)
    if (node->type == NODE_COMPOUND_STMT || node->type == NODE_FUNCTION_DEF || node->type == NODE_FUNCTION_DECL
        || node->type == NODE_FOR_STMT || node->type == NODE_RANGE_FOR_STMT) {
        if (scope_start_ptr && scope_start_ptr->prev) {
            // Only free if this is actually a local scope node, not a global one
            semantic_info* to_free = scope_start_ptr;
            scope_start_ptr->prev->next = NULL;
            // Don't free if this might be part of the global scope
            if (to_free != *parent_scope) {
                free_semantic_info(to_free);
            }
        } else if (scope_start_ptr && scope_start_ptr == current_scope) {
            // Only reset parent scope if we're sure this is a local scope
            if (scope_start_ptr != *parent_scope) {
                *parent_scope = NULL;
                free_semantic_info(scope_start_ptr);
            }
        }
    }
    // Continue with siblings using the original scope (not modified by this node)
    if (node->next) {
        check_semantics(node->next, parent_scope);
    }
}

/* ==================== AST PRINTING FUNCTIONS ==================== */

void print_ast(ASTNode *node, int depth) {
    if (!node) return;

    for (int i = 0; i < depth; i++) printf("  ");

    printf("%s", node_type_to_string(node->type));

    if (node->value) printf(" [%s]", node->value);
    if (node->op) printf(" (op: %s)", node->op);
    if (node->datatype) printf(" <type: %s>", node->datatype);

    // Print LLVM-specific fields with dimension and size information
    if (node->is_array||node->type==NODE_INDEX) {
        printf(" [array:%dD", node->array_dimensions);
        if (node->array_sizes && node->array_dimensions > 0) {
            printf(" sizes:[");
            for (int i = 0; i < node->array_dimensions; i++) {
                printf("%d", node->array_sizes[i]);
                if (i < node->array_dimensions - 1) printf(",");
            }
            printf("]");
        }
        printf("]");
    }

    // Print initializer list dimensions if present
    if (node->type == NODE_INIT_LIST) {
        printf(" [init_dims:%d", node->init_list_dimentions);
        if (node->init_list_sizes) {
            printf(" init_sizes:[");
            for (int i = 0; i < node->init_list_dimentions; i++) {
                printf("%d", node->init_list_sizes[i]);
                if (i < node->init_list_dimentions - 1) printf(",");
            }
            printf("]");
        }
        printf("]");
    }

    if (node->is_pointer) printf(" [ptr:%d]", node->pointer_depth);
    if (node->is_reference) printf(" [ref]");
    if (node->is_function) printf(" [func:%d params]", node->param_count);
    if (node->size > 0) printf(" [size:%d]", node->size);

    printf(" (line %d)\n", node->line_number);

    print_ast(node->child, depth + 1);
    print_ast(node->left, depth + 1);
    print_ast(node->right, depth + 1);
    print_ast(node->next, depth);
}


void free_ast(ASTNode *node) {
    if (!node) return;

    free_ast(node->child);
    free_ast(node->left);
    free_ast(node->right);
    free_ast(node->next);

    if (node->value) free(node->value);
    if (node->op) free(node->op);
    if (node->datatype && strcmp(node->datatype, "unknown") != 0) free(node->datatype);
    if (node->array_sizes) free(node->array_sizes);
    if (node->struct_name) free(node->struct_name);
    free(node);
}

/* ==================== GLOBAL AST ROOT ==================== */

ASTNode *ast_root = NULL;


/* ==================== LLVM IR GENERATION STRUCTURES ==================== */

typedef struct {
    char* name;
    int is_static;
    char* datatype;  // Added: store variable type
    int is_array;
    int array_dimensions;
    int* array_sizes;
    int is_pointer;
    int pointer_depth;
    int size;
    char* llvm_type;
    // other info like type, scope, etc.
} SymbolEntry;

SymbolEntry symbol_table[1000];
int symbol_count = 0;

/* ==================== IR STORAGE DATA STRUCTURES ==================== */

typedef struct {
    char* ir_line;
    int line_number;
} IRLines;

typedef struct {
    char* ir_line;
    int line_number;
} GlobalIRLine;

// Storage for different types of IR
GlobalIRLine global_ir_lines[10000];
IRLines function_ir_lines[10000];
IRLines other_ir_lines[10000];

int global_ir_count = 0;
int function_ir_count = 0;
int other_ir_count = 0;

// Flag to track if we're in global scope collection mode
int collecting_global_ir = 0;

/* ==================== STRING CONSTANT COLLECTION ==================== */

typedef struct {
    char* name;
    char* content;
    int length;
} StringConstant;

StringConstant string_constants[1000];
int string_const_count = 0;

void add_string_constant(char* name, char* content, int length) {
    string_constants[string_const_count].name = strdup(name);
    string_constants[string_const_count].content = strdup(content);
    string_constants[string_const_count].length = length;
    string_const_count++;
}

void emit_string_constants() {
    // Set flag to ensure these go to global storage
    int old_collecting_flag = collecting_global_ir;
    collecting_global_ir = 1;

    for (int i = 0; i < string_const_count; i++) {
        StringConstant* str_const = &string_constants[i];
        emit_llvm_ir("@%s = private unnamed_addr constant [%d x i8] c\"%s\\00\"",
                     str_const->name, str_const->length, str_const->content);
    }

    // Restore the original collecting flag
    collecting_global_ir = old_collecting_flag;
}

// Helper function to generate unique string constant names
char* generate_string_constant_name() {
    static int string_counter = 0;
    char* name = malloc(32);
    sprintf(name, ".str%d", string_counter++);
    return strdup(name);
}

// Helper function to generate unique format string names
char* generate_format_string_name() {
    static int format_counter = 0;
    char* name = malloc(32);
    sprintf(name, ".io_format_%d", format_counter++);
    return strdup(name);
}




void add_symbol(char* name, int is_static) {
    symbol_table[symbol_count].name = strdup(name);
    symbol_table[symbol_count].is_static = is_static;
    symbol_table[symbol_count].datatype = NULL;
    symbol_table[symbol_count].is_array = 0;
    symbol_table[symbol_count].array_dimensions = 0;
    symbol_table[symbol_count].array_sizes = NULL;
    symbol_table[symbol_count].is_pointer = 0;
    symbol_table[symbol_count].pointer_depth = 0;
    symbol_count++;
}

void add_symbol_with_type(char* name, int is_static, char* datatype, int is_array, int array_dimensions, int* array_sizes, int is_pointer, int pointer_depth) {
    symbol_table[symbol_count].name = strdup(name);
    symbol_table[symbol_count].is_static = is_static;
    symbol_table[symbol_count].datatype = datatype ? strdup(datatype) : NULL;
    symbol_table[symbol_count].is_array = is_array;
    symbol_table[symbol_count].array_dimensions = array_dimensions;


     if (strcmp(datatype, "va_list") == 0) {
            // va_list is treated as i8* in LLVM
            symbol_table[symbol_count].llvm_type = strdup("i8*");
            symbol_table[symbol_count].is_pointer = 1;
            symbol_table[symbol_count].pointer_depth = 1;
            symbol_table[symbol_count].size = 8; // Pointer size
        }



    if (array_sizes && array_dimensions > 0) {
        symbol_table[symbol_count].array_sizes = malloc(array_dimensions * sizeof(int));
        for (int i = 0; i < array_dimensions; i++) {
            symbol_table[symbol_count].array_sizes[i] = array_sizes[i];
        }
    } else {
        symbol_table[symbol_count].array_sizes = NULL;
    }


    symbol_table[symbol_count].is_pointer = is_pointer;
    symbol_table[symbol_count].pointer_depth = pointer_depth;
    symbol_count++;
}

int is_static_variable(char* name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].is_static;
        }
    }
    return 0; // Default to non-static
}

SymbolEntry* find_symbol(char* name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return &symbol_table[i];
        }
    }
    return NULL;
}

/* ==================== VA_LIST HANDLING ==================== */

typedef struct {
    char* va_list_name;
    char* function_name;
    int va_list_counter;
} VAListInfo;

VAListInfo va_list_stack[100];
int va_list_stack_top = -1;

// Push va_list info onto stack
void push_va_list(char* va_list_name, char* function_name) {
    va_list_stack_top++;
    va_list_stack[va_list_stack_top].va_list_name = strdup(va_list_name);
    va_list_stack[va_list_stack_top].function_name = strdup(function_name);
    va_list_stack[va_list_stack_top].va_list_counter = 0;
}

// Pop va_list info from stack
void pop_va_list() {
    if (va_list_stack_top >= 0) {
        free(va_list_stack[va_list_stack_top].va_list_name);
        free(va_list_stack[va_list_stack_top].function_name);
        va_list_stack_top--;
    }
}

// Get current va_list info
VAListInfo* get_current_va_list() {
    if (va_list_stack_top >= 0) {
        return &va_list_stack[va_list_stack_top];
    }
    return NULL;
}

// Generate unique name for va_list variable
char* generate_va_list_name() {
    static int va_list_counter = 0;
    char* name = malloc(32);
    sprintf(name, "%%va_list_%d", va_list_counter++);
    return strdup(name);
}




// Add to your global variables section
typedef struct {
    char* func_name;
    int is_varargs;
    char* return_type;
} FunctionInfo;

FunctionInfo function_table[100];
int function_count = 0;

void add_function_info(char* name, int is_varargs) {
    function_table[function_count].func_name = strdup(name);
    function_table[function_count].is_varargs = is_varargs;
    function_table[function_count].return_type = strdup("i32"); // Default
    function_count++;
}

void add_function_info_with_type(char* name, int is_varargs, char* return_type) {
    function_table[function_count].func_name = strdup(name);
    function_table[function_count].is_varargs = is_varargs;
    function_table[function_count].return_type = return_type ? strdup(return_type) : strdup("i32");
    function_count++;
}

int is_varargs_function(char* name) {
    for (int i = 0; i < function_count; i++) {
        if (strcmp(function_table[i].func_name, name) == 0) {
            return function_table[i].is_varargs;
        }
    }
    return 0; // Default to non-varargs
}

FunctionInfo* find_function_info(char* name) {
    for (int i = 0; i < function_count; i++) {
        if (strcmp(function_table[i].func_name, name) == 0) {
            return &function_table[i];
        }
    }
    return NULL;
}

ASTNode* create_ast_node(NodeType type, int line, char *value);
ASTNode* create_binary_node(NodeType type, int line, char *op, ASTNode *left, ASTNode *right);
ASTNode* create_unary_node(NodeType type, int line, char *op, ASTNode *operand);
ASTNode* create_ternary_node(int line, ASTNode *cond, ASTNode *then_expr, ASTNode *else_expr);
void ast_add_child(ASTNode *parent, ASTNode *child);
void ast_add_sibling(ASTNode *first, ASTNode *sibling);
void print_ast(ASTNode *node, int depth);
void free_ast(ASTNode *node);
const char* node_type_to_string(NodeType type);
char* generate_temp();
char* generate_label();
void emit_llvm_ir(char* format, ...);
char* load_variable_if_needed(ASTNode* node, char* name);
char* find_parameter_name(ASTNode* param_node);
char* generate_llvm_ir_from_ast(ASTNode* node);
void print_llvm_ir(ASTNode* ast_root);
void free_llvm_ir();
int is_main_function(ASTNode* node);
void allocate_parameters(ASTNode* params_node);
char* generate_lambda_call(ASTNode* lambda_ptr, ASTNode* args_node);
int ends_with_unconditional_branch(ASTNode* node);
char* get_literal_value_for_llvm(ASTNode* node);
char* get_complete_llvm_type(ASTNode* node);
char* get_llvm_base_type(char* datatype);
/* ==================== LLVM IR GENERATION FUNCTIONS ==================== */

int has_main_function = 0;
int temp_counter = 0;
int label_counter = 0;
char current_function[64] = "";
char* current_break_label = NULL;
char* current_continue_label = NULL;
char* generate_temp() {
    char buffer[16];
    sprintf(buffer, "%%t%d", temp_counter++);
    return strdup(buffer);  // Clear ownership transfer
}

char* generate_label() {
    char* label = malloc(16);
    sprintf(label, "L%d", label_counter++);
    return strdup(label);
}

void emit_llvm_ir(char* format, ...) {
    va_list args;
    char buffer[1024];

    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    // Store the IR line in the appropriate storage
    if (collecting_global_ir) {
        // Store global declarations and string constants
        global_ir_lines[global_ir_count].ir_line = strdup(buffer);
        global_ir_lines[global_ir_count].line_number = global_ir_count;
        global_ir_count++;
    } else if (strcmp(current_function, "") != 0) {
        // Store function definitions
        function_ir_lines[function_ir_count].ir_line = strdup(buffer);
        function_ir_lines[function_ir_count].line_number = function_ir_count;
        function_ir_count++;
    } else {
        // Store other IR (typedefs, declarations, etc.)
        other_ir_lines[other_ir_count].ir_line = strdup(buffer);
        other_ir_lines[other_ir_count].line_number = other_ir_count;
        other_ir_count++;
    }
}


// Generate unique name for va_arg temp
char* generate_va_arg_temp() {
    VAListInfo* va_info = get_current_va_list();
    if (va_info) {
        char* name = malloc(32);
        sprintf(name, "%%va_arg_%d_%d", va_info->va_list_counter++, va_list_stack_top);
        return name;
    }
    return generate_temp();
}


// Helper function to convert C type string to LLVM type
char* get_llvm_type_from_semantic_for_type(char* datatype) {
    if (!datatype) return "i32";

    if (strcmp(datatype, "int") == 0 ||
        strcmp(datatype, "unsigned int")||
        strcmp(datatype, "static int") == 0) {
        return "i32";
    }

    else if (strcmp(datatype, "float") == 0||
    strcmp(datatype, "static float")) {
        return "float";
    }
    else if (strcmp(datatype, "double") == 0 || strcmp(datatype, "static double")) {
        return "double";
    }else if (strcmp(datatype, "long") == 0||
    strcmp(datatype, "long long") == 0||
    strcmp(datatype, "long int") == 0
    ) {
        return "i64";
    }

    else if (strcmp(datatype, "char") == 0 ||
             strcmp(datatype, "unsigned char") == 0) {
        return "i8";
    }
    else if (strcmp(datatype, "bool") == 0) {
        return "i1";
    }
    else if (strcmp(datatype, "short") == 0) {
        return "i16";
    }
    else if (strcmp(datatype, "void") == 0) {
        return "void";
    }
    else if (strcmp(datatype, "string") == 0 ||
             strcmp(datatype, "char*") == 0 ||
             (datatype && strstr(datatype, "char*") != NULL)) {
        return "i8*";
    }
    else {
        return "i32"; // Default fallback
    }
}


/* ==================== GLOBAL VARIABLE COLLECTION ==================== */

typedef struct {
    char* name;
    char* datatype;
    int is_static;
    int is_array;
    int array_dimensions;
    int* array_sizes;
    int is_pointer;
    int pointer_depth;
    char* init_value;
} GlobalDeclaration;

GlobalDeclaration global_declarations[1000];
int global_decl_count = 0;

void add_global_declaration(char* name, char* datatype, int is_static, int is_array,
                           int array_dimensions, int* array_sizes, int is_pointer,
                           int pointer_depth, char* init_value) {
    global_declarations[global_decl_count].name = strdup(name);
    global_declarations[global_decl_count].datatype = datatype ? strdup(datatype) : NULL;
    global_declarations[global_decl_count].is_static = is_static;
    global_declarations[global_decl_count].is_array = is_array;
    global_declarations[global_decl_count].array_dimensions = array_dimensions;

    if (array_sizes && array_dimensions > 0) {
        global_declarations[global_decl_count].array_sizes = malloc(array_dimensions * sizeof(int));
        for (int i = 0; i < array_dimensions; i++) {
            global_declarations[global_decl_count].array_sizes[i] = array_sizes[i];
        }
    } else {
        global_declarations[global_decl_count].array_sizes = NULL;
    }

    global_declarations[global_decl_count].is_pointer = is_pointer;
    global_declarations[global_decl_count].pointer_depth = pointer_depth;
    global_declarations[global_decl_count].init_value = init_value ? strdup(init_value) : NULL;

    global_decl_count++;
}

char* get_complete_llvm_type_for_global(GlobalDeclaration* decl) {
    static char type_str[512];

    if (decl->is_array && decl->array_dimensions > 0) {
        char base_type[32];

        // Get base type from datatype
        if (decl->datatype) {
            if (strcmp(decl->datatype, "int") == 0 ||strcmp(decl->datatype, "unsigned int") == 0 || strcmp(decl->datatype, "static int") == 0 ) strcpy(base_type, "i32");
            else if (strcmp(decl->datatype, "float") == 0  || strcmp(decl->datatype, "static float") == 0) strcpy(base_type, "float");
            else if (strcmp(decl->datatype, "double") == 0 || strcmp(decl->datatype, "static double") == 0) strcpy(base_type, "double");
            else if (strcmp(decl->datatype, "char") == 0 || strcmp(decl->datatype, "unsigned char") == 0) strcpy(base_type, "i8");
            else if(strcmp(decl->datatype, "long") == 0 || strcmp(decl->datatype, "long long") == 0 || strcmp(decl->datatype, "long int") == 0 || strcmp(decl->datatype, "static long") == 0) strcpy(base_type, "i64");
            else if (strcmp(decl->datatype, "bool") == 0) strcpy(base_type, "i1");
            else if (strcmp(decl->datatype, "short") == 0) strcpy(base_type, "i16");
            else if (strcmp(decl->datatype, "string") == 0 || strcmp(decl->datatype, "char*") == 0) strcpy(base_type, "i8*");
            else strcpy(base_type, "i32");
        } else {
            strcpy(base_type, "i32");
        }

        // Build array type from innermost to outermost
        char temp[512];
        if (decl->array_sizes && decl->array_dimensions > 0 && decl->array_sizes[0] > 0) {
            sprintf(temp, "[%d x %s]", decl->array_sizes[decl->array_dimensions-1], base_type);

            for (int i = decl->array_dimensions-2; i >= 0; i--) {
                char new_temp[512];
                sprintf(new_temp, "[%d x %s]", decl->array_sizes[i], temp);
                strcpy(temp, new_temp);
            }
        } else {
            sprintf(temp, "%s*", base_type);
        }

        strcpy(type_str, temp);
    } else {
        // Scalar type
        if (decl->datatype) {
            if (strcmp(decl->datatype, "int") == 0) strcpy(type_str, "i32");
            else if (strcmp(decl->datatype, "float") == 0  || strcmp(decl->datatype, "static float") == 0) strcpy(type_str, "float");
            else if (strcmp(decl->datatype, "double") == 0 || strcmp(decl->datatype, "static double") == 0) strcpy(type_str, "double");
            else if (strcmp(decl->datatype, "char") == 0 || strcmp(decl->datatype, "unsigned char") == 0) strcpy(type_str, "i8");
            else if (strcmp(decl->datatype, "void") == 0) strcpy(type_str, "void");
            else if (strcmp(decl->datatype, "bool") == 0) strcpy(type_str, "i1");
            else if (strcmp(decl->datatype, "short") == 0) strcpy(type_str, "i16");
            else if(strcmp(decl->datatype, "long") == 0 || strcmp(decl->datatype, "long long") == 0 || strcmp(decl->datatype, "long int") == 0) strcpy(type_str, "i64");
            else if (strcmp(decl->datatype, "string") == 0 || strcmp(decl->datatype, "char*") == 0) strcpy(type_str, "i8*");
            else strcpy(type_str, "i32");
        } else {
            strcpy(type_str, "i32");
        }
    }

    return type_str;
}

char * get_alignment_str(char * llvm_type){
    if(!llvm_type) return "align 4"; // Default fallback
    
    // Handle scalar types
    if(strcmp(llvm_type,"i1")==0) return "align 1";
    else if(strcmp(llvm_type,"i8")==0) return "align 1";
    else if(strcmp(llvm_type,"i16")==0) return "align 2";
    else if(strcmp(llvm_type,"i32")==0) return "align 4";
    else if(strcmp(llvm_type,"i64")==0) return "align 8";
    else if(strcmp(llvm_type,"float")==0) return "align 4";
    else if(strcmp(llvm_type,"double")==0) return "align 8";
    
    // Handle pointer types (depth 1)
    else if(strcmp(llvm_type,"i1*")==0) return "align 8";
    else if(strcmp(llvm_type,"i8*")==0) return "align 8";
    else if(strcmp(llvm_type,"i16*")==0) return "align 8";
    else if(strcmp(llvm_type,"i32*")==0) return "align 8";
    else if(strcmp(llvm_type,"i64*")==0) return "align 8";
    else if(strcmp(llvm_type,"float*")==0) return "align 8";
    else if(strcmp(llvm_type,"double*")==0) return "align 8";
    
    // Handle pointer-to-pointer types (depth 2)
    else if(strcmp(llvm_type,"i1**")==0) return "align 8";
    else if(strcmp(llvm_type,"i8**")==0) return "align 8";
    else if(strcmp(llvm_type,"i16**")==0) return "align 8";
    else if(strcmp(llvm_type,"i32**")==0) return "align 8";
    else if(strcmp(llvm_type,"i64**")==0) return "align 8";
    else if(strcmp(llvm_type,"float**")==0) return "align 8";
    else if(strcmp(llvm_type,"double**")==0) return "align 8";
    
    // Handle array types (common cases)
    else if(strstr(llvm_type, "[") != NULL) {
        // For arrays, use the alignment of the base type
        if(strstr(llvm_type, "i8") != NULL) return "align 1";
        else if(strstr(llvm_type, "i16") != NULL) return "align 2";
        else if(strstr(llvm_type, "i32") != NULL) return "align 4";
        else if(strstr(llvm_type, "i64") != NULL) return "align 8";
        else if(strstr(llvm_type, "float") != NULL) return "align 4";
        else if(strstr(llvm_type, "double") != NULL) return "align 8";
    }
    
    // Generic pointer detection - if type ends with '*'
    int len = strlen(llvm_type);
    if(len > 0 && llvm_type[len-1] == '*') {
        return "align 8"; // All pointers get 8-byte alignment
    }

    return "align 4"; // Default fallback for unknown types
}

void emit_global_declarations() {
    // Set flag to ensure these go to global storage
    int old_collecting_flag = collecting_global_ir;
    collecting_global_ir = 1;

    for (int i = 0; i < global_decl_count; i++) {
        GlobalDeclaration* decl = &global_declarations[i];
        char* llvm_type = get_complete_llvm_type(decl);
        char* base_llvm_type=strdup(llvm_type);

        if(decl->is_array){
            base_llvm_type=get_llvm_base_type(decl->datatype);
        }

        char * align_str=get_alignment_str(strdup(base_llvm_type));

        // Handle arrays
        if (decl->is_array && decl->array_dimensions > 0) {
            llvm_type = get_complete_llvm_type_for_global(decl);
        }

        // Handle pointers
        if (decl->is_pointer && decl->pointer_depth > 0) {
            char temp_type[256];
            strcpy(temp_type, llvm_type);
            for (int j = 0; j < decl->pointer_depth; j++) {
                char new_type[256];
                sprintf(new_type, "%s*", temp_type);
                strcpy(temp_type, new_type);
            }
            llvm_type = strdup(temp_type);
        }

        // Emit the global declaration (will be stored in global_ir_lines)
        if (decl->init_value) {
            if (strcmp(decl->datatype, "string") == 0 || strcmp(decl->datatype, "char*") == 0) {
                emit_llvm_ir("@%s = global i8* %s, align 8", decl->name, decl->init_value);
            } else {
                emit_llvm_ir("@%s = global %s %s, %s", decl->name, llvm_type, decl->init_value,align_str);
            }
        } else {
            if (strcmp(decl->datatype, "string") == 0 || strcmp(decl->datatype, "char*") == 0) {
                emit_llvm_ir("@%s = global i8* null, align 8", decl->name);
            } else {
                emit_llvm_ir("@%s = global %s zeroinitializer, %s", decl->name, llvm_type,align_str);
            }
        }

        // Add to symbol table as global
        add_symbol_with_type(decl->name, 1, decl->datatype, decl->is_array,
                           decl->array_dimensions, decl->array_sizes,
                           decl->is_pointer, decl->pointer_depth);
    }

    // Restore the original collecting flag
    collecting_global_ir = old_collecting_flag;
}

int is_global_scope() {
    return strcmp(current_function, "") == 0;
}

// Helper function to get format specifier for a node
char* get_format_specifier_for_node(ASTNode* node) {
    if (!node) return "%d"; // default

    //char* llvm_type = get_complete_llvm_type(node);

    if (strcmp(node->datatype, "int") == 0 || strcmp(node->datatype, "static int") == 0) return "%d";
    else if (strcmp(node->datatype, "unsigned int") == 0) return "%u";
    else if (strcmp(node->datatype, "short") == 0) return "%hd";
    else if (strcmp(node->datatype, "unsigned short") == 0) return "%hu";
    else if (strcmp(node->datatype, "long") == 0 || strcmp(node->datatype, "long int") == 0) return "%ld";
    else if (strcmp(node->datatype, "long long") == 0) return "%lld";

    else if (strcmp(node->datatype, "float") == 0|| strcmp(node->datatype, "static float") == 0) return "%f";
    else if (strcmp(node->datatype, "double") == 0 || strcmp(node->datatype, "static double") == 0) return "%lf";
    else if (strcmp(node->datatype, "char") == 0) return "%c";
    else if (strcmp(node->datatype, "unsigned char") == 0) return "%c";

    else if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) return "%s";
    else if (strcmp(node->datatype, "void*") == 0) return "%p";
    else if (strcmp(node->datatype, "bool") == 0) return "%d"; // bool as int
    else return "%d"; // default
}

// Helper function to generate format string for multiple arguments
char* generate_format_string_for_arguments(ASTNode* args_node) {
    if (!args_node || args_node->type != NODE_ARG_LIST || !args_node->child) {
        return strdup("");
    }

    char format_str[1024] = "";
    ASTNode* arg = args_node->child;
    int first = 1;

    while (arg) {
        if (!first) strcat(format_str, " ");

        char* specifier = get_format_specifier_for_node(arg);
        strcat(format_str, specifier);

        first = 0;
        arg = arg->next;
    }

    return strdup(format_str);
}

// Helper function to convert value to appropriate type for I/O
char* convert_value_for_io(char* value, char* from_type, char* to_type) {
    if (!value || !from_type || !to_type) return value;

    // If types match, no conversion needed
    if (strcmp(from_type, to_type) == 0) return value;

    char* result = generate_temp();

    // Handle boolean to integer conversion
    if (value[0] == '!' && strcmp(to_type, "i32") == 0) {
        emit_llvm_ir("  %s = zext i1 %s to i32", result, value + 1);
        return strdup(result);
    }

    // Handle integer to float conversion
    if (strcmp(from_type, "i32") == 0 && strcmp(to_type, "float") == 0) {
        emit_llvm_ir("  %s = sitofp i32 %s to float", result, value);
        return strdup(result);
    }

    // Handle float to double conversion
    if (strcmp(from_type, "float") == 0 && strcmp(to_type, "double") == 0) {
        emit_llvm_ir("  %s = fpext float %s to double", result, value);
        return strdup(result);
    }

    // Handle double to float conversion
    if (strcmp(from_type, "double") == 0 && strcmp(to_type, "float") == 0) {
        emit_llvm_ir("  %s = fptrunc double %s to float", result, value);
        return strdup(result);
    }

    // Default: no conversion
    return value;
}

// Enhanced string literal processing
char* process_string_literal_for_io(ASTNode* node) {
    if (!node || node->type != NODE_LITERAL) return NULL;

    if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
        return get_literal_value_for_llvm(node);
    }
    return NULL;
}

// Helper function to handle array/pointer arguments for I/O
char* handle_array_pointer_for_io(ASTNode* node) {
    if (!node) return NULL;

    // Handle string literals


    // Handle string variables

    // Handle pointer dereference for strings
    if (node->type == NODE_UNARY_OP && strcmp(node->op, "*") == 0) {
        ASTNode* operand = node->left;
        if (operand && operand->datatype &&
            (strstr(operand->datatype, "char*") != NULL || strstr(operand->datatype, "string") != NULL)) {
            return generate_llvm_ir_from_ast(operand);
        }
    }

    return NULL;
}

// In the array/pointer handling section, add support for array element access
char* handle_array_element_for_io(ASTNode* node,char * element_value) {
    if (!node || node->type != NODE_INDEX) return NULL;



    // Generate the code to get the array element value

    if (!element_value) return NULL;

    // For character arrays, we might need to handle individual characters
    ASTNode* base_array = node->child;
    while(base_array&&base_array->type==NODE_INDEX)base_array=base_array->child;
    if (base_array && base_array->type == NODE_IDENTIFIER) {
        SymbolEntry* symbol = find_symbol(base_array->value);
        if (symbol && strcmp(symbol->datatype, "char") == 0) {
            // Character array element - promote to i32 for printf
            char* promoted = generate_temp();
            emit_llvm_ir("  %s = zext i8 %s to i32", promoted, element_value);
            free(element_value);
            return promoted;
        }
    }

    return element_value;
}

// Enhanced helper function to load a variable value if it's an identifier
char* load_variable_if_needed(ASTNode* node, char* name) {
    if (node->type == NODE_IDENTIFIER) {
        char* result = generate_temp();
        char* llvm_type = get_complete_llvm_type(node);
        char* base_llvm_type=strdup(llvm_type);

        if(node->is_array){
            base_llvm_type=get_llvm_base_type(node->datatype);
        }


        // Check if this is a static/global variable
        SymbolEntry* symbol = find_symbol(name);
        SymbolEntry* symbol2=find_symbol(strcat(strcat(current_function,"."),name));
        if (symbol && symbol->is_static) {
            emit_llvm_ir("  %s = load %s, %s* @%s, %s", result, llvm_type, llvm_type, name,get_alignment_str(base_llvm_type));
        } else if(symbol2&&symbol2->is_static){
          emit_llvm_ir("  %s = load %s, %s* @%s, %s", result, llvm_type, llvm_type,symbol2->name,get_alignment_str(base_llvm_type));
        }
        else {
            emit_llvm_ir("  %s = load %s, %s* %%%s, %s", result, llvm_type, llvm_type, name,get_alignment_str(base_llvm_type));
        }
        return strdup(result);
    }
    return strdup(name); // Return a copy if no load needed
}

// Helper function to extract parameter name from variable declaration
char* find_parameter_name(ASTNode* param_node) {
    if (!param_node || param_node->type != NODE_VARIABLE_DECL) return NULL;

    // Search through children for identifier
    ASTNode* child = param_node->child;
    while (child) {
        if (child->type == NODE_IDENTIFIER) {
            return strdup(child->value);
        } else if (child->type == NODE_DECLARATOR) {
            // Look for identifier in declarator
            ASTNode* decl_child = child->child;
            while (decl_child) {
                if (decl_child->type == NODE_IDENTIFIER) {
                    return strdup(decl_child->value);
                }
                decl_child = decl_child->next;
            }
        }
        child = child->next;
    }
    return NULL;
}

// Function to emit all stored IR in correct order
void emit_all_stored_ir() {
    // 1. Emit global declarations and string constants first
    for (int i = 0; i < global_ir_count; i++) {
        printf("%s\n", global_ir_lines[i].ir_line);
    }

    // 2. Emit other IR (function declarations, typedefs, etc.)
    for (int i = 0; i < other_ir_count; i++) {
        printf("%s\n", other_ir_lines[i].ir_line);
    }

    // 3. Emit function definitions
    for (int i = 0; i < function_ir_count; i++) {
        printf("%s\n", function_ir_lines[i].ir_line);
    }
}

// Function to free all stored IR
void free_stored_ir() {
    for (int i = 0; i < global_ir_count; i++) {
        free(global_ir_lines[i].ir_line);
    }
    for (int i = 0; i < function_ir_count; i++) {
        free(function_ir_lines[i].ir_line);
    }
    for (int i = 0; i < other_ir_count; i++) {
        free(other_ir_lines[i].ir_line);
    }

    global_ir_count = 0;
    function_ir_count = 0;
    other_ir_count = 0;
}

/* ==================== SEMANTIC ANALYSIS INTEGRATION ==================== */



// Helper function to handle array types
char* get_llvm_array_type(ASTNode* node) {
    if (!node || !node->is_array || node->array_dimensions == 0) {
        return get_complete_llvm_type(node);
    }

    // Build array type string
    char* base_type = get_complete_llvm_type(node);
    char array_type[256] = "";

    if (node->array_sizes && node->array_dimensions > 0) {
        // Static array
        sprintf(array_type, "[%d x %s]", node->array_sizes[0], base_type);
        for (int i = 1; i < node->array_dimensions; i++) {
            char temp[256];
            sprintf(temp, "[%d x %s]", node->array_sizes[i], array_type);
            strcpy(array_type, temp);
        }
    } else {
        // Dynamic array - use pointer
        sprintf(array_type, "%s*", base_type);
    }

    return strdup(array_type);
}

char* get_index_value(ASTNode* index_node) {
    if (!index_node) return "0";

    // If it's a literal, return the value directly
    if (index_node->type == NODE_LITERAL) {
        return strdup(index_node->value);
    }

    // Otherwise generate the IR
    return generate_llvm_ir_from_ast(index_node);
}

// Helper function to process variable arguments in function body
void process_varargs_function_body(ASTNode* body_node, int named_param_count) {
    if (!body_node) return;

    // This function would be called from NODE_FUNCTION_DEF case
    // to help set up the variable arguments processing

    // Look for va_list, va_start, va_arg, va_end usage in the function body
    // and ensure they're properly handled
    ASTNode* stmt = body_node->child;
    while (stmt) {
        // Process each statement looking for va_* operations
        if (stmt->type == NODE_VA_START || stmt->type == NODE_VA_ARG ||
            stmt->type == NODE_VA_END || stmt->type == NODE_VA_LIST_TYPE) {
            generate_llvm_ir_from_ast(stmt);
        }
        stmt = stmt->next;
    }
}

// Helper function to handle pointer types
char* get_llvm_pointer_type(ASTNode* node) {
    if (!node) return "i8*"; // Default to generic pointer

    char* base_type = get_complete_llvm_type(node);
    char pointer_type[256] = "";

    if (node->is_pointer && node->pointer_depth > 0) {
        sprintf(pointer_type, "%s", base_type);
        for (int i = 0; i < node->pointer_depth; i++) {
            char temp[256];
            sprintf(temp, "%s*", pointer_type);
            strcpy(pointer_type, temp);
        }
    } else {
        sprintf(pointer_type, "%s", base_type);
    }

    return strdup(pointer_type);
}

char* get_llvm_base_type(char* datatype) {

    if (strcmp(datatype, "int") == 0 ||
                strcmp(datatype, "unsigned int") == 0 ||
                strcmp(datatype, "static int") == 0) {
                return "i32";
            }
    
 else if (strcmp(datatype, "long") == 0 ||
                   strcmp(datatype, "long int") == 0 ||
                   strcmp(datatype, "long long") == 0 ||
                   strcmp(datatype, "static long") == 0) {
            return "i64";
            }
      else if (strcmp(datatype, "float") == 0||strcmp(datatype, "unsigned float") == 0 || strcmp(datatype, "static float") == 0) {
                return "float";
            }
            else if (strcmp(datatype, "double") == 0 || strcmp(datatype, "static double") == 0 || strcmp(datatype, "unsigned double") == 0) {
                return "double";
            }
            else if (strcmp(datatype, "char") == 0 ||
                     strcmp(datatype, "unsigned char") == 0) {

                return "i8";
            }
            else if (strcmp(datatype, "bool") == 0) {
                return "i1";
            }
            else if (strcmp(datatype, "short") == 0) {
                return "i16";
            }
            else if (strcmp(datatype, "void") == 0) {
                return "void";
            }
            else if (strcmp(datatype, "string") == 0 ||
                     strcmp(datatype, "char*") == 0 ||
                     (datatype && strstr(datatype, "char*") != NULL)) {
                return "i8*";
            }
            else if(strcmp(datatype, "unknown")==0){
            return "ERROR";
            }
    return "i32"; // default
}

char* get_llvm_pointer_base_type(char* llvm_type) {
    if (!llvm_type) return "i32";

    static char base_type[256];
    strcpy(base_type, llvm_type);

    // Remove ONE trailing '*' character
    int len = strlen(base_type);
    if (len > 0 && base_type[len-1] == '*') {
        base_type[len-1] = '\0';
        // Also remove any trailing space
        len = strlen(base_type);
        if (len > 0 && base_type[len-1] == ' ') {
            base_type[len-1] = '\0';
        }
    }

    // If we removed everything, return default type
    if (strlen(base_type) == 0) {
        strcpy(base_type, "i32");
    }

    return strdup(base_type);
}

// Main function to get complete LLVM type
char* get_complete_llvm_type(ASTNode* node) {
    static char type_str[512];

    if (!node) {
        strcpy(type_str, "i32");
        return strdup(type_str);
    }

    printf("node type : %s \n",node->datatype);
    
    // Handle pointers correctly
    if (node->is_pointer && node->pointer_depth > 0&&strcmp(node->datatype,"string")!=0) {
        char* base_type = get_llvm_base_type(node->datatype);
        strcpy(type_str, base_type);
        for (int i = 0; i < node->pointer_depth; i++) {
            char temp[512];
            sprintf(temp, "%s*", type_str);
            strcpy(type_str, temp);
        }
        return strdup(type_str);
    }
    // Handle arrays
    else if (node->is_array && node->array_dimensions > 0) {
        char base_type[32];

        // Get base type from datatype
        if (node->datatype) {
            if (strcmp(node->datatype, "int") == 0 || strcmp(node->datatype, "unsigned int") == 0 || strcmp(node->datatype, "static int") == 0) strcpy(base_type, "i32");
            else if (strcmp(node->datatype, "unsigned float") == 0 || strcmp(node->datatype, "float") == 0 || strcmp(node->datatype, "static float") == 0) strcpy(base_type, "float");
            else if (strcmp(node->datatype, "long long") == 0 || strcmp(node->datatype, "long int") == 0 || strcmp(node->datatype, "long") == 0) strcpy(base_type, "i64");
            else if (strcmp(node->datatype, "double") == 0 || strcmp(node->datatype, "unsigned double") == 0 || strcmp(node->datatype, "static double") == 0) strcpy(base_type, "double");
            else if (strcmp(node->datatype, "char") == 0 || strcmp(node->datatype, "unsigned char") == 0) strcpy(base_type, "i8");
            else if (strcmp(node->datatype, "void") == 0) strcpy(base_type, "void");
            else if (strcmp(node->datatype, "bool") == 0) strcpy(base_type, "i1");
            else if (strcmp(node->datatype, "short") == 0) strcpy(base_type, "i16");
            else if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) strcpy(base_type, "i8*");
            else strcpy(base_type, "i32");
        } else {
            strcpy(base_type, "i32");
        }

        // Build array type from innermost to outermost
        char temp[512];
        if (node->array_sizes && node->array_dimensions > 0 && node->array_sizes[0] > 0) {
            sprintf(temp, "[%d x %s]", node->array_sizes[node->array_dimensions-1], base_type);

            // Handle multi-dimensional arrays
            for (int i = node->array_dimensions-2; i >= 0; i--) {
                char new_temp[512];
                sprintf(new_temp, "[%d x %s]", node->array_sizes[i], temp);
                strcpy(temp, new_temp);
            }
        } else {
            // Dynamic array - use pointer
            sprintf(temp, "%s*", base_type);
        }

        strcpy(type_str, temp);
    } else {
        // Scalar type
        if (node->datatype) {
            
            if (strcmp(node->datatype, "int") == 0 || strcmp(node->datatype, "unsigned int") == 0 || strcmp(node->datatype, "static int") == 0) strcpy(type_str, "i32");
            else if (strcmp(node->datatype, "unsigned float") == 0 || strcmp(node->datatype, "float") == 0 || strcmp(node->datatype, "static float") == 0) strcpy(type_str, "float");
            else if (strcmp(node->datatype, "long long") == 0 || strcmp(node->datatype, "long int") == 0 || strcmp(node->datatype, "long") == 0 || strcmp(node->datatype, "static long") == 0) strcpy(type_str, "i64");
            else if (strcmp(node->datatype, "double") == 0 || strcmp(node->datatype, "unsigned double") == 0 || strcmp(node->datatype, "static double") == 0) strcpy(type_str, "double");
            else if (strcmp(node->datatype, "char") == 0 || strcmp(node->datatype, "unsigned char") == 0) strcpy(type_str, "i8");
            else if (strcmp(node->datatype, "void") == 0) strcpy(type_str, "void");
            else if (strcmp(node->datatype, "bool") == 0) strcpy(type_str, "i1");
            else if (strcmp(node->datatype, "short") == 0) strcpy(type_str, "i16");
            else if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) strcpy(type_str, "i8*");
            else strcpy(type_str, "i32");
        } else {
            strcpy(type_str, "i32");
        }
    }
    printf("captured node type : %s \n",type_str);
    return strdup(type_str);
}

// Generate local static variable declarations at global scope
void generate_local_static_declaration(ASTNode* node) {
    if (!node || node->type != NODE_VARIABLE_DECL || !node->is_static) return;
    if (strcmp(current_function, "") == 0) return; // Skip global statics (handled elsewhere)

    ASTNode* type_node = node->child;
    ASTNode* decl_node = type_node ? type_node->next : NULL;

    if (!decl_node) return;

    char* var_name = NULL;
    char* llvm_type = get_complete_llvm_type(node);
    char* base_llvm_type=strdup(llvm_type);

    if(node->is_array){
        base_llvm_type=get_llvm_base_type(node->datatype);
    }

    // Extract variable name
    if (decl_node->type == NODE_IDENTIFIER) {
        var_name = decl_node->value;
    } else if (decl_node->type == NODE_ASSIGNMENT && decl_node->left) {
        if (decl_node->left->type == NODE_IDENTIFIER) {
            var_name = decl_node->left->value;
        } else if (decl_node->left->type == NODE_INDEX) {
            // Array declaration - get base identifier
            ASTNode* current = decl_node->left;
            while (current && current->type == NODE_INDEX) {
                if (current->child && current->child->type == NODE_IDENTIFIER) {
                    var_name = current->child->value;
                    break;
                }
                current = current->child;
            }
        }
    }

    if (!var_name) return;

    // Generate mangled name for local static variable
    char mangled_name[128];
    sprintf(mangled_name, "%s.%s", current_function, var_name);

    // Check if this static variable has already been declared
    SymbolEntry* existing_symbol = find_symbol(mangled_name);

    if (!existing_symbol) {
        // For global initialization, we can only use CONSTANT values, not register values
        // So we need to handle initialization differently for globals vs locals
        if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
            // Check if the initializer is a constant literal
            if (decl_node->right->type == NODE_LITERAL) {
                // Use the literal value directly for global initialization
                char* init_value = get_literal_value_for_llvm(decl_node->right);
                if (init_value) {
                    // Handle string type specifically
                    if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                        emit_llvm_ir("@%s = internal global i8* %s", mangled_name, init_value);
                    } else {
                        emit_llvm_ir("@%s = internal global %s %s, %s", mangled_name, llvm_type, init_value,get_alignment_str(base_llvm_type));
                    }
                    free(init_value);
                } else {
                    // Default initialization for constants
                    if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                        emit_llvm_ir("@%s = internal global i8* null", mangled_name);
                    } else {
                        emit_llvm_ir("@%s = internal global %s zeroinitializer, %s", mangled_name, llvm_type,get_alignment_str(base_llvm_type));
                    }
                }
            } else {
                // Non-constant initializer - initialize to zero and handle runtime initialization
                if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                    emit_llvm_ir("@%s = internal global i8* null", mangled_name);
                } else {
                    emit_llvm_ir("@%s = internal global %s zeroinitializer, %s", mangled_name, llvm_type,get_alignment_str(base_llvm_type));
                }
                // Store the flag that this static needs runtime initialization
                // We'll handle this during the function processing
            }
        } else {
            // No initializer - zero initialize
            if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                emit_llvm_ir("@%s = internal global i8* null", mangled_name);
            } else {
                emit_llvm_ir("@%s = internal global %s zeroinitializer, %s", mangled_name, llvm_type,get_alignment_str(base_llvm_type));
            }
        }

        // Add to symbol table with the mangled name
        add_symbol_with_type(mangled_name, 1, node->datatype,
                           node->is_array, node->array_dimensions, node->array_sizes,
                           node->is_pointer, node->pointer_depth);
    }

    // Also add the original name to symbol table pointing to the static variable
    add_symbol_with_type(var_name, 1, node->datatype,
                       node->is_array, node->array_dimensions, node->array_sizes,
                       node->is_pointer, node->pointer_depth);
}

// Helper function to process local static variable declarations in functions
void process_local_static_declarations(ASTNode* node) {
    if (!node) return;

    // Process current node if it's a local static variable declaration
    if (node->type == NODE_VARIABLE_DECL && node->is_static && strcmp(current_function, "") != 0) {
        generate_local_static_declaration(node);
    }

    // Recursively process children
    ASTNode* child = node->child;
    while (child) {
        process_local_static_declarations(child);
        child = child->next;
    }

    // Process siblings
    ASTNode* sibling = node->next;
    while (sibling) {
        process_local_static_declarations(sibling);
        sibling = sibling->next;
    }
}

// Helper to get literal value for LLVM
char* get_literal_value_for_llvm(ASTNode* node) {
    if (!node || !node->value) return "0";

    if (node->type == NODE_LITERAL) {
        if (strcmp(node->datatype, "string") == 0) {
            // String literal - create global constant (but collect it, don't emit immediately)
            char* string_name = generate_string_constant_name();

            // Calculate actual string length (without quotes) and process escape sequences
            char* string_content = strdup(node->value);
            int len = strlen(string_content);

            int processed_len = len + 1;
            char* processed_string = malloc(processed_len);
            int j = 0;
            int in_string = 0;

            for (int i = 0; i < len; i++) {
                if (string_content[i] == '"') {
                    in_string = !in_string;
                    continue;
                }
                if (in_string) {
                    if (string_content[i] == '\\') {
                        // Handle escape sequences
                        i++;
                        switch(string_content[i]) {
                            case 'n': processed_string[j++] = '\n'; break;
                            case 't': processed_string[j++] = '\t'; break;
                            case 'r': processed_string[j++] = '\r'; break;
                            case '0': processed_string[j++] = '\0'; break;
                            case '\\': processed_string[j++] = '\\'; break;
                            case '"': processed_string[j++] = '"'; break;
                            case '\'': processed_string[j++] = '\''; break;
                            default: processed_string[j++] = string_content[i]; break;
                        }
                    } else {
                        processed_string[j++] = string_content[i];
                    }
                }
            }
            processed_string[j] = '\0';

            // Add to string constants collection
            add_string_constant(string_name, processed_string, j + 1); // Include null terminator
            free(processed_string);

            char* result = malloc(128);
            sprintf(result, "getelementptr inbounds ([%d x i8], [%d x i8]* @%s, i64 0, i64 0)",
                    j + 1, j + 1, string_name);
            return strdup(result);
        }
        else if (strcmp(node->datatype, "char") == 0) {
            // Character literal
            char* result = malloc(16);
            if (node->value[1] == '\\') {
                // Handle escape sequences
                switch(node->value[2]) {
                    case 'n': sprintf(result, "%d", (int)'\n'); break;
                    case 't': sprintf(result, "%d", (int)'\t'); break;
                    case 'r': sprintf(result, "%d", (int)'\r'); break;
                    case '0': sprintf(result, "%d", (int)'\0'); break;
                    case '\\': sprintf(result, "%d", (int)'\\'); break;
                    case '\'': sprintf(result, "%d", (int)'\''); break;
                    case '\"': sprintf(result, "%d", (int)'\"'); break;
                    default: sprintf(result, "%d", (int)node->value[1]); break;
                }
            } else {
                sprintf(result, "%d", (int)node->value[1]);
            }
            return strdup(result);
        }
        else if (strcmp(node->datatype, "bool") == 0) {
            return (strcmp(node->value, "true") == 0) ? "1" : "0";
        }
        else {
            // Numeric literals (int, float)
            return strdup(node->value);
        }
    }

    return "0";
}

// Helper function to get mangled name for local static variables
char* get_local_static_name(char* var_name) {
    if (strcmp(current_function, "") == 0) {
        return strdup(var_name); // Global scope - no mangling needed
    }

    char* mangled_name = malloc(strlen(current_function) + strlen(var_name) + 2);
    sprintf(mangled_name, "%s.%s", current_function, var_name);
    return strdup(mangled_name);
}
// Enhanced array type generation for MIPS compatibility
char* get_array_llvm_type(ASTNode* node) {
    if (!is_array_type(node)) {
        return get_complete_llvm_type(node);
    }

    static char array_type[512];
    char* base_type = get_llvm_base_type(node->datatype);

    // Build array type from the dimensions
    if (node->array_sizes && node->array_dimensions > 0) {
        // Start with the innermost dimension
        sprintf(array_type, "[%d x %s]", node->array_sizes[node->array_dimensions-1], base_type);

        // Add outer dimensions (if any)
        for (int i = node->array_dimensions-2; i >= 0; i--) {
            char temp[512];
            sprintf(temp, "[%d x %s]", node->array_sizes[i], array_type);
            strcpy(array_type, temp);
        }
    } else {
        // Dynamic array - use pointer type
        sprintf(array_type, "%s*", base_type);
    }

    return array_type;
}

// Initialize entire array to zero values
void initialize_array_to_zero(char* array_name, ASTNode* array_decl, int is_global) {
    if (!array_name || !array_decl || !array_decl->is_array) return;

    char* array_type = get_complete_llvm_type(array_decl);

   

    if (is_global) {
        // Global arrays are zero-initialized by LLVM
        emit_llvm_ir("  ; global array %s zero-initialized", array_name);
    } else {
        // Local array - use memset for efficiency
        char* array_ptr = generate_temp();
        emit_llvm_ir("  %s = bitcast %s* %%%s to i8*", array_ptr, array_type, array_name);

        // CORRECTED: Calculate total size based on element type and dimensions
        int element_size = 4; // default for i32
        
        // Get element size from AST node type
        if (array_decl->datatype) {
            if (strcmp(array_decl->datatype, "char") == 0 || 
                strcmp(array_decl->datatype, "unsigned char") == 0) {
                element_size = 1;
            } else if (strcmp(array_decl->datatype, "short") == 0) {
                element_size = 2;
            } else if (strcmp(array_decl->datatype, "int") == 0 || 
                       strcmp(array_decl->datatype, "float") == 0 ||
                       strcmp(array_decl->datatype, "unsigned int") == 0) {
                element_size = 4;
            } else if (strcmp(array_decl->datatype, "double") == 0 || 
                       strcmp(array_decl->datatype, "long") == 0 ||
                       strcmp(array_decl->datatype, "long long") == 0 ||
                       strcmp(array_decl->datatype, "long int") == 0) {
                element_size = 8;
            } else if (strcmp(array_decl->datatype, "string") == 0) {
                element_size = 8; // pointer size
            }
        }

        // Calculate total bytes = element_size * array_size
        int total_bytes = element_size;
        if (array_decl->array_sizes && array_decl->array_dimensions > 0) {
            for (int i = 0; i < array_decl->array_dimensions; i++) {
                total_bytes *= array_decl->array_sizes[i];
            }
        }

        char* size_val = generate_temp();
        emit_llvm_ir("  %s = add i32 %d, 0", size_val, total_bytes);

        // CORRECTED: Get proper alignment and fix memset call
        char * base_type=get_llvm_base_type(array_decl->datatype);
        const char* alignment_str = get_alignment_str(base_type);
        
        
        emit_llvm_ir("  call void @llvm.memset.p0i8.i32(i8* %s %s, i8 0, i32 %s, i1 false)",alignment_str, array_ptr, size_val);

        free(array_ptr);
        free(size_val);
    }
}

// Array initialisation
void initialize_array(char* array_name, char* array_type, ASTNode* init_node, ASTNode* array_decl, int is_global) {
    if (!init_node) return;

    if (init_node->type == NODE_INIT_LIST) {
        // Handle array initializer list: {1, 2, 3, 4}
        ASTNode* element = init_node->child;
        int index = 0;

        while (element) {
            char* element_value = generate_llvm_ir_from_ast(element);
            if (element_value) {
                char* elem_ptr = generate_temp();

                if (is_global) {
                    // Global array initialization (handled differently)
                    // For now, just emit a comment
                    emit_llvm_ir("  ; global array init: %s[%d] = %s", array_name, index, element_value);
                } else {
                    // Local array initialization
                    emit_llvm_ir("  %s = getelementptr inbounds %s, %s* %%%s, i32 0, i32 %d",
                                elem_ptr, array_type, array_type, array_name, index);

                    // Store element value with proper type
                    char* element_type = get_complete_llvm_type(element);
                    char* store_value = element_value;
                    char * base_llvm_type=strdup(element_type);

                    if(element->is_array){
                        base_llvm_type=get_llvm_base_type(element->datatype);
                    }

                    // Handle boolean values
                    if (element_value[0] == '!') {
                        store_value = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to i32", store_value, element_value + 1);
                        free(element_value);
                    }

                    emit_llvm_ir("  store %s %s, %s* %s, %s", element_type, store_value, element_type, elem_ptr,get_alignment_str(base_llvm_type));

                    if (store_value != element_value) free(store_value);
                }

                free(elem_ptr);
            }
            index++;
            element = element->next;
        }
    }
}

// Array allocation helper function
void allocate_array_variable(ASTNode* node, char* var_name, ASTNode* decl_node) {
    if (!node->is_array || node->array_dimensions == 0) return;

    // Get the complete array type (e.g., [3 x i32])
    char* array_type = get_complete_llvm_type(node);
    char* base_llvm_type=get_llvm_base_type(node->datatype);

    if (node->array_sizes && node->array_sizes[0] > 0) {
        // Static array allocation
        printf("base size : %s \n",base_llvm_type);
        emit_llvm_ir("  %%%s = alloca %s, %s", var_name, array_type,get_alignment_str(base_llvm_type));

        // Initialize array to zeros if no explicit initializer
        if (!(decl_node->type == NODE_ASSIGNMENT && decl_node->right)) {
            initialize_array_to_zero(var_name, array_type, node->array_sizes[0]);
        }
    } else {
        // Dynamic array allocation
        char* size_expr = "10"; // default size
        if (decl_node->type == NODE_INDEX && decl_node->right) {
            char* temp_size = generate_llvm_ir_from_ast(decl_node->right);
            if (temp_size) {
                size_expr = temp_size;
            }
        }

        char* size_bytes = generate_temp();
        char* element_size = "4"; // i32 size
        if (strcmp(node->datatype, "char") == 0) element_size = "1";
        else if (strcmp(node->datatype, "float") == 0) element_size = "4";
        else if (strcmp(node->datatype, "double") == 0) element_size = "8";

        emit_llvm_ir("  %s = mul i32 %s, %s", size_bytes, size_expr, element_size);

        char* malloc_result = generate_temp();
        emit_llvm_ir("  %s = call i8* @malloc(i32 %s)", malloc_result, size_bytes);

        char* base_type = get_llvm_base_type(node->datatype);
        emit_llvm_ir("  %%%s = bitcast i8* %s to %s*", var_name, malloc_result, base_type);

        free(size_bytes);
        free(malloc_result);
        if (size_expr != "10") free(size_expr);
    }
}

// Helper to detect if a node represents an array
int is_array_type(ASTNode* node) {
    return (node != NULL && node->is_array && node->array_dimensions > 0);
}

char* generate_lambda_call(ASTNode* lambda_ptr, ASTNode* args_node) {
    if (!lambda_ptr) return NULL;

    char* result_temp = generate_temp();

    // Build argument list
    char args_str[512] = "";
    if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
        ASTNode* arg = args_node->child;
        int first_arg = 1;

        while (arg) {
            if (!first_arg) strcat(args_str, ", ");

            char* arg_val = generate_llvm_ir_from_ast(arg);
            if (arg_val) {
                if (arg_val[0] == '!') {
                    // Boolean argument
                    char* zext_temp = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to i32", zext_temp, arg_val + 1);
                    strcat(args_str, zext_temp);
                    free(zext_temp);
                } else {
                    strcat(args_str, arg_val);
                }
                free(arg_val);
            } else {
                strcat(args_str, "0");
            }

            first_arg = 0;
            arg = arg->next;
        }
    }

    // Call the lambda through function pointer
    emit_llvm_ir("  %s = call i32 bitcast (i8* %s to i32 (%s)*)(%s)",
                result_temp, lambda_ptr,
                args_str[0] != '\0' ? args_str : "void",
                args_str);

    return strdup(result_temp);
}

void initialize_multi_dim_array(char* array_name, ASTNode* array_decl, ASTNode* init_node) {
    if (!init_node || init_node->type != NODE_INIT_LIST) return;

    char* array_type = get_complete_llvm_type(array_decl);
    char *array_type_buffer = strdup(array_type);
    printf("got array type %s \n", array_type);

    // Recursive helper function for nested initialization
    void init_nested(ASTNode* list_node, char* base_ptr, int* indices, int depth, int max_depth) {
        if (!list_node) return;

        ASTNode* element = list_node->child;
        int element_index = 0;

        while (element) {
            indices[depth] = element_index;

            if (element->type == NODE_INIT_LIST && depth < max_depth - 1) {
                // Nested initializer - recurse deeper
                init_nested(element, base_ptr, indices, depth + 1, max_depth);
            } else {
                
                // Leaf element - generate store
                char* element_value = generate_llvm_ir_from_ast(element);
                if (element_value) {
                    char* elem_ptr = generate_temp();

                    // Build GEP indices string
                    char indices_str[256] = "i64 0";  // CORRECTED: Use i64 for 64-bit systems
                    for (int i = 0; i <= depth; i++) {
                        char temp[16];
                        sprintf(temp, ", i32 %d", indices[i]);  // CORRECTED: Array indices are i32
                        strcat(indices_str, temp);
                    }
                    printf("final array type %s \n", array_type_buffer);

                    // CORRECTED: Use the stored array_type_buffer
                    emit_llvm_ir("  %s = getelementptr inbounds %s, %s* %%%s, %s",
                                elem_ptr, array_type_buffer, array_type_buffer, array_name, indices_str);

                    // Get proper type for the element
                    char* element_type = get_complete_llvm_type(element);
                    char* base_element_type=strdup(element_type);
                    if(element->is_array)
                    base_element_type=get_llvm_base_type(element->datatype);

                    char* store_value = element_value;

                    printf("init list element : %s ,",element_value);

                    // Handle boolean values
                    if (element_value[0] == '!') {
                        store_value = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to %s", store_value, element_value + 1, element_type);
                        free(element_value);
                    }

                    // CORRECTED: Get proper alignment for store
                    const char* alignment_str = get_alignment_str(base_element_type);
                    
                    emit_llvm_ir("  store %s %s, %s* %s, %s", 
                                element_type, store_value, element_type, elem_ptr, alignment_str);

                    if (store_value != element_value) free(store_value);
                    if(elem_ptr)
                    free(elem_ptr);
                    if(element_type)
                    free(element_type);
                }
            }

            element_index++;
            element = element->next;
        }
    }

    // CORRECTED: Initialize indices array properly
    int max_depth = array_decl->array_dimensions;
    if (max_depth <= 0) {
        free(array_type_buffer);
        return;
    }
    
    int indices[max_depth];
    memset(indices, 0, sizeof(indices));  // Initialize to zero
    
    init_nested(init_node, array_name, indices, 0, max_depth);
    printf("\n");
    if(array_type_buffer)
    free(array_type_buffer);
}

char* generate_llvm_ir_from_ast(ASTNode* node) {
    if (!node) return NULL;

    switch (node->type) {

case NODE_LITERAL: {
    char* llvm_type = get_complete_llvm_type(node);
    char* literal_value = get_literal_value_for_llvm(node);

    printf("liter type : %s , value : %s \n",llvm_type,literal_value);

    if (strcmp(llvm_type, "i8*") == 0) {
        // String literal - already handled in get_literal_value_for_llvm
        return literal_value;
    }
    else {
        char* temp = generate_temp();

        if (strcmp(llvm_type, "i1") == 0) {
            // Boolean literal
            emit_llvm_ir("  %s = add i1 0, %s", temp, literal_value);
            char* marked = malloc(strlen(temp) + 2);
            sprintf(marked, "!%s", temp);
            return marked;
        }
        else if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
            // Floating point literal
            emit_llvm_ir("  %s = fadd %s 0.0, %s", temp, llvm_type, literal_value);
        }
        else {
            // Integer literal
            emit_llvm_ir("  %s = add %s 0, %s", temp, llvm_type, literal_value);
        }

        return temp;
    }
}

case NODE_VARIABLE_DECL: {
            ASTNode* type_node = node->child;
            ASTNode* decl_node = type_node ? type_node->next : NULL;

            if (decl_node) {
                char* var_name = NULL;
                char* init_value = NULL;
                ASTNode* actual_decl_node = decl_node;

                // Extract variable name and handle different declarator types
                if (decl_node->type == NODE_IDENTIFIER) {
                    var_name = decl_node->value;
                }
                else if (decl_node->type == NODE_INDEX) {
                    // Array declaration - get the identifier from the index node
                    ASTNode* array_base = decl_node->child;
                    while(array_base){
                        if (array_base && array_base->type == NODE_IDENTIFIER) {
                            var_name = array_base->value;
                            break;
                        }
                        array_base=array_base->child;
                    }
                    actual_decl_node = array_base;
                }
                else if(decl_node->type==NODE_DECLARATOR){
                    ASTNode* left_left_node=decl_node->child;
                    if(decl_node->value=="&"){
                        ASTNode* ch=decl_node->child;
                        if(ch&&ch->type==NODE_IDENTIFIER){
                            var_name=ch->value;
                        }
                    }
                    else if (left_left_node->type==NODE_MULTI_PTR) {
                        // Pointer dereference assignment in declaration
                        ASTNode* pointer_base;
                        pointer_base= left_left_node->next;
                        if (pointer_base && pointer_base->type == NODE_IDENTIFIER) {
                            var_name = pointer_base->value;
                        }
                    }
                }
                else if (decl_node->type == NODE_ASSIGNMENT && decl_node->left) {
                    // Assignment during declaration - handle the left side
                    ASTNode* left_node = decl_node->left;

                    if (left_node->type == NODE_IDENTIFIER) {
                        var_name = left_node->value;
                    }
                    else if (left_node->type == NODE_INDEX) {
                        // Array element assignment in declaration - get base identifier
                        ASTNode* current = left_node;
                        printf("left node : %s \n",current->datatype);
                        while (current && current->type == NODE_INDEX) {
                            if (current->child && current->child->type == NODE_IDENTIFIER) {
                                var_name = current->child->value;
                                break;
                            }
                            current = current->child;
                        }
                    }
                    else if(left_node->type==NODE_DECLARATOR){
                        ASTNode* left_left_node=left_node->child;
                        if(left_node->value=="&"){
                            ASTNode* ch=left_node->child;
                            if(ch&&ch->type==NODE_IDENTIFIER){
                                var_name=ch->value;
                            }
                        }
                        else if (left_left_node->type==NODE_MULTI_PTR) {
                            // Pointer dereference assignment in declaration
                            ASTNode* pointer_base;
                            pointer_base= left_left_node->next;
                            if (pointer_base && pointer_base->type == NODE_IDENTIFIER) {
                                var_name = pointer_base->value;
                            }
                        }
                    }
                    actual_decl_node = left_node;

                    // Extract initial value for global declarations
                    if (strcmp(current_function, "") == 0 && decl_node->right) {
                        if (decl_node->right->type == NODE_LITERAL) {
                            init_value = get_literal_value_for_llvm(decl_node->right);
                        }
                    }
                }

                if (var_name) {
                    printf("var name : %s\n",var_name);
                    // Check if we're at global scope (not inside any function)
                    if (strcmp(current_function, "") == 0) {
                        // This is a global variable - add to global declarations collection
                        add_global_declaration(var_name, node->datatype, node->is_static,
                                             node->is_array, node->array_dimensions, node->array_sizes,
                                             node->is_pointer, node->pointer_depth, init_value);

                        // Add to symbol table immediately for proper lookup
                        add_symbol_with_type(var_name, node->is_static, node->datatype,
                                           node->is_array, node->array_dimensions, node->array_sizes,
                                           node->is_pointer, node->pointer_depth);

                        // Don't emit any code here - globals will be emitted later
                        if (init_value) free(init_value);
                        return NULL;
                    }
                    else {
                        // This is a local variable - use existing local variable handling
                        char* llvm_type = get_complete_llvm_type(node);
                        printf("LLVM TYPE :%s \n",llvm_type);
                        char * base_llvm_type=strdup(llvm_type);

                        if(node->is_array){
                                    base_llvm_type=get_llvm_base_type(node->datatype);
                            }

                        // Handle LOCAL STATIC variables
                        if (node->is_static && strcmp(current_function, "") != 0) {
                            // Local static variable - use global storage with internal linkage
                            char static_var_name[128];
                            sprintf(static_var_name, "%s.%s", current_function, var_name);

                            // Check if this static variable has already been declared
                            SymbolEntry* existing_symbol = find_symbol(static_var_name);

                            if (!existing_symbol) {
                                // First time encountering this static variable - declare it
                                if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                    char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                    if (local_init_value) {
                                        // Handle string type specifically
                                        if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                                            collecting_global_ir=1;
                                            emit_llvm_ir("@%s = internal global i8* %s", static_var_name, local_init_value);
                                            collecting_global_ir=0;
                                        } else {
                                            collecting_global_ir=1;
                                            emit_llvm_ir("@%s = internal global %s %s, %s", static_var_name, llvm_type, local_init_value,get_alignment_str(base_llvm_type));
                                            collecting_global_ir=0;
                                        }
                                        free(local_init_value);
                                    } else {
                                        // Default initialization
                                        if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                                            collecting_global_ir=1;
                                            emit_llvm_ir("@%s = internal global i8* null", static_var_name);
                                            collecting_global_ir=0;
                                        } else {
                                            collecting_global_ir=1;
                                            emit_llvm_ir("@%s = internal global %s zeroinitializer, %s", static_var_name, llvm_type,get_alignment_str(base_llvm_type));
                                            collecting_global_ir=0;
                                        }
                                    }
                                } else {
                                    // No initializer - zero initialize
                                    if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                                        collecting_global_ir=1;
                                        emit_llvm_ir("@%s = internal global i8* null", static_var_name);
                                        collecting_global_ir=0;
                                    } else {
                                        collecting_global_ir=1;
                                        emit_llvm_ir("@%s = internal global %s zeroinitializer, %s", static_var_name, llvm_type,get_alignment_str(base_llvm_type));
                                        collecting_global_ir=0;
                                    }
                                }

                                // Add to symbol table with the mangled name
                                add_symbol_with_type(static_var_name, 1, node->datatype,
                                                   node->is_array, node->array_dimensions, node->array_sizes,
                                                   node->is_pointer, node->pointer_depth);
                            }

                            // Also add the original name to symbol table pointing to the static variable
                            add_symbol_with_type(var_name, 1, node->datatype,
                                               node->is_array, node->array_dimensions, node->array_sizes,
                                               node->is_pointer, node->pointer_depth);

                        }
                        // Handle string type specifically
                        else if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char*") == 0) {
                            if (node->is_static) {
                                // Global string
                                if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                    char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                    collecting_global_ir=1;
                                    emit_llvm_ir("@%s = internal global i8* %s", var_name, local_init_value);
                                    collecting_global_ir=0;
                                    free(local_init_value);
                                } else {
                                    collecting_global_ir=1;
                                    emit_llvm_ir("@%s = internal global i8* null", var_name);
                                    collecting_global_ir=0;
                                }
                            } else {
                                // Local string - allocate pointer
                                emit_llvm_ir("  %%%s = alloca i8*, align 8", var_name);

                                // Initialize if needed
                                if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                    char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                    emit_llvm_ir("  store i8* %s, i8** %%%s, align 8", local_init_value, var_name);
                                    free(local_init_value);
                                } else {
                                    emit_llvm_ir("  store i8* null, i8** %%%s, align 8", var_name);
                                }
                            }
                        }
                        // Handle GLOBAL static variables (existing code)
                        else if (node->is_static && strcmp(current_function, "") == 0) {
                            if (strcmp(current_function, "") == 0) {
                                // Global static with alignment
                                if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                    char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                    

                                    collecting_global_ir=1;
                                    emit_llvm_ir("@%s = internal global %s %s, %s", var_name, llvm_type, local_init_value,get_alignment_str(base_llvm_type));
                                    collecting_global_ir=0;
                                    free(local_init_value);

                                    // For arrays with initializers, also initialize the values
                                    if (node->is_array && node->array_dimensions > 0 &&
                                        decl_node->right->type == NODE_INIT_LIST) {
                                        initialize_multi_dim_array(var_name, node, decl_node->right);
                                    }
                                } else {
                                    collecting_global_ir=1;
                                    emit_llvm_ir("@%s = internal global %s zeroinitializer, %s", var_name, llvm_type,get_alignment_str(base_llvm_type));
                                    collecting_global_ir=0;
                                }
                            } else {
                                // This case should now be handled by the local static code above
                                emit_llvm_ir("  ; static variable %s (complex handling needed)", var_name);
                            }
                        } else {
                            // Regular local variable - handle arrays and pointers with alignment
                            if (node->is_array) {
                                char * base_llvm_type=get_llvm_base_type(node->datatype);
                                // Enhanced multi-dimensional array allocation
                                if (node->array_sizes && node->array_dimensions > 0) {
                                    // Static multi-dimensional array allocation
                                    
                                    emit_llvm_ir("  %%%s = alloca %s, %s", var_name, llvm_type,get_alignment_str(base_llvm_type));

                                    // Initialize array if there's an initializer
                                    if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                        initialize_multi_dim_array(var_name, node, decl_node->right);
                                    } else {
                                        // Zero-initialize the array
                                        initialize_array_to_zero(var_name, node, 0); // 0 for local
                                    }
                                } else {
                                    // Dynamic array allocation
                                    char* size_bytes = generate_temp();
                                    emit_llvm_ir("  %s = mul i32 %s, 4", size_bytes,
                                                decl_node->right ? generate_llvm_ir_from_ast(decl_node->right) : "10");
                                    char* malloc_result = generate_temp();
                                    emit_llvm_ir("  %s = call i8* @malloc(i32 %s)", malloc_result, size_bytes);
                                    emit_llvm_ir("  %%%s = bitcast i8* %s to i32*", var_name, malloc_result);
                                    free(size_bytes);
                                    free(malloc_result);
                                }
                            } else if (node->is_pointer) {
                                char * type_buffer = strdup(llvm_type);
                                // POINTER FIX: Handle pointers specifically
                                if (node->is_static) {
                                    // Global pointer
                                    if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                        char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                        collecting_global_ir=1;
                                        emit_llvm_ir("@%s = internal global %s %s", var_name, type_buffer, local_init_value);
                                        collecting_global_ir=0;
                                        free(local_init_value);
                                    } else {
                                        collecting_global_ir=1;
                                        emit_llvm_ir("@%s = internal global %s null", var_name, type_buffer);
                                        collecting_global_ir=0;
                                    }
                                } else {
                                    // Local pointer - allocate space for the pointer itself
                                    char* base_type = get_llvm_pointer_base_type(strdup(llvm_type));
                                    emit_llvm_ir("  %%%s = alloca %s, %s", var_name, type_buffer,get_alignment_str(base_llvm_type));

                                    // Initialize if needed
                                    if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                        char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                    

                                        // For pointer assignment, we need to handle different cases:
                                        if (local_init_value && local_init_value[0] == '%') {
                                            // If it's a temporary value (address), store it directly
                                            emit_llvm_ir("  store %s %s, %s* %%%s, %s", type_buffer, local_init_value, type_buffer, var_name,get_alignment_str(base_llvm_type));
                                        } else {
                                            // For literal addresses or null
                                            emit_llvm_ir("  store %s %s, %s* %%%s, %s", type_buffer, local_init_value, type_buffer, var_name,get_alignment_str(base_llvm_type));
                                        }
                                        free(local_init_value);
                                    } else {
                                        // Initialize to null if no initial value
                                        emit_llvm_ir("  store %s null, %s* %%%s, %s", type_buffer, type_buffer, var_name,get_alignment_str(base_llvm_type));
                                    }
                                }
                                free(type_buffer);
                            } else {
                                // Regular scalar variable with alignment
                                char * stored_llvm_type=strdup(llvm_type);
                                emit_llvm_ir("  %%%s = alloca %s, %s", var_name, llvm_type, get_alignment_str(base_llvm_type));
                                llvm_type=strdup(stored_llvm_type);

                                if(stored_llvm_type){
                                    free(stored_llvm_type);
                                }

                                // Handle initialization
                                if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
                                    char* local_init_value = generate_llvm_ir_from_ast(decl_node->right);
                                    emit_llvm_ir("  store %s %s, %s* %%%s, %s", llvm_type, local_init_value, llvm_type, var_name,get_alignment_str(base_llvm_type));
                                    free(local_init_value);
                                }
                            }
                        }

                        // Add to symbol table with type information (for non-local-static cases)
                        if (!(node->is_static && strcmp(current_function, "") != 0)) {
                            add_symbol_with_type(var_name, node->is_static, node->datatype,
                                               node->is_array, node->array_dimensions, node->array_sizes,
                                               node->is_pointer, node->pointer_depth);
                        }
                    }
                }
            }
            return NULL;
        }

case NODE_IDENTIFIER: {
            if (!node->value) return NULL;

            SymbolEntry* symbol = find_symbol(node->value);
            char* llvm_type = get_complete_llvm_type(node);
            char * base_llvm_type=strdup(llvm_type);

            if(node->is_array){
                base_llvm_type=get_llvm_base_type(node->datatype);
            }

            // Handle local static variables - check if there's a mangled name
            if (symbol && symbol->is_static && strcmp(current_function, "") != 0) {
                char static_var_name[128];
                sprintf(static_var_name, "%s.%s", current_function, node->value);
                SymbolEntry* static_symbol = find_symbol(static_var_name);
                char* result = generate_temp();

                if (static_symbol) {
                    // Use the mangled static variable name
                    // Handle string type
                    if (strcmp(symbol->datatype, "string") == 0 || strcmp(symbol->datatype, "char*") == 0) {
                        emit_llvm_ir("  %s = load i8*, i8** @%s, align 8", result, static_var_name);
                    } else {
                        emit_llvm_ir("  %s = load %s, %s* @%s, %s", result, llvm_type, llvm_type, static_var_name,get_alignment_str(base_llvm_type));
                    }
                }
                else{
                    if (strcmp(symbol->datatype, "string") == 0 || strcmp(symbol->datatype, "char*") == 0) {
                        emit_llvm_ir("  %s = load i8*, i8** @%s, align 8", result, symbol->name);
                    } else {
                        emit_llvm_ir("  %s = load %s, %s* @%s, %s", result, llvm_type, llvm_type, symbol->name,get_alignment_str(base_llvm_type));
                    }
                }

                return strdup(result);
            }

            // Handle string type
            if (symbol && (strcmp(symbol->datatype, "string") == 0 || strcmp(symbol->datatype, "char*") == 0)) {
                char* result = generate_temp();
                if (symbol->is_static) {
                    emit_llvm_ir("  %s = load i8*, i8** @%s, align 8", result, node->value);
                } else {
                    if(node->is_parameter)
                        emit_llvm_ir("  %s = load i8*, i8** %%%s.addr, align 8", result, node->value);
                    else
                        emit_llvm_ir("  %s = load i8*, i8** %%%s, align 8", result, node->value);
                }
                return strdup(result);
            } else {
                char* result = generate_temp();
                // Check if this is a static/global variable
                if (symbol && symbol->is_static) {
                    // Direct global variable access (simpler approach)
                    emit_llvm_ir("  %s = load %s, %s* @%s, %s", result, llvm_type, llvm_type, node->value,get_alignment_str(base_llvm_type));
                } else {
                    // Local variable access with alignment
                    if(node->is_parameter)
                        emit_llvm_ir("  %s = load %s, %s* %%%s.addr, %s", result, llvm_type, llvm_type, node->value,get_alignment_str(base_llvm_type));
                    else if(node->is_array){
                        emit_llvm_ir("  %s =  getelementptr inbounds %s, %s* %%%s , i32 0, i32 0", result, llvm_type, llvm_type, node->value);
                    }
                    else
                        emit_llvm_ir("  %s = load %s, %s* %%%s, %s", result, llvm_type, llvm_type, node->value,get_alignment_str(base_llvm_type));
                }
                return strdup(result);
            }
        }

case NODE_BREAK_STMT: {
    if (current_break_label) {
        emit_llvm_ir("  br label %%%s", current_break_label);
    } else {
        // Error: break outside loop/switch
        emit_llvm_ir("  ; ERROR: break outside loop");
    }
    return NULL;
}

case NODE_CONTINUE_STMT: {
    if (current_continue_label) {
        emit_llvm_ir("  br label %%%s", current_continue_label);
    } else {
        // Error: continue outside loop
        emit_llvm_ir("  ; ERROR: continue outside loop");
    }
    return NULL;
}

case NODE_INDEX: {
    // Handle array element access: arr[i] or arr[i][j] or arr[i][j][k] etc.
    ASTNode* current = node;
    ASTNode* base_array = NULL;
    char* array_name = NULL;
    SymbolEntry* symbol = NULL;

    // Collect all indices in reverse order (from outermost to innermost)
    ASTNode* indices[10]; // max 10 dimensions
    int index_count = 0;

    // Traverse the index chain to find the base array and collect indices
    while (current && current->type == NODE_INDEX) {
        indices[index_count++] = current;
        ASTNode* array_part = current->child;

        if (array_part && array_part->type == NODE_IDENTIFIER) {
            base_array = array_part;
            array_name = array_part->value;
            symbol = find_symbol(array_name);
            break;
        }
        current = array_part;
    }

    if (!base_array || !array_name || !symbol) {
    printf("array : %s \n",array_name);
    return NULL;
    }

    // Generate all index expressions (from outermost to innermost)
    char* index_values[10];
    int actual_index_count = 0;

    for (int i =index_count-1; i >=0 ; i--) {
        ASTNode* index_node = indices[i]->child ? indices[i]->child->next : NULL;
        if (index_node) {
            index_values[actual_index_count++] = get_index_value(index_node);
        }
    }

    char* array_type = get_complete_llvm_type(base_array);
    char * array_base_type=get_llvm_base_type(base_array->datatype);

    char* element_ptr = generate_temp();
    char* result = generate_temp();


    // Build GEP instruction with all indices
    if (symbol->is_static) {
        // Global array
        char* load_temp = generate_temp();
        emit_llvm_ir("  %s = load %s, %s* @%s, %s", load_temp, array_type, array_type, array_name,get_alignment_str(array_base_type));

        // Build GEP with all indices
        char gep_str[512] = "";
        strcpy(gep_str, "i32 0");
        for (int i = 0; i <actual_index_count ; i++) {
            char temp[64];
            sprintf(temp, ", i32 %s", index_values[i]);
            strcat(gep_str, temp);
        }

        emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, %s",
                     element_ptr, array_type, array_type, load_temp, gep_str);
        free(load_temp);
    } else {
        // Local array - build GEP with all indices
        char gep_str[512] = "";
        strcpy(gep_str, "i32 0");
        for (int i =0 ; i <actual_index_count; i++) {
            char temp[64];
            sprintf(temp, ", i32 %s", index_values[i]);
            strcat(gep_str, temp);
        }

        emit_llvm_ir("  %s = getelementptr inbounds %s, %s* %%%s, %s",
                     element_ptr, array_type, array_type, array_name, gep_str);
    }

    emit_llvm_ir("  %s = load i32, i32* %s, %s", result, element_ptr,get_alignment_str(array_base_type));

    // Free temporary values
    free(element_ptr);
    for (int i = 0; i < actual_index_count; i++) {
        if (index_values[i]) free(index_values[i]);
    }

    return strdup(result);
}

case NODE_DECLARATOR: {
    // Handle array declarators: int arr[10] or int arr[]
    ASTNode* child = node->child;

    // Check if this is an array declarator
    if (child && child->type == NODE_INDEX) {
        ASTNode* array_name_node = child->child;
        ASTNode* array_size_node = array_name_node ? array_name_node->next : NULL;
        
        if (array_name_node && array_name_node->type == NODE_IDENTIFIER) {
            char* array_name = array_name_node->value;
            int array_size = 10; // Default size
            char* base_llvm_type=get_llvm_base_type(array_name_node->datatype);


            // Get array size if specified
            if (array_size_node) {
                char* size_str = generate_llvm_ir_from_ast(array_size_node);
                if (size_str) {
                    if (size_str[0] == '%' || isdigit(size_str[0])) {
                        // Dynamic size or literal
                        array_size = 0; // Will be handled during allocation
                    }
                    free(size_str);
                }
            }

            // Allocate array (using malloc for dynamic arrays)
            if (array_size > 0) {
                // Static array allocation
                printf("base array size : %s \n",base_llvm_type);
                emit_llvm_ir("  %%%s = alloca [%d x i32], %s", array_name, array_size,get_alignment_str(base_llvm_type));
            } else {
                // Dynamic array allocation
                char* size_bytes = generate_temp();
                emit_llvm_ir("  %s = mul i32 %s, 4", size_bytes,
                            array_size_node ? generate_llvm_ir_from_ast(array_size_node) : "40");
                emit_llvm_ir("  %%%s_ptr = call i8* @malloc(i32 %s)", array_name, size_bytes);
                free(size_bytes);
            }

            return create_ast_node(NODE_IDENTIFIER, node->line_number, array_name);
        }
    }

    // Regular identifier declarator
    if (child && child->type == NODE_IDENTIFIER) {
        return child;
    }

    // Process children for complex declarators
    ASTNode* current = node->child;
    while (current) {
        generate_llvm_ir_from_ast(current);
        current = current->next;
    }
    return NULL;
}

case NODE_INIT_LIST: {
    // Array initializer: {1, 2, 3, 4}
    ASTNode* element = node->child;
    int count = 0;

    // Count elements
    ASTNode* temp = element;
    while (temp) {
        count++;
        temp = temp->next;
    }

    // For now, just process each element
    // In a complete implementation, you'd store these for array initialization
    while (element) {
        generate_llvm_ir_from_ast(element);
        element = element->next;
    }

    emit_llvm_ir("  ; array initializer with %d elements", count);
    return NULL;
}

case NODE_INITIALIZER: {
    // Variable initializer (could be single value or array initializer)
    ASTNode* init_value = node->child;
    if (init_value) {
        return generate_llvm_ir_from_ast(init_value);
    }
    return NULL;
}

case NODE_UNARY_OP: {
    if (!node->op || !node->left) return NULL;

    // Handle address-of operator (&)
    if (strcmp(node->op, "&") == 0) {
        ASTNode* operand = node->left;
        if (operand->type == NODE_IDENTIFIER) {
            SymbolEntry* symbol = find_symbol(operand->value);
            if (symbol) {
                char* result = malloc(strlen(operand->value) + 2);  // +1 for % +1 for null terminator
               if (result != NULL) {
                   sprintf(result, "%%%s", operand->value);
                  }
                 return strdup(result);
            }
        }
        return NULL;
    }

    // Handle pointer dereference operator (*)
    else if (strcmp(node->op, "*") == 0) {
        // Generate the pointer value (this could be a simple identifier or another dereference)
        char* ptr_value = generate_llvm_ir_from_ast(node->left);
        if (!ptr_value) return NULL;

        // Get the complete type of the pointer (including pointer levels)
        char* complete_type = get_complete_llvm_type(node->left);

        // For dereference, we need the type that this pointer points to
        // Remove one level of pointer from the type
        char* base_type = get_llvm_pointer_base_type(complete_type);

        char* result = generate_temp();

        // Load through the pointer - the pointer value is already the correct type
        emit_llvm_ir("  %s = load %s, %s %s, %s", result, base_type, complete_type, ptr_value,get_alignment_str(base_type));

        free(ptr_value);
        return strdup(result);
    }

    // Handle postfix increment/decrement (i++, i--)
    if ((strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0) && node->is_postfix) {
        ASTNode* operand = node->left;
        if (!operand || operand->type != NODE_IDENTIFIER || !operand->value) return NULL;

        char* varname = operand->value;
        SymbolEntry* symbol = find_symbol(varname);
        if (!symbol) return NULL;

        char* llvm_type = get_complete_llvm_type(operand);
        char* base_llvm_type=strdup(llvm_type);

        if(operand->is_array){
            base_llvm_type=get_llvm_base_type(operand->datatype);
        }

        // Check if this is a pointer type
        if (symbol->is_pointer) {
            // POINTER ARITHMETIC: p++ or p--

            // Load current pointer value (return value)
            char* old_ptr = generate_temp();
            if (symbol->is_static) {
                emit_llvm_ir("  %s = load %s, %s* @%s, %s", old_ptr, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  %s = load %s, %s* %%%s, %s", old_ptr, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            // Calculate new pointer value using getelementptr
            char* new_ptr = generate_temp();
            if (strcmp(node->op, "++") == 0) {
                // p = p + 1 (increment pointer)
                emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, i32 1",
                            new_ptr, get_llvm_pointer_base_type(llvm_type), llvm_type, old_ptr);
            } else {
                // p = p - 1 (decrement pointer)
                emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, i32 -1",
                            new_ptr, get_llvm_pointer_base_type(llvm_type), llvm_type, old_ptr);
            }

            // Store new pointer value back
            if (symbol->is_static) {
                emit_llvm_ir("  store %s %s, %s* @%s, %s", llvm_type, new_ptr, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  store %s %s, %s* %%%s, %s", llvm_type, new_ptr, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            free(new_ptr);
            return old_ptr; // Return the old pointer value for postfix
        }
        else {
            // REGULAR VARIABLE (non-pointer) - existing code
            // Load current value (return value)
            char* old_val = generate_temp();
            if (symbol->is_static) {
                emit_llvm_ir("  %s = load %s, %s* @%s, %s", old_val, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  %s = load %s, %s* %%%s, %s", old_val, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            // Calculate new value
            char* new_val = generate_temp();
            if (strcmp(node->op, "++") == 0) {
                if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
                    emit_llvm_ir("  %s = fadd %s %s, 1.0", new_val, llvm_type, old_val);
                } else {
                    emit_llvm_ir("  %s = add nsw %s %s, 1", new_val, llvm_type, old_val);
                }
            } else {
                if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
                    emit_llvm_ir("  %s = fsub %s %s, 1.0", new_val, llvm_type, old_val);
                } else {
                    emit_llvm_ir("  %s = sub nsw %s %s, 1", new_val, llvm_type, old_val);
                }
            }

            // Store new value back
            if (symbol->is_static) {
                emit_llvm_ir("  store %s %s, %s* @%s, %s", llvm_type, new_val, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  store %s %s, %s* %%%s, %s", llvm_type, new_val, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            free(new_val);
            return old_val; // Return the old value for postfix
        }
    }
    // Handle prefix increment/decrement (++i, --i)
    else if (strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0) {
        ASTNode* operand = node->left;
        if (!operand || operand->type != NODE_IDENTIFIER || !operand->value) return NULL;

        char* varname = operand->value;
        SymbolEntry* symbol = find_symbol(varname);
        if (!symbol) return NULL;

        char* llvm_type = get_complete_llvm_type(operand);
        char * base_llvm_type=strdup(llvm_type);

        if(operand->is_array){
            base_llvm_type=get_llvm_base_type(operand->datatype);
        }

        // Check if this is a pointer type
        if (symbol->is_pointer) {
            // POINTER ARITHMETIC: ++p or --p

            // Load current pointer value
            char* current_ptr = generate_temp();
            if (symbol->is_static) {
                emit_llvm_ir("  %s = load %s, %s* @%s, %s", current_ptr, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  %s = load %s, %s* %%%s, %s", current_ptr, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            // Calculate new pointer value using getelementptr
            char* new_ptr = generate_temp();
            if (strcmp(node->op, "++") == 0) {
                // p = p + 1 (increment pointer)
                emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, i32 1",
                            new_ptr, get_llvm_pointer_base_type(llvm_type), llvm_type, current_ptr);
            } else {
                // p = p - 1 (decrement pointer)
                emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, i32 -1",
                            new_ptr, get_llvm_pointer_base_type(llvm_type), llvm_type, current_ptr);
            }

            // Store new pointer value back
            if (symbol->is_static) {
                emit_llvm_ir("  store %s %s, %s* @%s, %s", llvm_type, new_ptr, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  store %s %s, %s* %%%s, %s", llvm_type, new_ptr, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            free(current_ptr);
            return new_ptr; // Return the new pointer value for prefix
        }
        else {
            // REGULAR VARIABLE (non-pointer) - existing code
            // Load current value
            char* current_val = generate_temp();
            if (symbol->is_static) {
                emit_llvm_ir("  %s = load %s, %s* @%s, %s", current_val, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  %s = load %s, %s* %%%s, %s", current_val, llvm_type, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            // Calculate new value
            char* new_val = generate_temp();
            if (strcmp(node->op, "++") == 0) {
                if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
                    emit_llvm_ir("  %s = fadd %s %s, 1.0", new_val, llvm_type, current_val);
                } else {
                    emit_llvm_ir("  %s = add nsw %s %s, 1", new_val, llvm_type, current_val);
                }
            } else {
                if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
                    emit_llvm_ir("  %s = fsub %s %s, 1.0", new_val, llvm_type, current_val);
                } else {
                    emit_llvm_ir("  %s = sub nsw %s %s, 1", new_val, llvm_type, current_val);
                }
            }

            // Store new value back
            if (symbol->is_static) {
                emit_llvm_ir("  store %s %s, %s* @%s, %s", llvm_type, new_val, llvm_type, varname,get_alignment_str(base_llvm_type));
            } else {
                emit_llvm_ir("  store %s %s, %s* %%%s, %s", llvm_type, new_val, llvm_type, varname,get_alignment_str(base_llvm_type));
            }

            free(current_val);
            return new_val; // Return the new value for prefix
        }
    }
    // Handle other unary operators
    else if (strcmp(node->op, "-") == 0) {
        char* operand_val = generate_llvm_ir_from_ast(node->left);
        if (!operand_val) return NULL;

        char* llvm_type = get_complete_llvm_type(node->left);
        char* result = generate_temp();

        if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
            emit_llvm_ir("  %s = fneg %s %s", result, llvm_type, operand_val);
        } else {
            emit_llvm_ir("  %s = sub nsw %s 0, %s", result, llvm_type, operand_val);
        }
        free(operand_val);
        return strdup(result);
    }
    else if (strcmp(node->op, "!") == 0) {
        char* operand_val = generate_llvm_ir_from_ast(node->left);
        if (!operand_val) return NULL;

        char* result = generate_temp();
        char* llvm_type = get_complete_llvm_type(node->left);

        if (strcmp(llvm_type, "i1") == 0) {
            // Direct boolean negation
            emit_llvm_ir("  %s = xor i1 %s, true", result, operand_val);
        } else {
            // Compare to zero for other types
            emit_llvm_ir("  %s = icmp eq %s %s, 0", result, llvm_type, operand_val);
        }


        free(operand_val);
        
        return strdup(result);
    }

    // fallback -> evaluate child
    return generate_llvm_ir_from_ast(node->left);
}

case NODE_DO_WHILE_STMT: {
    // Structure: body -> condition
    ASTNode* body_node = node->child;
    ASTNode* condition_node = body_node ? body_node->next : NULL;

    char* body_label = generate_label();
    char* cond_label = generate_label();
    char* end_label = generate_label();

    // Start with body (do-while executes at least once)
    emit_llvm_ir("  br label %%%s", body_label);
    emit_llvm_ir("%s:", body_label);

    // Execute body
    if (body_node) {
        generate_llvm_ir_from_ast(body_node);
    }

    // Jump to condition check
    emit_llvm_ir("  br label %%%s", cond_label);
    emit_llvm_ir("%s:", cond_label);

    // Condition evaluation
    if (condition_node && condition_node->type != NODE_EMPTY) {
        char* cond_value = generate_llvm_ir_from_ast(condition_node);
        if (cond_value) {
            // Check if it's already a boolean (starts with '!')
            if (strcmp(condition_node->datatype,"bool")==0) {
                // Already a boolean temp - use directly
                emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                            cond_value + 1, body_label, end_label);
            } else {
                // Not a boolean - compare to zero
                char* cmp_temp = generate_temp();
                emit_llvm_ir("  %s = icmp ne i32 %s, 0", cmp_temp, cond_value);
                emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                            cmp_temp, body_label, end_label);
                free(cmp_temp);
            }
            free(cond_value);
        } else {
            // No condition value - treat as true
            emit_llvm_ir("  br label %%%s", body_label);
        }
    } else {
        // No condition means infinite loop
        emit_llvm_ir("  br label %%%s", body_label);
    }

    // End label
    emit_llvm_ir("%s:", end_label);

    // Free the labels
    free(body_label);
    free(cond_label);
    free(end_label);

    return NULL;
}

case NODE_WHILE_STMT: {
    ASTNode* condition_node = node->child;
    ASTNode* body_node = condition_node ? condition_node->next : NULL;

    char* cond_label = generate_label();
    char* body_label = generate_label();
    char* end_label = generate_label();

    // Store context for break/continue
    char* old_break_label = current_break_label;
    char* old_continue_label = current_continue_label;
    current_break_label = end_label;
    current_continue_label = cond_label;

    // Start with condition check
    emit_llvm_ir("  br label %%%s", cond_label);
    emit_llvm_ir("%s:", cond_label);

    // Condition evaluation
    if (condition_node && condition_node->type != NODE_EMPTY) {
        char* cond_value = generate_llvm_ir_from_ast(condition_node);
        if (cond_value) {
            // Check if it's already a boolean (starts with '!')
            if (strcmp(condition_node->datatype,"bool")==0) {
                // Already a boolean temp - use directly
                emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                            cond_value , body_label, end_label);
            } else {
                // Not a boolean - compare to zero
                char* cmp_temp = generate_temp();
                emit_llvm_ir("  %s = icmp ne i32 %s, 0", cmp_temp, cond_value);
                emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                            cmp_temp, body_label, end_label);
                free(cmp_temp);
            }
            free(cond_value);
        } else {
            // No condition value - treat as true
            emit_llvm_ir("  br label %%%s", body_label);
        }
    } else {
        // No condition means infinite loop
        emit_llvm_ir("  br label %%%s", body_label);
    }

    // Loop body
    emit_llvm_ir("%s:", body_label);
    if (body_node) {
        generate_llvm_ir_from_ast(body_node);
    }
    
    // Jump back to condition check
    emit_llvm_ir("  br label %%%s", cond_label);

    // End label
    emit_llvm_ir("%s:", end_label);

    // Restore context
    current_break_label = old_break_label;
    current_continue_label = old_continue_label;

    free(cond_label);
    free(body_label);
    free(end_label);
    return NULL;
}

case NODE_FOR_STMT: {
    ASTNode* init_node = node->child;
    ASTNode* condition_node = init_node ? init_node->next : NULL;
    ASTNode* increment_node = condition_node ? condition_node->next : NULL;
    ASTNode* body_node = increment_node ? increment_node->next : NULL;

    char* cond_label = generate_label();
    char* body_label = generate_label();
    char* inc_label = generate_label();
    char* end_label = generate_label();

    // Store context for break/continue
    char* old_break_label = current_break_label;
    char* old_continue_label = current_continue_label;
    current_break_label = end_label;
    current_continue_label = inc_label;

    // Initialization
    if (init_node && init_node->type != NODE_EMPTY) {
        generate_llvm_ir_from_ast(init_node);
    }

    // Jump to condition check
    emit_llvm_ir("  br label %%%s", cond_label);
    emit_llvm_ir("%s:", cond_label);

    // Condition evaluation
    if (condition_node && condition_node->type != NODE_EMPTY) {
        char* cond_value = generate_llvm_ir_from_ast(condition_node);
        if (cond_value) {
            // Check if it's already a boolean (starts with '!')
            if (strcmp(condition_node->datatype,"bool")==0) {
                // Already a boolean temp - use directly
                emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                            cond_value, body_label, end_label);
            } else {
                // Not a boolean - compare to zero
                char* cmp_temp = generate_temp();
                emit_llvm_ir("  %s = icmp ne i32 %s, 0", cmp_temp, cond_value);
                emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                            cmp_temp, body_label, end_label);
                free(cmp_temp);
            }
            free(cond_value);
        } else {
            // No condition value - treat as true
            emit_llvm_ir("  br label %%%s", body_label);
        }
    } else {
        // No condition means infinite loop
        emit_llvm_ir("  br label %%%s", body_label);
    }

    // Loop body
    emit_llvm_ir("%s:", body_label);
    if (body_node) {
        generate_llvm_ir_from_ast(body_node);
    }

    // Jump to increment
    emit_llvm_ir("  br label %%%s", inc_label);
    emit_llvm_ir("%s:", inc_label);

    // Increment step
    if (increment_node && increment_node->type != NODE_EMPTY) {
        generate_llvm_ir_from_ast(increment_node);
    }

    // Jump back to condition check
    emit_llvm_ir("  br label %%%s", cond_label);

    // End label
    emit_llvm_ir("%s:", end_label);

    // Restore context
    current_break_label = old_break_label;
    current_continue_label = old_continue_label;

    // Free the labels
    free(cond_label);
    free(body_label);
    free(inc_label);
    free(end_label);

    return NULL;
}

case NODE_IF_STMT: {
    ASTNode* condition_node = node->child;
    ASTNode* true_branch = condition_node ? condition_node->next : NULL;
    ASTNode* false_branch = true_branch ? true_branch->next : NULL;

    char* true_label = generate_label();
    char* false_label = generate_label();
    char* end_label = generate_label();

    // Generate condition
    char* cond_value = NULL;
    if (condition_node) {
        cond_value = generate_llvm_ir_from_ast(condition_node);
    }

    if (cond_value) {
        // Check if it's already a boolean (starts with '!')
        if (strcmp(condition_node->datatype,"bool")==0) {
            // Already a boolean temp - use directly
            emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                        cond_value , true_label, false_label);
        } else {
            // Not a boolean - compare to zero
            char* cmp_temp = generate_temp();
            emit_llvm_ir("  %s = icmp ne i32 %s, 0", cmp_temp, cond_value);
            emit_llvm_ir("  br i1 %s, label %%%s, label %%%s", 
                        cmp_temp, true_label, false_label);
            free(cmp_temp);
        }
        free(cond_value);
    } else {
        // No condition - always take true branch
        emit_llvm_ir("  br label %%%s", true_label);
    }

    // True branch
    emit_llvm_ir("%s:", true_label);
    if (true_branch) {
        generate_llvm_ir_from_ast(true_branch);
    }
    // Jump to end after true branch (unless it already has a terminator)
    emit_llvm_ir("  br label %%%s", end_label);

    // False branch
    emit_llvm_ir("%s:", false_label);
    if (false_branch) {
        generate_llvm_ir_from_ast(false_branch);
    }
    // Jump to end after false branch (unless it already has a terminator)
    emit_llvm_ir("  br label %%%s", end_label);

    // End label
    emit_llvm_ir("%s:", end_label);

    free(true_label);
    free(false_label);
    free(end_label);
    return NULL;
}

case NODE_BINARY_OP: {
    char* left_val = NULL;
    char* right_val = NULL;
    char* left_raw = NULL;
    char* right_raw = NULL;

    char* left_type = get_complete_llvm_type(node->left);
    char* right_type = get_complete_llvm_type(node->right);

    printf("left : %s , right %s \n", left_type, right_type);
    
    char* left_base_type = strdup(left_type);
    char* right_base_type = strdup(right_type);

    if(node->left->is_array){
        left_base_type = get_llvm_base_type(node->left->datatype);
    }

    if(node->right->is_array){
        right_base_type = get_llvm_base_type(node->right->datatype);
    }

    printf("left : %s , right %s \n", left_type, right_type);

    // Use the dominant type for the operation
    char* result_type = left_type;
    
    // Check if either type is floating point
    int left_is_float = (strstr(left_type, "float") != NULL) || (strstr(left_type, "double") != NULL);
    int right_is_float = (strstr(right_type, "float") != NULL) || (strstr(right_type, "double") != NULL);
    
    if (strstr(left_type, "double") != NULL || strstr(right_type, "double") != NULL) {
        result_type = "double";
    } else if (left_is_float || right_is_float) {
        result_type = "float";
    } else if (strstr(left_type, "i64") != NULL || strstr(right_type, "i64") != NULL) {
        result_type = "i64";
    } else if (strstr(left_type, "i32") != NULL || strstr(right_type, "i32") != NULL) {
        result_type = "i32";
    } else if (strstr(left_type, "i16") != NULL || strstr(right_type, "i16") != NULL) {
        result_type = "i16";
    } else if (strstr(left_type, "i8") != NULL || strstr(right_type, "i8") != NULL) {
        result_type = "i8";
    } else if (strstr(left_type, "i1") != NULL || strstr(right_type, "i1") != NULL) {
        result_type = "i1";
    }

    // Handle identifier nodes (load values)
    if (node->left->type == NODE_IDENTIFIER) {
        left_raw = strdup(node->left->value);
        left_val = generate_temp();
        SymbolEntry* symbol = find_symbol(left_raw);
        if(symbol && symbol->is_static){
            emit_llvm_ir("  %s = load %s, %s* @%s, %s", left_val, left_type, left_type, left_raw, get_alignment_str(left_base_type));
        } else {
            if (node->left->is_parameter){
                emit_llvm_ir("  %s = load %s, %s* %%%s.addr, %s", left_val, left_type, left_type, left_raw, get_alignment_str(left_base_type));
            } else {
                emit_llvm_ir("  %s = load %s, %s* %%%s, %s", left_val, left_type, left_type, left_raw, get_alignment_str(left_base_type));
            }
        }
    } else {
        left_val = generate_llvm_ir_from_ast(node->left);
    }

    if (node->right->type == NODE_IDENTIFIER) {
        right_raw = strdup(node->right->value);
        right_val = generate_temp();
        SymbolEntry* symbol = find_symbol(right_raw);
        if(symbol && symbol->is_static){
            emit_llvm_ir("  %s = load %s, %s* @%s, %s", right_val, right_type, right_type, right_raw, get_alignment_str(right_base_type));
        } else {
            if(node->right->is_parameter){
                emit_llvm_ir("  %s = load %s, %s* %%%s.addr, %s", right_val, right_type, right_type, right_raw, get_alignment_str(right_base_type));
            } else {
                emit_llvm_ir("  %s = load %s, %s* %%%s, %s", right_val, right_type, right_type, right_raw, get_alignment_str(right_base_type));
            }
        }
    } else {
        right_val = generate_llvm_ir_from_ast(node->right);
    }

    if (!left_val) left_val = strdup("0");
    if (!right_val) right_val = strdup("0");

    char* result = generate_temp();

    // Handle type conversions if needed
    char* converted_left = left_val;
    char* converted_right = right_val;

    printf("left : %s , right %s , result %s \n", left_type, right_type, result_type);

   // Check if conversion needed for left operand
if (strcmp(left_type, result_type) != 0) {
    converted_left = generate_temp();
    
    // Convert to double
    if ((strcmp(result_type, "double") == 0) && 
        (strcmp(left_type, "i32") == 0 || strcmp(left_type, "i64") == 0 || 
         strcmp(left_type, "i16") == 0 || strcmp(left_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sitofp %s %s to double", converted_left, left_type, left_val);
    } 
    // Convert to float
    else if ((strcmp(result_type, "float") == 0) && 
             (strcmp(left_type, "i32") == 0 || strcmp(left_type, "i64") == 0 || 
              strcmp(left_type, "i16") == 0 || strcmp(left_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sitofp %s %s to float", converted_left, left_type, left_val);
    } 
    // Float to double extension
    else if ((strcmp(result_type, "double") == 0) && (strcmp(left_type, "float") == 0)) {
        emit_llvm_ir("  %s = fpext float %s to double", converted_left, left_val);
    } 
    // Double to float truncation
    else if ((strcmp(result_type, "float") == 0) && (strcmp(left_type, "double") == 0)) {
        emit_llvm_ir("  %s = fptrunc double %s to float", converted_left, left_val);
    }
    // Convert to i64 (sign extension)
    else if ((strcmp(result_type, "i64") == 0) && 
             (strcmp(left_type, "i32") == 0 || strcmp(left_type, "i16") == 0 || 
              strcmp(left_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sext %s %s to i64", converted_left, left_type, left_val);
    }
    // Convert to i32 (sign extension)
    else if ((strcmp(result_type, "i32") == 0) && 
             (strcmp(left_type, "i16") == 0 || strcmp(left_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sext %s %s to i32", converted_left, left_type, left_val);
    }
    // Convert to i16 (sign extension)
    else if ((strcmp(result_type, "i16") == 0) && (strcmp(left_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sext %s %s to i16", converted_left, left_type, left_val);
    }
    // Convert from i64 to smaller integers (truncation)
    else if ((strcmp(left_type, "i64") == 0) && 
             (strcmp(result_type, "i32") == 0 || strcmp(result_type, "i16") == 0 || 
              strcmp(result_type, "i8") == 0)) {
        emit_llvm_ir("  %s = trunc i64 %s to %s", converted_left, left_val, result_type);
    }
    // Convert from i32 to smaller integers (truncation)
    else if ((strcmp(left_type, "i32") == 0) && 
             (strcmp(result_type, "i16") == 0 || strcmp(result_type, "i8") == 0)) {
        emit_llvm_ir("  %s = trunc i32 %s to %s", converted_left, left_val, result_type);
    }
    // Convert from i16 to i8 (truncation)
    else if ((strcmp(left_type, "i16") == 0) && (strcmp(result_type, "i8") == 0)) {
        emit_llvm_ir("  %s = trunc i16 %s to i8", converted_left, left_val);
    }
    // Floating point to integer conversion
    else if ((strcmp(result_type, "i32") == 0 || strcmp(result_type, "i64") == 0 || 
              strcmp(result_type, "i16") == 0 || strcmp(result_type, "i8") == 0) &&
             (strcmp(left_type, "float") == 0 || strcmp(left_type, "double") == 0)) {
        emit_llvm_ir("  %s = fptosi %s %s to %s", converted_left, left_type, left_val, result_type);
    }
    // Integer to integer (same size but different signedness - use bitcast)
    else if ((strcmp(result_type, "i32") == 0 && strcmp(left_type, "i32") == 0) ||
             (strcmp(result_type, "i64") == 0 && strcmp(left_type, "i64") == 0) ||
             (strcmp(result_type, "i16") == 0 && strcmp(left_type, "i16") == 0) ||
             (strcmp(result_type, "i8") == 0 && strcmp(left_type, "i8") == 0)) {
        // For same-size integers with different signedness, use bitcast
        emit_llvm_ir("  %s = bitcast %s %s to %s", converted_left, left_type, left_val, result_type);
    }
    // Pointer type conversions
    else if (strstr(result_type, "*") != NULL && strstr(left_type, "*") != NULL) {
        // Pointer to pointer conversion - use bitcast
        emit_llvm_ir("  %s = bitcast %s %s to %s", converted_left, left_type, left_val, result_type);
    }
    else {
        // No conversion available or not supported - use original value
        converted_left = left_val;
    }
    }

  // Check if conversion needed for right operand  
if (strcmp(right_type, result_type) != 0) {
    converted_right = generate_temp();
    
    // Convert to double
    if ((strcmp(result_type, "double") == 0) && 
        (strcmp(right_type, "i32") == 0 || strcmp(right_type, "i64") == 0 || 
         strcmp(right_type, "i16") == 0 || strcmp(right_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sitofp %s %s to double", converted_right, right_type, right_val);
    } 
    // Convert to float
    else if ((strcmp(result_type, "float") == 0) && 
             (strcmp(right_type, "i32") == 0 || strcmp(right_type, "i64") == 0 || 
              strcmp(right_type, "i16") == 0 || strcmp(right_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sitofp %s %s to float", converted_right, right_type, right_val);
    } 
    // Float to double extension
    else if ((strcmp(result_type, "double") == 0) && (strcmp(right_type, "float") == 0)) {
        emit_llvm_ir("  %s = fpext float %s to double", converted_right, right_val);
    } 
    // Double to float truncation
    else if ((strcmp(result_type, "float") == 0) && (strcmp(right_type, "double") == 0)) {
        emit_llvm_ir("  %s = fptrunc double %s to float", converted_right, right_val);
    }
    // Convert to i64 (sign extension)
    else if ((strcmp(result_type, "i64") == 0) && 
             (strcmp(right_type, "i32") == 0 || strcmp(right_type, "i16") == 0 || 
              strcmp(right_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sext %s %s to i64", converted_right, right_type, right_val);
    }
    // Convert to i32 (sign extension)
    else if ((strcmp(result_type, "i32") == 0) && 
             (strcmp(right_type, "i16") == 0 || strcmp(right_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sext %s %s to i32", converted_right, right_type, right_val);
    }
    // Convert to i16 (sign extension)
    else if ((strcmp(result_type, "i16") == 0) && (strcmp(right_type, "i8") == 0)) {
        emit_llvm_ir("  %s = sext %s %s to i16", converted_right, right_type, right_val);
    }
    // Convert from i64 to smaller integers (truncation)
    else if ((strcmp(right_type, "i64") == 0) && 
             (strcmp(result_type, "i32") == 0 || strcmp(result_type, "i16") == 0 || 
              strcmp(result_type, "i8") == 0)) {
        emit_llvm_ir("  %s = trunc i64 %s to %s", converted_right, right_val, result_type);
    }
    // Convert from i32 to smaller integers (truncation)
    else if ((strcmp(right_type, "i32") == 0) && 
             (strcmp(result_type, "i16") == 0 || strcmp(result_type, "i8") == 0)) {
        emit_llvm_ir("  %s = trunc i32 %s to %s", converted_right, right_val, result_type);
    }
    // Convert from i16 to i8 (truncation)
    else if ((strcmp(right_type, "i16") == 0) && (strcmp(result_type, "i8") == 0)) {
        emit_llvm_ir("  %s = trunc i16 %s to i8", converted_right, right_val);
    }
    // Floating point to integer conversion
    else if ((strcmp(result_type, "i32") == 0 || strcmp(result_type, "i64") == 0 || 
              strcmp(result_type, "i16") == 0 || strcmp(result_type, "i8") == 0) &&
             (strcmp(right_type, "float") == 0 || strcmp(right_type, "double") == 0)) {
        emit_llvm_ir("  %s = fptosi %s %s to %s", converted_right, right_type, right_val, result_type);
    }
    // Integer to integer (same size but different signedness - use bitcast)
    else if ((strcmp(result_type, "i32") == 0 && strcmp(right_type, "i32") == 0) ||
             (strcmp(result_type, "i64") == 0 && strcmp(right_type, "i64") == 0) ||
             (strcmp(result_type, "i16") == 0 && strcmp(right_type, "i16") == 0) ||
             (strcmp(result_type, "i8") == 0 && strcmp(right_type, "i8") == 0)) {
        // For same-size integers with different signedness, use bitcast
        emit_llvm_ir("  %s = bitcast %s %s to %s", converted_right, right_type, right_val, result_type);
    }
    // Pointer type conversions
    else if (strstr(result_type, "*") != NULL && strstr(right_type, "*") != NULL) {
        // Pointer to pointer conversion - use bitcast
        emit_llvm_ir("  %s = bitcast %s %s to %s", converted_right, right_type, right_val, result_type);
    }
    else {
        // No conversion available or not supported - use original value
        converted_right = right_val;
    }
    }

    // Determine if operation is floating point
    int is_float_op = (strcmp(result_type, "float") == 0) || (strcmp(result_type, "double") == 0);
    int is_integer_op = !is_float_op && strcmp(result_type, "i1") != 0;

    // ========== ARITHMETIC OPERATORS ==========
    if (strcmp(node->op, "+") == 0) {
        if (is_float_op) {
            emit_llvm_ir("  %s = fadd %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  %s = add nsw %s %s, %s", result, result_type, converted_left, converted_right);
        }
    } 
    else if (strcmp(node->op, "-") == 0) {
        if (is_float_op) {
            emit_llvm_ir("  %s = fsub %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  %s = sub nsw %s %s, %s", result, result_type, converted_left, converted_right);
        }
    } 
    else if (strcmp(node->op, "*") == 0) {
        if (is_float_op) {
            emit_llvm_ir("  %s = fmul %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  %s = mul nsw %s %s, %s", result, result_type, converted_left, converted_right);
        }
    } 
    else if (strcmp(node->op, "/") == 0) {
        if (is_float_op) {
            emit_llvm_ir("  %s = fdiv %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  %s = sdiv %s %s, %s", result, result_type, converted_left, converted_right);
        }
    } 
    else if (strcmp(node->op, "%") == 0) {
        if (is_float_op) {
            emit_llvm_ir("  %s = frem %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  %s = srem %s %s, %s", result, result_type, converted_left, converted_right);
        }
    }

    // ========== BITWISE OPERATORS ==========
    else if (strcmp(node->op, "&") == 0) {
        if (is_integer_op) {
            emit_llvm_ir("  %s = and %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  ; ERROR: Bitwise AND on non-integer type");
            emit_llvm_ir("  %s = and i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, "|") == 0) {
        if (is_integer_op) {
            emit_llvm_ir("  %s = or %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  ; ERROR: Bitwise OR on non-integer type");
            emit_llvm_ir("  %s = or i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, "^") == 0) {
        if (is_integer_op) {
            emit_llvm_ir("  %s = xor %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  ; ERROR: Bitwise XOR on non-integer type");
            emit_llvm_ir("  %s = xor i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, "<<") == 0) {
        if (is_integer_op) {
            emit_llvm_ir("  %s = shl %s %s, %s", result, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  ; ERROR: Left shift on non-integer type");
            emit_llvm_ir("  %s = shl i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, ">>") == 0) {
        if (is_integer_op) {
            // Use arithmetic right shift for signed integers, logical for unsigned
            if (node->left->datatype && strstr(node->left->datatype, "unsigned") != NULL) {
                emit_llvm_ir("  %s = lshr %s %s, %s", result, result_type, converted_left, converted_right);
            } else {
                emit_llvm_ir("  %s = ashr %s %s, %s", result, result_type, converted_left, converted_right);
            }
        } else {
            emit_llvm_ir("  ; ERROR: Right shift on non-integer type");
            emit_llvm_ir("  %s = ashr i32 0, 0", result);
        }
    }

    // ========== RELATIONAL OPERATORS ==========
    else if (strcmp(node->op, "==") == 0 || strcmp(node->op, "!=") == 0 ||
             strcmp(node->op, "<") == 0 || strcmp(node->op, "<=") == 0 ||
             strcmp(node->op, ">") == 0 || strcmp(node->op, ">=") == 0) {

        const char* pred = "eq";
        const char* float_pred = "oeq";

        if (strcmp(node->op, "<") == 0) { pred = "slt"; float_pred = "olt"; }
        else if (strcmp(node->op, "<=") == 0) { pred = "sle"; float_pred = "ole"; }
        else if (strcmp(node->op, ">") == 0) { pred = "sgt"; float_pred = "ogt"; }
        else if (strcmp(node->op, ">=") == 0) { pred = "sge"; float_pred = "oge"; }
        else if (strcmp(node->op, "==") == 0) { pred = "eq"; float_pred = "oeq"; }
        else if (strcmp(node->op, "!=") == 0) { pred = "ne"; float_pred = "one"; }

        if (is_float_op) {
            emit_llvm_ir("  %s = fcmp %s %s %s, %s", result, float_pred, result_type, converted_left, converted_right);
        } else {
            emit_llvm_ir("  %s = icmp %s %s %s, %s", result, pred, result_type, converted_left, converted_right);
        }
    }

    // ========== LOGICAL OPERATORS ==========
    else if (strcmp(node->op, "&&") == 0) {
        // Convert both operands to i1 if needed, then AND them
        char* left_bool = generate_temp();
        char* right_bool = generate_temp();
        
        if (strcmp(result_type, "i1") == 0) {
            // Already booleans
            left_bool = converted_left;
            right_bool = converted_right;
        } else {
            // Convert to boolean (compare with zero)
            if (is_float_op) {
                emit_llvm_ir("  %s = fcmp one %s %s, 0.0", left_bool, result_type, converted_left);
                emit_llvm_ir("  %s = fcmp one %s %s, 0.0", right_bool, result_type, converted_right);
            } else {
                emit_llvm_ir("  %s = icmp ne %s %s, 0", left_bool, result_type, converted_left);
                emit_llvm_ir("  %s = icmp ne %s %s, 0", right_bool, result_type, converted_right);
            }
        }
        
        emit_llvm_ir("  %s = and i1 %s, %s", result, left_bool, right_bool);
        
        if (left_bool != converted_left) free(left_bool);
        if (right_bool != converted_right) free(right_bool);
    }
    else if (strcmp(node->op, "||") == 0) {
        // Convert both operands to i1 if needed, then OR them
        char* left_bool = generate_temp();
        char* right_bool = generate_temp();
        
        if (strcmp(result_type, "i1") == 0) {
            // Already booleans
            left_bool = converted_left;
            right_bool = converted_right;
        } else {
            // Convert to boolean (compare with zero)
            if (is_float_op) {
                emit_llvm_ir("  %s = fcmp one %s %s, 0.0", left_bool, result_type, converted_left);
                emit_llvm_ir("  %s = fcmp one %s %s, 0.0", right_bool, result_type, converted_right);
            } else {
                emit_llvm_ir("  %s = icmp ne %s %s, 0", left_bool, result_type, converted_left);
                emit_llvm_ir("  %s = icmp ne %s %s, 0", right_bool, result_type, converted_right);
            }
        }
        
        emit_llvm_ir("  %s = or i1 %s, %s", result, left_bool, right_bool);
        
        if (left_bool != converted_left) free(left_bool);
        if (right_bool != converted_right) free(right_bool);
    }

    // ========== ASSIGNMENT OPERATORS ==========
    else if (strcmp(node->op, "=") == 0) {
        // Simple assignment - store right value to left address
        emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, converted_right, result_type, converted_left, get_alignment_str(left_base_type));
        // Return the assigned value
        emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
    }
    else if (strcmp(node->op, "+=") == 0) {
        if (is_float_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = fadd %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        } else {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = add nsw %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        }
        emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
    }
    else if (strcmp(node->op, "-=") == 0) {
        if (is_float_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = fsub %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        } else {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = sub nsw %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        }
        emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
    }
    else if (strcmp(node->op, "*=") == 0) {
        if (is_float_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = fmul %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        } else {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = mul nsw %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        }
        emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
    }
    else if (strcmp(node->op, "/=") == 0) {
        if (is_float_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = fdiv %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        } else {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = sdiv %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        }
        emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
    }
    else if (strcmp(node->op, "%=") == 0) {
        if (is_float_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = frem %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        } else {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = srem %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
        }
        emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
    }
    else if (strcmp(node->op, "&=") == 0) {
        if (is_integer_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = and %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
            emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
        } else {
            emit_llvm_ir("  ; ERROR: Bitwise AND assignment on non-integer type");
            emit_llvm_ir("  %s = add i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, "|=") == 0) {
        if (is_integer_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = or %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
            emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
        } else {
            emit_llvm_ir("  ; ERROR: Bitwise OR assignment on non-integer type");
            emit_llvm_ir("  %s = add i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, "^=") == 0) {
        if (is_integer_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = xor %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
            emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
        } else {
            emit_llvm_ir("  ; ERROR: Bitwise XOR assignment on non-integer type");
            emit_llvm_ir("  %s = add i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, "<<=") == 0) {
        if (is_integer_op) {
            char* new_val = generate_temp();
            emit_llvm_ir("  %s = shl %s %s, %s", new_val, result_type, converted_left, converted_right);
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
            emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
        } else {
            emit_llvm_ir("  ; ERROR: Left shift assignment on non-integer type");
            emit_llvm_ir("  %s = add i32 0, 0", result);
        }
    }
    else if (strcmp(node->op, ">>=") == 0) {
        if (is_integer_op) {
            char* new_val = generate_temp();
            if (node->left->datatype && strstr(node->left->datatype, "unsigned") != NULL) {
                emit_llvm_ir("  %s = lshr %s %s, %s", new_val, result_type, converted_left, converted_right);
            } else {
                emit_llvm_ir("  %s = ashr %s %s, %s", new_val, result_type, converted_left, converted_right);
            }
            emit_llvm_ir("  store %s %s, %s* %s, %s", result_type, new_val, result_type, converted_left, get_alignment_str(left_base_type));
            free(new_val);
            emit_llvm_ir("  %s = load %s, %s* %s, %s", result, result_type, result_type, converted_left, get_alignment_str(left_base_type));
        } else {
            emit_llvm_ir("  ; ERROR: Right shift assignment on non-integer type");
            emit_llvm_ir("  %s = add i32 0, 0", result);
        }
    }

    // ========== COMMA OPERATOR ==========
    else if (strcmp(node->op, ",") == 0) {
        // Comma operator: evaluate left, then right, return right
        emit_llvm_ir("  ; Comma operator - evaluating left then right");
        if (strcmp(result_type, "i1") == 0 && converted_right[0] != '!') {
            char* cmp_temp = generate_temp();
            emit_llvm_ir("  %s = icmp ne %s %s, 0", cmp_temp, result_type, converted_right);
            emit_llvm_ir("  %s = add i1 0, %s", result, cmp_temp);
            free(cmp_temp);
        } else {
            emit_llvm_ir("  %s = add %s 0, %s", result, result_type, converted_right);
        }
    }

    // ========== UNSUPPORTED OPERATOR ==========
    else {
        emit_llvm_ir("  ; ERROR: Unsupported binary operator '%s'", node->op);
        emit_llvm_ir("  %s = add %s 0, 0", result, result_type);
    }

cleanup:
    if (left_raw) free(left_raw);
    if (right_raw) free(right_raw);
    if (left_val && left_val != converted_left) free(left_val);
    if (right_val && right_val != converted_right) free(right_val);
    if (converted_left != left_val) free(converted_left);
    if (converted_right != right_val) free(converted_right);
    if (left_base_type) free(left_base_type);
    if (right_base_type) free(right_base_type);
    return strdup(result);
}

case NODE_TERNARY_OP: {
    // Ternary operator: condition ? true_expr : false_expr
    // Structure: child = condition, left = true_expr, right = false_expr
    
    ASTNode* condition_node = node->child;
    ASTNode* true_node = node->left;
    ASTNode* false_node = node->right;
    
    // Validate we have all three components
    if (!condition_node || !true_node || !false_node) {
        printf("Error: Invalid ternary operator structure - missing components\n");
        return NULL;
    }
    
    printf("Ternary components: condition=%s, true=%s, false=%s\n",
           node_type_to_string(condition_node->type),
           node_type_to_string(true_node->type), 
           node_type_to_string(false_node->type));
    
    // Generate IR for all three components
    char* condition_val = generate_llvm_ir_from_ast(condition_node);
    char* true_val = generate_llvm_ir_from_ast(true_node);
    char* false_val = generate_llvm_ir_from_ast(false_node);

    printf("condition value : %s \n",condition_val);
    
    if (!condition_val || !true_val || !false_val) {
        if (condition_val) free(condition_val);
        if (true_val) free(true_val);
        if (false_val) free(false_val);
        return NULL;
    }
    
    // Get types for type conversion
    char* result_type = get_complete_llvm_type(node);
    char* condition_type = get_complete_llvm_type(condition_node);
    char* true_type = get_complete_llvm_type(true_node);
    char* false_type = get_complete_llvm_type(false_node);
    
    printf("Ternary types - condition: %s, true: %s, false: %s, result: %s\n", 
           condition_type, true_type, false_type, result_type);
    
    // Step 1: Convert condition to i1 (boolean)
    char* condition_bool = condition_val;
    
    if (strcmp(condition_type, "i1") != 0) {
        condition_bool = generate_temp();
        if (strcmp(condition_type, "float") == 0 || strcmp(condition_type, "double") == 0) {
            // Floating point: compare with 0.0
            emit_llvm_ir("  %s = fcmp one %s %s, 0.0", condition_bool, condition_type, condition_val);
        } else {
            // Integer types: compare with 0
            emit_llvm_ir("  %s = icmp ne %s %s, 0", condition_bool, condition_type, condition_val);
        }
    }
    
    // Step 2: Handle type conversions for true and false expressions
    char* converted_true = true_val;
    char* converted_false = false_val;
    
    // Convert true expression to result type if needed
    if (strcmp(true_type, result_type) != 0) {
        converted_true = generate_temp();
        
        // Integer to floating point
        if ((strcmp(result_type, "double") == 0) && 
            (strcmp(true_type, "i32") == 0 || strcmp(true_type, "i64") == 0 || 
             strcmp(true_type, "i16") == 0 || strcmp(true_type, "i8") == 0)) {
            emit_llvm_ir("  %s = sitofp %s %s to double", converted_true, true_type, true_val);
        }
        else if ((strcmp(result_type, "float") == 0) && 
                (strcmp(true_type, "i32") == 0 || strcmp(true_type, "i64") == 0 || 
                 strcmp(true_type, "i16") == 0 || strcmp(true_type, "i8") == 0)) {
            emit_llvm_ir("  %s = sitofp %s %s to float", converted_true, true_type, true_val);
        }
        // Floating point to floating point
        else if ((strcmp(result_type, "double") == 0) && (strcmp(true_type, "float") == 0)) {
            emit_llvm_ir("  %s = fpext float %s to double", converted_true, true_val);
        }
        else if ((strcmp(result_type, "float") == 0) && (strcmp(true_type, "double") == 0)) {
            emit_llvm_ir("  %s = fptrunc double %s to float", converted_true, true_val);
        }
        // Floating point to integer
        else if ((strcmp(result_type, "i32") == 0) && (strcmp(true_type, "double") == 0 || strcmp(true_type, "float") == 0)) {
            emit_llvm_ir("  %s = fptosi %s %s to i32", converted_true, true_type, true_val);
        }
        else if ((strcmp(result_type, "i64") == 0) && (strcmp(true_type, "double") == 0 || strcmp(true_type, "float") == 0)) {
            emit_llvm_ir("  %s = fptosi %s %s to i64", converted_true, true_type, true_val);
        }
        // Integer to integer (different sizes)
        else if (strcmp(result_type, "i32") == 0 && strcmp(true_type, "i64") == 0) {
            emit_llvm_ir("  %s = trunc i64 %s to i32", converted_true, true_val);
        }
        else if (strcmp(result_type, "i64") == 0 && strcmp(true_type, "i32") == 0) {
            emit_llvm_ir("  %s = sext i32 %s to i64", converted_true, true_val);
        }
        else if (strcmp(result_type, "i32") == 0 && strcmp(true_type, "i16") == 0) {
            emit_llvm_ir("  %s = sext i16 %s to i32", converted_true, true_val);
        }
        else if (strcmp(result_type, "i32") == 0 && strcmp(true_type, "i8") == 0) {
            emit_llvm_ir("  %s = sext i8 %s to i32", converted_true, true_val);
        }
        // Boolean to integer
        else if ((strcmp(result_type, "i32") == 0 || strcmp(result_type, "i64") == 0) && 
                 true_val[0] == '!') {
            emit_llvm_ir("  %s = zext i1 %s to %s", converted_true, true_val + 1, result_type);
        }
        else {
            // No conversion possible or needed
            converted_true = true_val;
        }
    }
    
    // Convert false expression to result type if needed
    if (strcmp(false_type, result_type) != 0) {
        converted_false = generate_temp();
        
        // Integer to floating point
        if ((strcmp(result_type, "double") == 0) && 
            (strcmp(false_type, "i32") == 0 || strcmp(false_type, "i64") == 0 || 
             strcmp(false_type, "i16") == 0 || strcmp(false_type, "i8") == 0)) {
            emit_llvm_ir("  %s = sitofp %s %s to double", converted_false, false_type, false_val);
        }
        else if ((strcmp(result_type, "float") == 0) && 
                (strcmp(false_type, "i32") == 0 || strcmp(false_type, "i64") == 0 || 
                 strcmp(false_type, "i16") == 0 || strcmp(false_type, "i8") == 0)) {
            emit_llvm_ir("  %s = sitofp %s %s to float", converted_false, false_type, false_val);
        }
        // Floating point to floating point
        else if ((strcmp(result_type, "double") == 0) && (strcmp(false_type, "float") == 0)) {
            emit_llvm_ir("  %s = fpext float %s to double", converted_false, false_val);
        }
        else if ((strcmp(result_type, "float") == 0) && (strcmp(false_type, "double") == 0)) {
            emit_llvm_ir("  %s = fptrunc double %s to float", converted_false, false_val);
        }
        // Floating point to integer
        else if ((strcmp(result_type, "i32") == 0) && (strcmp(false_type, "double") == 0 || strcmp(false_type, "float") == 0)) {
            emit_llvm_ir("  %s = fptosi %s %s to i32", converted_false, false_type, false_val);
        }
        else if ((strcmp(result_type, "i64") == 0) && (strcmp(false_type, "double") == 0 || strcmp(false_type, "float") == 0)) {
            emit_llvm_ir("  %s = fptosi %s %s to i64", converted_false, false_type, false_val);
        }
        // Integer to integer (different sizes)
        else if (strcmp(result_type, "i32") == 0 && strcmp(false_type, "i64") == 0) {
            emit_llvm_ir("  %s = trunc i64 %s to i32", converted_false, false_val);
        }
        else if (strcmp(result_type, "i64") == 0 && strcmp(false_type, "i32") == 0) {
            emit_llvm_ir("  %s = sext i32 %s to i64", converted_false, false_val);
        }
        else if (strcmp(result_type, "i32") == 0 && strcmp(false_type, "i16") == 0) {
            emit_llvm_ir("  %s = sext i16 %s to i32", converted_false, false_val);
        }
        else if (strcmp(result_type, "i32") == 0 && strcmp(false_type, "i8") == 0) {
            emit_llvm_ir("  %s = sext i8 %s to i32", converted_false, false_val);
        }
        // Boolean to integer
        else if ((strcmp(result_type, "i32") == 0 || strcmp(result_type, "i64") == 0) && 
                 false_val[0] == '!') {
            emit_llvm_ir("  %s = zext i1 %s to %s", converted_false, false_val + 1, result_type);
        }
        else {
            // No conversion possible or needed
            converted_false = false_val;
        }
    }
    
    // Step 3: Generate the select instruction
    char* result = generate_temp();
    emit_llvm_ir("  %s = select i1 %s, %s %s, %s %s", 
                 result, condition_bool, result_type, converted_true, result_type, converted_false);
    
    // Step 4: Cleanup - only free what we allocated
    if (condition_bool != condition_val) {
        free(condition_bool);
    }
    free(condition_val);
    
    if (converted_true != true_val) {
        free(converted_true);
    } else {
        free(true_val);
    }
    
    if (converted_false != false_val) {
        free(converted_false);
    } else {
        free(false_val);
    }
    
    return strdup(result);
}

case NODE_ASSIGNMENT: {
    /* left should be identifier node; node->op holds the assignment operator */
    char* var_name = NULL;

    // Handle array element assignment: arr[i] = value
    // Handle multi-dimensional array element assignment: arr[i][j] = value
    if (node->left && node->left->type == NODE_INDEX) {

        ASTNode* current = node->left;
        ASTNode* base_array = NULL;
        char* array_name = NULL;
        SymbolEntry* symbol = NULL;
        char* llvm_type=get_complete_llvm_type(node);
        char * base_llvm_type=strdup(llvm_type);

        if(node->is_array)
       base_llvm_type=get_llvm_base_type(node->datatype);

        // Collect all indices in reverse order (from outermost to innermost)
        ASTNode* indices[10]; // max 10 dimensions
        int index_count = 0;

        // Traverse the index chain to find the base array and collect indices
        while (current && current->type == NODE_INDEX) {
            indices[index_count++] = current;
            ASTNode* array_part = current->child;

            if (array_part && array_part->type == NODE_IDENTIFIER) {
                base_array = array_part;
                array_name = array_part->value;
                symbol = find_symbol(array_name);
                break;
            }
            current = array_part;
        }

        if (!base_array || !array_name || !symbol) return NULL;

        char* value_val = generate_llvm_ir_from_ast(node->right);
        if (!value_val) return NULL;

        // Generate all index expressions (from outermost to innermost)
        char* index_values[10];
        int actual_index_count = 0;

        for (int i = index_count-1; i >=0; i--) {
            ASTNode* index_node = indices[i]->child ? indices[i]->child->next : NULL;
            if (index_node) {
                // Use simplified value for literals to avoid redundant "add i32 0, constant"
                if (index_node->type == NODE_LITERAL ) {
                    index_values[i] = strdup(index_node->value);
                } else {
                    index_values[i] = get_index_value(index_node);
                }
            }
        }

        char* array_type = get_complete_llvm_type(base_array);
        
        char* element_ptr = generate_temp();

        // Build GEP instruction with all indices
        if (symbol->is_static) {
            // Global array
            char* load_temp = generate_temp();
            

            emit_llvm_ir("  %s = load %s, %s* @%s, %s", load_temp, array_type, array_type, array_name,get_alignment_str(base_llvm_type));

            // Build GEP with all indices
            char gep_str[512] = "";
            strcpy(gep_str, "i32 0");
            for (int i = 0; i < actual_index_count; i++) {
                char temp[64];
                sprintf(temp, ", i32 %s", index_values[i]);
                strcat(gep_str, temp);
            }

            emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, %s",
                         element_ptr, array_type, array_type, load_temp, gep_str);
            free(load_temp);
        } else {
            // Local array - build GEP with all indices
            char gep_str[512] = "";
            strcpy(gep_str, "i32 0");
            for (int i = 0; i < actual_index_count; i++) {
                char temp[64];
                sprintf(temp, ", i32 %s", index_values[i]);
                strcat(gep_str, temp);
            }

            emit_llvm_ir("  %s = getelementptr inbounds %s, %s* %%%s, %s",
                         element_ptr, array_type, array_type, array_name, gep_str);
        }

        // Store the value
        char* store_value = value_val;
        if (value_val[0] == '!') {
            // Boolean value
            store_value = generate_temp();
            emit_llvm_ir("  %s = zext i1 %s to i32", store_value, value_val + 1);
            free(value_val);
        }
        

        emit_llvm_ir("  store i32 %s, i32* %s, %s", store_value, element_ptr,get_alignment_str(base_llvm_type));

        if (store_value != value_val) free(store_value);
        free(element_ptr);
        for (int i = 0; i < actual_index_count; i++) {
            if (index_values[i]) free(index_values[i]);
        }
        return NULL;
    }

    // Handle pointer dereference assignment: *ptr = value
    if (node->left && node->left->type == NODE_UNARY_OP &&
        node->left->op && strcmp(node->left->op, "*") == 0) {
        ASTNode* ptr_node = node->left->child;
        ASTNode* value_node = node->right;
        char* llvm_type=get_complete_llvm_type(node);
        char * base_llvm_type=strdup(llvm_type);

            if(node->is_array)
            base_llvm_type=get_llvm_base_type(node->datatype);

        if (!ptr_node || !value_node) return NULL;

        char* ptr_val = generate_llvm_ir_from_ast(ptr_node);
        char* value_val = generate_llvm_ir_from_ast(value_node);

        if (!ptr_val || !value_val) {
            if (ptr_val) free(ptr_val);
            if (value_val) free(value_val);
            return NULL;
        }

        // Get the pointer base type
        char* base_type = "i32"; // Default
        if (ptr_node->datatype) {
            base_type = get_complete_llvm_type(ptr_node);
        }

        // Handle value storage through pointer
        if (value_val[0] == '!') {
            char* zext_temp = generate_temp();
            emit_llvm_ir("  %s = zext i1 %s to %s", zext_temp, value_val + 1, base_type);
            emit_llvm_ir("  store %s %s, %s* %s, %s", base_type, zext_temp, base_type, ptr_val,get_alignment_str(base_llvm_type));
            free(zext_temp);
        } else {
            emit_llvm_ir("  store %s %s, %s* %s, %s", base_type, value_val, base_type, ptr_val,get_alignment_str(base_llvm_type));
        }

        free(ptr_val);
        free(value_val);
        return NULL;
    }

    // Handle string assignment
    if (node->left && node->left->type == NODE_IDENTIFIER) {
        SymbolEntry* symbol = find_symbol(node->left->value);
        if (symbol && (strcmp(symbol->datatype, "string") == 0 || strcmp(symbol->datatype, "char*") == 0)) {

            // Handle string assignment
            char* string_value = generate_llvm_ir_from_ast(node->right);

            if (symbol->is_static) {
                emit_llvm_ir("  store i8* %s, i8** @%s, align 8", string_value, node->left->value);
            } else {
                emit_llvm_ir("  store i8* %s, i8** %%%s, align 8", string_value, node->left->value);
            }

            if (string_value) free(string_value);
            return NULL;
        }
    }
    // Handle pointer assignment: p = &a or p = q (where p and q are pointers)
    if (node->left && node->left->type == NODE_IDENTIFIER) {
        SymbolEntry* symbol = find_symbol(node->left->value);
        if (symbol && symbol->is_pointer) {
            // This is a pointer variable assignment
            char* pointer_value = generate_llvm_ir_from_ast(node->right);
            if (!pointer_value) return NULL;

            char* pointer_type = get_complete_llvm_type(node->left);
            char* base_llvm_type=strdup(pointer_type);

            if(node->left->is_array){
              base_llvm_type=get_llvm_base_type(node->left->datatype);
            }

            if (symbol->is_static) {
                // Global pointer
                emit_llvm_ir("  store %s %s, %s* @%s, %s", pointer_type, pointer_value, pointer_type, node->left->value,get_alignment_str(base_llvm_type));
            } else {
                // Local pointer
                emit_llvm_ir("  store %s %s, %s* %%%s, %s", pointer_type, pointer_value, pointer_type, node->left->value,get_alignment_str(base_llvm_type));
            }

            free(pointer_value);
            return NULL;
        }
    }

// Handle LOCAL STATIC variable assignment - CHECK THIS FIRST
    if (node->left && node->left->type == NODE_IDENTIFIER && node->left->value) {
        SymbolEntry* symbol = find_symbol(node->left->value);
        if (symbol && symbol->is_static && strcmp(current_function, "") != 0) {
            char mangled_name[128];
            sprintf(mangled_name, "%s.%s", current_function, node->left->value);

            char* var_type = get_complete_llvm_type(node->left);
            char * base_llvm_type=strdup(var_type);

            if(node->is_array)
            base_llvm_type=get_llvm_base_type(node->datatype);

            char* right_value = node->right ? generate_llvm_ir_from_ast(node->right) : NULL;


            // Handle compound assignment operators for local static variables
            if (node->op && strcmp(node->op, "=") != 0) {
                /* Compound assignment: load var, apply op with RHS, store back */

                /* Load current value with alignment */
                char* cur = generate_temp();
                emit_llvm_ir("  %s = load %s, %s* @%s, %s", cur, var_type, var_type, mangled_name,get_alignment_str(base_llvm_type));

                /* Ensure RHS is correct type: if RHS is a marked i1, zext it to var_type */
                char* rhs = NULL;
                if (!right_value) {
                    rhs = strdup("0");
                } else if (right_value[0] == '!') {
                    rhs = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to %s", rhs, right_value + 1, var_type);
                    free(right_value);
                } else {
                    rhs = right_value;
                }

                /* Compute new value based on operator */
                char* res = generate_temp();
                if (strcmp(node->op, "+=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fadd %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = add nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "-=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fsub %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = sub nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "*=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fmul %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = mul nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "/=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fdiv %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = sdiv %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "%=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = frem %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = srem %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "&=") == 0) {
                    emit_llvm_ir("  %s = and %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "|=") == 0) {
                    emit_llvm_ir("  %s = or %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "^=") == 0) {
                    emit_llvm_ir("  %s = xor %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "<<=") == 0) {
                    emit_llvm_ir("  %s = shl %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, ">>=") == 0) {
                    emit_llvm_ir("  %s = ashr %s %s, %s", res, var_type, cur, rhs);
                } else {
                    /* Unknown compound operator - fall back to simple store */
                    char* store_value = rhs;
                    if (rhs[0] == '!') {
                        char* zext_tmp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to %s", zext_tmp, rhs + 1, var_type);
                        emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, zext_tmp, var_type, mangled_name,get_alignment_str(base_llvm_type));
                        free(zext_tmp);
                    } else {
                        emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, rhs, var_type, mangled_name,get_alignment_str(base_llvm_type));
                    }
                    free(cur);
                    if (rhs != right_value) free(rhs);
                    return NULL;
                }

                /* Store back with alignment */
                emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, res, var_type, mangled_name,get_alignment_str(base_llvm_type));

                /* free temps */
                free(cur);
                free(res);
                if (rhs != right_value) free(rhs);
                return NULL;
            }

            // Handle simple assignment for local static variables
            if (right_value) {
                char* store_value = right_value;
                if (right_value[0] == '!') {
                    char* zext_tmp = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to %s", zext_tmp, right_value + 1, var_type);
                    emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, zext_tmp, var_type, mangled_name,get_alignment_str(base_llvm_type));
                    free(zext_tmp);
                    free(right_value);
                } else {
                    emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, right_value, var_type, mangled_name,get_alignment_str(base_llvm_type));
                    free(right_value);
                }
            } else {
                /* no rhs -> store 0 */
                emit_llvm_ir("  store %s 0, %s* @%s, %s", var_type, var_type, mangled_name,get_alignment_str(base_llvm_type));
            }
            return NULL;
        }
    }

    // Handle GLOBAL STATIC variable assignment
    if (node->left && node->left->type == NODE_IDENTIFIER && node->left->value) {
        SymbolEntry* symbol = find_symbol(node->left->value);
        if (symbol && symbol->is_static && strcmp(current_function, "") == 0) {
            char* var_type = get_complete_llvm_type(node->left);
            char* right_value = node->right ? generate_llvm_ir_from_ast(node->right) : NULL;
            char * base_llvm_type=strdup(var_type);

            if(node->is_array)
            base_llvm_type=get_llvm_base_type(node->datatype);

            // Handle compound assignment operators for global static variables
            if (node->op && strcmp(node->op, "=") != 0) {
                /* Compound assignment: load var, apply op with RHS, store back */

                /* Load current value with alignment */
                char* cur = generate_temp();
                emit_llvm_ir("  %s = load %s, %s* @%s, %s", cur, var_type, var_type, node->left->value,get_alignment_str(base_llvm_type));

                /* Ensure RHS is correct type: if RHS is a marked i1, zext it to var_type */
                char* rhs = NULL;
                if (!right_value) {
                    rhs = strdup("0");
                } else if (right_value[0] == '!') {
                    rhs = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to %s", rhs, right_value + 1, var_type);
                    free(right_value);
                } else {
                    rhs = right_value;
                }

                /* Compute new value based on operator */
                char* res = generate_temp();
                if (strcmp(node->op, "+=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fadd %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = add nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "-=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fsub %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = sub nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "*=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fmul %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = mul nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "/=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fdiv %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = sdiv %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "%=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = frem %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = srem %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "&=") == 0) {
                    emit_llvm_ir("  %s = and %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "|=") == 0) {
                    emit_llvm_ir("  %s = or %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "^=") == 0) {
                    emit_llvm_ir("  %s = xor %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "<<=") == 0) {
                    emit_llvm_ir("  %s = shl %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, ">>=") == 0) {
                    emit_llvm_ir("  %s = ashr %s %s, %s", res, var_type, cur, rhs);
                } else {
                    /* Unknown compound operator - fall back to simple store */
                    char* store_value = rhs;
                    if (rhs[0] == '!') {
                        char* zext_tmp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to %s", zext_tmp, rhs + 1, var_type);
                        emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, zext_tmp, var_type, node->left->value,get_alignment_str(base_llvm_type));
                        free(zext_tmp);
                    } else {
                        emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, rhs, var_type, node->left->value,get_alignment_str(base_llvm_type));
                    }
                    free(cur);
                    if (rhs != right_value) free(rhs);
                    return NULL;
                }

                /* Store back with alignment */
                emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, res, var_type, node->left->value,get_alignment_str(base_llvm_type));

                /* free temps */
                free(cur);
                free(res);
                if (rhs != right_value) free(rhs);
                return NULL;
            }

            // Handle simple assignment for global static variables
            if (right_value) {
                char* store_value = right_value;
                if (right_value[0] == '!') {
                    char* zext_tmp = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to %s", zext_tmp, right_value + 1, var_type);
                    emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, zext_tmp, var_type, node->left->value,get_alignment_str(base_llvm_type));
                    free(zext_tmp);
                    free(right_value);
                } else {
                    emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, right_value, var_type, node->left->value,get_alignment_str(base_llvm_type));
                    free(right_value);
                }
            } else {
                /* no rhs -> store 0 */
                emit_llvm_ir("  store %s 0, %s* @%s, %s", var_type, var_type, node->left->value,get_alignment_str(base_llvm_type) );
            }
            return NULL;
        }
    }
    // Handle regular variable assignment
    if (node->left && node->left->type == NODE_IDENTIFIER && node->left->value) {
        var_name = strdup(node->left->value);

        // Check if this is a static variable
        SymbolEntry* symbol = find_symbol(var_name);
        int is_static = symbol ? symbol->is_static : 0;
        char* var_type = get_complete_llvm_type(node->left);
        char * base_llvm_type=strdup(var_type);
        if(node->is_array)
        base_llvm_type=get_llvm_base_type(node->datatype);

        /* Generate RHS */
        char* right_value = node->right ? generate_llvm_ir_from_ast(node->right) : NULL;

        if (var_name) {
            if (!node->op || strcmp(node->op, "=") == 0) {
                /* Simple store with alignment */
                if (right_value) {
                    char* store_value = right_value;

                    if (right_value[0] == '!') {
                        /* zext i1 -> var_type then store */
                        char* zext_tmp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to %s", zext_tmp, right_value + 1, var_type);
                        if (is_static) {
                            emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, zext_tmp, var_type, var_name,get_alignment_str(base_llvm_type));
                        } else {
                            emit_llvm_ir("  store %s %s, %s* %%%s, %s", var_type, zext_tmp, var_type, var_name,get_alignment_str(base_llvm_type));
                        }
                        free(zext_tmp);
                        free(right_value);
                    } else {
                        if (is_static) {
                            emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, right_value, var_type, var_name,get_alignment_str(base_llvm_type));
                        } else {
                            emit_llvm_ir("  store %s %s, %s* %%%s, %s", var_type, right_value, var_type, var_name,get_alignment_str(base_llvm_type));
                        }
                        free(right_value);
                    }
                } else {
                    /* no rhs -> store 0 */
                    if (is_static) {
                        emit_llvm_ir("  store %s 0, %s* @%s, %s", var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                    } else {
                        emit_llvm_ir("  store %s 0, %s* %%%s, %s", var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                    }
                }
            } else if (strcmp(node->op, "+=") == 0 || strcmp(node->op, "-=") == 0 ||
                       strcmp(node->op, "*=") == 0 || strcmp(node->op, "/=") == 0 ||
                       strcmp(node->op, "%=") == 0) {

                /* Compound assignment: load var, apply op with RHS, store back */

                /* Load current value with alignment */
                char* cur = generate_temp();
                if (is_static) {
                    emit_llvm_ir("  %s = load %s, %s* @%s, %s", cur, var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                } else {
                    emit_llvm_ir("  %s = load %s, %s* %%%s, %s", cur, var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                }

                /* Ensure RHS is correct type: if RHS is a marked i1, zext it to var_type */
                char* rhs = NULL;
                if (!right_value) {
                    rhs = strdup("0");
                } else if (right_value[0] == '!') {
                    rhs = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to %s", rhs, right_value + 1, var_type);
                    free(right_value);
                } else {
                    rhs = right_value;
                }

                /* Compute new value based on operator */
                char* res = generate_temp();
                if (strcmp(node->op, "+=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fadd %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = add nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "-=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fsub %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = sub nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "*=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fmul %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = mul nsw %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "/=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = fdiv %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = sdiv %s %s, %s", res, var_type, cur, rhs);
                    }
                } else if (strcmp(node->op, "%=") == 0) {
                    if (strcmp(var_type, "float") == 0 || strcmp(var_type, "double") == 0) {
                        emit_llvm_ir("  %s = frem %s %s, %s", res, var_type, cur, rhs);
                    } else {
                        emit_llvm_ir("  %s = srem %s %s, %s", res, var_type, cur, rhs);
                    }
                }

                /* Store back with alignment */
                if (is_static) {
                    emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, res, var_type, var_name,get_alignment_str(base_llvm_type));
                } else {
                    emit_llvm_ir("  store %s %s, %s* %%%s, %s", var_type, res, var_type, var_name,get_alignment_str(base_llvm_type));
                }

                /* free temps */
                free(cur);
                free(res);
                if (rhs != right_value) free(rhs); // Only free if we allocated
            } else if (strcmp(node->op, "&=") == 0 || strcmp(node->op, "|=") == 0 ||
                       strcmp(node->op, "^=") == 0 || strcmp(node->op, "<<=") == 0 ||
                       strcmp(node->op, ">>=") == 0) {

                /* Bitwise compound assignment (integer types only) */
                char* cur = generate_temp();
                if (is_static) {
                    emit_llvm_ir("  %s = load %s, %s* @%s, %s", cur, var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                } else {
                    emit_llvm_ir("  %s = load %s, %s* %%%s, %s", cur, var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                }

                char* rhs = NULL;
                if (!right_value) {
                    rhs = strdup("0");
                } else if (right_value[0] == '!') {
                    rhs = generate_temp();
                    emit_llvm_ir("  %s = zext i1 %s to %s", rhs, right_value + 1, var_type);
                    free(right_value);
                } else {
                    rhs = right_value;
                }

                char* res = generate_temp();
                if (strcmp(node->op, "&=") == 0) {
                    emit_llvm_ir("  %s = and %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "|=") == 0) {
                    emit_llvm_ir("  %s = or %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "^=") == 0) {
                    emit_llvm_ir("  %s = xor %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, "<<=") == 0) {
                    emit_llvm_ir("  %s = shl %s %s, %s", res, var_type, cur, rhs);
                } else if (strcmp(node->op, ">>=") == 0) {
                    emit_llvm_ir("  %s = ashr %s %s, %s", res, var_type, cur, rhs);
                }

                if (is_static) {
                    emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, res, var_type, var_name,get_alignment_str(base_llvm_type));
                } else {
                    emit_llvm_ir("  store %s %s, %s* %%%s, %s", var_type, res, var_type, var_name,get_alignment_str(base_llvm_type));
                }

                free(cur);
                free(res);
                if (rhs != right_value) free(rhs);
            } else {
                /* Unknown assignment operator: fall back to simple store */
                if (right_value) {
                    char* store_value = right_value;
                    if (right_value[0] == '!') {
                        char* zext_tmp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to %s", zext_tmp, right_value + 1, var_type);
                        if (is_static) {
                            emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, zext_tmp, var_type, var_name,get_alignment_str(base_llvm_type));
                        } else {
                            emit_llvm_ir("  store %s %s, %s* %%%s, %s", var_type, zext_tmp, var_type, var_name,get_alignment_str(base_llvm_type));
                        }
                        free(zext_tmp);
                        free(right_value);
                    } else {
                        if (is_static) {
                            emit_llvm_ir("  store %s %s, %s* @%s, %s", var_type, right_value, var_type, var_name,get_alignment_str(base_llvm_type));
                        } else {
                            emit_llvm_ir("  store %s %s, %s* %%%s, %s", var_type, right_value, var_type, var_name,get_alignment_str(base_llvm_type));
                        }
                        free(right_value);
                    }
                } else {
                    if (is_static) {
                        emit_llvm_ir("  store %s 0, %s* @%s, %s", var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                    } else {
                        emit_llvm_ir("  store %s 0, %s* %%%s, %s", var_type, var_type, var_name,get_alignment_str(base_llvm_type));
                    }
                }
            }
        }

        if (var_name) free(var_name);
        return NULL;
    }

    return NULL;
}

case NODE_FUNCTION_DEF: {
    ASTNode* type_node = node->child;
    ASTNode* name_node = type_node ? type_node->next : NULL;
    ASTNode* params_node = name_node ? name_node->next : NULL;
    ASTNode* body_node = params_node ? params_node->next : NULL;

    char* func_name = NULL;
    char* return_type = "i32"; // Default return type

    // Extract function name
    if (name_node && name_node->type == NODE_IDENTIFIER) {
        func_name = name_node->value;
    } else if (name_node && name_node->type == NODE_DECLARATOR) {
        // Extract identifier from declarator
        ASTNode* id_node = name_node->child;
        while (id_node && id_node->type != NODE_IDENTIFIER) {
            id_node = id_node->child;
        }
        if (id_node) func_name = id_node->value;
    }

    if (!func_name) func_name = "anonymous";

    // Determine return type from type_node
    if (type_node && type_node->type == NODE_TYPE && type_node->value) {
        if (strcmp(type_node->value, "void") == 0) {
            return_type = "void";
        } else if (strcmp(type_node->value, "float") == 0) {
            return_type = "float";
        } else if (strcmp(type_node->value, "double") == 0) {
            return_type = "double";
        } else if (strcmp(type_node->value, "char") == 0) {
            return_type = "i8";
        } else if (strcmp(type_node->value, "string") == 0 || strcmp(type_node->value, "char*") == 0) {
            return_type = "i8*";
        } else {
            return_type = "i32"; // int, bool, long, etc.
        }
    }

    // Store current function name for return statements
    strcpy(current_function, func_name);

    // Check if this is main function
    if (strcmp(func_name, "main") == 0) {
        has_main_function = 1;
        return_type = "i32"; // main always returns i32
    }

    // Check if function has varargs
    int has_varargs = 0;
    int named_param_count = 0;
    if (params_node && params_node->type == NODE_PARAM_LIST) {
        ASTNode* param = params_node->child;
        while (param) {
            if (param->type == NODE_ELLIPSIS) {
                has_varargs = 1;
            } else {
                named_param_count++;
            }
            param = param->next;
        }
    }
    add_function_info_with_type(func_name, has_varargs, return_type);

    // Generate function signature with parameter names and types
    char param_signature[512] = "";

    if (params_node && params_node->type == NODE_PARAM_LIST && params_node->child) {
        ASTNode* param = params_node->child;
        int first_param = 1;
        int param_index = 0;

        while (param) {
            // Skip ELLIPSIS nodes in parameter signature generation
            if (param->type == NODE_ELLIPSIS) {
                param = param->next;
                continue;
            }

            if (!first_param) strcat(param_signature, ", ");

            // Extract parameter name and type
            char* param_name = find_parameter_name(param);
            char* param_type = "i32"; // Default parameter type

            // Get parameter type from the variable declaration - FIXED FOR POINTERS
            if (param->datatype) {
                // Use get_complete_llvm_type to properly handle pointers
                param_type = get_complete_llvm_type(param);
            }

            if (param_name) {
                // Use named parameter with type: type %param_name
                char param_str[64];
                sprintf(param_str, "%s %%%s", param_type, param_name);
                strcat(param_signature, param_str);
            } else {
                // Fallback to positional parameter
                char param_str[16];
                sprintf(param_str, "%s %%%d", param_type, param_index);
                strcat(param_signature, param_str);
            }

            first_param = 0;
            param_index++;
            param = param->next;
        }
    }

    // Emit function definition with varargs support
    if (strcmp(return_type, "void") == 0) {
        if (has_varargs) {
            if (param_signature[0] != '\0') {
                emit_llvm_ir("define void @%s(%s, ...) {", func_name, param_signature);
            } else {
                emit_llvm_ir("define void @%s(...) {", func_name);
            }
        } else {
            if (param_signature[0] != '\0') {
                emit_llvm_ir("define void @%s(%s) {", func_name, param_signature);
            } else {
                emit_llvm_ir("define void @%s() {", func_name);
            }
        }
    } else {
        if (has_varargs) {
            if (param_signature[0] != '\0') {
                emit_llvm_ir("define %s @%s(%s, ...) {", return_type, func_name, param_signature);
            } else {
                emit_llvm_ir("define %s @%s(...) {", return_type, func_name);
            }
        } else {
            if (param_signature[0] != '\0') {
                emit_llvm_ir("define %s @%s(%s) {", return_type, func_name, param_signature);
            } else {
                emit_llvm_ir("define %s @%s() {", return_type, func_name);
            }
        }
    }

    // ADD ENTRY BLOCK FOR MIPS COMPATIBILITY
    emit_llvm_ir("entry:");

    // Allocate space for parameters and store them with alignment
    if (params_node && params_node->type == NODE_PARAM_LIST && params_node->child) {
        ASTNode* param = params_node->child;
        int param_index = 0;

        while (param) {
            // Skip ELLIPSIS nodes
            if (param->type == NODE_ELLIPSIS) {
                param = param->next;
                continue;
            }

            char* param_name = find_parameter_name(param);
            char* param_type = "i32"; // Default
            if (param->datatype) {
                param_type = get_complete_llvm_type(param); // Use complete type for pointers
            }
            char * base_llvm_type=strdup(param_type);

            if(param->is_array){
                base_llvm_type=get_llvm_base_type(param->datatype);
            }

            if (param_name) {
                // POINTER FIX: Handle pointer parameters specifically
                if (param->is_pointer) {
                    // For pointer parameters, we need to allocate space for the pointer itself
                    char* complete_param_type = get_complete_llvm_type(param);
                    
                    emit_llvm_ir("  %%%s.addr = alloca %s, %s", param_name, complete_param_type,get_alignment_str(base_llvm_type));
                    emit_llvm_ir("  store %s %%%s, %s* %%%s.addr, %s",
                                complete_param_type, param_name, complete_param_type, param_name,get_alignment_str(base_llvm_type));
                }
                // Handle string parameters
                else if (strcmp(param->datatype, "string") == 0 || strcmp(param->datatype, "char*") == 0) {
                    emit_llvm_ir("  %%%s.addr = alloca i8*, align 8", param_name);
                    emit_llvm_ir("  store i8* %%%s, i8** %%%s.addr, align 8", param_name, param_name);
                } else {
                    // Regular non-pointer parameters
                    emit_llvm_ir("  %%%s.addr = alloca %s, %s", param_name, param_type,get_alignment_str(base_llvm_type));
                    emit_llvm_ir("  store %s %%%s, %s* %%%s.addr, %s", param_type, param_name, param_type, param_name,get_alignment_str(base_llvm_type));
                }
            } else {
                // Use positional parameter name
                char temp_name[16];
                sprintf(temp_name, "arg%d", param_index);

                // POINTER FIX: Handle pointer parameters for positional arguments too
                if (param->is_pointer) {
                    char* complete_param_type = get_complete_llvm_type(param);
                    emit_llvm_ir("  %%arg%d.addr = alloca %s, %s", param_index, complete_param_type,get_alignment_str(base_llvm_type));
                    emit_llvm_ir("  store %s %%%d, %s* %%arg%d.addr, %s",
                                complete_param_type, param_index, complete_param_type, param_index,get_alignment_str(base_llvm_type));
                } else {
                    emit_llvm_ir("  %%arg%d.addr = alloca %s, %s", param_index, param_type,get_alignment_str(base_llvm_type));
                    emit_llvm_ir("  store %s %%%d, %s* %%arg%d.addr, %s", param_type, param_index, param_type, param_index,get_alignment_str(base_llvm_type));
                }
            }
            param_index++;
            param = param->next;
        }
    }

    // For varargs functions, set up va_list infrastructure
    if (has_varargs) {
        // Add va_list declarations to the function
        //emit_llvm_ir("  ; varargs function setup");

        // Store named parameter count for va_start
        char named_count_str[16];
        sprintf(named_count_str, "%d", named_param_count);

        // Emit comment about va_list usage
        //emit_llvm_ir("  ; named parameter count: %s (for va_start)", named_count_str);
       // emit_llvm_ir("  ; use va_list, va_start, va_arg, va_end for variable arguments");

        // Note: Actual va_list variables will be created when NODE_VA_LIST_TYPE is encountered
        // in the function body. The va_start will use the last named parameter.
    }

    // Process function body
    if (body_node && body_node->type == NODE_COMPOUND_STMT) {
        ASTNode* stmt_list = body_node->child;
        if (stmt_list) {
            ASTNode* stmt = stmt_list->child;
            while (stmt) {
                generate_llvm_ir_from_ast(stmt);
                stmt = stmt->next;
            }
        }
    }

    // Add default return if missing (only for non-void functions)
    if (strcmp(return_type, "void") != 0) {
        // Check if the last statement was a return
        int has_return = 0;
        if (body_node && body_node->type == NODE_COMPOUND_STMT) {
            ASTNode* stmt_list = body_node->child;
            if (stmt_list) {
                ASTNode* stmt = stmt_list->child;
                while (stmt) {
                    if (stmt->type == NODE_RETURN_STMT) {
                        has_return = 1;
                        break;
                    }
                    stmt = stmt->next;
                }
            }
        }

        if (!has_return) {
            if (strcmp(return_type, "i32") == 0) {
                emit_llvm_ir("  ret i32 0");
            } else if (strcmp(return_type, "float") == 0) {
                emit_llvm_ir("  ret float 0.0");
            } else if (strcmp(return_type, "double") == 0) {
                emit_llvm_ir("  ret double 0.0");
            } else if (strcmp(return_type, "i8") == 0) {
                emit_llvm_ir("  ret i8 0");
            } else if (strcmp(return_type, "i8*") == 0) {
                emit_llvm_ir("  ret i8* null");
            }
        }
    } else {
        // For void functions, add void return if missing
        int has_return = 0;
        if (body_node && body_node->type == NODE_COMPOUND_STMT) {
            ASTNode* stmt_list = body_node->child;
            if (stmt_list) {
                ASTNode* stmt = stmt_list->child;
                while (stmt) {
                    if (stmt->type == NODE_RETURN_STMT) {
                        has_return = 1;
                        break;
                    }
                    stmt = stmt->next;
                }
            }
        }
        if (!has_return) {
            emit_llvm_ir("  ret void");
        }
    }

    emit_llvm_ir("}");
    current_function[0] = '\0';

    // Clean up any remaining va_list stack entries for this function
    while (va_list_stack_top >= 0 &&
           strcmp(va_list_stack[va_list_stack_top].function_name, func_name) == 0) {
        pop_va_list();
    }

    return NULL;
}

 case NODE_RETURN_STMT: {
    if (node->left) {
        char* ret_val = generate_llvm_ir_from_ast(node->left);
        if (ret_val) {
            // Get the return type from function info
            FunctionInfo* func_info = find_function_info(current_function);
            char* return_type = func_info ? func_info->return_type : "i32";

            if (ret_val[0] == '!') {
                // Boolean return value - convert to function return type
                if (strcmp(return_type, "i1") == 0) {
                    // Direct boolean return
                    emit_llvm_ir("  ret i1 %s", ret_val + 1);
                } else {
                    // Convert boolean to return type
                    char* conv_temp = generate_temp();
                    if (strcmp(return_type, "i32") == 0) {
                        emit_llvm_ir("  %s = zext i1 %s to i32", conv_temp, ret_val + 1);
                        emit_llvm_ir("  ret i32 %s", conv_temp);
                    } else if (strcmp(return_type, "float") == 0 || strcmp(return_type, "double") == 0) {
                        char* int_temp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to i32", int_temp, ret_val + 1);
                        emit_llvm_ir("  %s = sitofp i32 %s to %s", conv_temp, int_temp, return_type);
                        emit_llvm_ir("  ret %s %s", return_type, conv_temp);
                        free(int_temp);
                    } else if (strcmp(return_type, "i8*") == 0) {
                        // Convert boolean to string pointer (not typical, but handle it)
                        char* conv_temp = generate_temp();
                        emit_llvm_ir("  %s = select i1 %s, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.true_str, i64 0, i64 0), i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.false_str, i64 0, i64 0)",
                                    conv_temp, ret_val + 1);
                        emit_llvm_ir("  ret i8* %s", conv_temp);
                        free(conv_temp);
                    }
                    free(conv_temp);
                }
            } else {
                // Regular return value
                emit_llvm_ir("  ret %s %s", return_type, ret_val);
            }
            free(ret_val);
        } else {
            // No return value but function expects one
            FunctionInfo* func_info = find_function_info(current_function);
            char* return_type = func_info ? func_info->return_type : "i32";

            if (strcmp(return_type, "i32") == 0) {
                emit_llvm_ir("  ret i32 0");
            } else if (strcmp(return_type, "float") == 0) {
                emit_llvm_ir("  ret float 0.0");
            } else if (strcmp(return_type, "double") == 0) {
                emit_llvm_ir("  ret double 0.0");
            } else if (strcmp(return_type, "i8") == 0) {
                emit_llvm_ir("  ret i8 0");
            } else if (strcmp(return_type, "i8*") == 0) {
                emit_llvm_ir("  ret i8* null");
            } else if (strcmp(return_type, "i1") == 0) {
                emit_llvm_ir("  ret i1 false");
            }
        }
    } else {
        // No return value - check if we're in a void function
        FunctionInfo* func_info = find_function_info(current_function);
        if (func_info && strcmp(func_info->return_type, "void") == 0) {
            emit_llvm_ir("  ret void");
        } else if (strcmp(current_function, "main") == 0) {
            emit_llvm_ir("  ret i32 0");
        } else {
            // For other functions, use the function's return type
            char* return_type = func_info ? func_info->return_type : "i32";
            if (strcmp(return_type, "void") == 0) {
                emit_llvm_ir("  ret void");
            } else if (strcmp(return_type, "i32") == 0) {
                emit_llvm_ir("  ret i32 0");
            } else if (strcmp(return_type, "float") == 0) {
                emit_llvm_ir("  ret float 0.0");
            } else if (strcmp(return_type, "double") == 0) {
                emit_llvm_ir("  ret double 0.0");
            } else if (strcmp(return_type, "i8") == 0) {
                emit_llvm_ir("  ret i8 0");
            } else if (strcmp(return_type, "i8*") == 0) {
                emit_llvm_ir("  ret i8* null");
            } else if (strcmp(return_type, "i1") == 0) {
                emit_llvm_ir("  ret i1 false");
            }
        }
    }
    return NULL;
}

case NODE_COMPOUND_STMT: {
            // Process all statements
            ASTNode* stmt_list = node->child;
            if (stmt_list) {
                ASTNode* stmt = stmt_list->child;
                while (stmt) {
                    generate_llvm_ir_from_ast(stmt);
                    stmt = stmt->next;
                }
            }
            return NULL;
        }

case NODE_STMT_LIST: {
            // Process all statements in the list
            ASTNode* stmt = node->child;
            while (stmt) {
                generate_llvm_ir_from_ast(stmt);
                stmt = stmt->next;
            }
            return NULL;
        }

case NODE_CALL: {
    ASTNode* func_node = node->child;
    ASTNode* args_node = func_node ? func_node->next : NULL;
    printf("call node : %s \n",func_node->value);

    // Lambda expression handling (keep existing)
    if (func_node->type == NODE_LAMBDA_EXPR) {
        // Inline lambda definition and call
        char* lambda_ptr = generate_llvm_ir_from_ast(func_node);
        if (!lambda_ptr) return NULL;

        // Build argument string
        char args_str[512] = "";
        int arg_count = 0;

        if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
            ASTNode* arg = args_node->child;
            int first_arg = 1;

            while (arg) {
                if (!first_arg) strcat(args_str, ", ");

                char* arg_val = generate_llvm_ir_from_ast(arg);
                if (arg_val) {
                    if (arg_val[0] == '!') {
                        // Boolean argument
                        char* zext_temp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to i32", zext_temp, arg_val + 1);
                        strcat(args_str, zext_temp);
                        free(zext_temp);
                    } else {
                        strcat(args_str, arg_val);
                    }
                    free(arg_val);
                } else {
                    strcat(args_str, "0");
                }

                first_arg = 0;
                arg_count++;
                arg = arg->next;
            }
        }

        // Call the lambda via function pointer
        char* result = generate_temp();
        if (arg_count > 0) {
            emit_llvm_ir("  %s = call i32 (i8*, i32) bitcast (i8* %s to i32 (i8*, i32)*)(i8* null, %s)",
                        result, lambda_ptr, args_str);
        } else {
            emit_llvm_ir("  %s = call i32 (i8*) bitcast (i8* %s to i32 (i8*)*)(i8* null)",
                        result, lambda_ptr);
        }

        free(lambda_ptr);
        return strdup(result);
    }

    char* func_name = NULL;
    if (func_node->type == NODE_IDENTIFIER) {
        func_name = func_node->value;
    } else {
        // Handle complex function expressions
        func_name = generate_llvm_ir_from_ast(func_node);
    }

    if (!func_name) return NULL;

    // Check if this is a varargs function
    int is_varargs = is_varargs_function(func_name);
    FunctionInfo* func_info = find_function_info(func_name);
    char* return_type = func_info ? func_info->return_type : "i32";

    printf("call function name : %s \n",func_name);

    // Handle string functions (keep existing)
    if (strcmp(func_name, "strlen") == 0) {
        char* result = generate_temp();
        if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
            char* arg_val = generate_llvm_ir_from_ast(args_node->child);
            emit_llvm_ir("  %s = call i64 @strlen(i8* %s)", result, arg_val);
            // Convert i64 to i32 if needed
            char* conv_result = generate_temp();
            emit_llvm_ir("  %s = trunc i64 %s to i32", conv_result, result);
            free(result);
            free(arg_val);
            return conv_result;
        }
        return strdup(result);
    } else if (strcmp(func_name, "strcpy") == 0) {
        char* result = generate_temp();
        if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
            ASTNode* arg1 = args_node->child;
            ASTNode* arg2 = arg1 ? arg1->next : NULL;
            if (arg1 && arg2) {
                char* arg1_val = generate_llvm_ir_from_ast(arg1);
                char* arg2_val = generate_llvm_ir_from_ast(arg2);
                emit_llvm_ir("  %s = call i8* @strcpy(i8* %s, i8* %s)", result, arg1_val, arg2_val);
                free(arg1_val);
                free(arg2_val);
            }
        }
        return strdup(result);
    }

else if (strcmp(func_name, "cout") == 0 || strcmp(func_name, "cin") == 0) {
    char* result = generate_temp();

    // Generate dynamic format string based on argument types
    char* format_str = generate_format_string_for_arguments(args_node);
    char* format_str_ptr = generate_temp();

    // Create the format string constant name
    char* format_var_name = generate_format_string_name();

    int format_len = strlen(format_str) + 3; // +3 for "\\0A\\00" (newline + null terminator for cout)
    if (strcmp(func_name, "cout") == 0) {
        // Add to string constants collection instead of emitting immediately
        char format_content[1024];
        sprintf(format_content, "%s\\0A", format_str);
        add_string_constant(format_var_name, format_content, format_len);
    } else {
        // For cin, no newline needed
        format_len = strlen(format_str) + 1; // +1 for null terminator
        add_string_constant(format_var_name, format_str, format_len);
    }

    // Use the collected string constant
    emit_llvm_ir("  %s = getelementptr inbounds [%d x i8], [%d x i8]* @%s, i32 0, i32 0",
                 format_str_ptr, format_len, format_len, format_var_name);

    // Build comprehensive argument list
    char final_args_str[2048] = "";
    strcpy(final_args_str, "i8* ");
    strcat(final_args_str, format_str_ptr);

    if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
        ASTNode* arg = args_node->child;
        int arg_index = 0;

        while (arg) {
            strcat(final_args_str, ", ");

            char* arg_type = get_complete_llvm_type(arg);
            char* base_arg_type = get_llvm_base_type(arg->datatype);

            // ========== CIN HANDLING ==========
            if (strcmp(func_name, "cin") == 0) {
                // Handle multi-dimensional array element access: arr[i][j]
                if (arg->type == NODE_INDEX) {
                    char* element_addr = generate_temp();
                    
                    // Get the base array and all indices
                    ASTNode* current = arg;
                    ASTNode* base_array = NULL;
                    char* array_name = NULL;
                    SymbolEntry* symbol = NULL;
                    
                    // Collect all indices in reverse order
                    ASTNode* indices[10];
                    int index_count = 0;
                    
                    // Traverse to find base array and collect indices
                    while (current && current->type == NODE_INDEX) {
                        indices[index_count++] = current;
                        ASTNode* array_part = current->child;
                        
                        if (array_part && array_part->type == NODE_IDENTIFIER) {
                            base_array = array_part;
                            array_name = base_array->value;
                            symbol = find_symbol(array_name);
                            break;
                        }
                        current = array_part;
                    }
                    
                    if (base_array && array_name && symbol) {
                        char* array_type = get_complete_llvm_type(base_array);
                        char* base_array_type = get_llvm_base_type(base_array->datatype);
                        
                        // Generate all index expressions
                        char* index_values[10];
                        int actual_index_count = 0;
                        
                        for (int i = index_count-1; i >= 0; i--) {
                            ASTNode* index_node = indices[i]->child ? indices[i]->child->next : NULL;
                            if (index_node) {
                                index_values[actual_index_count++] = get_index_value(index_node);
                            }
                        }
                        
                        // Build GEP with all indices for multi-dimensional arrays
                        if (symbol->is_static) {
                            char* load_temp = generate_temp();
                            emit_llvm_ir("  %s = load %s, %s* @%s, %s", load_temp, array_type, array_type, array_name, get_alignment_str(base_array_type));
                            
                            char gep_str[512] = "";
                            strcpy(gep_str, "i32 0");
                            for (int i = 0; i < actual_index_count; i++) {
                                char temp[64];
                                sprintf(temp, ", i32 %s", index_values[i]);
                                strcat(gep_str, temp);
                            }
                            
                            emit_llvm_ir("  %s = getelementptr inbounds %s, %s %s, %s", 
                                        element_addr, array_type, array_type, load_temp, gep_str);
                            free(load_temp);
                        } else {
                            char gep_str[512] = "";
                            strcpy(gep_str, "i32 0");
                            for (int i = 0; i < actual_index_count; i++) {
                                char temp[64];
                                sprintf(temp, ", i32 %s", index_values[i]);
                                strcat(gep_str, temp);
                            }
                            
                            emit_llvm_ir("  %s = getelementptr inbounds %s, %s* %%%s, %s", 
                                        element_addr, array_type, array_type, array_name, gep_str);
                        }
                        
                        // Convert to i8* for cin
                        char* bitcast_temp = generate_temp();
                        emit_llvm_ir("  %s = bitcast %s* %s to i8*", bitcast_temp, base_array_type, element_addr);
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, bitcast_temp);
                        
                        // Free temporary values
                        for (int i = 0; i < actual_index_count; i++) {
                            if (index_values[i]) free(index_values[i]);
                        }
                        free(bitcast_temp);
                        free(element_addr);
                    } else {
                        strcat(final_args_str, "i8* null");
                    }
                }
                // Handle pointer dereference: *ptr
                else if (arg->type == NODE_UNARY_OP && strcmp(arg->op, "*") == 0) {
                    ASTNode* ptr_node = arg->child;
                    char* ptr_val = generate_llvm_ir_from_ast(ptr_node);
                    
                    if (ptr_val) {
                        // The pointer value IS the address we want for cin
                        char* bitcast_temp = generate_temp();
                        char* ptr_type = get_complete_llvm_type(ptr_node);
                        char* base_type = get_llvm_pointer_base_type(ptr_type);
                        emit_llvm_ir("  %s = bitcast %s %s to i8*", bitcast_temp, base_type, ptr_val);
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, bitcast_temp);
                        
                        free(ptr_val);
                        free(bitcast_temp);
                    } else {
                        strcat(final_args_str, "i8* null");
                    }
                }
                // Handle pointer-to-pointer: **ptr2
                else if (arg->type == NODE_UNARY_OP && strcmp(arg->op, "*") == 0) {
                    // Check if this is a double dereference
                    ASTNode* inner_ptr = arg->child;
                    if (inner_ptr && inner_ptr->type == NODE_UNARY_OP && strcmp(inner_ptr->op, "*") == 0) {
                        ASTNode* ptr2_node = inner_ptr->child;
                        char* ptr2_val = generate_llvm_ir_from_ast(ptr2_node);
                        
                        if (ptr2_val) {
                            // Load the first pointer
                            char* ptr1_temp = generate_temp();
                            char* ptr2_type = get_complete_llvm_type(ptr2_node);
                            char* ptr1_type = get_llvm_pointer_base_type(ptr2_type);
                            emit_llvm_ir("  %s = load %s, %s %s, %s", ptr1_temp, ptr1_type, ptr2_type, ptr2_val, get_alignment_str(ptr1_type));
                            
                            // The loaded pointer is the address we want for cin
                            char* bitcast_temp = generate_temp();
                            char* base_type = get_llvm_pointer_base_type(ptr1_type);
                            emit_llvm_ir("  %s = bitcast %s %s to i8*", bitcast_temp, base_type, ptr1_temp);
                            strcat(final_args_str, "i8* ");
                            strcat(final_args_str, bitcast_temp);
                            
                            free(ptr2_val);
                            free(ptr1_temp);
                            free(bitcast_temp);
                        } else {
                            strcat(final_args_str, "i8* null");
                        }
                    } else {
                        // Single pointer dereference (handled above)
                        strcat(final_args_str, "i8* null");
                    }
                }
                // Handle complex expressions - create temporary storage
                else if (arg->type != NODE_IDENTIFIER) {
                    char* temp_ptr = generate_temp();
                    char* arg_val = generate_llvm_ir_from_ast(arg);
                    
                    if (arg_val) {
                        // Allocate temporary storage with alignment
                        emit_llvm_ir("  %s = alloca %s, %s", temp_ptr, arg_type, get_alignment_str(base_arg_type));
                        
                        // Store initial value (optional) with alignment
                        if (arg_val[0] == '!') {
                            char* zext_temp = generate_temp();
                            emit_llvm_ir("  %s = zext i1 %s to %s", zext_temp, arg_val + 1, arg_type);
                            emit_llvm_ir("  store %s %s, %s* %s, %s", arg_type, zext_temp, arg_type, temp_ptr, get_alignment_str(base_arg_type));
                            free(zext_temp);
                        } else {
                            emit_llvm_ir("  store %s %s, %s* %s, %s", arg_type, arg_val, arg_type, temp_ptr, get_alignment_str(base_arg_type));
                        }
                        
                        // Get address as i8*
                        char* addr_temp = generate_temp();
                        emit_llvm_ir("  %s = bitcast %s* %s to i8*", addr_temp, arg_type, temp_ptr);
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, addr_temp);
                        
                        free(arg_val);
                        free(addr_temp);
                    } else {
                        strcat(final_args_str, "i8* null");
                    }
                    free(temp_ptr);
                }
                // Handle regular identifiers
                else {
                    char* arg_val = generate_llvm_ir_from_ast(arg);
                    
                    if (arg_val) {
                        SymbolEntry* symbol = find_symbol(arg->value);
                        char* addr_temp = generate_temp();
                        
                        if (symbol && symbol->is_static) {
                            emit_llvm_ir("  %s = bitcast %s* @%s to i8*", addr_temp, arg_type, arg->value);
                        } else {
                            if (arg->is_parameter) {
                                emit_llvm_ir("  %s = bitcast %s* %%%s.addr to i8*", addr_temp, arg_type, arg->value);
                            } else {
                                emit_llvm_ir("  %s = bitcast %s* %%%s to i8*", addr_temp, arg_type, arg->value);
                            }
                        }
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, addr_temp);
                        
                        free(arg_val);
                        free(addr_temp);
                    } else {
                        strcat(final_args_str, "i8* null");
                    }
                }
            }
            // ========== COUT HANDLING ==========
            else {
                char* arg_val = generate_llvm_ir_from_ast(arg);
                
                if (arg_val) {
                    // Handle multi-dimensional array element access for cout: arr[i][j]
                    if (arg->type == NODE_INDEX) {
                        // For multi-dimensional arrays, we need to load the value
                        char* loaded_val = generate_temp();
                        
                        // Get base array to determine type
                        ASTNode* base_array = arg->child;
                        while(base_array && base_array->type == NODE_INDEX) {
                            base_array = base_array->child;
                        }
                        
                        if (base_array && base_array->type == NODE_IDENTIFIER) {
                            SymbolEntry* symbol = find_symbol(base_array->value);
                            char* base_array_type = get_llvm_base_type(base_array->datatype);
                            
                            if (symbol && strcmp(symbol->datatype, "char") == 0) {
                                // Character array element - promote to i32
                                char* promoted = generate_temp();
                                emit_llvm_ir("  %s = zext i8 %s to i32", promoted, arg_val);
                                strcat(final_args_str, "i32 ");
                                strcat(final_args_str, promoted);
                                free(promoted);
                            } else {
                                // Regular array element - load with alignment
                                emit_llvm_ir("  %s = load %s, %s* %s, %s", loaded_val, base_array_type, base_array_type, arg_val, get_alignment_str(base_array_type));
                                strcat(final_args_str, base_array_type);
                                strcat(final_args_str, " ");
                                strcat(final_args_str, loaded_val);
                                free(loaded_val);
                            }
                        } else {
                            // Fallback - use the generated value directly
                            strcat(final_args_str, arg_type);
                            strcat(final_args_str, " ");
                            strcat(final_args_str, arg_val);
                        }
                        free(arg_val);
                    }
                    // Handle pointer dereference for cout: *ptr
                    else if (arg->type == NODE_UNARY_OP && strcmp(arg->op, "*") == 0) {
                        // For cout, we want the dereferenced VALUE
                        char* loaded_val = generate_temp();
                        char* ptr_type = get_complete_llvm_type(arg->child);
                        char* base_type = get_llvm_pointer_base_type(ptr_type);
                        emit_llvm_ir("  %s = load %s, %s %s, %s", loaded_val, base_type, ptr_type, arg_val, get_alignment_str(base_type));
                        
                        // Handle character pointers specially
                        if (strcmp(base_type, "i8") == 0) {
                            char* promoted = generate_temp();
                            emit_llvm_ir("  %s = zext i8 %s to i32", promoted, loaded_val);
                            strcat(final_args_str, "i32 ");
                            strcat(final_args_str, promoted);
                            free(promoted);
                        } else {
                            strcat(final_args_str, base_type);
                            strcat(final_args_str, " ");
                            strcat(final_args_str, loaded_val);
                        }
                        
                        free(loaded_val);
                        free(arg_val);
                    }
                    // Handle pointer-to-pointer dereference for cout: **ptr2
                    else if (arg->type == NODE_UNARY_OP && strcmp(arg->op, "*") == 0) {
                        // Check if this is a double dereference
                        ASTNode* inner_ptr = arg->child;
                        if (inner_ptr && inner_ptr->type == NODE_UNARY_OP && strcmp(inner_ptr->op, "*") == 0) {
                            ASTNode* ptr2_node = inner_ptr->child;
                            char* ptr2_val = generate_llvm_ir_from_ast(ptr2_node);
                            
                            if (ptr2_val) {
                                // Load the first pointer
                                char* ptr1_temp = generate_temp();
                                char* ptr2_type = get_complete_llvm_type(ptr2_node);
                                char* ptr1_type = get_llvm_pointer_base_type(ptr2_type);
                                emit_llvm_ir("  %s = load %s, %s %s, %s", ptr1_temp, ptr1_type, ptr2_type, ptr2_val, get_alignment_str(ptr1_type));
                                
                                // Load the actual value
                                char* loaded_val = generate_temp();
                                char* base_type = get_llvm_pointer_base_type(ptr1_type);
                                emit_llvm_ir("  %s = load %s, %s %s, %s", loaded_val, base_type, ptr1_type, ptr1_temp, get_alignment_str(base_type));
                                
                                strcat(final_args_str, base_type);
                                strcat(final_args_str, " ");
                                strcat(final_args_str, loaded_val);
                                
                                free(ptr2_val);
                                free(ptr1_temp);
                                free(loaded_val);
                            } else {
                                strcat(final_args_str, "i32 0");
                            }
                            free(arg_val);
                        } else {
                            // Single pointer dereference (handled above)
                            free(arg_val);
                            strcat(final_args_str, "i32 0");
                        }
                    }
                    // Handle string/pointer types
                    else if (handle_array_pointer_for_io(arg) && (strcmp(arg->datatype,"string")!=0)) {
                        char* array_ptr_val = handle_array_pointer_for_io(arg);
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, array_ptr_val);
                        if (array_ptr_val != arg_val) free(array_ptr_val);
                        free(arg_val);
                    }
                    else if(strcmp(arg->datatype,"string")==0){
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, arg_val);
                    }
                    // Handle boolean types with special treatment
                    else if (arg_val[0] == '!') {
                        // For cout, convert bool to string representation
                        char* bool_str_var = generate_temp();
                        emit_llvm_ir("  %s = select i1 %s, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str.true, i64 0, i64 0), i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.false, i64 0, i64 0)",
                                    bool_str_var, arg_val + 1);
                        strcat(final_args_str, "i8* ");
                        strcat(final_args_str, bool_str_var);
                        free(bool_str_var);
                        free(arg_val);
                    }
                    // Handle character types (promote to i32)
                    else if (strcmp(arg_type, "i8") == 0) {
                        char* zext_temp = generate_temp();
                        emit_llvm_ir("  %s = zext i8 %s to i32", zext_temp, arg_val);
                        strcat(final_args_str, "i32 ");
                        strcat(final_args_str, zext_temp);
                        free(zext_temp);
                        free(arg_val);
                    }
                    // Handle regular types
                    else {
                        strcat(final_args_str, arg_type);
                        strcat(final_args_str, " ");
                        strcat(final_args_str, arg_val);
                        free(arg_val);
                    }
                } else {
                    // Default value for missing argument
                    strcat(final_args_str, arg_type);
                    strcat(final_args_str, " 0");
                }
            }

            arg_index++;
            arg = arg->next;
        }
    }

    // Emit the call with proper function mapping
    if (strcmp(func_name, "cout") == 0) {
        emit_llvm_ir("  %s = call i32 (i8*, ...) @cout(%s)", result, final_args_str);
    } else {
        emit_llvm_ir("  %s = call i32 (i8*, ...) @cin(%s)", result, final_args_str);
    }

    free(format_str);
    free(format_str_ptr);
    return strdup(result);
}
    else if (is_varargs) {
        
        // For user-defined varargs functions - build proper argument list
        char* result = generate_temp();

        // Build argument list with explicit types
        char final_args_str[2048] = "";

        if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
            ASTNode* arg = args_node->child;
            int first_arg = 1;
            int arg_index = 0;

            while (arg) {
                if (!first_arg) strcat(final_args_str, ", ");

                char* arg_type = get_complete_llvm_type(arg);
                char* arg_val = generate_llvm_ir_from_ast(arg);

                if (arg_val) {
                    // Handle boolean arguments
                    if (arg_val[0] == '!') {
                        if (strcmp(arg_type, "i1") == 0) {
                            strcat(final_args_str, "i1 ");
                            strcat(final_args_str, arg_val + 1);
                        } else {
                            char* zext_temp = generate_temp();
                            emit_llvm_ir("  %s = zext i1 %s to %s", zext_temp, arg_val + 1, arg_type);
                            strcat(final_args_str, arg_type);
                            strcat(final_args_str, " ");
                            strcat(final_args_str, zext_temp);
                            free(zext_temp);
                        }
                    } else {
                        strcat(final_args_str, arg_type);
                        strcat(final_args_str, " ");
                        strcat(final_args_str, arg_val);
                    }
                    free(arg_val);
                } else {
                    strcat(final_args_str, arg_type);
                    strcat(final_args_str, " 0");
                }

                first_arg = 0;
                arg_index++;
                arg = arg->next;
            }
        }

        if (final_args_str[0] != '\0') {
            emit_llvm_ir("  %s = call %s (i32, ...) @%s(%s)", result, return_type, func_name, final_args_str);
        } else {
            emit_llvm_ir("  %s = call %s (i32, ...) @%s()", result, return_type, func_name);
        }
        return strdup(result);
    }

    // Handle arguments - build argument list properly with types (existing functionality)
    char args_str[512] = "";
    char typed_args_str[1024] = "";
    int arg_count = 0;

    if (args_node && args_node->type == NODE_ARG_LIST && args_node->child) {
        ASTNode* arg = args_node->child;
        int first_arg = 1;

        while (arg) {
            if (!first_arg) {
                strcat(args_str, ", ");
                strcat(typed_args_str, ", ");
            }
            char* arg_type = get_complete_llvm_type(arg);
            char* arg_val = generate_llvm_ir_from_ast(arg);

            printf("call node arg type : %s , arg value %s \n",arg_type,arg_val);
            

            if (arg_val) {
                if (arg_val[0] == '!') {
                    // Boolean argument - zext to i32 or use as i1
                    if (strcmp(arg_type, "i1") == 0) {
                        strcat(args_str, arg_val + 1); // Skip the '!' for direct i1
                        strcat(typed_args_str, "i1 ");
                        strcat(typed_args_str, arg_val + 1);
                    } else {
                        char* zext_temp = generate_temp();
                        emit_llvm_ir("  %s = zext i1 %s to %s", zext_temp, arg_val + 1, arg_type);
                        strcat(args_str, zext_temp);
                        strcat(typed_args_str, arg_type);
                        strcat(typed_args_str, " ");
                        strcat(typed_args_str, zext_temp);
                        free(zext_temp);
                    }
                } else {
                    strcat(args_str, arg_val);
                    strcat(typed_args_str, arg_type);
                    strcat(typed_args_str, " ");
                    strcat(typed_args_str, arg_val);
                }
                free(arg_val);
            } else {
                strcat(args_str, "0");
                strcat(typed_args_str, arg_type);
                strcat(typed_args_str, " 0");
            }

            first_arg = 0;
            arg_count++;
            arg = arg->next;
        }
    }

     
        // For regular functions (non-varargs)
        char* result = generate_temp();

        printf("call node calling value: %s \n",result);

        if (typed_args_str[0] != '\0') {
            emit_llvm_ir("  %s = call %s @%s(%s)", result, return_type, func_name, typed_args_str);
        } else {
            emit_llvm_ir("  %s = call %s @%s()", result, return_type, func_name);
        }
        return strdup(result);
    
}

case NODE_SWITCH_STMT: {
    ASTNode* expr_node = node->child;
    ASTNode* case_blocks_node = expr_node ? expr_node->next : NULL;

    if (!expr_node) return NULL;

    // Generate the switch expression and ensure it's i32
    char* switch_value_raw = generate_llvm_ir_from_ast(expr_node);
    if (!switch_value_raw) return NULL;

    // Convert switch value to i32 if needed (for char, short, etc.)
    char* switch_value = switch_value_raw;
    char* expr_type = get_complete_llvm_type(expr_node);
    
    if (strcmp(expr_type, "i8") == 0 || strcmp(expr_type, "i16") == 0) {
        char* extended = generate_temp();
        if (strcmp(expr_type, "i8") == 0) {
            emit_llvm_ir("  %s = zext i8 %s to i32", extended, switch_value_raw);
        } else {
            emit_llvm_ir("  %s = zext i16 %s to i32", extended, switch_value_raw);
        }
        switch_value = extended;
        free(switch_value_raw);
    }

    char* end_switch = generate_label();
    char* default_label = generate_label(); // Always create default label
    
    // Store old break label and set new one for switch
    char* old_break_label = current_break_label;
    current_break_label = end_switch;

    // First pass: collect all case values and generate labels
    typedef struct {
        char* value;
        char* label;
        ASTNode* body;
    } CaseEntry;
    
    CaseEntry case_entries[100];
    int case_count = 0;
    char* actual_default_label = NULL;

    if (case_blocks_node && case_blocks_node->type == NODE_CASE_BLOCKS) {
        ASTNode* case_block = case_blocks_node->child;
        
        while (case_block) {
            if (case_block->type == NODE_CASE_STMT) {
                ASTNode* case_expr = case_block->child;
                ASTNode* case_body = case_expr ? case_expr->next : NULL;
                
                if (case_expr) {
                    char* case_value_raw = generate_llvm_ir_from_ast(case_expr);
                    if (case_value_raw) {
                        // Convert case value to i32 if needed
                        char* case_value = case_value_raw;
                        char* case_type = get_complete_llvm_type(case_expr);
                        
                        if (strcmp(case_type, "i8") == 0 || strcmp(case_type, "i16") == 0) {
                            char* case_extended = generate_temp();
                            if (strcmp(case_type, "i8") == 0) {
                                emit_llvm_ir("  %s = zext i8 %s to i32", case_extended, case_value_raw);
                            } else {
                                emit_llvm_ir("  %s = zext i16 %s to i32", case_extended, case_value_raw);
                            }
                            case_value = case_extended;
                            free(case_value_raw);
                        }
                        
                        case_entries[case_count].value = strdup(case_value);
                        case_entries[case_count].label = generate_label();
                        case_entries[case_count].body = case_body;
                        case_count++;
                        
                        if (case_value != case_value_raw) free(case_value);
                    }
                }
            } else if (case_block->type == NODE_DEFAULT_STMT) {
                actual_default_label = generate_label();
                case_entries[case_count].value = NULL; // Mark as default
                case_entries[case_count].label = actual_default_label;
                case_entries[case_count].body = case_block->child;
                case_count++;
            }
            case_block = case_block->next;
        }
    }

    // Generate the switch instruction
    if (case_count > 0) {
        // Use LLVM's switch instruction for better code generation
        char switch_str[2048] = "";
        snprintf(switch_str, sizeof(switch_str), "  switch i32 %s, label %%%s [ ", 
                switch_value, actual_default_label ? actual_default_label : default_label);
        
        // Add all case entries to switch
        for (int i = 0; i < case_count; i++) {
            if (case_entries[i].value) { // Skip default entry in switch table
                char case_str[128];
                snprintf(case_str, sizeof(case_str), "i32 %s, label %%%s ", 
                        case_entries[i].value, case_entries[i].label);
                if (strlen(switch_str) + strlen(case_str) < sizeof(switch_str) - 10) {
                    strcat(switch_str, case_str);
                }
            }
        }
        strcat(switch_str, "]");
        emit_llvm_ir("%s", switch_str);
    } else {
        // No cases, just jump to default
        emit_llvm_ir("  br label %%%s", default_label);
    }

    // Second pass: generate case bodies
    for (int i = 0; i < case_count; i++) {
        emit_llvm_ir("%s:", case_entries[i].label);
        
        if (case_entries[i].body) {
            generate_llvm_ir_from_ast(case_entries[i].body);
        }
        
        // If case body doesn't end with break, fall through to next case
        // In proper LLVM, we should handle fallthrough explicitly
        // For now, always jump to end unless there's an explicit break
        if (!case_entries[i].body || !ends_with_unconditional_branch(case_entries[i].body)) {
            if (i < case_count - 1) {
                // Fall through to next case
                emit_llvm_ir("  br label %%%s", case_entries[i + 1].label);
            } else {
                // Last case falls through to default
                emit_llvm_ir("  br label %%%s", actual_default_label ? actual_default_label : default_label);
            }
        }
    }

    // Generate default case if it exists
    if (actual_default_label) {
        emit_llvm_ir("%s:", actual_default_label);
        if (case_entries[case_count-1].body) { // Default is always last in our array
            generate_llvm_ir_from_ast(case_entries[case_count-1].body);
        }
        if (!case_entries[case_count-1].body || !ends_with_unconditional_branch(case_entries[case_count-1].body)) {
            emit_llvm_ir("  br label %%%s", end_switch);
        }
    } else {
        // Empty default case
        emit_llvm_ir("%s:", default_label);
        emit_llvm_ir("  br label %%%s", end_switch);
    }

    // End of switch
    emit_llvm_ir("%s:", end_switch);

    // Restore break label
    current_break_label = old_break_label;

    // Cleanup
    free(switch_value);
    free(end_switch);
    free(default_label);
    if (actual_default_label) free(actual_default_label);
    
    for (int i = 0; i < case_count; i++) {
        if (case_entries[i].value) free(case_entries[i].value);
        free(case_entries[i].label);
    }

    return NULL;
}

case NODE_LAMBDA_EXPR: {
    // Lambda expression: [capture](params) -> ret_type { body }
    ASTNode* capture_node = node->child;
    ASTNode* params_node = capture_node ? capture_node->next : NULL;
    ASTNode* ret_type_node = params_node ? params_node->next : NULL;
    ASTNode* body_node = ret_type_node ? ret_type_node->next : (params_node ? params_node->next : NULL);

    // Generate a unique name for the lambda function
    static int lambda_counter = 0;
    char lambda_name[32];
    sprintf(lambda_name, "lambda_%d", lambda_counter++);

    // Determine return type
    char* return_type = "i32"; // Default return type
    if (ret_type_node && ret_type_node->type == NODE_LAMBDA_RET) {
        ASTNode* actual_ret_type = ret_type_node->child;
        if (actual_ret_type && actual_ret_type->type == NODE_TYPE && actual_ret_type->value) {
            if (strcmp(actual_ret_type->value, "void") == 0) {
                return_type = "void";
            }
        }
    }

    // Build capture parameters
    char capture_params[512] = "";
    int has_captures = 0;

    if (capture_node && capture_node->type == NODE_LAMBDA_CAPTURE) {
        ASTNode* capture_item = capture_node->child;
        int first_capture = 1;

        while (capture_item) {
            if (!first_capture) strcat(capture_params, ", ");

            if (capture_item->type == NODE_IDENTIFIER) {
                // Capture by value
                char capture_str[64];
                sprintf(capture_str, "i32 %%%s_val", capture_item->value);
                strcat(capture_params, capture_str);
                has_captures = 1;
            } else if (capture_item->type == NODE_TYPE && capture_item->value) {
                if (strcmp(capture_item->value, "&") == 0) {
                    // Capture by reference
                    ASTNode* ref_target = capture_item->next;
                    if (ref_target && ref_target->type == NODE_IDENTIFIER) {
                        char capture_str[64];
                        sprintf(capture_str, "i32* %%%s_ref", ref_target->value);
                        strcat(capture_params, capture_str);
                        has_captures = 1;
                        capture_item = ref_target; // Skip the reference target
                    }
                }
            }

            first_capture = 0;
            capture_item = capture_item->next;
        }
    }

    // Build regular parameters
    char regular_params[512] = "";
    int has_regular_params = 0;

    if (params_node && params_node->type == NODE_PARAM_LIST && params_node->child) {
        ASTNode* param = params_node->child;
        int first_param = 1;

        while (param) {
            if (!first_param) strcat(regular_params, ", ");

            char* param_name = find_parameter_name(param);
            if (param_name) {
                char param_str[64];
                sprintf(param_str, "i32 %%%s", param_name);
                strcat(regular_params, param_str);
            } else {
                char param_str[16];
                sprintf(param_str, "i32 %%p%d", has_regular_params);
                strcat(regular_params, param_str);
            }

            has_regular_params = 1;
            first_param = 0;
            param = param->next;
        }
    }

    // Combine all parameters
    char full_signature[1024] = "";
    if (has_captures) {
        strcpy(full_signature, capture_params);
        if (has_regular_params) {
            strcat(full_signature, ", ");
            strcat(full_signature, regular_params);
        }
    } else if (has_regular_params) {
        strcpy(full_signature, regular_params);
    }

    // Emit lambda function definition
    if (strcmp(return_type, "void") == 0) {
        if (full_signature[0] != '\0') {
            emit_llvm_ir("define internal void @%s(%s) {", lambda_name, full_signature);
        } else {
            emit_llvm_ir("define internal void @%s() {", lambda_name);
        }
    } else {
        if (full_signature[0] != '\0') {
            emit_llvm_ir("define internal %s @%s(%s) {", return_type, lambda_name, full_signature);
        } else {
            emit_llvm_ir("define internal %s @%s() {", return_type, lambda_name);
        }
    }

    // Handle captures in function body
    if (capture_node && capture_node->type == NODE_LAMBDA_CAPTURE) {
        ASTNode* capture_item = capture_node->child;

        while (capture_item) {
            if (capture_item->type == NODE_IDENTIFIER) {
                // Capture by value - create local copy
                emit_llvm_ir("  %%%s = alloca i32", capture_item->value);
                emit_llvm_ir("  store i32 %%%s_val, i32* %%%s",
                            capture_item->value, capture_item->value);
            } else if (capture_item->type == NODE_TYPE && capture_item->value) {
                if (strcmp(capture_item->value, "&") == 0) {
                    // Capture by reference - store the pointer
                    ASTNode* ref_target = capture_item->next;
                    if (ref_target && ref_target->type == NODE_IDENTIFIER) {
                        emit_llvm_ir("  %%%s_ptr = alloca i32*", ref_target->value);
                        emit_llvm_ir("  store i32* %%%s_ref, i32** %%%s_ptr",
                                    ref_target->value, ref_target->value);
                    }
                    capture_item = ref_target;
                }
            }
            capture_item = capture_item->next;
        }
    }

    // Handle regular parameters
    if (params_node && params_node->type == NODE_PARAM_LIST && params_node->child) {
        ASTNode* param = params_node->child;
        int param_index = 0;

        while (param) {
            char* param_name = find_parameter_name(param);
            if (param_name) {
                emit_llvm_ir("  %%%s.addr = alloca i32", param_name);
                emit_llvm_ir("  store i32 %%%s, i32* %%%s.addr", param_name, param_name);
            } else {
                emit_llvm_ir("  %%arg%d.addr = alloca i32", param_index);
                emit_llvm_ir("  store i32 %%p%d, i32* %%arg%d.addr", param_index, param_index);
            }
            param_index++;
            param = param->next;
        }
    }

    // Process lambda body
    if (body_node) {
        generate_llvm_ir_from_ast(body_node);
    }

    // Add default return if needed
    if (strcmp(return_type, "void") != 0) {
        int has_return = 0;
        if (body_node) {
            // Check if body ends with return statement
            ASTNode* last_child = body_node;
            while (last_child && last_child->next) {
                last_child = last_child->next;
            }
            if (last_child && last_child->type == NODE_RETURN_STMT) {
                has_return = 1;
            }
        }

        if (!has_return) {
            emit_llvm_ir("  ret i32 0");
        }
    } else {
        emit_llvm_ir("  ret void");
    }

    emit_llvm_ir("}");

    // Return function pointer as i8*
    char* lambda_ptr = generate_temp();
    if (strcmp(return_type, "void") == 0) {
        if (full_signature[0] != '\0') {
            emit_llvm_ir("  %s = bitcast void (%s)* @%s to i8*",
                        lambda_ptr, full_signature, lambda_name);
        } else {
            emit_llvm_ir("  %s = bitcast void ()* @%s to i8*",
                        lambda_ptr, lambda_name);
        }
    } else {
        if (full_signature[0] != '\0') {
            emit_llvm_ir("  %s = bitcast %s (%s)* @%s to i8*",
                        lambda_ptr, return_type, full_signature, lambda_name);
        } else {
            emit_llvm_ir("  %s = bitcast %s ()* @%s to i8*",
                        lambda_ptr, return_type, lambda_name);
        }
    }

    return lambda_ptr;
}
case NODE_LAMBDA_CAPTURE: {
    // Lambda capture: [&] or [=] or [var1, &var2]
    if (node->value) {
        if (strcmp(node->value, "&") == 0) {
            // Capture all by reference
            emit_llvm_ir("  ; capture all by reference");
        } else if (strcmp(node->value, "=") == 0) {
            // Capture all by value
            emit_llvm_ir("  ; capture all by value");
        }
    }

    // Process individual captures
    ASTNode* capture_item = node->child;
    while (capture_item) {
        generate_llvm_ir_from_ast(capture_item);
        capture_item = capture_item->next;
    }
    return NULL;
}
case NODE_LAMBDA_RET: {
    // Lambda return type: -> type
    ASTNode* ret_type = node->child;
    if (ret_type) {
        return generate_llvm_ir_from_ast(ret_type);
    }
    return NULL;
}
case NODE_TYPE: {
    // Handle static types: static int, static float, etc.
    if (node->value && strstr(node->value, "static") != NULL) {
        // For static variables, we'll use internal linkage
        // The actual static handling is done in NODE_VARIABLE_DECL
        emit_llvm_ir("  ; static type: %s", node->value);
    }
    return NULL;
}
case NODE_ELLIPSIS: {
    // ... in function parameter list - no code generation needed
    // This is handled in NODE_FUNCTION_DEF during signature generation
    return NULL;
}

case NODE_PROGRAM: {
    // Set flag to collect global IR
    collecting_global_ir = 1;

    // Create mutable copies of the header strings
    char llvm_header[] = "target datalayout = \"e-m:e-p:32:32-f64:64:64-f80:32-n8:16:32-S128\"\ntarget triple = \"mips-unknown-unknown\"";

    // Store header in other_ir_lines - use a simpler approach without strtok
    global_ir_lines[global_ir_count++].ir_line = strdup("; LLVM IR Generated by Compiler for MIPS target");
    global_ir_lines[global_ir_count++].ir_line = strdup("target datalayout = \"e-m:e-p:32:32-f64:64:64-f80:32-n8:16:32-S128\"");
    global_ir_lines[global_ir_count++].ir_line = strdup("target triple = \"mips-unknown-unknown\"");
    global_ir_lines[global_ir_count++].ir_line = strdup("");

    // Store standard format strings in global_ir_lines

    const char* std_strings[] = {
        "@.str.true = private unnamed_addr constant [5 x i8] c\"true\\00\"",
        "@.str.false = private unnamed_addr constant [6 x i8] c\"false\\00\"",
        "@.str.empty = private unnamed_addr constant [1 x i8] c\"\\00\"",
        "@.str.d = private unnamed_addr constant [3 x i8] c\"%%d\\00\"",
        "@.str.f = private unnamed_addr constant [3 x i8] c\"%%f\\00\"",
        "@.str.lf = private unnamed_addr constant [4 x i8] c\"%%lf\\00\"",
        "@.str.s = private unnamed_addr constant [3 x i8] c\"%%s\\00\"",
        "@.str.c = private unnamed_addr constant [3 x i8] c\"%%c\\00\"",
        "@.str.p = private unnamed_addr constant [3 x i8] c\"%%p\\00\"",
        "@.str.x = private unnamed_addr constant [3 x i8] c\"%%x\\00\"",
        "@.str.space = private unnamed_addr constant [2 x i8] c\" \\00\"",
        "@.str.newline = private unnamed_addr constant [2 x i8] c\"\\0A\\00\"",
        NULL
    };

    for (int i = 0; std_strings[i] != NULL; i++) {
        global_ir_lines[global_ir_count].ir_line = strdup(std_strings[i]);
        global_ir_lines[global_ir_count].line_number = global_ir_count;
        global_ir_count++;
    }

    // Store library declarations in other_ir_lines
    collecting_global_ir = 0;
    // Update the library declarations section to include va_* intrinsics:

    const char* lib_decls[] = {
        "declare i32 @cin(i8* nocapture, ...)",
        "declare i32 @cout(i8* nocapture readonly, ...)",
        "declare i32 @puts(i8* nocapture readonly)",
        "declare i32 @putchar(i32)",
        "declare i32 @getchar()",
        "declare noalias i8* @malloc(i32)",
        "declare void @free(i8* nocapture)",
        "declare i32 @atoi(i8* nocapture)",
        "declare void @llvm.memset.p0i8.i32(i8* nocapture writeonly, i8, i32, i1 immarg)",
        "declare void @llvm.va_start(i8*)",
        "declare void @llvm.va_end(i8*)",
        "declare i8* @llvm.va_arg(i8*, i8*)",  // Generic version
        "declare i32 @llvm.va_arg.i32(i8*, i32)",
        "declare double @llvm.va_arg.f64(i8*, double)",
        "declare i8* @llvm.va_arg.p0i8(i8*, i8*)",
        "",
        NULL
    };

    for (int i = 0; lib_decls[i] != NULL; i++) {
        global_ir_lines[global_ir_count].ir_line = strdup(lib_decls[i]);
        global_ir_lines[global_ir_count].line_number = global_ir_count;
        global_ir_count++;
    }

    has_main_function = 0;

    // FIRST PASS: Process the AST to collect global declarations and string constants
    collecting_global_ir = 0;
    ASTNode* child = node->child;
    while (child) {
        generate_llvm_ir_from_ast(child);
        child = child->next;
    }

    //print_llvm_ir(node);

    // Emit all global declarations at the top (this stores them in global_ir_lines)
    emit_global_declarations();

    // Emit all collected string constants (this stores them in global_ir_lines)
    emit_string_constants();

    collecting_global_ir = 0;

    // If no main function, add a default one to function_ir_lines
    if (!has_main_function) {
        strcpy(current_function, "main");
        // Make sure we're not in global collection mode when emitting function IR
        int old_flag = collecting_global_ir;
        collecting_global_ir = 0;

        emit_llvm_ir("define i32 @main() {");
        emit_llvm_ir("entry:");
        emit_llvm_ir("  ret i32 0");
        emit_llvm_ir("}");

        collecting_global_ir = old_flag;
        current_function[0] = '\0';
    }

    return NULL;
}

// Add these cases to the main switch statement in generate_llvm_ir_from_ast


case NODE_VA_LIST: {
    // This handles va_list variable declaration
    ASTNode* id_node = node->child;

    if (id_node && id_node->type == NODE_IDENTIFIER) {
        char* va_list_name = id_node->value;
        char * llvm_type=get_complete_llvm_type(id_node);
        char * base_llvm_type=llvm_type;
        if (id_node->is_array){
           base_llvm_type=get_llvm_base_type(id_node->datatype);
        }


        // CORRECT: va_list is represented as i8* in LLVM IR
        emit_llvm_ir("  %%%s = alloca i8*, %s", va_list_name,get_alignment_str(base_llvm_type));

        // Store in symbol table with proper type information
        add_symbol_with_type(va_list_name, 0, "va_list", 1, 1, NULL, 0, 0); // is_pointer=1, pointer_depth=1

        printf("DEBUG: va_list '%s' allocated\n", va_list_name);
        return strdup(va_list_name);
    }
    return NULL;
}

case NODE_VA_START: {
    ASTNode* va_list_node = node->child;
    ASTNode* last_param_node = va_list_node ? va_list_node->next : NULL;

    if (!va_list_node || va_list_node->type != NODE_IDENTIFIER) {
        printf("Error: va_start requires va_list identifier\n");
        return NULL;
    }

    char* va_list_name = va_list_node->value;

    // FIXED: Use direct bitcast without temporary variable
    emit_llvm_ir("  call void @llvm.va_start(i8* bitcast (i8** %%%s to i8*))", va_list_name);

    printf("DEBUG: va_start called on '%s'\n", va_list_name);
    return NULL;
}

case NODE_VA_ARG: {
    ASTNode* va_list_node = node->child;
    ASTNode* type_node = va_list_node ? va_list_node->next : NULL;

    if (!va_list_node || va_list_node->type != NODE_IDENTIFIER || !type_node) {
        printf("Error: va_arg requires va_list and type\n");
        return NULL;
    }

    char* va_list_name = va_list_node->value;
    char* result = generate_temp();

    // Get the actual type from the type node
    char* llvm_type = "i32"; // default to int
    char* c_type = "int";    // for debugging
    int is_float = 0;
    int is_double = 0;
    int is_char = 0;
    int is_short = 0;
    int is_long = 0;
    int is_long_long = 0;

    if (type_node->type == NODE_TYPE && type_node->value) {
        c_type = type_node->value;

        if (strcmp(type_node->value, "int") == 0 ||
            strcmp(type_node->value, "unsigned int") == 0) {
            llvm_type = "i32";
        } else if (strcmp(type_node->value, "long") == 0 ||
                   strcmp(type_node->value, "long int") == 0 ||
                   strcmp(type_node->value, "unsigned long") == 0) {
            // For MIPS target, long is typically 32-bit (same as int)
            llvm_type = "i32";
            is_long = 1;
        } else if (strcmp(type_node->value, "long long") == 0 ||
                   strcmp(type_node->value, "unsigned long long") == 0) {
            // long long is always 64-bit
            llvm_type = "i64";
            is_long_long = 1;
        } else if (strcmp(type_node->value, "float") == 0) {
            // float is promoted to double in varargs
            llvm_type = "double";
            is_float = 1;
        } else if (strcmp(type_node->value, "double") == 0) {
            llvm_type = "double";
            is_double = 1;
        } else if (strcmp(type_node->value, "char") == 0 ||
                   strcmp(type_node->value, "unsigned char") == 0) {
            // char is promoted to int in varargs
            llvm_type = "i32";
            is_char = 1;
        } else if (strcmp(type_node->value, "short") == 0 ||
                   strcmp(type_node->value, "unsigned short") == 0) {
            // short is promoted to int in varargs
            llvm_type = "i32";
            is_short = 1;
        } else if (strstr(type_node->value, "*") != NULL) {
            // Pointer types
            llvm_type = "i8*";
        }
    }

    // CORRECT: Use the standard LLVM va_arg instruction
    if (is_float) {
        // float is promoted to double in varargs, so we need to convert back
        char* double_temp = generate_temp();
        emit_llvm_ir("  %s = va_arg i8** %%%s, double", double_temp, va_list_name);
        emit_llvm_ir("  %s = fptrunc double %s to float", result, double_temp);
        free(double_temp);
    } else if (is_double) {
        emit_llvm_ir("  %s = va_arg i8** %%%s, double", result, va_list_name);
    } else if (is_char) {
        // chars are promoted to int in varargs
        char* int_temp = generate_temp();
        emit_llvm_ir("  %s = va_arg i8** %%%s, i32", int_temp, va_list_name);
        emit_llvm_ir("  %s = trunc i32 %s to i8", result, int_temp);
        free(int_temp);
    } else if (is_short) {
        // shorts are promoted to int in varargs
        char* int_temp = generate_temp();
        emit_llvm_ir("  %s = va_arg i8** %%%s, i32", int_temp, va_list_name);
        emit_llvm_ir("  %s = trunc i32 %s to i16", result, int_temp);
        free(int_temp);
    } else if (is_long_long) {
        // long long is 64-bit
        emit_llvm_ir("  %s = va_arg i8** %%%s, i64", result, va_list_name);
    } else if (strcmp(llvm_type, "i8*") == 0) {
        emit_llvm_ir("  %s = va_arg i8** %%%s, i8*", result, va_list_name);
    } else {
        // Integer types (i32 for int, long, etc.)
        emit_llvm_ir("  %s = va_arg i8** %%%s, %s", result, va_list_name, llvm_type);
    }
    
    // Note: va_list_name, llvm_type, c_type are not dynamically allocated in this function
    // and result is returned to the caller, so we don't need to free them.

    return strdup(result);
}

case NODE_VA_END: {
    ASTNode* va_list_node = node->child;

    if (!va_list_node || va_list_node->type != NODE_IDENTIFIER) {
        printf("Error: va_end requires va_list identifier\n");
        return NULL;
    }

    char* va_list_name = va_list_node->value;

    // FIXED: Use direct bitcast without temporary variable
    emit_llvm_ir("  call void @llvm.va_end(i8* bitcast (i8** %%%s to i8*))", va_list_name);

    printf("DEBUG: va_end called on '%s'\n", va_list_name);
    return NULL;
}




        default: {
            // Generic fallback: process children
            ASTNode* child = node->child;
            while (child) {
                generate_llvm_ir_from_ast(child);
                child = child->next;
            }
            return NULL;
        }
    }
}

void print_llvm_ir(ASTNode* ast_root) {
    printf("\n=== LLVM Intermediate Representation ===\n");

    // 1. Emit global declarations and string constants first
    for (int i = 0; i < global_ir_count; i++) {
        printf("%s\n", global_ir_lines[i].ir_line);
    }

    // 2. Emit other IR (function declarations, typedefs, etc.)
    for (int i = 0; i < other_ir_count; i++) {
        printf("%s\n", other_ir_lines[i].ir_line);
    }

    // 3. Emit function definitions
    for (int i = 0; i < function_ir_count; i++) {
        printf("%s\n", function_ir_lines[i].ir_line);
    }
}

void free_llvm_ir() {
    temp_counter = 0;
    label_counter = 0;
    current_function[0] = '\0';
    free_stored_ir();
}

void generate_global_static_declaration(ASTNode* node) {
    if (!node || node->type != NODE_VARIABLE_DECL) return;

    ASTNode* type_node = node->child;
    ASTNode* decl_node = type_node ? type_node->next : NULL;

    if (!decl_node) return;

    char* var_name = NULL;
    char* init_value_str = NULL;
    char* llvm_type = "i32"; // Default type
    char * base_llvm_type="i32";

    


    // Extract variable name
    if (decl_node->type == NODE_IDENTIFIER) {
        var_name = decl_node->value;
    } else if (decl_node->type == NODE_ASSIGNMENT && decl_node->left) {
        if (decl_node->left->type == NODE_IDENTIFIER) {
            var_name = decl_node->left->value;
        }
    }

    if (!var_name) return;

    // Determine LLVM type
    if (type_node && type_node->type == NODE_TYPE && type_node->value) {
        llvm_type = get_llvm_type_from_semantic_for_type(type_node->value);
    }

    base_llvm_type=strdup(llvm_type);

    if(node->is_array){
    base_llvm_type=get_llvm_base_type(node->datatype);
    }

    // Handle string type
    if (strcmp(type_node->value, "string") == 0 || strcmp(type_node->value, "char*") == 0) {
        llvm_type = "i8*";

        if (init_value_str && strcmp(init_value_str, "0") != 0) {
            // For strings, we need to handle the string literal properly
            emit_llvm_ir("@%s = internal global i8* %s", var_name, init_value_str);
        } else {
            emit_llvm_ir("@%s = internal global i8* null", var_name);
        }
    } else {
        // Extract initial value
        if (decl_node->type == NODE_ASSIGNMENT && decl_node->right) {
            // For global scope, we can only use constant initializers
            if (decl_node->right->type == NODE_LITERAL) {
                init_value_str = strdup(decl_node->right->value);
            } else {
                // For non-literals, use default value
                if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
                    init_value_str = strdup("0.0");
                } else if (strcmp(llvm_type, "i1") == 0) {
                    init_value_str = strdup("false");
                } else {
                    init_value_str = strdup("0");
                }
            }
        } else {
            // No initializer - use default
            if (strcmp(llvm_type, "float") == 0 || strcmp(llvm_type, "double") == 0) {
                init_value_str = strdup("0.0");
            } else if (strcmp(llvm_type, "i1") == 0) {
                init_value_str = strdup("false");
            } else {
                init_value_str = strdup("0");
            }
        }

        // Emit the global declaration with alignment for MIPS
        emit_llvm_ir("@%s = internal global %s %s, %s", var_name, llvm_type, init_value_str,get_alignment_str(base_llvm_type));
    }

    // Add to symbol table as static with type information
    add_symbol_with_type(var_name, 1, type_node ? type_node->value : "int",
                        node->is_array, node->array_dimensions, node->array_sizes,
                        node->is_pointer, node->pointer_depth);

    if (init_value_str) free(init_value_str);
}

int is_main_function(ASTNode* node) {
    if (node->type != NODE_FUNCTION_DEF) return 0;

    ASTNode* name_node = node->child ? node->child->next : NULL;
    if (!name_node) return 0;

    char* func_name = NULL;
    if (name_node->type == NODE_IDENTIFIER) {
        func_name = name_node->value;
    } else if (name_node->type == NODE_DECLARATOR) {
        ASTNode* id_node = name_node->child;
        while (id_node && id_node->type != NODE_IDENTIFIER) {
            id_node = id_node->child;
        }
        if (id_node) func_name = id_node->value;
    }

    return (func_name && strcmp(func_name, "main") == 0);
}

void allocate_parameters(ASTNode* params_node) {
    if (!params_node || params_node->type != NODE_PARAM_LIST) return;

    ASTNode* param = params_node->child;
    int param_index = 0;

    while (param) {
        if (param->type == NODE_VARIABLE_DECL) {
            // Find the parameter name
            ASTNode* param_name_node = NULL;
            ASTNode* child = param->child;
            while (child) {
                if (child->type == NODE_IDENTIFIER) {
                    param_name_node = child;
                    break;
                }
                child = child->next;
            }

            if (param_name_node && param_name_node->value) {
                char* param_name = param_name_node->value;
                char* param_type = get_complete_llvm_type(param);
                char * base_type=strdup(param_type);
                if(param->is_array){
                    base_type=get_llvm_base_type(param->datatype);
                }

                emit_llvm_ir("  %%%s = alloca %s, %s", param_name, param_type,get_alignment_str(base_type));
                emit_llvm_ir("  store %s %%%d, %s* %%%s, %s", param_type, param_index, param_type, param_name,get_alignment_str(base_type));
            }
        }
        param_index++;
        param = param->next;
    }
}

// Helper function to check if a statement ends with unconditional branch
int ends_with_unconditional_branch(ASTNode* node) {
    if (!node) return 0;

    if (node->type == NODE_BREAK_STMT ||
        node->type == NODE_CONTINUE_STMT ||
        node->type == NODE_RETURN_STMT) {
        return 1;
    }

    if (node->type == NODE_COMPOUND_STMT || node->type == NODE_STMT_LIST) {
        ASTNode* last_stmt = NULL;
        ASTNode* child = node->child;
        while (child) {
            last_stmt = child;
            child = child->next;
        }
        if (last_stmt) {
            return ends_with_unconditional_branch(last_stmt);
        }
    }

    if (node->type == NODE_IF_STMT) {
        ASTNode* true_branch = node->child ? node->child->next : NULL;
        ASTNode* false_branch = true_branch ? true_branch->next : NULL;

        int true_ends = true_branch ? ends_with_unconditional_branch(true_branch) : 0;
        int false_ends = false_branch ? ends_with_unconditional_branch(false_branch) : 0;

        return true_ends && false_ends;
    }

    return 0;
}


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
%token <str> STRING_LITERAL CHAR_LITERAL IDENTIFIER TRUE FALSE
%token <num> INT_LITERAL
%token <fnum> FLOAT_LITERAL
%token STD_CIN STD_COUT STD_ENDL
%token VA_START VA_ARG VA_END VA_LIST
%token TOK_VA_START TOK_VA_END TOK_VA_ARG TOK_VA_LIST
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
%left INC DEC  // Postfix increment/decrement
%right PRE_INC PRE_DEC  // Prefix increment/decrement
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
%type <ast> else_part init_list_items init_list_contents cast_expr

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

/* ---------------- Struct definition ---------------- */
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
    :{$$= create_ast_node(NODE_EMPTY, line_val, "empty");}
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
    | TOK_VA_LIST IDENTIFIER SEMI {
        ASTNode *va_list_type = create_ast_node(NODE_VA_LIST, line_val, "va_list");
        ASTNode *identifier = create_ast_node(NODE_IDENTIFIER, line_val, $2);
        ast_add_child(va_list_type, identifier);
        $$ = va_list_type;
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
    | STATIC type declarator SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *static_type = create_ast_node(NODE_TYPE, line_val, "static");
        ast_add_child(static_type, $2);
        ast_add_child(decl, static_type);
        ast_add_child(decl, $3);
        $$ = decl;
    }
    | STATIC type declarator ASSIGN expression SEMI {
        ASTNode *decl = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *static_type = create_ast_node(NODE_TYPE, line_val, "static");
        ast_add_child(static_type, $2);
        ASTNode *assign = create_binary_node(NODE_ASSIGNMENT, line_val, "=", $3, $5);
        ast_add_child(decl, static_type);
        ast_add_child(decl, assign);
        $$ = decl;
    }
    ;

/* ---------------- Declarators ---------------- */
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
    : assignment_expr {$$ = $1;  }
    | LBRACE init_list_contents RBRACE {
        $$ = $2;
      }
    | LBRACE RBRACE {
        $$ = create_ast_node(NODE_INIT_LIST, line_val, "empty");
      }
    ;

init_list_contents
    : /* empty */ {
        $$ = create_ast_node(NODE_INIT_LIST, line_val, NULL);
      }
    | init_list_items {
        $$ = $1;
      }
    ;

init_list_items
    : initializer {
        $$ = create_ast_node(NODE_INIT_LIST, line_val, NULL);
        ast_add_child($$, $1);
      }
    | init_list_items COMMA initializer {
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
    | SHORT     { $$ = create_ast_node(NODE_TYPE, line_val, "short"); }
    | CONST     { $$ = create_ast_node(NODE_TYPE, line_val, "const"); }
    | STATIC    { $$ = create_ast_node(NODE_TYPE, line_val, "static"); }
    | UNSIGNED  { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned"); }
    | UNSIGNED INT { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned int"); }
    | UNSIGNED CHAR { $$ = create_ast_node(NODE_TYPE, line_val, "unsigned char"); }
    | AUTO      { $$ = create_ast_node(NODE_TYPE, line_val, "auto"); }
    | STRING    { $$ = create_ast_node(NODE_TYPE, line_val, "string"); }
    | IDENTIFIER { $$ = create_ast_node(NODE_TYPE, line_val, $1); }
    | CONST INT {$$ = create_ast_node(NODE_TYPE, line_val, "const int");}
    | CONST FLOAT {$$ = create_ast_node(NODE_TYPE, line_val, "const float");}
    | CONST DOUBLE{$$ = create_ast_node(NODE_TYPE, line_val, "const double");}
    | CONST CHAR {$$ = create_ast_node(NODE_TYPE, line_val, "const char");}
    | CONST LONG {$$ = create_ast_node(NODE_TYPE, line_val, "const long");}

    | STATIC INT {$$ = create_ast_node(NODE_TYPE, line_val, "static int");}
    | STATIC FLOAT {$$ = create_ast_node(NODE_TYPE, line_val, "static float");}
    | STATIC DOUBLE {$$ = create_ast_node(NODE_TYPE, line_val, "static double");}
    
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
        ASTNode *ellipsis = create_ast_node(NODE_ELLIPSIS, line_val, "...");
        ast_add_child($1, ellipsis);
        $$ = $1;
      }
    | ELLIPSIS {
        $$ = create_ast_node(NODE_PARAM_LIST, line_val, NULL);
        ASTNode *ellipsis = create_ast_node(NODE_ELLIPSIS, line_val, "...");
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

/* ---------------- Statements ---------------- */
statement
    : expression SEMI { $$ = $1; }
    | declaration { $$ = $1; }
    | compound_stmt { $$ = $1; }
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
        $$ = create_ast_node(NODE_GOTO_STMT, line_val, $2);
      }
    | TOK_VA_START LPAREN IDENTIFIER COMMA IDENTIFIER RPAREN SEMI {
        ASTNode *va_start = create_ast_node(NODE_VA_START, line_val, NULL);
        ast_add_child(va_start, create_ast_node(NODE_IDENTIFIER, line_val, $3));  // va_list
        ast_add_child(va_start, create_ast_node(NODE_IDENTIFIER, line_val, $5));  // last_param
        $$ = va_start;
    }
    | TOK_VA_ARG LPAREN IDENTIFIER COMMA type RPAREN SEMI {
        ASTNode *va_arg = create_ast_node(NODE_VA_ARG, line_val, NULL);
        ast_add_child(va_arg, create_ast_node(NODE_IDENTIFIER, line_val, $3));  // va_list
        ast_add_child(va_arg, $5);  // type
        $$ = va_arg;
    }
    | TOK_VA_END LPAREN IDENTIFIER RPAREN SEMI {
        ASTNode *va_end = create_ast_node(NODE_VA_END, line_val, NULL);
        ast_add_child(va_end, create_ast_node(NODE_IDENTIFIER, line_val, $3));  // va_list
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
    : cast_expr { $$ = $1; }
    | multiplicative_expr MUL cast_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "*", $1, $3);
    }
    | multiplicative_expr DIV cast_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "/", $1, $3);
    }
    | multiplicative_expr MOD cast_expr {
        $$ = create_binary_node(NODE_BINARY_OP, line_val, "%", $1, $3);
    }
    ;

cast_expr
    : unary_expr { $$ = $1; }
    | LPAREN type RPAREN cast_expr {
        ASTNode *cast = create_ast_node(NODE_CAST_EXPR, line_val, NULL);
        ast_add_child(cast, $2);  // target type
        ast_add_child(cast, $4);  // expression to cast
        $$ = cast;
    }
    ;

/* FIXED: Proper prefix/postfix increment/decrement handling */
unary_expr
    : postfix_expr { $$ = $1; }
    | INC unary_expr %prec PRE_INC {
        ASTNode *node = create_unary_node(NODE_UNARY_OP, line_val, "++", $2);
        node->is_postfix = false;  // Prefix increment
        $$ = node;
    }
    | DEC unary_expr %prec PRE_DEC {
        ASTNode *node = create_unary_node(NODE_UNARY_OP, line_val, "--", $2);
        node->is_postfix = false;  // Prefix decrement
        $$ = node;
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

/* FIXED: Proper postfix increment/decrement */
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
    | postfix_expr INC {
        ASTNode *node = create_unary_node(NODE_UNARY_OP, line_val, "++", $1);
        node->is_postfix = true;  // Postfix increment
        $$ = node;
    }
    | postfix_expr DEC {
        ASTNode *node = create_unary_node(NODE_UNARY_OP, line_val, "--", $1);
        node->is_postfix = true;  // Postfix decrement
        $$ = node;
    }
    ;

primary_expr
    : IDENTIFIER { $$ = create_ast_node(NODE_IDENTIFIER, line_val, $1); }
    | literal { $$ = $1; }
    | LPAREN expression RPAREN { $$ = $2; }
    | lambda_expr { $$ = $1; }
    | TOK_VA_ARG LPAREN IDENTIFIER COMMA type RPAREN {
        ASTNode *va_arg = create_ast_node(NODE_VA_ARG, line_val, NULL);
        ast_add_child(va_arg, create_ast_node(NODE_IDENTIFIER, line_val, $3));  // va_list
        ast_add_child(va_arg, $5);  // type
        $$ = va_arg;
    }
    | STD_CIN { $$ = create_ast_node(NODE_IDENTIFIER, line_val, "cin"); }
    | STD_COUT { $$ = create_ast_node(NODE_IDENTIFIER, line_val, "cout"); }
    | STD_ENDL { $$ = create_ast_node(NODE_IDENTIFIER, line_val, "endl"); }
    ;

literal
    : INT_LITERAL {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%d", $1);
        $$ = create_ast_node(NODE_LITERAL, line_val, buffer);
        // Set datatype based on value
        if (strchr(buffer, '.') || strchr(buffer, 'e') || strchr(buffer, 'E')) {
            $$->datatype = strdup("float");
        } else {
            $$->datatype = strdup("int");
        }
    }
    | FLOAT_LITERAL {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%f", $1);
        $$ = create_ast_node(NODE_LITERAL, line_val, buffer);
        $$->datatype = strdup("float");
    }
    | CHAR_LITERAL {
        $$ = create_ast_node(NODE_LITERAL, line_val, $1);
        $$->datatype = strdup("char");
    }
    | STRING_LITERAL {
        $$ = create_ast_node(NODE_LITERAL, line_val, $1);
        $$->datatype = strdup("string");
        $$->is_pointer = true;
        $$->pointer_depth = 1;
    }
    | TRUE {
        $$ = create_ast_node(NODE_LITERAL, line_val, "true");
        $$->datatype = strdup("bool");
    }
    | FALSE {
        $$ = create_ast_node(NODE_LITERAL, line_val, "false");
        $$->datatype = strdup("bool");
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
    : assignment_expr {
        $$ = create_ast_node(NODE_ARG_LIST, line_val, NULL);
        ast_add_child($$, $1);
      }
    | args_list COMMA assignment_expr {
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
        /* ========== SEMANTIC ANALYSIS ===================*/
        printf("\n=== Semantic Analysis ===\n");
        semantic_info* global_scope = NULL;
        check_semantics(ast_root, &global_scope);

        printf("\n=== Abstract Syntax Tree ===\n");
        print_ast(ast_root, 0);

        /* ========== IR GENERATION ========== */
        printf("\nGenerating Intermediate Representation...\n");

        // Reset all counters and storage
        temp_counter = 0;
        label_counter = 0;
        current_function[0] = '\0';
        global_ir_count = 0;
        function_ir_count = 0;
        other_ir_count = 0;
        string_const_count = 0;
        global_decl_count = 0;


        // Generate IR (this will store it in the appropriate arrays)
        generate_llvm_ir_from_ast(ast_root);



        // Print all stored IR in correct order
        print_llvm_ir(ast_root);

        printf("\nParsing completed successfully!\n");
    } else {
        printf("\nParsing failed with errors.\n");
    }

    if (ast_root) {
        free_ast(ast_root);
    }

    free_llvm_ir();

    if (yyin != stdin) {
        fclose(yyin);
    }

    return result;
}
