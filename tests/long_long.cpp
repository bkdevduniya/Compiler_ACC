

int main() {
    // declare long long integers
    long long a = 1000000000;          // 1 billion
    long long b = 2000000000;          // 2 billion
    long long c = a * b;               // multiplication

    cout ("a = ",a,endl);
    cout ("b = " , b , endl);
    cout ("a + b = ", a + b ,endl);
    cout ("a * b = " , c ,endl);

    // test with negative values
    long long d = -9223372036854775LL;  // near min of long long
    cout ("d = " ,d , endl);

    // test with max value
    long long e = 92233720368547757LL;   // max of long long
    cout ("e = " , e , endl);

    return 0;
}
