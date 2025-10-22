// Empty control bodies
if (condition);              // Empty if
while (condition);           // Empty while
for (;;);                    // Empty infinite loop

// Complex conditions
if (x > 0)  // Declaration in condition (C++17)
  // Comma operator in condition

// Nested control flow
for (int i = 0; i < 10; i++)
    for (int j = 0; j < 10; j++)
        if (i == j) break;   // Which loop does break target?

// Switch with fall-through
switch (x) {
    case 1:
    case 2: func(); break;   // Multiple cases
    default: break;
}