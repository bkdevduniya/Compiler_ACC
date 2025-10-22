// Missing semicolons
int x = 10
int y = 20;         // Should recover

// Missing braces
if (x > 0)
    cout << "positive"
else                // Missing brace recovery
    cout << "negative";

// Missing parentheses
if x > 0)           // Missing opening paren
if (x > 0           // Missing closing paren