static int y=5;

int counter() {
    static int x = 0;   // initialized once, retains value
    x++;
    return x;
}

int main() {
    int a = counter();  // returns 1
    int b = counter();  // returns 2
    return b;
}
