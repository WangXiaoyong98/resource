void * my_memcpy(void *dest,const void *src, int n){
    unsigned char* d = dest;
    const unsigned char* s = src;
    for(int i = 0;i < n;++i){
        d[i] = s[i];
    }
    return dest;
}