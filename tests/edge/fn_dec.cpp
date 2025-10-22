// Function returning pointer
int* func();
int& func();                // Function returning reference

// Pointer parameters
void func(int* param);
void func(int& param);      // Reference parameter
void func(int param[]);     // Array parameter

// Variable arguments with complex types
void variadic(int count, ...);

// Auto return type deduction
auto func() { return 42; }