void printNumbers(int count,...) {
    va_list args;                // Declare argument list
    va_start(args,count);       // Initialize it with count

    for (int i=0; i<count;i++) {
        int num=args[i]; // Extract next argument
        cout<<num<<" ";
    }

    va_end(args); // Clean up
    cout<<"\n";
}

int hii(int,float,int,...);


int main(){
    printNumbers(3,10,20,30);
    printNumbers(5,1,2,3,4,5);
    return 0;
}
