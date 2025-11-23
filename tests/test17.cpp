// Use an array to specify types
int sum_mixed(int count, int types[], ...) {
    va_list args;
    va_start(args, types);
    
    double total = 0.0;
    for (int i = 0; i < count; i++) {
        switch (types[i]) {
            case 0: // int
                total += va_arg(args, int);
                break;
            case 1: // double
                total += va_arg(args, double);
                break;
            case 2: // float (promoted to double)
                total += va_arg(args, double);
                break;
        }
    }
    va_end(args);
    return total;
}

// Usage:
int main() {
    int types[] = {0, 1, 0, 0}; // int, double, int, int
    int result = sum_mixed(4, types, 10, 50.5, 30, 40);
    return 0;
}