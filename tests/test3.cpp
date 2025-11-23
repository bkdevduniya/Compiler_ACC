int main() {
    int x = 0;
    for (int i = 0; i < 10; i++) {
        if (i % 2 == 0) {
            x += i;
        } else {
            x -= i;
        }
    }
    return x;
}
