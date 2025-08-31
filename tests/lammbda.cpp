

int main() {
    // Outer lambda
    auto outer = [](int x) {
        cout << "Outer lambda, x = " << x << endl;

        // Inner lambda inside outer
        auto inner = [x](int y) {
            cout << "  Inner lambda, y = " << y << endl;
            return x + y; // captures x from outer
        };

        return inner; // return the inner lambda
    };

    // Call outer lambda
    auto innerFunc = outer(10);

    // Now call the returned inner lambda
    int result = innerFunc(20);

    cout << "Result = " << result << endl;

    return 0;
}
