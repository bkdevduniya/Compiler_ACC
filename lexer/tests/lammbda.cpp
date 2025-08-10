
int main() {
    // Basic lambda without capture
    auto greet = []() {
        cout << "Hello from a lambda function!" << endl;
    };
    greet(); // call the lambda

    // Lambda with parameters
    auto add = [](int a, int b) {
        return a + b;
    };
    cout << "Sum: " << add(5, 3) << endl;

    // Lambda with capture by value
    int x = 10;
    auto showX = [x]() {
        cout << "Captured x = " << x << endl;
    };
    showX();

    // Lambda with capture by reference
    auto incrementX = [&x]() {
        x++;
        cout << "Incremented x = " << x << endl;
    };
    incrementX();

    return 0;
}
