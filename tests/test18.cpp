int main() {
    int a = 10;
    int *p = &a;        // pointer to int
    int **pp = &p;      // pointer to pointer to int
    
    return **pp;        // double dereference → returns 10
}