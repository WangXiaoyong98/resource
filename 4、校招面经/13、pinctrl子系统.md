1、pinctrl 子系统的作用是什么 
    管理和配置 SOC 引脚，实现引脚复用功能配置引脚电气特性，（上拉、下拉、驱动强度），与GPIO子系统协同工作

2、pinctrl 与 GPIO 子系统的关系是什么
    pinctrl 负责引脚功能配置和复用GPIO 子系统负责引脚的输入输出控制两者协同工作，就是pinctrl 先配置引脚功能，GPIO 再控制引脚状态

3、设备树中如何描述 pinctrl 配置
    Pinctrl 配置通常分为两部分，Pin controller节点（描述引脚控制硬件）和 Device 节点（）
```C
// 1. Pin Controller 节点（由 SoC 厂商提供，一般位于 .dtsi 文件）
pinctrl: pinctrl {
    compatible = "rockchip,rk3568-pinctrl";
    reg = <0x0 0xfdc20000 0x0 0x10000>;
 
    // 定义 GPIO 引脚组
    gpio0: gpio0 {
        gpio-controller;
        #gpio-cells = <2>;
        interrupt-controller;
        #interrupt-cells = <2>;
    };
 
    // 定义 UART2 的引脚复用配置
    uart2m0_xfer: uart2m0-xfer {
        rockchip,pins =
            // 引脚复用为 UART2，配置电气属性
            <0 RK_PD1 1 &pcfg_pull_none>,  // TXD
            <0 RK_PD0 1 &pcfg_pull_none>;  // RXD
    };
};

// 2. Device 节点（在板级 .dts 文件中）
&uart2 {
    status = "okay";
    pinctrl-names = "default";          // 状态名
    pinctrl-0 = <&uart2m0_xfer>;       // 引用具体的 pinctrl 配置
};

```

