
int main() {
    cout("=== LOOPS AND CONDITIONALS TEST ===");
    
    // If-else statements
    cout("\n=== IF-ELSE STATEMENTS ===");
    int number;
    cout("Enter a number:");
    cin(number);
    
    if (number > 0) {
        cout("The number is positive");
    } else if (number < 0) {
        cout("The number is negative");
    } else {
        cout("The number is zero");
    }
    
    // Switch statement
    cout("\n=== SWITCH STATEMENT ===");
    int choice;
    cout("Enter a choice (1-3):");
    cin(choice);
    
    switch(choice) {
        case 1:
            cout("You selected option 1");
            break;
        case 2:
            cout("You selected option 2");
            break;
        case 3:
            cout("You selected option 3");
            break;
        default:
            cout("Invalid choice");
    }
    
    // For loop
    cout("\n=== FOR LOOP ===");
    cout("Counting from 1 to 5:");
    for(int i = 1; i <= 5; i++) {
        cout("Iteration:", i);
    }
    
    // While loop
    cout("\n=== WHILE LOOP ===");
    int count = 1;
    cout("Counting from 1 to 3 using while:");
    while(count <= 3) {
        cout("Count:", count);
        count++;
    }
    
    // Do-while loop
    cout("\n=== DO-WHILE LOOP ===");
    int value;
    do {
        cout("Enter a number greater than 10:");
        cin(value);
    } while(value <= 10);
    cout("Thank you! You entered:", value);
    
    // Nested loops
    cout("\n=== NESTED LOOPS ===");
    cout("Multiplication table (1-3):");
    for(int i = 1; i <= 3; i++) {
        for(int j = 1; j <= 3; j++) {
            cout(i, "x", j, "=", (i * j));
        }
    }
    
    // Loop control statements
    cout("\n=== LOOP CONTROL STATEMENTS ===");
    cout("Break example (stops at 3):");
    for(int i = 1; i <= 5; i++) {
        if(i == 4) break;
        cout("i =", i);
    }
    
    cout("Continue example (skips 3):");
    for(int i = 1; i <= 5; i++) {
        if(i == 3) continue;
        cout("i =", i);
    }
    
    // Range-based for loop
    cout("\n=== RANGE-BASED FOR LOOP ===");
    int numbers[5] = {10, 20, 30, 40, 50};
    cout("Vector elements:");
    for(int i=0;i<5;i++) {

        cout(numbers[i]);
    }
    
    return 0;
}