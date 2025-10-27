%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

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
    NODE_VAR_ARGS,
    NODE_STRUCT_TYPE,
    NODE_STRUCT_DEF,
    NODE_TYPE,
    NODE_IDENTIFIER,
    NODE_LITERAL,
    NODE_INT_LITERAL,
    NODE_FLOAT_LITERAL,
    NODE_CHAR_LITERAL,
    NODE_BOOL_LITERAL,
    NODE_STRING_LITERAL,
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
    NODE_VA_LIST,
    NODE_TERNARY_OP,
    NODE_EMPTY,
    NODE_DECLARATOR,
    NODE_STRUCT_MEMBER_LIST,
    NODE_STMT_LIST,
    NODE_CASE_BLOCKS,
    NODE_LAMBDA_CAPTURE,
    NODE_LAMBDA_PARAMS,
    NODE_LAMBDA_RET,
    NODE_COUT_STMT,
    NODE_CIN_STMT,
    NODE_GOTO_STMT,
    NODE_LABEL_STMT,
    NODE_ENUM_DEF,
    NODE_ENUM_MEMBER,
    NODE_CLASS_DEF,
    NODE_ACCESS_SPEC,
    NODE_TEMPLATE_DECL,
    NODE_NAMESPACE_DEF,
    NODE_TRY_BLOCK,
    NODE_CATCH_BLOCK,
    NODE_THROW_STMT,
    NODE_NEW_EXPR,
    NODE_DELETE_EXPR,
    NODE_CAST_EXPR,
    NODE_SIZEOF_EXPR,
    NODE_ALIGNOF_EXPR,
    NODE_TYPEID_EXPR,
    NODE_NOEXCEPT_EXPR,
    NODE_DECLTYPE_EXPR,
    NODE_STATIC_ASSERT,
    NODE_FRIEND_DECL,
    NODE_USING_DECL,
    NODE_TYPEDEF_DECL,
    NODE_EXPLICIT_INST,
    NODE_ATOMIC_EXPR,
    NODE_ATTR_EXPR
} NodeType;

