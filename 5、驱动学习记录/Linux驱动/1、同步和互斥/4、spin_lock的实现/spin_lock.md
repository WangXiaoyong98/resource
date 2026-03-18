自旋锁 spin_lock 在多核的系统中也有效，Core0 如果占用了其中一个资源，Core1 这个时候需要用这个资源，则会无法抢占。

spin_lock 中需要做的事情：
1、禁止抢占 Preempt_disable()
2、关中断 （spin_lock 这个时候就是 spin_lock_irq），同时也要禁止抢占

