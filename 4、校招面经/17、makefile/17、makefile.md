1、VPATH 机制

    VPATH 是一个 Makefile 变量，用于指定一个或多个目录路径，告诉 make 在这些目录中搜索依赖文件和目标文件。
    工作原理：
        1、依赖文件搜索： 当make找不到依赖文件时，会在VPATH指定的目录中搜索
        2、规则匹配 ： 找到文件后，make会在规则中使用实际找到的路径


2、vpath 指令
    vpath指令 选择性搜索
    具体用法 ： 
        1) vpath PATTERN DIRECTORIES 
        说明：vpath test.c src              // 在 src 路径下搜索文件 test.c
        2) vpath PATTERN
        vpath test.c                        // 清除符合文件 test.c 的搜索目录 
        3) vpath                            //清除所有已被设置的文件搜索路径
