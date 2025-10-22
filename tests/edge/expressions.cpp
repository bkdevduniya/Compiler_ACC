// Complex ternary operators
int x = a ? b : c ? d : e;  // Right-associative
int y = (a ? b : c) ? d : e; // Parenthesized

// Comma operator precedence
int z = (a, b, c);          // Comma in initialization
x = (y = 5, y + 10);        // Comma in assignment

// Mixed operators
int result = a + b * c < d ? e : f;  // Complex precedence

// Prefix vs postfix
++x++;        // Invalid but test parsing
*x++;         // Dereference and increment