

int main() {
    int x = 10, y = 20;

    // Simple if
    if (x < y) 
        cout << "x is less than y\n";

    // If-else
    if (x == y) {
        cout << "Equal\n";
    } else {
        cout << "Not Equal\n";
    }

    // Else-if ladder
    if (x > y) {
        cout << "x > y\n";
    } else if (x < y) {
        cout << "x < y\n";
    } else {
        cout << "Equal\n";
    }

    // Nested if
    if (x < 100) {
        if (y > 0) {
            cout << "Nested if works\n";
        }
    }

    // Ternary operator
    string result = (x > y) ? "Yes" : "No";
    cout << result << endl;

    // Switch-case
    switch (x) {
        case 5:
            cout << "Five\n";
            break;
        case 10:
            cout << "Ten\n";
            break;
        default:
            cout << "Default\n";
    }

    // While loop with condition
    while (x > 0) {
        x--;
    }

    // Do-while loop
    do {
        y--;
    } while (y > 0);

    // For loop
    for (int i = 0; i < 5; i++) {
        cout << i << " ";
    }
    cout << endl;

    return 0;
}
