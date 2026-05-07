.global _start  ; 声明_start为全局符号，链接器通过该符号定位程序入口地址，必须声明
.extern main    ; 声明main为外部符号，来自C语言文件main.c，告诉汇编器该符号在其他文件中定义
 
; -------------------------- 异常向量表（ARMv7-A架构强制要求，0x00~0x1C） --------------------------
; ARM架构规定：CPU上电/复位后，必须在0x00000000~0x0000001C地址空间配置异常向量表
; 共8个异常向量，每个向量占4字节，对应ARM的8种异常类型，发生异常时CPU自动跳转到对应地址
_start:
    ldr pc, =_reset_handler      ; 0x00: 复位异常（上电/复位后第一个执行的异常，核心）
    ldr pc, =_undef_handler      ; 0x04: 未定义指令异常（捕获CPU无法识别的非法指令）
    ldr pc, =_software_handler   ; 0x08: 软件中断异常（用于系统调用，如Linux的软中断）
    ldr pc, =_prefect_handler    ; 0x0C: 预取指中止异常（指令读取错误，如地址越界）
    ldr pc, =_data_abort_handler ; 0x10: 数据中止异常（数据读写错误，如写只读内存）
    nop                          ; 0x14: 保留地址（ARM架构预留，必须填充nop，避免地址错位）
    ldr pc, =_irq_handler        ; 0x18: IRQ中断异常（外部设备中断，如按键、定时器）
    ldr pc, =_fiq_handler        ; 0x1C: FIQ快速中断异常（高优先级中断，如高速传感器）
 
; -------------------------- 异常处理函数（暂设死循环，工业开发需完善） --------------------------
; 本次实验为基础LED控制，暂未使用复杂异常处理，所有未用到的异常处理函数均设为死循环
; 目的：捕获异常后，防止CPU执行无效指令导致**程序跑飞**，是裸机程序的基础保护机制
; 工业级开发中，需根据异常类型编写专属处理逻辑（如数据备份、错误上报、系统复位）
_undef_handler:
    b _undef_handler  ; 无条件跳转到自身，实现死循环
 
_software_handler:
    b _software_handler  
 
_prefect_handler:
    b _prefect_handler  
 
_data_abort_handler:
    b _data_abort_handler  
 
_irq_handler:
    b _irq_handler  
 
_fiq_handler:
    b _fiq_handler  
 
; -------------------------- 复位异常处理函数：核心初始化流程（重中之重） --------------------------
; 复位异常是上电后第一个执行的异常，所有底层硬件初始化均在此完成，是裸机程序的核心
; 初始化流程：关闭全局中断→配置处理器模式→设置栈地址→开启全局中断→跳转到C语言main函数
_reset_handler:
    ; 1. 关闭IRQ全局中断（cpsid i），FIQ中断默认关闭
    ; 指令说明：cpsid = Change Processor State IDisable，i表示IRQ中断，f表示FIQ中断
    ; 初始化阶段：CPU状态不稳定，栈地址、处理器模式尚未配置，若触发中断会导致程序跑飞
    cpsid i                 
    
    ; 2. 切换处理器到IRQ模式（0x12为IRQ模式的固定编码，ARMv7-A架构定义）
    ; 为IRQ模式配置独立栈地址，避免中断处理时覆盖其他模式的栈数据
    cps #0x12               
    ; 3. 设置IRQ模式的栈地址（SP指针），0x82000000为DDR3的空闲安全地址
    ldr sp, =0x82000000     
    ; 4. 切换处理器到SYS模式（系统模式，0x1F为固定编码）
    ; SYS模式是裸机程序主逻辑的默认运行模式，拥有特权模式的所有权限，与USER模式共享寄存器
    cps #0x1F               
    ; 5. 设置SYS模式的栈地址，0x84000000与IRQ模式栈地址间隔200MB，实现完全隔离
    ldr sp, =0x84000000     
    ; 6. 开启IRQ全局中断（cpsie i）
    ; 初始化完成后，CPU状态稳定，开启中断以响应外部设备请求（本次实验暂未使用中断，可省略）
    cpsie i                 
    
    ; 7. 无条件跳转到C语言main函数，执行LED控制业务逻辑
    ; b指令：ARM汇编无条件跳转指令，跳转后不返回，符合裸机程序死循环逻辑
    ; 这一步是**汇编到C语言的关键过渡**，完成底层初始化到上层业务逻辑的切换
    b main                  
    
; 程序结束后死循环，防止CPU执行无效指令导致跑飞
; 裸机程序无操作系统的进程调度，若main函数意外退出，CPU会继续执行后续内存的无效指令
finish:
    b finish  

    