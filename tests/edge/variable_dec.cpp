// Multiple pointers
int **pp;           // Double pointer
int ***ppp;         // Triple pointer
const int * const * cpp;  // Const pointer to const int

// Complex array declarations
int arr[10][20];           // 2D array
int (*parr)[10];           // Pointer to array
int arr[] = {1,2,3};       // Array without size

// Reference declarations
int &ref = x;
int &&rref = 10;           // R-value reference

// Auto with complex initializers
auto x = 5;
auto &rx = x;
auto *px = &x;