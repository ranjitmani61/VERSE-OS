#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
#define LS 4096
typedef struct { volatile unsigned h; volatile unsigned t; char d[LS-8]; } Ring;
int run(void) { Ring *r=(Ring*)logbuf; r->h=r->t=0; while(1){ while(r->t!=r->h){putchar(r->d[r->t]); r->t=(r->t+1)%sizeof(r->d);} for(volatile int i=0;i<100000;i++); } return 0; }
