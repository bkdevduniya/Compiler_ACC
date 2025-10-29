int main() {
    static_assert(sizeof(int) == 4,"int must be 4 bytes");
    cout("Static assert passed");
    return 0;
}
