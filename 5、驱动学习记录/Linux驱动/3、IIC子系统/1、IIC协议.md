# 1.1 IIC 传输数据的格式
## 写操作
1、主芯片发出 start 信号
2、发出一个设备地址（往哪个芯片写数据，方向（读、写 0表示写，1表示读））
3、从设备回应（用来确定这个设备是否存在，然后就可以传输数据）
4、主设备发送一个字节数据给从设备并等待回应
5、每传输一字节数据，接收方要有一个回应信号（确定数据是否接受完成），然后再传输下一个数据
6、数据发送完成后，主芯片就会发送一个停止信号

## 读操作
1、主芯片要发出一个 start 信号
2、然后发出一个设备地址（用来确定往哪个芯片写数据），方向（读、写 0表示写，1 表示读 ）
3、从设备回应 （用来确定这个设备是否存在，然后就可以传输数据）
4、从设备发送一个字节数据给主设备，并等待回应
5、每传输一字节数据，接收方就要有一个回应信号（确定数据是否接受完成），然后再传输下一个数据
6、数据发送完成之后，主芯片就会发送一个停止信号

## I2C信号
I2C 协议中数据传输的单位是字节，也就是 8 位，但是要用到9个时钟，前面8个时钟用来传输数据，第九个时钟用来传输回应信号，传输时，先传输的是最高位 （MSB）
只有两根线，一根是 SDA 一根是 SCK
开始信号 ： SCL 高电平期间，SDA 由高向低跳变 开始传输数据
结束信号 :  SCL 高电平期间，SDA 由低向高跳变 结束传输数据
响应信号（ACK）： 接收器在接收到8位数据后，在第9个时钟周期，拉低SDA

SMBus
SMBus 是 I2C 协议的一个子集
SMBus : System Management Bus 系统管理总线
SMBus 用来链接各种设备，包括电源相关设备 系统传感器，EEPROM 通讯设备
SMBus 与 I2C 协议的联系与区别

## 时钟延长
I2C 协议中的 时钟延长概念：从设备为了控制数据传输节奏，主动拉低时钟线的行为

为什么需要时钟延长：
从设备通常比主设备速度慢，需要额外的时间来处理数据      

其本质上是一种流控机制 

i2c_client : 一般是使用七位地址，加上一些扩展也可以使用十位地址 


设备挂在控制器下面一般是写在 adapter 里面

数据写在 i2c_msg 里面
struct i2c_msg {
    __u16 addr;
    __u16 flags;
#define I2C_M_RD          0x001 //读数据
#define I2C_M_TEN         0x010 //10bit chip addr
#define I2C_M_DMA_SAFE    0x0200  //10bit chip addr
#define I2C_M_RECV_LEN    0x0400  //length will be first received
#define I2C_M_NO_RD_ACK    0x0000  //
#define I2C_M_IGNORE_NAK   0x10000   
    __u16 len;              //消息长度
    __u8 *buf;              //消息缓冲

}

## I2C tools
APP  通过 I2C controller 和 I2C Device 进行通信
使用 I2C tools 需要指定：
1、I2C 控制器（I2C BUS、 I2C Adapter）
2、I2C Device 地址
3、数据：读写，数据本身


## Linux下检测 I2C 设备
指令： i2cdetect -l //检测i2c设备

// 使用SMBus协议写数据
i2cset -f  -y 0 0x1e 0 0x4   //i2c写数据
i2cget -f  -y 0 0x1e 0 0x4   //i2c读数据

//使用I2C协议读数据
i2ctransfer -f -y 0 w2@0x1e 0 0x4 

I2C 读取芯片数据时，每读出一个数据，芯片内部的地址值就会加1 ，当地址值增长到最大时，会变为0，再次读数据时就会从0地址继续累加
int main(int argc，char **argv)
{
    unsigned char dev_addr =0x50;
    unsigned char mem_addr = 0;
    unsigned char buf[50] = {0};

    int file;
    char filename[20];
    unsigned char *str;

    if (argc != 3 && argc != 4){
        printf("Usage: %s <bus> <addr> [len]\n", argv[0]);
    }

    file = open_i2c_dev(i2cbus,filename,sizeof(filename),0);
    if (file < 0){
        printf("open i2c dev failed\n");
        return -1;
    }
    if(set_slave_addr(file,dev_addr,1)){
        printf("set slave addr failed\n");
        return -1;
    }
    if(argv[2][0] = 'w')
    {
        //write str: argc[3]
        str = argv[3];
        while(*str)
        {
            // mem_addr, *str
            // mem_addr++, str++
            i2c_smbus_write_byte_data(file,mem_addr,*str);
            mem_addr++;
            str++;
        }
        i2c_smbus_write_byte_data(file,mem_addr,0); //string end char

    }else
    {
        i2c_smbus_read_i2c_block_data(file,mem_addr,sizeof(buf),buf);
        buf[31] = '\0';
            printf("read data: %s\n",buf);
    }


}






