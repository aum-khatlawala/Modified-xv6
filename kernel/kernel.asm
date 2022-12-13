
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c8010113          	addi	sp,sp,-896 # 80008c80 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	aee70713          	addi	a4,a4,-1298 # 80008b40 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	17c78793          	addi	a5,a5,380 # 800061e0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdac4f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	5f6080e7          	jalr	1526(ra) # 80002722 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	af450513          	addi	a0,a0,-1292 # 80010c80 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ae448493          	addi	s1,s1,-1308 # 80010c80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b7290913          	addi	s2,s2,-1166 # 80010d18 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	832080e7          	jalr	-1998(ra) # 800019f6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	3a0080e7          	jalr	928(ra) # 8000256c <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f8e080e7          	jalr	-114(ra) # 80002168 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	4b6080e7          	jalr	1206(ra) # 800026cc <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	a5650513          	addi	a0,a0,-1450 # 80010c80 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a4050513          	addi	a0,a0,-1472 # 80010c80 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	aaf72023          	sw	a5,-1376(a4) # 80010d18 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	9ae50513          	addi	a0,a0,-1618 # 80010c80 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	480080e7          	jalr	1152(ra) # 80002778 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	98050513          	addi	a0,a0,-1664 # 80010c80 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	95c70713          	addi	a4,a4,-1700 # 80010c80 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	93278793          	addi	a5,a5,-1742 # 80010c80 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	99c7a783          	lw	a5,-1636(a5) # 80010d18 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	8f070713          	addi	a4,a4,-1808 # 80010c80 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	8e048493          	addi	s1,s1,-1824 # 80010c80 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	8a470713          	addi	a4,a4,-1884 # 80010c80 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	92f72723          	sw	a5,-1746(a4) # 80010d20 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	86878793          	addi	a5,a5,-1944 # 80010c80 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	8ec7a023          	sw	a2,-1824(a5) # 80010d1c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	8d450513          	addi	a0,a0,-1836 # 80010d18 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	ed0080e7          	jalr	-304(ra) # 8000231c <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	81a50513          	addi	a0,a0,-2022 # 80010c80 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00022797          	auipc	a5,0x22
    80000482:	59a78793          	addi	a5,a5,1434 # 80022a18 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	7e07a823          	sw	zero,2032(a5) # 80010d40 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	56f72e23          	sw	a5,1404(a4) # 80008b00 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	780dad83          	lw	s11,1920(s11) # 80010d40 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	72a50513          	addi	a0,a0,1834 # 80010d28 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	5c650513          	addi	a0,a0,1478 # 80010d28 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	5aa48493          	addi	s1,s1,1450 # 80010d28 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	56a50513          	addi	a0,a0,1386 # 80010d48 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	2f67a783          	lw	a5,758(a5) # 80008b00 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	2c273703          	ld	a4,706(a4) # 80008b08 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2c27b783          	ld	a5,706(a5) # 80008b10 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	4d8a0a13          	addi	s4,s4,1240 # 80010d48 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	29048493          	addi	s1,s1,656 # 80008b08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	29098993          	addi	s3,s3,656 # 80008b10 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	a76080e7          	jalr	-1418(ra) # 8000231c <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	46650513          	addi	a0,a0,1126 # 80010d48 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	20e7a783          	lw	a5,526(a5) # 80008b00 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2147b783          	ld	a5,532(a5) # 80008b10 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	20473703          	ld	a4,516(a4) # 80008b08 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	438a0a13          	addi	s4,s4,1080 # 80010d48 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	1f048493          	addi	s1,s1,496 # 80008b08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	1f090913          	addi	s2,s2,496 # 80008b10 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	838080e7          	jalr	-1992(ra) # 80002168 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	40248493          	addi	s1,s1,1026 # 80010d48 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	1af73b23          	sd	a5,438(a4) # 80008b10 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	37848493          	addi	s1,s1,888 # 80010d48 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00023797          	auipc	a5,0x23
    80000a16:	19e78793          	addi	a5,a5,414 # 80023bb0 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	34e90913          	addi	s2,s2,846 # 80010d80 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	2b250513          	addi	a0,a0,690 # 80010d80 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00023517          	auipc	a0,0x23
    80000ae6:	0ce50513          	addi	a0,a0,206 # 80023bb0 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	27c48493          	addi	s1,s1,636 # 80010d80 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	26450513          	addi	a0,a0,612 # 80010d80 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	23850513          	addi	a0,a0,568 # 80010d80 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e56080e7          	jalr	-426(ra) # 800019da <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	e24080e7          	jalr	-476(ra) # 800019da <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	e18080e7          	jalr	-488(ra) # 800019da <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	e00080e7          	jalr	-512(ra) # 800019da <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	dc0080e7          	jalr	-576(ra) # 800019da <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d94080e7          	jalr	-620(ra) # 800019da <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b2e080e7          	jalr	-1234(ra) # 800019ca <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	c7470713          	addi	a4,a4,-908 # 80008b18 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	b12080e7          	jalr	-1262(ra) # 800019ca <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	a62080e7          	jalr	-1438(ra) # 8000293c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	33e080e7          	jalr	830(ra) # 80006220 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	12c080e7          	jalr	300(ra) # 80002016 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	9cc080e7          	jalr	-1588(ra) # 80001916 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	9c2080e7          	jalr	-1598(ra) # 80002914 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	9e2080e7          	jalr	-1566(ra) # 8000293c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	2a8080e7          	jalr	680(ra) # 8000620a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	2b6080e7          	jalr	694(ra) # 80006220 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	464080e7          	jalr	1124(ra) # 800033d6 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	b08080e7          	jalr	-1272(ra) # 80003a82 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	aa6080e7          	jalr	-1370(ra) # 80004a28 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	39e080e7          	jalr	926(ra) # 80006328 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d7a080e7          	jalr	-646(ra) # 80001d0c <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b6f72c23          	sw	a5,-1160(a4) # 80008b18 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	b6c7b783          	ld	a5,-1172(a5) # 80008b20 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00008797          	auipc	a5,0x8
    80001274:	8aa7b823          	sd	a0,-1872(a5) # 80008b20 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	96a48493          	addi	s1,s1,-1686 # 800111d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00017a17          	auipc	s4,0x17
    80001884:	f50a0a13          	addi	s4,s4,-176 # 800187d0 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	1d848493          	addi	s1,s1,472
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <max>:

int max(int a, int b)
{
    800018e6:	1141                	addi	sp,sp,-16
    800018e8:	e422                	sd	s0,8(sp)
    800018ea:	0800                	addi	s0,sp,16
  return (a > b) ? a : b;
    800018ec:	87ae                	mv	a5,a1
    800018ee:	00a5d363          	bge	a1,a0,800018f4 <max+0xe>
    800018f2:	87aa                	mv	a5,a0
}
    800018f4:	0007851b          	sext.w	a0,a5
    800018f8:	6422                	ld	s0,8(sp)
    800018fa:	0141                	addi	sp,sp,16
    800018fc:	8082                	ret

00000000800018fe <min>:
int min(int a, int b)
{
    800018fe:	1141                	addi	sp,sp,-16
    80001900:	e422                	sd	s0,8(sp)
    80001902:	0800                	addi	s0,sp,16
  return (a > b) ? a : b;
    80001904:	87ae                	mv	a5,a1
    80001906:	00a5d363          	bge	a1,a0,8000190c <min+0xe>
    8000190a:	87aa                	mv	a5,a0
}
    8000190c:	0007851b          	sext.w	a0,a5
    80001910:	6422                	ld	s0,8(sp)
    80001912:	0141                	addi	sp,sp,16
    80001914:	8082                	ret

0000000080001916 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001916:	7139                	addi	sp,sp,-64
    80001918:	fc06                	sd	ra,56(sp)
    8000191a:	f822                	sd	s0,48(sp)
    8000191c:	f426                	sd	s1,40(sp)
    8000191e:	f04a                	sd	s2,32(sp)
    80001920:	ec4e                	sd	s3,24(sp)
    80001922:	e852                	sd	s4,16(sp)
    80001924:	e456                	sd	s5,8(sp)
    80001926:	e05a                	sd	s6,0(sp)
    80001928:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    8000192a:	00007597          	auipc	a1,0x7
    8000192e:	8b658593          	addi	a1,a1,-1866 # 800081e0 <digits+0x1a0>
    80001932:	0000f517          	auipc	a0,0xf
    80001936:	46e50513          	addi	a0,a0,1134 # 80010da0 <pid_lock>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	220080e7          	jalr	544(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	8a658593          	addi	a1,a1,-1882 # 800081e8 <digits+0x1a8>
    8000194a:	0000f517          	auipc	a0,0xf
    8000194e:	46e50513          	addi	a0,a0,1134 # 80010db8 <wait_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	208080e7          	jalr	520(ra) # 80000b5a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000195a:	00010497          	auipc	s1,0x10
    8000195e:	87648493          	addi	s1,s1,-1930 # 800111d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001962:	00007b17          	auipc	s6,0x7
    80001966:	896b0b13          	addi	s6,s6,-1898 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000196a:	8aa6                	mv	s5,s1
    8000196c:	00006a17          	auipc	s4,0x6
    80001970:	694a0a13          	addi	s4,s4,1684 # 80008000 <etext>
    80001974:	04000937          	lui	s2,0x4000
    80001978:	197d                	addi	s2,s2,-1
    8000197a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000197c:	00017997          	auipc	s3,0x17
    80001980:	e5498993          	addi	s3,s3,-428 # 800187d0 <tickslock>
    initlock(&p->lock, "proc");
    80001984:	85da                	mv	a1,s6
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1d2080e7          	jalr	466(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001990:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001994:	415487b3          	sub	a5,s1,s5
    80001998:	878d                	srai	a5,a5,0x3
    8000199a:	000a3703          	ld	a4,0(s4)
    8000199e:	02e787b3          	mul	a5,a5,a4
    800019a2:	2785                	addiw	a5,a5,1
    800019a4:	00d7979b          	slliw	a5,a5,0xd
    800019a8:	40f907b3          	sub	a5,s2,a5
    800019ac:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    800019ae:	1d848493          	addi	s1,s1,472
    800019b2:	fd3499e3          	bne	s1,s3,80001984 <procinit+0x6e>
  }
}
    800019b6:	70e2                	ld	ra,56(sp)
    800019b8:	7442                	ld	s0,48(sp)
    800019ba:	74a2                	ld	s1,40(sp)
    800019bc:	7902                	ld	s2,32(sp)
    800019be:	69e2                	ld	s3,24(sp)
    800019c0:	6a42                	ld	s4,16(sp)
    800019c2:	6aa2                	ld	s5,8(sp)
    800019c4:	6b02                	ld	s6,0(sp)
    800019c6:	6121                	addi	sp,sp,64
    800019c8:	8082                	ret

00000000800019ca <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e422                	sd	s0,8(sp)
    800019ce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019d2:	2501                	sext.w	a0,a0
    800019d4:	6422                	ld	s0,8(sp)
    800019d6:	0141                	addi	sp,sp,16
    800019d8:	8082                	ret

00000000800019da <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019da:	1141                	addi	sp,sp,-16
    800019dc:	e422                	sd	s0,8(sp)
    800019de:	0800                	addi	s0,sp,16
    800019e0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e6:	0000f517          	auipc	a0,0xf
    800019ea:	3ea50513          	addi	a0,a0,1002 # 80010dd0 <cpus>
    800019ee:	953e                	add	a0,a0,a5
    800019f0:	6422                	ld	s0,8(sp)
    800019f2:	0141                	addi	sp,sp,16
    800019f4:	8082                	ret

00000000800019f6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019f6:	1101                	addi	sp,sp,-32
    800019f8:	ec06                	sd	ra,24(sp)
    800019fa:	e822                	sd	s0,16(sp)
    800019fc:	e426                	sd	s1,8(sp)
    800019fe:	1000                	addi	s0,sp,32
  push_off();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	19e080e7          	jalr	414(ra) # 80000b9e <push_off>
    80001a08:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a0a:	2781                	sext.w	a5,a5
    80001a0c:	079e                	slli	a5,a5,0x7
    80001a0e:	0000f717          	auipc	a4,0xf
    80001a12:	39270713          	addi	a4,a4,914 # 80010da0 <pid_lock>
    80001a16:	97ba                	add	a5,a5,a4
    80001a18:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	224080e7          	jalr	548(ra) # 80000c3e <pop_off>
  return p;
}
    80001a22:	8526                	mv	a0,s1
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret

0000000080001a2e <forkret>:
}

// A child'fork s very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e406                	sd	ra,8(sp)
    80001a32:	e022                	sd	s0,0(sp)
    80001a34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a36:	00000097          	auipc	ra,0x0
    80001a3a:	fc0080e7          	jalr	-64(ra) # 800019f6 <myproc>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	260080e7          	jalr	608(ra) # 80000c9e <release>

  if (first)
    80001a46:	00007797          	auipc	a5,0x7
    80001a4a:	f3a7a783          	lw	a5,-198(a5) # 80008980 <first.1735>
    80001a4e:	eb89                	bnez	a5,80001a60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a50:	00001097          	auipc	ra,0x1
    80001a54:	f04080e7          	jalr	-252(ra) # 80002954 <usertrapret>
}
    80001a58:	60a2                	ld	ra,8(sp)
    80001a5a:	6402                	ld	s0,0(sp)
    80001a5c:	0141                	addi	sp,sp,16
    80001a5e:	8082                	ret
    first = 0;
    80001a60:	00007797          	auipc	a5,0x7
    80001a64:	f207a023          	sw	zero,-224(a5) # 80008980 <first.1735>
    fsinit(ROOTDEV);
    80001a68:	4505                	li	a0,1
    80001a6a:	00002097          	auipc	ra,0x2
    80001a6e:	f98080e7          	jalr	-104(ra) # 80003a02 <fsinit>
    80001a72:	bff9                	j	80001a50 <forkret+0x22>

0000000080001a74 <allocpid>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a80:	0000f917          	auipc	s2,0xf
    80001a84:	32090913          	addi	s2,s2,800 # 80010da0 <pid_lock>
    80001a88:	854a                	mv	a0,s2
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	160080e7          	jalr	352(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	ef678793          	addi	a5,a5,-266 # 80008988 <nextpid>
    80001a9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a9c:	0014871b          	addiw	a4,s1,1
    80001aa0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa2:	854a                	mv	a0,s2
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	1fa080e7          	jalr	506(ra) # 80000c9e <release>
}
    80001aac:	8526                	mv	a0,s1
    80001aae:	60e2                	ld	ra,24(sp)
    80001ab0:	6442                	ld	s0,16(sp)
    80001ab2:	64a2                	ld	s1,8(sp)
    80001ab4:	6902                	ld	s2,0(sp)
    80001ab6:	6105                	addi	sp,sp,32
    80001ab8:	8082                	ret

0000000080001aba <proc_pagetable>:
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
    80001ac6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac8:	00000097          	auipc	ra,0x0
    80001acc:	87c080e7          	jalr	-1924(ra) # 80001344 <uvmcreate>
    80001ad0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ad2:	c121                	beqz	a0,80001b12 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad4:	4729                	li	a4,10
    80001ad6:	00005697          	auipc	a3,0x5
    80001ada:	52a68693          	addi	a3,a3,1322 # 80007000 <_trampoline>
    80001ade:	6605                	lui	a2,0x1
    80001ae0:	040005b7          	lui	a1,0x4000
    80001ae4:	15fd                	addi	a1,a1,-1
    80001ae6:	05b2                	slli	a1,a1,0xc
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	5d2080e7          	jalr	1490(ra) # 800010ba <mappages>
    80001af0:	02054863          	bltz	a0,80001b20 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af4:	4719                	li	a4,6
    80001af6:	06093683          	ld	a3,96(s2)
    80001afa:	6605                	lui	a2,0x1
    80001afc:	020005b7          	lui	a1,0x2000
    80001b00:	15fd                	addi	a1,a1,-1
    80001b02:	05b6                	slli	a1,a1,0xd
    80001b04:	8526                	mv	a0,s1
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	5b4080e7          	jalr	1460(ra) # 800010ba <mappages>
    80001b0e:	02054163          	bltz	a0,80001b30 <proc_pagetable+0x76>
}
    80001b12:	8526                	mv	a0,s1
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6902                	ld	s2,0(sp)
    80001b1c:	6105                	addi	sp,sp,32
    80001b1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	a24080e7          	jalr	-1500(ra) # 80001548 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	b7d5                	j	80001b12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	742080e7          	jalr	1858(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b46:	4581                	li	a1,0
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9fe080e7          	jalr	-1538(ra) # 80001548 <uvmfree>
    return 0;
    80001b52:	4481                	li	s1,0
    80001b54:	bf7d                	j	80001b12 <proc_pagetable+0x58>

0000000080001b56 <proc_freepagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
    80001b64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	040005b7          	lui	a1,0x4000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b2                	slli	a1,a1,0xc
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	70e080e7          	jalr	1806(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b7a:	4681                	li	a3,0
    80001b7c:	4605                	li	a2,1
    80001b7e:	020005b7          	lui	a1,0x2000
    80001b82:	15fd                	addi	a1,a1,-1
    80001b84:	05b6                	slli	a1,a1,0xd
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	6f8080e7          	jalr	1784(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b90:	85ca                	mv	a1,s2
    80001b92:	8526                	mv	a0,s1
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	9b4080e7          	jalr	-1612(ra) # 80001548 <uvmfree>
}
    80001b9c:	60e2                	ld	ra,24(sp)
    80001b9e:	6442                	ld	s0,16(sp)
    80001ba0:	64a2                	ld	s1,8(sp)
    80001ba2:	6902                	ld	s2,0(sp)
    80001ba4:	6105                	addi	sp,sp,32
    80001ba6:	8082                	ret

0000000080001ba8 <freeproc>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001bb4:	7128                	ld	a0,96(a0)
    80001bb6:	c509                	beqz	a0,80001bc0 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	e46080e7          	jalr	-442(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001bc0:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001bc4:	6ca8                	ld	a0,88(s1)
    80001bc6:	c511                	beqz	a0,80001bd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc8:	64ac                	ld	a1,72(s1)
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	f8c080e7          	jalr	-116(ra) # 80001b56 <proc_freepagetable>
  p->pagetable = 0;
    80001bd2:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001bd6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bda:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bde:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001be2:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001be6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bea:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bee:	0204a623          	sw	zero,44(s1)
  p->ctime = 0;
    80001bf2:	1604ac23          	sw	zero,376(s1)
  p->state = UNUSED;
    80001bf6:	0004ac23          	sw	zero,24(s1)
}
    80001bfa:	60e2                	ld	ra,24(sp)
    80001bfc:	6442                	ld	s0,16(sp)
    80001bfe:	64a2                	ld	s1,8(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret

0000000080001c04 <allocproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001c10:	0000f497          	auipc	s1,0xf
    80001c14:	5c048493          	addi	s1,s1,1472 # 800111d0 <proc>
    80001c18:	00017917          	auipc	s2,0x17
    80001c1c:	bb890913          	addi	s2,s2,-1096 # 800187d0 <tickslock>
    acquire(&p->lock);
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	fc8080e7          	jalr	-56(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001c2a:	4c9c                	lw	a5,24(s1)
    80001c2c:	cf81                	beqz	a5,80001c44 <allocproc+0x40>
      release(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	06e080e7          	jalr	110(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c38:	1d848493          	addi	s1,s1,472
    80001c3c:	ff2492e3          	bne	s1,s2,80001c20 <allocproc+0x1c>
  return 0;
    80001c40:	4481                	li	s1,0
    80001c42:	a071                	j	80001cce <allocproc+0xca>
  p->pid = allocpid();
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e30080e7          	jalr	-464(ra) # 80001a74 <allocpid>
    80001c4c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c4e:	4785                	li	a5,1
    80001c50:	cc9c                	sw	a5,24(s1)
  p->current_ticks = 0;
    80001c52:	1c04a423          	sw	zero,456(s1)
  p->ctime = ticks;
    80001c56:	00007797          	auipc	a5,0x7
    80001c5a:	eda7a783          	lw	a5,-294(a5) # 80008b30 <ticks>
    80001c5e:	16f4ac23          	sw	a5,376(s1)
  p->end_time = 0;
    80001c62:	1604ae23          	sw	zero,380(s1)
  p->run_time = 0;
    80001c66:	1804b023          	sd	zero,384(s1)
  p->start_time = 0;
    80001c6a:	1804b423          	sd	zero,392(s1)
  p->sleep_time = 0;
    80001c6e:	1804b823          	sd	zero,400(s1)
  p->tickets = 1;
    80001c72:	4785                	li	a5,1
    80001c74:	1af4b423          	sd	a5,424(s1)
  p->n_runs = 0;
    80001c78:	1804bc23          	sd	zero,408(s1)
  p->priority = 60;
    80001c7c:	03c00713          	li	a4,60
    80001c80:	1ae4b023          	sd	a4,416(s1)
  p->handler_permission = 1;
    80001c84:	1cf4a623          	sw	a5,460(s1)
  p->alarm_on = 0;
    80001c88:	1c04a823          	sw	zero,464(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	e6e080e7          	jalr	-402(ra) # 80000afa <kalloc>
    80001c94:	892a                	mv	s2,a0
    80001c96:	f0a8                	sd	a0,96(s1)
    80001c98:	c131                	beqz	a0,80001cdc <allocproc+0xd8>
  p->pagetable = proc_pagetable(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e1e080e7          	jalr	-482(ra) # 80001aba <proc_pagetable>
    80001ca4:	892a                	mv	s2,a0
    80001ca6:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001ca8:	c531                	beqz	a0,80001cf4 <allocproc+0xf0>
  memset(&p->context, 0, sizeof(p->context));
    80001caa:	07000613          	li	a2,112
    80001cae:	4581                	li	a1,0
    80001cb0:	07048513          	addi	a0,s1,112
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	032080e7          	jalr	50(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001cbc:	00000797          	auipc	a5,0x0
    80001cc0:	d7278793          	addi	a5,a5,-654 # 80001a2e <forkret>
    80001cc4:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cc6:	60bc                	ld	a5,64(s1)
    80001cc8:	6705                	lui	a4,0x1
    80001cca:	97ba                	add	a5,a5,a4
    80001ccc:	fcbc                	sd	a5,120(s1)
}
    80001cce:	8526                	mv	a0,s1
    80001cd0:	60e2                	ld	ra,24(sp)
    80001cd2:	6442                	ld	s0,16(sp)
    80001cd4:	64a2                	ld	s1,8(sp)
    80001cd6:	6902                	ld	s2,0(sp)
    80001cd8:	6105                	addi	sp,sp,32
    80001cda:	8082                	ret
    freeproc(p);
    80001cdc:	8526                	mv	a0,s1
    80001cde:	00000097          	auipc	ra,0x0
    80001ce2:	eca080e7          	jalr	-310(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001ce6:	8526                	mv	a0,s1
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	fb6080e7          	jalr	-74(ra) # 80000c9e <release>
    return 0;
    80001cf0:	84ca                	mv	s1,s2
    80001cf2:	bff1                	j	80001cce <allocproc+0xca>
    freeproc(p);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	eb2080e7          	jalr	-334(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	f9e080e7          	jalr	-98(ra) # 80000c9e <release>
    return 0;
    80001d08:	84ca                	mv	s1,s2
    80001d0a:	b7d1                	j	80001cce <allocproc+0xca>

0000000080001d0c <userinit>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	eee080e7          	jalr	-274(ra) # 80001c04 <allocproc>
    80001d1e:	84aa                	mv	s1,a0
  initproc = p;
    80001d20:	00007797          	auipc	a5,0x7
    80001d24:	e0a7b423          	sd	a0,-504(a5) # 80008b28 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d28:	03400613          	li	a2,52
    80001d2c:	00007597          	auipc	a1,0x7
    80001d30:	c6458593          	addi	a1,a1,-924 # 80008990 <initcode>
    80001d34:	6d28                	ld	a0,88(a0)
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	63c080e7          	jalr	1596(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001d3e:	6785                	lui	a5,0x1
    80001d40:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d42:	70b8                	ld	a4,96(s1)
    80001d44:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d48:	70b8                	ld	a4,96(s1)
    80001d4a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d4c:	4641                	li	a2,16
    80001d4e:	00006597          	auipc	a1,0x6
    80001d52:	4b258593          	addi	a1,a1,1202 # 80008200 <digits+0x1c0>
    80001d56:	16848513          	addi	a0,s1,360
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	0de080e7          	jalr	222(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d62:	00006517          	auipc	a0,0x6
    80001d66:	4ae50513          	addi	a0,a0,1198 # 80008210 <digits+0x1d0>
    80001d6a:	00002097          	auipc	ra,0x2
    80001d6e:	6ba080e7          	jalr	1722(ra) # 80004424 <namei>
    80001d72:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    80001d76:	478d                	li	a5,3
    80001d78:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f22080e7          	jalr	-222(ra) # 80000c9e <release>
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <growproc>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
    80001d9a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	c5a080e7          	jalr	-934(ra) # 800019f6 <myproc>
    80001da4:	84aa                	mv	s1,a0
  sz = p->sz;
    80001da6:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001da8:	01204c63          	bgtz	s2,80001dc0 <growproc+0x32>
  else if (n < 0)
    80001dac:	02094663          	bltz	s2,80001dd8 <growproc+0x4a>
  p->sz = sz;
    80001db0:	e4ac                	sd	a1,72(s1)
  return 0;
    80001db2:	4501                	li	a0,0
}
    80001db4:	60e2                	ld	ra,24(sp)
    80001db6:	6442                	ld	s0,16(sp)
    80001db8:	64a2                	ld	s1,8(sp)
    80001dba:	6902                	ld	s2,0(sp)
    80001dbc:	6105                	addi	sp,sp,32
    80001dbe:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001dc0:	4691                	li	a3,4
    80001dc2:	00b90633          	add	a2,s2,a1
    80001dc6:	6d28                	ld	a0,88(a0)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	664080e7          	jalr	1636(ra) # 8000142c <uvmalloc>
    80001dd0:	85aa                	mv	a1,a0
    80001dd2:	fd79                	bnez	a0,80001db0 <growproc+0x22>
      return -1;
    80001dd4:	557d                	li	a0,-1
    80001dd6:	bff9                	j	80001db4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd8:	00b90633          	add	a2,s2,a1
    80001ddc:	6d28                	ld	a0,88(a0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	606080e7          	jalr	1542(ra) # 800013e4 <uvmdealloc>
    80001de6:	85aa                	mv	a1,a0
    80001de8:	b7e1                	j	80001db0 <growproc+0x22>

0000000080001dea <fork>:
{
    80001dea:	7179                	addi	sp,sp,-48
    80001dec:	f406                	sd	ra,40(sp)
    80001dee:	f022                	sd	s0,32(sp)
    80001df0:	ec26                	sd	s1,24(sp)
    80001df2:	e84a                	sd	s2,16(sp)
    80001df4:	e44e                	sd	s3,8(sp)
    80001df6:	e052                	sd	s4,0(sp)
    80001df8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	bfc080e7          	jalr	-1028(ra) # 800019f6 <myproc>
    80001e02:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	e00080e7          	jalr	-512(ra) # 80001c04 <allocproc>
    80001e0c:	12050363          	beqz	a0,80001f32 <fork+0x148>
    80001e10:	89aa                	mv	s3,a0
  np->mask = p->mask;       // Assignment 4
    80001e12:	1c092783          	lw	a5,448(s2)
    80001e16:	1cf52023          	sw	a5,448(a0)
  np->tickets = p->tickets; // Assignment 4
    80001e1a:	1a893783          	ld	a5,424(s2)
    80001e1e:	1af53423          	sd	a5,424(a0)
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e22:	04893603          	ld	a2,72(s2)
    80001e26:	6d2c                	ld	a1,88(a0)
    80001e28:	05893503          	ld	a0,88(s2)
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	754080e7          	jalr	1876(ra) # 80001580 <uvmcopy>
    80001e34:	04054663          	bltz	a0,80001e80 <fork+0x96>
  np->sz = p->sz;
    80001e38:	04893783          	ld	a5,72(s2)
    80001e3c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e40:	06093683          	ld	a3,96(s2)
    80001e44:	87b6                	mv	a5,a3
    80001e46:	0609b703          	ld	a4,96(s3)
    80001e4a:	12068693          	addi	a3,a3,288
    80001e4e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e52:	6788                	ld	a0,8(a5)
    80001e54:	6b8c                	ld	a1,16(a5)
    80001e56:	6f90                	ld	a2,24(a5)
    80001e58:	01073023          	sd	a6,0(a4)
    80001e5c:	e708                	sd	a0,8(a4)
    80001e5e:	eb0c                	sd	a1,16(a4)
    80001e60:	ef10                	sd	a2,24(a4)
    80001e62:	02078793          	addi	a5,a5,32
    80001e66:	02070713          	addi	a4,a4,32
    80001e6a:	fed792e3          	bne	a5,a3,80001e4e <fork+0x64>
  np->trapframe->a0 = 0;
    80001e6e:	0609b783          	ld	a5,96(s3)
    80001e72:	0607b823          	sd	zero,112(a5)
    80001e76:	0e000493          	li	s1,224
  for (i = 0; i < NOFILE; i++)
    80001e7a:	16000a13          	li	s4,352
    80001e7e:	a03d                	j	80001eac <fork+0xc2>
    freeproc(np);
    80001e80:	854e                	mv	a0,s3
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	d26080e7          	jalr	-730(ra) # 80001ba8 <freeproc>
    release(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e12080e7          	jalr	-494(ra) # 80000c9e <release>
    return -1;
    80001e94:	5a7d                	li	s4,-1
    80001e96:	a069                	j	80001f20 <fork+0x136>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e98:	00003097          	auipc	ra,0x3
    80001e9c:	c22080e7          	jalr	-990(ra) # 80004aba <filedup>
    80001ea0:	009987b3          	add	a5,s3,s1
    80001ea4:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001ea6:	04a1                	addi	s1,s1,8
    80001ea8:	01448763          	beq	s1,s4,80001eb6 <fork+0xcc>
    if (p->ofile[i])
    80001eac:	009907b3          	add	a5,s2,s1
    80001eb0:	6388                	ld	a0,0(a5)
    80001eb2:	f17d                	bnez	a0,80001e98 <fork+0xae>
    80001eb4:	bfcd                	j	80001ea6 <fork+0xbc>
  np->cwd = idup(p->cwd);
    80001eb6:	16093503          	ld	a0,352(s2)
    80001eba:	00002097          	auipc	ra,0x2
    80001ebe:	d86080e7          	jalr	-634(ra) # 80003c40 <idup>
    80001ec2:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec6:	4641                	li	a2,16
    80001ec8:	16890593          	addi	a1,s2,360
    80001ecc:	16898513          	addi	a0,s3,360
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	f68080e7          	jalr	-152(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001ed8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001edc:	854e                	mv	a0,s3
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dc0080e7          	jalr	-576(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001ee6:	0000f497          	auipc	s1,0xf
    80001eea:	ed248493          	addi	s1,s1,-302 # 80010db8 <wait_lock>
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	cfa080e7          	jalr	-774(ra) # 80000bea <acquire>
  np->parent = p;
    80001ef8:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	da0080e7          	jalr	-608(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	ce2080e7          	jalr	-798(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001f10:	478d                	li	a5,3
    80001f12:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f16:	854e                	mv	a0,s3
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d86080e7          	jalr	-634(ra) # 80000c9e <release>
}
    80001f20:	8552                	mv	a0,s4
    80001f22:	70a2                	ld	ra,40(sp)
    80001f24:	7402                	ld	s0,32(sp)
    80001f26:	64e2                	ld	s1,24(sp)
    80001f28:	6942                	ld	s2,16(sp)
    80001f2a:	69a2                	ld	s3,8(sp)
    80001f2c:	6a02                	ld	s4,0(sp)
    80001f2e:	6145                	addi	sp,sp,48
    80001f30:	8082                	ret
    return -1;
    80001f32:	5a7d                	li	s4,-1
    80001f34:	b7f5                	j	80001f20 <fork+0x136>

0000000080001f36 <update_time>:
{
    80001f36:	7179                	addi	sp,sp,-48
    80001f38:	f406                	sd	ra,40(sp)
    80001f3a:	f022                	sd	s0,32(sp)
    80001f3c:	ec26                	sd	s1,24(sp)
    80001f3e:	e84a                	sd	s2,16(sp)
    80001f40:	e44e                	sd	s3,8(sp)
    80001f42:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001f44:	0000f497          	auipc	s1,0xf
    80001f48:	28c48493          	addi	s1,s1,652 # 800111d0 <proc>
    if (p->state == RUNNING)
    80001f4c:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80001f4e:	00017917          	auipc	s2,0x17
    80001f52:	88290913          	addi	s2,s2,-1918 # 800187d0 <tickslock>
    80001f56:	a811                	j	80001f6a <update_time+0x34>
    release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d44080e7          	jalr	-700(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f62:	1d848493          	addi	s1,s1,472
    80001f66:	03248063          	beq	s1,s2,80001f86 <update_time+0x50>
    acquire(&p->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	c7e080e7          	jalr	-898(ra) # 80000bea <acquire>
    if (p->state == RUNNING)
    80001f74:	4c9c                	lw	a5,24(s1)
    80001f76:	ff3791e3          	bne	a5,s3,80001f58 <update_time+0x22>
      p->run_time++;
    80001f7a:	1804b783          	ld	a5,384(s1)
    80001f7e:	0785                	addi	a5,a5,1
    80001f80:	18f4b023          	sd	a5,384(s1)
    80001f84:	bfd1                	j	80001f58 <update_time+0x22>
}
    80001f86:	70a2                	ld	ra,40(sp)
    80001f88:	7402                	ld	s0,32(sp)
    80001f8a:	64e2                	ld	s1,24(sp)
    80001f8c:	6942                	ld	s2,16(sp)
    80001f8e:	69a2                	ld	s3,8(sp)
    80001f90:	6145                	addi	sp,sp,48
    80001f92:	8082                	ret

0000000080001f94 <roundRobin>:
{
    80001f94:	7139                	addi	sp,sp,-64
    80001f96:	fc06                	sd	ra,56(sp)
    80001f98:	f822                	sd	s0,48(sp)
    80001f9a:	f426                	sd	s1,40(sp)
    80001f9c:	f04a                	sd	s2,32(sp)
    80001f9e:	ec4e                	sd	s3,24(sp)
    80001fa0:	e852                	sd	s4,16(sp)
    80001fa2:	e456                	sd	s5,8(sp)
    80001fa4:	e05a                	sd	s6,0(sp)
    80001fa6:	0080                	addi	s0,sp,64
    80001fa8:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    80001faa:	0000f497          	auipc	s1,0xf
    80001fae:	22648493          	addi	s1,s1,550 # 800111d0 <proc>
    if (p->state == RUNNABLE)
    80001fb2:	498d                	li	s3,3
      p->state = RUNNING;
    80001fb4:	4b11                	li	s6,4
      swtch(&c->context, &p->context);
    80001fb6:	00850a93          	addi	s5,a0,8
  for (p = proc; p < &proc[NPROC]; p++)
    80001fba:	00017917          	auipc	s2,0x17
    80001fbe:	81690913          	addi	s2,s2,-2026 # 800187d0 <tickslock>
    80001fc2:	a03d                	j	80001ff0 <roundRobin+0x5c>
      p->state = RUNNING;
    80001fc4:	0164ac23          	sw	s6,24(s1)
      c->proc = p;
    80001fc8:	009a3023          	sd	s1,0(s4)
      swtch(&c->context, &p->context);
    80001fcc:	07048593          	addi	a1,s1,112
    80001fd0:	8556                	mv	a0,s5
    80001fd2:	00001097          	auipc	ra,0x1
    80001fd6:	8d8080e7          	jalr	-1832(ra) # 800028aa <swtch>
      c->proc = 0;
    80001fda:	000a3023          	sd	zero,0(s4)
    release(&p->lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	cbe080e7          	jalr	-834(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001fe8:	1d848493          	addi	s1,s1,472
    80001fec:	01248b63          	beq	s1,s2,80002002 <roundRobin+0x6e>
    acquire(&p->lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	bf8080e7          	jalr	-1032(ra) # 80000bea <acquire>
    if (p->state == RUNNABLE)
    80001ffa:	4c9c                	lw	a5,24(s1)
    80001ffc:	ff3791e3          	bne	a5,s3,80001fde <roundRobin+0x4a>
    80002000:	b7d1                	j	80001fc4 <roundRobin+0x30>
}
    80002002:	70e2                	ld	ra,56(sp)
    80002004:	7442                	ld	s0,48(sp)
    80002006:	74a2                	ld	s1,40(sp)
    80002008:	7902                	ld	s2,32(sp)
    8000200a:	69e2                	ld	s3,24(sp)
    8000200c:	6a42                	ld	s4,16(sp)
    8000200e:	6aa2                	ld	s5,8(sp)
    80002010:	6b02                	ld	s6,0(sp)
    80002012:	6121                	addi	sp,sp,64
    80002014:	8082                	ret

0000000080002016 <scheduler>:
{
    80002016:	1101                	addi	sp,sp,-32
    80002018:	ec06                	sd	ra,24(sp)
    8000201a:	e822                	sd	s0,16(sp)
    8000201c:	e426                	sd	s1,8(sp)
    8000201e:	1000                	addi	s0,sp,32
    80002020:	8792                	mv	a5,tp
  int id = r_tp();
    80002022:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    80002024:	079e                	slli	a5,a5,0x7
    80002026:	0000f497          	auipc	s1,0xf
    8000202a:	daa48493          	addi	s1,s1,-598 # 80010dd0 <cpus>
    8000202e:	94be                	add	s1,s1,a5
  c->proc = 0;
    80002030:	0000f717          	auipc	a4,0xf
    80002034:	d7070713          	addi	a4,a4,-656 # 80010da0 <pid_lock>
    80002038:	97ba                	add	a5,a5,a4
    8000203a:	0207b823          	sd	zero,48(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002042:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002046:	10079073          	csrw	sstatus,a5
    roundRobin(c);
    8000204a:	8526                	mv	a0,s1
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	f48080e7          	jalr	-184(ra) # 80001f94 <roundRobin>
  for (;;)
    80002054:	b7ed                	j	8000203e <scheduler+0x28>

0000000080002056 <sched>:
{
    80002056:	7179                	addi	sp,sp,-48
    80002058:	f406                	sd	ra,40(sp)
    8000205a:	f022                	sd	s0,32(sp)
    8000205c:	ec26                	sd	s1,24(sp)
    8000205e:	e84a                	sd	s2,16(sp)
    80002060:	e44e                	sd	s3,8(sp)
    80002062:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002064:	00000097          	auipc	ra,0x0
    80002068:	992080e7          	jalr	-1646(ra) # 800019f6 <myproc>
    8000206c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	b02080e7          	jalr	-1278(ra) # 80000b70 <holding>
    80002076:	c93d                	beqz	a0,800020ec <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002078:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	0000f717          	auipc	a4,0xf
    80002082:	d2270713          	addi	a4,a4,-734 # 80010da0 <pid_lock>
    80002086:	97ba                	add	a5,a5,a4
    80002088:	0a87a703          	lw	a4,168(a5)
    8000208c:	4785                	li	a5,1
    8000208e:	06f71763          	bne	a4,a5,800020fc <sched+0xa6>
  if (p->state == RUNNING)
    80002092:	4c98                	lw	a4,24(s1)
    80002094:	4791                	li	a5,4
    80002096:	06f70b63          	beq	a4,a5,8000210c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000209a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000209e:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020a0:	efb5                	bnez	a5,8000211c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020a2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020a4:	0000f917          	auipc	s2,0xf
    800020a8:	cfc90913          	addi	s2,s2,-772 # 80010da0 <pid_lock>
    800020ac:	2781                	sext.w	a5,a5
    800020ae:	079e                	slli	a5,a5,0x7
    800020b0:	97ca                	add	a5,a5,s2
    800020b2:	0ac7a983          	lw	s3,172(a5)
    800020b6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b8:	2781                	sext.w	a5,a5
    800020ba:	079e                	slli	a5,a5,0x7
    800020bc:	0000f597          	auipc	a1,0xf
    800020c0:	d1c58593          	addi	a1,a1,-740 # 80010dd8 <cpus+0x8>
    800020c4:	95be                	add	a1,a1,a5
    800020c6:	07048513          	addi	a0,s1,112
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	7e0080e7          	jalr	2016(ra) # 800028aa <swtch>
    800020d2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020d4:	2781                	sext.w	a5,a5
    800020d6:	079e                	slli	a5,a5,0x7
    800020d8:	97ca                	add	a5,a5,s2
    800020da:	0b37a623          	sw	s3,172(a5)
}
    800020de:	70a2                	ld	ra,40(sp)
    800020e0:	7402                	ld	s0,32(sp)
    800020e2:	64e2                	ld	s1,24(sp)
    800020e4:	6942                	ld	s2,16(sp)
    800020e6:	69a2                	ld	s3,8(sp)
    800020e8:	6145                	addi	sp,sp,48
    800020ea:	8082                	ret
    panic("sched p->lock");
    800020ec:	00006517          	auipc	a0,0x6
    800020f0:	12c50513          	addi	a0,a0,300 # 80008218 <digits+0x1d8>
    800020f4:	ffffe097          	auipc	ra,0xffffe
    800020f8:	450080e7          	jalr	1104(ra) # 80000544 <panic>
    panic("sched locks");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	12c50513          	addi	a0,a0,300 # 80008228 <digits+0x1e8>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	440080e7          	jalr	1088(ra) # 80000544 <panic>
    panic("sched running");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	12c50513          	addi	a0,a0,300 # 80008238 <digits+0x1f8>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	430080e7          	jalr	1072(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	12c50513          	addi	a0,a0,300 # 80008248 <digits+0x208>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	420080e7          	jalr	1056(ra) # 80000544 <panic>

000000008000212c <yield>:
{
    8000212c:	1101                	addi	sp,sp,-32
    8000212e:	ec06                	sd	ra,24(sp)
    80002130:	e822                	sd	s0,16(sp)
    80002132:	e426                	sd	s1,8(sp)
    80002134:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	8c0080e7          	jalr	-1856(ra) # 800019f6 <myproc>
    8000213e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	aaa080e7          	jalr	-1366(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002148:	478d                	li	a5,3
    8000214a:	cc9c                	sw	a5,24(s1)
  sched();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	f0a080e7          	jalr	-246(ra) # 80002056 <sched>
  release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b48080e7          	jalr	-1208(ra) # 80000c9e <release>
}
    8000215e:	60e2                	ld	ra,24(sp)
    80002160:	6442                	ld	s0,16(sp)
    80002162:	64a2                	ld	s1,8(sp)
    80002164:	6105                	addi	sp,sp,32
    80002166:	8082                	ret

0000000080002168 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	1800                	addi	s0,sp,48
    80002176:	89aa                	mv	s3,a0
    80002178:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	87c080e7          	jalr	-1924(ra) # 800019f6 <myproc>
    80002182:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	a66080e7          	jalr	-1434(ra) # 80000bea <acquire>
  release(lk);
    8000218c:	854a                	mv	a0,s2
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	b10080e7          	jalr	-1264(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002196:	0334b023          	sd	s3,32(s1)
#ifdef MLFQ
  p->ticks_in_current_slice = 0;
#endif
  p->state = SLEEPING;
    8000219a:	4789                	li	a5,2
    8000219c:	cc9c                	sw	a5,24(s1)

  sched();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	eb8080e7          	jalr	-328(ra) # 80002056 <sched>

  // Tidy up.
  p->chan = 0;
    800021a6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	af2080e7          	jalr	-1294(ra) # 80000c9e <release>
  acquire(lk);
    800021b4:	854a                	mv	a0,s2
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	a34080e7          	jalr	-1484(ra) # 80000bea <acquire>
}
    800021be:	70a2                	ld	ra,40(sp)
    800021c0:	7402                	ld	s0,32(sp)
    800021c2:	64e2                	ld	s1,24(sp)
    800021c4:	6942                	ld	s2,16(sp)
    800021c6:	69a2                	ld	s3,8(sp)
    800021c8:	6145                	addi	sp,sp,48
    800021ca:	8082                	ret

00000000800021cc <waitx>:
{
    800021cc:	711d                	addi	sp,sp,-96
    800021ce:	ec86                	sd	ra,88(sp)
    800021d0:	e8a2                	sd	s0,80(sp)
    800021d2:	e4a6                	sd	s1,72(sp)
    800021d4:	e0ca                	sd	s2,64(sp)
    800021d6:	fc4e                	sd	s3,56(sp)
    800021d8:	f852                	sd	s4,48(sp)
    800021da:	f456                	sd	s5,40(sp)
    800021dc:	f05a                	sd	s6,32(sp)
    800021de:	ec5e                	sd	s7,24(sp)
    800021e0:	e862                	sd	s8,16(sp)
    800021e2:	e466                	sd	s9,8(sp)
    800021e4:	e06a                	sd	s10,0(sp)
    800021e6:	1080                	addi	s0,sp,96
    800021e8:	8b2a                	mv	s6,a0
    800021ea:	8bae                	mv	s7,a1
    800021ec:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	808080e7          	jalr	-2040(ra) # 800019f6 <myproc>
    800021f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021f8:	0000f517          	auipc	a0,0xf
    800021fc:	bc050513          	addi	a0,a0,-1088 # 80010db8 <wait_lock>
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	9ea080e7          	jalr	-1558(ra) # 80000bea <acquire>
    havekids = 0;
    80002208:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000220a:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000220c:	00016997          	auipc	s3,0x16
    80002210:	5c498993          	addi	s3,s3,1476 # 800187d0 <tickslock>
        havekids = 1;
    80002214:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002216:	0000fd17          	auipc	s10,0xf
    8000221a:	ba2d0d13          	addi	s10,s10,-1118 # 80010db8 <wait_lock>
    havekids = 0;
    8000221e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002220:	0000f497          	auipc	s1,0xf
    80002224:	fb048493          	addi	s1,s1,-80 # 800111d0 <proc>
    80002228:	a069                	j	800022b2 <waitx+0xe6>
          pid = np->pid;
    8000222a:	0304a983          	lw	s3,48(s1)
          *rtime = np->run_time;
    8000222e:	1804b783          	ld	a5,384(s1)
    80002232:	00fc2023          	sw	a5,0(s8)
          *wtime = np->end_time - np->ctime - np->run_time;
    80002236:	17c4a783          	lw	a5,380(s1)
    8000223a:	1784a703          	lw	a4,376(s1)
    8000223e:	9f99                	subw	a5,a5,a4
    80002240:	1804b703          	ld	a4,384(s1)
    80002244:	9f99                	subw	a5,a5,a4
    80002246:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffdb450>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000224a:	000b0e63          	beqz	s6,80002266 <waitx+0x9a>
    8000224e:	4691                	li	a3,4
    80002250:	02c48613          	addi	a2,s1,44
    80002254:	85da                	mv	a1,s6
    80002256:	05893503          	ld	a0,88(s2)
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	42a080e7          	jalr	1066(ra) # 80001684 <copyout>
    80002262:	02054563          	bltz	a0,8000228c <waitx+0xc0>
          freeproc(np);
    80002266:	8526                	mv	a0,s1
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	940080e7          	jalr	-1728(ra) # 80001ba8 <freeproc>
          release(&np->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a2c080e7          	jalr	-1492(ra) # 80000c9e <release>
          release(&wait_lock);
    8000227a:	0000f517          	auipc	a0,0xf
    8000227e:	b3e50513          	addi	a0,a0,-1218 # 80010db8 <wait_lock>
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a1c080e7          	jalr	-1508(ra) # 80000c9e <release>
          return pid;
    8000228a:	a09d                	j	800022f0 <waitx+0x124>
            release(&np->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a10080e7          	jalr	-1520(ra) # 80000c9e <release>
            release(&wait_lock);
    80002296:	0000f517          	auipc	a0,0xf
    8000229a:	b2250513          	addi	a0,a0,-1246 # 80010db8 <wait_lock>
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	a00080e7          	jalr	-1536(ra) # 80000c9e <release>
            return -1;
    800022a6:	59fd                	li	s3,-1
    800022a8:	a0a1                	j	800022f0 <waitx+0x124>
    for (np = proc; np < &proc[NPROC]; np++)
    800022aa:	1d848493          	addi	s1,s1,472
    800022ae:	03348463          	beq	s1,s3,800022d6 <waitx+0x10a>
      if (np->parent == p)
    800022b2:	7c9c                	ld	a5,56(s1)
    800022b4:	ff279be3          	bne	a5,s2,800022aa <waitx+0xde>
        acquire(&np->lock);
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	930080e7          	jalr	-1744(ra) # 80000bea <acquire>
        if (np->state == ZOMBIE)
    800022c2:	4c9c                	lw	a5,24(s1)
    800022c4:	f74783e3          	beq	a5,s4,8000222a <waitx+0x5e>
        release(&np->lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9d4080e7          	jalr	-1580(ra) # 80000c9e <release>
        havekids = 1;
    800022d2:	8756                	mv	a4,s5
    800022d4:	bfd9                	j	800022aa <waitx+0xde>
    if (!havekids || p->killed)
    800022d6:	c701                	beqz	a4,800022de <waitx+0x112>
    800022d8:	02892783          	lw	a5,40(s2)
    800022dc:	cb8d                	beqz	a5,8000230e <waitx+0x142>
      release(&wait_lock);
    800022de:	0000f517          	auipc	a0,0xf
    800022e2:	ada50513          	addi	a0,a0,-1318 # 80010db8 <wait_lock>
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9b8080e7          	jalr	-1608(ra) # 80000c9e <release>
      return -1;
    800022ee:	59fd                	li	s3,-1
}
    800022f0:	854e                	mv	a0,s3
    800022f2:	60e6                	ld	ra,88(sp)
    800022f4:	6446                	ld	s0,80(sp)
    800022f6:	64a6                	ld	s1,72(sp)
    800022f8:	6906                	ld	s2,64(sp)
    800022fa:	79e2                	ld	s3,56(sp)
    800022fc:	7a42                	ld	s4,48(sp)
    800022fe:	7aa2                	ld	s5,40(sp)
    80002300:	7b02                	ld	s6,32(sp)
    80002302:	6be2                	ld	s7,24(sp)
    80002304:	6c42                	ld	s8,16(sp)
    80002306:	6ca2                	ld	s9,8(sp)
    80002308:	6d02                	ld	s10,0(sp)
    8000230a:	6125                	addi	sp,sp,96
    8000230c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000230e:	85ea                	mv	a1,s10
    80002310:	854a                	mv	a0,s2
    80002312:	00000097          	auipc	ra,0x0
    80002316:	e56080e7          	jalr	-426(ra) # 80002168 <sleep>
    havekids = 0;
    8000231a:	b711                	j	8000221e <waitx+0x52>

000000008000231c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000231c:	7139                	addi	sp,sp,-64
    8000231e:	fc06                	sd	ra,56(sp)
    80002320:	f822                	sd	s0,48(sp)
    80002322:	f426                	sd	s1,40(sp)
    80002324:	f04a                	sd	s2,32(sp)
    80002326:	ec4e                	sd	s3,24(sp)
    80002328:	e852                	sd	s4,16(sp)
    8000232a:	e456                	sd	s5,8(sp)
    8000232c:	0080                	addi	s0,sp,64
    8000232e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002330:	0000f497          	auipc	s1,0xf
    80002334:	ea048493          	addi	s1,s1,-352 # 800111d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002338:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000233a:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000233c:	00016917          	auipc	s2,0x16
    80002340:	49490913          	addi	s2,s2,1172 # 800187d0 <tickslock>
    80002344:	a821                	j	8000235c <wakeup+0x40>
        p->state = RUNNABLE;
    80002346:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	952080e7          	jalr	-1710(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002354:	1d848493          	addi	s1,s1,472
    80002358:	03248463          	beq	s1,s2,80002380 <wakeup+0x64>
    if (p != myproc())
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	69a080e7          	jalr	1690(ra) # 800019f6 <myproc>
    80002364:	fea488e3          	beq	s1,a0,80002354 <wakeup+0x38>
      acquire(&p->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	880080e7          	jalr	-1920(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002372:	4c9c                	lw	a5,24(s1)
    80002374:	fd379be3          	bne	a5,s3,8000234a <wakeup+0x2e>
    80002378:	709c                	ld	a5,32(s1)
    8000237a:	fd4798e3          	bne	a5,s4,8000234a <wakeup+0x2e>
    8000237e:	b7e1                	j	80002346 <wakeup+0x2a>
    }
  }
}
    80002380:	70e2                	ld	ra,56(sp)
    80002382:	7442                	ld	s0,48(sp)
    80002384:	74a2                	ld	s1,40(sp)
    80002386:	7902                	ld	s2,32(sp)
    80002388:	69e2                	ld	s3,24(sp)
    8000238a:	6a42                	ld	s4,16(sp)
    8000238c:	6aa2                	ld	s5,8(sp)
    8000238e:	6121                	addi	sp,sp,64
    80002390:	8082                	ret

0000000080002392 <reparent>:
{
    80002392:	7179                	addi	sp,sp,-48
    80002394:	f406                	sd	ra,40(sp)
    80002396:	f022                	sd	s0,32(sp)
    80002398:	ec26                	sd	s1,24(sp)
    8000239a:	e84a                	sd	s2,16(sp)
    8000239c:	e44e                	sd	s3,8(sp)
    8000239e:	e052                	sd	s4,0(sp)
    800023a0:	1800                	addi	s0,sp,48
    800023a2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023a4:	0000f497          	auipc	s1,0xf
    800023a8:	e2c48493          	addi	s1,s1,-468 # 800111d0 <proc>
      pp->parent = initproc;
    800023ac:	00006a17          	auipc	s4,0x6
    800023b0:	77ca0a13          	addi	s4,s4,1916 # 80008b28 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b4:	00016997          	auipc	s3,0x16
    800023b8:	41c98993          	addi	s3,s3,1052 # 800187d0 <tickslock>
    800023bc:	a029                	j	800023c6 <reparent+0x34>
    800023be:	1d848493          	addi	s1,s1,472
    800023c2:	01348d63          	beq	s1,s3,800023dc <reparent+0x4a>
    if (pp->parent == p)
    800023c6:	7c9c                	ld	a5,56(s1)
    800023c8:	ff279be3          	bne	a5,s2,800023be <reparent+0x2c>
      pp->parent = initproc;
    800023cc:	000a3503          	ld	a0,0(s4)
    800023d0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	f4a080e7          	jalr	-182(ra) # 8000231c <wakeup>
    800023da:	b7d5                	j	800023be <reparent+0x2c>
}
    800023dc:	70a2                	ld	ra,40(sp)
    800023de:	7402                	ld	s0,32(sp)
    800023e0:	64e2                	ld	s1,24(sp)
    800023e2:	6942                	ld	s2,16(sp)
    800023e4:	69a2                	ld	s3,8(sp)
    800023e6:	6a02                	ld	s4,0(sp)
    800023e8:	6145                	addi	sp,sp,48
    800023ea:	8082                	ret

00000000800023ec <exit>:
{
    800023ec:	7179                	addi	sp,sp,-48
    800023ee:	f406                	sd	ra,40(sp)
    800023f0:	f022                	sd	s0,32(sp)
    800023f2:	ec26                	sd	s1,24(sp)
    800023f4:	e84a                	sd	s2,16(sp)
    800023f6:	e44e                	sd	s3,8(sp)
    800023f8:	e052                	sd	s4,0(sp)
    800023fa:	1800                	addi	s0,sp,48
    800023fc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	5f8080e7          	jalr	1528(ra) # 800019f6 <myproc>
    80002406:	89aa                	mv	s3,a0
  if (p == initproc)
    80002408:	00006797          	auipc	a5,0x6
    8000240c:	7207b783          	ld	a5,1824(a5) # 80008b28 <initproc>
    80002410:	0e050493          	addi	s1,a0,224
    80002414:	16050913          	addi	s2,a0,352
    80002418:	02a79363          	bne	a5,a0,8000243e <exit+0x52>
    panic("init exiting");
    8000241c:	00006517          	auipc	a0,0x6
    80002420:	e4450513          	addi	a0,a0,-444 # 80008260 <digits+0x220>
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	120080e7          	jalr	288(ra) # 80000544 <panic>
      fileclose(f);
    8000242c:	00002097          	auipc	ra,0x2
    80002430:	6e0080e7          	jalr	1760(ra) # 80004b0c <fileclose>
      p->ofile[fd] = 0;
    80002434:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002438:	04a1                	addi	s1,s1,8
    8000243a:	01248563          	beq	s1,s2,80002444 <exit+0x58>
    if (p->ofile[fd])
    8000243e:	6088                	ld	a0,0(s1)
    80002440:	f575                	bnez	a0,8000242c <exit+0x40>
    80002442:	bfdd                	j	80002438 <exit+0x4c>
  begin_op();
    80002444:	00002097          	auipc	ra,0x2
    80002448:	1fc080e7          	jalr	508(ra) # 80004640 <begin_op>
  iput(p->cwd);
    8000244c:	1609b503          	ld	a0,352(s3)
    80002450:	00002097          	auipc	ra,0x2
    80002454:	9e8080e7          	jalr	-1560(ra) # 80003e38 <iput>
  end_op();
    80002458:	00002097          	auipc	ra,0x2
    8000245c:	268080e7          	jalr	616(ra) # 800046c0 <end_op>
  p->cwd = 0;
    80002460:	1609b023          	sd	zero,352(s3)
  acquire(&wait_lock);
    80002464:	0000f497          	auipc	s1,0xf
    80002468:	95448493          	addi	s1,s1,-1708 # 80010db8 <wait_lock>
    8000246c:	8526                	mv	a0,s1
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	77c080e7          	jalr	1916(ra) # 80000bea <acquire>
  reparent(p);
    80002476:	854e                	mv	a0,s3
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	f1a080e7          	jalr	-230(ra) # 80002392 <reparent>
  wakeup(p->parent);
    80002480:	0389b503          	ld	a0,56(s3)
    80002484:	00000097          	auipc	ra,0x0
    80002488:	e98080e7          	jalr	-360(ra) # 8000231c <wakeup>
  acquire(&p->lock);
    8000248c:	854e                	mv	a0,s3
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	75c080e7          	jalr	1884(ra) # 80000bea <acquire>
  p->xstate = status;
    80002496:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000249a:	4795                	li	a5,5
    8000249c:	00f9ac23          	sw	a5,24(s3)
  p->end_time = ticks;
    800024a0:	00006797          	auipc	a5,0x6
    800024a4:	6907a783          	lw	a5,1680(a5) # 80008b30 <ticks>
    800024a8:	16f9ae23          	sw	a5,380(s3)
  release(&wait_lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7f0080e7          	jalr	2032(ra) # 80000c9e <release>
  sched();
    800024b6:	00000097          	auipc	ra,0x0
    800024ba:	ba0080e7          	jalr	-1120(ra) # 80002056 <sched>
  panic("zombie exit");
    800024be:	00006517          	auipc	a0,0x6
    800024c2:	db250513          	addi	a0,a0,-590 # 80008270 <digits+0x230>
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	07e080e7          	jalr	126(ra) # 80000544 <panic>

00000000800024ce <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024ce:	7179                	addi	sp,sp,-48
    800024d0:	f406                	sd	ra,40(sp)
    800024d2:	f022                	sd	s0,32(sp)
    800024d4:	ec26                	sd	s1,24(sp)
    800024d6:	e84a                	sd	s2,16(sp)
    800024d8:	e44e                	sd	s3,8(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800024de:	0000f497          	auipc	s1,0xf
    800024e2:	cf248493          	addi	s1,s1,-782 # 800111d0 <proc>
    800024e6:	00016997          	auipc	s3,0x16
    800024ea:	2ea98993          	addi	s3,s3,746 # 800187d0 <tickslock>
  {
    acquire(&p->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	6fa080e7          	jalr	1786(ra) # 80000bea <acquire>
    if (p->pid == pid)
    800024f8:	589c                	lw	a5,48(s1)
    800024fa:	01278d63          	beq	a5,s2,80002514 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	79e080e7          	jalr	1950(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002508:	1d848493          	addi	s1,s1,472
    8000250c:	ff3491e3          	bne	s1,s3,800024ee <kill+0x20>
  }
  return -1;
    80002510:	557d                	li	a0,-1
    80002512:	a829                	j	8000252c <kill+0x5e>
      p->killed = 1;
    80002514:	4785                	li	a5,1
    80002516:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002518:	4c98                	lw	a4,24(s1)
    8000251a:	4789                	li	a5,2
    8000251c:	00f70f63          	beq	a4,a5,8000253a <kill+0x6c>
      release(&p->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	77c080e7          	jalr	1916(ra) # 80000c9e <release>
      return 0;
    8000252a:	4501                	li	a0,0
}
    8000252c:	70a2                	ld	ra,40(sp)
    8000252e:	7402                	ld	s0,32(sp)
    80002530:	64e2                	ld	s1,24(sp)
    80002532:	6942                	ld	s2,16(sp)
    80002534:	69a2                	ld	s3,8(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
        p->state = RUNNABLE;
    8000253a:	478d                	li	a5,3
    8000253c:	cc9c                	sw	a5,24(s1)
    8000253e:	b7cd                	j	80002520 <kill+0x52>

0000000080002540 <setkilled>:

void setkilled(struct proc *p)
{
    80002540:	1101                	addi	sp,sp,-32
    80002542:	ec06                	sd	ra,24(sp)
    80002544:	e822                	sd	s0,16(sp)
    80002546:	e426                	sd	s1,8(sp)
    80002548:	1000                	addi	s0,sp,32
    8000254a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	69e080e7          	jalr	1694(ra) # 80000bea <acquire>
  p->killed = 1;
    80002554:	4785                	li	a5,1
    80002556:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	744080e7          	jalr	1860(ra) # 80000c9e <release>
}
    80002562:	60e2                	ld	ra,24(sp)
    80002564:	6442                	ld	s0,16(sp)
    80002566:	64a2                	ld	s1,8(sp)
    80002568:	6105                	addi	sp,sp,32
    8000256a:	8082                	ret

000000008000256c <killed>:

int killed(struct proc *p)
{
    8000256c:	1101                	addi	sp,sp,-32
    8000256e:	ec06                	sd	ra,24(sp)
    80002570:	e822                	sd	s0,16(sp)
    80002572:	e426                	sd	s1,8(sp)
    80002574:	e04a                	sd	s2,0(sp)
    80002576:	1000                	addi	s0,sp,32
    80002578:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	670080e7          	jalr	1648(ra) # 80000bea <acquire>
  k = p->killed;
    80002582:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	716080e7          	jalr	1814(ra) # 80000c9e <release>
  return k;
}
    80002590:	854a                	mv	a0,s2
    80002592:	60e2                	ld	ra,24(sp)
    80002594:	6442                	ld	s0,16(sp)
    80002596:	64a2                	ld	s1,8(sp)
    80002598:	6902                	ld	s2,0(sp)
    8000259a:	6105                	addi	sp,sp,32
    8000259c:	8082                	ret

000000008000259e <wait>:
{
    8000259e:	715d                	addi	sp,sp,-80
    800025a0:	e486                	sd	ra,72(sp)
    800025a2:	e0a2                	sd	s0,64(sp)
    800025a4:	fc26                	sd	s1,56(sp)
    800025a6:	f84a                	sd	s2,48(sp)
    800025a8:	f44e                	sd	s3,40(sp)
    800025aa:	f052                	sd	s4,32(sp)
    800025ac:	ec56                	sd	s5,24(sp)
    800025ae:	e85a                	sd	s6,16(sp)
    800025b0:	e45e                	sd	s7,8(sp)
    800025b2:	e062                	sd	s8,0(sp)
    800025b4:	0880                	addi	s0,sp,80
    800025b6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025b8:	fffff097          	auipc	ra,0xfffff
    800025bc:	43e080e7          	jalr	1086(ra) # 800019f6 <myproc>
    800025c0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025c2:	0000e517          	auipc	a0,0xe
    800025c6:	7f650513          	addi	a0,a0,2038 # 80010db8 <wait_lock>
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	620080e7          	jalr	1568(ra) # 80000bea <acquire>
    havekids = 0;
    800025d2:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800025d4:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025d6:	00016997          	auipc	s3,0x16
    800025da:	1fa98993          	addi	s3,s3,506 # 800187d0 <tickslock>
        havekids = 1;
    800025de:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025e0:	0000ec17          	auipc	s8,0xe
    800025e4:	7d8c0c13          	addi	s8,s8,2008 # 80010db8 <wait_lock>
    havekids = 0;
    800025e8:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ea:	0000f497          	auipc	s1,0xf
    800025ee:	be648493          	addi	s1,s1,-1050 # 800111d0 <proc>
    800025f2:	a0bd                	j	80002660 <wait+0xc2>
          pid = pp->pid;
    800025f4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800025f8:	000b0e63          	beqz	s6,80002614 <wait+0x76>
    800025fc:	4691                	li	a3,4
    800025fe:	02c48613          	addi	a2,s1,44
    80002602:	85da                	mv	a1,s6
    80002604:	05893503          	ld	a0,88(s2)
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	07c080e7          	jalr	124(ra) # 80001684 <copyout>
    80002610:	02054563          	bltz	a0,8000263a <wait+0x9c>
          freeproc(pp);
    80002614:	8526                	mv	a0,s1
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	592080e7          	jalr	1426(ra) # 80001ba8 <freeproc>
          release(&pp->lock);
    8000261e:	8526                	mv	a0,s1
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	67e080e7          	jalr	1662(ra) # 80000c9e <release>
          release(&wait_lock);
    80002628:	0000e517          	auipc	a0,0xe
    8000262c:	79050513          	addi	a0,a0,1936 # 80010db8 <wait_lock>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	66e080e7          	jalr	1646(ra) # 80000c9e <release>
          return pid;
    80002638:	a0b5                	j	800026a4 <wait+0x106>
            release(&pp->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	662080e7          	jalr	1634(ra) # 80000c9e <release>
            release(&wait_lock);
    80002644:	0000e517          	auipc	a0,0xe
    80002648:	77450513          	addi	a0,a0,1908 # 80010db8 <wait_lock>
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	652080e7          	jalr	1618(ra) # 80000c9e <release>
            return -1;
    80002654:	59fd                	li	s3,-1
    80002656:	a0b9                	j	800026a4 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002658:	1d848493          	addi	s1,s1,472
    8000265c:	03348463          	beq	s1,s3,80002684 <wait+0xe6>
      if (pp->parent == p)
    80002660:	7c9c                	ld	a5,56(s1)
    80002662:	ff279be3          	bne	a5,s2,80002658 <wait+0xba>
        acquire(&pp->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	582080e7          	jalr	1410(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    80002670:	4c9c                	lw	a5,24(s1)
    80002672:	f94781e3          	beq	a5,s4,800025f4 <wait+0x56>
        release(&pp->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	626080e7          	jalr	1574(ra) # 80000c9e <release>
        havekids = 1;
    80002680:	8756                	mv	a4,s5
    80002682:	bfd9                	j	80002658 <wait+0xba>
    if (!havekids || killed(p))
    80002684:	c719                	beqz	a4,80002692 <wait+0xf4>
    80002686:	854a                	mv	a0,s2
    80002688:	00000097          	auipc	ra,0x0
    8000268c:	ee4080e7          	jalr	-284(ra) # 8000256c <killed>
    80002690:	c51d                	beqz	a0,800026be <wait+0x120>
      release(&wait_lock);
    80002692:	0000e517          	auipc	a0,0xe
    80002696:	72650513          	addi	a0,a0,1830 # 80010db8 <wait_lock>
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	604080e7          	jalr	1540(ra) # 80000c9e <release>
      return -1;
    800026a2:	59fd                	li	s3,-1
}
    800026a4:	854e                	mv	a0,s3
    800026a6:	60a6                	ld	ra,72(sp)
    800026a8:	6406                	ld	s0,64(sp)
    800026aa:	74e2                	ld	s1,56(sp)
    800026ac:	7942                	ld	s2,48(sp)
    800026ae:	79a2                	ld	s3,40(sp)
    800026b0:	7a02                	ld	s4,32(sp)
    800026b2:	6ae2                	ld	s5,24(sp)
    800026b4:	6b42                	ld	s6,16(sp)
    800026b6:	6ba2                	ld	s7,8(sp)
    800026b8:	6c02                	ld	s8,0(sp)
    800026ba:	6161                	addi	sp,sp,80
    800026bc:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026be:	85e2                	mv	a1,s8
    800026c0:	854a                	mv	a0,s2
    800026c2:	00000097          	auipc	ra,0x0
    800026c6:	aa6080e7          	jalr	-1370(ra) # 80002168 <sleep>
    havekids = 0;
    800026ca:	bf39                	j	800025e8 <wait+0x4a>

00000000800026cc <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026cc:	7179                	addi	sp,sp,-48
    800026ce:	f406                	sd	ra,40(sp)
    800026d0:	f022                	sd	s0,32(sp)
    800026d2:	ec26                	sd	s1,24(sp)
    800026d4:	e84a                	sd	s2,16(sp)
    800026d6:	e44e                	sd	s3,8(sp)
    800026d8:	e052                	sd	s4,0(sp)
    800026da:	1800                	addi	s0,sp,48
    800026dc:	84aa                	mv	s1,a0
    800026de:	892e                	mv	s2,a1
    800026e0:	89b2                	mv	s3,a2
    800026e2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	312080e7          	jalr	786(ra) # 800019f6 <myproc>
  if (user_dst)
    800026ec:	c08d                	beqz	s1,8000270e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800026ee:	86d2                	mv	a3,s4
    800026f0:	864e                	mv	a2,s3
    800026f2:	85ca                	mv	a1,s2
    800026f4:	6d28                	ld	a0,88(a0)
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	f8e080e7          	jalr	-114(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026fe:	70a2                	ld	ra,40(sp)
    80002700:	7402                	ld	s0,32(sp)
    80002702:	64e2                	ld	s1,24(sp)
    80002704:	6942                	ld	s2,16(sp)
    80002706:	69a2                	ld	s3,8(sp)
    80002708:	6a02                	ld	s4,0(sp)
    8000270a:	6145                	addi	sp,sp,48
    8000270c:	8082                	ret
    memmove((char *)dst, src, len);
    8000270e:	000a061b          	sext.w	a2,s4
    80002712:	85ce                	mv	a1,s3
    80002714:	854a                	mv	a0,s2
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	630080e7          	jalr	1584(ra) # 80000d46 <memmove>
    return 0;
    8000271e:	8526                	mv	a0,s1
    80002720:	bff9                	j	800026fe <either_copyout+0x32>

0000000080002722 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002722:	7179                	addi	sp,sp,-48
    80002724:	f406                	sd	ra,40(sp)
    80002726:	f022                	sd	s0,32(sp)
    80002728:	ec26                	sd	s1,24(sp)
    8000272a:	e84a                	sd	s2,16(sp)
    8000272c:	e44e                	sd	s3,8(sp)
    8000272e:	e052                	sd	s4,0(sp)
    80002730:	1800                	addi	s0,sp,48
    80002732:	892a                	mv	s2,a0
    80002734:	84ae                	mv	s1,a1
    80002736:	89b2                	mv	s3,a2
    80002738:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	2bc080e7          	jalr	700(ra) # 800019f6 <myproc>
  if (user_src)
    80002742:	c08d                	beqz	s1,80002764 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002744:	86d2                	mv	a3,s4
    80002746:	864e                	mv	a2,s3
    80002748:	85ca                	mv	a1,s2
    8000274a:	6d28                	ld	a0,88(a0)
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	fc4080e7          	jalr	-60(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002754:	70a2                	ld	ra,40(sp)
    80002756:	7402                	ld	s0,32(sp)
    80002758:	64e2                	ld	s1,24(sp)
    8000275a:	6942                	ld	s2,16(sp)
    8000275c:	69a2                	ld	s3,8(sp)
    8000275e:	6a02                	ld	s4,0(sp)
    80002760:	6145                	addi	sp,sp,48
    80002762:	8082                	ret
    memmove(dst, (char *)src, len);
    80002764:	000a061b          	sext.w	a2,s4
    80002768:	85ce                	mv	a1,s3
    8000276a:	854a                	mv	a0,s2
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	5da080e7          	jalr	1498(ra) # 80000d46 <memmove>
    return 0;
    80002774:	8526                	mv	a0,s1
    80002776:	bff9                	j	80002754 <either_copyin+0x32>

0000000080002778 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002778:	715d                	addi	sp,sp,-80
    8000277a:	e486                	sd	ra,72(sp)
    8000277c:	e0a2                	sd	s0,64(sp)
    8000277e:	fc26                	sd	s1,56(sp)
    80002780:	f84a                	sd	s2,48(sp)
    80002782:	f44e                	sd	s3,40(sp)
    80002784:	f052                	sd	s4,32(sp)
    80002786:	ec56                	sd	s5,24(sp)
    80002788:	e85a                	sd	s6,16(sp)
    8000278a:	e45e                	sd	s7,8(sp)
    8000278c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000278e:	00006517          	auipc	a0,0x6
    80002792:	93a50513          	addi	a0,a0,-1734 # 800080c8 <digits+0x88>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	df8080e7          	jalr	-520(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000279e:	0000f497          	auipc	s1,0xf
    800027a2:	b9a48493          	addi	s1,s1,-1126 # 80011338 <proc+0x168>
    800027a6:	00016917          	auipc	s2,0x16
    800027aa:	19290913          	addi	s2,s2,402 # 80018938 <bcache+0x150>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ae:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800027b0:	00006997          	auipc	s3,0x6
    800027b4:	ad098993          	addi	s3,s3,-1328 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800027b8:	00006a97          	auipc	s5,0x6
    800027bc:	ad0a8a93          	addi	s5,s5,-1328 # 80008288 <digits+0x248>
    printf("\n");
    800027c0:	00006a17          	auipc	s4,0x6
    800027c4:	908a0a13          	addi	s4,s4,-1784 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c8:	00006b97          	auipc	s7,0x6
    800027cc:	b00b8b93          	addi	s7,s7,-1280 # 800082c8 <states.1779>
    800027d0:	a00d                	j	800027f2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027d2:	ec86a583          	lw	a1,-312(a3)
    800027d6:	8556                	mv	a0,s5
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	db6080e7          	jalr	-586(ra) # 8000058e <printf>
    printf("\n");
    800027e0:	8552                	mv	a0,s4
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	dac080e7          	jalr	-596(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027ea:	1d848493          	addi	s1,s1,472
    800027ee:	03248163          	beq	s1,s2,80002810 <procdump+0x98>
    if (p->state == UNUSED)
    800027f2:	86a6                	mv	a3,s1
    800027f4:	eb04a783          	lw	a5,-336(s1)
    800027f8:	dbed                	beqz	a5,800027ea <procdump+0x72>
      state = "???";
    800027fa:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027fc:	fcfb6be3          	bltu	s6,a5,800027d2 <procdump+0x5a>
    80002800:	1782                	slli	a5,a5,0x20
    80002802:	9381                	srli	a5,a5,0x20
    80002804:	078e                	slli	a5,a5,0x3
    80002806:	97de                	add	a5,a5,s7
    80002808:	6390                	ld	a2,0(a5)
    8000280a:	f661                	bnez	a2,800027d2 <procdump+0x5a>
      state = "???";
    8000280c:	864e                	mv	a2,s3
    8000280e:	b7d1                	j	800027d2 <procdump+0x5a>
  }
}
    80002810:	60a6                	ld	ra,72(sp)
    80002812:	6406                	ld	s0,64(sp)
    80002814:	74e2                	ld	s1,56(sp)
    80002816:	7942                	ld	s2,48(sp)
    80002818:	79a2                	ld	s3,40(sp)
    8000281a:	7a02                	ld	s4,32(sp)
    8000281c:	6ae2                	ld	s5,24(sp)
    8000281e:	6b42                	ld	s6,16(sp)
    80002820:	6ba2                	ld	s7,8(sp)
    80002822:	6161                	addi	sp,sp,80
    80002824:	8082                	ret

0000000080002826 <setpriority>:

int setpriority(int new_priority, int pid)
{
    80002826:	7179                	addi	sp,sp,-48
    80002828:	f406                	sd	ra,40(sp)
    8000282a:	f022                	sd	s0,32(sp)
    8000282c:	ec26                	sd	s1,24(sp)
    8000282e:	e84a                	sd	s2,16(sp)
    80002830:	e44e                	sd	s3,8(sp)
    80002832:	e052                	sd	s4,0(sp)
    80002834:	1800                	addi	s0,sp,48
    80002836:	8a2a                	mv	s4,a0
    80002838:	892e                	mv	s2,a1
  int prev_priority = 0;

  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000283a:	0000f497          	auipc	s1,0xf
    8000283e:	99648493          	addi	s1,s1,-1642 # 800111d0 <proc>
    80002842:	00016997          	auipc	s3,0x16
    80002846:	f8e98993          	addi	s3,s3,-114 # 800187d0 <tickslock>
  {
    acquire(&p->lock);
    8000284a:	8526                	mv	a0,s1
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	39e080e7          	jalr	926(ra) # 80000bea <acquire>

    if (p->pid == pid)
    80002854:	589c                	lw	a5,48(s1)
    80002856:	01278d63          	beq	a5,s2,80002870 <setpriority+0x4a>
        yield();
      }

      break;
    }
    release(&p->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	442080e7          	jalr	1090(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002864:	1d848493          	addi	s1,s1,472
    80002868:	ff3491e3          	bne	s1,s3,8000284a <setpriority+0x24>
  int prev_priority = 0;
    8000286c:	4901                	li	s2,0
    8000286e:	a005                	j	8000288e <setpriority+0x68>
      prev_priority = p->priority;
    80002870:	1a04a903          	lw	s2,416(s1)
      p->priority = new_priority;
    80002874:	1b44b023          	sd	s4,416(s1)
      p->sleep_time = 0;
    80002878:	1804b823          	sd	zero,400(s1)
      p->run_time = 0;
    8000287c:	1804b023          	sd	zero,384(s1)
      release(&p->lock);
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	41c080e7          	jalr	1052(ra) # 80000c9e <release>
      if (new_priority < prev_priority)
    8000288a:	012a4b63          	blt	s4,s2,800028a0 <setpriority+0x7a>
  }
  return prev_priority;
}
    8000288e:	854a                	mv	a0,s2
    80002890:	70a2                	ld	ra,40(sp)
    80002892:	7402                	ld	s0,32(sp)
    80002894:	64e2                	ld	s1,24(sp)
    80002896:	6942                	ld	s2,16(sp)
    80002898:	69a2                	ld	s3,8(sp)
    8000289a:	6a02                	ld	s4,0(sp)
    8000289c:	6145                	addi	sp,sp,48
    8000289e:	8082                	ret
        yield();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	88c080e7          	jalr	-1908(ra) # 8000212c <yield>
    800028a8:	b7dd                	j	8000288e <setpriority+0x68>

00000000800028aa <swtch>:
    800028aa:	00153023          	sd	ra,0(a0)
    800028ae:	00253423          	sd	sp,8(a0)
    800028b2:	e900                	sd	s0,16(a0)
    800028b4:	ed04                	sd	s1,24(a0)
    800028b6:	03253023          	sd	s2,32(a0)
    800028ba:	03353423          	sd	s3,40(a0)
    800028be:	03453823          	sd	s4,48(a0)
    800028c2:	03553c23          	sd	s5,56(a0)
    800028c6:	05653023          	sd	s6,64(a0)
    800028ca:	05753423          	sd	s7,72(a0)
    800028ce:	05853823          	sd	s8,80(a0)
    800028d2:	05953c23          	sd	s9,88(a0)
    800028d6:	07a53023          	sd	s10,96(a0)
    800028da:	07b53423          	sd	s11,104(a0)
    800028de:	0005b083          	ld	ra,0(a1)
    800028e2:	0085b103          	ld	sp,8(a1)
    800028e6:	6980                	ld	s0,16(a1)
    800028e8:	6d84                	ld	s1,24(a1)
    800028ea:	0205b903          	ld	s2,32(a1)
    800028ee:	0285b983          	ld	s3,40(a1)
    800028f2:	0305ba03          	ld	s4,48(a1)
    800028f6:	0385ba83          	ld	s5,56(a1)
    800028fa:	0405bb03          	ld	s6,64(a1)
    800028fe:	0485bb83          	ld	s7,72(a1)
    80002902:	0505bc03          	ld	s8,80(a1)
    80002906:	0585bc83          	ld	s9,88(a1)
    8000290a:	0605bd03          	ld	s10,96(a1)
    8000290e:	0685bd83          	ld	s11,104(a1)
    80002912:	8082                	ret

0000000080002914 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002914:	1141                	addi	sp,sp,-16
    80002916:	e406                	sd	ra,8(sp)
    80002918:	e022                	sd	s0,0(sp)
    8000291a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000291c:	00006597          	auipc	a1,0x6
    80002920:	9dc58593          	addi	a1,a1,-1572 # 800082f8 <states.1779+0x30>
    80002924:	00016517          	auipc	a0,0x16
    80002928:	eac50513          	addi	a0,a0,-340 # 800187d0 <tickslock>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	22e080e7          	jalr	558(ra) # 80000b5a <initlock>
}
    80002934:	60a2                	ld	ra,8(sp)
    80002936:	6402                	ld	s0,0(sp)
    80002938:	0141                	addi	sp,sp,16
    8000293a:	8082                	ret

000000008000293c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000293c:	1141                	addi	sp,sp,-16
    8000293e:	e422                	sd	s0,8(sp)
    80002940:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002942:	00004797          	auipc	a5,0x4
    80002946:	80e78793          	addi	a5,a5,-2034 # 80006150 <kernelvec>
    8000294a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000294e:	6422                	ld	s0,8(sp)
    80002950:	0141                	addi	sp,sp,16
    80002952:	8082                	ret

0000000080002954 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002954:	1141                	addi	sp,sp,-16
    80002956:	e406                	sd	ra,8(sp)
    80002958:	e022                	sd	s0,0(sp)
    8000295a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000295c:	fffff097          	auipc	ra,0xfffff
    80002960:	09a080e7          	jalr	154(ra) # 800019f6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002964:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002968:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000296e:	00004617          	auipc	a2,0x4
    80002972:	69260613          	addi	a2,a2,1682 # 80007000 <_trampoline>
    80002976:	00004697          	auipc	a3,0x4
    8000297a:	68a68693          	addi	a3,a3,1674 # 80007000 <_trampoline>
    8000297e:	8e91                	sub	a3,a3,a2
    80002980:	040007b7          	lui	a5,0x4000
    80002984:	17fd                	addi	a5,a5,-1
    80002986:	07b2                	slli	a5,a5,0xc
    80002988:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000298e:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002990:	180026f3          	csrr	a3,satp
    80002994:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002996:	7138                	ld	a4,96(a0)
    80002998:	6134                	ld	a3,64(a0)
    8000299a:	6585                	lui	a1,0x1
    8000299c:	96ae                	add	a3,a3,a1
    8000299e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029a0:	7138                	ld	a4,96(a0)
    800029a2:	00000697          	auipc	a3,0x0
    800029a6:	13e68693          	addi	a3,a3,318 # 80002ae0 <usertrap>
    800029aa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800029ac:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029ae:	8692                	mv	a3,tp
    800029b0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029b6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ba:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029be:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029c2:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c4:	6f18                	ld	a4,24(a4)
    800029c6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ca:	6d28                	ld	a0,88(a0)
    800029cc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029ce:	00004717          	auipc	a4,0x4
    800029d2:	6ce70713          	addi	a4,a4,1742 # 8000709c <userret>
    800029d6:	8f11                	sub	a4,a4,a2
    800029d8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029da:	577d                	li	a4,-1
    800029dc:	177e                	slli	a4,a4,0x3f
    800029de:	8d59                	or	a0,a0,a4
    800029e0:	9782                	jalr	a5
}
    800029e2:	60a2                	ld	ra,8(sp)
    800029e4:	6402                	ld	s0,0(sp)
    800029e6:	0141                	addi	sp,sp,16
    800029e8:	8082                	ret

00000000800029ea <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800029ea:	1101                	addi	sp,sp,-32
    800029ec:	ec06                	sd	ra,24(sp)
    800029ee:	e822                	sd	s0,16(sp)
    800029f0:	e426                	sd	s1,8(sp)
    800029f2:	e04a                	sd	s2,0(sp)
    800029f4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f6:	00016917          	auipc	s2,0x16
    800029fa:	dda90913          	addi	s2,s2,-550 # 800187d0 <tickslock>
    800029fe:	854a                	mv	a0,s2
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	1ea080e7          	jalr	490(ra) # 80000bea <acquire>
  ticks++;
    80002a08:	00006497          	auipc	s1,0x6
    80002a0c:	12848493          	addi	s1,s1,296 # 80008b30 <ticks>
    80002a10:	409c                	lw	a5,0(s1)
    80002a12:	2785                	addiw	a5,a5,1
    80002a14:	c09c                	sw	a5,0(s1)
  update_time();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	520080e7          	jalr	1312(ra) # 80001f36 <update_time>
  wakeup(&ticks);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	8fc080e7          	jalr	-1796(ra) # 8000231c <wakeup>
  release(&tickslock);
    80002a28:	854a                	mv	a0,s2
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	274080e7          	jalr	628(ra) # 80000c9e <release>
}
    80002a32:	60e2                	ld	ra,24(sp)
    80002a34:	6442                	ld	s0,16(sp)
    80002a36:	64a2                	ld	s1,8(sp)
    80002a38:	6902                	ld	s2,0(sp)
    80002a3a:	6105                	addi	sp,sp,32
    80002a3c:	8082                	ret

0000000080002a3e <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a48:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a4c:	00074d63          	bltz	a4,80002a66 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a50:	57fd                	li	a5,-1
    80002a52:	17fe                	slli	a5,a5,0x3f
    80002a54:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a56:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a58:	06f70363          	beq	a4,a5,80002abe <devintr+0x80>
  }
}
    80002a5c:	60e2                	ld	ra,24(sp)
    80002a5e:	6442                	ld	s0,16(sp)
    80002a60:	64a2                	ld	s1,8(sp)
    80002a62:	6105                	addi	sp,sp,32
    80002a64:	8082                	ret
      (scause & 0xff) == 9)
    80002a66:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002a6a:	46a5                	li	a3,9
    80002a6c:	fed792e3          	bne	a5,a3,80002a50 <devintr+0x12>
    int irq = plic_claim();
    80002a70:	00003097          	auipc	ra,0x3
    80002a74:	7e8080e7          	jalr	2024(ra) # 80006258 <plic_claim>
    80002a78:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002a7a:	47a9                	li	a5,10
    80002a7c:	02f50763          	beq	a0,a5,80002aaa <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002a80:	4785                	li	a5,1
    80002a82:	02f50963          	beq	a0,a5,80002ab4 <devintr+0x76>
    return 1;
    80002a86:	4505                	li	a0,1
    else if (irq)
    80002a88:	d8f1                	beqz	s1,80002a5c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a8a:	85a6                	mv	a1,s1
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	87450513          	addi	a0,a0,-1932 # 80008300 <states.1779+0x38>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	afa080e7          	jalr	-1286(ra) # 8000058e <printf>
      plic_complete(irq);
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	00003097          	auipc	ra,0x3
    80002aa2:	7de080e7          	jalr	2014(ra) # 8000627c <plic_complete>
    return 1;
    80002aa6:	4505                	li	a0,1
    80002aa8:	bf55                	j	80002a5c <devintr+0x1e>
      uartintr();
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	f04080e7          	jalr	-252(ra) # 800009ae <uartintr>
    80002ab2:	b7ed                	j	80002a9c <devintr+0x5e>
      virtio_disk_intr();
    80002ab4:	00004097          	auipc	ra,0x4
    80002ab8:	cf2080e7          	jalr	-782(ra) # 800067a6 <virtio_disk_intr>
    80002abc:	b7c5                	j	80002a9c <devintr+0x5e>
    if (cpuid() == 0)
    80002abe:	fffff097          	auipc	ra,0xfffff
    80002ac2:	f0c080e7          	jalr	-244(ra) # 800019ca <cpuid>
    80002ac6:	c901                	beqz	a0,80002ad6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ac8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002acc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ace:	14479073          	csrw	sip,a5
    return 2;
    80002ad2:	4509                	li	a0,2
    80002ad4:	b761                	j	80002a5c <devintr+0x1e>
      clockintr();
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	f14080e7          	jalr	-236(ra) # 800029ea <clockintr>
    80002ade:	b7ed                	j	80002ac8 <devintr+0x8a>

0000000080002ae0 <usertrap>:
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	e04a                	sd	s2,0(sp)
    80002aea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aec:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002af0:	1007f793          	andi	a5,a5,256
    80002af4:	e3b1                	bnez	a5,80002b38 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002af6:	00003797          	auipc	a5,0x3
    80002afa:	65a78793          	addi	a5,a5,1626 # 80006150 <kernelvec>
    80002afe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	ef4080e7          	jalr	-268(ra) # 800019f6 <myproc>
    80002b0a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b0c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0e:	14102773          	csrr	a4,sepc
    80002b12:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b14:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b18:	47a1                	li	a5,8
    80002b1a:	02f70763          	beq	a4,a5,80002b48 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	f20080e7          	jalr	-224(ra) # 80002a3e <devintr>
    80002b26:	892a                	mv	s2,a0
    80002b28:	c92d                	beqz	a0,80002b9a <usertrap+0xba>
  if (killed(p))
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	a40080e7          	jalr	-1472(ra) # 8000256c <killed>
    80002b34:	c555                	beqz	a0,80002be0 <usertrap+0x100>
    80002b36:	a045                	j	80002bd6 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002b38:	00005517          	auipc	a0,0x5
    80002b3c:	7e850513          	addi	a0,a0,2024 # 80008320 <states.1779+0x58>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a04080e7          	jalr	-1532(ra) # 80000544 <panic>
    if (killed(p))
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	a24080e7          	jalr	-1500(ra) # 8000256c <killed>
    80002b50:	ed1d                	bnez	a0,80002b8e <usertrap+0xae>
    p->trapframe->epc += 4;
    80002b52:	70b8                	ld	a4,96(s1)
    80002b54:	6f1c                	ld	a5,24(a4)
    80002b56:	0791                	addi	a5,a5,4
    80002b58:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b5e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b62:	10079073          	csrw	sstatus,a5
    syscall();
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	330080e7          	jalr	816(ra) # 80002e96 <syscall>
  if (killed(p))
    80002b6e:	8526                	mv	a0,s1
    80002b70:	00000097          	auipc	ra,0x0
    80002b74:	9fc080e7          	jalr	-1540(ra) # 8000256c <killed>
    80002b78:	ed31                	bnez	a0,80002bd4 <usertrap+0xf4>
  usertrapret();
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	dda080e7          	jalr	-550(ra) # 80002954 <usertrapret>
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6902                	ld	s2,0(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret
      exit(-1);
    80002b8e:	557d                	li	a0,-1
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	85c080e7          	jalr	-1956(ra) # 800023ec <exit>
    80002b98:	bf6d                	j	80002b52 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b9a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b9e:	5890                	lw	a2,48(s1)
    80002ba0:	00005517          	auipc	a0,0x5
    80002ba4:	7a050513          	addi	a0,a0,1952 # 80008340 <states.1779+0x78>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9e6080e7          	jalr	-1562(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	7b850513          	addi	a0,a0,1976 # 80008370 <states.1779+0xa8>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9ce080e7          	jalr	-1586(ra) # 8000058e <printf>
    setkilled(p);
    80002bc8:	8526                	mv	a0,s1
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	976080e7          	jalr	-1674(ra) # 80002540 <setkilled>
    80002bd2:	bf71                	j	80002b6e <usertrap+0x8e>
  if (killed(p))
    80002bd4:	4901                	li	s2,0
    exit(-1);
    80002bd6:	557d                	li	a0,-1
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	814080e7          	jalr	-2028(ra) # 800023ec <exit>
  if (which_dev == 2 && p->alarm_on == 1 && p->handler_permission == 1) // which_dev == 2 is time interrupt
    80002be0:	4789                	li	a5,2
    80002be2:	f8f91ce3          	bne	s2,a5,80002b7a <usertrap+0x9a>
    80002be6:	1d04a703          	lw	a4,464(s1)
    80002bea:	4785                	li	a5,1
    80002bec:	00f70763          	beq	a4,a5,80002bfa <usertrap+0x11a>
    yield();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	53c080e7          	jalr	1340(ra) # 8000212c <yield>
    80002bf8:	b749                	j	80002b7a <usertrap+0x9a>
  if (which_dev == 2 && p->alarm_on == 1 && p->handler_permission == 1) // which_dev == 2 is time interrupt
    80002bfa:	1cc4a703          	lw	a4,460(s1)
    80002bfe:	fef719e3          	bne	a4,a5,80002bf0 <usertrap+0x110>
    struct trapframe *trap_frame = kalloc();
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	ef8080e7          	jalr	-264(ra) # 80000afa <kalloc>
    80002c0a:	892a                	mv	s2,a0
    memmove(trap_frame, p->trapframe, 4096);
    80002c0c:	6605                	lui	a2,0x1
    80002c0e:	70ac                	ld	a1,96(s1)
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	136080e7          	jalr	310(ra) # 80000d46 <memmove>
    p->current_ticks = p->current_ticks + 1;
    80002c18:	1c84a783          	lw	a5,456(s1)
    80002c1c:	2785                	addiw	a5,a5,1
    80002c1e:	0007871b          	sext.w	a4,a5
    80002c22:	1cf4a423          	sw	a5,456(s1)
    p->ticks_in_current_slice = p->ticks_in_current_slice + 1; // increment ticks every time time interrupt occurs (can be thought of as a clock cycle is completed)
    80002c26:	1b84b783          	ld	a5,440(s1)
    80002c2a:	0785                	addi	a5,a5,1
    80002c2c:	1af4bc23          	sd	a5,440(s1)
    p->alarm_trapframe = trap_frame;
    80002c30:	0724b423          	sd	s2,104(s1)
    if (p->current_ticks < p->ticks)
    80002c34:	1c44a783          	lw	a5,452(s1)
    80002c38:	faf74ce3          	blt	a4,a5,80002bf0 <usertrap+0x110>
      p->handler_permission = 0;
    80002c3c:	1c04a623          	sw	zero,460(s1)
      p->trapframe->epc = p->handler; // next instruction to be executed pointed by program counter is handler function (user defined function)
    80002c40:	70bc                	ld	a5,96(s1)
    80002c42:	68b8                	ld	a4,80(s1)
    80002c44:	ef98                	sd	a4,24(a5)
    80002c46:	b76d                	j	80002bf0 <usertrap+0x110>

0000000080002c48 <kerneltrap>:
{
    80002c48:	7179                	addi	sp,sp,-48
    80002c4a:	f406                	sd	ra,40(sp)
    80002c4c:	f022                	sd	s0,32(sp)
    80002c4e:	ec26                	sd	s1,24(sp)
    80002c50:	e84a                	sd	s2,16(sp)
    80002c52:	e44e                	sd	s3,8(sp)
    80002c54:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c56:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5e:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002c62:	1004f793          	andi	a5,s1,256
    80002c66:	cb85                	beqz	a5,80002c96 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c68:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c6c:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002c6e:	ef85                	bnez	a5,80002ca6 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	dce080e7          	jalr	-562(ra) # 80002a3e <devintr>
    80002c78:	cd1d                	beqz	a0,80002cb6 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c7a:	4789                	li	a5,2
    80002c7c:	06f50a63          	beq	a0,a5,80002cf0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c80:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c84:	10049073          	csrw	sstatus,s1
}
    80002c88:	70a2                	ld	ra,40(sp)
    80002c8a:	7402                	ld	s0,32(sp)
    80002c8c:	64e2                	ld	s1,24(sp)
    80002c8e:	6942                	ld	s2,16(sp)
    80002c90:	69a2                	ld	s3,8(sp)
    80002c92:	6145                	addi	sp,sp,48
    80002c94:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	6fa50513          	addi	a0,a0,1786 # 80008390 <states.1779+0xc8>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8a6080e7          	jalr	-1882(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	71250513          	addi	a0,a0,1810 # 800083b8 <states.1779+0xf0>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	896080e7          	jalr	-1898(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002cb6:	85ce                	mv	a1,s3
    80002cb8:	00005517          	auipc	a0,0x5
    80002cbc:	72050513          	addi	a0,a0,1824 # 800083d8 <states.1779+0x110>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	8ce080e7          	jalr	-1842(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ccc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	71850513          	addi	a0,a0,1816 # 800083e8 <states.1779+0x120>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	8b6080e7          	jalr	-1866(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002ce0:	00005517          	auipc	a0,0x5
    80002ce4:	72050513          	addi	a0,a0,1824 # 80008400 <states.1779+0x138>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	85c080e7          	jalr	-1956(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	d06080e7          	jalr	-762(ra) # 800019f6 <myproc>
    80002cf8:	d541                	beqz	a0,80002c80 <kerneltrap+0x38>
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	cfc080e7          	jalr	-772(ra) # 800019f6 <myproc>
    80002d02:	4d18                	lw	a4,24(a0)
    80002d04:	4791                	li	a5,4
    80002d06:	f6f71de3          	bne	a4,a5,80002c80 <kerneltrap+0x38>
    yield();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	422080e7          	jalr	1058(ra) # 8000212c <yield>
    80002d12:	b7bd                	j	80002c80 <kerneltrap+0x38>

0000000080002d14 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	1000                	addi	s0,sp,32
    80002d1e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	cd6080e7          	jalr	-810(ra) # 800019f6 <myproc>
  switch (n)
    80002d28:	4795                	li	a5,5
    80002d2a:	0497e163          	bltu	a5,s1,80002d6c <argraw+0x58>
    80002d2e:	048a                	slli	s1,s1,0x2
    80002d30:	00006717          	auipc	a4,0x6
    80002d34:	82870713          	addi	a4,a4,-2008 # 80008558 <states.1779+0x290>
    80002d38:	94ba                	add	s1,s1,a4
    80002d3a:	409c                	lw	a5,0(s1)
    80002d3c:	97ba                	add	a5,a5,a4
    80002d3e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d40:	713c                	ld	a5,96(a0)
    80002d42:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d44:	60e2                	ld	ra,24(sp)
    80002d46:	6442                	ld	s0,16(sp)
    80002d48:	64a2                	ld	s1,8(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret
    return p->trapframe->a1;
    80002d4e:	713c                	ld	a5,96(a0)
    80002d50:	7fa8                	ld	a0,120(a5)
    80002d52:	bfcd                	j	80002d44 <argraw+0x30>
    return p->trapframe->a2;
    80002d54:	713c                	ld	a5,96(a0)
    80002d56:	63c8                	ld	a0,128(a5)
    80002d58:	b7f5                	j	80002d44 <argraw+0x30>
    return p->trapframe->a3;
    80002d5a:	713c                	ld	a5,96(a0)
    80002d5c:	67c8                	ld	a0,136(a5)
    80002d5e:	b7dd                	j	80002d44 <argraw+0x30>
    return p->trapframe->a4;
    80002d60:	713c                	ld	a5,96(a0)
    80002d62:	6bc8                	ld	a0,144(a5)
    80002d64:	b7c5                	j	80002d44 <argraw+0x30>
    return p->trapframe->a5;
    80002d66:	713c                	ld	a5,96(a0)
    80002d68:	6fc8                	ld	a0,152(a5)
    80002d6a:	bfe9                	j	80002d44 <argraw+0x30>
  panic("argraw");
    80002d6c:	00005517          	auipc	a0,0x5
    80002d70:	6a450513          	addi	a0,a0,1700 # 80008410 <states.1779+0x148>
    80002d74:	ffffd097          	auipc	ra,0xffffd
    80002d78:	7d0080e7          	jalr	2000(ra) # 80000544 <panic>

0000000080002d7c <fetchaddr>:
{
    80002d7c:	1101                	addi	sp,sp,-32
    80002d7e:	ec06                	sd	ra,24(sp)
    80002d80:	e822                	sd	s0,16(sp)
    80002d82:	e426                	sd	s1,8(sp)
    80002d84:	e04a                	sd	s2,0(sp)
    80002d86:	1000                	addi	s0,sp,32
    80002d88:	84aa                	mv	s1,a0
    80002d8a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	c6a080e7          	jalr	-918(ra) # 800019f6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d94:	653c                	ld	a5,72(a0)
    80002d96:	02f4f863          	bgeu	s1,a5,80002dc6 <fetchaddr+0x4a>
    80002d9a:	00848713          	addi	a4,s1,8
    80002d9e:	02e7e663          	bltu	a5,a4,80002dca <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002da2:	46a1                	li	a3,8
    80002da4:	8626                	mv	a2,s1
    80002da6:	85ca                	mv	a1,s2
    80002da8:	6d28                	ld	a0,88(a0)
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	966080e7          	jalr	-1690(ra) # 80001710 <copyin>
    80002db2:	00a03533          	snez	a0,a0
    80002db6:	40a00533          	neg	a0,a0
}
    80002dba:	60e2                	ld	ra,24(sp)
    80002dbc:	6442                	ld	s0,16(sp)
    80002dbe:	64a2                	ld	s1,8(sp)
    80002dc0:	6902                	ld	s2,0(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret
    return -1;
    80002dc6:	557d                	li	a0,-1
    80002dc8:	bfcd                	j	80002dba <fetchaddr+0x3e>
    80002dca:	557d                	li	a0,-1
    80002dcc:	b7fd                	j	80002dba <fetchaddr+0x3e>

0000000080002dce <fetchstr>:
{
    80002dce:	7179                	addi	sp,sp,-48
    80002dd0:	f406                	sd	ra,40(sp)
    80002dd2:	f022                	sd	s0,32(sp)
    80002dd4:	ec26                	sd	s1,24(sp)
    80002dd6:	e84a                	sd	s2,16(sp)
    80002dd8:	e44e                	sd	s3,8(sp)
    80002dda:	1800                	addi	s0,sp,48
    80002ddc:	892a                	mv	s2,a0
    80002dde:	84ae                	mv	s1,a1
    80002de0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	c14080e7          	jalr	-1004(ra) # 800019f6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002dea:	86ce                	mv	a3,s3
    80002dec:	864a                	mv	a2,s2
    80002dee:	85a6                	mv	a1,s1
    80002df0:	6d28                	ld	a0,88(a0)
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	9aa080e7          	jalr	-1622(ra) # 8000179c <copyinstr>
    80002dfa:	00054e63          	bltz	a0,80002e16 <fetchstr+0x48>
  return strlen(buf);
    80002dfe:	8526                	mv	a0,s1
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	06a080e7          	jalr	106(ra) # 80000e6a <strlen>
}
    80002e08:	70a2                	ld	ra,40(sp)
    80002e0a:	7402                	ld	s0,32(sp)
    80002e0c:	64e2                	ld	s1,24(sp)
    80002e0e:	6942                	ld	s2,16(sp)
    80002e10:	69a2                	ld	s3,8(sp)
    80002e12:	6145                	addi	sp,sp,48
    80002e14:	8082                	ret
    return -1;
    80002e16:	557d                	li	a0,-1
    80002e18:	bfc5                	j	80002e08 <fetchstr+0x3a>

0000000080002e1a <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
    80002e24:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	eee080e7          	jalr	-274(ra) # 80002d14 <argraw>
    80002e2e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e30:	4501                	li	a0,0
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	1000                	addi	s0,sp,32
    80002e46:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	ecc080e7          	jalr	-308(ra) # 80002d14 <argraw>
    80002e50:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e52:	4501                	li	a0,0
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	64a2                	ld	s1,8(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e5e:	7179                	addi	sp,sp,-48
    80002e60:	f406                	sd	ra,40(sp)
    80002e62:	f022                	sd	s0,32(sp)
    80002e64:	ec26                	sd	s1,24(sp)
    80002e66:	e84a                	sd	s2,16(sp)
    80002e68:	1800                	addi	s0,sp,48
    80002e6a:	84ae                	mv	s1,a1
    80002e6c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e6e:	fd840593          	addi	a1,s0,-40
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	fca080e7          	jalr	-54(ra) # 80002e3c <argaddr>
  return fetchstr(addr, buf, max);
    80002e7a:	864a                	mv	a2,s2
    80002e7c:	85a6                	mv	a1,s1
    80002e7e:	fd843503          	ld	a0,-40(s0)
    80002e82:	00000097          	auipc	ra,0x0
    80002e86:	f4c080e7          	jalr	-180(ra) # 80002dce <fetchstr>
}
    80002e8a:	70a2                	ld	ra,40(sp)
    80002e8c:	7402                	ld	s0,32(sp)
    80002e8e:	64e2                	ld	s1,24(sp)
    80002e90:	6942                	ld	s2,16(sp)
    80002e92:	6145                	addi	sp,sp,48
    80002e94:	8082                	ret

0000000080002e96 <syscall>:
    3, // waitx

};

void syscall(void)
{
    80002e96:	715d                	addi	sp,sp,-80
    80002e98:	e486                	sd	ra,72(sp)
    80002e9a:	e0a2                	sd	s0,64(sp)
    80002e9c:	fc26                	sd	s1,56(sp)
    80002e9e:	f84a                	sd	s2,48(sp)
    80002ea0:	f44e                	sd	s3,40(sp)
    80002ea2:	f052                	sd	s4,32(sp)
    80002ea4:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	b50080e7          	jalr	-1200(ra) # 800019f6 <myproc>
    80002eae:	84aa                	mv	s1,a0
  num = p->trapframe->a7; // number of the particular syscall to be executed
    80002eb0:	713c                	ld	a5,96(a0)
    80002eb2:	77dc                	ld	a5,168(a5)
    80002eb4:	0007891b          	sext.w	s2,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002eb8:	37fd                	addiw	a5,a5,-1
    80002eba:	4765                	li	a4,25
    80002ebc:	10f76663          	bltu	a4,a5,80002fc8 <syscall+0x132>
    80002ec0:	00391713          	slli	a4,s2,0x3
    80002ec4:	00005797          	auipc	a5,0x5
    80002ec8:	6ac78793          	addi	a5,a5,1708 # 80008570 <syscalls>
    80002ecc:	97ba                	add	a5,a5,a4
    80002ece:	0007b983          	ld	s3,0(a5)
    80002ed2:	0e098b63          	beqz	s3,80002fc8 <syscall+0x132>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    uint64 addr1;
    argaddr(0, &addr1); // check the first argument that the syscall takes
    80002ed6:	fb840593          	addi	a1,s0,-72
    80002eda:	4501                	li	a0,0
    80002edc:	00000097          	auipc	ra,0x0
    80002ee0:	f60080e7          	jalr	-160(ra) # 80002e3c <argaddr>
    p->trapframe->a0 = syscalls[num](); // return value of syscall is stored in a0 for printing at the end
    80002ee4:	0604ba03          	ld	s4,96(s1)
    80002ee8:	9982                	jalr	s3
    80002eea:	06aa3823          	sd	a0,112(s4)
    if ((p->mask >> num) & 1) // if mask = 32, 100000 bitwise and with right shift of 100000 by the syscall number 5 (read)
    80002eee:	1c04a783          	lw	a5,448(s1)
    80002ef2:	4127d7bb          	sraw	a5,a5,s2
    80002ef6:	8b85                	andi	a5,a5,1
    80002ef8:	c7fd                	beqz	a5,80002fe6 <syscall+0x150>
    {
      int proc_pid = p->pid;
      printf("%d: syscall %s ", proc_pid, syscallnames[num - 1]);
    80002efa:	397d                	addiw	s2,s2,-1
    80002efc:	00006997          	auipc	s3,0x6
    80002f00:	acc98993          	addi	s3,s3,-1332 # 800089c8 <syscallnames>
    80002f04:	00391793          	slli	a5,s2,0x3
    80002f08:	97ce                	add	a5,a5,s3
    80002f0a:	6390                	ld	a2,0(a5)
    80002f0c:	588c                	lw	a1,48(s1)
    80002f0e:	00005517          	auipc	a0,0x5
    80002f12:	50a50513          	addi	a0,a0,1290 # 80008418 <states.1779+0x150>
    80002f16:	ffffd097          	auipc	ra,0xffffd
    80002f1a:	678080e7          	jalr	1656(ra) # 8000058e <printf>
      if (argnum[num - 1] == 0)
    80002f1e:	090a                	slli	s2,s2,0x2
    80002f20:	99ca                	add	s3,s3,s2
    80002f22:	0d09a783          	lw	a5,208(s3)
    80002f26:	cb91                	beqz	a5,80002f3a <syscall+0xa4>
      {
      }
      else if (argnum[num - 1] == 1)
    80002f28:	4705                	li	a4,1
    80002f2a:	02e78363          	beq	a5,a4,80002f50 <syscall+0xba>
      {
        printf("(%d) ", addr1);
      }
      else if (argnum[num - 1] == 2)
    80002f2e:	4709                	li	a4,2
    80002f30:	02e78b63          	beq	a5,a4,80002f66 <syscall+0xd0>
      {
        uint64 addr2;
        argaddr(1, &addr2);
        printf("(%d %d) ", addr1, addr2);
      }
      else if (argnum[num - 1] == 3)
    80002f34:	470d                	li	a4,3
    80002f36:	04e78c63          	beq	a5,a4,80002f8e <syscall+0xf8>
        uint64 addr3;
        argaddr(1, &addr2);
        argaddr(2, &addr3);
        printf("(%d %d %d) ", addr1, addr2, addr3);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002f3a:	70bc                	ld	a5,96(s1)
    80002f3c:	7bac                	ld	a1,112(a5)
    80002f3e:	00005517          	auipc	a0,0x5
    80002f42:	51250513          	addi	a0,a0,1298 # 80008450 <states.1779+0x188>
    80002f46:	ffffd097          	auipc	ra,0xffffd
    80002f4a:	648080e7          	jalr	1608(ra) # 8000058e <printf>
  {
    80002f4e:	a861                	j	80002fe6 <syscall+0x150>
        printf("(%d) ", addr1);
    80002f50:	fb843583          	ld	a1,-72(s0)
    80002f54:	00005517          	auipc	a0,0x5
    80002f58:	4d450513          	addi	a0,a0,1236 # 80008428 <states.1779+0x160>
    80002f5c:	ffffd097          	auipc	ra,0xffffd
    80002f60:	632080e7          	jalr	1586(ra) # 8000058e <printf>
    80002f64:	bfd9                	j	80002f3a <syscall+0xa4>
        argaddr(1, &addr2);
    80002f66:	fc840593          	addi	a1,s0,-56
    80002f6a:	4505                	li	a0,1
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	ed0080e7          	jalr	-304(ra) # 80002e3c <argaddr>
        printf("(%d %d) ", addr1, addr2);
    80002f74:	fc843603          	ld	a2,-56(s0)
    80002f78:	fb843583          	ld	a1,-72(s0)
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	4b450513          	addi	a0,a0,1204 # 80008430 <states.1779+0x168>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	60a080e7          	jalr	1546(ra) # 8000058e <printf>
    80002f8c:	b77d                	j	80002f3a <syscall+0xa4>
        argaddr(1, &addr2);
    80002f8e:	fc040593          	addi	a1,s0,-64
    80002f92:	4505                	li	a0,1
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	ea8080e7          	jalr	-344(ra) # 80002e3c <argaddr>
        argaddr(2, &addr3);
    80002f9c:	fc840593          	addi	a1,s0,-56
    80002fa0:	4509                	li	a0,2
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	e9a080e7          	jalr	-358(ra) # 80002e3c <argaddr>
        printf("(%d %d %d) ", addr1, addr2, addr3);
    80002faa:	fc843683          	ld	a3,-56(s0)
    80002fae:	fc043603          	ld	a2,-64(s0)
    80002fb2:	fb843583          	ld	a1,-72(s0)
    80002fb6:	00005517          	auipc	a0,0x5
    80002fba:	48a50513          	addi	a0,a0,1162 # 80008440 <states.1779+0x178>
    80002fbe:	ffffd097          	auipc	ra,0xffffd
    80002fc2:	5d0080e7          	jalr	1488(ra) # 8000058e <printf>
    80002fc6:	bf95                	j	80002f3a <syscall+0xa4>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002fc8:	86ca                	mv	a3,s2
    80002fca:	16848613          	addi	a2,s1,360
    80002fce:	588c                	lw	a1,48(s1)
    80002fd0:	00005517          	auipc	a0,0x5
    80002fd4:	48850513          	addi	a0,a0,1160 # 80008458 <states.1779+0x190>
    80002fd8:	ffffd097          	auipc	ra,0xffffd
    80002fdc:	5b6080e7          	jalr	1462(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fe0:	70bc                	ld	a5,96(s1)
    80002fe2:	577d                	li	a4,-1
    80002fe4:	fbb8                	sd	a4,112(a5)
  }
}
    80002fe6:	60a6                	ld	ra,72(sp)
    80002fe8:	6406                	ld	s0,64(sp)
    80002fea:	74e2                	ld	s1,56(sp)
    80002fec:	7942                	ld	s2,48(sp)
    80002fee:	79a2                	ld	s3,40(sp)
    80002ff0:	7a02                	ld	s4,32(sp)
    80002ff2:	6161                	addi	sp,sp,80
    80002ff4:	8082                	ret

0000000080002ff6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ff6:	1101                	addi	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ffe:	fec40593          	addi	a1,s0,-20
    80003002:	4501                	li	a0,0
    80003004:	00000097          	auipc	ra,0x0
    80003008:	e16080e7          	jalr	-490(ra) # 80002e1a <argint>
  exit(n);
    8000300c:	fec42503          	lw	a0,-20(s0)
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	3dc080e7          	jalr	988(ra) # 800023ec <exit>
  return 0; // not reached
}
    80003018:	4501                	li	a0,0
    8000301a:	60e2                	ld	ra,24(sp)
    8000301c:	6442                	ld	s0,16(sp)
    8000301e:	6105                	addi	sp,sp,32
    80003020:	8082                	ret

0000000080003022 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003022:	1141                	addi	sp,sp,-16
    80003024:	e406                	sd	ra,8(sp)
    80003026:	e022                	sd	s0,0(sp)
    80003028:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	9cc080e7          	jalr	-1588(ra) # 800019f6 <myproc>
}
    80003032:	5908                	lw	a0,48(a0)
    80003034:	60a2                	ld	ra,8(sp)
    80003036:	6402                	ld	s0,0(sp)
    80003038:	0141                	addi	sp,sp,16
    8000303a:	8082                	ret

000000008000303c <sys_fork>:

uint64
sys_fork(void)
{
    8000303c:	1141                	addi	sp,sp,-16
    8000303e:	e406                	sd	ra,8(sp)
    80003040:	e022                	sd	s0,0(sp)
    80003042:	0800                	addi	s0,sp,16
  return fork();
    80003044:	fffff097          	auipc	ra,0xfffff
    80003048:	da6080e7          	jalr	-602(ra) # 80001dea <fork>
}
    8000304c:	60a2                	ld	ra,8(sp)
    8000304e:	6402                	ld	s0,0(sp)
    80003050:	0141                	addi	sp,sp,16
    80003052:	8082                	ret

0000000080003054 <sys_wait>:

uint64
sys_wait(void)
{
    80003054:	1101                	addi	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000305c:	fe840593          	addi	a1,s0,-24
    80003060:	4501                	li	a0,0
    80003062:	00000097          	auipc	ra,0x0
    80003066:	dda080e7          	jalr	-550(ra) # 80002e3c <argaddr>
  return wait(p);
    8000306a:	fe843503          	ld	a0,-24(s0)
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	530080e7          	jalr	1328(ra) # 8000259e <wait>
}
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret

000000008000307e <sys_waitx>:

uint64
sys_waitx(void)
{
    8000307e:	7139                	addi	sp,sp,-64
    80003080:	fc06                	sd	ra,56(sp)
    80003082:	f822                	sd	s0,48(sp)
    80003084:	f426                	sd	s1,40(sp)
    80003086:	f04a                	sd	s2,32(sp)
    80003088:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000308a:	fd840593          	addi	a1,s0,-40
    8000308e:	4501                	li	a0,0
    80003090:	00000097          	auipc	ra,0x0
    80003094:	dac080e7          	jalr	-596(ra) # 80002e3c <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003098:	fd040593          	addi	a1,s0,-48
    8000309c:	4505                	li	a0,1
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	d9e080e7          	jalr	-610(ra) # 80002e3c <argaddr>
  argaddr(2, &addr2);
    800030a6:	fc840593          	addi	a1,s0,-56
    800030aa:	4509                	li	a0,2
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	d90080e7          	jalr	-624(ra) # 80002e3c <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030b4:	fc040613          	addi	a2,s0,-64
    800030b8:	fc440593          	addi	a1,s0,-60
    800030bc:	fd843503          	ld	a0,-40(s0)
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	10c080e7          	jalr	268(ra) # 800021cc <waitx>
    800030c8:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	92c080e7          	jalr	-1748(ra) # 800019f6 <myproc>
    800030d2:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800030d4:	4691                	li	a3,4
    800030d6:	fc440613          	addi	a2,s0,-60
    800030da:	fd043583          	ld	a1,-48(s0)
    800030de:	6d28                	ld	a0,88(a0)
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	5a4080e7          	jalr	1444(ra) # 80001684 <copyout>
    return -1;
    800030e8:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800030ea:	00054f63          	bltz	a0,80003108 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    800030ee:	4691                	li	a3,4
    800030f0:	fc040613          	addi	a2,s0,-64
    800030f4:	fc843583          	ld	a1,-56(s0)
    800030f8:	6ca8                	ld	a0,88(s1)
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	58a080e7          	jalr	1418(ra) # 80001684 <copyout>
    80003102:	00054a63          	bltz	a0,80003116 <sys_waitx+0x98>
    return -1;
  return ret;
    80003106:	87ca                	mv	a5,s2
}
    80003108:	853e                	mv	a0,a5
    8000310a:	70e2                	ld	ra,56(sp)
    8000310c:	7442                	ld	s0,48(sp)
    8000310e:	74a2                	ld	s1,40(sp)
    80003110:	7902                	ld	s2,32(sp)
    80003112:	6121                	addi	sp,sp,64
    80003114:	8082                	ret
    return -1;
    80003116:	57fd                	li	a5,-1
    80003118:	bfc5                	j	80003108 <sys_waitx+0x8a>

000000008000311a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000311a:	7179                	addi	sp,sp,-48
    8000311c:	f406                	sd	ra,40(sp)
    8000311e:	f022                	sd	s0,32(sp)
    80003120:	ec26                	sd	s1,24(sp)
    80003122:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003124:	fdc40593          	addi	a1,s0,-36
    80003128:	4501                	li	a0,0
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	cf0080e7          	jalr	-784(ra) # 80002e1a <argint>
  addr = myproc()->sz;
    80003132:	fffff097          	auipc	ra,0xfffff
    80003136:	8c4080e7          	jalr	-1852(ra) # 800019f6 <myproc>
    8000313a:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000313c:	fdc42503          	lw	a0,-36(s0)
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	c4e080e7          	jalr	-946(ra) # 80001d8e <growproc>
    80003148:	00054863          	bltz	a0,80003158 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000314c:	8526                	mv	a0,s1
    8000314e:	70a2                	ld	ra,40(sp)
    80003150:	7402                	ld	s0,32(sp)
    80003152:	64e2                	ld	s1,24(sp)
    80003154:	6145                	addi	sp,sp,48
    80003156:	8082                	ret
    return -1;
    80003158:	54fd                	li	s1,-1
    8000315a:	bfcd                	j	8000314c <sys_sbrk+0x32>

000000008000315c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000315c:	7139                	addi	sp,sp,-64
    8000315e:	fc06                	sd	ra,56(sp)
    80003160:	f822                	sd	s0,48(sp)
    80003162:	f426                	sd	s1,40(sp)
    80003164:	f04a                	sd	s2,32(sp)
    80003166:	ec4e                	sd	s3,24(sp)
    80003168:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000316a:	fcc40593          	addi	a1,s0,-52
    8000316e:	4501                	li	a0,0
    80003170:	00000097          	auipc	ra,0x0
    80003174:	caa080e7          	jalr	-854(ra) # 80002e1a <argint>
  acquire(&tickslock);
    80003178:	00015517          	auipc	a0,0x15
    8000317c:	65850513          	addi	a0,a0,1624 # 800187d0 <tickslock>
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	a6a080e7          	jalr	-1430(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80003188:	00006917          	auipc	s2,0x6
    8000318c:	9a892903          	lw	s2,-1624(s2) # 80008b30 <ticks>
  while (ticks - ticks0 < n)
    80003190:	fcc42783          	lw	a5,-52(s0)
    80003194:	cf9d                	beqz	a5,800031d2 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003196:	00015997          	auipc	s3,0x15
    8000319a:	63a98993          	addi	s3,s3,1594 # 800187d0 <tickslock>
    8000319e:	00006497          	auipc	s1,0x6
    800031a2:	99248493          	addi	s1,s1,-1646 # 80008b30 <ticks>
    if (killed(myproc()))
    800031a6:	fffff097          	auipc	ra,0xfffff
    800031aa:	850080e7          	jalr	-1968(ra) # 800019f6 <myproc>
    800031ae:	fffff097          	auipc	ra,0xfffff
    800031b2:	3be080e7          	jalr	958(ra) # 8000256c <killed>
    800031b6:	ed15                	bnez	a0,800031f2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800031b8:	85ce                	mv	a1,s3
    800031ba:	8526                	mv	a0,s1
    800031bc:	fffff097          	auipc	ra,0xfffff
    800031c0:	fac080e7          	jalr	-84(ra) # 80002168 <sleep>
  while (ticks - ticks0 < n)
    800031c4:	409c                	lw	a5,0(s1)
    800031c6:	412787bb          	subw	a5,a5,s2
    800031ca:	fcc42703          	lw	a4,-52(s0)
    800031ce:	fce7ece3          	bltu	a5,a4,800031a6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800031d2:	00015517          	auipc	a0,0x15
    800031d6:	5fe50513          	addi	a0,a0,1534 # 800187d0 <tickslock>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	ac4080e7          	jalr	-1340(ra) # 80000c9e <release>
  return 0;
    800031e2:	4501                	li	a0,0
}
    800031e4:	70e2                	ld	ra,56(sp)
    800031e6:	7442                	ld	s0,48(sp)
    800031e8:	74a2                	ld	s1,40(sp)
    800031ea:	7902                	ld	s2,32(sp)
    800031ec:	69e2                	ld	s3,24(sp)
    800031ee:	6121                	addi	sp,sp,64
    800031f0:	8082                	ret
      release(&tickslock);
    800031f2:	00015517          	auipc	a0,0x15
    800031f6:	5de50513          	addi	a0,a0,1502 # 800187d0 <tickslock>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	aa4080e7          	jalr	-1372(ra) # 80000c9e <release>
      return -1;
    80003202:	557d                	li	a0,-1
    80003204:	b7c5                	j	800031e4 <sys_sleep+0x88>

0000000080003206 <sys_kill>:

uint64
sys_kill(void)
{
    80003206:	1101                	addi	sp,sp,-32
    80003208:	ec06                	sd	ra,24(sp)
    8000320a:	e822                	sd	s0,16(sp)
    8000320c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000320e:	fec40593          	addi	a1,s0,-20
    80003212:	4501                	li	a0,0
    80003214:	00000097          	auipc	ra,0x0
    80003218:	c06080e7          	jalr	-1018(ra) # 80002e1a <argint>
  return kill(pid);
    8000321c:	fec42503          	lw	a0,-20(s0)
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	2ae080e7          	jalr	686(ra) # 800024ce <kill>
}
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret

0000000080003230 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003230:	1101                	addi	sp,sp,-32
    80003232:	ec06                	sd	ra,24(sp)
    80003234:	e822                	sd	s0,16(sp)
    80003236:	e426                	sd	s1,8(sp)
    80003238:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000323a:	00015517          	auipc	a0,0x15
    8000323e:	59650513          	addi	a0,a0,1430 # 800187d0 <tickslock>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	9a8080e7          	jalr	-1624(ra) # 80000bea <acquire>
  xticks = ticks;
    8000324a:	00006497          	auipc	s1,0x6
    8000324e:	8e64a483          	lw	s1,-1818(s1) # 80008b30 <ticks>
  release(&tickslock);
    80003252:	00015517          	auipc	a0,0x15
    80003256:	57e50513          	addi	a0,a0,1406 # 800187d0 <tickslock>
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	a44080e7          	jalr	-1468(ra) # 80000c9e <release>
  return xticks;
}
    80003262:	02049513          	slli	a0,s1,0x20
    80003266:	9101                	srli	a0,a0,0x20
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <sys_trace>:

// Assignment 4

uint64
sys_trace(void)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	1000                	addi	s0,sp,32
  int mask;
  if (argint(0, &mask) == 0)
    8000327a:	fec40593          	addi	a1,s0,-20
    8000327e:	4501                	li	a0,0
    80003280:	00000097          	auipc	ra,0x0
    80003284:	b9a080e7          	jalr	-1126(ra) # 80002e1a <argint>
    myproc()->mask = mask;
    return 0;
  }
  else
  {
    return -1;
    80003288:	57fd                	li	a5,-1
  if (argint(0, &mask) == 0)
    8000328a:	c511                	beqz	a0,80003296 <sys_trace+0x24>
  }
}
    8000328c:	853e                	mv	a0,a5
    8000328e:	60e2                	ld	ra,24(sp)
    80003290:	6442                	ld	s0,16(sp)
    80003292:	6105                	addi	sp,sp,32
    80003294:	8082                	ret
    myproc()->mask = mask;
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	760080e7          	jalr	1888(ra) # 800019f6 <myproc>
    8000329e:	fec42783          	lw	a5,-20(s0)
    800032a2:	1cf52023          	sw	a5,448(a0)
    return 0;
    800032a6:	4781                	li	a5,0
    800032a8:	b7d5                	j	8000328c <sys_trace+0x1a>

00000000800032aa <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	1000                	addi	s0,sp,32
  int ticks;
  int ticks_ret = argint(0, &ticks);
    800032b2:	fec40593          	addi	a1,s0,-20
    800032b6:	4501                	li	a0,0
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	b62080e7          	jalr	-1182(ra) # 80002e1a <argint>
  if (ticks_ret < 0)
  {
    return -1;
    800032c0:	57fd                	li	a5,-1
  if (ticks_ret < 0)
    800032c2:	04054363          	bltz	a0,80003308 <sys_sigalarm+0x5e>
  }
  uint64 handler_address;
  int handler_address_ret = argaddr(1, &handler_address);
    800032c6:	fe040593          	addi	a1,s0,-32
    800032ca:	4505                	li	a0,1
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	b70080e7          	jalr	-1168(ra) # 80002e3c <argaddr>
  if (handler_address_ret < 0)
  {
    return -1;
    800032d4:	57fd                	li	a5,-1
  if (handler_address_ret < 0)
    800032d6:	02054963          	bltz	a0,80003308 <sys_sigalarm+0x5e>
  }
  myproc()->ticks = ticks;
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	71c080e7          	jalr	1820(ra) # 800019f6 <myproc>
    800032e2:	fec42783          	lw	a5,-20(s0)
    800032e6:	1cf52223          	sw	a5,452(a0)
  myproc()->handler = handler_address;
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	70c080e7          	jalr	1804(ra) # 800019f6 <myproc>
    800032f2:	fe043783          	ld	a5,-32(s0)
    800032f6:	e93c                	sd	a5,80(a0)
  myproc()->alarm_on = 1;
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	6fe080e7          	jalr	1790(ra) # 800019f6 <myproc>
    80003300:	4785                	li	a5,1
    80003302:	1cf52823          	sw	a5,464(a0)
  // printf("Hi\n");
  return 0;
    80003306:	4781                	li	a5,0
}
    80003308:	853e                	mv	a0,a5
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	e426                	sd	s1,8(sp)
    8000331a:	1000                	addi	s0,sp,32
  // moving alarm trapframe to trapframe and then freeing the contents of alarm trapframe to restore trapframe
  memmove(myproc()->trapframe, myproc()->alarm_trapframe, 4096);
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	6da080e7          	jalr	1754(ra) # 800019f6 <myproc>
    80003324:	7124                	ld	s1,96(a0)
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	6d0080e7          	jalr	1744(ra) # 800019f6 <myproc>
    8000332e:	6605                	lui	a2,0x1
    80003330:	752c                	ld	a1,104(a0)
    80003332:	8526                	mv	a0,s1
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	a12080e7          	jalr	-1518(ra) # 80000d46 <memmove>
  kfree(myproc()->alarm_trapframe);
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	6ba080e7          	jalr	1722(ra) # 800019f6 <myproc>
    80003344:	7528                	ld	a0,104(a0)
    80003346:	ffffd097          	auipc	ra,0xffffd
    8000334a:	6b8080e7          	jalr	1720(ra) # 800009fe <kfree>
  // cleaning up ticks info
  myproc()->alarm_trapframe = 0;
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	6a8080e7          	jalr	1704(ra) # 800019f6 <myproc>
    80003356:	06053423          	sd	zero,104(a0)
  myproc()->current_ticks = 0;
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	69c080e7          	jalr	1692(ra) # 800019f6 <myproc>
    80003362:	1c052423          	sw	zero,456(a0)
  myproc()->handler_permission = 1;
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	690080e7          	jalr	1680(ra) # 800019f6 <myproc>
    8000336e:	4785                	li	a5,1
    80003370:	1cf52623          	sw	a5,460(a0)
  // printf("Bye\n");
  return myproc()->trapframe->a0;
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	682080e7          	jalr	1666(ra) # 800019f6 <myproc>
    8000337c:	713c                	ld	a5,96(a0)
}
    8000337e:	7ba8                	ld	a0,112(a5)
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	64a2                	ld	s1,8(sp)
    80003386:	6105                	addi	sp,sp,32
    80003388:	8082                	ret

000000008000338a <sys_setpriority>:

uint64
sys_setpriority()
{
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	1000                	addi	s0,sp,32
  int pid, priority;

  if ((argint(0, &priority) < 0) || (argint(1, &pid) < 0))
    80003392:	fe840593          	addi	a1,s0,-24
    80003396:	4501                	li	a0,0
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	a82080e7          	jalr	-1406(ra) # 80002e1a <argint>
  {
    return -1;
    800033a0:	57fd                	li	a5,-1
  if ((argint(0, &priority) < 0) || (argint(1, &pid) < 0))
    800033a2:	02054563          	bltz	a0,800033cc <sys_setpriority+0x42>
    800033a6:	fec40593          	addi	a1,s0,-20
    800033aa:	4505                	li	a0,1
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	a6e080e7          	jalr	-1426(ra) # 80002e1a <argint>
    return -1;
    800033b4:	57fd                	li	a5,-1
  if ((argint(0, &priority) < 0) || (argint(1, &pid) < 0))
    800033b6:	00054b63          	bltz	a0,800033cc <sys_setpriority+0x42>
  }
  return setpriority(priority, pid);
    800033ba:	fec42583          	lw	a1,-20(s0)
    800033be:	fe842503          	lw	a0,-24(s0)
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	464080e7          	jalr	1124(ra) # 80002826 <setpriority>
    800033ca:	87aa                	mv	a5,a0
    800033cc:	853e                	mv	a0,a5
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	e052                	sd	s4,0(sp)
    800033e4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033e6:	00005597          	auipc	a1,0x5
    800033ea:	26258593          	addi	a1,a1,610 # 80008648 <syscalls+0xd8>
    800033ee:	00015517          	auipc	a0,0x15
    800033f2:	3fa50513          	addi	a0,a0,1018 # 800187e8 <bcache>
    800033f6:	ffffd097          	auipc	ra,0xffffd
    800033fa:	764080e7          	jalr	1892(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033fe:	0001d797          	auipc	a5,0x1d
    80003402:	3ea78793          	addi	a5,a5,1002 # 800207e8 <bcache+0x8000>
    80003406:	0001d717          	auipc	a4,0x1d
    8000340a:	64a70713          	addi	a4,a4,1610 # 80020a50 <bcache+0x8268>
    8000340e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003412:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003416:	00015497          	auipc	s1,0x15
    8000341a:	3ea48493          	addi	s1,s1,1002 # 80018800 <bcache+0x18>
    b->next = bcache.head.next;
    8000341e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003420:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003422:	00005a17          	auipc	s4,0x5
    80003426:	22ea0a13          	addi	s4,s4,558 # 80008650 <syscalls+0xe0>
    b->next = bcache.head.next;
    8000342a:	2b893783          	ld	a5,696(s2)
    8000342e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003430:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003434:	85d2                	mv	a1,s4
    80003436:	01048513          	addi	a0,s1,16
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	4c4080e7          	jalr	1220(ra) # 800048fe <initsleeplock>
    bcache.head.next->prev = b;
    80003442:	2b893783          	ld	a5,696(s2)
    80003446:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003448:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000344c:	45848493          	addi	s1,s1,1112
    80003450:	fd349de3          	bne	s1,s3,8000342a <binit+0x54>
  }
}
    80003454:	70a2                	ld	ra,40(sp)
    80003456:	7402                	ld	s0,32(sp)
    80003458:	64e2                	ld	s1,24(sp)
    8000345a:	6942                	ld	s2,16(sp)
    8000345c:	69a2                	ld	s3,8(sp)
    8000345e:	6a02                	ld	s4,0(sp)
    80003460:	6145                	addi	sp,sp,48
    80003462:	8082                	ret

0000000080003464 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003464:	7179                	addi	sp,sp,-48
    80003466:	f406                	sd	ra,40(sp)
    80003468:	f022                	sd	s0,32(sp)
    8000346a:	ec26                	sd	s1,24(sp)
    8000346c:	e84a                	sd	s2,16(sp)
    8000346e:	e44e                	sd	s3,8(sp)
    80003470:	1800                	addi	s0,sp,48
    80003472:	89aa                	mv	s3,a0
    80003474:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003476:	00015517          	auipc	a0,0x15
    8000347a:	37250513          	addi	a0,a0,882 # 800187e8 <bcache>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	76c080e7          	jalr	1900(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003486:	0001d497          	auipc	s1,0x1d
    8000348a:	61a4b483          	ld	s1,1562(s1) # 80020aa0 <bcache+0x82b8>
    8000348e:	0001d797          	auipc	a5,0x1d
    80003492:	5c278793          	addi	a5,a5,1474 # 80020a50 <bcache+0x8268>
    80003496:	02f48f63          	beq	s1,a5,800034d4 <bread+0x70>
    8000349a:	873e                	mv	a4,a5
    8000349c:	a021                	j	800034a4 <bread+0x40>
    8000349e:	68a4                	ld	s1,80(s1)
    800034a0:	02e48a63          	beq	s1,a4,800034d4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034a4:	449c                	lw	a5,8(s1)
    800034a6:	ff379ce3          	bne	a5,s3,8000349e <bread+0x3a>
    800034aa:	44dc                	lw	a5,12(s1)
    800034ac:	ff2799e3          	bne	a5,s2,8000349e <bread+0x3a>
      b->refcnt++;
    800034b0:	40bc                	lw	a5,64(s1)
    800034b2:	2785                	addiw	a5,a5,1
    800034b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034b6:	00015517          	auipc	a0,0x15
    800034ba:	33250513          	addi	a0,a0,818 # 800187e8 <bcache>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	7e0080e7          	jalr	2016(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800034c6:	01048513          	addi	a0,s1,16
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	46e080e7          	jalr	1134(ra) # 80004938 <acquiresleep>
      return b;
    800034d2:	a8b9                	j	80003530 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034d4:	0001d497          	auipc	s1,0x1d
    800034d8:	5c44b483          	ld	s1,1476(s1) # 80020a98 <bcache+0x82b0>
    800034dc:	0001d797          	auipc	a5,0x1d
    800034e0:	57478793          	addi	a5,a5,1396 # 80020a50 <bcache+0x8268>
    800034e4:	00f48863          	beq	s1,a5,800034f4 <bread+0x90>
    800034e8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034ea:	40bc                	lw	a5,64(s1)
    800034ec:	cf81                	beqz	a5,80003504 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034ee:	64a4                	ld	s1,72(s1)
    800034f0:	fee49de3          	bne	s1,a4,800034ea <bread+0x86>
  panic("bget: no buffers");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	16450513          	addi	a0,a0,356 # 80008658 <syscalls+0xe8>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	048080e7          	jalr	72(ra) # 80000544 <panic>
      b->dev = dev;
    80003504:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003508:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000350c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003510:	4785                	li	a5,1
    80003512:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003514:	00015517          	auipc	a0,0x15
    80003518:	2d450513          	addi	a0,a0,724 # 800187e8 <bcache>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	782080e7          	jalr	1922(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003524:	01048513          	addi	a0,s1,16
    80003528:	00001097          	auipc	ra,0x1
    8000352c:	410080e7          	jalr	1040(ra) # 80004938 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003530:	409c                	lw	a5,0(s1)
    80003532:	cb89                	beqz	a5,80003544 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003534:	8526                	mv	a0,s1
    80003536:	70a2                	ld	ra,40(sp)
    80003538:	7402                	ld	s0,32(sp)
    8000353a:	64e2                	ld	s1,24(sp)
    8000353c:	6942                	ld	s2,16(sp)
    8000353e:	69a2                	ld	s3,8(sp)
    80003540:	6145                	addi	sp,sp,48
    80003542:	8082                	ret
    virtio_disk_rw(b, 0);
    80003544:	4581                	li	a1,0
    80003546:	8526                	mv	a0,s1
    80003548:	00003097          	auipc	ra,0x3
    8000354c:	fd0080e7          	jalr	-48(ra) # 80006518 <virtio_disk_rw>
    b->valid = 1;
    80003550:	4785                	li	a5,1
    80003552:	c09c                	sw	a5,0(s1)
  return b;
    80003554:	b7c5                	j	80003534 <bread+0xd0>

0000000080003556 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003556:	1101                	addi	sp,sp,-32
    80003558:	ec06                	sd	ra,24(sp)
    8000355a:	e822                	sd	s0,16(sp)
    8000355c:	e426                	sd	s1,8(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003562:	0541                	addi	a0,a0,16
    80003564:	00001097          	auipc	ra,0x1
    80003568:	46e080e7          	jalr	1134(ra) # 800049d2 <holdingsleep>
    8000356c:	cd01                	beqz	a0,80003584 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000356e:	4585                	li	a1,1
    80003570:	8526                	mv	a0,s1
    80003572:	00003097          	auipc	ra,0x3
    80003576:	fa6080e7          	jalr	-90(ra) # 80006518 <virtio_disk_rw>
}
    8000357a:	60e2                	ld	ra,24(sp)
    8000357c:	6442                	ld	s0,16(sp)
    8000357e:	64a2                	ld	s1,8(sp)
    80003580:	6105                	addi	sp,sp,32
    80003582:	8082                	ret
    panic("bwrite");
    80003584:	00005517          	auipc	a0,0x5
    80003588:	0ec50513          	addi	a0,a0,236 # 80008670 <syscalls+0x100>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	fb8080e7          	jalr	-72(ra) # 80000544 <panic>

0000000080003594 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003594:	1101                	addi	sp,sp,-32
    80003596:	ec06                	sd	ra,24(sp)
    80003598:	e822                	sd	s0,16(sp)
    8000359a:	e426                	sd	s1,8(sp)
    8000359c:	e04a                	sd	s2,0(sp)
    8000359e:	1000                	addi	s0,sp,32
    800035a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035a2:	01050913          	addi	s2,a0,16
    800035a6:	854a                	mv	a0,s2
    800035a8:	00001097          	auipc	ra,0x1
    800035ac:	42a080e7          	jalr	1066(ra) # 800049d2 <holdingsleep>
    800035b0:	c92d                	beqz	a0,80003622 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	3da080e7          	jalr	986(ra) # 8000498e <releasesleep>

  acquire(&bcache.lock);
    800035bc:	00015517          	auipc	a0,0x15
    800035c0:	22c50513          	addi	a0,a0,556 # 800187e8 <bcache>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	626080e7          	jalr	1574(ra) # 80000bea <acquire>
  b->refcnt--;
    800035cc:	40bc                	lw	a5,64(s1)
    800035ce:	37fd                	addiw	a5,a5,-1
    800035d0:	0007871b          	sext.w	a4,a5
    800035d4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035d6:	eb05                	bnez	a4,80003606 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035d8:	68bc                	ld	a5,80(s1)
    800035da:	64b8                	ld	a4,72(s1)
    800035dc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035de:	64bc                	ld	a5,72(s1)
    800035e0:	68b8                	ld	a4,80(s1)
    800035e2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035e4:	0001d797          	auipc	a5,0x1d
    800035e8:	20478793          	addi	a5,a5,516 # 800207e8 <bcache+0x8000>
    800035ec:	2b87b703          	ld	a4,696(a5)
    800035f0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035f2:	0001d717          	auipc	a4,0x1d
    800035f6:	45e70713          	addi	a4,a4,1118 # 80020a50 <bcache+0x8268>
    800035fa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035fc:	2b87b703          	ld	a4,696(a5)
    80003600:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003602:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003606:	00015517          	auipc	a0,0x15
    8000360a:	1e250513          	addi	a0,a0,482 # 800187e8 <bcache>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	690080e7          	jalr	1680(ra) # 80000c9e <release>
}
    80003616:	60e2                	ld	ra,24(sp)
    80003618:	6442                	ld	s0,16(sp)
    8000361a:	64a2                	ld	s1,8(sp)
    8000361c:	6902                	ld	s2,0(sp)
    8000361e:	6105                	addi	sp,sp,32
    80003620:	8082                	ret
    panic("brelse");
    80003622:	00005517          	auipc	a0,0x5
    80003626:	05650513          	addi	a0,a0,86 # 80008678 <syscalls+0x108>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	f1a080e7          	jalr	-230(ra) # 80000544 <panic>

0000000080003632 <bpin>:

void
bpin(struct buf *b) {
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	e426                	sd	s1,8(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000363e:	00015517          	auipc	a0,0x15
    80003642:	1aa50513          	addi	a0,a0,426 # 800187e8 <bcache>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	5a4080e7          	jalr	1444(ra) # 80000bea <acquire>
  b->refcnt++;
    8000364e:	40bc                	lw	a5,64(s1)
    80003650:	2785                	addiw	a5,a5,1
    80003652:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003654:	00015517          	auipc	a0,0x15
    80003658:	19450513          	addi	a0,a0,404 # 800187e8 <bcache>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	642080e7          	jalr	1602(ra) # 80000c9e <release>
}
    80003664:	60e2                	ld	ra,24(sp)
    80003666:	6442                	ld	s0,16(sp)
    80003668:	64a2                	ld	s1,8(sp)
    8000366a:	6105                	addi	sp,sp,32
    8000366c:	8082                	ret

000000008000366e <bunpin>:

void
bunpin(struct buf *b) {
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	1000                	addi	s0,sp,32
    80003678:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000367a:	00015517          	auipc	a0,0x15
    8000367e:	16e50513          	addi	a0,a0,366 # 800187e8 <bcache>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	568080e7          	jalr	1384(ra) # 80000bea <acquire>
  b->refcnt--;
    8000368a:	40bc                	lw	a5,64(s1)
    8000368c:	37fd                	addiw	a5,a5,-1
    8000368e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003690:	00015517          	auipc	a0,0x15
    80003694:	15850513          	addi	a0,a0,344 # 800187e8 <bcache>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	606080e7          	jalr	1542(ra) # 80000c9e <release>
}
    800036a0:	60e2                	ld	ra,24(sp)
    800036a2:	6442                	ld	s0,16(sp)
    800036a4:	64a2                	ld	s1,8(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret

00000000800036aa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	e04a                	sd	s2,0(sp)
    800036b4:	1000                	addi	s0,sp,32
    800036b6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036b8:	00d5d59b          	srliw	a1,a1,0xd
    800036bc:	0001e797          	auipc	a5,0x1e
    800036c0:	8087a783          	lw	a5,-2040(a5) # 80020ec4 <sb+0x1c>
    800036c4:	9dbd                	addw	a1,a1,a5
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	d9e080e7          	jalr	-610(ra) # 80003464 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036ce:	0074f713          	andi	a4,s1,7
    800036d2:	4785                	li	a5,1
    800036d4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036d8:	14ce                	slli	s1,s1,0x33
    800036da:	90d9                	srli	s1,s1,0x36
    800036dc:	00950733          	add	a4,a0,s1
    800036e0:	05874703          	lbu	a4,88(a4)
    800036e4:	00e7f6b3          	and	a3,a5,a4
    800036e8:	c69d                	beqz	a3,80003716 <bfree+0x6c>
    800036ea:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036ec:	94aa                	add	s1,s1,a0
    800036ee:	fff7c793          	not	a5,a5
    800036f2:	8ff9                	and	a5,a5,a4
    800036f4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	120080e7          	jalr	288(ra) # 80004818 <log_write>
  brelse(bp);
    80003700:	854a                	mv	a0,s2
    80003702:	00000097          	auipc	ra,0x0
    80003706:	e92080e7          	jalr	-366(ra) # 80003594 <brelse>
}
    8000370a:	60e2                	ld	ra,24(sp)
    8000370c:	6442                	ld	s0,16(sp)
    8000370e:	64a2                	ld	s1,8(sp)
    80003710:	6902                	ld	s2,0(sp)
    80003712:	6105                	addi	sp,sp,32
    80003714:	8082                	ret
    panic("freeing free block");
    80003716:	00005517          	auipc	a0,0x5
    8000371a:	f6a50513          	addi	a0,a0,-150 # 80008680 <syscalls+0x110>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	e26080e7          	jalr	-474(ra) # 80000544 <panic>

0000000080003726 <balloc>:
{
    80003726:	711d                	addi	sp,sp,-96
    80003728:	ec86                	sd	ra,88(sp)
    8000372a:	e8a2                	sd	s0,80(sp)
    8000372c:	e4a6                	sd	s1,72(sp)
    8000372e:	e0ca                	sd	s2,64(sp)
    80003730:	fc4e                	sd	s3,56(sp)
    80003732:	f852                	sd	s4,48(sp)
    80003734:	f456                	sd	s5,40(sp)
    80003736:	f05a                	sd	s6,32(sp)
    80003738:	ec5e                	sd	s7,24(sp)
    8000373a:	e862                	sd	s8,16(sp)
    8000373c:	e466                	sd	s9,8(sp)
    8000373e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003740:	0001d797          	auipc	a5,0x1d
    80003744:	76c7a783          	lw	a5,1900(a5) # 80020eac <sb+0x4>
    80003748:	10078163          	beqz	a5,8000384a <balloc+0x124>
    8000374c:	8baa                	mv	s7,a0
    8000374e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003750:	0001db17          	auipc	s6,0x1d
    80003754:	758b0b13          	addi	s6,s6,1880 # 80020ea8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003758:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000375a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000375c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000375e:	6c89                	lui	s9,0x2
    80003760:	a061                	j	800037e8 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003762:	974a                	add	a4,a4,s2
    80003764:	8fd5                	or	a5,a5,a3
    80003766:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000376a:	854a                	mv	a0,s2
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	0ac080e7          	jalr	172(ra) # 80004818 <log_write>
        brelse(bp);
    80003774:	854a                	mv	a0,s2
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	e1e080e7          	jalr	-482(ra) # 80003594 <brelse>
  bp = bread(dev, bno);
    8000377e:	85a6                	mv	a1,s1
    80003780:	855e                	mv	a0,s7
    80003782:	00000097          	auipc	ra,0x0
    80003786:	ce2080e7          	jalr	-798(ra) # 80003464 <bread>
    8000378a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000378c:	40000613          	li	a2,1024
    80003790:	4581                	li	a1,0
    80003792:	05850513          	addi	a0,a0,88
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	550080e7          	jalr	1360(ra) # 80000ce6 <memset>
  log_write(bp);
    8000379e:	854a                	mv	a0,s2
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	078080e7          	jalr	120(ra) # 80004818 <log_write>
  brelse(bp);
    800037a8:	854a                	mv	a0,s2
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	dea080e7          	jalr	-534(ra) # 80003594 <brelse>
}
    800037b2:	8526                	mv	a0,s1
    800037b4:	60e6                	ld	ra,88(sp)
    800037b6:	6446                	ld	s0,80(sp)
    800037b8:	64a6                	ld	s1,72(sp)
    800037ba:	6906                	ld	s2,64(sp)
    800037bc:	79e2                	ld	s3,56(sp)
    800037be:	7a42                	ld	s4,48(sp)
    800037c0:	7aa2                	ld	s5,40(sp)
    800037c2:	7b02                	ld	s6,32(sp)
    800037c4:	6be2                	ld	s7,24(sp)
    800037c6:	6c42                	ld	s8,16(sp)
    800037c8:	6ca2                	ld	s9,8(sp)
    800037ca:	6125                	addi	sp,sp,96
    800037cc:	8082                	ret
    brelse(bp);
    800037ce:	854a                	mv	a0,s2
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	dc4080e7          	jalr	-572(ra) # 80003594 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037d8:	015c87bb          	addw	a5,s9,s5
    800037dc:	00078a9b          	sext.w	s5,a5
    800037e0:	004b2703          	lw	a4,4(s6)
    800037e4:	06eaf363          	bgeu	s5,a4,8000384a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800037e8:	41fad79b          	sraiw	a5,s5,0x1f
    800037ec:	0137d79b          	srliw	a5,a5,0x13
    800037f0:	015787bb          	addw	a5,a5,s5
    800037f4:	40d7d79b          	sraiw	a5,a5,0xd
    800037f8:	01cb2583          	lw	a1,28(s6)
    800037fc:	9dbd                	addw	a1,a1,a5
    800037fe:	855e                	mv	a0,s7
    80003800:	00000097          	auipc	ra,0x0
    80003804:	c64080e7          	jalr	-924(ra) # 80003464 <bread>
    80003808:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000380a:	004b2503          	lw	a0,4(s6)
    8000380e:	000a849b          	sext.w	s1,s5
    80003812:	8662                	mv	a2,s8
    80003814:	faa4fde3          	bgeu	s1,a0,800037ce <balloc+0xa8>
      m = 1 << (bi % 8);
    80003818:	41f6579b          	sraiw	a5,a2,0x1f
    8000381c:	01d7d69b          	srliw	a3,a5,0x1d
    80003820:	00c6873b          	addw	a4,a3,a2
    80003824:	00777793          	andi	a5,a4,7
    80003828:	9f95                	subw	a5,a5,a3
    8000382a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000382e:	4037571b          	sraiw	a4,a4,0x3
    80003832:	00e906b3          	add	a3,s2,a4
    80003836:	0586c683          	lbu	a3,88(a3)
    8000383a:	00d7f5b3          	and	a1,a5,a3
    8000383e:	d195                	beqz	a1,80003762 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003840:	2605                	addiw	a2,a2,1
    80003842:	2485                	addiw	s1,s1,1
    80003844:	fd4618e3          	bne	a2,s4,80003814 <balloc+0xee>
    80003848:	b759                	j	800037ce <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	e4e50513          	addi	a0,a0,-434 # 80008698 <syscalls+0x128>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	d3c080e7          	jalr	-708(ra) # 8000058e <printf>
  return 0;
    8000385a:	4481                	li	s1,0
    8000385c:	bf99                	j	800037b2 <balloc+0x8c>

000000008000385e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000385e:	7179                	addi	sp,sp,-48
    80003860:	f406                	sd	ra,40(sp)
    80003862:	f022                	sd	s0,32(sp)
    80003864:	ec26                	sd	s1,24(sp)
    80003866:	e84a                	sd	s2,16(sp)
    80003868:	e44e                	sd	s3,8(sp)
    8000386a:	e052                	sd	s4,0(sp)
    8000386c:	1800                	addi	s0,sp,48
    8000386e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003870:	47ad                	li	a5,11
    80003872:	02b7e763          	bltu	a5,a1,800038a0 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003876:	02059493          	slli	s1,a1,0x20
    8000387a:	9081                	srli	s1,s1,0x20
    8000387c:	048a                	slli	s1,s1,0x2
    8000387e:	94aa                	add	s1,s1,a0
    80003880:	0504a903          	lw	s2,80(s1)
    80003884:	06091e63          	bnez	s2,80003900 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003888:	4108                	lw	a0,0(a0)
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	e9c080e7          	jalr	-356(ra) # 80003726 <balloc>
    80003892:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003896:	06090563          	beqz	s2,80003900 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000389a:	0524a823          	sw	s2,80(s1)
    8000389e:	a08d                	j	80003900 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800038a0:	ff45849b          	addiw	s1,a1,-12
    800038a4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038a8:	0ff00793          	li	a5,255
    800038ac:	08e7e563          	bltu	a5,a4,80003936 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800038b0:	08052903          	lw	s2,128(a0)
    800038b4:	00091d63          	bnez	s2,800038ce <bmap+0x70>
      addr = balloc(ip->dev);
    800038b8:	4108                	lw	a0,0(a0)
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e6c080e7          	jalr	-404(ra) # 80003726 <balloc>
    800038c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038c6:	02090d63          	beqz	s2,80003900 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038ca:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038ce:	85ca                	mv	a1,s2
    800038d0:	0009a503          	lw	a0,0(s3)
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	b90080e7          	jalr	-1136(ra) # 80003464 <bread>
    800038dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038e2:	02049593          	slli	a1,s1,0x20
    800038e6:	9181                	srli	a1,a1,0x20
    800038e8:	058a                	slli	a1,a1,0x2
    800038ea:	00b784b3          	add	s1,a5,a1
    800038ee:	0004a903          	lw	s2,0(s1)
    800038f2:	02090063          	beqz	s2,80003912 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038f6:	8552                	mv	a0,s4
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	c9c080e7          	jalr	-868(ra) # 80003594 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003900:	854a                	mv	a0,s2
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6a02                	ld	s4,0(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret
      addr = balloc(ip->dev);
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	e10080e7          	jalr	-496(ra) # 80003726 <balloc>
    8000391e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003922:	fc090ae3          	beqz	s2,800038f6 <bmap+0x98>
        a[bn] = addr;
    80003926:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000392a:	8552                	mv	a0,s4
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	eec080e7          	jalr	-276(ra) # 80004818 <log_write>
    80003934:	b7c9                	j	800038f6 <bmap+0x98>
  panic("bmap: out of range");
    80003936:	00005517          	auipc	a0,0x5
    8000393a:	d7a50513          	addi	a0,a0,-646 # 800086b0 <syscalls+0x140>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	c06080e7          	jalr	-1018(ra) # 80000544 <panic>

0000000080003946 <iget>:
{
    80003946:	7179                	addi	sp,sp,-48
    80003948:	f406                	sd	ra,40(sp)
    8000394a:	f022                	sd	s0,32(sp)
    8000394c:	ec26                	sd	s1,24(sp)
    8000394e:	e84a                	sd	s2,16(sp)
    80003950:	e44e                	sd	s3,8(sp)
    80003952:	e052                	sd	s4,0(sp)
    80003954:	1800                	addi	s0,sp,48
    80003956:	89aa                	mv	s3,a0
    80003958:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000395a:	0001d517          	auipc	a0,0x1d
    8000395e:	56e50513          	addi	a0,a0,1390 # 80020ec8 <itable>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	288080e7          	jalr	648(ra) # 80000bea <acquire>
  empty = 0;
    8000396a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000396c:	0001d497          	auipc	s1,0x1d
    80003970:	57448493          	addi	s1,s1,1396 # 80020ee0 <itable+0x18>
    80003974:	0001f697          	auipc	a3,0x1f
    80003978:	ffc68693          	addi	a3,a3,-4 # 80022970 <log>
    8000397c:	a039                	j	8000398a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000397e:	02090b63          	beqz	s2,800039b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003982:	08848493          	addi	s1,s1,136
    80003986:	02d48a63          	beq	s1,a3,800039ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000398a:	449c                	lw	a5,8(s1)
    8000398c:	fef059e3          	blez	a5,8000397e <iget+0x38>
    80003990:	4098                	lw	a4,0(s1)
    80003992:	ff3716e3          	bne	a4,s3,8000397e <iget+0x38>
    80003996:	40d8                	lw	a4,4(s1)
    80003998:	ff4713e3          	bne	a4,s4,8000397e <iget+0x38>
      ip->ref++;
    8000399c:	2785                	addiw	a5,a5,1
    8000399e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039a0:	0001d517          	auipc	a0,0x1d
    800039a4:	52850513          	addi	a0,a0,1320 # 80020ec8 <itable>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	2f6080e7          	jalr	758(ra) # 80000c9e <release>
      return ip;
    800039b0:	8926                	mv	s2,s1
    800039b2:	a03d                	j	800039e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039b4:	f7f9                	bnez	a5,80003982 <iget+0x3c>
    800039b6:	8926                	mv	s2,s1
    800039b8:	b7e9                	j	80003982 <iget+0x3c>
  if(empty == 0)
    800039ba:	02090c63          	beqz	s2,800039f2 <iget+0xac>
  ip->dev = dev;
    800039be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039c6:	4785                	li	a5,1
    800039c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039d0:	0001d517          	auipc	a0,0x1d
    800039d4:	4f850513          	addi	a0,a0,1272 # 80020ec8 <itable>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2c6080e7          	jalr	710(ra) # 80000c9e <release>
}
    800039e0:	854a                	mv	a0,s2
    800039e2:	70a2                	ld	ra,40(sp)
    800039e4:	7402                	ld	s0,32(sp)
    800039e6:	64e2                	ld	s1,24(sp)
    800039e8:	6942                	ld	s2,16(sp)
    800039ea:	69a2                	ld	s3,8(sp)
    800039ec:	6a02                	ld	s4,0(sp)
    800039ee:	6145                	addi	sp,sp,48
    800039f0:	8082                	ret
    panic("iget: no inodes");
    800039f2:	00005517          	auipc	a0,0x5
    800039f6:	cd650513          	addi	a0,a0,-810 # 800086c8 <syscalls+0x158>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	b4a080e7          	jalr	-1206(ra) # 80000544 <panic>

0000000080003a02 <fsinit>:
fsinit(int dev) {
    80003a02:	7179                	addi	sp,sp,-48
    80003a04:	f406                	sd	ra,40(sp)
    80003a06:	f022                	sd	s0,32(sp)
    80003a08:	ec26                	sd	s1,24(sp)
    80003a0a:	e84a                	sd	s2,16(sp)
    80003a0c:	e44e                	sd	s3,8(sp)
    80003a0e:	1800                	addi	s0,sp,48
    80003a10:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a12:	4585                	li	a1,1
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	a50080e7          	jalr	-1456(ra) # 80003464 <bread>
    80003a1c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a1e:	0001d997          	auipc	s3,0x1d
    80003a22:	48a98993          	addi	s3,s3,1162 # 80020ea8 <sb>
    80003a26:	02000613          	li	a2,32
    80003a2a:	05850593          	addi	a1,a0,88
    80003a2e:	854e                	mv	a0,s3
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	316080e7          	jalr	790(ra) # 80000d46 <memmove>
  brelse(bp);
    80003a38:	8526                	mv	a0,s1
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	b5a080e7          	jalr	-1190(ra) # 80003594 <brelse>
  if(sb.magic != FSMAGIC)
    80003a42:	0009a703          	lw	a4,0(s3)
    80003a46:	102037b7          	lui	a5,0x10203
    80003a4a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a4e:	02f71263          	bne	a4,a5,80003a72 <fsinit+0x70>
  initlog(dev, &sb);
    80003a52:	0001d597          	auipc	a1,0x1d
    80003a56:	45658593          	addi	a1,a1,1110 # 80020ea8 <sb>
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00001097          	auipc	ra,0x1
    80003a60:	b40080e7          	jalr	-1216(ra) # 8000459c <initlog>
}
    80003a64:	70a2                	ld	ra,40(sp)
    80003a66:	7402                	ld	s0,32(sp)
    80003a68:	64e2                	ld	s1,24(sp)
    80003a6a:	6942                	ld	s2,16(sp)
    80003a6c:	69a2                	ld	s3,8(sp)
    80003a6e:	6145                	addi	sp,sp,48
    80003a70:	8082                	ret
    panic("invalid file system");
    80003a72:	00005517          	auipc	a0,0x5
    80003a76:	c6650513          	addi	a0,a0,-922 # 800086d8 <syscalls+0x168>
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	aca080e7          	jalr	-1334(ra) # 80000544 <panic>

0000000080003a82 <iinit>:
{
    80003a82:	7179                	addi	sp,sp,-48
    80003a84:	f406                	sd	ra,40(sp)
    80003a86:	f022                	sd	s0,32(sp)
    80003a88:	ec26                	sd	s1,24(sp)
    80003a8a:	e84a                	sd	s2,16(sp)
    80003a8c:	e44e                	sd	s3,8(sp)
    80003a8e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a90:	00005597          	auipc	a1,0x5
    80003a94:	c6058593          	addi	a1,a1,-928 # 800086f0 <syscalls+0x180>
    80003a98:	0001d517          	auipc	a0,0x1d
    80003a9c:	43050513          	addi	a0,a0,1072 # 80020ec8 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	0ba080e7          	jalr	186(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003aa8:	0001d497          	auipc	s1,0x1d
    80003aac:	44848493          	addi	s1,s1,1096 # 80020ef0 <itable+0x28>
    80003ab0:	0001f997          	auipc	s3,0x1f
    80003ab4:	ed098993          	addi	s3,s3,-304 # 80022980 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ab8:	00005917          	auipc	s2,0x5
    80003abc:	c4090913          	addi	s2,s2,-960 # 800086f8 <syscalls+0x188>
    80003ac0:	85ca                	mv	a1,s2
    80003ac2:	8526                	mv	a0,s1
    80003ac4:	00001097          	auipc	ra,0x1
    80003ac8:	e3a080e7          	jalr	-454(ra) # 800048fe <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003acc:	08848493          	addi	s1,s1,136
    80003ad0:	ff3498e3          	bne	s1,s3,80003ac0 <iinit+0x3e>
}
    80003ad4:	70a2                	ld	ra,40(sp)
    80003ad6:	7402                	ld	s0,32(sp)
    80003ad8:	64e2                	ld	s1,24(sp)
    80003ada:	6942                	ld	s2,16(sp)
    80003adc:	69a2                	ld	s3,8(sp)
    80003ade:	6145                	addi	sp,sp,48
    80003ae0:	8082                	ret

0000000080003ae2 <ialloc>:
{
    80003ae2:	715d                	addi	sp,sp,-80
    80003ae4:	e486                	sd	ra,72(sp)
    80003ae6:	e0a2                	sd	s0,64(sp)
    80003ae8:	fc26                	sd	s1,56(sp)
    80003aea:	f84a                	sd	s2,48(sp)
    80003aec:	f44e                	sd	s3,40(sp)
    80003aee:	f052                	sd	s4,32(sp)
    80003af0:	ec56                	sd	s5,24(sp)
    80003af2:	e85a                	sd	s6,16(sp)
    80003af4:	e45e                	sd	s7,8(sp)
    80003af6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003af8:	0001d717          	auipc	a4,0x1d
    80003afc:	3bc72703          	lw	a4,956(a4) # 80020eb4 <sb+0xc>
    80003b00:	4785                	li	a5,1
    80003b02:	04e7fa63          	bgeu	a5,a4,80003b56 <ialloc+0x74>
    80003b06:	8aaa                	mv	s5,a0
    80003b08:	8bae                	mv	s7,a1
    80003b0a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b0c:	0001da17          	auipc	s4,0x1d
    80003b10:	39ca0a13          	addi	s4,s4,924 # 80020ea8 <sb>
    80003b14:	00048b1b          	sext.w	s6,s1
    80003b18:	0044d593          	srli	a1,s1,0x4
    80003b1c:	018a2783          	lw	a5,24(s4)
    80003b20:	9dbd                	addw	a1,a1,a5
    80003b22:	8556                	mv	a0,s5
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	940080e7          	jalr	-1728(ra) # 80003464 <bread>
    80003b2c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b2e:	05850993          	addi	s3,a0,88
    80003b32:	00f4f793          	andi	a5,s1,15
    80003b36:	079a                	slli	a5,a5,0x6
    80003b38:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b3a:	00099783          	lh	a5,0(s3)
    80003b3e:	c3a1                	beqz	a5,80003b7e <ialloc+0x9c>
    brelse(bp);
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	a54080e7          	jalr	-1452(ra) # 80003594 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b48:	0485                	addi	s1,s1,1
    80003b4a:	00ca2703          	lw	a4,12(s4)
    80003b4e:	0004879b          	sext.w	a5,s1
    80003b52:	fce7e1e3          	bltu	a5,a4,80003b14 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b56:	00005517          	auipc	a0,0x5
    80003b5a:	baa50513          	addi	a0,a0,-1110 # 80008700 <syscalls+0x190>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	a30080e7          	jalr	-1488(ra) # 8000058e <printf>
  return 0;
    80003b66:	4501                	li	a0,0
}
    80003b68:	60a6                	ld	ra,72(sp)
    80003b6a:	6406                	ld	s0,64(sp)
    80003b6c:	74e2                	ld	s1,56(sp)
    80003b6e:	7942                	ld	s2,48(sp)
    80003b70:	79a2                	ld	s3,40(sp)
    80003b72:	7a02                	ld	s4,32(sp)
    80003b74:	6ae2                	ld	s5,24(sp)
    80003b76:	6b42                	ld	s6,16(sp)
    80003b78:	6ba2                	ld	s7,8(sp)
    80003b7a:	6161                	addi	sp,sp,80
    80003b7c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b7e:	04000613          	li	a2,64
    80003b82:	4581                	li	a1,0
    80003b84:	854e                	mv	a0,s3
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	160080e7          	jalr	352(ra) # 80000ce6 <memset>
      dip->type = type;
    80003b8e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	c84080e7          	jalr	-892(ra) # 80004818 <log_write>
      brelse(bp);
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	9f6080e7          	jalr	-1546(ra) # 80003594 <brelse>
      return iget(dev, inum);
    80003ba6:	85da                	mv	a1,s6
    80003ba8:	8556                	mv	a0,s5
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	d9c080e7          	jalr	-612(ra) # 80003946 <iget>
    80003bb2:	bf5d                	j	80003b68 <ialloc+0x86>

0000000080003bb4 <iupdate>:
{
    80003bb4:	1101                	addi	sp,sp,-32
    80003bb6:	ec06                	sd	ra,24(sp)
    80003bb8:	e822                	sd	s0,16(sp)
    80003bba:	e426                	sd	s1,8(sp)
    80003bbc:	e04a                	sd	s2,0(sp)
    80003bbe:	1000                	addi	s0,sp,32
    80003bc0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bc2:	415c                	lw	a5,4(a0)
    80003bc4:	0047d79b          	srliw	a5,a5,0x4
    80003bc8:	0001d597          	auipc	a1,0x1d
    80003bcc:	2f85a583          	lw	a1,760(a1) # 80020ec0 <sb+0x18>
    80003bd0:	9dbd                	addw	a1,a1,a5
    80003bd2:	4108                	lw	a0,0(a0)
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	890080e7          	jalr	-1904(ra) # 80003464 <bread>
    80003bdc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bde:	05850793          	addi	a5,a0,88
    80003be2:	40c8                	lw	a0,4(s1)
    80003be4:	893d                	andi	a0,a0,15
    80003be6:	051a                	slli	a0,a0,0x6
    80003be8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bea:	04449703          	lh	a4,68(s1)
    80003bee:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bf2:	04649703          	lh	a4,70(s1)
    80003bf6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003bfa:	04849703          	lh	a4,72(s1)
    80003bfe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c02:	04a49703          	lh	a4,74(s1)
    80003c06:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c0a:	44f8                	lw	a4,76(s1)
    80003c0c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c0e:	03400613          	li	a2,52
    80003c12:	05048593          	addi	a1,s1,80
    80003c16:	0531                	addi	a0,a0,12
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	12e080e7          	jalr	302(ra) # 80000d46 <memmove>
  log_write(bp);
    80003c20:	854a                	mv	a0,s2
    80003c22:	00001097          	auipc	ra,0x1
    80003c26:	bf6080e7          	jalr	-1034(ra) # 80004818 <log_write>
  brelse(bp);
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	968080e7          	jalr	-1688(ra) # 80003594 <brelse>
}
    80003c34:	60e2                	ld	ra,24(sp)
    80003c36:	6442                	ld	s0,16(sp)
    80003c38:	64a2                	ld	s1,8(sp)
    80003c3a:	6902                	ld	s2,0(sp)
    80003c3c:	6105                	addi	sp,sp,32
    80003c3e:	8082                	ret

0000000080003c40 <idup>:
{
    80003c40:	1101                	addi	sp,sp,-32
    80003c42:	ec06                	sd	ra,24(sp)
    80003c44:	e822                	sd	s0,16(sp)
    80003c46:	e426                	sd	s1,8(sp)
    80003c48:	1000                	addi	s0,sp,32
    80003c4a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c4c:	0001d517          	auipc	a0,0x1d
    80003c50:	27c50513          	addi	a0,a0,636 # 80020ec8 <itable>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	f96080e7          	jalr	-106(ra) # 80000bea <acquire>
  ip->ref++;
    80003c5c:	449c                	lw	a5,8(s1)
    80003c5e:	2785                	addiw	a5,a5,1
    80003c60:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c62:	0001d517          	auipc	a0,0x1d
    80003c66:	26650513          	addi	a0,a0,614 # 80020ec8 <itable>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	034080e7          	jalr	52(ra) # 80000c9e <release>
}
    80003c72:	8526                	mv	a0,s1
    80003c74:	60e2                	ld	ra,24(sp)
    80003c76:	6442                	ld	s0,16(sp)
    80003c78:	64a2                	ld	s1,8(sp)
    80003c7a:	6105                	addi	sp,sp,32
    80003c7c:	8082                	ret

0000000080003c7e <ilock>:
{
    80003c7e:	1101                	addi	sp,sp,-32
    80003c80:	ec06                	sd	ra,24(sp)
    80003c82:	e822                	sd	s0,16(sp)
    80003c84:	e426                	sd	s1,8(sp)
    80003c86:	e04a                	sd	s2,0(sp)
    80003c88:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c8a:	c115                	beqz	a0,80003cae <ilock+0x30>
    80003c8c:	84aa                	mv	s1,a0
    80003c8e:	451c                	lw	a5,8(a0)
    80003c90:	00f05f63          	blez	a5,80003cae <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c94:	0541                	addi	a0,a0,16
    80003c96:	00001097          	auipc	ra,0x1
    80003c9a:	ca2080e7          	jalr	-862(ra) # 80004938 <acquiresleep>
  if(ip->valid == 0){
    80003c9e:	40bc                	lw	a5,64(s1)
    80003ca0:	cf99                	beqz	a5,80003cbe <ilock+0x40>
}
    80003ca2:	60e2                	ld	ra,24(sp)
    80003ca4:	6442                	ld	s0,16(sp)
    80003ca6:	64a2                	ld	s1,8(sp)
    80003ca8:	6902                	ld	s2,0(sp)
    80003caa:	6105                	addi	sp,sp,32
    80003cac:	8082                	ret
    panic("ilock");
    80003cae:	00005517          	auipc	a0,0x5
    80003cb2:	a6a50513          	addi	a0,a0,-1430 # 80008718 <syscalls+0x1a8>
    80003cb6:	ffffd097          	auipc	ra,0xffffd
    80003cba:	88e080e7          	jalr	-1906(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cbe:	40dc                	lw	a5,4(s1)
    80003cc0:	0047d79b          	srliw	a5,a5,0x4
    80003cc4:	0001d597          	auipc	a1,0x1d
    80003cc8:	1fc5a583          	lw	a1,508(a1) # 80020ec0 <sb+0x18>
    80003ccc:	9dbd                	addw	a1,a1,a5
    80003cce:	4088                	lw	a0,0(s1)
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	794080e7          	jalr	1940(ra) # 80003464 <bread>
    80003cd8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cda:	05850593          	addi	a1,a0,88
    80003cde:	40dc                	lw	a5,4(s1)
    80003ce0:	8bbd                	andi	a5,a5,15
    80003ce2:	079a                	slli	a5,a5,0x6
    80003ce4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ce6:	00059783          	lh	a5,0(a1)
    80003cea:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cee:	00259783          	lh	a5,2(a1)
    80003cf2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cf6:	00459783          	lh	a5,4(a1)
    80003cfa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cfe:	00659783          	lh	a5,6(a1)
    80003d02:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d06:	459c                	lw	a5,8(a1)
    80003d08:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d0a:	03400613          	li	a2,52
    80003d0e:	05b1                	addi	a1,a1,12
    80003d10:	05048513          	addi	a0,s1,80
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	032080e7          	jalr	50(ra) # 80000d46 <memmove>
    brelse(bp);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	876080e7          	jalr	-1930(ra) # 80003594 <brelse>
    ip->valid = 1;
    80003d26:	4785                	li	a5,1
    80003d28:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d2a:	04449783          	lh	a5,68(s1)
    80003d2e:	fbb5                	bnez	a5,80003ca2 <ilock+0x24>
      panic("ilock: no type");
    80003d30:	00005517          	auipc	a0,0x5
    80003d34:	9f050513          	addi	a0,a0,-1552 # 80008720 <syscalls+0x1b0>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	80c080e7          	jalr	-2036(ra) # 80000544 <panic>

0000000080003d40 <iunlock>:
{
    80003d40:	1101                	addi	sp,sp,-32
    80003d42:	ec06                	sd	ra,24(sp)
    80003d44:	e822                	sd	s0,16(sp)
    80003d46:	e426                	sd	s1,8(sp)
    80003d48:	e04a                	sd	s2,0(sp)
    80003d4a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d4c:	c905                	beqz	a0,80003d7c <iunlock+0x3c>
    80003d4e:	84aa                	mv	s1,a0
    80003d50:	01050913          	addi	s2,a0,16
    80003d54:	854a                	mv	a0,s2
    80003d56:	00001097          	auipc	ra,0x1
    80003d5a:	c7c080e7          	jalr	-900(ra) # 800049d2 <holdingsleep>
    80003d5e:	cd19                	beqz	a0,80003d7c <iunlock+0x3c>
    80003d60:	449c                	lw	a5,8(s1)
    80003d62:	00f05d63          	blez	a5,80003d7c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d66:	854a                	mv	a0,s2
    80003d68:	00001097          	auipc	ra,0x1
    80003d6c:	c26080e7          	jalr	-986(ra) # 8000498e <releasesleep>
}
    80003d70:	60e2                	ld	ra,24(sp)
    80003d72:	6442                	ld	s0,16(sp)
    80003d74:	64a2                	ld	s1,8(sp)
    80003d76:	6902                	ld	s2,0(sp)
    80003d78:	6105                	addi	sp,sp,32
    80003d7a:	8082                	ret
    panic("iunlock");
    80003d7c:	00005517          	auipc	a0,0x5
    80003d80:	9b450513          	addi	a0,a0,-1612 # 80008730 <syscalls+0x1c0>
    80003d84:	ffffc097          	auipc	ra,0xffffc
    80003d88:	7c0080e7          	jalr	1984(ra) # 80000544 <panic>

0000000080003d8c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d8c:	7179                	addi	sp,sp,-48
    80003d8e:	f406                	sd	ra,40(sp)
    80003d90:	f022                	sd	s0,32(sp)
    80003d92:	ec26                	sd	s1,24(sp)
    80003d94:	e84a                	sd	s2,16(sp)
    80003d96:	e44e                	sd	s3,8(sp)
    80003d98:	e052                	sd	s4,0(sp)
    80003d9a:	1800                	addi	s0,sp,48
    80003d9c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d9e:	05050493          	addi	s1,a0,80
    80003da2:	08050913          	addi	s2,a0,128
    80003da6:	a021                	j	80003dae <itrunc+0x22>
    80003da8:	0491                	addi	s1,s1,4
    80003daa:	01248d63          	beq	s1,s2,80003dc4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003dae:	408c                	lw	a1,0(s1)
    80003db0:	dde5                	beqz	a1,80003da8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003db2:	0009a503          	lw	a0,0(s3)
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	8f4080e7          	jalr	-1804(ra) # 800036aa <bfree>
      ip->addrs[i] = 0;
    80003dbe:	0004a023          	sw	zero,0(s1)
    80003dc2:	b7dd                	j	80003da8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dc4:	0809a583          	lw	a1,128(s3)
    80003dc8:	e185                	bnez	a1,80003de8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dca:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dce:	854e                	mv	a0,s3
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	de4080e7          	jalr	-540(ra) # 80003bb4 <iupdate>
}
    80003dd8:	70a2                	ld	ra,40(sp)
    80003dda:	7402                	ld	s0,32(sp)
    80003ddc:	64e2                	ld	s1,24(sp)
    80003dde:	6942                	ld	s2,16(sp)
    80003de0:	69a2                	ld	s3,8(sp)
    80003de2:	6a02                	ld	s4,0(sp)
    80003de4:	6145                	addi	sp,sp,48
    80003de6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003de8:	0009a503          	lw	a0,0(s3)
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	678080e7          	jalr	1656(ra) # 80003464 <bread>
    80003df4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003df6:	05850493          	addi	s1,a0,88
    80003dfa:	45850913          	addi	s2,a0,1112
    80003dfe:	a811                	j	80003e12 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e00:	0009a503          	lw	a0,0(s3)
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	8a6080e7          	jalr	-1882(ra) # 800036aa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e0c:	0491                	addi	s1,s1,4
    80003e0e:	01248563          	beq	s1,s2,80003e18 <itrunc+0x8c>
      if(a[j])
    80003e12:	408c                	lw	a1,0(s1)
    80003e14:	dde5                	beqz	a1,80003e0c <itrunc+0x80>
    80003e16:	b7ed                	j	80003e00 <itrunc+0x74>
    brelse(bp);
    80003e18:	8552                	mv	a0,s4
    80003e1a:	fffff097          	auipc	ra,0xfffff
    80003e1e:	77a080e7          	jalr	1914(ra) # 80003594 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e22:	0809a583          	lw	a1,128(s3)
    80003e26:	0009a503          	lw	a0,0(s3)
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	880080e7          	jalr	-1920(ra) # 800036aa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e32:	0809a023          	sw	zero,128(s3)
    80003e36:	bf51                	j	80003dca <itrunc+0x3e>

0000000080003e38 <iput>:
{
    80003e38:	1101                	addi	sp,sp,-32
    80003e3a:	ec06                	sd	ra,24(sp)
    80003e3c:	e822                	sd	s0,16(sp)
    80003e3e:	e426                	sd	s1,8(sp)
    80003e40:	e04a                	sd	s2,0(sp)
    80003e42:	1000                	addi	s0,sp,32
    80003e44:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e46:	0001d517          	auipc	a0,0x1d
    80003e4a:	08250513          	addi	a0,a0,130 # 80020ec8 <itable>
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	d9c080e7          	jalr	-612(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e56:	4498                	lw	a4,8(s1)
    80003e58:	4785                	li	a5,1
    80003e5a:	02f70363          	beq	a4,a5,80003e80 <iput+0x48>
  ip->ref--;
    80003e5e:	449c                	lw	a5,8(s1)
    80003e60:	37fd                	addiw	a5,a5,-1
    80003e62:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e64:	0001d517          	auipc	a0,0x1d
    80003e68:	06450513          	addi	a0,a0,100 # 80020ec8 <itable>
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	e32080e7          	jalr	-462(ra) # 80000c9e <release>
}
    80003e74:	60e2                	ld	ra,24(sp)
    80003e76:	6442                	ld	s0,16(sp)
    80003e78:	64a2                	ld	s1,8(sp)
    80003e7a:	6902                	ld	s2,0(sp)
    80003e7c:	6105                	addi	sp,sp,32
    80003e7e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e80:	40bc                	lw	a5,64(s1)
    80003e82:	dff1                	beqz	a5,80003e5e <iput+0x26>
    80003e84:	04a49783          	lh	a5,74(s1)
    80003e88:	fbf9                	bnez	a5,80003e5e <iput+0x26>
    acquiresleep(&ip->lock);
    80003e8a:	01048913          	addi	s2,s1,16
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00001097          	auipc	ra,0x1
    80003e94:	aa8080e7          	jalr	-1368(ra) # 80004938 <acquiresleep>
    release(&itable.lock);
    80003e98:	0001d517          	auipc	a0,0x1d
    80003e9c:	03050513          	addi	a0,a0,48 # 80020ec8 <itable>
    80003ea0:	ffffd097          	auipc	ra,0xffffd
    80003ea4:	dfe080e7          	jalr	-514(ra) # 80000c9e <release>
    itrunc(ip);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	ee2080e7          	jalr	-286(ra) # 80003d8c <itrunc>
    ip->type = 0;
    80003eb2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003eb6:	8526                	mv	a0,s1
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	cfc080e7          	jalr	-772(ra) # 80003bb4 <iupdate>
    ip->valid = 0;
    80003ec0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00001097          	auipc	ra,0x1
    80003eca:	ac8080e7          	jalr	-1336(ra) # 8000498e <releasesleep>
    acquire(&itable.lock);
    80003ece:	0001d517          	auipc	a0,0x1d
    80003ed2:	ffa50513          	addi	a0,a0,-6 # 80020ec8 <itable>
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	d14080e7          	jalr	-748(ra) # 80000bea <acquire>
    80003ede:	b741                	j	80003e5e <iput+0x26>

0000000080003ee0 <iunlockput>:
{
    80003ee0:	1101                	addi	sp,sp,-32
    80003ee2:	ec06                	sd	ra,24(sp)
    80003ee4:	e822                	sd	s0,16(sp)
    80003ee6:	e426                	sd	s1,8(sp)
    80003ee8:	1000                	addi	s0,sp,32
    80003eea:	84aa                	mv	s1,a0
  iunlock(ip);
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	e54080e7          	jalr	-428(ra) # 80003d40 <iunlock>
  iput(ip);
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	f42080e7          	jalr	-190(ra) # 80003e38 <iput>
}
    80003efe:	60e2                	ld	ra,24(sp)
    80003f00:	6442                	ld	s0,16(sp)
    80003f02:	64a2                	ld	s1,8(sp)
    80003f04:	6105                	addi	sp,sp,32
    80003f06:	8082                	ret

0000000080003f08 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f08:	1141                	addi	sp,sp,-16
    80003f0a:	e422                	sd	s0,8(sp)
    80003f0c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f0e:	411c                	lw	a5,0(a0)
    80003f10:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f12:	415c                	lw	a5,4(a0)
    80003f14:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f16:	04451783          	lh	a5,68(a0)
    80003f1a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f1e:	04a51783          	lh	a5,74(a0)
    80003f22:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f26:	04c56783          	lwu	a5,76(a0)
    80003f2a:	e99c                	sd	a5,16(a1)
}
    80003f2c:	6422                	ld	s0,8(sp)
    80003f2e:	0141                	addi	sp,sp,16
    80003f30:	8082                	ret

0000000080003f32 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f32:	457c                	lw	a5,76(a0)
    80003f34:	0ed7e963          	bltu	a5,a3,80004026 <readi+0xf4>
{
    80003f38:	7159                	addi	sp,sp,-112
    80003f3a:	f486                	sd	ra,104(sp)
    80003f3c:	f0a2                	sd	s0,96(sp)
    80003f3e:	eca6                	sd	s1,88(sp)
    80003f40:	e8ca                	sd	s2,80(sp)
    80003f42:	e4ce                	sd	s3,72(sp)
    80003f44:	e0d2                	sd	s4,64(sp)
    80003f46:	fc56                	sd	s5,56(sp)
    80003f48:	f85a                	sd	s6,48(sp)
    80003f4a:	f45e                	sd	s7,40(sp)
    80003f4c:	f062                	sd	s8,32(sp)
    80003f4e:	ec66                	sd	s9,24(sp)
    80003f50:	e86a                	sd	s10,16(sp)
    80003f52:	e46e                	sd	s11,8(sp)
    80003f54:	1880                	addi	s0,sp,112
    80003f56:	8b2a                	mv	s6,a0
    80003f58:	8bae                	mv	s7,a1
    80003f5a:	8a32                	mv	s4,a2
    80003f5c:	84b6                	mv	s1,a3
    80003f5e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f60:	9f35                	addw	a4,a4,a3
    return 0;
    80003f62:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f64:	0ad76063          	bltu	a4,a3,80004004 <readi+0xd2>
  if(off + n > ip->size)
    80003f68:	00e7f463          	bgeu	a5,a4,80003f70 <readi+0x3e>
    n = ip->size - off;
    80003f6c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f70:	0a0a8963          	beqz	s5,80004022 <readi+0xf0>
    80003f74:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f76:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f7a:	5c7d                	li	s8,-1
    80003f7c:	a82d                	j	80003fb6 <readi+0x84>
    80003f7e:	020d1d93          	slli	s11,s10,0x20
    80003f82:	020ddd93          	srli	s11,s11,0x20
    80003f86:	05890613          	addi	a2,s2,88
    80003f8a:	86ee                	mv	a3,s11
    80003f8c:	963a                	add	a2,a2,a4
    80003f8e:	85d2                	mv	a1,s4
    80003f90:	855e                	mv	a0,s7
    80003f92:	ffffe097          	auipc	ra,0xffffe
    80003f96:	73a080e7          	jalr	1850(ra) # 800026cc <either_copyout>
    80003f9a:	05850d63          	beq	a0,s8,80003ff4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	5f4080e7          	jalr	1524(ra) # 80003594 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fa8:	013d09bb          	addw	s3,s10,s3
    80003fac:	009d04bb          	addw	s1,s10,s1
    80003fb0:	9a6e                	add	s4,s4,s11
    80003fb2:	0559f763          	bgeu	s3,s5,80004000 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003fb6:	00a4d59b          	srliw	a1,s1,0xa
    80003fba:	855a                	mv	a0,s6
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	8a2080e7          	jalr	-1886(ra) # 8000385e <bmap>
    80003fc4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fc8:	cd85                	beqz	a1,80004000 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fca:	000b2503          	lw	a0,0(s6)
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	496080e7          	jalr	1174(ra) # 80003464 <bread>
    80003fd6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fd8:	3ff4f713          	andi	a4,s1,1023
    80003fdc:	40ec87bb          	subw	a5,s9,a4
    80003fe0:	413a86bb          	subw	a3,s5,s3
    80003fe4:	8d3e                	mv	s10,a5
    80003fe6:	2781                	sext.w	a5,a5
    80003fe8:	0006861b          	sext.w	a2,a3
    80003fec:	f8f679e3          	bgeu	a2,a5,80003f7e <readi+0x4c>
    80003ff0:	8d36                	mv	s10,a3
    80003ff2:	b771                	j	80003f7e <readi+0x4c>
      brelse(bp);
    80003ff4:	854a                	mv	a0,s2
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	59e080e7          	jalr	1438(ra) # 80003594 <brelse>
      tot = -1;
    80003ffe:	59fd                	li	s3,-1
  }
  return tot;
    80004000:	0009851b          	sext.w	a0,s3
}
    80004004:	70a6                	ld	ra,104(sp)
    80004006:	7406                	ld	s0,96(sp)
    80004008:	64e6                	ld	s1,88(sp)
    8000400a:	6946                	ld	s2,80(sp)
    8000400c:	69a6                	ld	s3,72(sp)
    8000400e:	6a06                	ld	s4,64(sp)
    80004010:	7ae2                	ld	s5,56(sp)
    80004012:	7b42                	ld	s6,48(sp)
    80004014:	7ba2                	ld	s7,40(sp)
    80004016:	7c02                	ld	s8,32(sp)
    80004018:	6ce2                	ld	s9,24(sp)
    8000401a:	6d42                	ld	s10,16(sp)
    8000401c:	6da2                	ld	s11,8(sp)
    8000401e:	6165                	addi	sp,sp,112
    80004020:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004022:	89d6                	mv	s3,s5
    80004024:	bff1                	j	80004000 <readi+0xce>
    return 0;
    80004026:	4501                	li	a0,0
}
    80004028:	8082                	ret

000000008000402a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000402a:	457c                	lw	a5,76(a0)
    8000402c:	10d7e863          	bltu	a5,a3,8000413c <writei+0x112>
{
    80004030:	7159                	addi	sp,sp,-112
    80004032:	f486                	sd	ra,104(sp)
    80004034:	f0a2                	sd	s0,96(sp)
    80004036:	eca6                	sd	s1,88(sp)
    80004038:	e8ca                	sd	s2,80(sp)
    8000403a:	e4ce                	sd	s3,72(sp)
    8000403c:	e0d2                	sd	s4,64(sp)
    8000403e:	fc56                	sd	s5,56(sp)
    80004040:	f85a                	sd	s6,48(sp)
    80004042:	f45e                	sd	s7,40(sp)
    80004044:	f062                	sd	s8,32(sp)
    80004046:	ec66                	sd	s9,24(sp)
    80004048:	e86a                	sd	s10,16(sp)
    8000404a:	e46e                	sd	s11,8(sp)
    8000404c:	1880                	addi	s0,sp,112
    8000404e:	8aaa                	mv	s5,a0
    80004050:	8bae                	mv	s7,a1
    80004052:	8a32                	mv	s4,a2
    80004054:	8936                	mv	s2,a3
    80004056:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004058:	00e687bb          	addw	a5,a3,a4
    8000405c:	0ed7e263          	bltu	a5,a3,80004140 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004060:	00043737          	lui	a4,0x43
    80004064:	0ef76063          	bltu	a4,a5,80004144 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004068:	0c0b0863          	beqz	s6,80004138 <writei+0x10e>
    8000406c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004072:	5c7d                	li	s8,-1
    80004074:	a091                	j	800040b8 <writei+0x8e>
    80004076:	020d1d93          	slli	s11,s10,0x20
    8000407a:	020ddd93          	srli	s11,s11,0x20
    8000407e:	05848513          	addi	a0,s1,88
    80004082:	86ee                	mv	a3,s11
    80004084:	8652                	mv	a2,s4
    80004086:	85de                	mv	a1,s7
    80004088:	953a                	add	a0,a0,a4
    8000408a:	ffffe097          	auipc	ra,0xffffe
    8000408e:	698080e7          	jalr	1688(ra) # 80002722 <either_copyin>
    80004092:	07850263          	beq	a0,s8,800040f6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004096:	8526                	mv	a0,s1
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	780080e7          	jalr	1920(ra) # 80004818 <log_write>
    brelse(bp);
    800040a0:	8526                	mv	a0,s1
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	4f2080e7          	jalr	1266(ra) # 80003594 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040aa:	013d09bb          	addw	s3,s10,s3
    800040ae:	012d093b          	addw	s2,s10,s2
    800040b2:	9a6e                	add	s4,s4,s11
    800040b4:	0569f663          	bgeu	s3,s6,80004100 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800040b8:	00a9559b          	srliw	a1,s2,0xa
    800040bc:	8556                	mv	a0,s5
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	7a0080e7          	jalr	1952(ra) # 8000385e <bmap>
    800040c6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040ca:	c99d                	beqz	a1,80004100 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040cc:	000aa503          	lw	a0,0(s5)
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	394080e7          	jalr	916(ra) # 80003464 <bread>
    800040d8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040da:	3ff97713          	andi	a4,s2,1023
    800040de:	40ec87bb          	subw	a5,s9,a4
    800040e2:	413b06bb          	subw	a3,s6,s3
    800040e6:	8d3e                	mv	s10,a5
    800040e8:	2781                	sext.w	a5,a5
    800040ea:	0006861b          	sext.w	a2,a3
    800040ee:	f8f674e3          	bgeu	a2,a5,80004076 <writei+0x4c>
    800040f2:	8d36                	mv	s10,a3
    800040f4:	b749                	j	80004076 <writei+0x4c>
      brelse(bp);
    800040f6:	8526                	mv	a0,s1
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	49c080e7          	jalr	1180(ra) # 80003594 <brelse>
  }

  if(off > ip->size)
    80004100:	04caa783          	lw	a5,76(s5)
    80004104:	0127f463          	bgeu	a5,s2,8000410c <writei+0xe2>
    ip->size = off;
    80004108:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000410c:	8556                	mv	a0,s5
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	aa6080e7          	jalr	-1370(ra) # 80003bb4 <iupdate>

  return tot;
    80004116:	0009851b          	sext.w	a0,s3
}
    8000411a:	70a6                	ld	ra,104(sp)
    8000411c:	7406                	ld	s0,96(sp)
    8000411e:	64e6                	ld	s1,88(sp)
    80004120:	6946                	ld	s2,80(sp)
    80004122:	69a6                	ld	s3,72(sp)
    80004124:	6a06                	ld	s4,64(sp)
    80004126:	7ae2                	ld	s5,56(sp)
    80004128:	7b42                	ld	s6,48(sp)
    8000412a:	7ba2                	ld	s7,40(sp)
    8000412c:	7c02                	ld	s8,32(sp)
    8000412e:	6ce2                	ld	s9,24(sp)
    80004130:	6d42                	ld	s10,16(sp)
    80004132:	6da2                	ld	s11,8(sp)
    80004134:	6165                	addi	sp,sp,112
    80004136:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004138:	89da                	mv	s3,s6
    8000413a:	bfc9                	j	8000410c <writei+0xe2>
    return -1;
    8000413c:	557d                	li	a0,-1
}
    8000413e:	8082                	ret
    return -1;
    80004140:	557d                	li	a0,-1
    80004142:	bfe1                	j	8000411a <writei+0xf0>
    return -1;
    80004144:	557d                	li	a0,-1
    80004146:	bfd1                	j	8000411a <writei+0xf0>

0000000080004148 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004148:	1141                	addi	sp,sp,-16
    8000414a:	e406                	sd	ra,8(sp)
    8000414c:	e022                	sd	s0,0(sp)
    8000414e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004150:	4639                	li	a2,14
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	c6c080e7          	jalr	-916(ra) # 80000dbe <strncmp>
}
    8000415a:	60a2                	ld	ra,8(sp)
    8000415c:	6402                	ld	s0,0(sp)
    8000415e:	0141                	addi	sp,sp,16
    80004160:	8082                	ret

0000000080004162 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004162:	7139                	addi	sp,sp,-64
    80004164:	fc06                	sd	ra,56(sp)
    80004166:	f822                	sd	s0,48(sp)
    80004168:	f426                	sd	s1,40(sp)
    8000416a:	f04a                	sd	s2,32(sp)
    8000416c:	ec4e                	sd	s3,24(sp)
    8000416e:	e852                	sd	s4,16(sp)
    80004170:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004172:	04451703          	lh	a4,68(a0)
    80004176:	4785                	li	a5,1
    80004178:	00f71a63          	bne	a4,a5,8000418c <dirlookup+0x2a>
    8000417c:	892a                	mv	s2,a0
    8000417e:	89ae                	mv	s3,a1
    80004180:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004182:	457c                	lw	a5,76(a0)
    80004184:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004186:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004188:	e79d                	bnez	a5,800041b6 <dirlookup+0x54>
    8000418a:	a8a5                	j	80004202 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000418c:	00004517          	auipc	a0,0x4
    80004190:	5ac50513          	addi	a0,a0,1452 # 80008738 <syscalls+0x1c8>
    80004194:	ffffc097          	auipc	ra,0xffffc
    80004198:	3b0080e7          	jalr	944(ra) # 80000544 <panic>
      panic("dirlookup read");
    8000419c:	00004517          	auipc	a0,0x4
    800041a0:	5b450513          	addi	a0,a0,1460 # 80008750 <syscalls+0x1e0>
    800041a4:	ffffc097          	auipc	ra,0xffffc
    800041a8:	3a0080e7          	jalr	928(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ac:	24c1                	addiw	s1,s1,16
    800041ae:	04c92783          	lw	a5,76(s2)
    800041b2:	04f4f763          	bgeu	s1,a5,80004200 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041b6:	4741                	li	a4,16
    800041b8:	86a6                	mv	a3,s1
    800041ba:	fc040613          	addi	a2,s0,-64
    800041be:	4581                	li	a1,0
    800041c0:	854a                	mv	a0,s2
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	d70080e7          	jalr	-656(ra) # 80003f32 <readi>
    800041ca:	47c1                	li	a5,16
    800041cc:	fcf518e3          	bne	a0,a5,8000419c <dirlookup+0x3a>
    if(de.inum == 0)
    800041d0:	fc045783          	lhu	a5,-64(s0)
    800041d4:	dfe1                	beqz	a5,800041ac <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041d6:	fc240593          	addi	a1,s0,-62
    800041da:	854e                	mv	a0,s3
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	f6c080e7          	jalr	-148(ra) # 80004148 <namecmp>
    800041e4:	f561                	bnez	a0,800041ac <dirlookup+0x4a>
      if(poff)
    800041e6:	000a0463          	beqz	s4,800041ee <dirlookup+0x8c>
        *poff = off;
    800041ea:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041ee:	fc045583          	lhu	a1,-64(s0)
    800041f2:	00092503          	lw	a0,0(s2)
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	750080e7          	jalr	1872(ra) # 80003946 <iget>
    800041fe:	a011                	j	80004202 <dirlookup+0xa0>
  return 0;
    80004200:	4501                	li	a0,0
}
    80004202:	70e2                	ld	ra,56(sp)
    80004204:	7442                	ld	s0,48(sp)
    80004206:	74a2                	ld	s1,40(sp)
    80004208:	7902                	ld	s2,32(sp)
    8000420a:	69e2                	ld	s3,24(sp)
    8000420c:	6a42                	ld	s4,16(sp)
    8000420e:	6121                	addi	sp,sp,64
    80004210:	8082                	ret

0000000080004212 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004212:	711d                	addi	sp,sp,-96
    80004214:	ec86                	sd	ra,88(sp)
    80004216:	e8a2                	sd	s0,80(sp)
    80004218:	e4a6                	sd	s1,72(sp)
    8000421a:	e0ca                	sd	s2,64(sp)
    8000421c:	fc4e                	sd	s3,56(sp)
    8000421e:	f852                	sd	s4,48(sp)
    80004220:	f456                	sd	s5,40(sp)
    80004222:	f05a                	sd	s6,32(sp)
    80004224:	ec5e                	sd	s7,24(sp)
    80004226:	e862                	sd	s8,16(sp)
    80004228:	e466                	sd	s9,8(sp)
    8000422a:	1080                	addi	s0,sp,96
    8000422c:	84aa                	mv	s1,a0
    8000422e:	8b2e                	mv	s6,a1
    80004230:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004232:	00054703          	lbu	a4,0(a0)
    80004236:	02f00793          	li	a5,47
    8000423a:	02f70363          	beq	a4,a5,80004260 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	7b8080e7          	jalr	1976(ra) # 800019f6 <myproc>
    80004246:	16053503          	ld	a0,352(a0)
    8000424a:	00000097          	auipc	ra,0x0
    8000424e:	9f6080e7          	jalr	-1546(ra) # 80003c40 <idup>
    80004252:	89aa                	mv	s3,a0
  while(*path == '/')
    80004254:	02f00913          	li	s2,47
  len = path - s;
    80004258:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000425a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000425c:	4c05                	li	s8,1
    8000425e:	a865                	j	80004316 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004260:	4585                	li	a1,1
    80004262:	4505                	li	a0,1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	6e2080e7          	jalr	1762(ra) # 80003946 <iget>
    8000426c:	89aa                	mv	s3,a0
    8000426e:	b7dd                	j	80004254 <namex+0x42>
      iunlockput(ip);
    80004270:	854e                	mv	a0,s3
    80004272:	00000097          	auipc	ra,0x0
    80004276:	c6e080e7          	jalr	-914(ra) # 80003ee0 <iunlockput>
      return 0;
    8000427a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000427c:	854e                	mv	a0,s3
    8000427e:	60e6                	ld	ra,88(sp)
    80004280:	6446                	ld	s0,80(sp)
    80004282:	64a6                	ld	s1,72(sp)
    80004284:	6906                	ld	s2,64(sp)
    80004286:	79e2                	ld	s3,56(sp)
    80004288:	7a42                	ld	s4,48(sp)
    8000428a:	7aa2                	ld	s5,40(sp)
    8000428c:	7b02                	ld	s6,32(sp)
    8000428e:	6be2                	ld	s7,24(sp)
    80004290:	6c42                	ld	s8,16(sp)
    80004292:	6ca2                	ld	s9,8(sp)
    80004294:	6125                	addi	sp,sp,96
    80004296:	8082                	ret
      iunlock(ip);
    80004298:	854e                	mv	a0,s3
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	aa6080e7          	jalr	-1370(ra) # 80003d40 <iunlock>
      return ip;
    800042a2:	bfe9                	j	8000427c <namex+0x6a>
      iunlockput(ip);
    800042a4:	854e                	mv	a0,s3
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	c3a080e7          	jalr	-966(ra) # 80003ee0 <iunlockput>
      return 0;
    800042ae:	89d2                	mv	s3,s4
    800042b0:	b7f1                	j	8000427c <namex+0x6a>
  len = path - s;
    800042b2:	40b48633          	sub	a2,s1,a1
    800042b6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800042ba:	094cd463          	bge	s9,s4,80004342 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042be:	4639                	li	a2,14
    800042c0:	8556                	mv	a0,s5
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	a84080e7          	jalr	-1404(ra) # 80000d46 <memmove>
  while(*path == '/')
    800042ca:	0004c783          	lbu	a5,0(s1)
    800042ce:	01279763          	bne	a5,s2,800042dc <namex+0xca>
    path++;
    800042d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042d4:	0004c783          	lbu	a5,0(s1)
    800042d8:	ff278de3          	beq	a5,s2,800042d2 <namex+0xc0>
    ilock(ip);
    800042dc:	854e                	mv	a0,s3
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	9a0080e7          	jalr	-1632(ra) # 80003c7e <ilock>
    if(ip->type != T_DIR){
    800042e6:	04499783          	lh	a5,68(s3)
    800042ea:	f98793e3          	bne	a5,s8,80004270 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042ee:	000b0563          	beqz	s6,800042f8 <namex+0xe6>
    800042f2:	0004c783          	lbu	a5,0(s1)
    800042f6:	d3cd                	beqz	a5,80004298 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042f8:	865e                	mv	a2,s7
    800042fa:	85d6                	mv	a1,s5
    800042fc:	854e                	mv	a0,s3
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	e64080e7          	jalr	-412(ra) # 80004162 <dirlookup>
    80004306:	8a2a                	mv	s4,a0
    80004308:	dd51                	beqz	a0,800042a4 <namex+0x92>
    iunlockput(ip);
    8000430a:	854e                	mv	a0,s3
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	bd4080e7          	jalr	-1068(ra) # 80003ee0 <iunlockput>
    ip = next;
    80004314:	89d2                	mv	s3,s4
  while(*path == '/')
    80004316:	0004c783          	lbu	a5,0(s1)
    8000431a:	05279763          	bne	a5,s2,80004368 <namex+0x156>
    path++;
    8000431e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004320:	0004c783          	lbu	a5,0(s1)
    80004324:	ff278de3          	beq	a5,s2,8000431e <namex+0x10c>
  if(*path == 0)
    80004328:	c79d                	beqz	a5,80004356 <namex+0x144>
    path++;
    8000432a:	85a6                	mv	a1,s1
  len = path - s;
    8000432c:	8a5e                	mv	s4,s7
    8000432e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004330:	01278963          	beq	a5,s2,80004342 <namex+0x130>
    80004334:	dfbd                	beqz	a5,800042b2 <namex+0xa0>
    path++;
    80004336:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004338:	0004c783          	lbu	a5,0(s1)
    8000433c:	ff279ce3          	bne	a5,s2,80004334 <namex+0x122>
    80004340:	bf8d                	j	800042b2 <namex+0xa0>
    memmove(name, s, len);
    80004342:	2601                	sext.w	a2,a2
    80004344:	8556                	mv	a0,s5
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	a00080e7          	jalr	-1536(ra) # 80000d46 <memmove>
    name[len] = 0;
    8000434e:	9a56                	add	s4,s4,s5
    80004350:	000a0023          	sb	zero,0(s4)
    80004354:	bf9d                	j	800042ca <namex+0xb8>
  if(nameiparent){
    80004356:	f20b03e3          	beqz	s6,8000427c <namex+0x6a>
    iput(ip);
    8000435a:	854e                	mv	a0,s3
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	adc080e7          	jalr	-1316(ra) # 80003e38 <iput>
    return 0;
    80004364:	4981                	li	s3,0
    80004366:	bf19                	j	8000427c <namex+0x6a>
  if(*path == 0)
    80004368:	d7fd                	beqz	a5,80004356 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000436a:	0004c783          	lbu	a5,0(s1)
    8000436e:	85a6                	mv	a1,s1
    80004370:	b7d1                	j	80004334 <namex+0x122>

0000000080004372 <dirlink>:
{
    80004372:	7139                	addi	sp,sp,-64
    80004374:	fc06                	sd	ra,56(sp)
    80004376:	f822                	sd	s0,48(sp)
    80004378:	f426                	sd	s1,40(sp)
    8000437a:	f04a                	sd	s2,32(sp)
    8000437c:	ec4e                	sd	s3,24(sp)
    8000437e:	e852                	sd	s4,16(sp)
    80004380:	0080                	addi	s0,sp,64
    80004382:	892a                	mv	s2,a0
    80004384:	8a2e                	mv	s4,a1
    80004386:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004388:	4601                	li	a2,0
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	dd8080e7          	jalr	-552(ra) # 80004162 <dirlookup>
    80004392:	e93d                	bnez	a0,80004408 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004394:	04c92483          	lw	s1,76(s2)
    80004398:	c49d                	beqz	s1,800043c6 <dirlink+0x54>
    8000439a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000439c:	4741                	li	a4,16
    8000439e:	86a6                	mv	a3,s1
    800043a0:	fc040613          	addi	a2,s0,-64
    800043a4:	4581                	li	a1,0
    800043a6:	854a                	mv	a0,s2
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	b8a080e7          	jalr	-1142(ra) # 80003f32 <readi>
    800043b0:	47c1                	li	a5,16
    800043b2:	06f51163          	bne	a0,a5,80004414 <dirlink+0xa2>
    if(de.inum == 0)
    800043b6:	fc045783          	lhu	a5,-64(s0)
    800043ba:	c791                	beqz	a5,800043c6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043bc:	24c1                	addiw	s1,s1,16
    800043be:	04c92783          	lw	a5,76(s2)
    800043c2:	fcf4ede3          	bltu	s1,a5,8000439c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043c6:	4639                	li	a2,14
    800043c8:	85d2                	mv	a1,s4
    800043ca:	fc240513          	addi	a0,s0,-62
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	a2c080e7          	jalr	-1492(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800043d6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043da:	4741                	li	a4,16
    800043dc:	86a6                	mv	a3,s1
    800043de:	fc040613          	addi	a2,s0,-64
    800043e2:	4581                	li	a1,0
    800043e4:	854a                	mv	a0,s2
    800043e6:	00000097          	auipc	ra,0x0
    800043ea:	c44080e7          	jalr	-956(ra) # 8000402a <writei>
    800043ee:	1541                	addi	a0,a0,-16
    800043f0:	00a03533          	snez	a0,a0
    800043f4:	40a00533          	neg	a0,a0
}
    800043f8:	70e2                	ld	ra,56(sp)
    800043fa:	7442                	ld	s0,48(sp)
    800043fc:	74a2                	ld	s1,40(sp)
    800043fe:	7902                	ld	s2,32(sp)
    80004400:	69e2                	ld	s3,24(sp)
    80004402:	6a42                	ld	s4,16(sp)
    80004404:	6121                	addi	sp,sp,64
    80004406:	8082                	ret
    iput(ip);
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	a30080e7          	jalr	-1488(ra) # 80003e38 <iput>
    return -1;
    80004410:	557d                	li	a0,-1
    80004412:	b7dd                	j	800043f8 <dirlink+0x86>
      panic("dirlink read");
    80004414:	00004517          	auipc	a0,0x4
    80004418:	34c50513          	addi	a0,a0,844 # 80008760 <syscalls+0x1f0>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	128080e7          	jalr	296(ra) # 80000544 <panic>

0000000080004424 <namei>:

struct inode*
namei(char *path)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000442c:	fe040613          	addi	a2,s0,-32
    80004430:	4581                	li	a1,0
    80004432:	00000097          	auipc	ra,0x0
    80004436:	de0080e7          	jalr	-544(ra) # 80004212 <namex>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	6105                	addi	sp,sp,32
    80004440:	8082                	ret

0000000080004442 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004442:	1141                	addi	sp,sp,-16
    80004444:	e406                	sd	ra,8(sp)
    80004446:	e022                	sd	s0,0(sp)
    80004448:	0800                	addi	s0,sp,16
    8000444a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000444c:	4585                	li	a1,1
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	dc4080e7          	jalr	-572(ra) # 80004212 <namex>
}
    80004456:	60a2                	ld	ra,8(sp)
    80004458:	6402                	ld	s0,0(sp)
    8000445a:	0141                	addi	sp,sp,16
    8000445c:	8082                	ret

000000008000445e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	e426                	sd	s1,8(sp)
    80004466:	e04a                	sd	s2,0(sp)
    80004468:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000446a:	0001e917          	auipc	s2,0x1e
    8000446e:	50690913          	addi	s2,s2,1286 # 80022970 <log>
    80004472:	01892583          	lw	a1,24(s2)
    80004476:	02892503          	lw	a0,40(s2)
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	fea080e7          	jalr	-22(ra) # 80003464 <bread>
    80004482:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004484:	02c92683          	lw	a3,44(s2)
    80004488:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000448a:	02d05763          	blez	a3,800044b8 <write_head+0x5a>
    8000448e:	0001e797          	auipc	a5,0x1e
    80004492:	51278793          	addi	a5,a5,1298 # 800229a0 <log+0x30>
    80004496:	05c50713          	addi	a4,a0,92
    8000449a:	36fd                	addiw	a3,a3,-1
    8000449c:	1682                	slli	a3,a3,0x20
    8000449e:	9281                	srli	a3,a3,0x20
    800044a0:	068a                	slli	a3,a3,0x2
    800044a2:	0001e617          	auipc	a2,0x1e
    800044a6:	50260613          	addi	a2,a2,1282 # 800229a4 <log+0x34>
    800044aa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044ac:	4390                	lw	a2,0(a5)
    800044ae:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044b0:	0791                	addi	a5,a5,4
    800044b2:	0711                	addi	a4,a4,4
    800044b4:	fed79ce3          	bne	a5,a3,800044ac <write_head+0x4e>
  }
  bwrite(buf);
    800044b8:	8526                	mv	a0,s1
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	09c080e7          	jalr	156(ra) # 80003556 <bwrite>
  brelse(buf);
    800044c2:	8526                	mv	a0,s1
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	0d0080e7          	jalr	208(ra) # 80003594 <brelse>
}
    800044cc:	60e2                	ld	ra,24(sp)
    800044ce:	6442                	ld	s0,16(sp)
    800044d0:	64a2                	ld	s1,8(sp)
    800044d2:	6902                	ld	s2,0(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret

00000000800044d8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d8:	0001e797          	auipc	a5,0x1e
    800044dc:	4c47a783          	lw	a5,1220(a5) # 8002299c <log+0x2c>
    800044e0:	0af05d63          	blez	a5,8000459a <install_trans+0xc2>
{
    800044e4:	7139                	addi	sp,sp,-64
    800044e6:	fc06                	sd	ra,56(sp)
    800044e8:	f822                	sd	s0,48(sp)
    800044ea:	f426                	sd	s1,40(sp)
    800044ec:	f04a                	sd	s2,32(sp)
    800044ee:	ec4e                	sd	s3,24(sp)
    800044f0:	e852                	sd	s4,16(sp)
    800044f2:	e456                	sd	s5,8(sp)
    800044f4:	e05a                	sd	s6,0(sp)
    800044f6:	0080                	addi	s0,sp,64
    800044f8:	8b2a                	mv	s6,a0
    800044fa:	0001ea97          	auipc	s5,0x1e
    800044fe:	4a6a8a93          	addi	s5,s5,1190 # 800229a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004502:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004504:	0001e997          	auipc	s3,0x1e
    80004508:	46c98993          	addi	s3,s3,1132 # 80022970 <log>
    8000450c:	a035                	j	80004538 <install_trans+0x60>
      bunpin(dbuf);
    8000450e:	8526                	mv	a0,s1
    80004510:	fffff097          	auipc	ra,0xfffff
    80004514:	15e080e7          	jalr	350(ra) # 8000366e <bunpin>
    brelse(lbuf);
    80004518:	854a                	mv	a0,s2
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	07a080e7          	jalr	122(ra) # 80003594 <brelse>
    brelse(dbuf);
    80004522:	8526                	mv	a0,s1
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	070080e7          	jalr	112(ra) # 80003594 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000452c:	2a05                	addiw	s4,s4,1
    8000452e:	0a91                	addi	s5,s5,4
    80004530:	02c9a783          	lw	a5,44(s3)
    80004534:	04fa5963          	bge	s4,a5,80004586 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004538:	0189a583          	lw	a1,24(s3)
    8000453c:	014585bb          	addw	a1,a1,s4
    80004540:	2585                	addiw	a1,a1,1
    80004542:	0289a503          	lw	a0,40(s3)
    80004546:	fffff097          	auipc	ra,0xfffff
    8000454a:	f1e080e7          	jalr	-226(ra) # 80003464 <bread>
    8000454e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004550:	000aa583          	lw	a1,0(s5)
    80004554:	0289a503          	lw	a0,40(s3)
    80004558:	fffff097          	auipc	ra,0xfffff
    8000455c:	f0c080e7          	jalr	-244(ra) # 80003464 <bread>
    80004560:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004562:	40000613          	li	a2,1024
    80004566:	05890593          	addi	a1,s2,88
    8000456a:	05850513          	addi	a0,a0,88
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	7d8080e7          	jalr	2008(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004576:	8526                	mv	a0,s1
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	fde080e7          	jalr	-34(ra) # 80003556 <bwrite>
    if(recovering == 0)
    80004580:	f80b1ce3          	bnez	s6,80004518 <install_trans+0x40>
    80004584:	b769                	j	8000450e <install_trans+0x36>
}
    80004586:	70e2                	ld	ra,56(sp)
    80004588:	7442                	ld	s0,48(sp)
    8000458a:	74a2                	ld	s1,40(sp)
    8000458c:	7902                	ld	s2,32(sp)
    8000458e:	69e2                	ld	s3,24(sp)
    80004590:	6a42                	ld	s4,16(sp)
    80004592:	6aa2                	ld	s5,8(sp)
    80004594:	6b02                	ld	s6,0(sp)
    80004596:	6121                	addi	sp,sp,64
    80004598:	8082                	ret
    8000459a:	8082                	ret

000000008000459c <initlog>:
{
    8000459c:	7179                	addi	sp,sp,-48
    8000459e:	f406                	sd	ra,40(sp)
    800045a0:	f022                	sd	s0,32(sp)
    800045a2:	ec26                	sd	s1,24(sp)
    800045a4:	e84a                	sd	s2,16(sp)
    800045a6:	e44e                	sd	s3,8(sp)
    800045a8:	1800                	addi	s0,sp,48
    800045aa:	892a                	mv	s2,a0
    800045ac:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045ae:	0001e497          	auipc	s1,0x1e
    800045b2:	3c248493          	addi	s1,s1,962 # 80022970 <log>
    800045b6:	00004597          	auipc	a1,0x4
    800045ba:	1ba58593          	addi	a1,a1,442 # 80008770 <syscalls+0x200>
    800045be:	8526                	mv	a0,s1
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	59a080e7          	jalr	1434(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800045c8:	0149a583          	lw	a1,20(s3)
    800045cc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045ce:	0109a783          	lw	a5,16(s3)
    800045d2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045d4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045d8:	854a                	mv	a0,s2
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	e8a080e7          	jalr	-374(ra) # 80003464 <bread>
  log.lh.n = lh->n;
    800045e2:	4d3c                	lw	a5,88(a0)
    800045e4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045e6:	02f05563          	blez	a5,80004610 <initlog+0x74>
    800045ea:	05c50713          	addi	a4,a0,92
    800045ee:	0001e697          	auipc	a3,0x1e
    800045f2:	3b268693          	addi	a3,a3,946 # 800229a0 <log+0x30>
    800045f6:	37fd                	addiw	a5,a5,-1
    800045f8:	1782                	slli	a5,a5,0x20
    800045fa:	9381                	srli	a5,a5,0x20
    800045fc:	078a                	slli	a5,a5,0x2
    800045fe:	06050613          	addi	a2,a0,96
    80004602:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004604:	4310                	lw	a2,0(a4)
    80004606:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004608:	0711                	addi	a4,a4,4
    8000460a:	0691                	addi	a3,a3,4
    8000460c:	fef71ce3          	bne	a4,a5,80004604 <initlog+0x68>
  brelse(buf);
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	f84080e7          	jalr	-124(ra) # 80003594 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004618:	4505                	li	a0,1
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	ebe080e7          	jalr	-322(ra) # 800044d8 <install_trans>
  log.lh.n = 0;
    80004622:	0001e797          	auipc	a5,0x1e
    80004626:	3607ad23          	sw	zero,890(a5) # 8002299c <log+0x2c>
  write_head(); // clear the log
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	e34080e7          	jalr	-460(ra) # 8000445e <write_head>
}
    80004632:	70a2                	ld	ra,40(sp)
    80004634:	7402                	ld	s0,32(sp)
    80004636:	64e2                	ld	s1,24(sp)
    80004638:	6942                	ld	s2,16(sp)
    8000463a:	69a2                	ld	s3,8(sp)
    8000463c:	6145                	addi	sp,sp,48
    8000463e:	8082                	ret

0000000080004640 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004640:	1101                	addi	sp,sp,-32
    80004642:	ec06                	sd	ra,24(sp)
    80004644:	e822                	sd	s0,16(sp)
    80004646:	e426                	sd	s1,8(sp)
    80004648:	e04a                	sd	s2,0(sp)
    8000464a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000464c:	0001e517          	auipc	a0,0x1e
    80004650:	32450513          	addi	a0,a0,804 # 80022970 <log>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	596080e7          	jalr	1430(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    8000465c:	0001e497          	auipc	s1,0x1e
    80004660:	31448493          	addi	s1,s1,788 # 80022970 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004664:	4979                	li	s2,30
    80004666:	a039                	j	80004674 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004668:	85a6                	mv	a1,s1
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffe097          	auipc	ra,0xffffe
    80004670:	afc080e7          	jalr	-1284(ra) # 80002168 <sleep>
    if(log.committing){
    80004674:	50dc                	lw	a5,36(s1)
    80004676:	fbed                	bnez	a5,80004668 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004678:	509c                	lw	a5,32(s1)
    8000467a:	0017871b          	addiw	a4,a5,1
    8000467e:	0007069b          	sext.w	a3,a4
    80004682:	0027179b          	slliw	a5,a4,0x2
    80004686:	9fb9                	addw	a5,a5,a4
    80004688:	0017979b          	slliw	a5,a5,0x1
    8000468c:	54d8                	lw	a4,44(s1)
    8000468e:	9fb9                	addw	a5,a5,a4
    80004690:	00f95963          	bge	s2,a5,800046a2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004694:	85a6                	mv	a1,s1
    80004696:	8526                	mv	a0,s1
    80004698:	ffffe097          	auipc	ra,0xffffe
    8000469c:	ad0080e7          	jalr	-1328(ra) # 80002168 <sleep>
    800046a0:	bfd1                	j	80004674 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046a2:	0001e517          	auipc	a0,0x1e
    800046a6:	2ce50513          	addi	a0,a0,718 # 80022970 <log>
    800046aa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	5f2080e7          	jalr	1522(ra) # 80000c9e <release>
      break;
    }
  }
}
    800046b4:	60e2                	ld	ra,24(sp)
    800046b6:	6442                	ld	s0,16(sp)
    800046b8:	64a2                	ld	s1,8(sp)
    800046ba:	6902                	ld	s2,0(sp)
    800046bc:	6105                	addi	sp,sp,32
    800046be:	8082                	ret

00000000800046c0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046c0:	7139                	addi	sp,sp,-64
    800046c2:	fc06                	sd	ra,56(sp)
    800046c4:	f822                	sd	s0,48(sp)
    800046c6:	f426                	sd	s1,40(sp)
    800046c8:	f04a                	sd	s2,32(sp)
    800046ca:	ec4e                	sd	s3,24(sp)
    800046cc:	e852                	sd	s4,16(sp)
    800046ce:	e456                	sd	s5,8(sp)
    800046d0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046d2:	0001e497          	auipc	s1,0x1e
    800046d6:	29e48493          	addi	s1,s1,670 # 80022970 <log>
    800046da:	8526                	mv	a0,s1
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	50e080e7          	jalr	1294(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800046e4:	509c                	lw	a5,32(s1)
    800046e6:	37fd                	addiw	a5,a5,-1
    800046e8:	0007891b          	sext.w	s2,a5
    800046ec:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046ee:	50dc                	lw	a5,36(s1)
    800046f0:	efb9                	bnez	a5,8000474e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046f2:	06091663          	bnez	s2,8000475e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800046f6:	0001e497          	auipc	s1,0x1e
    800046fa:	27a48493          	addi	s1,s1,634 # 80022970 <log>
    800046fe:	4785                	li	a5,1
    80004700:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004702:	8526                	mv	a0,s1
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	59a080e7          	jalr	1434(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000470c:	54dc                	lw	a5,44(s1)
    8000470e:	06f04763          	bgtz	a5,8000477c <end_op+0xbc>
    acquire(&log.lock);
    80004712:	0001e497          	auipc	s1,0x1e
    80004716:	25e48493          	addi	s1,s1,606 # 80022970 <log>
    8000471a:	8526                	mv	a0,s1
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	4ce080e7          	jalr	1230(ra) # 80000bea <acquire>
    log.committing = 0;
    80004724:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffe097          	auipc	ra,0xffffe
    8000472e:	bf2080e7          	jalr	-1038(ra) # 8000231c <wakeup>
    release(&log.lock);
    80004732:	8526                	mv	a0,s1
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	56a080e7          	jalr	1386(ra) # 80000c9e <release>
}
    8000473c:	70e2                	ld	ra,56(sp)
    8000473e:	7442                	ld	s0,48(sp)
    80004740:	74a2                	ld	s1,40(sp)
    80004742:	7902                	ld	s2,32(sp)
    80004744:	69e2                	ld	s3,24(sp)
    80004746:	6a42                	ld	s4,16(sp)
    80004748:	6aa2                	ld	s5,8(sp)
    8000474a:	6121                	addi	sp,sp,64
    8000474c:	8082                	ret
    panic("log.committing");
    8000474e:	00004517          	auipc	a0,0x4
    80004752:	02a50513          	addi	a0,a0,42 # 80008778 <syscalls+0x208>
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	dee080e7          	jalr	-530(ra) # 80000544 <panic>
    wakeup(&log);
    8000475e:	0001e497          	auipc	s1,0x1e
    80004762:	21248493          	addi	s1,s1,530 # 80022970 <log>
    80004766:	8526                	mv	a0,s1
    80004768:	ffffe097          	auipc	ra,0xffffe
    8000476c:	bb4080e7          	jalr	-1100(ra) # 8000231c <wakeup>
  release(&log.lock);
    80004770:	8526                	mv	a0,s1
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	52c080e7          	jalr	1324(ra) # 80000c9e <release>
  if(do_commit){
    8000477a:	b7c9                	j	8000473c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000477c:	0001ea97          	auipc	s5,0x1e
    80004780:	224a8a93          	addi	s5,s5,548 # 800229a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004784:	0001ea17          	auipc	s4,0x1e
    80004788:	1eca0a13          	addi	s4,s4,492 # 80022970 <log>
    8000478c:	018a2583          	lw	a1,24(s4)
    80004790:	012585bb          	addw	a1,a1,s2
    80004794:	2585                	addiw	a1,a1,1
    80004796:	028a2503          	lw	a0,40(s4)
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	cca080e7          	jalr	-822(ra) # 80003464 <bread>
    800047a2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047a4:	000aa583          	lw	a1,0(s5)
    800047a8:	028a2503          	lw	a0,40(s4)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	cb8080e7          	jalr	-840(ra) # 80003464 <bread>
    800047b4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047b6:	40000613          	li	a2,1024
    800047ba:	05850593          	addi	a1,a0,88
    800047be:	05848513          	addi	a0,s1,88
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	584080e7          	jalr	1412(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800047ca:	8526                	mv	a0,s1
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	d8a080e7          	jalr	-630(ra) # 80003556 <bwrite>
    brelse(from);
    800047d4:	854e                	mv	a0,s3
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	dbe080e7          	jalr	-578(ra) # 80003594 <brelse>
    brelse(to);
    800047de:	8526                	mv	a0,s1
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	db4080e7          	jalr	-588(ra) # 80003594 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047e8:	2905                	addiw	s2,s2,1
    800047ea:	0a91                	addi	s5,s5,4
    800047ec:	02ca2783          	lw	a5,44(s4)
    800047f0:	f8f94ee3          	blt	s2,a5,8000478c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047f4:	00000097          	auipc	ra,0x0
    800047f8:	c6a080e7          	jalr	-918(ra) # 8000445e <write_head>
    install_trans(0); // Now install writes to home locations
    800047fc:	4501                	li	a0,0
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	cda080e7          	jalr	-806(ra) # 800044d8 <install_trans>
    log.lh.n = 0;
    80004806:	0001e797          	auipc	a5,0x1e
    8000480a:	1807ab23          	sw	zero,406(a5) # 8002299c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	c50080e7          	jalr	-944(ra) # 8000445e <write_head>
    80004816:	bdf5                	j	80004712 <end_op+0x52>

0000000080004818 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004818:	1101                	addi	sp,sp,-32
    8000481a:	ec06                	sd	ra,24(sp)
    8000481c:	e822                	sd	s0,16(sp)
    8000481e:	e426                	sd	s1,8(sp)
    80004820:	e04a                	sd	s2,0(sp)
    80004822:	1000                	addi	s0,sp,32
    80004824:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004826:	0001e917          	auipc	s2,0x1e
    8000482a:	14a90913          	addi	s2,s2,330 # 80022970 <log>
    8000482e:	854a                	mv	a0,s2
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	3ba080e7          	jalr	954(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004838:	02c92603          	lw	a2,44(s2)
    8000483c:	47f5                	li	a5,29
    8000483e:	06c7c563          	blt	a5,a2,800048a8 <log_write+0x90>
    80004842:	0001e797          	auipc	a5,0x1e
    80004846:	14a7a783          	lw	a5,330(a5) # 8002298c <log+0x1c>
    8000484a:	37fd                	addiw	a5,a5,-1
    8000484c:	04f65e63          	bge	a2,a5,800048a8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004850:	0001e797          	auipc	a5,0x1e
    80004854:	1407a783          	lw	a5,320(a5) # 80022990 <log+0x20>
    80004858:	06f05063          	blez	a5,800048b8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000485c:	4781                	li	a5,0
    8000485e:	06c05563          	blez	a2,800048c8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004862:	44cc                	lw	a1,12(s1)
    80004864:	0001e717          	auipc	a4,0x1e
    80004868:	13c70713          	addi	a4,a4,316 # 800229a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000486c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000486e:	4314                	lw	a3,0(a4)
    80004870:	04b68c63          	beq	a3,a1,800048c8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004874:	2785                	addiw	a5,a5,1
    80004876:	0711                	addi	a4,a4,4
    80004878:	fef61be3          	bne	a2,a5,8000486e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000487c:	0621                	addi	a2,a2,8
    8000487e:	060a                	slli	a2,a2,0x2
    80004880:	0001e797          	auipc	a5,0x1e
    80004884:	0f078793          	addi	a5,a5,240 # 80022970 <log>
    80004888:	963e                	add	a2,a2,a5
    8000488a:	44dc                	lw	a5,12(s1)
    8000488c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000488e:	8526                	mv	a0,s1
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	da2080e7          	jalr	-606(ra) # 80003632 <bpin>
    log.lh.n++;
    80004898:	0001e717          	auipc	a4,0x1e
    8000489c:	0d870713          	addi	a4,a4,216 # 80022970 <log>
    800048a0:	575c                	lw	a5,44(a4)
    800048a2:	2785                	addiw	a5,a5,1
    800048a4:	d75c                	sw	a5,44(a4)
    800048a6:	a835                	j	800048e2 <log_write+0xca>
    panic("too big a transaction");
    800048a8:	00004517          	auipc	a0,0x4
    800048ac:	ee050513          	addi	a0,a0,-288 # 80008788 <syscalls+0x218>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	c94080e7          	jalr	-876(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800048b8:	00004517          	auipc	a0,0x4
    800048bc:	ee850513          	addi	a0,a0,-280 # 800087a0 <syscalls+0x230>
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	c84080e7          	jalr	-892(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800048c8:	00878713          	addi	a4,a5,8
    800048cc:	00271693          	slli	a3,a4,0x2
    800048d0:	0001e717          	auipc	a4,0x1e
    800048d4:	0a070713          	addi	a4,a4,160 # 80022970 <log>
    800048d8:	9736                	add	a4,a4,a3
    800048da:	44d4                	lw	a3,12(s1)
    800048dc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048de:	faf608e3          	beq	a2,a5,8000488e <log_write+0x76>
  }
  release(&log.lock);
    800048e2:	0001e517          	auipc	a0,0x1e
    800048e6:	08e50513          	addi	a0,a0,142 # 80022970 <log>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	3b4080e7          	jalr	948(ra) # 80000c9e <release>
}
    800048f2:	60e2                	ld	ra,24(sp)
    800048f4:	6442                	ld	s0,16(sp)
    800048f6:	64a2                	ld	s1,8(sp)
    800048f8:	6902                	ld	s2,0(sp)
    800048fa:	6105                	addi	sp,sp,32
    800048fc:	8082                	ret

00000000800048fe <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048fe:	1101                	addi	sp,sp,-32
    80004900:	ec06                	sd	ra,24(sp)
    80004902:	e822                	sd	s0,16(sp)
    80004904:	e426                	sd	s1,8(sp)
    80004906:	e04a                	sd	s2,0(sp)
    80004908:	1000                	addi	s0,sp,32
    8000490a:	84aa                	mv	s1,a0
    8000490c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000490e:	00004597          	auipc	a1,0x4
    80004912:	eb258593          	addi	a1,a1,-334 # 800087c0 <syscalls+0x250>
    80004916:	0521                	addi	a0,a0,8
    80004918:	ffffc097          	auipc	ra,0xffffc
    8000491c:	242080e7          	jalr	578(ra) # 80000b5a <initlock>
  lk->name = name;
    80004920:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004924:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004928:	0204a423          	sw	zero,40(s1)
}
    8000492c:	60e2                	ld	ra,24(sp)
    8000492e:	6442                	ld	s0,16(sp)
    80004930:	64a2                	ld	s1,8(sp)
    80004932:	6902                	ld	s2,0(sp)
    80004934:	6105                	addi	sp,sp,32
    80004936:	8082                	ret

0000000080004938 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004938:	1101                	addi	sp,sp,-32
    8000493a:	ec06                	sd	ra,24(sp)
    8000493c:	e822                	sd	s0,16(sp)
    8000493e:	e426                	sd	s1,8(sp)
    80004940:	e04a                	sd	s2,0(sp)
    80004942:	1000                	addi	s0,sp,32
    80004944:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004946:	00850913          	addi	s2,a0,8
    8000494a:	854a                	mv	a0,s2
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	29e080e7          	jalr	670(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004954:	409c                	lw	a5,0(s1)
    80004956:	cb89                	beqz	a5,80004968 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004958:	85ca                	mv	a1,s2
    8000495a:	8526                	mv	a0,s1
    8000495c:	ffffe097          	auipc	ra,0xffffe
    80004960:	80c080e7          	jalr	-2036(ra) # 80002168 <sleep>
  while (lk->locked) {
    80004964:	409c                	lw	a5,0(s1)
    80004966:	fbed                	bnez	a5,80004958 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004968:	4785                	li	a5,1
    8000496a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000496c:	ffffd097          	auipc	ra,0xffffd
    80004970:	08a080e7          	jalr	138(ra) # 800019f6 <myproc>
    80004974:	591c                	lw	a5,48(a0)
    80004976:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004978:	854a                	mv	a0,s2
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	324080e7          	jalr	804(ra) # 80000c9e <release>
}
    80004982:	60e2                	ld	ra,24(sp)
    80004984:	6442                	ld	s0,16(sp)
    80004986:	64a2                	ld	s1,8(sp)
    80004988:	6902                	ld	s2,0(sp)
    8000498a:	6105                	addi	sp,sp,32
    8000498c:	8082                	ret

000000008000498e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000498e:	1101                	addi	sp,sp,-32
    80004990:	ec06                	sd	ra,24(sp)
    80004992:	e822                	sd	s0,16(sp)
    80004994:	e426                	sd	s1,8(sp)
    80004996:	e04a                	sd	s2,0(sp)
    80004998:	1000                	addi	s0,sp,32
    8000499a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000499c:	00850913          	addi	s2,a0,8
    800049a0:	854a                	mv	a0,s2
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	248080e7          	jalr	584(ra) # 80000bea <acquire>
  lk->locked = 0;
    800049aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049ae:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049b2:	8526                	mv	a0,s1
    800049b4:	ffffe097          	auipc	ra,0xffffe
    800049b8:	968080e7          	jalr	-1688(ra) # 8000231c <wakeup>
  release(&lk->lk);
    800049bc:	854a                	mv	a0,s2
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	2e0080e7          	jalr	736(ra) # 80000c9e <release>
}
    800049c6:	60e2                	ld	ra,24(sp)
    800049c8:	6442                	ld	s0,16(sp)
    800049ca:	64a2                	ld	s1,8(sp)
    800049cc:	6902                	ld	s2,0(sp)
    800049ce:	6105                	addi	sp,sp,32
    800049d0:	8082                	ret

00000000800049d2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049d2:	7179                	addi	sp,sp,-48
    800049d4:	f406                	sd	ra,40(sp)
    800049d6:	f022                	sd	s0,32(sp)
    800049d8:	ec26                	sd	s1,24(sp)
    800049da:	e84a                	sd	s2,16(sp)
    800049dc:	e44e                	sd	s3,8(sp)
    800049de:	1800                	addi	s0,sp,48
    800049e0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049e2:	00850913          	addi	s2,a0,8
    800049e6:	854a                	mv	a0,s2
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	202080e7          	jalr	514(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049f0:	409c                	lw	a5,0(s1)
    800049f2:	ef99                	bnez	a5,80004a10 <holdingsleep+0x3e>
    800049f4:	4481                	li	s1,0
  release(&lk->lk);
    800049f6:	854a                	mv	a0,s2
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	2a6080e7          	jalr	678(ra) # 80000c9e <release>
  return r;
}
    80004a00:	8526                	mv	a0,s1
    80004a02:	70a2                	ld	ra,40(sp)
    80004a04:	7402                	ld	s0,32(sp)
    80004a06:	64e2                	ld	s1,24(sp)
    80004a08:	6942                	ld	s2,16(sp)
    80004a0a:	69a2                	ld	s3,8(sp)
    80004a0c:	6145                	addi	sp,sp,48
    80004a0e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a10:	0284a983          	lw	s3,40(s1)
    80004a14:	ffffd097          	auipc	ra,0xffffd
    80004a18:	fe2080e7          	jalr	-30(ra) # 800019f6 <myproc>
    80004a1c:	5904                	lw	s1,48(a0)
    80004a1e:	413484b3          	sub	s1,s1,s3
    80004a22:	0014b493          	seqz	s1,s1
    80004a26:	bfc1                	j	800049f6 <holdingsleep+0x24>

0000000080004a28 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a28:	1141                	addi	sp,sp,-16
    80004a2a:	e406                	sd	ra,8(sp)
    80004a2c:	e022                	sd	s0,0(sp)
    80004a2e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a30:	00004597          	auipc	a1,0x4
    80004a34:	da058593          	addi	a1,a1,-608 # 800087d0 <syscalls+0x260>
    80004a38:	0001e517          	auipc	a0,0x1e
    80004a3c:	08050513          	addi	a0,a0,128 # 80022ab8 <ftable>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	11a080e7          	jalr	282(ra) # 80000b5a <initlock>
}
    80004a48:	60a2                	ld	ra,8(sp)
    80004a4a:	6402                	ld	s0,0(sp)
    80004a4c:	0141                	addi	sp,sp,16
    80004a4e:	8082                	ret

0000000080004a50 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a50:	1101                	addi	sp,sp,-32
    80004a52:	ec06                	sd	ra,24(sp)
    80004a54:	e822                	sd	s0,16(sp)
    80004a56:	e426                	sd	s1,8(sp)
    80004a58:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a5a:	0001e517          	auipc	a0,0x1e
    80004a5e:	05e50513          	addi	a0,a0,94 # 80022ab8 <ftable>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	188080e7          	jalr	392(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a6a:	0001e497          	auipc	s1,0x1e
    80004a6e:	06648493          	addi	s1,s1,102 # 80022ad0 <ftable+0x18>
    80004a72:	0001f717          	auipc	a4,0x1f
    80004a76:	ffe70713          	addi	a4,a4,-2 # 80023a70 <disk>
    if(f->ref == 0){
    80004a7a:	40dc                	lw	a5,4(s1)
    80004a7c:	cf99                	beqz	a5,80004a9a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a7e:	02848493          	addi	s1,s1,40
    80004a82:	fee49ce3          	bne	s1,a4,80004a7a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a86:	0001e517          	auipc	a0,0x1e
    80004a8a:	03250513          	addi	a0,a0,50 # 80022ab8 <ftable>
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	210080e7          	jalr	528(ra) # 80000c9e <release>
  return 0;
    80004a96:	4481                	li	s1,0
    80004a98:	a819                	j	80004aae <filealloc+0x5e>
      f->ref = 1;
    80004a9a:	4785                	li	a5,1
    80004a9c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a9e:	0001e517          	auipc	a0,0x1e
    80004aa2:	01a50513          	addi	a0,a0,26 # 80022ab8 <ftable>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	1f8080e7          	jalr	504(ra) # 80000c9e <release>
}
    80004aae:	8526                	mv	a0,s1
    80004ab0:	60e2                	ld	ra,24(sp)
    80004ab2:	6442                	ld	s0,16(sp)
    80004ab4:	64a2                	ld	s1,8(sp)
    80004ab6:	6105                	addi	sp,sp,32
    80004ab8:	8082                	ret

0000000080004aba <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004aba:	1101                	addi	sp,sp,-32
    80004abc:	ec06                	sd	ra,24(sp)
    80004abe:	e822                	sd	s0,16(sp)
    80004ac0:	e426                	sd	s1,8(sp)
    80004ac2:	1000                	addi	s0,sp,32
    80004ac4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ac6:	0001e517          	auipc	a0,0x1e
    80004aca:	ff250513          	addi	a0,a0,-14 # 80022ab8 <ftable>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	11c080e7          	jalr	284(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004ad6:	40dc                	lw	a5,4(s1)
    80004ad8:	02f05263          	blez	a5,80004afc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004adc:	2785                	addiw	a5,a5,1
    80004ade:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ae0:	0001e517          	auipc	a0,0x1e
    80004ae4:	fd850513          	addi	a0,a0,-40 # 80022ab8 <ftable>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	1b6080e7          	jalr	438(ra) # 80000c9e <release>
  return f;
}
    80004af0:	8526                	mv	a0,s1
    80004af2:	60e2                	ld	ra,24(sp)
    80004af4:	6442                	ld	s0,16(sp)
    80004af6:	64a2                	ld	s1,8(sp)
    80004af8:	6105                	addi	sp,sp,32
    80004afa:	8082                	ret
    panic("filedup");
    80004afc:	00004517          	auipc	a0,0x4
    80004b00:	cdc50513          	addi	a0,a0,-804 # 800087d8 <syscalls+0x268>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	a40080e7          	jalr	-1472(ra) # 80000544 <panic>

0000000080004b0c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b0c:	7139                	addi	sp,sp,-64
    80004b0e:	fc06                	sd	ra,56(sp)
    80004b10:	f822                	sd	s0,48(sp)
    80004b12:	f426                	sd	s1,40(sp)
    80004b14:	f04a                	sd	s2,32(sp)
    80004b16:	ec4e                	sd	s3,24(sp)
    80004b18:	e852                	sd	s4,16(sp)
    80004b1a:	e456                	sd	s5,8(sp)
    80004b1c:	0080                	addi	s0,sp,64
    80004b1e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b20:	0001e517          	auipc	a0,0x1e
    80004b24:	f9850513          	addi	a0,a0,-104 # 80022ab8 <ftable>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	0c2080e7          	jalr	194(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004b30:	40dc                	lw	a5,4(s1)
    80004b32:	06f05163          	blez	a5,80004b94 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b36:	37fd                	addiw	a5,a5,-1
    80004b38:	0007871b          	sext.w	a4,a5
    80004b3c:	c0dc                	sw	a5,4(s1)
    80004b3e:	06e04363          	bgtz	a4,80004ba4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b42:	0004a903          	lw	s2,0(s1)
    80004b46:	0094ca83          	lbu	s5,9(s1)
    80004b4a:	0104ba03          	ld	s4,16(s1)
    80004b4e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b52:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b56:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b5a:	0001e517          	auipc	a0,0x1e
    80004b5e:	f5e50513          	addi	a0,a0,-162 # 80022ab8 <ftable>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	13c080e7          	jalr	316(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004b6a:	4785                	li	a5,1
    80004b6c:	04f90d63          	beq	s2,a5,80004bc6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b70:	3979                	addiw	s2,s2,-2
    80004b72:	4785                	li	a5,1
    80004b74:	0527e063          	bltu	a5,s2,80004bb4 <fileclose+0xa8>
    begin_op();
    80004b78:	00000097          	auipc	ra,0x0
    80004b7c:	ac8080e7          	jalr	-1336(ra) # 80004640 <begin_op>
    iput(ff.ip);
    80004b80:	854e                	mv	a0,s3
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	2b6080e7          	jalr	694(ra) # 80003e38 <iput>
    end_op();
    80004b8a:	00000097          	auipc	ra,0x0
    80004b8e:	b36080e7          	jalr	-1226(ra) # 800046c0 <end_op>
    80004b92:	a00d                	j	80004bb4 <fileclose+0xa8>
    panic("fileclose");
    80004b94:	00004517          	auipc	a0,0x4
    80004b98:	c4c50513          	addi	a0,a0,-948 # 800087e0 <syscalls+0x270>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	9a8080e7          	jalr	-1624(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004ba4:	0001e517          	auipc	a0,0x1e
    80004ba8:	f1450513          	addi	a0,a0,-236 # 80022ab8 <ftable>
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	0f2080e7          	jalr	242(ra) # 80000c9e <release>
  }
}
    80004bb4:	70e2                	ld	ra,56(sp)
    80004bb6:	7442                	ld	s0,48(sp)
    80004bb8:	74a2                	ld	s1,40(sp)
    80004bba:	7902                	ld	s2,32(sp)
    80004bbc:	69e2                	ld	s3,24(sp)
    80004bbe:	6a42                	ld	s4,16(sp)
    80004bc0:	6aa2                	ld	s5,8(sp)
    80004bc2:	6121                	addi	sp,sp,64
    80004bc4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bc6:	85d6                	mv	a1,s5
    80004bc8:	8552                	mv	a0,s4
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	34c080e7          	jalr	844(ra) # 80004f16 <pipeclose>
    80004bd2:	b7cd                	j	80004bb4 <fileclose+0xa8>

0000000080004bd4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bd4:	715d                	addi	sp,sp,-80
    80004bd6:	e486                	sd	ra,72(sp)
    80004bd8:	e0a2                	sd	s0,64(sp)
    80004bda:	fc26                	sd	s1,56(sp)
    80004bdc:	f84a                	sd	s2,48(sp)
    80004bde:	f44e                	sd	s3,40(sp)
    80004be0:	0880                	addi	s0,sp,80
    80004be2:	84aa                	mv	s1,a0
    80004be4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	e10080e7          	jalr	-496(ra) # 800019f6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bee:	409c                	lw	a5,0(s1)
    80004bf0:	37f9                	addiw	a5,a5,-2
    80004bf2:	4705                	li	a4,1
    80004bf4:	04f76763          	bltu	a4,a5,80004c42 <filestat+0x6e>
    80004bf8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bfa:	6c88                	ld	a0,24(s1)
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	082080e7          	jalr	130(ra) # 80003c7e <ilock>
    stati(f->ip, &st);
    80004c04:	fb840593          	addi	a1,s0,-72
    80004c08:	6c88                	ld	a0,24(s1)
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	2fe080e7          	jalr	766(ra) # 80003f08 <stati>
    iunlock(f->ip);
    80004c12:	6c88                	ld	a0,24(s1)
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	12c080e7          	jalr	300(ra) # 80003d40 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c1c:	46e1                	li	a3,24
    80004c1e:	fb840613          	addi	a2,s0,-72
    80004c22:	85ce                	mv	a1,s3
    80004c24:	05893503          	ld	a0,88(s2)
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	a5c080e7          	jalr	-1444(ra) # 80001684 <copyout>
    80004c30:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c34:	60a6                	ld	ra,72(sp)
    80004c36:	6406                	ld	s0,64(sp)
    80004c38:	74e2                	ld	s1,56(sp)
    80004c3a:	7942                	ld	s2,48(sp)
    80004c3c:	79a2                	ld	s3,40(sp)
    80004c3e:	6161                	addi	sp,sp,80
    80004c40:	8082                	ret
  return -1;
    80004c42:	557d                	li	a0,-1
    80004c44:	bfc5                	j	80004c34 <filestat+0x60>

0000000080004c46 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c46:	7179                	addi	sp,sp,-48
    80004c48:	f406                	sd	ra,40(sp)
    80004c4a:	f022                	sd	s0,32(sp)
    80004c4c:	ec26                	sd	s1,24(sp)
    80004c4e:	e84a                	sd	s2,16(sp)
    80004c50:	e44e                	sd	s3,8(sp)
    80004c52:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c54:	00854783          	lbu	a5,8(a0)
    80004c58:	c3d5                	beqz	a5,80004cfc <fileread+0xb6>
    80004c5a:	84aa                	mv	s1,a0
    80004c5c:	89ae                	mv	s3,a1
    80004c5e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c60:	411c                	lw	a5,0(a0)
    80004c62:	4705                	li	a4,1
    80004c64:	04e78963          	beq	a5,a4,80004cb6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c68:	470d                	li	a4,3
    80004c6a:	04e78d63          	beq	a5,a4,80004cc4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c6e:	4709                	li	a4,2
    80004c70:	06e79e63          	bne	a5,a4,80004cec <fileread+0xa6>
    ilock(f->ip);
    80004c74:	6d08                	ld	a0,24(a0)
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	008080e7          	jalr	8(ra) # 80003c7e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c7e:	874a                	mv	a4,s2
    80004c80:	5094                	lw	a3,32(s1)
    80004c82:	864e                	mv	a2,s3
    80004c84:	4585                	li	a1,1
    80004c86:	6c88                	ld	a0,24(s1)
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	2aa080e7          	jalr	682(ra) # 80003f32 <readi>
    80004c90:	892a                	mv	s2,a0
    80004c92:	00a05563          	blez	a0,80004c9c <fileread+0x56>
      f->off += r;
    80004c96:	509c                	lw	a5,32(s1)
    80004c98:	9fa9                	addw	a5,a5,a0
    80004c9a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c9c:	6c88                	ld	a0,24(s1)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	0a2080e7          	jalr	162(ra) # 80003d40 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ca6:	854a                	mv	a0,s2
    80004ca8:	70a2                	ld	ra,40(sp)
    80004caa:	7402                	ld	s0,32(sp)
    80004cac:	64e2                	ld	s1,24(sp)
    80004cae:	6942                	ld	s2,16(sp)
    80004cb0:	69a2                	ld	s3,8(sp)
    80004cb2:	6145                	addi	sp,sp,48
    80004cb4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cb6:	6908                	ld	a0,16(a0)
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	3ce080e7          	jalr	974(ra) # 80005086 <piperead>
    80004cc0:	892a                	mv	s2,a0
    80004cc2:	b7d5                	j	80004ca6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cc4:	02451783          	lh	a5,36(a0)
    80004cc8:	03079693          	slli	a3,a5,0x30
    80004ccc:	92c1                	srli	a3,a3,0x30
    80004cce:	4725                	li	a4,9
    80004cd0:	02d76863          	bltu	a4,a3,80004d00 <fileread+0xba>
    80004cd4:	0792                	slli	a5,a5,0x4
    80004cd6:	0001e717          	auipc	a4,0x1e
    80004cda:	d4270713          	addi	a4,a4,-702 # 80022a18 <devsw>
    80004cde:	97ba                	add	a5,a5,a4
    80004ce0:	639c                	ld	a5,0(a5)
    80004ce2:	c38d                	beqz	a5,80004d04 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ce4:	4505                	li	a0,1
    80004ce6:	9782                	jalr	a5
    80004ce8:	892a                	mv	s2,a0
    80004cea:	bf75                	j	80004ca6 <fileread+0x60>
    panic("fileread");
    80004cec:	00004517          	auipc	a0,0x4
    80004cf0:	b0450513          	addi	a0,a0,-1276 # 800087f0 <syscalls+0x280>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	850080e7          	jalr	-1968(ra) # 80000544 <panic>
    return -1;
    80004cfc:	597d                	li	s2,-1
    80004cfe:	b765                	j	80004ca6 <fileread+0x60>
      return -1;
    80004d00:	597d                	li	s2,-1
    80004d02:	b755                	j	80004ca6 <fileread+0x60>
    80004d04:	597d                	li	s2,-1
    80004d06:	b745                	j	80004ca6 <fileread+0x60>

0000000080004d08 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d08:	715d                	addi	sp,sp,-80
    80004d0a:	e486                	sd	ra,72(sp)
    80004d0c:	e0a2                	sd	s0,64(sp)
    80004d0e:	fc26                	sd	s1,56(sp)
    80004d10:	f84a                	sd	s2,48(sp)
    80004d12:	f44e                	sd	s3,40(sp)
    80004d14:	f052                	sd	s4,32(sp)
    80004d16:	ec56                	sd	s5,24(sp)
    80004d18:	e85a                	sd	s6,16(sp)
    80004d1a:	e45e                	sd	s7,8(sp)
    80004d1c:	e062                	sd	s8,0(sp)
    80004d1e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d20:	00954783          	lbu	a5,9(a0)
    80004d24:	10078663          	beqz	a5,80004e30 <filewrite+0x128>
    80004d28:	892a                	mv	s2,a0
    80004d2a:	8aae                	mv	s5,a1
    80004d2c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d2e:	411c                	lw	a5,0(a0)
    80004d30:	4705                	li	a4,1
    80004d32:	02e78263          	beq	a5,a4,80004d56 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d36:	470d                	li	a4,3
    80004d38:	02e78663          	beq	a5,a4,80004d64 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d3c:	4709                	li	a4,2
    80004d3e:	0ee79163          	bne	a5,a4,80004e20 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d42:	0ac05d63          	blez	a2,80004dfc <filewrite+0xf4>
    int i = 0;
    80004d46:	4981                	li	s3,0
    80004d48:	6b05                	lui	s6,0x1
    80004d4a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d4e:	6b85                	lui	s7,0x1
    80004d50:	c00b8b9b          	addiw	s7,s7,-1024
    80004d54:	a861                	j	80004dec <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d56:	6908                	ld	a0,16(a0)
    80004d58:	00000097          	auipc	ra,0x0
    80004d5c:	22e080e7          	jalr	558(ra) # 80004f86 <pipewrite>
    80004d60:	8a2a                	mv	s4,a0
    80004d62:	a045                	j	80004e02 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d64:	02451783          	lh	a5,36(a0)
    80004d68:	03079693          	slli	a3,a5,0x30
    80004d6c:	92c1                	srli	a3,a3,0x30
    80004d6e:	4725                	li	a4,9
    80004d70:	0cd76263          	bltu	a4,a3,80004e34 <filewrite+0x12c>
    80004d74:	0792                	slli	a5,a5,0x4
    80004d76:	0001e717          	auipc	a4,0x1e
    80004d7a:	ca270713          	addi	a4,a4,-862 # 80022a18 <devsw>
    80004d7e:	97ba                	add	a5,a5,a4
    80004d80:	679c                	ld	a5,8(a5)
    80004d82:	cbdd                	beqz	a5,80004e38 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d84:	4505                	li	a0,1
    80004d86:	9782                	jalr	a5
    80004d88:	8a2a                	mv	s4,a0
    80004d8a:	a8a5                	j	80004e02 <filewrite+0xfa>
    80004d8c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d90:	00000097          	auipc	ra,0x0
    80004d94:	8b0080e7          	jalr	-1872(ra) # 80004640 <begin_op>
      ilock(f->ip);
    80004d98:	01893503          	ld	a0,24(s2)
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	ee2080e7          	jalr	-286(ra) # 80003c7e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004da4:	8762                	mv	a4,s8
    80004da6:	02092683          	lw	a3,32(s2)
    80004daa:	01598633          	add	a2,s3,s5
    80004dae:	4585                	li	a1,1
    80004db0:	01893503          	ld	a0,24(s2)
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	276080e7          	jalr	630(ra) # 8000402a <writei>
    80004dbc:	84aa                	mv	s1,a0
    80004dbe:	00a05763          	blez	a0,80004dcc <filewrite+0xc4>
        f->off += r;
    80004dc2:	02092783          	lw	a5,32(s2)
    80004dc6:	9fa9                	addw	a5,a5,a0
    80004dc8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dcc:	01893503          	ld	a0,24(s2)
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	f70080e7          	jalr	-144(ra) # 80003d40 <iunlock>
      end_op();
    80004dd8:	00000097          	auipc	ra,0x0
    80004ddc:	8e8080e7          	jalr	-1816(ra) # 800046c0 <end_op>

      if(r != n1){
    80004de0:	009c1f63          	bne	s8,s1,80004dfe <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004de4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004de8:	0149db63          	bge	s3,s4,80004dfe <filewrite+0xf6>
      int n1 = n - i;
    80004dec:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004df0:	84be                	mv	s1,a5
    80004df2:	2781                	sext.w	a5,a5
    80004df4:	f8fb5ce3          	bge	s6,a5,80004d8c <filewrite+0x84>
    80004df8:	84de                	mv	s1,s7
    80004dfa:	bf49                	j	80004d8c <filewrite+0x84>
    int i = 0;
    80004dfc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dfe:	013a1f63          	bne	s4,s3,80004e1c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e02:	8552                	mv	a0,s4
    80004e04:	60a6                	ld	ra,72(sp)
    80004e06:	6406                	ld	s0,64(sp)
    80004e08:	74e2                	ld	s1,56(sp)
    80004e0a:	7942                	ld	s2,48(sp)
    80004e0c:	79a2                	ld	s3,40(sp)
    80004e0e:	7a02                	ld	s4,32(sp)
    80004e10:	6ae2                	ld	s5,24(sp)
    80004e12:	6b42                	ld	s6,16(sp)
    80004e14:	6ba2                	ld	s7,8(sp)
    80004e16:	6c02                	ld	s8,0(sp)
    80004e18:	6161                	addi	sp,sp,80
    80004e1a:	8082                	ret
    ret = (i == n ? n : -1);
    80004e1c:	5a7d                	li	s4,-1
    80004e1e:	b7d5                	j	80004e02 <filewrite+0xfa>
    panic("filewrite");
    80004e20:	00004517          	auipc	a0,0x4
    80004e24:	9e050513          	addi	a0,a0,-1568 # 80008800 <syscalls+0x290>
    80004e28:	ffffb097          	auipc	ra,0xffffb
    80004e2c:	71c080e7          	jalr	1820(ra) # 80000544 <panic>
    return -1;
    80004e30:	5a7d                	li	s4,-1
    80004e32:	bfc1                	j	80004e02 <filewrite+0xfa>
      return -1;
    80004e34:	5a7d                	li	s4,-1
    80004e36:	b7f1                	j	80004e02 <filewrite+0xfa>
    80004e38:	5a7d                	li	s4,-1
    80004e3a:	b7e1                	j	80004e02 <filewrite+0xfa>

0000000080004e3c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e3c:	7179                	addi	sp,sp,-48
    80004e3e:	f406                	sd	ra,40(sp)
    80004e40:	f022                	sd	s0,32(sp)
    80004e42:	ec26                	sd	s1,24(sp)
    80004e44:	e84a                	sd	s2,16(sp)
    80004e46:	e44e                	sd	s3,8(sp)
    80004e48:	e052                	sd	s4,0(sp)
    80004e4a:	1800                	addi	s0,sp,48
    80004e4c:	84aa                	mv	s1,a0
    80004e4e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e50:	0005b023          	sd	zero,0(a1)
    80004e54:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e58:	00000097          	auipc	ra,0x0
    80004e5c:	bf8080e7          	jalr	-1032(ra) # 80004a50 <filealloc>
    80004e60:	e088                	sd	a0,0(s1)
    80004e62:	c551                	beqz	a0,80004eee <pipealloc+0xb2>
    80004e64:	00000097          	auipc	ra,0x0
    80004e68:	bec080e7          	jalr	-1044(ra) # 80004a50 <filealloc>
    80004e6c:	00aa3023          	sd	a0,0(s4)
    80004e70:	c92d                	beqz	a0,80004ee2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	c88080e7          	jalr	-888(ra) # 80000afa <kalloc>
    80004e7a:	892a                	mv	s2,a0
    80004e7c:	c125                	beqz	a0,80004edc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e7e:	4985                	li	s3,1
    80004e80:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e84:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e88:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e8c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e90:	00003597          	auipc	a1,0x3
    80004e94:	60058593          	addi	a1,a1,1536 # 80008490 <states.1779+0x1c8>
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	cc2080e7          	jalr	-830(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004ea0:	609c                	ld	a5,0(s1)
    80004ea2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ea6:	609c                	ld	a5,0(s1)
    80004ea8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004eac:	609c                	ld	a5,0(s1)
    80004eae:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004eb2:	609c                	ld	a5,0(s1)
    80004eb4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004eb8:	000a3783          	ld	a5,0(s4)
    80004ebc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ec0:	000a3783          	ld	a5,0(s4)
    80004ec4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ec8:	000a3783          	ld	a5,0(s4)
    80004ecc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ed0:	000a3783          	ld	a5,0(s4)
    80004ed4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ed8:	4501                	li	a0,0
    80004eda:	a025                	j	80004f02 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004edc:	6088                	ld	a0,0(s1)
    80004ede:	e501                	bnez	a0,80004ee6 <pipealloc+0xaa>
    80004ee0:	a039                	j	80004eee <pipealloc+0xb2>
    80004ee2:	6088                	ld	a0,0(s1)
    80004ee4:	c51d                	beqz	a0,80004f12 <pipealloc+0xd6>
    fileclose(*f0);
    80004ee6:	00000097          	auipc	ra,0x0
    80004eea:	c26080e7          	jalr	-986(ra) # 80004b0c <fileclose>
  if(*f1)
    80004eee:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ef2:	557d                	li	a0,-1
  if(*f1)
    80004ef4:	c799                	beqz	a5,80004f02 <pipealloc+0xc6>
    fileclose(*f1);
    80004ef6:	853e                	mv	a0,a5
    80004ef8:	00000097          	auipc	ra,0x0
    80004efc:	c14080e7          	jalr	-1004(ra) # 80004b0c <fileclose>
  return -1;
    80004f00:	557d                	li	a0,-1
}
    80004f02:	70a2                	ld	ra,40(sp)
    80004f04:	7402                	ld	s0,32(sp)
    80004f06:	64e2                	ld	s1,24(sp)
    80004f08:	6942                	ld	s2,16(sp)
    80004f0a:	69a2                	ld	s3,8(sp)
    80004f0c:	6a02                	ld	s4,0(sp)
    80004f0e:	6145                	addi	sp,sp,48
    80004f10:	8082                	ret
  return -1;
    80004f12:	557d                	li	a0,-1
    80004f14:	b7fd                	j	80004f02 <pipealloc+0xc6>

0000000080004f16 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f16:	1101                	addi	sp,sp,-32
    80004f18:	ec06                	sd	ra,24(sp)
    80004f1a:	e822                	sd	s0,16(sp)
    80004f1c:	e426                	sd	s1,8(sp)
    80004f1e:	e04a                	sd	s2,0(sp)
    80004f20:	1000                	addi	s0,sp,32
    80004f22:	84aa                	mv	s1,a0
    80004f24:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	cc4080e7          	jalr	-828(ra) # 80000bea <acquire>
  if(writable){
    80004f2e:	02090d63          	beqz	s2,80004f68 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f32:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f36:	21848513          	addi	a0,s1,536
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	3e2080e7          	jalr	994(ra) # 8000231c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f42:	2204b783          	ld	a5,544(s1)
    80004f46:	eb95                	bnez	a5,80004f7a <pipeclose+0x64>
    release(&pi->lock);
    80004f48:	8526                	mv	a0,s1
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	d54080e7          	jalr	-684(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004f52:	8526                	mv	a0,s1
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	aaa080e7          	jalr	-1366(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004f5c:	60e2                	ld	ra,24(sp)
    80004f5e:	6442                	ld	s0,16(sp)
    80004f60:	64a2                	ld	s1,8(sp)
    80004f62:	6902                	ld	s2,0(sp)
    80004f64:	6105                	addi	sp,sp,32
    80004f66:	8082                	ret
    pi->readopen = 0;
    80004f68:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f6c:	21c48513          	addi	a0,s1,540
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	3ac080e7          	jalr	940(ra) # 8000231c <wakeup>
    80004f78:	b7e9                	j	80004f42 <pipeclose+0x2c>
    release(&pi->lock);
    80004f7a:	8526                	mv	a0,s1
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	d22080e7          	jalr	-734(ra) # 80000c9e <release>
}
    80004f84:	bfe1                	j	80004f5c <pipeclose+0x46>

0000000080004f86 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f86:	7159                	addi	sp,sp,-112
    80004f88:	f486                	sd	ra,104(sp)
    80004f8a:	f0a2                	sd	s0,96(sp)
    80004f8c:	eca6                	sd	s1,88(sp)
    80004f8e:	e8ca                	sd	s2,80(sp)
    80004f90:	e4ce                	sd	s3,72(sp)
    80004f92:	e0d2                	sd	s4,64(sp)
    80004f94:	fc56                	sd	s5,56(sp)
    80004f96:	f85a                	sd	s6,48(sp)
    80004f98:	f45e                	sd	s7,40(sp)
    80004f9a:	f062                	sd	s8,32(sp)
    80004f9c:	ec66                	sd	s9,24(sp)
    80004f9e:	1880                	addi	s0,sp,112
    80004fa0:	84aa                	mv	s1,a0
    80004fa2:	8aae                	mv	s5,a1
    80004fa4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	a50080e7          	jalr	-1456(ra) # 800019f6 <myproc>
    80004fae:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	c38080e7          	jalr	-968(ra) # 80000bea <acquire>
  while(i < n){
    80004fba:	0d405463          	blez	s4,80005082 <pipewrite+0xfc>
    80004fbe:	8ba6                	mv	s7,s1
  int i = 0;
    80004fc0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fc2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fc4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fc8:	21c48c13          	addi	s8,s1,540
    80004fcc:	a08d                	j	8000502e <pipewrite+0xa8>
      release(&pi->lock);
    80004fce:	8526                	mv	a0,s1
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	cce080e7          	jalr	-818(ra) # 80000c9e <release>
      return -1;
    80004fd8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fda:	854a                	mv	a0,s2
    80004fdc:	70a6                	ld	ra,104(sp)
    80004fde:	7406                	ld	s0,96(sp)
    80004fe0:	64e6                	ld	s1,88(sp)
    80004fe2:	6946                	ld	s2,80(sp)
    80004fe4:	69a6                	ld	s3,72(sp)
    80004fe6:	6a06                	ld	s4,64(sp)
    80004fe8:	7ae2                	ld	s5,56(sp)
    80004fea:	7b42                	ld	s6,48(sp)
    80004fec:	7ba2                	ld	s7,40(sp)
    80004fee:	7c02                	ld	s8,32(sp)
    80004ff0:	6ce2                	ld	s9,24(sp)
    80004ff2:	6165                	addi	sp,sp,112
    80004ff4:	8082                	ret
      wakeup(&pi->nread);
    80004ff6:	8566                	mv	a0,s9
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	324080e7          	jalr	804(ra) # 8000231c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005000:	85de                	mv	a1,s7
    80005002:	8562                	mv	a0,s8
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	164080e7          	jalr	356(ra) # 80002168 <sleep>
    8000500c:	a839                	j	8000502a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000500e:	21c4a783          	lw	a5,540(s1)
    80005012:	0017871b          	addiw	a4,a5,1
    80005016:	20e4ae23          	sw	a4,540(s1)
    8000501a:	1ff7f793          	andi	a5,a5,511
    8000501e:	97a6                	add	a5,a5,s1
    80005020:	f9f44703          	lbu	a4,-97(s0)
    80005024:	00e78c23          	sb	a4,24(a5)
      i++;
    80005028:	2905                	addiw	s2,s2,1
  while(i < n){
    8000502a:	05495063          	bge	s2,s4,8000506a <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    8000502e:	2204a783          	lw	a5,544(s1)
    80005032:	dfd1                	beqz	a5,80004fce <pipewrite+0x48>
    80005034:	854e                	mv	a0,s3
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	536080e7          	jalr	1334(ra) # 8000256c <killed>
    8000503e:	f941                	bnez	a0,80004fce <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005040:	2184a783          	lw	a5,536(s1)
    80005044:	21c4a703          	lw	a4,540(s1)
    80005048:	2007879b          	addiw	a5,a5,512
    8000504c:	faf705e3          	beq	a4,a5,80004ff6 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005050:	4685                	li	a3,1
    80005052:	01590633          	add	a2,s2,s5
    80005056:	f9f40593          	addi	a1,s0,-97
    8000505a:	0589b503          	ld	a0,88(s3)
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	6b2080e7          	jalr	1714(ra) # 80001710 <copyin>
    80005066:	fb6514e3          	bne	a0,s6,8000500e <pipewrite+0x88>
  wakeup(&pi->nread);
    8000506a:	21848513          	addi	a0,s1,536
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	2ae080e7          	jalr	686(ra) # 8000231c <wakeup>
  release(&pi->lock);
    80005076:	8526                	mv	a0,s1
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	c26080e7          	jalr	-986(ra) # 80000c9e <release>
  return i;
    80005080:	bfa9                	j	80004fda <pipewrite+0x54>
  int i = 0;
    80005082:	4901                	li	s2,0
    80005084:	b7dd                	j	8000506a <pipewrite+0xe4>

0000000080005086 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005086:	715d                	addi	sp,sp,-80
    80005088:	e486                	sd	ra,72(sp)
    8000508a:	e0a2                	sd	s0,64(sp)
    8000508c:	fc26                	sd	s1,56(sp)
    8000508e:	f84a                	sd	s2,48(sp)
    80005090:	f44e                	sd	s3,40(sp)
    80005092:	f052                	sd	s4,32(sp)
    80005094:	ec56                	sd	s5,24(sp)
    80005096:	e85a                	sd	s6,16(sp)
    80005098:	0880                	addi	s0,sp,80
    8000509a:	84aa                	mv	s1,a0
    8000509c:	892e                	mv	s2,a1
    8000509e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	956080e7          	jalr	-1706(ra) # 800019f6 <myproc>
    800050a8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050aa:	8b26                	mv	s6,s1
    800050ac:	8526                	mv	a0,s1
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	b3c080e7          	jalr	-1220(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050b6:	2184a703          	lw	a4,536(s1)
    800050ba:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050be:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050c2:	02f71763          	bne	a4,a5,800050f0 <piperead+0x6a>
    800050c6:	2244a783          	lw	a5,548(s1)
    800050ca:	c39d                	beqz	a5,800050f0 <piperead+0x6a>
    if(killed(pr)){
    800050cc:	8552                	mv	a0,s4
    800050ce:	ffffd097          	auipc	ra,0xffffd
    800050d2:	49e080e7          	jalr	1182(ra) # 8000256c <killed>
    800050d6:	e941                	bnez	a0,80005166 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d8:	85da                	mv	a1,s6
    800050da:	854e                	mv	a0,s3
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	08c080e7          	jalr	140(ra) # 80002168 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050e4:	2184a703          	lw	a4,536(s1)
    800050e8:	21c4a783          	lw	a5,540(s1)
    800050ec:	fcf70de3          	beq	a4,a5,800050c6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f0:	09505263          	blez	s5,80005174 <piperead+0xee>
    800050f4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050f6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800050f8:	2184a783          	lw	a5,536(s1)
    800050fc:	21c4a703          	lw	a4,540(s1)
    80005100:	02f70d63          	beq	a4,a5,8000513a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005104:	0017871b          	addiw	a4,a5,1
    80005108:	20e4ac23          	sw	a4,536(s1)
    8000510c:	1ff7f793          	andi	a5,a5,511
    80005110:	97a6                	add	a5,a5,s1
    80005112:	0187c783          	lbu	a5,24(a5)
    80005116:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000511a:	4685                	li	a3,1
    8000511c:	fbf40613          	addi	a2,s0,-65
    80005120:	85ca                	mv	a1,s2
    80005122:	058a3503          	ld	a0,88(s4)
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	55e080e7          	jalr	1374(ra) # 80001684 <copyout>
    8000512e:	01650663          	beq	a0,s6,8000513a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005132:	2985                	addiw	s3,s3,1
    80005134:	0905                	addi	s2,s2,1
    80005136:	fd3a91e3          	bne	s5,s3,800050f8 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000513a:	21c48513          	addi	a0,s1,540
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	1de080e7          	jalr	478(ra) # 8000231c <wakeup>
  release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b56080e7          	jalr	-1194(ra) # 80000c9e <release>
  return i;
}
    80005150:	854e                	mv	a0,s3
    80005152:	60a6                	ld	ra,72(sp)
    80005154:	6406                	ld	s0,64(sp)
    80005156:	74e2                	ld	s1,56(sp)
    80005158:	7942                	ld	s2,48(sp)
    8000515a:	79a2                	ld	s3,40(sp)
    8000515c:	7a02                	ld	s4,32(sp)
    8000515e:	6ae2                	ld	s5,24(sp)
    80005160:	6b42                	ld	s6,16(sp)
    80005162:	6161                	addi	sp,sp,80
    80005164:	8082                	ret
      release(&pi->lock);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	b36080e7          	jalr	-1226(ra) # 80000c9e <release>
      return -1;
    80005170:	59fd                	li	s3,-1
    80005172:	bff9                	j	80005150 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005174:	4981                	li	s3,0
    80005176:	b7d1                	j	8000513a <piperead+0xb4>

0000000080005178 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005178:	1141                	addi	sp,sp,-16
    8000517a:	e422                	sd	s0,8(sp)
    8000517c:	0800                	addi	s0,sp,16
    8000517e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005180:	8905                	andi	a0,a0,1
    80005182:	c111                	beqz	a0,80005186 <flags2perm+0xe>
      perm = PTE_X;
    80005184:	4521                	li	a0,8
    if(flags & 0x2)
    80005186:	8b89                	andi	a5,a5,2
    80005188:	c399                	beqz	a5,8000518e <flags2perm+0x16>
      perm |= PTE_W;
    8000518a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000518e:	6422                	ld	s0,8(sp)
    80005190:	0141                	addi	sp,sp,16
    80005192:	8082                	ret

0000000080005194 <exec>:

int
exec(char *path, char **argv)
{
    80005194:	df010113          	addi	sp,sp,-528
    80005198:	20113423          	sd	ra,520(sp)
    8000519c:	20813023          	sd	s0,512(sp)
    800051a0:	ffa6                	sd	s1,504(sp)
    800051a2:	fbca                	sd	s2,496(sp)
    800051a4:	f7ce                	sd	s3,488(sp)
    800051a6:	f3d2                	sd	s4,480(sp)
    800051a8:	efd6                	sd	s5,472(sp)
    800051aa:	ebda                	sd	s6,464(sp)
    800051ac:	e7de                	sd	s7,456(sp)
    800051ae:	e3e2                	sd	s8,448(sp)
    800051b0:	ff66                	sd	s9,440(sp)
    800051b2:	fb6a                	sd	s10,432(sp)
    800051b4:	f76e                	sd	s11,424(sp)
    800051b6:	0c00                	addi	s0,sp,528
    800051b8:	84aa                	mv	s1,a0
    800051ba:	dea43c23          	sd	a0,-520(s0)
    800051be:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051c2:	ffffd097          	auipc	ra,0xffffd
    800051c6:	834080e7          	jalr	-1996(ra) # 800019f6 <myproc>
    800051ca:	892a                	mv	s2,a0

  begin_op();
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	474080e7          	jalr	1140(ra) # 80004640 <begin_op>

  if((ip = namei(path)) == 0){
    800051d4:	8526                	mv	a0,s1
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	24e080e7          	jalr	590(ra) # 80004424 <namei>
    800051de:	c92d                	beqz	a0,80005250 <exec+0xbc>
    800051e0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	a9c080e7          	jalr	-1380(ra) # 80003c7e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051ea:	04000713          	li	a4,64
    800051ee:	4681                	li	a3,0
    800051f0:	e5040613          	addi	a2,s0,-432
    800051f4:	4581                	li	a1,0
    800051f6:	8526                	mv	a0,s1
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	d3a080e7          	jalr	-710(ra) # 80003f32 <readi>
    80005200:	04000793          	li	a5,64
    80005204:	00f51a63          	bne	a0,a5,80005218 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005208:	e5042703          	lw	a4,-432(s0)
    8000520c:	464c47b7          	lui	a5,0x464c4
    80005210:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005214:	04f70463          	beq	a4,a5,8000525c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005218:	8526                	mv	a0,s1
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	cc6080e7          	jalr	-826(ra) # 80003ee0 <iunlockput>
    end_op();
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	49e080e7          	jalr	1182(ra) # 800046c0 <end_op>
  }
  return -1;
    8000522a:	557d                	li	a0,-1
}
    8000522c:	20813083          	ld	ra,520(sp)
    80005230:	20013403          	ld	s0,512(sp)
    80005234:	74fe                	ld	s1,504(sp)
    80005236:	795e                	ld	s2,496(sp)
    80005238:	79be                	ld	s3,488(sp)
    8000523a:	7a1e                	ld	s4,480(sp)
    8000523c:	6afe                	ld	s5,472(sp)
    8000523e:	6b5e                	ld	s6,464(sp)
    80005240:	6bbe                	ld	s7,456(sp)
    80005242:	6c1e                	ld	s8,448(sp)
    80005244:	7cfa                	ld	s9,440(sp)
    80005246:	7d5a                	ld	s10,432(sp)
    80005248:	7dba                	ld	s11,424(sp)
    8000524a:	21010113          	addi	sp,sp,528
    8000524e:	8082                	ret
    end_op();
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	470080e7          	jalr	1136(ra) # 800046c0 <end_op>
    return -1;
    80005258:	557d                	li	a0,-1
    8000525a:	bfc9                	j	8000522c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000525c:	854a                	mv	a0,s2
    8000525e:	ffffd097          	auipc	ra,0xffffd
    80005262:	85c080e7          	jalr	-1956(ra) # 80001aba <proc_pagetable>
    80005266:	8baa                	mv	s7,a0
    80005268:	d945                	beqz	a0,80005218 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000526a:	e7042983          	lw	s3,-400(s0)
    8000526e:	e8845783          	lhu	a5,-376(s0)
    80005272:	c7ad                	beqz	a5,800052dc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005274:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005276:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005278:	6c85                	lui	s9,0x1
    8000527a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000527e:	def43823          	sd	a5,-528(s0)
    80005282:	ac0d                	j	800054b4 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005284:	00003517          	auipc	a0,0x3
    80005288:	58c50513          	addi	a0,a0,1420 # 80008810 <syscalls+0x2a0>
    8000528c:	ffffb097          	auipc	ra,0xffffb
    80005290:	2b8080e7          	jalr	696(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005294:	8756                	mv	a4,s5
    80005296:	012d86bb          	addw	a3,s11,s2
    8000529a:	4581                	li	a1,0
    8000529c:	8526                	mv	a0,s1
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	c94080e7          	jalr	-876(ra) # 80003f32 <readi>
    800052a6:	2501                	sext.w	a0,a0
    800052a8:	1aaa9a63          	bne	s5,a0,8000545c <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800052ac:	6785                	lui	a5,0x1
    800052ae:	0127893b          	addw	s2,a5,s2
    800052b2:	77fd                	lui	a5,0xfffff
    800052b4:	01478a3b          	addw	s4,a5,s4
    800052b8:	1f897563          	bgeu	s2,s8,800054a2 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800052bc:	02091593          	slli	a1,s2,0x20
    800052c0:	9181                	srli	a1,a1,0x20
    800052c2:	95ea                	add	a1,a1,s10
    800052c4:	855e                	mv	a0,s7
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	db2080e7          	jalr	-590(ra) # 80001078 <walkaddr>
    800052ce:	862a                	mv	a2,a0
    if(pa == 0)
    800052d0:	d955                	beqz	a0,80005284 <exec+0xf0>
      n = PGSIZE;
    800052d2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800052d4:	fd9a70e3          	bgeu	s4,s9,80005294 <exec+0x100>
      n = sz - i;
    800052d8:	8ad2                	mv	s5,s4
    800052da:	bf6d                	j	80005294 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052dc:	4a01                	li	s4,0
  iunlockput(ip);
    800052de:	8526                	mv	a0,s1
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	c00080e7          	jalr	-1024(ra) # 80003ee0 <iunlockput>
  end_op();
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	3d8080e7          	jalr	984(ra) # 800046c0 <end_op>
  p = myproc();
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	706080e7          	jalr	1798(ra) # 800019f6 <myproc>
    800052f8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800052fa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052fe:	6785                	lui	a5,0x1
    80005300:	17fd                	addi	a5,a5,-1
    80005302:	9a3e                	add	s4,s4,a5
    80005304:	757d                	lui	a0,0xfffff
    80005306:	00aa77b3          	and	a5,s4,a0
    8000530a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000530e:	4691                	li	a3,4
    80005310:	6609                	lui	a2,0x2
    80005312:	963e                	add	a2,a2,a5
    80005314:	85be                	mv	a1,a5
    80005316:	855e                	mv	a0,s7
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	114080e7          	jalr	276(ra) # 8000142c <uvmalloc>
    80005320:	8b2a                	mv	s6,a0
  ip = 0;
    80005322:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005324:	12050c63          	beqz	a0,8000545c <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005328:	75f9                	lui	a1,0xffffe
    8000532a:	95aa                	add	a1,a1,a0
    8000532c:	855e                	mv	a0,s7
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	324080e7          	jalr	804(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005336:	7c7d                	lui	s8,0xfffff
    80005338:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000533a:	e0043783          	ld	a5,-512(s0)
    8000533e:	6388                	ld	a0,0(a5)
    80005340:	c535                	beqz	a0,800053ac <exec+0x218>
    80005342:	e9040993          	addi	s3,s0,-368
    80005346:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000534a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	b1e080e7          	jalr	-1250(ra) # 80000e6a <strlen>
    80005354:	2505                	addiw	a0,a0,1
    80005356:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000535a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000535e:	13896663          	bltu	s2,s8,8000548a <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005362:	e0043d83          	ld	s11,-512(s0)
    80005366:	000dba03          	ld	s4,0(s11)
    8000536a:	8552                	mv	a0,s4
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	afe080e7          	jalr	-1282(ra) # 80000e6a <strlen>
    80005374:	0015069b          	addiw	a3,a0,1
    80005378:	8652                	mv	a2,s4
    8000537a:	85ca                	mv	a1,s2
    8000537c:	855e                	mv	a0,s7
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	306080e7          	jalr	774(ra) # 80001684 <copyout>
    80005386:	10054663          	bltz	a0,80005492 <exec+0x2fe>
    ustack[argc] = sp;
    8000538a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000538e:	0485                	addi	s1,s1,1
    80005390:	008d8793          	addi	a5,s11,8
    80005394:	e0f43023          	sd	a5,-512(s0)
    80005398:	008db503          	ld	a0,8(s11)
    8000539c:	c911                	beqz	a0,800053b0 <exec+0x21c>
    if(argc >= MAXARG)
    8000539e:	09a1                	addi	s3,s3,8
    800053a0:	fb3c96e3          	bne	s9,s3,8000534c <exec+0x1b8>
  sz = sz1;
    800053a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053a8:	4481                	li	s1,0
    800053aa:	a84d                	j	8000545c <exec+0x2c8>
  sp = sz;
    800053ac:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053ae:	4481                	li	s1,0
  ustack[argc] = 0;
    800053b0:	00349793          	slli	a5,s1,0x3
    800053b4:	f9040713          	addi	a4,s0,-112
    800053b8:	97ba                	add	a5,a5,a4
    800053ba:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053be:	00148693          	addi	a3,s1,1
    800053c2:	068e                	slli	a3,a3,0x3
    800053c4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053c8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053cc:	01897663          	bgeu	s2,s8,800053d8 <exec+0x244>
  sz = sz1;
    800053d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d4:	4481                	li	s1,0
    800053d6:	a059                	j	8000545c <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053d8:	e9040613          	addi	a2,s0,-368
    800053dc:	85ca                	mv	a1,s2
    800053de:	855e                	mv	a0,s7
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	2a4080e7          	jalr	676(ra) # 80001684 <copyout>
    800053e8:	0a054963          	bltz	a0,8000549a <exec+0x306>
  p->trapframe->a1 = sp;
    800053ec:	060ab783          	ld	a5,96(s5)
    800053f0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053f4:	df843783          	ld	a5,-520(s0)
    800053f8:	0007c703          	lbu	a4,0(a5)
    800053fc:	cf11                	beqz	a4,80005418 <exec+0x284>
    800053fe:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005400:	02f00693          	li	a3,47
    80005404:	a039                	j	80005412 <exec+0x27e>
      last = s+1;
    80005406:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000540a:	0785                	addi	a5,a5,1
    8000540c:	fff7c703          	lbu	a4,-1(a5)
    80005410:	c701                	beqz	a4,80005418 <exec+0x284>
    if(*s == '/')
    80005412:	fed71ce3          	bne	a4,a3,8000540a <exec+0x276>
    80005416:	bfc5                	j	80005406 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005418:	4641                	li	a2,16
    8000541a:	df843583          	ld	a1,-520(s0)
    8000541e:	168a8513          	addi	a0,s5,360
    80005422:	ffffc097          	auipc	ra,0xffffc
    80005426:	a16080e7          	jalr	-1514(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    8000542a:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    8000542e:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005432:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005436:	060ab783          	ld	a5,96(s5)
    8000543a:	e6843703          	ld	a4,-408(s0)
    8000543e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005440:	060ab783          	ld	a5,96(s5)
    80005444:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005448:	85ea                	mv	a1,s10
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	70c080e7          	jalr	1804(ra) # 80001b56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005452:	0004851b          	sext.w	a0,s1
    80005456:	bbd9                	j	8000522c <exec+0x98>
    80005458:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000545c:	e0843583          	ld	a1,-504(s0)
    80005460:	855e                	mv	a0,s7
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	6f4080e7          	jalr	1780(ra) # 80001b56 <proc_freepagetable>
  if(ip){
    8000546a:	da0497e3          	bnez	s1,80005218 <exec+0x84>
  return -1;
    8000546e:	557d                	li	a0,-1
    80005470:	bb75                	j	8000522c <exec+0x98>
    80005472:	e1443423          	sd	s4,-504(s0)
    80005476:	b7dd                	j	8000545c <exec+0x2c8>
    80005478:	e1443423          	sd	s4,-504(s0)
    8000547c:	b7c5                	j	8000545c <exec+0x2c8>
    8000547e:	e1443423          	sd	s4,-504(s0)
    80005482:	bfe9                	j	8000545c <exec+0x2c8>
    80005484:	e1443423          	sd	s4,-504(s0)
    80005488:	bfd1                	j	8000545c <exec+0x2c8>
  sz = sz1;
    8000548a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000548e:	4481                	li	s1,0
    80005490:	b7f1                	j	8000545c <exec+0x2c8>
  sz = sz1;
    80005492:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005496:	4481                	li	s1,0
    80005498:	b7d1                	j	8000545c <exec+0x2c8>
  sz = sz1;
    8000549a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000549e:	4481                	li	s1,0
    800054a0:	bf75                	j	8000545c <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054a2:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054a6:	2b05                	addiw	s6,s6,1
    800054a8:	0389899b          	addiw	s3,s3,56
    800054ac:	e8845783          	lhu	a5,-376(s0)
    800054b0:	e2fb57e3          	bge	s6,a5,800052de <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054b4:	2981                	sext.w	s3,s3
    800054b6:	03800713          	li	a4,56
    800054ba:	86ce                	mv	a3,s3
    800054bc:	e1840613          	addi	a2,s0,-488
    800054c0:	4581                	li	a1,0
    800054c2:	8526                	mv	a0,s1
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	a6e080e7          	jalr	-1426(ra) # 80003f32 <readi>
    800054cc:	03800793          	li	a5,56
    800054d0:	f8f514e3          	bne	a0,a5,80005458 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800054d4:	e1842783          	lw	a5,-488(s0)
    800054d8:	4705                	li	a4,1
    800054da:	fce796e3          	bne	a5,a4,800054a6 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800054de:	e4043903          	ld	s2,-448(s0)
    800054e2:	e3843783          	ld	a5,-456(s0)
    800054e6:	f8f966e3          	bltu	s2,a5,80005472 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054ea:	e2843783          	ld	a5,-472(s0)
    800054ee:	993e                	add	s2,s2,a5
    800054f0:	f8f964e3          	bltu	s2,a5,80005478 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800054f4:	df043703          	ld	a4,-528(s0)
    800054f8:	8ff9                	and	a5,a5,a4
    800054fa:	f3d1                	bnez	a5,8000547e <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054fc:	e1c42503          	lw	a0,-484(s0)
    80005500:	00000097          	auipc	ra,0x0
    80005504:	c78080e7          	jalr	-904(ra) # 80005178 <flags2perm>
    80005508:	86aa                	mv	a3,a0
    8000550a:	864a                	mv	a2,s2
    8000550c:	85d2                	mv	a1,s4
    8000550e:	855e                	mv	a0,s7
    80005510:	ffffc097          	auipc	ra,0xffffc
    80005514:	f1c080e7          	jalr	-228(ra) # 8000142c <uvmalloc>
    80005518:	e0a43423          	sd	a0,-504(s0)
    8000551c:	d525                	beqz	a0,80005484 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000551e:	e2843d03          	ld	s10,-472(s0)
    80005522:	e2042d83          	lw	s11,-480(s0)
    80005526:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000552a:	f60c0ce3          	beqz	s8,800054a2 <exec+0x30e>
    8000552e:	8a62                	mv	s4,s8
    80005530:	4901                	li	s2,0
    80005532:	b369                	j	800052bc <exec+0x128>

0000000080005534 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005534:	7179                	addi	sp,sp,-48
    80005536:	f406                	sd	ra,40(sp)
    80005538:	f022                	sd	s0,32(sp)
    8000553a:	ec26                	sd	s1,24(sp)
    8000553c:	e84a                	sd	s2,16(sp)
    8000553e:	1800                	addi	s0,sp,48
    80005540:	892e                	mv	s2,a1
    80005542:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005544:	fdc40593          	addi	a1,s0,-36
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	8d2080e7          	jalr	-1838(ra) # 80002e1a <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005550:	fdc42703          	lw	a4,-36(s0)
    80005554:	47bd                	li	a5,15
    80005556:	02e7eb63          	bltu	a5,a4,8000558c <argfd+0x58>
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	49c080e7          	jalr	1180(ra) # 800019f6 <myproc>
    80005562:	fdc42703          	lw	a4,-36(s0)
    80005566:	01c70793          	addi	a5,a4,28
    8000556a:	078e                	slli	a5,a5,0x3
    8000556c:	953e                	add	a0,a0,a5
    8000556e:	611c                	ld	a5,0(a0)
    80005570:	c385                	beqz	a5,80005590 <argfd+0x5c>
    return -1;
  if(pfd)
    80005572:	00090463          	beqz	s2,8000557a <argfd+0x46>
    *pfd = fd;
    80005576:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000557a:	4501                	li	a0,0
  if(pf)
    8000557c:	c091                	beqz	s1,80005580 <argfd+0x4c>
    *pf = f;
    8000557e:	e09c                	sd	a5,0(s1)
}
    80005580:	70a2                	ld	ra,40(sp)
    80005582:	7402                	ld	s0,32(sp)
    80005584:	64e2                	ld	s1,24(sp)
    80005586:	6942                	ld	s2,16(sp)
    80005588:	6145                	addi	sp,sp,48
    8000558a:	8082                	ret
    return -1;
    8000558c:	557d                	li	a0,-1
    8000558e:	bfcd                	j	80005580 <argfd+0x4c>
    80005590:	557d                	li	a0,-1
    80005592:	b7fd                	j	80005580 <argfd+0x4c>

0000000080005594 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005594:	1101                	addi	sp,sp,-32
    80005596:	ec06                	sd	ra,24(sp)
    80005598:	e822                	sd	s0,16(sp)
    8000559a:	e426                	sd	s1,8(sp)
    8000559c:	1000                	addi	s0,sp,32
    8000559e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	456080e7          	jalr	1110(ra) # 800019f6 <myproc>
    800055a8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055aa:	0e050793          	addi	a5,a0,224 # fffffffffffff0e0 <end+0xffffffff7ffdb530>
    800055ae:	4501                	li	a0,0
    800055b0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055b2:	6398                	ld	a4,0(a5)
    800055b4:	cb19                	beqz	a4,800055ca <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055b6:	2505                	addiw	a0,a0,1
    800055b8:	07a1                	addi	a5,a5,8
    800055ba:	fed51ce3          	bne	a0,a3,800055b2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055be:	557d                	li	a0,-1
}
    800055c0:	60e2                	ld	ra,24(sp)
    800055c2:	6442                	ld	s0,16(sp)
    800055c4:	64a2                	ld	s1,8(sp)
    800055c6:	6105                	addi	sp,sp,32
    800055c8:	8082                	ret
      p->ofile[fd] = f;
    800055ca:	01c50793          	addi	a5,a0,28
    800055ce:	078e                	slli	a5,a5,0x3
    800055d0:	963e                	add	a2,a2,a5
    800055d2:	e204                	sd	s1,0(a2)
      return fd;
    800055d4:	b7f5                	j	800055c0 <fdalloc+0x2c>

00000000800055d6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055d6:	715d                	addi	sp,sp,-80
    800055d8:	e486                	sd	ra,72(sp)
    800055da:	e0a2                	sd	s0,64(sp)
    800055dc:	fc26                	sd	s1,56(sp)
    800055de:	f84a                	sd	s2,48(sp)
    800055e0:	f44e                	sd	s3,40(sp)
    800055e2:	f052                	sd	s4,32(sp)
    800055e4:	ec56                	sd	s5,24(sp)
    800055e6:	e85a                	sd	s6,16(sp)
    800055e8:	0880                	addi	s0,sp,80
    800055ea:	8b2e                	mv	s6,a1
    800055ec:	89b2                	mv	s3,a2
    800055ee:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055f0:	fb040593          	addi	a1,s0,-80
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	e4e080e7          	jalr	-434(ra) # 80004442 <nameiparent>
    800055fc:	84aa                	mv	s1,a0
    800055fe:	16050063          	beqz	a0,8000575e <create+0x188>
    return 0;

  ilock(dp);
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	67c080e7          	jalr	1660(ra) # 80003c7e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000560a:	4601                	li	a2,0
    8000560c:	fb040593          	addi	a1,s0,-80
    80005610:	8526                	mv	a0,s1
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	b50080e7          	jalr	-1200(ra) # 80004162 <dirlookup>
    8000561a:	8aaa                	mv	s5,a0
    8000561c:	c931                	beqz	a0,80005670 <create+0x9a>
    iunlockput(dp);
    8000561e:	8526                	mv	a0,s1
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	8c0080e7          	jalr	-1856(ra) # 80003ee0 <iunlockput>
    ilock(ip);
    80005628:	8556                	mv	a0,s5
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	654080e7          	jalr	1620(ra) # 80003c7e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005632:	000b059b          	sext.w	a1,s6
    80005636:	4789                	li	a5,2
    80005638:	02f59563          	bne	a1,a5,80005662 <create+0x8c>
    8000563c:	044ad783          	lhu	a5,68(s5)
    80005640:	37f9                	addiw	a5,a5,-2
    80005642:	17c2                	slli	a5,a5,0x30
    80005644:	93c1                	srli	a5,a5,0x30
    80005646:	4705                	li	a4,1
    80005648:	00f76d63          	bltu	a4,a5,80005662 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000564c:	8556                	mv	a0,s5
    8000564e:	60a6                	ld	ra,72(sp)
    80005650:	6406                	ld	s0,64(sp)
    80005652:	74e2                	ld	s1,56(sp)
    80005654:	7942                	ld	s2,48(sp)
    80005656:	79a2                	ld	s3,40(sp)
    80005658:	7a02                	ld	s4,32(sp)
    8000565a:	6ae2                	ld	s5,24(sp)
    8000565c:	6b42                	ld	s6,16(sp)
    8000565e:	6161                	addi	sp,sp,80
    80005660:	8082                	ret
    iunlockput(ip);
    80005662:	8556                	mv	a0,s5
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	87c080e7          	jalr	-1924(ra) # 80003ee0 <iunlockput>
    return 0;
    8000566c:	4a81                	li	s5,0
    8000566e:	bff9                	j	8000564c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005670:	85da                	mv	a1,s6
    80005672:	4088                	lw	a0,0(s1)
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	46e080e7          	jalr	1134(ra) # 80003ae2 <ialloc>
    8000567c:	8a2a                	mv	s4,a0
    8000567e:	c921                	beqz	a0,800056ce <create+0xf8>
  ilock(ip);
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	5fe080e7          	jalr	1534(ra) # 80003c7e <ilock>
  ip->major = major;
    80005688:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000568c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005690:	4785                	li	a5,1
    80005692:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005696:	8552                	mv	a0,s4
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	51c080e7          	jalr	1308(ra) # 80003bb4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056a0:	000b059b          	sext.w	a1,s6
    800056a4:	4785                	li	a5,1
    800056a6:	02f58b63          	beq	a1,a5,800056dc <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800056aa:	004a2603          	lw	a2,4(s4)
    800056ae:	fb040593          	addi	a1,s0,-80
    800056b2:	8526                	mv	a0,s1
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	cbe080e7          	jalr	-834(ra) # 80004372 <dirlink>
    800056bc:	06054f63          	bltz	a0,8000573a <create+0x164>
  iunlockput(dp);
    800056c0:	8526                	mv	a0,s1
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	81e080e7          	jalr	-2018(ra) # 80003ee0 <iunlockput>
  return ip;
    800056ca:	8ad2                	mv	s5,s4
    800056cc:	b741                	j	8000564c <create+0x76>
    iunlockput(dp);
    800056ce:	8526                	mv	a0,s1
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	810080e7          	jalr	-2032(ra) # 80003ee0 <iunlockput>
    return 0;
    800056d8:	8ad2                	mv	s5,s4
    800056da:	bf8d                	j	8000564c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056dc:	004a2603          	lw	a2,4(s4)
    800056e0:	00003597          	auipc	a1,0x3
    800056e4:	15058593          	addi	a1,a1,336 # 80008830 <syscalls+0x2c0>
    800056e8:	8552                	mv	a0,s4
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	c88080e7          	jalr	-888(ra) # 80004372 <dirlink>
    800056f2:	04054463          	bltz	a0,8000573a <create+0x164>
    800056f6:	40d0                	lw	a2,4(s1)
    800056f8:	00003597          	auipc	a1,0x3
    800056fc:	14058593          	addi	a1,a1,320 # 80008838 <syscalls+0x2c8>
    80005700:	8552                	mv	a0,s4
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	c70080e7          	jalr	-912(ra) # 80004372 <dirlink>
    8000570a:	02054863          	bltz	a0,8000573a <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000570e:	004a2603          	lw	a2,4(s4)
    80005712:	fb040593          	addi	a1,s0,-80
    80005716:	8526                	mv	a0,s1
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	c5a080e7          	jalr	-934(ra) # 80004372 <dirlink>
    80005720:	00054d63          	bltz	a0,8000573a <create+0x164>
    dp->nlink++;  // for ".."
    80005724:	04a4d783          	lhu	a5,74(s1)
    80005728:	2785                	addiw	a5,a5,1
    8000572a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000572e:	8526                	mv	a0,s1
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	484080e7          	jalr	1156(ra) # 80003bb4 <iupdate>
    80005738:	b761                	j	800056c0 <create+0xea>
  ip->nlink = 0;
    8000573a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000573e:	8552                	mv	a0,s4
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	474080e7          	jalr	1140(ra) # 80003bb4 <iupdate>
  iunlockput(ip);
    80005748:	8552                	mv	a0,s4
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	796080e7          	jalr	1942(ra) # 80003ee0 <iunlockput>
  iunlockput(dp);
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	78c080e7          	jalr	1932(ra) # 80003ee0 <iunlockput>
  return 0;
    8000575c:	bdc5                	j	8000564c <create+0x76>
    return 0;
    8000575e:	8aaa                	mv	s5,a0
    80005760:	b5f5                	j	8000564c <create+0x76>

0000000080005762 <sys_dup>:
{
    80005762:	7179                	addi	sp,sp,-48
    80005764:	f406                	sd	ra,40(sp)
    80005766:	f022                	sd	s0,32(sp)
    80005768:	ec26                	sd	s1,24(sp)
    8000576a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000576c:	fd840613          	addi	a2,s0,-40
    80005770:	4581                	li	a1,0
    80005772:	4501                	li	a0,0
    80005774:	00000097          	auipc	ra,0x0
    80005778:	dc0080e7          	jalr	-576(ra) # 80005534 <argfd>
    return -1;
    8000577c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000577e:	02054363          	bltz	a0,800057a4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005782:	fd843503          	ld	a0,-40(s0)
    80005786:	00000097          	auipc	ra,0x0
    8000578a:	e0e080e7          	jalr	-498(ra) # 80005594 <fdalloc>
    8000578e:	84aa                	mv	s1,a0
    return -1;
    80005790:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005792:	00054963          	bltz	a0,800057a4 <sys_dup+0x42>
  filedup(f);
    80005796:	fd843503          	ld	a0,-40(s0)
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	320080e7          	jalr	800(ra) # 80004aba <filedup>
  return fd;
    800057a2:	87a6                	mv	a5,s1
}
    800057a4:	853e                	mv	a0,a5
    800057a6:	70a2                	ld	ra,40(sp)
    800057a8:	7402                	ld	s0,32(sp)
    800057aa:	64e2                	ld	s1,24(sp)
    800057ac:	6145                	addi	sp,sp,48
    800057ae:	8082                	ret

00000000800057b0 <sys_read>:
{
    800057b0:	7179                	addi	sp,sp,-48
    800057b2:	f406                	sd	ra,40(sp)
    800057b4:	f022                	sd	s0,32(sp)
    800057b6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057b8:	fd840593          	addi	a1,s0,-40
    800057bc:	4505                	li	a0,1
    800057be:	ffffd097          	auipc	ra,0xffffd
    800057c2:	67e080e7          	jalr	1662(ra) # 80002e3c <argaddr>
  argint(2, &n);
    800057c6:	fe440593          	addi	a1,s0,-28
    800057ca:	4509                	li	a0,2
    800057cc:	ffffd097          	auipc	ra,0xffffd
    800057d0:	64e080e7          	jalr	1614(ra) # 80002e1a <argint>
  if(argfd(0, 0, &f) < 0)
    800057d4:	fe840613          	addi	a2,s0,-24
    800057d8:	4581                	li	a1,0
    800057da:	4501                	li	a0,0
    800057dc:	00000097          	auipc	ra,0x0
    800057e0:	d58080e7          	jalr	-680(ra) # 80005534 <argfd>
    800057e4:	87aa                	mv	a5,a0
    return -1;
    800057e6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057e8:	0007cc63          	bltz	a5,80005800 <sys_read+0x50>
  return fileread(f, p, n);
    800057ec:	fe442603          	lw	a2,-28(s0)
    800057f0:	fd843583          	ld	a1,-40(s0)
    800057f4:	fe843503          	ld	a0,-24(s0)
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	44e080e7          	jalr	1102(ra) # 80004c46 <fileread>
}
    80005800:	70a2                	ld	ra,40(sp)
    80005802:	7402                	ld	s0,32(sp)
    80005804:	6145                	addi	sp,sp,48
    80005806:	8082                	ret

0000000080005808 <sys_write>:
{
    80005808:	7179                	addi	sp,sp,-48
    8000580a:	f406                	sd	ra,40(sp)
    8000580c:	f022                	sd	s0,32(sp)
    8000580e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005810:	fd840593          	addi	a1,s0,-40
    80005814:	4505                	li	a0,1
    80005816:	ffffd097          	auipc	ra,0xffffd
    8000581a:	626080e7          	jalr	1574(ra) # 80002e3c <argaddr>
  argint(2, &n);
    8000581e:	fe440593          	addi	a1,s0,-28
    80005822:	4509                	li	a0,2
    80005824:	ffffd097          	auipc	ra,0xffffd
    80005828:	5f6080e7          	jalr	1526(ra) # 80002e1a <argint>
  if(argfd(0, 0, &f) < 0)
    8000582c:	fe840613          	addi	a2,s0,-24
    80005830:	4581                	li	a1,0
    80005832:	4501                	li	a0,0
    80005834:	00000097          	auipc	ra,0x0
    80005838:	d00080e7          	jalr	-768(ra) # 80005534 <argfd>
    8000583c:	87aa                	mv	a5,a0
    return -1;
    8000583e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005840:	0007cc63          	bltz	a5,80005858 <sys_write+0x50>
  return filewrite(f, p, n);
    80005844:	fe442603          	lw	a2,-28(s0)
    80005848:	fd843583          	ld	a1,-40(s0)
    8000584c:	fe843503          	ld	a0,-24(s0)
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	4b8080e7          	jalr	1208(ra) # 80004d08 <filewrite>
}
    80005858:	70a2                	ld	ra,40(sp)
    8000585a:	7402                	ld	s0,32(sp)
    8000585c:	6145                	addi	sp,sp,48
    8000585e:	8082                	ret

0000000080005860 <sys_close>:
{
    80005860:	1101                	addi	sp,sp,-32
    80005862:	ec06                	sd	ra,24(sp)
    80005864:	e822                	sd	s0,16(sp)
    80005866:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005868:	fe040613          	addi	a2,s0,-32
    8000586c:	fec40593          	addi	a1,s0,-20
    80005870:	4501                	li	a0,0
    80005872:	00000097          	auipc	ra,0x0
    80005876:	cc2080e7          	jalr	-830(ra) # 80005534 <argfd>
    return -1;
    8000587a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000587c:	02054463          	bltz	a0,800058a4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005880:	ffffc097          	auipc	ra,0xffffc
    80005884:	176080e7          	jalr	374(ra) # 800019f6 <myproc>
    80005888:	fec42783          	lw	a5,-20(s0)
    8000588c:	07f1                	addi	a5,a5,28
    8000588e:	078e                	slli	a5,a5,0x3
    80005890:	97aa                	add	a5,a5,a0
    80005892:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005896:	fe043503          	ld	a0,-32(s0)
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	272080e7          	jalr	626(ra) # 80004b0c <fileclose>
  return 0;
    800058a2:	4781                	li	a5,0
}
    800058a4:	853e                	mv	a0,a5
    800058a6:	60e2                	ld	ra,24(sp)
    800058a8:	6442                	ld	s0,16(sp)
    800058aa:	6105                	addi	sp,sp,32
    800058ac:	8082                	ret

00000000800058ae <sys_fstat>:
{
    800058ae:	1101                	addi	sp,sp,-32
    800058b0:	ec06                	sd	ra,24(sp)
    800058b2:	e822                	sd	s0,16(sp)
    800058b4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800058b6:	fe040593          	addi	a1,s0,-32
    800058ba:	4505                	li	a0,1
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	580080e7          	jalr	1408(ra) # 80002e3c <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058c4:	fe840613          	addi	a2,s0,-24
    800058c8:	4581                	li	a1,0
    800058ca:	4501                	li	a0,0
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	c68080e7          	jalr	-920(ra) # 80005534 <argfd>
    800058d4:	87aa                	mv	a5,a0
    return -1;
    800058d6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058d8:	0007ca63          	bltz	a5,800058ec <sys_fstat+0x3e>
  return filestat(f, st);
    800058dc:	fe043583          	ld	a1,-32(s0)
    800058e0:	fe843503          	ld	a0,-24(s0)
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	2f0080e7          	jalr	752(ra) # 80004bd4 <filestat>
}
    800058ec:	60e2                	ld	ra,24(sp)
    800058ee:	6442                	ld	s0,16(sp)
    800058f0:	6105                	addi	sp,sp,32
    800058f2:	8082                	ret

00000000800058f4 <sys_link>:
{
    800058f4:	7169                	addi	sp,sp,-304
    800058f6:	f606                	sd	ra,296(sp)
    800058f8:	f222                	sd	s0,288(sp)
    800058fa:	ee26                	sd	s1,280(sp)
    800058fc:	ea4a                	sd	s2,272(sp)
    800058fe:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005900:	08000613          	li	a2,128
    80005904:	ed040593          	addi	a1,s0,-304
    80005908:	4501                	li	a0,0
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	554080e7          	jalr	1364(ra) # 80002e5e <argstr>
    return -1;
    80005912:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005914:	10054e63          	bltz	a0,80005a30 <sys_link+0x13c>
    80005918:	08000613          	li	a2,128
    8000591c:	f5040593          	addi	a1,s0,-176
    80005920:	4505                	li	a0,1
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	53c080e7          	jalr	1340(ra) # 80002e5e <argstr>
    return -1;
    8000592a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000592c:	10054263          	bltz	a0,80005a30 <sys_link+0x13c>
  begin_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	d10080e7          	jalr	-752(ra) # 80004640 <begin_op>
  if((ip = namei(old)) == 0){
    80005938:	ed040513          	addi	a0,s0,-304
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	ae8080e7          	jalr	-1304(ra) # 80004424 <namei>
    80005944:	84aa                	mv	s1,a0
    80005946:	c551                	beqz	a0,800059d2 <sys_link+0xde>
  ilock(ip);
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	336080e7          	jalr	822(ra) # 80003c7e <ilock>
  if(ip->type == T_DIR){
    80005950:	04449703          	lh	a4,68(s1)
    80005954:	4785                	li	a5,1
    80005956:	08f70463          	beq	a4,a5,800059de <sys_link+0xea>
  ip->nlink++;
    8000595a:	04a4d783          	lhu	a5,74(s1)
    8000595e:	2785                	addiw	a5,a5,1
    80005960:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	24e080e7          	jalr	590(ra) # 80003bb4 <iupdate>
  iunlock(ip);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	3d0080e7          	jalr	976(ra) # 80003d40 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005978:	fd040593          	addi	a1,s0,-48
    8000597c:	f5040513          	addi	a0,s0,-176
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	ac2080e7          	jalr	-1342(ra) # 80004442 <nameiparent>
    80005988:	892a                	mv	s2,a0
    8000598a:	c935                	beqz	a0,800059fe <sys_link+0x10a>
  ilock(dp);
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	2f2080e7          	jalr	754(ra) # 80003c7e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005994:	00092703          	lw	a4,0(s2)
    80005998:	409c                	lw	a5,0(s1)
    8000599a:	04f71d63          	bne	a4,a5,800059f4 <sys_link+0x100>
    8000599e:	40d0                	lw	a2,4(s1)
    800059a0:	fd040593          	addi	a1,s0,-48
    800059a4:	854a                	mv	a0,s2
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	9cc080e7          	jalr	-1588(ra) # 80004372 <dirlink>
    800059ae:	04054363          	bltz	a0,800059f4 <sys_link+0x100>
  iunlockput(dp);
    800059b2:	854a                	mv	a0,s2
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	52c080e7          	jalr	1324(ra) # 80003ee0 <iunlockput>
  iput(ip);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	47a080e7          	jalr	1146(ra) # 80003e38 <iput>
  end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	cfa080e7          	jalr	-774(ra) # 800046c0 <end_op>
  return 0;
    800059ce:	4781                	li	a5,0
    800059d0:	a085                	j	80005a30 <sys_link+0x13c>
    end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	cee080e7          	jalr	-786(ra) # 800046c0 <end_op>
    return -1;
    800059da:	57fd                	li	a5,-1
    800059dc:	a891                	j	80005a30 <sys_link+0x13c>
    iunlockput(ip);
    800059de:	8526                	mv	a0,s1
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	500080e7          	jalr	1280(ra) # 80003ee0 <iunlockput>
    end_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	cd8080e7          	jalr	-808(ra) # 800046c0 <end_op>
    return -1;
    800059f0:	57fd                	li	a5,-1
    800059f2:	a83d                	j	80005a30 <sys_link+0x13c>
    iunlockput(dp);
    800059f4:	854a                	mv	a0,s2
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	4ea080e7          	jalr	1258(ra) # 80003ee0 <iunlockput>
  ilock(ip);
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	27e080e7          	jalr	638(ra) # 80003c7e <ilock>
  ip->nlink--;
    80005a08:	04a4d783          	lhu	a5,74(s1)
    80005a0c:	37fd                	addiw	a5,a5,-1
    80005a0e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a12:	8526                	mv	a0,s1
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	1a0080e7          	jalr	416(ra) # 80003bb4 <iupdate>
  iunlockput(ip);
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	4c2080e7          	jalr	1218(ra) # 80003ee0 <iunlockput>
  end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	c9a080e7          	jalr	-870(ra) # 800046c0 <end_op>
  return -1;
    80005a2e:	57fd                	li	a5,-1
}
    80005a30:	853e                	mv	a0,a5
    80005a32:	70b2                	ld	ra,296(sp)
    80005a34:	7412                	ld	s0,288(sp)
    80005a36:	64f2                	ld	s1,280(sp)
    80005a38:	6952                	ld	s2,272(sp)
    80005a3a:	6155                	addi	sp,sp,304
    80005a3c:	8082                	ret

0000000080005a3e <sys_unlink>:
{
    80005a3e:	7151                	addi	sp,sp,-240
    80005a40:	f586                	sd	ra,232(sp)
    80005a42:	f1a2                	sd	s0,224(sp)
    80005a44:	eda6                	sd	s1,216(sp)
    80005a46:	e9ca                	sd	s2,208(sp)
    80005a48:	e5ce                	sd	s3,200(sp)
    80005a4a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a4c:	08000613          	li	a2,128
    80005a50:	f3040593          	addi	a1,s0,-208
    80005a54:	4501                	li	a0,0
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	408080e7          	jalr	1032(ra) # 80002e5e <argstr>
    80005a5e:	18054163          	bltz	a0,80005be0 <sys_unlink+0x1a2>
  begin_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	bde080e7          	jalr	-1058(ra) # 80004640 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a6a:	fb040593          	addi	a1,s0,-80
    80005a6e:	f3040513          	addi	a0,s0,-208
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	9d0080e7          	jalr	-1584(ra) # 80004442 <nameiparent>
    80005a7a:	84aa                	mv	s1,a0
    80005a7c:	c979                	beqz	a0,80005b52 <sys_unlink+0x114>
  ilock(dp);
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	200080e7          	jalr	512(ra) # 80003c7e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a86:	00003597          	auipc	a1,0x3
    80005a8a:	daa58593          	addi	a1,a1,-598 # 80008830 <syscalls+0x2c0>
    80005a8e:	fb040513          	addi	a0,s0,-80
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	6b6080e7          	jalr	1718(ra) # 80004148 <namecmp>
    80005a9a:	14050a63          	beqz	a0,80005bee <sys_unlink+0x1b0>
    80005a9e:	00003597          	auipc	a1,0x3
    80005aa2:	d9a58593          	addi	a1,a1,-614 # 80008838 <syscalls+0x2c8>
    80005aa6:	fb040513          	addi	a0,s0,-80
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	69e080e7          	jalr	1694(ra) # 80004148 <namecmp>
    80005ab2:	12050e63          	beqz	a0,80005bee <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ab6:	f2c40613          	addi	a2,s0,-212
    80005aba:	fb040593          	addi	a1,s0,-80
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	6a2080e7          	jalr	1698(ra) # 80004162 <dirlookup>
    80005ac8:	892a                	mv	s2,a0
    80005aca:	12050263          	beqz	a0,80005bee <sys_unlink+0x1b0>
  ilock(ip);
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	1b0080e7          	jalr	432(ra) # 80003c7e <ilock>
  if(ip->nlink < 1)
    80005ad6:	04a91783          	lh	a5,74(s2)
    80005ada:	08f05263          	blez	a5,80005b5e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ade:	04491703          	lh	a4,68(s2)
    80005ae2:	4785                	li	a5,1
    80005ae4:	08f70563          	beq	a4,a5,80005b6e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ae8:	4641                	li	a2,16
    80005aea:	4581                	li	a1,0
    80005aec:	fc040513          	addi	a0,s0,-64
    80005af0:	ffffb097          	auipc	ra,0xffffb
    80005af4:	1f6080e7          	jalr	502(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005af8:	4741                	li	a4,16
    80005afa:	f2c42683          	lw	a3,-212(s0)
    80005afe:	fc040613          	addi	a2,s0,-64
    80005b02:	4581                	li	a1,0
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	524080e7          	jalr	1316(ra) # 8000402a <writei>
    80005b0e:	47c1                	li	a5,16
    80005b10:	0af51563          	bne	a0,a5,80005bba <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b14:	04491703          	lh	a4,68(s2)
    80005b18:	4785                	li	a5,1
    80005b1a:	0af70863          	beq	a4,a5,80005bca <sys_unlink+0x18c>
  iunlockput(dp);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	3c0080e7          	jalr	960(ra) # 80003ee0 <iunlockput>
  ip->nlink--;
    80005b28:	04a95783          	lhu	a5,74(s2)
    80005b2c:	37fd                	addiw	a5,a5,-1
    80005b2e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b32:	854a                	mv	a0,s2
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	080080e7          	jalr	128(ra) # 80003bb4 <iupdate>
  iunlockput(ip);
    80005b3c:	854a                	mv	a0,s2
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	3a2080e7          	jalr	930(ra) # 80003ee0 <iunlockput>
  end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	b7a080e7          	jalr	-1158(ra) # 800046c0 <end_op>
  return 0;
    80005b4e:	4501                	li	a0,0
    80005b50:	a84d                	j	80005c02 <sys_unlink+0x1c4>
    end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	b6e080e7          	jalr	-1170(ra) # 800046c0 <end_op>
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	a05d                	j	80005c02 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b5e:	00003517          	auipc	a0,0x3
    80005b62:	ce250513          	addi	a0,a0,-798 # 80008840 <syscalls+0x2d0>
    80005b66:	ffffb097          	auipc	ra,0xffffb
    80005b6a:	9de080e7          	jalr	-1570(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b6e:	04c92703          	lw	a4,76(s2)
    80005b72:	02000793          	li	a5,32
    80005b76:	f6e7f9e3          	bgeu	a5,a4,80005ae8 <sys_unlink+0xaa>
    80005b7a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b7e:	4741                	li	a4,16
    80005b80:	86ce                	mv	a3,s3
    80005b82:	f1840613          	addi	a2,s0,-232
    80005b86:	4581                	li	a1,0
    80005b88:	854a                	mv	a0,s2
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	3a8080e7          	jalr	936(ra) # 80003f32 <readi>
    80005b92:	47c1                	li	a5,16
    80005b94:	00f51b63          	bne	a0,a5,80005baa <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b98:	f1845783          	lhu	a5,-232(s0)
    80005b9c:	e7a1                	bnez	a5,80005be4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b9e:	29c1                	addiw	s3,s3,16
    80005ba0:	04c92783          	lw	a5,76(s2)
    80005ba4:	fcf9ede3          	bltu	s3,a5,80005b7e <sys_unlink+0x140>
    80005ba8:	b781                	j	80005ae8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005baa:	00003517          	auipc	a0,0x3
    80005bae:	cae50513          	addi	a0,a0,-850 # 80008858 <syscalls+0x2e8>
    80005bb2:	ffffb097          	auipc	ra,0xffffb
    80005bb6:	992080e7          	jalr	-1646(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005bba:	00003517          	auipc	a0,0x3
    80005bbe:	cb650513          	addi	a0,a0,-842 # 80008870 <syscalls+0x300>
    80005bc2:	ffffb097          	auipc	ra,0xffffb
    80005bc6:	982080e7          	jalr	-1662(ra) # 80000544 <panic>
    dp->nlink--;
    80005bca:	04a4d783          	lhu	a5,74(s1)
    80005bce:	37fd                	addiw	a5,a5,-1
    80005bd0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	fde080e7          	jalr	-34(ra) # 80003bb4 <iupdate>
    80005bde:	b781                	j	80005b1e <sys_unlink+0xe0>
    return -1;
    80005be0:	557d                	li	a0,-1
    80005be2:	a005                	j	80005c02 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005be4:	854a                	mv	a0,s2
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	2fa080e7          	jalr	762(ra) # 80003ee0 <iunlockput>
  iunlockput(dp);
    80005bee:	8526                	mv	a0,s1
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	2f0080e7          	jalr	752(ra) # 80003ee0 <iunlockput>
  end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	ac8080e7          	jalr	-1336(ra) # 800046c0 <end_op>
  return -1;
    80005c00:	557d                	li	a0,-1
}
    80005c02:	70ae                	ld	ra,232(sp)
    80005c04:	740e                	ld	s0,224(sp)
    80005c06:	64ee                	ld	s1,216(sp)
    80005c08:	694e                	ld	s2,208(sp)
    80005c0a:	69ae                	ld	s3,200(sp)
    80005c0c:	616d                	addi	sp,sp,240
    80005c0e:	8082                	ret

0000000080005c10 <sys_open>:

uint64
sys_open(void)
{
    80005c10:	7131                	addi	sp,sp,-192
    80005c12:	fd06                	sd	ra,184(sp)
    80005c14:	f922                	sd	s0,176(sp)
    80005c16:	f526                	sd	s1,168(sp)
    80005c18:	f14a                	sd	s2,160(sp)
    80005c1a:	ed4e                	sd	s3,152(sp)
    80005c1c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c1e:	f4c40593          	addi	a1,s0,-180
    80005c22:	4505                	li	a0,1
    80005c24:	ffffd097          	auipc	ra,0xffffd
    80005c28:	1f6080e7          	jalr	502(ra) # 80002e1a <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c2c:	08000613          	li	a2,128
    80005c30:	f5040593          	addi	a1,s0,-176
    80005c34:	4501                	li	a0,0
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	228080e7          	jalr	552(ra) # 80002e5e <argstr>
    80005c3e:	87aa                	mv	a5,a0
    return -1;
    80005c40:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c42:	0a07c963          	bltz	a5,80005cf4 <sys_open+0xe4>

  begin_op();
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	9fa080e7          	jalr	-1542(ra) # 80004640 <begin_op>

  if(omode & O_CREATE){
    80005c4e:	f4c42783          	lw	a5,-180(s0)
    80005c52:	2007f793          	andi	a5,a5,512
    80005c56:	cfc5                	beqz	a5,80005d0e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c58:	4681                	li	a3,0
    80005c5a:	4601                	li	a2,0
    80005c5c:	4589                	li	a1,2
    80005c5e:	f5040513          	addi	a0,s0,-176
    80005c62:	00000097          	auipc	ra,0x0
    80005c66:	974080e7          	jalr	-1676(ra) # 800055d6 <create>
    80005c6a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c6c:	c959                	beqz	a0,80005d02 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c6e:	04449703          	lh	a4,68(s1)
    80005c72:	478d                	li	a5,3
    80005c74:	00f71763          	bne	a4,a5,80005c82 <sys_open+0x72>
    80005c78:	0464d703          	lhu	a4,70(s1)
    80005c7c:	47a5                	li	a5,9
    80005c7e:	0ce7ed63          	bltu	a5,a4,80005d58 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	dce080e7          	jalr	-562(ra) # 80004a50 <filealloc>
    80005c8a:	89aa                	mv	s3,a0
    80005c8c:	10050363          	beqz	a0,80005d92 <sys_open+0x182>
    80005c90:	00000097          	auipc	ra,0x0
    80005c94:	904080e7          	jalr	-1788(ra) # 80005594 <fdalloc>
    80005c98:	892a                	mv	s2,a0
    80005c9a:	0e054763          	bltz	a0,80005d88 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c9e:	04449703          	lh	a4,68(s1)
    80005ca2:	478d                	li	a5,3
    80005ca4:	0cf70563          	beq	a4,a5,80005d6e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ca8:	4789                	li	a5,2
    80005caa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005cae:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cb2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005cb6:	f4c42783          	lw	a5,-180(s0)
    80005cba:	0017c713          	xori	a4,a5,1
    80005cbe:	8b05                	andi	a4,a4,1
    80005cc0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cc4:	0037f713          	andi	a4,a5,3
    80005cc8:	00e03733          	snez	a4,a4
    80005ccc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cd0:	4007f793          	andi	a5,a5,1024
    80005cd4:	c791                	beqz	a5,80005ce0 <sys_open+0xd0>
    80005cd6:	04449703          	lh	a4,68(s1)
    80005cda:	4789                	li	a5,2
    80005cdc:	0af70063          	beq	a4,a5,80005d7c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	05e080e7          	jalr	94(ra) # 80003d40 <iunlock>
  end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	9d6080e7          	jalr	-1578(ra) # 800046c0 <end_op>

  return fd;
    80005cf2:	854a                	mv	a0,s2
}
    80005cf4:	70ea                	ld	ra,184(sp)
    80005cf6:	744a                	ld	s0,176(sp)
    80005cf8:	74aa                	ld	s1,168(sp)
    80005cfa:	790a                	ld	s2,160(sp)
    80005cfc:	69ea                	ld	s3,152(sp)
    80005cfe:	6129                	addi	sp,sp,192
    80005d00:	8082                	ret
      end_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	9be080e7          	jalr	-1602(ra) # 800046c0 <end_op>
      return -1;
    80005d0a:	557d                	li	a0,-1
    80005d0c:	b7e5                	j	80005cf4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d0e:	f5040513          	addi	a0,s0,-176
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	712080e7          	jalr	1810(ra) # 80004424 <namei>
    80005d1a:	84aa                	mv	s1,a0
    80005d1c:	c905                	beqz	a0,80005d4c <sys_open+0x13c>
    ilock(ip);
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	f60080e7          	jalr	-160(ra) # 80003c7e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d26:	04449703          	lh	a4,68(s1)
    80005d2a:	4785                	li	a5,1
    80005d2c:	f4f711e3          	bne	a4,a5,80005c6e <sys_open+0x5e>
    80005d30:	f4c42783          	lw	a5,-180(s0)
    80005d34:	d7b9                	beqz	a5,80005c82 <sys_open+0x72>
      iunlockput(ip);
    80005d36:	8526                	mv	a0,s1
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	1a8080e7          	jalr	424(ra) # 80003ee0 <iunlockput>
      end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	980080e7          	jalr	-1664(ra) # 800046c0 <end_op>
      return -1;
    80005d48:	557d                	li	a0,-1
    80005d4a:	b76d                	j	80005cf4 <sys_open+0xe4>
      end_op();
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	974080e7          	jalr	-1676(ra) # 800046c0 <end_op>
      return -1;
    80005d54:	557d                	li	a0,-1
    80005d56:	bf79                	j	80005cf4 <sys_open+0xe4>
    iunlockput(ip);
    80005d58:	8526                	mv	a0,s1
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	186080e7          	jalr	390(ra) # 80003ee0 <iunlockput>
    end_op();
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	95e080e7          	jalr	-1698(ra) # 800046c0 <end_op>
    return -1;
    80005d6a:	557d                	li	a0,-1
    80005d6c:	b761                	j	80005cf4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d6e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d72:	04649783          	lh	a5,70(s1)
    80005d76:	02f99223          	sh	a5,36(s3)
    80005d7a:	bf25                	j	80005cb2 <sys_open+0xa2>
    itrunc(ip);
    80005d7c:	8526                	mv	a0,s1
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	00e080e7          	jalr	14(ra) # 80003d8c <itrunc>
    80005d86:	bfa9                	j	80005ce0 <sys_open+0xd0>
      fileclose(f);
    80005d88:	854e                	mv	a0,s3
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	d82080e7          	jalr	-638(ra) # 80004b0c <fileclose>
    iunlockput(ip);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	14c080e7          	jalr	332(ra) # 80003ee0 <iunlockput>
    end_op();
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	924080e7          	jalr	-1756(ra) # 800046c0 <end_op>
    return -1;
    80005da4:	557d                	li	a0,-1
    80005da6:	b7b9                	j	80005cf4 <sys_open+0xe4>

0000000080005da8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005da8:	7175                	addi	sp,sp,-144
    80005daa:	e506                	sd	ra,136(sp)
    80005dac:	e122                	sd	s0,128(sp)
    80005dae:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	890080e7          	jalr	-1904(ra) # 80004640 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005db8:	08000613          	li	a2,128
    80005dbc:	f7040593          	addi	a1,s0,-144
    80005dc0:	4501                	li	a0,0
    80005dc2:	ffffd097          	auipc	ra,0xffffd
    80005dc6:	09c080e7          	jalr	156(ra) # 80002e5e <argstr>
    80005dca:	02054963          	bltz	a0,80005dfc <sys_mkdir+0x54>
    80005dce:	4681                	li	a3,0
    80005dd0:	4601                	li	a2,0
    80005dd2:	4585                	li	a1,1
    80005dd4:	f7040513          	addi	a0,s0,-144
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	7fe080e7          	jalr	2046(ra) # 800055d6 <create>
    80005de0:	cd11                	beqz	a0,80005dfc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	0fe080e7          	jalr	254(ra) # 80003ee0 <iunlockput>
  end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	8d6080e7          	jalr	-1834(ra) # 800046c0 <end_op>
  return 0;
    80005df2:	4501                	li	a0,0
}
    80005df4:	60aa                	ld	ra,136(sp)
    80005df6:	640a                	ld	s0,128(sp)
    80005df8:	6149                	addi	sp,sp,144
    80005dfa:	8082                	ret
    end_op();
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	8c4080e7          	jalr	-1852(ra) # 800046c0 <end_op>
    return -1;
    80005e04:	557d                	li	a0,-1
    80005e06:	b7fd                	j	80005df4 <sys_mkdir+0x4c>

0000000080005e08 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e08:	7135                	addi	sp,sp,-160
    80005e0a:	ed06                	sd	ra,152(sp)
    80005e0c:	e922                	sd	s0,144(sp)
    80005e0e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e10:	fffff097          	auipc	ra,0xfffff
    80005e14:	830080e7          	jalr	-2000(ra) # 80004640 <begin_op>
  argint(1, &major);
    80005e18:	f6c40593          	addi	a1,s0,-148
    80005e1c:	4505                	li	a0,1
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	ffc080e7          	jalr	-4(ra) # 80002e1a <argint>
  argint(2, &minor);
    80005e26:	f6840593          	addi	a1,s0,-152
    80005e2a:	4509                	li	a0,2
    80005e2c:	ffffd097          	auipc	ra,0xffffd
    80005e30:	fee080e7          	jalr	-18(ra) # 80002e1a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e34:	08000613          	li	a2,128
    80005e38:	f7040593          	addi	a1,s0,-144
    80005e3c:	4501                	li	a0,0
    80005e3e:	ffffd097          	auipc	ra,0xffffd
    80005e42:	020080e7          	jalr	32(ra) # 80002e5e <argstr>
    80005e46:	02054b63          	bltz	a0,80005e7c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e4a:	f6841683          	lh	a3,-152(s0)
    80005e4e:	f6c41603          	lh	a2,-148(s0)
    80005e52:	458d                	li	a1,3
    80005e54:	f7040513          	addi	a0,s0,-144
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	77e080e7          	jalr	1918(ra) # 800055d6 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e60:	cd11                	beqz	a0,80005e7c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	07e080e7          	jalr	126(ra) # 80003ee0 <iunlockput>
  end_op();
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	856080e7          	jalr	-1962(ra) # 800046c0 <end_op>
  return 0;
    80005e72:	4501                	li	a0,0
}
    80005e74:	60ea                	ld	ra,152(sp)
    80005e76:	644a                	ld	s0,144(sp)
    80005e78:	610d                	addi	sp,sp,160
    80005e7a:	8082                	ret
    end_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	844080e7          	jalr	-1980(ra) # 800046c0 <end_op>
    return -1;
    80005e84:	557d                	li	a0,-1
    80005e86:	b7fd                	j	80005e74 <sys_mknod+0x6c>

0000000080005e88 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e88:	7135                	addi	sp,sp,-160
    80005e8a:	ed06                	sd	ra,152(sp)
    80005e8c:	e922                	sd	s0,144(sp)
    80005e8e:	e526                	sd	s1,136(sp)
    80005e90:	e14a                	sd	s2,128(sp)
    80005e92:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e94:	ffffc097          	auipc	ra,0xffffc
    80005e98:	b62080e7          	jalr	-1182(ra) # 800019f6 <myproc>
    80005e9c:	892a                	mv	s2,a0
  
  begin_op();
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	7a2080e7          	jalr	1954(ra) # 80004640 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ea6:	08000613          	li	a2,128
    80005eaa:	f6040593          	addi	a1,s0,-160
    80005eae:	4501                	li	a0,0
    80005eb0:	ffffd097          	auipc	ra,0xffffd
    80005eb4:	fae080e7          	jalr	-82(ra) # 80002e5e <argstr>
    80005eb8:	04054b63          	bltz	a0,80005f0e <sys_chdir+0x86>
    80005ebc:	f6040513          	addi	a0,s0,-160
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	564080e7          	jalr	1380(ra) # 80004424 <namei>
    80005ec8:	84aa                	mv	s1,a0
    80005eca:	c131                	beqz	a0,80005f0e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	db2080e7          	jalr	-590(ra) # 80003c7e <ilock>
  if(ip->type != T_DIR){
    80005ed4:	04449703          	lh	a4,68(s1)
    80005ed8:	4785                	li	a5,1
    80005eda:	04f71063          	bne	a4,a5,80005f1a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ede:	8526                	mv	a0,s1
    80005ee0:	ffffe097          	auipc	ra,0xffffe
    80005ee4:	e60080e7          	jalr	-416(ra) # 80003d40 <iunlock>
  iput(p->cwd);
    80005ee8:	16093503          	ld	a0,352(s2)
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	f4c080e7          	jalr	-180(ra) # 80003e38 <iput>
  end_op();
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	7cc080e7          	jalr	1996(ra) # 800046c0 <end_op>
  p->cwd = ip;
    80005efc:	16993023          	sd	s1,352(s2)
  return 0;
    80005f00:	4501                	li	a0,0
}
    80005f02:	60ea                	ld	ra,152(sp)
    80005f04:	644a                	ld	s0,144(sp)
    80005f06:	64aa                	ld	s1,136(sp)
    80005f08:	690a                	ld	s2,128(sp)
    80005f0a:	610d                	addi	sp,sp,160
    80005f0c:	8082                	ret
    end_op();
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	7b2080e7          	jalr	1970(ra) # 800046c0 <end_op>
    return -1;
    80005f16:	557d                	li	a0,-1
    80005f18:	b7ed                	j	80005f02 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f1a:	8526                	mv	a0,s1
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	fc4080e7          	jalr	-60(ra) # 80003ee0 <iunlockput>
    end_op();
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	79c080e7          	jalr	1948(ra) # 800046c0 <end_op>
    return -1;
    80005f2c:	557d                	li	a0,-1
    80005f2e:	bfd1                	j	80005f02 <sys_chdir+0x7a>

0000000080005f30 <sys_exec>:

uint64
sys_exec(void)
{
    80005f30:	7145                	addi	sp,sp,-464
    80005f32:	e786                	sd	ra,456(sp)
    80005f34:	e3a2                	sd	s0,448(sp)
    80005f36:	ff26                	sd	s1,440(sp)
    80005f38:	fb4a                	sd	s2,432(sp)
    80005f3a:	f74e                	sd	s3,424(sp)
    80005f3c:	f352                	sd	s4,416(sp)
    80005f3e:	ef56                	sd	s5,408(sp)
    80005f40:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f42:	e3840593          	addi	a1,s0,-456
    80005f46:	4505                	li	a0,1
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	ef4080e7          	jalr	-268(ra) # 80002e3c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f50:	08000613          	li	a2,128
    80005f54:	f4040593          	addi	a1,s0,-192
    80005f58:	4501                	li	a0,0
    80005f5a:	ffffd097          	auipc	ra,0xffffd
    80005f5e:	f04080e7          	jalr	-252(ra) # 80002e5e <argstr>
    80005f62:	87aa                	mv	a5,a0
    return -1;
    80005f64:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f66:	0c07c263          	bltz	a5,8000602a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f6a:	10000613          	li	a2,256
    80005f6e:	4581                	li	a1,0
    80005f70:	e4040513          	addi	a0,s0,-448
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	d72080e7          	jalr	-654(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f7c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f80:	89a6                	mv	s3,s1
    80005f82:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f84:	02000a13          	li	s4,32
    80005f88:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f8c:	00391513          	slli	a0,s2,0x3
    80005f90:	e3040593          	addi	a1,s0,-464
    80005f94:	e3843783          	ld	a5,-456(s0)
    80005f98:	953e                	add	a0,a0,a5
    80005f9a:	ffffd097          	auipc	ra,0xffffd
    80005f9e:	de2080e7          	jalr	-542(ra) # 80002d7c <fetchaddr>
    80005fa2:	02054a63          	bltz	a0,80005fd6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005fa6:	e3043783          	ld	a5,-464(s0)
    80005faa:	c3b9                	beqz	a5,80005ff0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fac:	ffffb097          	auipc	ra,0xffffb
    80005fb0:	b4e080e7          	jalr	-1202(ra) # 80000afa <kalloc>
    80005fb4:	85aa                	mv	a1,a0
    80005fb6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fba:	cd11                	beqz	a0,80005fd6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fbc:	6605                	lui	a2,0x1
    80005fbe:	e3043503          	ld	a0,-464(s0)
    80005fc2:	ffffd097          	auipc	ra,0xffffd
    80005fc6:	e0c080e7          	jalr	-500(ra) # 80002dce <fetchstr>
    80005fca:	00054663          	bltz	a0,80005fd6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005fce:	0905                	addi	s2,s2,1
    80005fd0:	09a1                	addi	s3,s3,8
    80005fd2:	fb491be3          	bne	s2,s4,80005f88 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd6:	10048913          	addi	s2,s1,256
    80005fda:	6088                	ld	a0,0(s1)
    80005fdc:	c531                	beqz	a0,80006028 <sys_exec+0xf8>
    kfree(argv[i]);
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	a20080e7          	jalr	-1504(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fe6:	04a1                	addi	s1,s1,8
    80005fe8:	ff2499e3          	bne	s1,s2,80005fda <sys_exec+0xaa>
  return -1;
    80005fec:	557d                	li	a0,-1
    80005fee:	a835                	j	8000602a <sys_exec+0xfa>
      argv[i] = 0;
    80005ff0:	0a8e                	slli	s5,s5,0x3
    80005ff2:	fc040793          	addi	a5,s0,-64
    80005ff6:	9abe                	add	s5,s5,a5
    80005ff8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ffc:	e4040593          	addi	a1,s0,-448
    80006000:	f4040513          	addi	a0,s0,-192
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	190080e7          	jalr	400(ra) # 80005194 <exec>
    8000600c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600e:	10048993          	addi	s3,s1,256
    80006012:	6088                	ld	a0,0(s1)
    80006014:	c901                	beqz	a0,80006024 <sys_exec+0xf4>
    kfree(argv[i]);
    80006016:	ffffb097          	auipc	ra,0xffffb
    8000601a:	9e8080e7          	jalr	-1560(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000601e:	04a1                	addi	s1,s1,8
    80006020:	ff3499e3          	bne	s1,s3,80006012 <sys_exec+0xe2>
  return ret;
    80006024:	854a                	mv	a0,s2
    80006026:	a011                	j	8000602a <sys_exec+0xfa>
  return -1;
    80006028:	557d                	li	a0,-1
}
    8000602a:	60be                	ld	ra,456(sp)
    8000602c:	641e                	ld	s0,448(sp)
    8000602e:	74fa                	ld	s1,440(sp)
    80006030:	795a                	ld	s2,432(sp)
    80006032:	79ba                	ld	s3,424(sp)
    80006034:	7a1a                	ld	s4,416(sp)
    80006036:	6afa                	ld	s5,408(sp)
    80006038:	6179                	addi	sp,sp,464
    8000603a:	8082                	ret

000000008000603c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000603c:	7139                	addi	sp,sp,-64
    8000603e:	fc06                	sd	ra,56(sp)
    80006040:	f822                	sd	s0,48(sp)
    80006042:	f426                	sd	s1,40(sp)
    80006044:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006046:	ffffc097          	auipc	ra,0xffffc
    8000604a:	9b0080e7          	jalr	-1616(ra) # 800019f6 <myproc>
    8000604e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006050:	fd840593          	addi	a1,s0,-40
    80006054:	4501                	li	a0,0
    80006056:	ffffd097          	auipc	ra,0xffffd
    8000605a:	de6080e7          	jalr	-538(ra) # 80002e3c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000605e:	fc840593          	addi	a1,s0,-56
    80006062:	fd040513          	addi	a0,s0,-48
    80006066:	fffff097          	auipc	ra,0xfffff
    8000606a:	dd6080e7          	jalr	-554(ra) # 80004e3c <pipealloc>
    return -1;
    8000606e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006070:	0c054463          	bltz	a0,80006138 <sys_pipe+0xfc>
  fd0 = -1;
    80006074:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006078:	fd043503          	ld	a0,-48(s0)
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	518080e7          	jalr	1304(ra) # 80005594 <fdalloc>
    80006084:	fca42223          	sw	a0,-60(s0)
    80006088:	08054b63          	bltz	a0,8000611e <sys_pipe+0xe2>
    8000608c:	fc843503          	ld	a0,-56(s0)
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	504080e7          	jalr	1284(ra) # 80005594 <fdalloc>
    80006098:	fca42023          	sw	a0,-64(s0)
    8000609c:	06054863          	bltz	a0,8000610c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060a0:	4691                	li	a3,4
    800060a2:	fc440613          	addi	a2,s0,-60
    800060a6:	fd843583          	ld	a1,-40(s0)
    800060aa:	6ca8                	ld	a0,88(s1)
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	5d8080e7          	jalr	1496(ra) # 80001684 <copyout>
    800060b4:	02054063          	bltz	a0,800060d4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060b8:	4691                	li	a3,4
    800060ba:	fc040613          	addi	a2,s0,-64
    800060be:	fd843583          	ld	a1,-40(s0)
    800060c2:	0591                	addi	a1,a1,4
    800060c4:	6ca8                	ld	a0,88(s1)
    800060c6:	ffffb097          	auipc	ra,0xffffb
    800060ca:	5be080e7          	jalr	1470(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060ce:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d0:	06055463          	bgez	a0,80006138 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060d4:	fc442783          	lw	a5,-60(s0)
    800060d8:	07f1                	addi	a5,a5,28
    800060da:	078e                	slli	a5,a5,0x3
    800060dc:	97a6                	add	a5,a5,s1
    800060de:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060e2:	fc042503          	lw	a0,-64(s0)
    800060e6:	0571                	addi	a0,a0,28
    800060e8:	050e                	slli	a0,a0,0x3
    800060ea:	94aa                	add	s1,s1,a0
    800060ec:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060f0:	fd043503          	ld	a0,-48(s0)
    800060f4:	fffff097          	auipc	ra,0xfffff
    800060f8:	a18080e7          	jalr	-1512(ra) # 80004b0c <fileclose>
    fileclose(wf);
    800060fc:	fc843503          	ld	a0,-56(s0)
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	a0c080e7          	jalr	-1524(ra) # 80004b0c <fileclose>
    return -1;
    80006108:	57fd                	li	a5,-1
    8000610a:	a03d                	j	80006138 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000610c:	fc442783          	lw	a5,-60(s0)
    80006110:	0007c763          	bltz	a5,8000611e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006114:	07f1                	addi	a5,a5,28
    80006116:	078e                	slli	a5,a5,0x3
    80006118:	94be                	add	s1,s1,a5
    8000611a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000611e:	fd043503          	ld	a0,-48(s0)
    80006122:	fffff097          	auipc	ra,0xfffff
    80006126:	9ea080e7          	jalr	-1558(ra) # 80004b0c <fileclose>
    fileclose(wf);
    8000612a:	fc843503          	ld	a0,-56(s0)
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	9de080e7          	jalr	-1570(ra) # 80004b0c <fileclose>
    return -1;
    80006136:	57fd                	li	a5,-1
}
    80006138:	853e                	mv	a0,a5
    8000613a:	70e2                	ld	ra,56(sp)
    8000613c:	7442                	ld	s0,48(sp)
    8000613e:	74a2                	ld	s1,40(sp)
    80006140:	6121                	addi	sp,sp,64
    80006142:	8082                	ret
	...

0000000080006150 <kernelvec>:
    80006150:	7111                	addi	sp,sp,-256
    80006152:	e006                	sd	ra,0(sp)
    80006154:	e40a                	sd	sp,8(sp)
    80006156:	e80e                	sd	gp,16(sp)
    80006158:	ec12                	sd	tp,24(sp)
    8000615a:	f016                	sd	t0,32(sp)
    8000615c:	f41a                	sd	t1,40(sp)
    8000615e:	f81e                	sd	t2,48(sp)
    80006160:	fc22                	sd	s0,56(sp)
    80006162:	e0a6                	sd	s1,64(sp)
    80006164:	e4aa                	sd	a0,72(sp)
    80006166:	e8ae                	sd	a1,80(sp)
    80006168:	ecb2                	sd	a2,88(sp)
    8000616a:	f0b6                	sd	a3,96(sp)
    8000616c:	f4ba                	sd	a4,104(sp)
    8000616e:	f8be                	sd	a5,112(sp)
    80006170:	fcc2                	sd	a6,120(sp)
    80006172:	e146                	sd	a7,128(sp)
    80006174:	e54a                	sd	s2,136(sp)
    80006176:	e94e                	sd	s3,144(sp)
    80006178:	ed52                	sd	s4,152(sp)
    8000617a:	f156                	sd	s5,160(sp)
    8000617c:	f55a                	sd	s6,168(sp)
    8000617e:	f95e                	sd	s7,176(sp)
    80006180:	fd62                	sd	s8,184(sp)
    80006182:	e1e6                	sd	s9,192(sp)
    80006184:	e5ea                	sd	s10,200(sp)
    80006186:	e9ee                	sd	s11,208(sp)
    80006188:	edf2                	sd	t3,216(sp)
    8000618a:	f1f6                	sd	t4,224(sp)
    8000618c:	f5fa                	sd	t5,232(sp)
    8000618e:	f9fe                	sd	t6,240(sp)
    80006190:	ab9fc0ef          	jal	ra,80002c48 <kerneltrap>
    80006194:	6082                	ld	ra,0(sp)
    80006196:	6122                	ld	sp,8(sp)
    80006198:	61c2                	ld	gp,16(sp)
    8000619a:	7282                	ld	t0,32(sp)
    8000619c:	7322                	ld	t1,40(sp)
    8000619e:	73c2                	ld	t2,48(sp)
    800061a0:	7462                	ld	s0,56(sp)
    800061a2:	6486                	ld	s1,64(sp)
    800061a4:	6526                	ld	a0,72(sp)
    800061a6:	65c6                	ld	a1,80(sp)
    800061a8:	6666                	ld	a2,88(sp)
    800061aa:	7686                	ld	a3,96(sp)
    800061ac:	7726                	ld	a4,104(sp)
    800061ae:	77c6                	ld	a5,112(sp)
    800061b0:	7866                	ld	a6,120(sp)
    800061b2:	688a                	ld	a7,128(sp)
    800061b4:	692a                	ld	s2,136(sp)
    800061b6:	69ca                	ld	s3,144(sp)
    800061b8:	6a6a                	ld	s4,152(sp)
    800061ba:	7a8a                	ld	s5,160(sp)
    800061bc:	7b2a                	ld	s6,168(sp)
    800061be:	7bca                	ld	s7,176(sp)
    800061c0:	7c6a                	ld	s8,184(sp)
    800061c2:	6c8e                	ld	s9,192(sp)
    800061c4:	6d2e                	ld	s10,200(sp)
    800061c6:	6dce                	ld	s11,208(sp)
    800061c8:	6e6e                	ld	t3,216(sp)
    800061ca:	7e8e                	ld	t4,224(sp)
    800061cc:	7f2e                	ld	t5,232(sp)
    800061ce:	7fce                	ld	t6,240(sp)
    800061d0:	6111                	addi	sp,sp,256
    800061d2:	10200073          	sret
    800061d6:	00000013          	nop
    800061da:	00000013          	nop
    800061de:	0001                	nop

00000000800061e0 <timervec>:
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	e10c                	sd	a1,0(a0)
    800061e6:	e510                	sd	a2,8(a0)
    800061e8:	e914                	sd	a3,16(a0)
    800061ea:	6d0c                	ld	a1,24(a0)
    800061ec:	7110                	ld	a2,32(a0)
    800061ee:	6194                	ld	a3,0(a1)
    800061f0:	96b2                	add	a3,a3,a2
    800061f2:	e194                	sd	a3,0(a1)
    800061f4:	4589                	li	a1,2
    800061f6:	14459073          	csrw	sip,a1
    800061fa:	6914                	ld	a3,16(a0)
    800061fc:	6510                	ld	a2,8(a0)
    800061fe:	610c                	ld	a1,0(a0)
    80006200:	34051573          	csrrw	a0,mscratch,a0
    80006204:	30200073          	mret
	...

000000008000620a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000620a:	1141                	addi	sp,sp,-16
    8000620c:	e422                	sd	s0,8(sp)
    8000620e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006210:	0c0007b7          	lui	a5,0xc000
    80006214:	4705                	li	a4,1
    80006216:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006218:	c3d8                	sw	a4,4(a5)
}
    8000621a:	6422                	ld	s0,8(sp)
    8000621c:	0141                	addi	sp,sp,16
    8000621e:	8082                	ret

0000000080006220 <plicinithart>:

void
plicinithart(void)
{
    80006220:	1141                	addi	sp,sp,-16
    80006222:	e406                	sd	ra,8(sp)
    80006224:	e022                	sd	s0,0(sp)
    80006226:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	7a2080e7          	jalr	1954(ra) # 800019ca <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006230:	0085171b          	slliw	a4,a0,0x8
    80006234:	0c0027b7          	lui	a5,0xc002
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	40200713          	li	a4,1026
    8000623e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006242:	00d5151b          	slliw	a0,a0,0xd
    80006246:	0c2017b7          	lui	a5,0xc201
    8000624a:	953e                	add	a0,a0,a5
    8000624c:	00052023          	sw	zero,0(a0)
}
    80006250:	60a2                	ld	ra,8(sp)
    80006252:	6402                	ld	s0,0(sp)
    80006254:	0141                	addi	sp,sp,16
    80006256:	8082                	ret

0000000080006258 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006258:	1141                	addi	sp,sp,-16
    8000625a:	e406                	sd	ra,8(sp)
    8000625c:	e022                	sd	s0,0(sp)
    8000625e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	76a080e7          	jalr	1898(ra) # 800019ca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006268:	00d5179b          	slliw	a5,a0,0xd
    8000626c:	0c201537          	lui	a0,0xc201
    80006270:	953e                	add	a0,a0,a5
  return irq;
}
    80006272:	4148                	lw	a0,4(a0)
    80006274:	60a2                	ld	ra,8(sp)
    80006276:	6402                	ld	s0,0(sp)
    80006278:	0141                	addi	sp,sp,16
    8000627a:	8082                	ret

000000008000627c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000627c:	1101                	addi	sp,sp,-32
    8000627e:	ec06                	sd	ra,24(sp)
    80006280:	e822                	sd	s0,16(sp)
    80006282:	e426                	sd	s1,8(sp)
    80006284:	1000                	addi	s0,sp,32
    80006286:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006288:	ffffb097          	auipc	ra,0xffffb
    8000628c:	742080e7          	jalr	1858(ra) # 800019ca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006290:	00d5151b          	slliw	a0,a0,0xd
    80006294:	0c2017b7          	lui	a5,0xc201
    80006298:	97aa                	add	a5,a5,a0
    8000629a:	c3c4                	sw	s1,4(a5)
}
    8000629c:	60e2                	ld	ra,24(sp)
    8000629e:	6442                	ld	s0,16(sp)
    800062a0:	64a2                	ld	s1,8(sp)
    800062a2:	6105                	addi	sp,sp,32
    800062a4:	8082                	ret

00000000800062a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062a6:	1141                	addi	sp,sp,-16
    800062a8:	e406                	sd	ra,8(sp)
    800062aa:	e022                	sd	s0,0(sp)
    800062ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062ae:	479d                	li	a5,7
    800062b0:	04a7cc63          	blt	a5,a0,80006308 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800062b4:	0001d797          	auipc	a5,0x1d
    800062b8:	7bc78793          	addi	a5,a5,1980 # 80023a70 <disk>
    800062bc:	97aa                	add	a5,a5,a0
    800062be:	0187c783          	lbu	a5,24(a5)
    800062c2:	ebb9                	bnez	a5,80006318 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062c4:	00451613          	slli	a2,a0,0x4
    800062c8:	0001d797          	auipc	a5,0x1d
    800062cc:	7a878793          	addi	a5,a5,1960 # 80023a70 <disk>
    800062d0:	6394                	ld	a3,0(a5)
    800062d2:	96b2                	add	a3,a3,a2
    800062d4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062d8:	6398                	ld	a4,0(a5)
    800062da:	9732                	add	a4,a4,a2
    800062dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062e8:	953e                	add	a0,a0,a5
    800062ea:	4785                	li	a5,1
    800062ec:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800062f0:	0001d517          	auipc	a0,0x1d
    800062f4:	79850513          	addi	a0,a0,1944 # 80023a88 <disk+0x18>
    800062f8:	ffffc097          	auipc	ra,0xffffc
    800062fc:	024080e7          	jalr	36(ra) # 8000231c <wakeup>
}
    80006300:	60a2                	ld	ra,8(sp)
    80006302:	6402                	ld	s0,0(sp)
    80006304:	0141                	addi	sp,sp,16
    80006306:	8082                	ret
    panic("free_desc 1");
    80006308:	00002517          	auipc	a0,0x2
    8000630c:	57850513          	addi	a0,a0,1400 # 80008880 <syscalls+0x310>
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	234080e7          	jalr	564(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006318:	00002517          	auipc	a0,0x2
    8000631c:	57850513          	addi	a0,a0,1400 # 80008890 <syscalls+0x320>
    80006320:	ffffa097          	auipc	ra,0xffffa
    80006324:	224080e7          	jalr	548(ra) # 80000544 <panic>

0000000080006328 <virtio_disk_init>:
{
    80006328:	1101                	addi	sp,sp,-32
    8000632a:	ec06                	sd	ra,24(sp)
    8000632c:	e822                	sd	s0,16(sp)
    8000632e:	e426                	sd	s1,8(sp)
    80006330:	e04a                	sd	s2,0(sp)
    80006332:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006334:	00002597          	auipc	a1,0x2
    80006338:	56c58593          	addi	a1,a1,1388 # 800088a0 <syscalls+0x330>
    8000633c:	0001e517          	auipc	a0,0x1e
    80006340:	85c50513          	addi	a0,a0,-1956 # 80023b98 <disk+0x128>
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	816080e7          	jalr	-2026(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000634c:	100017b7          	lui	a5,0x10001
    80006350:	4398                	lw	a4,0(a5)
    80006352:	2701                	sext.w	a4,a4
    80006354:	747277b7          	lui	a5,0x74727
    80006358:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000635c:	14f71e63          	bne	a4,a5,800064b8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006360:	100017b7          	lui	a5,0x10001
    80006364:	43dc                	lw	a5,4(a5)
    80006366:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006368:	4709                	li	a4,2
    8000636a:	14e79763          	bne	a5,a4,800064b8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000636e:	100017b7          	lui	a5,0x10001
    80006372:	479c                	lw	a5,8(a5)
    80006374:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006376:	14e79163          	bne	a5,a4,800064b8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000637a:	100017b7          	lui	a5,0x10001
    8000637e:	47d8                	lw	a4,12(a5)
    80006380:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006382:	554d47b7          	lui	a5,0x554d4
    80006386:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000638a:	12f71763          	bne	a4,a5,800064b8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638e:	100017b7          	lui	a5,0x10001
    80006392:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006396:	4705                	li	a4,1
    80006398:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000639a:	470d                	li	a4,3
    8000639c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000639e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063a0:	c7ffe737          	lui	a4,0xc7ffe
    800063a4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdabaf>
    800063a8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063aa:	2701                	sext.w	a4,a4
    800063ac:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063ae:	472d                	li	a4,11
    800063b0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800063b2:	0707a903          	lw	s2,112(a5)
    800063b6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800063b8:	00897793          	andi	a5,s2,8
    800063bc:	10078663          	beqz	a5,800064c8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063c0:	100017b7          	lui	a5,0x10001
    800063c4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063c8:	43fc                	lw	a5,68(a5)
    800063ca:	2781                	sext.w	a5,a5
    800063cc:	10079663          	bnez	a5,800064d8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063d0:	100017b7          	lui	a5,0x10001
    800063d4:	5bdc                	lw	a5,52(a5)
    800063d6:	2781                	sext.w	a5,a5
  if(max == 0)
    800063d8:	10078863          	beqz	a5,800064e8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800063dc:	471d                	li	a4,7
    800063de:	10f77d63          	bgeu	a4,a5,800064f8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800063e2:	ffffa097          	auipc	ra,0xffffa
    800063e6:	718080e7          	jalr	1816(ra) # 80000afa <kalloc>
    800063ea:	0001d497          	auipc	s1,0x1d
    800063ee:	68648493          	addi	s1,s1,1670 # 80023a70 <disk>
    800063f2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063f4:	ffffa097          	auipc	ra,0xffffa
    800063f8:	706080e7          	jalr	1798(ra) # 80000afa <kalloc>
    800063fc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	6fc080e7          	jalr	1788(ra) # 80000afa <kalloc>
    80006406:	87aa                	mv	a5,a0
    80006408:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000640a:	6088                	ld	a0,0(s1)
    8000640c:	cd75                	beqz	a0,80006508 <virtio_disk_init+0x1e0>
    8000640e:	0001d717          	auipc	a4,0x1d
    80006412:	66a73703          	ld	a4,1642(a4) # 80023a78 <disk+0x8>
    80006416:	cb6d                	beqz	a4,80006508 <virtio_disk_init+0x1e0>
    80006418:	cbe5                	beqz	a5,80006508 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000641a:	6605                	lui	a2,0x1
    8000641c:	4581                	li	a1,0
    8000641e:	ffffb097          	auipc	ra,0xffffb
    80006422:	8c8080e7          	jalr	-1848(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006426:	0001d497          	auipc	s1,0x1d
    8000642a:	64a48493          	addi	s1,s1,1610 # 80023a70 <disk>
    8000642e:	6605                	lui	a2,0x1
    80006430:	4581                	li	a1,0
    80006432:	6488                	ld	a0,8(s1)
    80006434:	ffffb097          	auipc	ra,0xffffb
    80006438:	8b2080e7          	jalr	-1870(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000643c:	6605                	lui	a2,0x1
    8000643e:	4581                	li	a1,0
    80006440:	6888                	ld	a0,16(s1)
    80006442:	ffffb097          	auipc	ra,0xffffb
    80006446:	8a4080e7          	jalr	-1884(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000644a:	100017b7          	lui	a5,0x10001
    8000644e:	4721                	li	a4,8
    80006450:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006452:	4098                	lw	a4,0(s1)
    80006454:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006458:	40d8                	lw	a4,4(s1)
    8000645a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000645e:	6498                	ld	a4,8(s1)
    80006460:	0007069b          	sext.w	a3,a4
    80006464:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006468:	9701                	srai	a4,a4,0x20
    8000646a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000646e:	6898                	ld	a4,16(s1)
    80006470:	0007069b          	sext.w	a3,a4
    80006474:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006478:	9701                	srai	a4,a4,0x20
    8000647a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000647e:	4685                	li	a3,1
    80006480:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006482:	4705                	li	a4,1
    80006484:	00d48c23          	sb	a3,24(s1)
    80006488:	00e48ca3          	sb	a4,25(s1)
    8000648c:	00e48d23          	sb	a4,26(s1)
    80006490:	00e48da3          	sb	a4,27(s1)
    80006494:	00e48e23          	sb	a4,28(s1)
    80006498:	00e48ea3          	sb	a4,29(s1)
    8000649c:	00e48f23          	sb	a4,30(s1)
    800064a0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800064a4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800064a8:	0727a823          	sw	s2,112(a5)
}
    800064ac:	60e2                	ld	ra,24(sp)
    800064ae:	6442                	ld	s0,16(sp)
    800064b0:	64a2                	ld	s1,8(sp)
    800064b2:	6902                	ld	s2,0(sp)
    800064b4:	6105                	addi	sp,sp,32
    800064b6:	8082                	ret
    panic("could not find virtio disk");
    800064b8:	00002517          	auipc	a0,0x2
    800064bc:	3f850513          	addi	a0,a0,1016 # 800088b0 <syscalls+0x340>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	084080e7          	jalr	132(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064c8:	00002517          	auipc	a0,0x2
    800064cc:	40850513          	addi	a0,a0,1032 # 800088d0 <syscalls+0x360>
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	074080e7          	jalr	116(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800064d8:	00002517          	auipc	a0,0x2
    800064dc:	41850513          	addi	a0,a0,1048 # 800088f0 <syscalls+0x380>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	064080e7          	jalr	100(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800064e8:	00002517          	auipc	a0,0x2
    800064ec:	42850513          	addi	a0,a0,1064 # 80008910 <syscalls+0x3a0>
    800064f0:	ffffa097          	auipc	ra,0xffffa
    800064f4:	054080e7          	jalr	84(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800064f8:	00002517          	auipc	a0,0x2
    800064fc:	43850513          	addi	a0,a0,1080 # 80008930 <syscalls+0x3c0>
    80006500:	ffffa097          	auipc	ra,0xffffa
    80006504:	044080e7          	jalr	68(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006508:	00002517          	auipc	a0,0x2
    8000650c:	44850513          	addi	a0,a0,1096 # 80008950 <syscalls+0x3e0>
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	034080e7          	jalr	52(ra) # 80000544 <panic>

0000000080006518 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006518:	7159                	addi	sp,sp,-112
    8000651a:	f486                	sd	ra,104(sp)
    8000651c:	f0a2                	sd	s0,96(sp)
    8000651e:	eca6                	sd	s1,88(sp)
    80006520:	e8ca                	sd	s2,80(sp)
    80006522:	e4ce                	sd	s3,72(sp)
    80006524:	e0d2                	sd	s4,64(sp)
    80006526:	fc56                	sd	s5,56(sp)
    80006528:	f85a                	sd	s6,48(sp)
    8000652a:	f45e                	sd	s7,40(sp)
    8000652c:	f062                	sd	s8,32(sp)
    8000652e:	ec66                	sd	s9,24(sp)
    80006530:	e86a                	sd	s10,16(sp)
    80006532:	1880                	addi	s0,sp,112
    80006534:	892a                	mv	s2,a0
    80006536:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006538:	00c52c83          	lw	s9,12(a0)
    8000653c:	001c9c9b          	slliw	s9,s9,0x1
    80006540:	1c82                	slli	s9,s9,0x20
    80006542:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006546:	0001d517          	auipc	a0,0x1d
    8000654a:	65250513          	addi	a0,a0,1618 # 80023b98 <disk+0x128>
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	69c080e7          	jalr	1692(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006556:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006558:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000655a:	0001db17          	auipc	s6,0x1d
    8000655e:	516b0b13          	addi	s6,s6,1302 # 80023a70 <disk>
  for(int i = 0; i < 3; i++){
    80006562:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006564:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006566:	0001dc17          	auipc	s8,0x1d
    8000656a:	632c0c13          	addi	s8,s8,1586 # 80023b98 <disk+0x128>
    8000656e:	a8b5                	j	800065ea <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006570:	00fb06b3          	add	a3,s6,a5
    80006574:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006578:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000657a:	0207c563          	bltz	a5,800065a4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000657e:	2485                	addiw	s1,s1,1
    80006580:	0711                	addi	a4,a4,4
    80006582:	1f548a63          	beq	s1,s5,80006776 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006586:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006588:	0001d697          	auipc	a3,0x1d
    8000658c:	4e868693          	addi	a3,a3,1256 # 80023a70 <disk>
    80006590:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006592:	0186c583          	lbu	a1,24(a3)
    80006596:	fde9                	bnez	a1,80006570 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006598:	2785                	addiw	a5,a5,1
    8000659a:	0685                	addi	a3,a3,1
    8000659c:	ff779be3          	bne	a5,s7,80006592 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800065a0:	57fd                	li	a5,-1
    800065a2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800065a4:	02905a63          	blez	s1,800065d8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800065a8:	f9042503          	lw	a0,-112(s0)
    800065ac:	00000097          	auipc	ra,0x0
    800065b0:	cfa080e7          	jalr	-774(ra) # 800062a6 <free_desc>
      for(int j = 0; j < i; j++)
    800065b4:	4785                	li	a5,1
    800065b6:	0297d163          	bge	a5,s1,800065d8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800065ba:	f9442503          	lw	a0,-108(s0)
    800065be:	00000097          	auipc	ra,0x0
    800065c2:	ce8080e7          	jalr	-792(ra) # 800062a6 <free_desc>
      for(int j = 0; j < i; j++)
    800065c6:	4789                	li	a5,2
    800065c8:	0097d863          	bge	a5,s1,800065d8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800065cc:	f9842503          	lw	a0,-104(s0)
    800065d0:	00000097          	auipc	ra,0x0
    800065d4:	cd6080e7          	jalr	-810(ra) # 800062a6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065d8:	85e2                	mv	a1,s8
    800065da:	0001d517          	auipc	a0,0x1d
    800065de:	4ae50513          	addi	a0,a0,1198 # 80023a88 <disk+0x18>
    800065e2:	ffffc097          	auipc	ra,0xffffc
    800065e6:	b86080e7          	jalr	-1146(ra) # 80002168 <sleep>
  for(int i = 0; i < 3; i++){
    800065ea:	f9040713          	addi	a4,s0,-112
    800065ee:	84ce                	mv	s1,s3
    800065f0:	bf59                	j	80006586 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065f2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800065f6:	00479693          	slli	a3,a5,0x4
    800065fa:	0001d797          	auipc	a5,0x1d
    800065fe:	47678793          	addi	a5,a5,1142 # 80023a70 <disk>
    80006602:	97b6                	add	a5,a5,a3
    80006604:	4685                	li	a3,1
    80006606:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006608:	0001d597          	auipc	a1,0x1d
    8000660c:	46858593          	addi	a1,a1,1128 # 80023a70 <disk>
    80006610:	00a60793          	addi	a5,a2,10
    80006614:	0792                	slli	a5,a5,0x4
    80006616:	97ae                	add	a5,a5,a1
    80006618:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000661c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006620:	f6070693          	addi	a3,a4,-160
    80006624:	619c                	ld	a5,0(a1)
    80006626:	97b6                	add	a5,a5,a3
    80006628:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000662a:	6188                	ld	a0,0(a1)
    8000662c:	96aa                	add	a3,a3,a0
    8000662e:	47c1                	li	a5,16
    80006630:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006632:	4785                	li	a5,1
    80006634:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006638:	f9442783          	lw	a5,-108(s0)
    8000663c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006640:	0792                	slli	a5,a5,0x4
    80006642:	953e                	add	a0,a0,a5
    80006644:	05890693          	addi	a3,s2,88
    80006648:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000664a:	6188                	ld	a0,0(a1)
    8000664c:	97aa                	add	a5,a5,a0
    8000664e:	40000693          	li	a3,1024
    80006652:	c794                	sw	a3,8(a5)
  if(write)
    80006654:	100d0d63          	beqz	s10,8000676e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006658:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000665c:	00c7d683          	lhu	a3,12(a5)
    80006660:	0016e693          	ori	a3,a3,1
    80006664:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006668:	f9842583          	lw	a1,-104(s0)
    8000666c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006670:	0001d697          	auipc	a3,0x1d
    80006674:	40068693          	addi	a3,a3,1024 # 80023a70 <disk>
    80006678:	00260793          	addi	a5,a2,2
    8000667c:	0792                	slli	a5,a5,0x4
    8000667e:	97b6                	add	a5,a5,a3
    80006680:	587d                	li	a6,-1
    80006682:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006686:	0592                	slli	a1,a1,0x4
    80006688:	952e                	add	a0,a0,a1
    8000668a:	f9070713          	addi	a4,a4,-112
    8000668e:	9736                	add	a4,a4,a3
    80006690:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006692:	6298                	ld	a4,0(a3)
    80006694:	972e                	add	a4,a4,a1
    80006696:	4585                	li	a1,1
    80006698:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000669a:	4509                	li	a0,2
    8000669c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800066a0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066a4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800066a8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066ac:	6698                	ld	a4,8(a3)
    800066ae:	00275783          	lhu	a5,2(a4)
    800066b2:	8b9d                	andi	a5,a5,7
    800066b4:	0786                	slli	a5,a5,0x1
    800066b6:	97ba                	add	a5,a5,a4
    800066b8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800066bc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066c0:	6698                	ld	a4,8(a3)
    800066c2:	00275783          	lhu	a5,2(a4)
    800066c6:	2785                	addiw	a5,a5,1
    800066c8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066cc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066d0:	100017b7          	lui	a5,0x10001
    800066d4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066d8:	00492703          	lw	a4,4(s2)
    800066dc:	4785                	li	a5,1
    800066de:	02f71163          	bne	a4,a5,80006700 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800066e2:	0001d997          	auipc	s3,0x1d
    800066e6:	4b698993          	addi	s3,s3,1206 # 80023b98 <disk+0x128>
  while(b->disk == 1) {
    800066ea:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066ec:	85ce                	mv	a1,s3
    800066ee:	854a                	mv	a0,s2
    800066f0:	ffffc097          	auipc	ra,0xffffc
    800066f4:	a78080e7          	jalr	-1416(ra) # 80002168 <sleep>
  while(b->disk == 1) {
    800066f8:	00492783          	lw	a5,4(s2)
    800066fc:	fe9788e3          	beq	a5,s1,800066ec <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006700:	f9042903          	lw	s2,-112(s0)
    80006704:	00290793          	addi	a5,s2,2
    80006708:	00479713          	slli	a4,a5,0x4
    8000670c:	0001d797          	auipc	a5,0x1d
    80006710:	36478793          	addi	a5,a5,868 # 80023a70 <disk>
    80006714:	97ba                	add	a5,a5,a4
    80006716:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000671a:	0001d997          	auipc	s3,0x1d
    8000671e:	35698993          	addi	s3,s3,854 # 80023a70 <disk>
    80006722:	00491713          	slli	a4,s2,0x4
    80006726:	0009b783          	ld	a5,0(s3)
    8000672a:	97ba                	add	a5,a5,a4
    8000672c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006730:	854a                	mv	a0,s2
    80006732:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006736:	00000097          	auipc	ra,0x0
    8000673a:	b70080e7          	jalr	-1168(ra) # 800062a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000673e:	8885                	andi	s1,s1,1
    80006740:	f0ed                	bnez	s1,80006722 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006742:	0001d517          	auipc	a0,0x1d
    80006746:	45650513          	addi	a0,a0,1110 # 80023b98 <disk+0x128>
    8000674a:	ffffa097          	auipc	ra,0xffffa
    8000674e:	554080e7          	jalr	1364(ra) # 80000c9e <release>
}
    80006752:	70a6                	ld	ra,104(sp)
    80006754:	7406                	ld	s0,96(sp)
    80006756:	64e6                	ld	s1,88(sp)
    80006758:	6946                	ld	s2,80(sp)
    8000675a:	69a6                	ld	s3,72(sp)
    8000675c:	6a06                	ld	s4,64(sp)
    8000675e:	7ae2                	ld	s5,56(sp)
    80006760:	7b42                	ld	s6,48(sp)
    80006762:	7ba2                	ld	s7,40(sp)
    80006764:	7c02                	ld	s8,32(sp)
    80006766:	6ce2                	ld	s9,24(sp)
    80006768:	6d42                	ld	s10,16(sp)
    8000676a:	6165                	addi	sp,sp,112
    8000676c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000676e:	4689                	li	a3,2
    80006770:	00d79623          	sh	a3,12(a5)
    80006774:	b5e5                	j	8000665c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006776:	f9042603          	lw	a2,-112(s0)
    8000677a:	00a60713          	addi	a4,a2,10
    8000677e:	0712                	slli	a4,a4,0x4
    80006780:	0001d517          	auipc	a0,0x1d
    80006784:	2f850513          	addi	a0,a0,760 # 80023a78 <disk+0x8>
    80006788:	953a                	add	a0,a0,a4
  if(write)
    8000678a:	e60d14e3          	bnez	s10,800065f2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000678e:	00a60793          	addi	a5,a2,10
    80006792:	00479693          	slli	a3,a5,0x4
    80006796:	0001d797          	auipc	a5,0x1d
    8000679a:	2da78793          	addi	a5,a5,730 # 80023a70 <disk>
    8000679e:	97b6                	add	a5,a5,a3
    800067a0:	0007a423          	sw	zero,8(a5)
    800067a4:	b595                	j	80006608 <virtio_disk_rw+0xf0>

00000000800067a6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067a6:	1101                	addi	sp,sp,-32
    800067a8:	ec06                	sd	ra,24(sp)
    800067aa:	e822                	sd	s0,16(sp)
    800067ac:	e426                	sd	s1,8(sp)
    800067ae:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067b0:	0001d497          	auipc	s1,0x1d
    800067b4:	2c048493          	addi	s1,s1,704 # 80023a70 <disk>
    800067b8:	0001d517          	auipc	a0,0x1d
    800067bc:	3e050513          	addi	a0,a0,992 # 80023b98 <disk+0x128>
    800067c0:	ffffa097          	auipc	ra,0xffffa
    800067c4:	42a080e7          	jalr	1066(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067c8:	10001737          	lui	a4,0x10001
    800067cc:	533c                	lw	a5,96(a4)
    800067ce:	8b8d                	andi	a5,a5,3
    800067d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067d6:	689c                	ld	a5,16(s1)
    800067d8:	0204d703          	lhu	a4,32(s1)
    800067dc:	0027d783          	lhu	a5,2(a5)
    800067e0:	04f70863          	beq	a4,a5,80006830 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800067e4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067e8:	6898                	ld	a4,16(s1)
    800067ea:	0204d783          	lhu	a5,32(s1)
    800067ee:	8b9d                	andi	a5,a5,7
    800067f0:	078e                	slli	a5,a5,0x3
    800067f2:	97ba                	add	a5,a5,a4
    800067f4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067f6:	00278713          	addi	a4,a5,2
    800067fa:	0712                	slli	a4,a4,0x4
    800067fc:	9726                	add	a4,a4,s1
    800067fe:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006802:	e721                	bnez	a4,8000684a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006804:	0789                	addi	a5,a5,2
    80006806:	0792                	slli	a5,a5,0x4
    80006808:	97a6                	add	a5,a5,s1
    8000680a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000680c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006810:	ffffc097          	auipc	ra,0xffffc
    80006814:	b0c080e7          	jalr	-1268(ra) # 8000231c <wakeup>

    disk.used_idx += 1;
    80006818:	0204d783          	lhu	a5,32(s1)
    8000681c:	2785                	addiw	a5,a5,1
    8000681e:	17c2                	slli	a5,a5,0x30
    80006820:	93c1                	srli	a5,a5,0x30
    80006822:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006826:	6898                	ld	a4,16(s1)
    80006828:	00275703          	lhu	a4,2(a4)
    8000682c:	faf71ce3          	bne	a4,a5,800067e4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006830:	0001d517          	auipc	a0,0x1d
    80006834:	36850513          	addi	a0,a0,872 # 80023b98 <disk+0x128>
    80006838:	ffffa097          	auipc	ra,0xffffa
    8000683c:	466080e7          	jalr	1126(ra) # 80000c9e <release>
}
    80006840:	60e2                	ld	ra,24(sp)
    80006842:	6442                	ld	s0,16(sp)
    80006844:	64a2                	ld	s1,8(sp)
    80006846:	6105                	addi	sp,sp,32
    80006848:	8082                	ret
      panic("virtio_disk_intr status");
    8000684a:	00002517          	auipc	a0,0x2
    8000684e:	11e50513          	addi	a0,a0,286 # 80008968 <syscalls+0x3f8>
    80006852:	ffffa097          	auipc	ra,0xffffa
    80006856:	cf2080e7          	jalr	-782(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
