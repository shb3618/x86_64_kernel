#include <yaos/printk.h>
#include <asm/pm64.h>
void jump_to_zero()
{
    print_regs();
    printk("jump to zero?\n");
    asm volatile("cli");
    for(;;);
}
void install_zero_hook()
{
    uchar code[20];
    ulong addr = (ulong) jump_to_zero - 5; //相对偏移跳转，减去指令长度5字节
    uchar *ptr = (uchar *) 0;
    printk("addr %lx\n",addr);
    code[0] = 0xe9;
    code[1] = addr & 0xff;
    code[2] = (addr >> 8) & 0xff;
    code[3] = (addr >> 16) & 0xff;
    code[4] = (addr >> 24) & 0xff;
    for (int i = 0; i < 5; i++) {
        printk(" %x ",code[i]);
        *ptr++ = code[i];
    }
    printk("install_zero_hook：%lx\n", (ulong) jump_to_zero);
}
void default_exception(struct trapframe *tf)
{
    extern void cprint_regs(struct trapframe *tf);
    cprint_regs(tf);
    asm volatile("cli");
    for(;;);

}
void default_syscall(struct trapframe *tf)
{
    printk("SSYSCALL EIP:%lx,Error:%lx\n", tf->rip, tf->trapno);
    print_regs();

}
void default_trap(struct trapframe *tf)
{
    printk("Trap EIP:%lx,Error:%lx\n", tf->rip, tf->trapno);
    print_regs();

}
