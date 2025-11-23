void func1(int a, int b){
return;
}

int func2(int a, string s){
return a;
}

string func3(int a, int b, int c){
return "hello";
}

int main(){
func1(1, 2);
int k=func2(1, "hello");
func3(1, 2, 3);
return k;
}