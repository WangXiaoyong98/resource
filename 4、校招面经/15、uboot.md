1、Uboot 的基本概念和作用
    u-boot 是一段裸机引导程序，主要功能包括
        1. 硬件初始化：初始化CPU 内存控制器，时钟等硬件
        2、加载OS，将存储设备中的操作系统加载到内存并执行
        3、提供命令行界面，用户可以通过该界面与系统交互
    
2、u-boot 启动流程
    1、执行最小化硬件初始化，设置时钟和内存控制器加载u-boot到ram
    2、完成更全面的硬件初始化，包括GPIO、UART、SPI、I2C等
    3、命令处理阶段：检查自动启动倒计时，如果倒计时终端，进入命令行界面，执行预设的启动命令
    4、os 加载阶段：从指定存储设备加载内核镜像准备内核启动参数跳转到内核入口下执行

```C
// SPL启动流程简化代码示例
void board_init_f(ulong dummy)
{
    /* 时钟初始化 */
    clock_init();
 
    /* 串口初始化 */
    serial_init();
 
    /* DRAM初始化 */
    dram_init();
 
    /* 加载U-Boot主镜像 */
    spl_load_image();
 
    /* 跳转到U-Boot主镜像 */
    jump_to_image_no_args();
}
```

3、u-boot 环境变量
    u-boot 中的环境变量是一组键值对，用于配置系统启动参数和行为
    1、环境变量存储：Flash 或者 EEPROM
    2、环境变量 : bootargs 用于传递内核启动参数
                 bootcmd 用于指定启动命令
                 bootdelay 用于指定启动延时时间
    3、环境变量操作指令： printenv ： 打印环境变量
                        setenv ： 设置环境变量
                        saveenv ： 保存环境变量到存储

```C
// 环境变量操作示例
// 设置bootargs
setenv bootargs 'console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait'
 
// 设置复合命令
setenv bootcmd 'mmc dev 0; fatload mmc 0:1 ${loadaddr} uImage; bootm ${loadaddr}'
 
// 保存环境变量
saveenv
 
// 执行环境变量中的命令
run bootcmd
```

4、如何自定义 u-boot 环境变量
    1、配置方式，在 include/config/board.h 中定义 CONFIG_EXTRA_ENV_SETTINGS 或在 board 中定义 board_env_default 

    2、defconfig 方式：在板级 defconfig 中添加 CONFIG_ENV_VARS_YBOOT_CONFIG=y 然后添加 CONFIG_ENV_VAR_[name]="value"

```C
// 在头文件中定义默认环境变量
#define CONFIG_EXTRA_ENV_SETTINGS \
    "bootargs=console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait\0" \
    "bootcmd=mmc dev 0; fatload mmc 0:1 ${loadaddr} uImage; bootm ${loadaddr}\0" \
    "ipaddr=192.168.1.100\0" \
    "serverip=192.168.1.1\0"
```

5、u-boot 设备树支持
    u-boot 如何使用设备树，设备树在u-boot 中的作用是什么
        1、u-boot 中设备树的使用：硬件平台描述驱动程序配置向linux内核传递硬件信息
        2、设备树在 u-boot 中的使用，编译时生成的dtb 文件， u-boot 加载设备树到内存可以再运行时修改设备树驱动内核时传递设备树地址
        3、设备树相关命令
            1、fdt addr ： 设置设备树工作地址
            2、fdt get : 获取设备树节点属性


6、u-boot 调试技巧
    1、使用 printenv 打印环境变量
    2、使用 printf\debug 等函数输出信息设置不同级别的调试信息
    3、GDB调试
    4、常见调试命令 bdinfo
    5、md/mm 内存查看
    6、mw 内存写入

```C
// 调试配置示例
#define CONFIG_BOOTDELAY 10
#define CONFIG_DEBUG_UART
#define CONFIG_LOGLEVEL 8  // 最详细的日志级别

// 板级配置文件示例 (configs/myboard_defconfig)
CONFIG_ARM=y
CONFIG_ARCH_MYVENDOR=y
CONFIG_TARGET_MYBOARD=y
CONFIG_SYS_TEXT_BASE=0x80000000
CONFIG_NR_DRAM_BANKS=1
CONFIG_ENV_SIZE=0x2000
CONFIG_ENV_OFFSET=0x100000
CONFIG_SYS_PROMPT="MyBoard> "
 
// 板级初始化代码示例
int board_init(void)
{
    /* 设置SDRAM基地址 */
    gd->bd->bi_dram[0].start = CONFIG_SYS_SDRAM_BASE;
    gd->bd->bi_dram[0].size = CONFIG_SYS_SDRAM_SIZE;
 
    /* 初始化GPIO */
    gpio_init();
 
    return 0;
}
 
int dram_init(void)
{
    /* 初始化SDRAM控制器 */
    sdram_init();
 
    return 0;
}
```

7、u-boot 与 linux 内核交互
    u-boot 可以向linux内核传递参数
    1、bootargs ： 用于传递内核启动参数
    2、设备树 ： 通过 、chosen 节点传递参数可以在运行时修改设备树
```C
// 通过bootargs传递参数
setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait ip=dhcp"
 
// 通过设备树传递参数
fdt addr ${fdt_addr}
fdt resize
fdt set /chosen bootargs "console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait"
```

8、在 u-boot 开发过程中会遇到哪些常见问题，如何解决 
    1、卡在特定阶段
    增加调试打印，定位卡住的具体位置，检查硬件初始化代码；
    2、环境变量丢失
    检查环境变量存储区域配置，验证flash 是否成功写入
    3、网络功能不正常（无法通过网络加载文件）
    用ping测试下网络连接成功
    4、内存初始化问题（内存初始化失败导致系统不稳定）
    检查内存控制器配置，调整时序参数，使用mtest 命令测试内存
    5、设备树加载失败
    检查设备树格式，验证加载地址

9、 u-boot 性能优化
    1、减少不必要的ip初始化，禁用不需要的外设
    2、优化内存操作：使用DMA进行大块内存复制
    3、开启编译优化选项

10、u-boot 与 Bootloader 安全性（u-boot在系统安全方面有哪些考虑，如何增强 u-boot 安全性）
    1、安全启动：验证签名
    2、防回滚保护：检查版本
    3、敏感数据保护
