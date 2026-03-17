.text   // 表示放在代码段
.global add     //实现全局函数 add 
.thumb          //使用 16 位指令集

add:
    add r0, r0, r1
    bx lr

