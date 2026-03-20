#include <linux/input.h>

int main(int argc, char** argv)
{
    int fd;
    int err;
    struct input_id id;

    if(argc != 2)
    {
        printf("Usage: %s <input_device>\n", argv[0]);
        return -1;
    }

    fd = open(argv[1], O_RDWR);
    if(fd < 0){
        printf("open %s failed\n", argv[1]);
        return -1;

    }

    err = ioctl(fd, EVIOCGID, &id);
    if(err == 0){
        printf("ioctl EVIOCGID failed\n");
        return -1;
    }
    printf("input device id: %d\n", id);
    return 0;
   }


//查询方式
APP 调用Open 函数时，传入 “O_NONBLOCK” 标志位，表示非阻塞

APP 调用read函数读取数据时，如果驱动程序中有数据，那么APP的read函数会返回数据，否则会立即返回错误

// 休眠唤醒
APP 调用open函数时候，不要传入 O_NONBLOCK 标志位，否则会导致驱动程序在没有数据时，阻塞在read函数中，
直到有数据可读
APP 调用 read函数读取数据时，如果驱动程序中有数据，那么APP的read函数会返回数据，否则 APP就会在内核态休眠，当有数据时，驱动程序会把 APP 唤醒，read函数恢复执行并把数据返回给APP

//POLL 方式




