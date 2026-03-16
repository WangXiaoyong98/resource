 int add(int a, int b){
    int sum;
    __asm__ volatile(
        "add %0, %1, %2"
        :"=r"(sum)
        :"r"(a), "r"(b)
        :"cc"
    );
    return sum;
 }