// #include 
static const struct of_device_id ask100_gpios[] = {
    {.compatible = "100ask,ask100-gpio"},
    {},
};

static int chip_demo_gpio_probe(struct platform_device *pdev){
    int count;
    enum of_gpio_flags flags;
    int gpio;
    count = of_gpio_count(pdev->dev.of_node);
    for(int i = 0;i<count;i++){
        of_gget_gpio_flags(pdev->dev.of_node,i,&flags);
        gpio_to_irq(gpio);
        request_irq(irq,chip_demo_gpio_handler,0,"chip_demo_gpio",pdev);
    }
}

static struct platform_driver chip_demo_gpio_driver = {
    .probe = chip_demo_gpio_probe,
    .remove = chip_demo_gpio_remove,
    .driver = {
        .name = "chip_demo_gpio",
        .of_match_table = ask100_gpios,
    },
};



























static platform_driver test_gpio__driver = {
};

static int test_gpio_drv_init(void){
    platform_driver_register(&test_gpio__driver);
}

static int test_gpio_drv_exit(void){
    platform_driver_unregister(&test_gpio__driver);
}

module_init(test_gpio_drv_init);
module_exit(test_gpio_drv_exit);
MODULE_LICENSE("GPL");

