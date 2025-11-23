void increment(int *x,int *arr) {
    int *y=x;
    cout((*y)+arr[0]);

}

int main() {
    int a = 5;
    int arr2[5]={1,2,3,4,5};
    increment(&a,arr2);
    return a;  // returns 6
}