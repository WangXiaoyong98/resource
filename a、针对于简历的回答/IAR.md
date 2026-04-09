Flash Loader 下载算法

IAR 下载算法总共包括 4 个文件（.out 文件 、 .flash 文件、 .board文件、 .mac文件）

out文件是由“Flash Loader”代码生成了，里面有对QSPI 管脚的定义，函数 FlashInit()、FlashWrite（）、FlashErase（）的实现

.Flash 文件是一个 XML 文件，里面包含了一些必要的元素
Exe: 指向. out 文件
Flash_base:  Flash 的基础地址
Page : Flash每页的大小
Block : 对应 Flash 有多少扇区，每个扇区多大

.Board 文件同样也是 XML 文件，可以由 <pass> *** </pass>进行多个 .flash 文件设置，每个 Pass 包含两个必要属性
range 表明Flash的起始地址及结束地址
loader：当前pass调用那个下载算法的路径

