// Complex captures
int x = 10, y = 20;
auto lambda1 = [x, &y]() { return x + y; };
auto lambda2 = [=]() { return x + y; };     // Capture by value all
auto lambda3 = [&]() { return x + y; };     // Capture by reference all

// Nested lambdas
auto outer = [x](int param) {
    return [x, param](int inner) { return x + param + inner; };
};

// Lambda in expressions
int result = [](int a, int b) { return a + b; }(5, 10);