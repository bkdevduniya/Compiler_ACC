int main() {
    int arr[3];
    arr[0] = 1;
    arr[1] = arr[0] + 1;  // 1 + 1 = 2
    arr[2] = arr[1] + 1;  // 2 + 1 = 3
    return arr[2];  // Returns 3
}
