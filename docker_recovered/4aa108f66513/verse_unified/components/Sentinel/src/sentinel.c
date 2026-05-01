#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
#define LC 0
#define LS 2
static int la(int s,int d){return s<=d;}
void client_h_say_hello(void){ if(la(LC,LS)){lw("S: FORWARD\n"); server_h_say_hello();} else {lw("S: BLOCK\n");} }
