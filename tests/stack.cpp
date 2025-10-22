

int main() {
    // create a stack of integers
    stack<int> st;

    // push elements
    st.push(10);
    st.push(20);
    st.push(30);

    // print top element
    cout << "Top element: " << st.top() << endl;

    // pop an element
    st.pop();
    cout << "Top after pop: " << st.top() << endl;

    // size of stack
    cout << "Size of stack: " << st.size() << endl;

    // empty the stack
    while (!st.empty()) {
        cout << "Popping: " << st.top() << endl;
        st.pop();
    }

    if (st.empty()) {
        cout << "Stack is now empty." << endl;
    }

    return 0;
}
