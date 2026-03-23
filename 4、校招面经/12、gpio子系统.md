1、gpio子系统框架
    gpio控制器：
    gpiochip：
    gpio_desc：
    gpiolib：

2、gpio驱动实现
```C
// GPIO控制器驱动示例
static const struct gpio_chip my_gpio_chip = {
    .label = "my-gpio",
    .owner = THIS_MODULE,
    .base = -1,  // 动态分配
    .ngpio = 32, // 32个GPIO
    .request = my_gpio_request,
    .free = my_gpio_free,
    .direction_input = my_gpio_direction_input,
    .direction_output = my_gpio_direction_output,
    .get = my_gpio_get,
    .set = my_gpio_set,
};
 
static int my_gpio_probe(struct platform_device *pdev)
{
    struct my_gpio_priv *priv;
    int ret;
 
    priv = devm_kzalloc(&pdev->dev, sizeof(*priv), GFP_KERNEL);
    if (!priv)
        return -ENOMEM;
 
    priv->base = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(priv->base))
        return PTR_ERR(priv->base);
 
    priv->chip = my_gpio_chip;
    priv->chip.parent = &pdev->dev;
 
    ret = devm_gpiochip_add_data(&pdev->dev, &priv->chip, priv);
    if (ret)
        return ret;
 
    platform_set_drvdata(pdev, priv);
    return 0;
}
```

