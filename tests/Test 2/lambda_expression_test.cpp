int main() {
    int base = 10;
    auto multiply = [base](int x) -> int { return base * x; };
    cout(multiply(5));
    return 0;
}
