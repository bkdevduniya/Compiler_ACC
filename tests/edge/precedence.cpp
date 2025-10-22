// Cast vs function call
    // Cast or function call?
         // Uniform init or function call
// Address-of and dereference
&*ptr;              // Valid but complex
*&x;                // Valid but complex

// Increment/decrement with other operators
x = *ptr++;         // Postfix increment with dereference
x = ++*ptr;  
int f1(int,int,float,...);

void f2(int *ptr) { *ptr++; }  

int f1(int x, int y, float z, ...) { f2(&x); } // Prefix increment with dereference