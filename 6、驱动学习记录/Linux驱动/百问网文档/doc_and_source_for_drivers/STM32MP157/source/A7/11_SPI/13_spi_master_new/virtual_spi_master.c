#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/errno.h>
#include <linux/timer.h>
#include <linux/delay.h>
#include <linux/list.h>
#include <linux/workqueue.h>
#include <linux/interrupt.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/spi/spi.h>

static struct spi_master *g_virtual_master;

static const struct of_device_id spi_virtual_dt_ids[] = {
	{ .compatible = "100ask,virtual_spi_master", },
	{ /* sentinel */ }
};

static int spi_virtual_probe(struct platform_device *pdev)
{
	struct spi_master *master;
	int ret;
	
	/* 分配/设置/注册spi_master */
	g_virtual_master = master = spi_alloc_master(&pdev->dev, 0);
	if (master == NULL) {
		dev_err(&pdev->dev, "spi_alloc_master error.\n");
		return -ENOMEM;
	}

	ret = spi_register_master(master);
	if (ret < 0) {
		printk(KERN_ERR "spi_register_master error.\n");
		spi_master_put(master);
		return ret;
	}

	return 0;

	
}

static int spi_virtual_remove(struct platform_device *pdev)
{
	/* 反注册spi_master */
	spi_unregister_master(g_virtual_master);
	return 0;
}


static struct platform_driver spi_virtual_driver = {
	.probe = spi_virtual_probe,
	.remove = spi_virtual_remove,
	.driver = {
		.name = "virtual_spi",
		.of_match_table = spi_virtual_dt_ids,
	},
};

static int virtual_master_init(void)
{
	return platform_driver_register(&spi_virtual_driver);
}

static void virtual_master_exit(void)
{
	platform_driver_unregister(&spi_virtual_driver);
}

module_init(virtual_master_init);
module_exit(virtual_master_exit);

MODULE_DESCRIPTION("Virtual SPI bus driver");
MODULE_LICENSE("GPL");
MODULE_AUTHOR("www.100ask.net");

