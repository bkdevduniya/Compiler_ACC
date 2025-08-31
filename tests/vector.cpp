

int main() {
    // create a vector of integers
    vector<int> nums;

    // add elements
    nums.push_back(10);
    nums.push_back(20);
    nums.push_back(30);

    // print elements
    cout << "Elements in vector: ";
    for (int x : nums) {
        cout << x << " ";
    }
    cout << endl;

    // access by index
    cout << "First element: " << nums[0] << endl;
    cout << "Second element: " << nums[1] << endl;

    // change an element
    nums[1] = 99;
    cout << "After update: ";
    for (int x : nums) {
        cout << x << " ";
    }
    cout << endl;

    // size of vector
    cout << "Size: " << nums.size() << endl;

    return 0;
}
