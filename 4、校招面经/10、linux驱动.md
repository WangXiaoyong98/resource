1、驱动分类
    字符设备驱动：键盘、串口
    块设备驱动：硬盘、光驱
    网络设备驱动：网卡、无线网卡、

2、驱动模块基本结构
```C


#include <linux/module.h>
#include <linux/init.h>


static int __init my_driver_init(void)
{
    printk(KERN_INFO "my_driver_init\n");
    return 0;
}

static void __exit my_driver_exit(void)
{
    printk(KERN_INFO "my_driver_exit\n");
}

module_init(my_driver_init);
module_exit(my_driver_exit);


```

3、驱动加载方式
    静态加载：编译进内核镜像
    动态加载：编译为模块（.ko）,使用 insmod modprobe 加载
    对应模块的静态加载和动态加载可以通过manuconfig来控制


4、字符驱动设备
    字符驱动设备驱动模块基本结构
```C
//分配设备号
dev_t dev;
alloc_chrdev_region(&dev, 0, 1, "my_driver");

//初始化cdev结构
struct cdev *my_cdev = cdev_alloc();
cdev_init(my_cdev,&fops);
my_cdev->owner = THIS_MODULE;

// 添加字符设备驱动
cdev_add(my_cdev, dev, 1);


//创建设备节点
struct class *my_class = class_create(THIS_MODULE, "my_driver");
device_create(my_class, NULL, dev, NULL, "%d", MINOR(dev));
```

5、文件操作结构体

```C
static struct file_operations my_fops = {
    .owner = THIS_MODULE,
    .open = my_open,
    .release = my_release,
    .read = my_read,
    .write = my_write,
    .unlocked_ioctl = my_ioctl,
};
```

6、字符设备驱动的主设备号和次设备号有什么作用
    主设备号：用于标识设备的类型，例如字符设备、块设备等
    次设备号：用于标识设备的实例，例如多个字符设备的实例、

7、copy_to_user 和 copy_from_user
    安全的在内核空间和用户空间进行数据拷贝


8、设备树和平台驱动
    8.1 设备树基础
```C
    my_device: my_device@50000000 { //标签（label）:<名称>@<寄存器基址>
        compatible = "vendor,my-device";
        reg = <0x50000000 0x100000>; //设备占用的物理地址空间
        interrupt-cells = <1>;
        interrupts = <0 100 0>; //中断类型、中断号、中断触发方式
        clocks = <&clk_1>;
        clock-names = "clk_1";
        status = "okay";
    };
```

9、设备树的作用是什么
描述硬件设备、实现硬件与驱动分离

10、如何在驱动中获得设备树中的函数
    1、通过设备树匹配节点（compatible）
    2、提取常用属性（of函数）

```C
#include <linux/of.h>
#include <linux/platform_device.h>
 
static int my_probe(struct platform_device *pdev)
{
    struct device_node *node = pdev->dev.of_node;
    struct resource *res;
    void __iomem *regs;
    int irq, ret;
    u32 freq;
 
    /* 1. 获取寄存器地址（通过 reg 属性） */
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    regs = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(regs))
        return PTR_ERR(regs);
 
    /* 2. 获取中断号 */
    irq = platform_get_irq(pdev, 0);
    if (irq < 0)
        return irq;
 
    /* 3. 读取自定义整数属性 */
    ret = of_property_read_u32(node, "clock-frequency", &freq);
    if (ret) {
        dev_warn(&pdev->dev, "clock-frequency not specified, using default\n");
        freq = 25000000; // 默认值
    }
 
    /* 4. 检查布尔属性 */
    if (of_property_read_bool(node, "dma-capable")) {
        setup_dma();
    }
 
    /* 注册中断处理函数 */
    ret = devm_request_irq(&pdev->dev, irq, my_irq_handler, 0, "my-device", NULL);
    if (ret)
        return ret;
 
    dev_info(&pdev->dev, "Device probed, freq=%d Hz\n", freq);
    return 0;
}
 
static const struct of_device_id my_device_ids[] = {
    { .compatible = "vendor,my-device" },
    { }
};
MODULE_DEVICE_TABLE(of, my_device_ids);
 
static struct platform_driver my_driver = {
    .driver = {
        .name = "my-device",
        .of_match_table = my_device_ids,
    },
    .probe = my_probe,
};
module_platform_driver(my_driver);
```

11、platform_driver 和 platform_device 关系
    platform_device : 描述设备资源
    platform_driver : 实现设备驱动通过总线和模型绑定

