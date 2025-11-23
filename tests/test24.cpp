

// Function demonstrations
int add(int a, int b) {
    return a + b;
}
// void incrementByReference(int &num) {
//     num++;
// }


int main() {
    cout("=== COMPREHENSIVE C++ TEST ===");

    // SECTION 1: RELATIONAL OPERATORS
    cout("\n=== SECTION 1: RELATIONAL OPERATORS ===");
    int a = 15;
    int b = 25;
    cout("a =", a, ", b =", b);
    cout("a == b:", (a == b));
    cout("a != b:", (a != b));
    cout("a < b:", (a < b));
    cout("a > b:", (a > b));

    // SECTION 2: LOGICAL OPERATORS
    cout("\n=== SECTION 2: LOGICAL OPERATORS ===");
    bool p = true;
    bool q = false;
    cout("p =", p, ", q =", q);
    cout("p && q:", (p && q));
    cout("p || q:", (p || q));
    cout("!p:", (!p));

    // SECTION 3: ARITHMETIC OPERATORS
    cout("\n=== SECTION 3: ARITHMETIC OPERATORS ===");
    int x = 20;
    int y = 6;
    cout("x =", x, ", y =", y);
    cout("x + y =", (x + y));
    cout("x - y =", (x - y));
    cout("x * y =", (x * y));
    cout("x / y =", (x / y));
    cout("x % y =", (x % y));

    // SECTION 4: CONDITIONAL STATEMENTS
    cout("\n=== SECTION 4: CONDITIONAL STATEMENTS ===");
    int score;
    cout("Enter your score (0-100):");
    cin(score);

    if(score >= 90) {
        cout("Grade: A");
    } else if(score >= 80) {
        cout("Grade: B");
    } else if(score >= 70) {
        cout("Grade: C");
    } else if(score >= 60) {
        cout("Grade: D");
    } else {
        cout("Grade: F");
    }

    // SECTION 5: LOOPS
    cout("\n=== SECTION 5: LOOPS ===");

    // For loop
    cout("For loop (1-5):");
    for(int i = 1; i <= 5; i++) {
        cout("Number:", i);
    }

    // While loop with user input
    cout("\nWhile loop demonstration:");
    int number;
    cout("Enter numbers (0 to stop):");
    while(true) {
        cin(number);
        if(number == 0) break;
        cout("You entered:", number);
    }

    // SECTION 6: FUNCTIONS
    cout("\n=== SECTION 6: FUNCTIONS ===");

    // Basic function
    int sum = add(10, 20);
    cout("add(10, 20) =", sum);

    // // Pass by reference
    // int num = 5;
    // cout("Before increment:", num);
    // incrementByReference(num);
    // cout("After increment:", num);


    // SECTION 7: ARRAYS
    cout("\n=== SECTION 7: ARRAYS AND VECTORS ===");

    // Array
    int arr[5] = {2, 4, 6, 8, 10};
    cout("Array elements:");
    for(int i = 0; i < 5; i++) {
        cout(arr[i]);
    }

    // Vector
     string fruits[3] = {"Apple", "Banana", "Orange"};
    cout("Vector elements:");
    for(auto fruit : fruits) {
        cout(fruit);
    }

    // SECTION 8: COMPREHENSIVE EXAMPLE
    cout("\n=== SECTION 8: COMPREHENSIVE EXAMPLE ===");

    int n;
    cout("Enter how many numbers to process:");
    cin(n);

    if(n > 0) {
        int numbers[n];
        cout("Enter", n, "numbers:");

        for(int i = 0; i < n; i++) {
            cin(numbers[i]);
        }

        int total = 0;
        int max = numbers[0];
        int min = numbers[0];

        for(int i=0;i<n;i++) {
            int num=numbers[i];
            total += num;
            if(num > max) max = num;
            if(num < min) min = num;
        }

        double average = (total) / n;

        cout("\nResults:");
        cout("Total:", total);
        cout("Average:", average);
        cout("Maximum:", max);
        cout("Minimum:", min);

        // Using relational operators
        cout("\nAnalysis:");
        cout("Max > Min:", (max > min));
        cout("Average >= 50:", (average >= 50));
        cout("Total != 0:", (total != 0));
    }

    cout("\n=== TEST COMPLETED ===");
    return 0;
}