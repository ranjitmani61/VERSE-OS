#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){strcpy((char*)page_allocatable,"CORTEX: ready"); lw("CORTEX: ok\n"); return 0;}
