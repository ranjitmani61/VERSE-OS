#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static unsigned char cs(const unsigned char *d,int n){unsigned char s=0; for(int i=0;i<n;i++)s^=d[i]; return s;}
#define BS 64
#define SS 4096
#define CTRL_BYTES ((int)sizeof(int))
#define MB ((SS-CTRL_BYTES)/BS)
typedef struct{unsigned char ph; char data[BS-2]; unsigned char h;}Block;
static Block *st; static int bc=0; static volatile int *rf;
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){st=(Block*)store; memset(st,0,SS); rf=(volatile int*)((char*)st+SS-CTRL_BYTES); *rf=0; lw("CODEX: ok\n"); return 0;}
int fs_write(const char *d){if(st==0||rf==0||bc>=MB)return -1; Block *b=&st[bc]; b->ph=(bc==0)?0:st[bc-1].h; strncpy(b->data,d,BS-2); b->data[BS-3]=0; b->h=cs((unsigned char*)b,BS-1); bc++; *rf=bc; return bc-1;}
int fs_verify(void){if(st==0)return -1; for(int i=0;i<bc;i++){if(st[i].ph!=(i==0?0:st[i-1].h))return -1; if(st[i].h!=cs((unsigned char*)&st[i],BS-1))return -1;} return 0;}
int fs_read_all(void){return 0;}
