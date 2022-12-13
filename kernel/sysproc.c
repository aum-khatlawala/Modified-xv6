#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc* p = myproc();
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// Assignment 4

uint64
sys_trace(void)
{
  int mask;
  if (argint(0, &mask) == 0)
  {
    myproc()->mask = mask;
    return 0;
  }
  else
  {
    return -1;
  }
}

uint64
sys_sigalarm(void)
{
  int ticks;
  int ticks_ret = argint(0, &ticks);
  if (ticks_ret < 0)
  {
    return -1;
  }
  uint64 handler_address;
  int handler_address_ret = argaddr(1, &handler_address);
  if (handler_address_ret < 0)
  {
    return -1;
  }
  myproc()->ticks = ticks;
  myproc()->handler = handler_address;
  myproc()->alarm_on = 1;
  // printf("Hi\n");
  return 0;
}

uint64
sys_sigreturn(void)
{
  // moving alarm trapframe to trapframe and then freeing the contents of alarm trapframe to restore trapframe
  memmove(myproc()->trapframe, myproc()->alarm_trapframe, 4096);
  kfree(myproc()->alarm_trapframe);
  // cleaning up ticks info
  myproc()->alarm_trapframe = 0;
  myproc()->current_ticks = 0;
  myproc()->handler_permission = 1;
  // printf("Bye\n");
  return myproc()->trapframe->a0;
}

uint64
sys_setpriority()
{
  int pid, priority;

  if ((argint(0, &priority) < 0) || (argint(1, &pid) < 0))
  {
    return -1;
  }
  return setpriority(priority, pid);
}