typedef struct ASTNode {
    NodeType type;
    int line_number;
    char *value;
    char *op;
    char* datatype;
    
    /* ========== LLVM IR Generation Fields ========== */
    bool is_array;              // Whether this is an array
    int array_dimensions;       // Number of array dimensions
    int* array_sizes;           // Array sizes for each dimension
    int init_list_dimentions;
    int * init_list_sizes;       
    bool is_pointer;            // Whether this is a pointer
    int pointer_depth;          // Pointer depth (e.g., int** has depth 2)
    bool is_reference;          // Whether this is a reference
    bool is_function;           // Whether this is a function
    bool is_parameter;          // Whether this is a function parameter
    int param_count;            // Number of function parameters
    bool has_ellipsis;          // Whether function has variable arguments
    int size;                   // Size in bytes
    int max_array_dim ;
    bool is_const;              // Whether type is const
    bool is_static;             // Whether storage is static
    bool is_unsigned;           // Whether type is unsigned
    char* struct_name;          // For struct types, the struct name
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
    /* ============================================== */
    
    struct ASTNode *left;
    struct ASTNode *right;
    struct ASTNode *child;
    struct ASTNode *next;
} ASTNode;

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
    node->is_volatile = false;
    node->is_extern = false;
    node->is_register = false;
    node->is_thread_local = false;
    node->is_mutable = false;
    node->is_virtual = false;
    node->is_pure_virtual = false;
    node->is_override = false;
    node->is_final = false;
    node->is_explicit = false;
    node->is_inline = false;
    node->is_constexpr = false;
    node->is_consteval = false;
    node->is_constinit = false;
    node->struct_name = NULL;
    
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
    node->is_volatile = (strstr(type_name, "volatile") != NULL);
    node->is_extern = (strstr(type_name, "extern") != NULL);
    node->is_register = (strstr(type_name, "register") != NULL);
    node->is_thread_local = (strstr(type_name, "thread_local") != NULL);
    node->is_mutable = (strstr(type_name, "mutable") != NULL);
    node->is_virtual = (strstr(type_name, "virtual") != NULL);
    node->is_inline = (strstr(type_name, "inline") != NULL);
    node->is_constexpr = (strstr(type_name, "constexpr") != NULL);
    node->is_consteval = (strstr(type_name, "consteval") != NULL);
    node->is_constinit = (strstr(type_name, "constinit") != NULL);
    node->is_explicit = (strstr(type_name, "explicit") != NULL);
    
    // Set size based on type
    if (strcmp(type_name, "int") == 0 || strcmp(type_name, "unsigned int") == 0) {
        node->size = 4;
    } else if (strcmp(type_name, "float") == 0) {
        node->size = 4;
    } else if (strcmp(type_name, "double") == 0) {
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
    } else if (strstr(type_name, "struct") != NULL) {
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
    } else if (strcmp(type_name, "float") == 0) {
        info->size = 4;
    } else if (strcmp(type_name, "double") == 0) {
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
    } else if (strstr(type_name, "struct") != NULL) {
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
    dest->is_volatile = src->is_volatile;
    dest->is_extern = src->is_extern;
    dest->is_register = src->is_register;
    dest->is_thread_local = src->is_thread_local;
    dest->is_mutable = src->is_mutable;
    dest->is_virtual = src->is_virtual;
    dest->is_pure_virtual = src->is_pure_virtual;
    dest->is_override = src->is_override;
    dest->is_final = src->is_final;
    dest->is_explicit = src->is_explicit;
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
    dest->is_volatile = src->is_volatile;
    dest->is_extern = src->is_extern;
    dest->is_register = src->is_register;
    dest->is_thread_local = src->is_thread_local;
    dest->is_mutable = src->is_mutable;
    dest->is_virtual = src->is_virtual;
    dest->is_pure_virtual = src->is_pure_virtual;
    dest->is_override = src->is_override;
    dest->is_final = src->is_final;
    dest->is_explicit = src->is_explicit;
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

int count_function_params(ASTNode* param_list) {
    if (!param_list) return 0;
    int count = 0;
    ASTNode* current = param_list->child;
    while (current) {
        if (current->type != NODE_VAR_ARGS) {
            count++;
        }
        current = current->next;
    }
    return count;
}

bool function_has_ellipsis(ASTNode* param_list) {
    if (!param_list) return false;
    ASTNode* current = param_list->child;
    while (current) {
        if (current->type == NODE_VAR_ARGS) {
            return true;
        }
        current = current->next;
    }
    return false;
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
        } else {
            break;
        }
    }
    return NULL;
}



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
    int sizes[10] = {0}; // Maximum 10 dimensions
    
    while (current) {
        if (current->type == NODE_DECLARATOR && current->value && strcmp(current->value, "*") == 0) {
            *is_pointer = true;
            (*pointer_depth)++;
        } else if (current->type == NODE_INDEX) {
            *is_array = true;
            dim_count++;
            // Try to get array size from the index expression
            if (current->child && current->child->next) {
                ASTNode* size_expr = current->child->next;
                if (size_expr->type == NODE_INT_LITERAL && size_expr->value) {
                    sizes[dim_count-1] = atoi(size_expr->value);
                } else {
                    sizes[dim_count-1] = -1; // Unknown size
                }
            } else {
                sizes[dim_count-1] = -1; // Unknown size (e.g., int arr[])
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
        
        // Also set the array info in the declarator node itself
        declarator->is_array = true;
        declarator->array_dimensions = dim_count;
        declarator->array_sizes = (int*)malloc(dim_count * sizeof(int));
        memcpy(declarator->array_sizes, sizes, dim_count * sizeof(int));
    }
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

const char* node_type_to_string(NodeType type) {
    switch (type) {
        case NODE_PROGRAM: return "PROGRAM";
        case NODE_FUNCTION_DECL: return "FUNCTION_DECL";
        case NODE_FUNCTION_DEF: return "FUNCTION_DEF";
        case NODE_VARIABLE_DECL: return "VARIABLE_DECL";
        case NODE_VAR_ARGS: return "VARIABLE_ARGS";
        case NODE_STRUCT_TYPE: return "STRUCT_TYPE";
        case NODE_STRUCT_DEF: return "STRUCT_DEF";
        case NODE_TYPE: return "TYPE";
        case NODE_IDENTIFIER: return "IDENTIFIER";
        case NODE_LITERAL: return "LITERAL";
        case NODE_INT_LITERAL: return "INT_LITERAL";
        case NODE_FLOAT_LITERAL: return "FLOAT_LITERAL";
        case NODE_CHAR_LITERAL: return "CHAR_LITERAL";
        case NODE_STRING_LITERAL: return "STRING_LITERAL";
        case NODE_BOOL_LITERAL : return "BOOL_LITERAL";
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
        case NODE_VA_LIST: return "VAR_ARGS_LIST";
        case NODE_TERNARY_OP: return "TERNARY_OP";
        case NODE_EMPTY: return "EMPTY";
        case NODE_DECLARATOR: return "DECLARATOR";
        case NODE_STRUCT_MEMBER_LIST: return "STRUCT_MEMBER_LIST";
        case NODE_STMT_LIST: return "STMT_LIST";
        case NODE_CASE_BLOCKS: return "CASE_BLOCKS";
        case NODE_LAMBDA_CAPTURE: return "LAMBDA_CAPTURE";
        case NODE_LAMBDA_PARAMS: return "LAMBDA_PARAMS";
        case NODE_LAMBDA_RET: return "LAMBDA_RET";
        case NODE_COUT_STMT: return "COUT_STMT";
        case NODE_CIN_STMT: return "CIN_STMT";
        case NODE_GOTO_STMT: return "GOTO_STMT";
        case NODE_LABEL_STMT: return "LABEL_STMT";
        case NODE_ENUM_DEF: return "ENUM_DEF";
        case NODE_ENUM_MEMBER: return "ENUM_MEMBER";
        case NODE_CLASS_DEF: return "CLASS_DEF";
        case NODE_ACCESS_SPEC: return "ACCESS_SPEC";
        case NODE_TEMPLATE_DECL: return "TEMPLATE_DECL";
        case NODE_NAMESPACE_DEF: return "NAMESPACE_DEF";
        case NODE_TRY_BLOCK: return "TRY_BLOCK";
        case NODE_CATCH_BLOCK: return "CATCH_BLOCK";
        case NODE_THROW_STMT: return "THROW_STMT";
        case NODE_NEW_EXPR: return "NEW_EXPR";
        case NODE_DELETE_EXPR: return "DELETE_EXPR";
        case NODE_CAST_EXPR: return "CAST_EXPR";
        case NODE_SIZEOF_EXPR: return "SIZEOF_EXPR";
        case NODE_ALIGNOF_EXPR: return "ALIGNOF_EXPR";
        case NODE_TYPEID_EXPR: return "TYPEID_EXPR";
        case NODE_NOEXCEPT_EXPR: return "NOEXCEPT_EXPR";
        case NODE_DECLTYPE_EXPR: return "DECLTYPE_EXPR";
        case NODE_STATIC_ASSERT: return "STATIC_ASSERT";
        case NODE_FRIEND_DECL: return "FRIEND_DECL";
        case NODE_USING_DECL: return "USING_DECL";
        case NODE_TYPEDEF_DECL: return "TYPEDEF_DECL";
        case NODE_EXPLICIT_INST: return "EXPLICIT_INST";
        case NODE_ATOMIC_EXPR: return "ATOMIC_EXPR";
        case NODE_ATTR_EXPR: return "ATTR_EXPR";
        default: return "UNKNOWN";
    }
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

bool is_valid_lvalue(ASTNode* node) {
    if (!node) return false;
    
    switch (node->type) {
        case NODE_IDENTIFIER:
            // Regular variables are lvalues
            return true;
            
        case NODE_INDEX:
            // Array element is an lvalue
            return true;
            
        case NODE_MEMBER_ACCESS:
            // Struct/class member is an lvalue
            return true;
            
        case NODE_UNARY_OP:
            // Pointer dereference (*ptr) is an lvalue
            if (node->op && strcmp(node->op, "*") == 0) {
                return true;
            }
            return false;
            
        case NODE_CALL:
            // Function call result is NOT an lvalue (unless it returns reference)
            return false;
            
        case NODE_BINARY_OP:
            // Most binary operations are not lvalues
            // Exception: comma operator in some contexts, but generally not lvalue
            return false;
            
        case NODE_TERNARY_OP:
            // Ternary result is NOT an lvalue
            return false;
            
        case NODE_LITERAL:
        case NODE_INT_LITERAL:
        case NODE_FLOAT_LITERAL:
        case NODE_CHAR_LITERAL:
        case NODE_BOOL_LITERAL:
        case NODE_STRING_LITERAL:
            // Literals are rvalues
            return false;
            
        case NODE_INIT_LIST:
            // Initializer lists are rvalues
            return false;
            
        case NODE_CAST_EXPR:
            // Cast expressions are rvalues
            return false;
            
        default:
            // By default, assume it's not an lvalue
            return false;
    }
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

/* ==================== UPDATED DIMENSION ANALYSIS FUNCTION ==================== */

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

// Helper function to infer lambda return type from body





// Helper function to infer return type from lambda body


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
            bool is_function=false;
            int param_count=0;

            // Extract array dimension and size information from declarator
            get_type_info_from_declarator(declarator_node, &is_pointer, &pointer_depth, &is_array, &is_ref, &array_sizes, &array_dimensions);
            
            // Process initializer expression if present (BEFORE setting AST fields)
            ASTNode* init_expr = NULL;
            if (assignment_node) {
                init_expr = assignment_node->right;
                check_semantics(init_expr, parent_scope);
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
                
                // Free existing type and set to inferred type
                if (type_node->value) free(type_node->value);
                type_node->value = init_expr->datatype ? strdup(init_expr->datatype) : NULL;
                
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
                if (is_array && init_expr->is_pointer && (array_dimensions == init_expr->pointer_depth)&& 
                    is_type_compatible(type_node->value, init_expr->datatype)) {
                    // Array can decay to pointer - check if base types are compatible
                    types_compatible = true;
                    
                } else {
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
              if(init_expr->type!=NODE_INIT_LIST){
                if(is_array && array_dimensions>0 && (!init_expr->is_array||init_expr->array_dimensions==0) && (!init_expr->is_pointer||init_expr->pointer_depth==0)){
                    printf("Semantic Error : invalid assignment to pointer '%s' \n",identifier);
                }

                else if(is_pointer && pointer_depth>0 && (!init_expr->is_array||init_expr->array_dimensions==0) && (!init_expr->is_pointer||init_expr->pointer_depth==0)){
                    printf("Semantic Error : invalid assignment to pointer '%s' \n",identifier);
                }

                else if(init_expr->is_array && init_expr->array_dimensions>0 && (!is_array||array_dimensions==0) && (!is_pointer||pointer_depth==0)){
                    printf("Semantic Error : invalid assignment of pointer '%s' \n",identifier);
                }

                 else if(init_expr->is_pointer && init_expr->pointer_depth>0 && (!is_array||array_dimensions==0) && (!is_pointer||pointer_depth==0)){
                    printf("Semantic Error : invalid assignment of pointer '%s' \n",identifier);
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
                    break; // Comma operator has different rules
                }
                
                // Check type compatibility based on operator
                bool types_compatible = is_type_compatible(node->left->datatype, node->right->datatype);
                printf("DEBUG : left type '%s' , right type '%s' is compatible %d \n",node->left->datatype,node->right->datatype,int(types_compatible==true));
                // Get operator for easier comparison
                char* op = node->op;
                
                // Arithmetic operators: +, -, *, /, %
                if (op && (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 || 
                           strcmp(op, "*") == 0 || strcmp(op, "/") == 0 || strcmp(op, "%") == 0)) {
                    
                    // Check if types support arithmetic operations
                    if (!types_compatible) {
                        printf("Semantic Error at line %d: Arithmetic operation '%s' between incompatible types '%s' and '%s'\n", 
                               node->line_number, op, node->left->datatype, node->right->datatype);
                    }
                    
                    // Check for pointer arithmetic restrictions
                    if (node->left->is_pointer || node->right->is_pointer) {
                        if (strcmp(op, "%") == 0) {
                            printf("Semantic Error at line %d: Modulo operator '%%' not allowed with pointers\n", 
                                   node->line_number);
                        }
                        if ((node->left->is_pointer && node->left->pointer_depth>0)|| (node->right->is_pointer && node->right->pointer_depth>0)) {
                            printf("Semantic Error at line %d: Arithmetic on pointers not allowed with '%s'\n", 
                                   node->line_number, op);
                        }
                         if ((node->left->is_array && node->left->array_dimensions>0)|| (node->right->is_array && node->right->array_dimensions>0)) {
                            printf("Semantic Error at line %d: Arithmetic on pointers not allowed with '%s'\n", 
                                   node->line_number, op);
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
                        break;
                    }
                    
                    // Type promotion for arithmetic operations
                    int prec1 = precedence(node->left->datatype);
                    int prec2 = precedence(node->right->datatype);
                    
                    if (prec1 >= prec2) {
                        node->datatype = strdup(node->left->datatype);
                        copy_llvm_fields(node, node->left);
                    } else {
                        node->datatype = strdup(node->right->datatype);
                        copy_llvm_fields(node, node->right);
                    }
                }
                
                // Comparison operators: ==, !=, <, >, <=, >=
                else if (op && (strcmp(op, "==") == 0 || strcmp(op, "!=") == 0 || 
                                strcmp(op, "<") == 0 || strcmp(op, ">") == 0 || 
                                strcmp(op, "<=") == 0 || strcmp(op, ">=") == 0)) {
                    
                    if (!types_compatible) {
                        printf("Semantic Error at line %d: Comparison '%s' between incompatible types '%s' and '%s'\n", 
                               node->line_number, op, node->left->datatype, node->right->datatype);
                    }
                    
                    // Pointer comparison rules
                    if (node->left->is_pointer && node->right->is_pointer) {
                        if (node->left->pointer_depth != node->right->pointer_depth) {
                            printf("Semantic Error at line %d: Cannot compare pointers of different depths (%d vs %d)\n", 
                                   node->line_number, node->left->pointer_depth, node->right->pointer_depth);
                        }
                    }

                     if (node->left->is_array && node->right->is_array) {
                        if (node->left->array_dimensions != node->right->array_dimensions) {
                            printf("Semantic Error at line %d: Cannot compare pointers of different depths (%d vs %d)\n", 
                                   node->line_number, node->left->array_dimensions, node->right->array_dimensions);
                        }
                    }
                    
                    // Result of comparison is always boolean
                    node->datatype = strdup("bool");
                    node->is_pointer = false;
                    node->pointer_depth = 0;
                    node->size = 1;
                    node->is_array = false;
                    node->array_dimensions = 0;
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
                    
                    // Result is always boolean
                    node->datatype = strdup("bool");
                    node->is_pointer = false;
                    node->pointer_depth = 0;
                    node->size = 1;
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
                    
                    // Pointer restrictions for bitwise operations
                    if (node->left->is_pointer || node->right->is_pointer) {
                        printf("Semantic Error at line %d: Bitwise operation '%s' not allowed with pointers\n", 
                               node->line_number, op);
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
                }
                
                // Array/pointer specific checks
                if (node->left->is_array && node->left->array_dimensions>0 || node->right->is_array && node->right->array_dimensions) {
                    // Arrays decay to pointers in most expressions
                    if (op && (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 || 
                               strcmp(op, "*") == 0 || strcmp(op, "/") == 0)) {
                        printf("Warning at line %d: Array used in arithmetic operation '%s' (decays to pointer)\n", 
                               node->line_number, op);
                    }
                }
                
                // Const correctness
                if ((node->left->is_const || node->right->is_const) && 
                    op && (strcmp(op, "=") == 0)) {
                    printf("Semantic Error at line %d: Cannot assign to const operand\n", 
                           node->line_number);
                }
                
                // Struct type operations
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
                        
                        if (prec1 >= prec2) {
                            node->datatype = strdup(node->left->datatype);
                            copy_llvm_fields(node, node->left);
                        } else {
                            node->datatype = strdup(node->right->datatype);
                            copy_llvm_fields(node, node->right);
                        }
                    } else {
                        printf("Semantic Error at line %d: Operation '%s' between incompatible types '%s' and '%s'\n", 
                               node->line_number, op, node->left->datatype, node->right->datatype);
                        node->datatype = strdup("unknown");
                    }
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
                
                // Handle pointer dereferencing (* operator)
                if (node->op && strcmp(node->op, "*") == 0) {
                    if (node->is_pointer && node->pointer_depth > 0) {
                        node->pointer_depth--;
                        if (node->pointer_depth == 0) {
                            node->is_pointer = false;
                        }
                    } else {
                        printf("Semantic Error at line %d: Invalid pointer dereferencing '%s'\n", 
                               node->line_number, node->op);
                    }
                }
                
                // Handle address-of operator (&)
                else if (node->op && strcmp(node->op, "&") == 0) {
                    if (!node->left->is_array||(node->left->is_array&&node->left->array_dimensions>0)) {
                        node->is_pointer = true;
                        node->pointer_depth = node->left->pointer_depth + 1;
                    }
                    else if (!node->left->is_pointer||(node->left->is_pointer&&node->left->pointer_depth>0)) {
                        node->is_pointer = true;
                        node->pointer_depth = node->left->pointer_depth + 1;
                    }
                    else if(node->left->type!=  NODE_IDENTIFIER ){
                        printf("Semantic Error at line %d: Cannot take address of pointer '%s'\n", 
                               node->line_number, node->left->value ? node->left->value : "");
                    }
                }
                
                // Handle increment/decrement operators (++ and --)
                else if (node->op && (strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0)) {
                    // Check if operand is an identifier or valid lvalue
                    if (node->left->type != NODE_IDENTIFIER) {
                        // Check if it's a pointer dereference that can be incremented
                        if (node->left->type == NODE_UNARY_OP && node->left->op && 
                            strcmp(node->left->op, "*") == 0) {
                            // This is valid: (*ptr)++ or (*ptr)--
                            // The dereferenced pointer can be modified
                        } 
                        // Check if it's array indexing
                        else if (node->left->type == NODE_INDEX) {
                            // This is valid: arr[i]++ or arr[i]--
                        }
                        // Check if it's member access
                        else if (node->left->type == NODE_MEMBER_ACCESS) {
                            // This is valid: obj.member++ or obj.member--
                        }
                        else {
                            printf("Semantic Error at line %d: Operator '%s' expects an lvalue (identifier, pointer dereference, array element, or member access), got '%s'\n", 
                                   node->line_number, node->op, 
                                   node->left->value ? node->left->value : node_type_to_string(node->left->type));
                        }
                    }
                    
                    // Check if the type supports increment/decrement
                    if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char") == 0 || 
                        strcmp(node->datatype, "bool") == 0) {
                        printf("Semantic Error at line %d: Operation '%s' not defined on type '%s'\n", 
                               node->line_number, node->op, node->datatype);
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
                }
                
                // Handle logical NOT operator (!)
                else if (node->op && strcmp(node->op, "!") == 0) {
                    // Logical NOT can be applied to any type, but warn about non-boolean types
                    if (strcmp(node->datatype, "bool") != 0) {
                        printf("Warning at line %d: Logical NOT applied to non-boolean type '%s'\n", 
                               node->line_number, node->datatype);
                    }
                }
                
                // Additional type compatibility checks for all unary operators
                if (strcmp(node->datatype, "string") == 0 || strcmp(node->datatype, "char") == 0) {
                    // Only allow certain operations on string/char types
                    if (node->op && (strcmp(node->op, "++") == 0 || strcmp(node->op, "--") == 0 ||
                                          strcmp(node->op, "+") == 0 || strcmp(node->op, "-") == 0)) {
                        printf("Semantic Error at line %d: Operation '%s' not defined on string or character type\n", 
                               node->line_number, node->op);
                    }
                }
                
                // Check for const correctness
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

                printf("DEBUG: left node '%s' is_pointer (%d) pointer_depth (%d)\n",
                       node->left->value ? node->left->value : "unknown", 
                       node->left->is_pointer, node->left->pointer_depth);
               
                
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
                    if (index_expr->type == NODE_INT_LITERAL && index_expr->value) {
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

case NODE_INT_LITERAL: {
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("int");
            node->size = 4;
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
            node->is_const = false;
            node->is_static = false;
            node->is_unsigned = false;
            if (node->struct_name) {
                free(node->struct_name);
                node->struct_name = NULL;
            }
            break;
        }
        
        
 case NODE_FLOAT_LITERAL: {
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("float");
            node->size = 4;
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
            node->is_const = false;
            node->is_static = false;
            node->is_unsigned = false;
            if (node->struct_name) {
                free(node->struct_name);
                node->struct_name = NULL;
            }
            break;
        }
        
case NODE_CHAR_LITERAL: {
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("char");
            node->size = 1;
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
            node->is_const = false;
            node->is_static = false;
            node->is_unsigned = false;
            if (node->struct_name) {
                free(node->struct_name);
                node->struct_name = NULL;
            }
            break;
        }

case NODE_BOOL_LITERAL: {

    
    if (node->datatype) free(node->datatype);
    node->datatype = strdup("bool");
    node->size = 1;
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
    node->is_const = true; // Boolean literals are constants
    node->is_static = false;
    node->is_unsigned = false;
    if (node->struct_name) {
        free(node->struct_name);
        node->struct_name = NULL;
    }
    
    // CRITICAL FIX: Preserve the actual boolean literal value
    // The issue was that node->value was being overwritten with the identifier name
    // We need to ensure the original boolean value is preserved
    if (node->value) {
        // Check if this is actually a boolean literal or if it got corrupted
        if (strcmp(node->value, "true") == 0 || strcmp(node->value, "false") == 0) {
            // This is a proper boolean literal, keep it as is

        } else {
            // The value got corrupted - this is the bug!
         
            
            // We need to determine the correct value from context
            // For LLVM generation, we'll use "1" for true and "0" for false
            // But we should preserve the semantic meaning
            // Since we can't recover the original, we'll set a default
            // In practice, this should be fixed in the lexer/parser
            
            // Set to "true" as default, but this is a workaround
            // The real fix should be in the grammar rules
            if (node->value) free(node->value);
            node->value = strdup("true"); // Default to true
    
        }
    } else {
        // No value set - this shouldn't happen but handle it
        node->value = strdup("true"); // Default value

    }
    

    break;
}

case NODE_STRING_LITERAL: {
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("string");
            // String literals are pointers to character arrays
            node->is_pointer = true;
            node->pointer_depth = 1;
            node->size = 8; // Pointer size
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
            node->is_const = true; // String literals are typically const
            node->is_static = false;
            node->is_unsigned = false;
            if (node->struct_name) {
                free(node->struct_name);
                node->struct_name = NULL;
            }
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

case NODE_GOTO_STMT: {
            if (node->value) {
                // Check if label exists (would need label tracking)
                printf("DEBUG: Goto label '%s' at line %d\n", node->value, node->line_number);
            }
            
            // FIXED: removed non-existent field 'is_control_flow'
            break;
        }

       

case NODE_COUT_STMT: {

    
    ASTNode* args = node->child;
    if (args) {
        check_semantics(args, parent_scope);
        
        // Check that all arguments are output stream compatible
        ASTNode* arg = args;
        while (arg) {
            if (arg->datatype) {
                // Most basic types can be output, but check for invalid types
                if (arg->is_function) {
                    printf("Semantic Error at line %d: Cannot output function '%s' with cout\n",
                           node->line_number, arg->value ? arg->value : "unknown");
                } else if (arg->is_pointer && arg->pointer_depth > 1) {
                    printf("Semantic Error at line %d: Cannot output multi-level pointer with cout\n",
                           node->line_number);
                } else if (arg->struct_name && strcmp(arg->struct_name, "unknown") != 0) {
                    // Allow struct output with proper operator<< overload (simplified)
                    printf("Warning at line %d: Struct type '%s' may require operator<< overload for cout\n",
                           node->line_number, arg->struct_name);
                }
                
                // Set cout node properties
                node->datatype = strdup("void");
                node->is_function = false;
                node->param_count = 0;
                node->has_ellipsis = false;
            }
            arg = arg->next;
        }
    }
    break;
}

case NODE_CIN_STMT: {
    
    ASTNode* args = node->child;
    if (args) {
        // First check semantics of arguments
        check_semantics(args, parent_scope);
        
        // Check that all arguments are input stream compatible (lvalues)
        ASTNode* arg = (args->type==NODE_ARG_LIST)?args->child:args;
        while (arg) {
            if (arg->value) printf("'%s' ", arg->value);
            if (arg->datatype) printf("type '%s'", arg->datatype);
            printf("\n");
            
            // Enhanced lvalue checking for cin
            bool is_valid = is_valid_lvalue(arg);
            
            if (!is_valid) {
                printf("Semantic Error at line %d: Cin requires lvalue (cannot read into rvalue or temporary)\n",
                       node->line_number);
                
                // Provide more specific error message
                if (arg->type == NODE_INT_LITERAL || arg->type == NODE_FLOAT_LITERAL || 
                    arg->type == NODE_CHAR_LITERAL || arg->type == NODE_BOOL_LITERAL || 
                    arg->type == NODE_STRING_LITERAL) {
                    printf("Semantic Error at line %d: Cannot read into literal value\n",
                           node->line_number);
                } else if (arg->is_const) {
                    printf("Semantic Error at line %d: Cannot read into const variable\n",
                           node->line_number);
                } else if (arg->type == NODE_BINARY_OP || arg->type == NODE_UNARY_OP) {
                    printf("Semantic Error at line %d: Cannot read into expression result\n",
                           node->line_number);
                }
            } else {
                printf("DEBUG: Cin argument '%s' is a valid lvalue\n", 
                       arg->value ? arg->value : "unknown");
                
                // Additional checks for cin-specific restrictions
                if (arg->is_const) {
                    printf("Semantic Error at line %d: Cannot read into const variable '%s' with cin\n",
                           node->line_number, arg->value ? arg->value : "unknown");
                }
                
                if (arg->is_array && !arg->is_pointer) {
                    printf("Semantic Error at line %d: Cannot read directly into array '%s' with cin (use loop or pointer)\n",
                           node->line_number, arg->value ? arg->value : "unknown");
                }
                
                if (arg->is_function) {
                    printf("Semantic Error at line %d: Cannot read into function '%s' with cin\n",
                           node->line_number, arg->value ? arg->value : "unknown");
                }
            }
            arg = arg->next;
        }
        
        // Set cin node properties
        node->datatype = strdup("void");
        node->is_function = false;
        node->param_count = 0;
        node->has_ellipsis = false;
    }
    break;
}

case NODE_CAST_EXPR: {
            ASTNode* type_node = node->child;
            // FIXED: removed unused variable 'expr'
            ASTNode* expr = type_node ? type_node->next : NULL;
            
            if (type_node) check_semantics(type_node, parent_scope);
    
            
            // Set result type to cast type
            if (type_node && type_node->datatype) {
                if (node->datatype) free(node->datatype);
                node->datatype = strdup(type_node->datatype);
                // Copy LLVM fields from type node
                copy_llvm_fields(node, type_node);
            }
            break;
        }

case NODE_SIZEOF_EXPR: {
            ASTNode* expr = node->child;
            if (expr) check_semantics(expr, parent_scope);
            
            // sizeof always returns size_t (typically unsigned int)
            if (node->datatype) free(node->datatype);
            node->datatype = strdup("size_t");
            node->size = 8; // Typically 64-bit on modern systems
            node->is_unsigned = true;
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
            node->is_const = false;
            node->is_static = false;
            if (node->struct_name) {
                free(node->struct_name);
                node->struct_name = NULL;
            }
            break;
        }

case NODE_IDENTIFIER: {

            
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
                node->is_function = false;
                node->param_count = 0;
                node->has_ellipsis = false;
                node->size = 0;
                node->is_const = false;
                node->is_static = false;
                node->is_unsigned = false;
                break;
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
            node->is_volatile = info->is_volatile;
            node->is_extern = info->is_extern;
            node->is_register = info->is_register;
            node->is_thread_local = info->is_thread_local;
            node->is_mutable = info->is_mutable;
            node->is_virtual = info->is_virtual;
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
                
                // Set type modifiers based on type name
                set_type_modifiers(node, node->value);
                
                // Set basic type properties
                if (strcmp(node->value, "void") == 0) {
                    node->size = 0;
                } else if (strcmp(node->value, "int") == 0 || 
                          strcmp(node->value, "unsigned int") == 0) {
                    node->size = 4;
                } else if (strcmp(node->value, "float") == 0) {
                    node->size = 4;
                } else if (strcmp(node->value, "double") == 0) {
                    node->size = 8;
                } else if (strcmp(node->value, "char") == 0 || 
                          strcmp(node->value, "unsigned char") == 0) {
                    node->size = 1;
                } else if (strcmp(node->value, "short") == 0) {
                    node->size = 2;
                } else if (strcmp(node->value, "long") == 0) {
                    node->size = 8;
                } else if (strcmp(node->value, "bool") == 0) {
                    node->size = 1;
                } else if (strstr(node->value, "struct") != NULL) {
                    // Struct size will be calculated during struct processing
                    node->size = 0;
                } else if (strcmp(node->value, "string") == 0) {
                    node->size = 8; // Pointer size
                    node->is_pointer = true;
                    node->pointer_depth = 1;
                } else if (strcmp(node->value, "auto") == 0) {
                    // Auto type - size determined later
                    node->size = 0;
                }
            }
            break;
        }

        // ==================== LITERAL NODES ====================
        case NODE_LITERAL: {
        
            // Generic literals are handled by their specific types
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
%type <ast> type type_val declarator
%type <ast> expression expression_stmt assignment_expr conditional_expr logical_or_expr
%type <ast> logical_and_expr bitwise_or_expr bitwise_xor_expr bitwise_and_expr
%type <ast> equality_expr relational_expr shift_expr additive_expr multiplicative_expr
%type <ast> unary_expr postfix_expr primary_expr lambda_expr lambda_capture lambda_capture_list
%type <ast> lambda_params lambda_ret params_opt param_list_dec param_decl
%type <ast> compound_stmt stmt_list statement case_blocks_opt case_blocks case_block
%type <ast> for_init_opt expression_opt initializer init_list args_opt args_list literal srtuct_ident
%type <ast> else_part cout_stmt cin_stmt init_list_items init_list_contents

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
    : { $$ = NULL; }  /* Don't create empty node */
    | struct_member_list struct_member {
        if (!$1) {
            $$ = create_ast_node(NODE_STRUCT_MEMBER_LIST, line_val, NULL);
        } else {
            $$ = $1;
        }
        ast_add_child($$, $2);
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
    ;

/*---------------- Declarators ----------------*/
declarator
    : IDENTIFIER { 
        $$ = create_ast_node(NODE_IDENTIFIER, line_val, $1);
      }
    | MUL declarator {
        ASTNode *ptr = create_ast_node(NODE_DECLARATOR, line_val, "*");
        ast_add_child(ptr, $2);
        $$ = ptr;
    }
    | AMP declarator {
        ASTNode *ref = create_ast_node(NODE_DECLARATOR, line_val, "&");
        ast_add_child(ref, $2);
        $$ = ref;
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
    : assignment_expr { $$ = $1; }
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
    : { $$ = NULL; }  /* Don't create empty param list */
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
        ASTNode *ellipsis = create_ast_node(NODE_VAR_ARGS, line_val, "...");
        ast_add_child($1, ellipsis);
        $$ = $1;
      }
    | ELLIPSIS {
        $$ = create_ast_node(NODE_PARAM_LIST, line_val, NULL);
        ASTNode *ellipsis = create_ast_node(NODE_VAR_ARGS, line_val, "...");
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
    | type MUL { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *ptr_decl = create_ast_node(NODE_DECLARATOR, line_val, "*");
        ast_add_child(param, $1);
        ast_add_child(param, ptr_decl);
        $$ = param;
      }
    | type AMP { 
        ASTNode *param = create_ast_node(NODE_VARIABLE_DECL, line_val, NULL);
        ASTNode *ref_decl = create_ast_node(NODE_DECLARATOR, line_val, "&");
        ast_add_child(param, $1);
        ast_add_child(param, ref_decl);
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
        if ($2) {
            ast_add_child(compound, $2);
        }
        $$ = compound;
      }
    ;

stmt_list
    : { $$ = NULL; }  /* Don't create empty stmt list */
    | statement { 
        $$ = create_ast_node(NODE_STMT_LIST, line_val, NULL);
        ast_add_child($$, $1);
      }
    | stmt_list statement { 
        if (!$1) {
            $$ = create_ast_node(NODE_STMT_LIST, line_val, NULL);
            ast_add_child($$, $2);
        } else {
            ast_add_child($1, $2);
            $$ = $1;
        }
      }
    | stmt_list declaration { 
        if (!$1) {
            $$ = create_ast_node(NODE_STMT_LIST, line_val, NULL);
            ast_add_child($$, $2);
        } else {
            ast_add_child($1, $2);
            $$ = $1;
        }
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
        if ($3) {
            ast_add_child(cout_node, $3);
        }
        $$ = cout_node;
    }
    ;

cin_stmt
    : STD_CIN LPAREN args_opt RPAREN SEMI {
        ASTNode *cin_node = create_ast_node(NODE_CIN_STMT, line_val, NULL);
        if ($3) {
            ast_add_child(cin_node, $3);
        }
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
        if ($6) {
            ast_add_child(switch_node, $6);
        }
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
        if ($3) ast_add_child(for_node, $3);
        if ($4) ast_add_child(for_node, $4);
        if ($6) ast_add_child(for_node, $6);
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
    : { $$ = NULL; }  /* Don't create empty case blocks */
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
        if ($4) {
            ast_add_child(case_node, $4);
        }
        $$ = case_node;
    }
    | DEFAULT COLON stmt_list {
        ASTNode *default_node = create_ast_node(NODE_DEFAULT_STMT, line_val, NULL);
        if ($3) {
            ast_add_child(default_node, $3);
        }
        $$ = default_node;
    }
    ;

/* ---------------- For loop parts ---------------- */
for_init_opt
    : SEMI { $$ = NULL; }  /* Don't create empty for init */
    | expression SEMI{ $$ = $1; }
    | declaration { $$ = $1; }
    ;

expression_opt
    : { $$ = NULL; }  /* Don't create empty expression */
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
        if ($3) {
            ast_add_child(call, $3);
        }
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
        $$ = create_ast_node(NODE_INT_LITERAL, line_val, buffer);
    }
    | FLOAT_LITERAL { 
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%f", $1);
        $$ = create_ast_node(NODE_FLOAT_LITERAL, line_val, buffer);
    }
    | CHAR_LITERAL { 
        $$ = create_ast_node(NODE_CHAR_LITERAL, line_val, $1);
    }
    | STRING_LITERAL { 
        $$ = create_ast_node(NODE_STRING_LITERAL, line_val, $1);
    }
    | TRUE{
        $$ = create_ast_node(NODE_BOOL_LITERAL, line_val, $1);
    }
    | FALSE {
        $$ = create_ast_node(NODE_BOOL_LITERAL, line_val, $1);
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
        printf("DEBUG: Lambda capture by value: %s\n", $1);
      }
    | lambda_capture_list COMMA IDENTIFIER {
        ast_add_child($1, create_ast_node(NODE_IDENTIFIER, line_val, $3));
        printf("DEBUG: Lambda capture by value: %s\n", $3);
        $$ = $1;
      }
    | AMP IDENTIFIER { 
        $$ = create_ast_node(NODE_LAMBDA_CAPTURE, line_val, NULL);
        ASTNode *ref = create_ast_node(NODE_IDENTIFIER, line_val, $2);
        ASTNode *amp = create_ast_node(NODE_TYPE, line_val, "&");
        ast_add_child($$, amp);
        ast_add_child($$, ref);
        printf("DEBUG: Lambda capture by reference: %s\n", $2);
      }
    | lambda_capture_list COMMA AMP IDENTIFIER {
        ASTNode *ref = create_ast_node(NODE_IDENTIFIER, line_val, $4);
        ASTNode *amp = create_ast_node(NODE_TYPE, line_val, "&");
        ast_add_child($1, amp);
        ast_add_child($1, ref);
        printf("DEBUG: Lambda capture by reference: %s\n", $4);
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
    : { $$ = NULL; }  /* Don't create empty arg list */
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
        
        printf("\n=== Semantic Analysis ===\n");
        semantic_info* global_scope = NULL;
        check_semantics(ast_root, &global_scope);
        
        free_semantic_scope(global_scope);

        printf("\n=== Abstract Syntax Tree ===\n");
        print_ast(ast_root, 0);
        
        // ADD LLVM IR GENERATION HERE
      
        
        printf("\nParsing and semantic analysis completed successfully!\n");

    } else {
        printf("\nParsing failed with errors.\n");
    }
    
    free_ast(ast_root);
    
    if (yyin != stdin) {
        fclose(yyin);
    }
    
    return result;
}
