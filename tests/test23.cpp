

int main() {
    cout("=== LOGICAL AND OTHER OPERATORS TEST ===");
    
    // Logical operators
    bool p = true;
    bool q = false;
    cout("Logical operators:");
    cout("p =", p, ", q =", q);
    cout("p && q (AND):", (p && q));
    cout("p || q (OR):", (p || q));
    cout("!p (NOT):", (!p));
    cout("!q (NOT):", (!q));
    
    // Arithmetic operators
    int x = 15;
    int y = 4;
    cout("\nArithmetic operators:");
    cout("x =", x, ", y =", y);
    cout("x + y:", (x + y));
    cout("x - y:", (x - y));
    cout("x * y:", (x * y));
    cout("x / y:", (x / y));
    cout("x % y:", (x % y));
    
    // Assignment operators
    int a = 10;
    cout("\nAssignment operators:");
    cout("Initial a =", a);
    a += 5; cout("After a += 5:", a);
    a -= 3; cout("After a -= 3:", a);
    a *= 2; cout("After a *= 2:", a);
    a /= 4; cout("After a /= 4:", a);
    
    // Increment/Decrement operators
    int counter = 5;
    cout("\nIncrement/Decrement operators:");
    cout("Initial counter =", counter);
    cout("counter++:", counter++);
    cout("After counter++:", counter);
    cout("++counter:", ++counter);
    cout("counter--:", counter--);
    cout("--counter:", --counter);
    
    // Bitwise operators
    unsigned int num1 = 5;
    unsigned int num2 = 3; // 5 = 101, 3 = 011
    cout("\nBitwise operators:");
    cout("num1 =", num1, "(binary: 101), num2 =", num2, "(binary: 011)");
    cout("num1 & num2 (AND):", (num1 & num2)); // 101 & 011 = 001 (1)
    cout("num1 | num2 (OR):", (num1 | num2));  // 101 | 011 = 111 (7)
    cout("num1 ^ num2 (XOR):", (num1 ^ num2)); // 101 ^ 011 = 110 (6)
    cout("~num1 (NOT):", (~num1));
    cout("num1 << 1 (Left shift):", (num1 << 1)); // 101 << 1 = 1010 (10)
    cout("num1 >> 1 (Right shift):", (num1 >> 1)); // 101 >> 1 = 10 (2)
    
    // Ternary operator
    int age = 18;
    string status = (age >= 18) ? "Adult" : "Minor";
    cout("\nTernary operator:");
    cout("age =", age, ", status =", status);
    
    return 0;
}