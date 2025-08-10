int main(){
    int a=5,b=10;
    a<<=2;
    b>>1;
    a<<b;
    if (a>b){
        b=a?:0;
    }
}
