#define READ_REG(addr) (*(volatile unsigned int*)(addr))

// 针对不同场景的宏

// 1. 基本读取
#define REG_READ(addr)     (*(volatile unsigned int*)(addr))

// 2. 基本写入  
#define REG_WRITE(addr, val) ((*(volatile unsigned int*)(addr)) = (val))

// 3. 修改特定位（置1）
#define REG_SET_BIT(addr, bit) (REG_WRITE(addr, REG_READ(addr) | (bit)))

// 4. 修改特定位（清0）
#define REG_CLEAR_BIT(addr, bit) (REG_WRITE(addr, REG_READ(addr) & ~(bit)))

// 5. 带参数检查的版本（调试用）
#ifdef DEBUG
    #define SAFE_READ_REG(addr) \
        (((addr) >= 0x40000000 && (addr) <= 0x5FFFFFFF) ? \
         (*(volatile unsigned int*)(addr)) : 0)
#else
    #define SAFE_READ_REG(addr) (*(volatile unsigned int*)(addr))
#endif



