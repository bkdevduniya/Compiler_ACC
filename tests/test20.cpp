

// Function with no parameters and no return value
void greet() {
    cout("Hello! Welcome to the function demo!");
}

// Function with parameters and return value
int add(int a, int b) {
    return a + b;
}

// Function with default parameters
double calculateArea(double length, double width ) {
    return length * width;
}

// Function with pass by value
void incrementByValue(int num) {
    num++;
    cout("Inside function (by value):", num);
}

// Function with pass by reference
void incrementByReference(int &num) {
    num++;
    cout("Inside function (by reference):", num);
}

// Function with pass by pointer
void incrementByPointer(int *num) {
    (*num)++;
    cout("Inside function (by pointer):", *num);
}

// Function overloading
int multiply(int a, int b) {
    return a * b;
}

// double multiply(double a, double b) {
//     return a * b;
// }


// Function with array parameter
void printArray(int arr[], int size) {
    cout("Array elements:");
    for(int i = 0; i < size; i++) {
        cout(arr[i]);
    }
}

// Recursive function
int factorial(int n) {
    if(n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int main() {
    cout("=== FUNCTIONS AND ARGUMENTS TEST ===");

    // Function with no parameters
    cout("\n1. Function with no parameters:");
    greet();

    // Function with parameters and return value
    cout("\n2. Function with parameters:");
    int result = add(5, 3);
    cout("add(5, 3) =", result);

    // Function with default parameters
    cout("\n3. Function with default parameters:");
    cout("calculateArea(5, 3) =", calculateArea(5, 3));
    cout("calculateArea(5) [default width] =", calculateArea(5));

    // Pass by value, reference, and pointer
    cout("\n4. Parameter passing methods:");
    int num = 10;
    cout("Original value:", num);

    incrementByValue(num);
    cout("After pass by value:", num);

    incrementByReference(num);
    cout("After pass by reference:", num);

    incrementByPointer(&num);
    cout("After pass by pointer:", num);

    // Function overloading
    cout("\n5. Function overloading:");
    cout("multiply(4, 5) =", multiply(4, 5));
    // cout("multiply(2.5, 3.5) =", multiply(2.5, 3.5));



    //Array parameter
    cout("\n7. Array parameter:");
    int numbers[5] = {1, 2, 3, 4, 5};
    printArray(numbers, 5);

   // Recursive function
    cout("\n8. Recursive function:");
    int fact = factorial(5);
    cout("factorial(5) =", fact);

    // User input with functions
    cout("\n9. User input demonstration:");
    int x;
    int y;
    cout("Enter two numbers to add:");
    cin(x, y);
    cout("Sum =", add(x, y));

    return 0;
}