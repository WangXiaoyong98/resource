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






