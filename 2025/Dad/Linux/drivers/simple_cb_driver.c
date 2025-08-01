// simple_cb_driver.c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/string.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("OpenAI");
MODULE_DESCRIPTION("Simple sysfs callback driver");
MODULE_VERSION("1.0");

static struct class *simple_class;
static struct device *simple_device;

static void on_yes(void)
{
    pr_info("Callback: YES was triggered!\n");
}

static void on_no(void)
{
    pr_info("Callback: NO was triggered!\n");
}
//using static makes the function local removing static would make visible to tracing
// and add EXPORT_SYMBOL_GPL(control_store);
//static ssize_t control_store(struct device *dev,
ssize_t control_store(struct device *dev,
                             struct device_attribute *attr,
                             const char *buf, size_t count)
{
    if (sysfs_streq(buf, "yes")) {
        on_yes();
    } else if (sysfs_streq(buf, "no")) {
        on_no();
    } else {
        pr_info("Unknown command: '%s'\n", buf);
    }

    return count;
}
EXPORT_SYMBOL(control_store);

// Create writable file: /sys/class/simple_cb/control
static DEVICE_ATTR_WO(control);  // Write-only sysfs attribute

static int __init simple_cb_init(void)
{
    int ret;

    simple_class = class_create(THIS_MODULE, "simple_cb");
    if (IS_ERR(simple_class))
        return PTR_ERR(simple_class);

    simple_device = device_create(simple_class, NULL, 0, NULL, "cbdev");
    if (IS_ERR(simple_device)) {
        class_destroy(simple_class);
        return PTR_ERR(simple_device);
    }

    ret = device_create_file(simple_device, &dev_attr_control);
    if (ret) {
        device_destroy(simple_class, 0);
        class_destroy(simple_class);
        return ret;
    }

    pr_info("==>Simple callback driver loaded<==\n");
    return 0;
}

static void __exit simple_cb_exit(void)
{
    device_remove_file(simple_device, &dev_attr_control);
    device_destroy(simple_class, 0);
    class_destroy(simple_class);
    pr_info("Simple callback driver unloaded\n");
}

module_init(simple_cb_init);
module_exit(simple_cb_exit);
