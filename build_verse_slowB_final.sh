#!/bin/bash
set -e
mkdir -p /tmp/camkes/projects/camkes/apps/verse_unified/{interfaces,components/{LogRing,Sentinel,Hello,Client,CortexMM,MemClient,WorkerA,WorkerB,DharmaNet,CodexFS,WriteClient,ReadClient,TestWorker,Watchdog,ProcMan}/src}

# ---- Interfaces ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/interfaces/Hello.idl4 << "EOFIDL"
procedure Hello { void say_hello(); };
EOFIDL
cat > /tmp/camkes/projects/camkes/apps/verse_unified/interfaces/FS.idl4 << "EOFIDL"
procedure FS { int write(in string data); int verify(); int read_all(); };
EOFIDL

# ---- LogRing ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/LogRing/LogRing.camkes << "EOFC"
component LogRing { control; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/LogRing/src/logring.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
#define LS 4096
typedef struct { volatile unsigned h; volatile unsigned t; char d[LS-8]; } Ring;
int run(void) { Ring *r=(Ring*)logbuf; r->h=r->t=0; while(1){ while(r->t!=r->h){putchar(r->d[r->t]); r->t=(r->t+1)%sizeof(r->d);} for(volatile int i=0;i<100000;i++); } return 0; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/LogRing/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(LogRing SOURCES src/logring.c)
EOFC

# ---- Sentinel ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Sentinel/Sentinel.camkes << "EOFC"
import "../../interfaces/Hello.idl4";
component Sentinel { provides Hello client_h; uses Hello server_h; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Sentinel/src/sentinel.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
#define LC 0
#define LS 2
static int la(int s,int d){return s<=d;}
void client_h_say_hello(void){ if(la(LC,LS)){lw("S: FORWARD\n"); server_h_say_hello();} else {lw("S: BLOCK\n");} }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Sentinel/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(Sentinel SOURCES src/sentinel.c)
EOFC

# ---- Hello ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Hello/Hello.camkes << "EOFC"
import "../../interfaces/Hello.idl4";
component Hello { provides Hello h; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Hello/src/hello.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
void h_say_hello(void){lw("HELLO: ok\n");}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Hello/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(Hello SOURCES src/hello.c)
EOFC

# ---- Client ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Client/Client.camkes << "EOFC"
import "../../interfaces/Hello.idl4";
component Client { control; uses Hello h; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Client/src/client.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){lw("CLIENT: call\n"); h_say_hello(); lw("CLIENT: done\n"); return 0;}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Client/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(Client SOURCES src/client.c)
EOFC

# ---- CortexMM ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/CortexMM/CortexMM.camkes << "EOFC"
component CortexMM { control; dataport Buf page_allocatable; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/CortexMM/src/cortexmm.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){strcpy((char*)page_allocatable,"CORTEX: ready"); lw("CORTEX: ok\n"); return 0;}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/CortexMM/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(CortexMM SOURCES src/cortexmm.c)
EOFC

# ---- MemClient ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/MemClient/MemClient.camkes << "EOFC"
component MemClient { control; dataport Buf allocated_page; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/MemClient/src/memclient.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){lw("MEMCL: "); lw((char*)allocated_page); lw("\n"); return 0;}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/MemClient/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(MemClient SOURCES src/memclient.c)
EOFC

# ---- WorkerA ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WorkerA/WorkerA.camkes << "EOFC"
component WorkerA { control; dataport Buf shared; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WorkerA/src/workera.c << "EOFC"
#include <camkes.h>
#include <camkes/dataport.h>
int run(void){ volatile unsigned long *c=(volatile unsigned long*)shared; *c=0; while(1){(*c)++;} return 0; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WorkerA/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(WorkerA SOURCES src/workera.c)
EOFC

# ---- WorkerB (SLOWED DOWN 1000x) ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WorkerB/WorkerB.camkes << "EOFC"
component WorkerB { control; dataport Buf shared; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WorkerB/src/workerb.c << "EOFC"
#include <camkes.h>
#include <camkes/dataport.h>
int run(void){ volatile unsigned long *c=(volatile unsigned long*)shared; *c=0; while(1){ (*c)++; for(volatile int i=0;i<1000000;i++); } return 0; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WorkerB/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(WorkerB SOURCES src/workerb.c)
EOFC

# ---- DharmNet (escalation) ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/DharmaNet/src/dharmanet.c << "DHARMA"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
#define SMOOTH_WIN 4
#define WARN_ENTER 55
#define WARN_EXIT 45
#define DWELL 5
#define CRIT_ENTER 80
#define CRIT_EXIT 70
#define CRIT_DWELL 8
#define CRIT_ESCALATE_EPOCHS 20
int run(void){
    volatile unsigned long *a=(volatile unsigned long*)workerA_buf;
    volatile unsigned long *b=(volatile unsigned long*)workerB_buf;
    volatile int *sev_out = (volatile int*)severity_buf;
    unsigned long hist[SMOOTH_WIN]={0}; int hi=0,hcnt=0; unsigned long hsum=0;
    int warned=0,crit=0,aw=0,bo=0,ac=0,bc=0,ep=0,crit_ep=0; char last='O';
    *sev_out=0;
    lw("DHARMA: strict hysteresis + escalation\n");
    while(1){
        for(volatile int i=0;i<5000000;i++);
        unsigned long ta=*a,tb=*b; *a=*b=0; unsigned long t=ta+tb; if(!t)continue;
        int pa=(int)(ta*100/t);
        if(hcnt<SMOOTH_WIN){hist[hcnt]=pa;hsum+=pa;hcnt++;}else{hsum-=hist[hi];hist[hi]=pa;hsum+=pa;hi=(hi+1)%SMOOTH_WIN;}
        unsigned long sp=hcnt==SMOOTH_WIN?hsum/SMOOTH_WIN:pa;
        if(!crit){if(sp>CRIT_ENTER){ac++;if(ac>=CRIT_DWELL){crit=1;warned=0;aw=0;bo=0;ac=0;crit_ep=0;}}else{ac=0;}}
        else{if(sp<CRIT_EXIT){bc++;if(bc>=DWELL){crit=0;bc=0;crit_ep=0;}}else{bc=0;}}
        if(!crit){if(!warned){if(sp>WARN_ENTER){aw++;if(aw>=DWELL){warned=1;aw=0;bo=0;}}else{aw=0;}}else{if(sp<WARN_EXIT){bo++;if(bo>=DWELL){warned=0;bo=0;aw=0;}}else{bo=0;}}}
        char cur=crit?'C':(warned?'W':'O');
        if(crit){ crit_ep++; if(crit_ep>=CRIT_ESCALATE_EPOCHS) *sev_out=2; else *sev_out=1; }
        else if(warned) *sev_out=1;
        else *sev_out=0;
        if(cur!=last||ep>=10){char b[64];if(cur=='C')sprintf(b,"DHARMA: CRIT (%lu%%) sev=%d\n",sp,*sev_out);else if(cur=='W')sprintf(b,"DHARMA: WARN (%lu%%)\n",sp);else sprintf(b,"DHARMA: OK (%lu%%)\n",sp);lw(b);last=cur;ep=0;}
        ep++;
    }
}
DHARMA
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/DharmaNet/DharmaNet.camkes << "EOFC"
component DharmaNet { control; dataport Buf workerA_buf; dataport Buf workerB_buf; dataport Buf severity_buf; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/DharmaNet/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(DharmaNet SOURCES src/dharmanet.c)
EOFC

# ---- ProcMan (severity escalation + bounded restarts) ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/ProcMan/src/procman.c << "PROCMAN"
#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
#define MAX_RESTARTS 3
#define BASE_BACKOFF 2000000
int run(void){
    volatile int *kflag = (volatile int*)kill_flag;
    volatile int *rf = (volatile int*)restart_flag;
    volatile int *sev_in = (volatile int*)severity_buf;
    int restarts=0;
    *rf=0; printf("ProcMan: waiting\n");
    while(1){
        if(*sev_in==2){
            printf("ProcMan: CRIT severity escalated - quarantining\n");
            *rf=0;
            while(1){ for(volatile int d=0;d<1000000;d++); }
        }
        while(*kflag==0){ for(volatile int d=0;d<500000;d++); }
        restarts++;
        if(restarts>MAX_RESTARTS){
            printf("ProcMan: QUARANTINE\n");
            *rf=0;
            while(1){ for(volatile int d=0;d<1000000;d++); }
        }
        printf("ProcMan: restart attempt %d/%d\n",restarts,MAX_RESTARTS);
        for(volatile int d=0;d<(restarts*BASE_BACKOFF);d++);
        *rf=1; for(volatile int d=0;d<2000000;d++); *rf=0;
        printf("ProcMan: restart done\n");
        while(*kflag==1){ for(volatile int d=0;d<500000;d++); }
    }
}
PROCMAN
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/ProcMan/ProcMan.camkes << "EOFC"
component ProcMan { control; dataport Buf kill_flag; dataport Buf restart_flag; dataport Buf severity_buf; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/ProcMan/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(ProcMan SOURCES src/procman.c)
EOFC

# ---- CodexFS ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/CodexFS/CodexFS.camkes << "EOFC"
import "../../interfaces/FS.idl4";
component CodexFS { control; provides FS fs; dataport Buf store; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/CodexFS/src/codexfs.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static unsigned char cs(const unsigned char *d,int n){unsigned char s=0; for(int i=0;i<n;i++)s^=d[i]; return s;}
#define BS 64
#define SS 4096
#define MB (SS/BS)
typedef struct{unsigned char ph; char data[BS-2]; unsigned char h;}Block;
static Block *st; static int bc=0; static volatile int *rf;
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){st=(Block*)store; memset(st,0,SS); rf=(volatile int*)((char*)st+SS-4); *rf=0; lw("CODEX: ok\n"); return 0;}
int fs_write(const char *d){if(bc>=MB)return -1; Block *b=&st[bc]; b->ph=(bc==0)?0:st[bc-1].h; strncpy(b->data,d,BS-2); b->data[BS-3]=0; b->h=cs((unsigned char*)b,BS-1); bc++; *rf=bc; return bc-1;}
int fs_verify(void){for(int i=0;i<bc;i++){if(st[i].h!=cs((unsigned char*)&st[i],BS-1))return -1;} return 0;}
int fs_read_all(void){return 0;}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/CodexFS/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(CodexFS SOURCES src/codexfs.c)
EOFC

# ---- WriteClient ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WriteClient/WriteClient.camkes << "EOFC"
import "../../interfaces/FS.idl4";
component WriteClient { control; uses FS fs; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WriteClient/src/writeclient.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
int run(void){fs_write("G"); fs_write("M"); fs_write("F"); lw("WRITER: done\n"); return 0;}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/WriteClient/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(WriteClient SOURCES src/writeclient.c)
EOFC

# ---- ReadClient ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/ReadClient/ReadClient.camkes << "EOFC"
import "../../interfaces/FS.idl4";
component ReadClient { control; uses FS fs; dataport Buf store; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/ReadClient/src/readclient.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
#define SS 4096
int run(void){volatile int *rf=(volatile int*)((char*)store+SS-4); while(*rf<3); if(fs_verify()==0) lw("READER: ok\n"); else lw("READER: err\n"); return 0;}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/ReadClient/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(ReadClient SOURCES src/readclient.c)
EOFC

# ---- TestWorker ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/TestWorker/TestWorker.camkes << "EOFC"
component TestWorker { control; dataport Buf heartbeat; dataport Buf restart_flag; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/TestWorker/src/testworker.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
int run(void){
    volatile int *hb = (volatile int*)heartbeat;
    volatile int *rd = (volatile int*)((char*)heartbeat+4092);
    volatile int *rf = (volatile int*)restart_flag;
    *hb = 0; *rd = 0; *rf = 0; *rd = 1;
    printf("TestWorker: started\n");
    for (int i=1; i<=5; i++) { *hb = i; for (volatile int d=0; d<10000000; d++); }
    printf("TestWorker: DEADLOCK SIMULATION\n");
    while (*rf == 0) { for (volatile int d=0; d<1000000; d++); }
    printf("TestWorker: restart flag seen! Reinitialising...\n");
    *rf = 0;
    *hb = 0;
    for (int i=1; i<=5; i++) { *hb = i; for (volatile int d=0; d<10000000; d++); }
    printf("TestWorker: second run complete, entering continuous loop\n");
    int counter = 0;
    while (1) {
        *hb = ++counter;
        for (volatile int d=0; d<10000000; d++);
    }
    return 0;
}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/TestWorker/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(TestWorker SOURCES src/testworker.c)
EOFC

# ---- Watchdog ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Watchdog/Watchdog.camkes << "EOFC"
component Watchdog { control; dataport Buf heartbeat; dataport Buf kill_flag; dataport Buf logbuf; }
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Watchdog/src/watchdog.c << "EOFC"
#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
int run(void){
    volatile int *hb = (volatile int*)heartbeat;
    volatile int *rd = (volatile int*)((char*)heartbeat+4092);
    volatile int *kflag = (volatile int*)kill_flag;
    *kflag = 0;
    while (*rd == 0);
    printf("WDOG: active monitoring\n");
    while (1) {
        int last = *hb, fc = 0;
        while (1) {
            for (volatile int d=0; d<1000000; d++);
            int cur = *hb;
            if (cur == last) {
                fc++;
                if (fc >= 15) {
                    printf("WDOG: heartbeat lost after %d polls, setting kill flag\n", fc);
                    *kflag = 1;
                    break;
                }
            } else { fc = 0; }
            last = cur;
        }
        printf("WDOG: waiting for recovery heartbeat...\n");
        while (*hb == last) { for (volatile int d=0; d<1000000; d++); }
        *kflag = 0;
        printf("WDOG: heartbeat resumed, re-armed and monitoring\n");
    }
    return 0;
}
EOFC
cat > /tmp/camkes/projects/camkes/apps/verse_unified/components/Watchdog/CMakeLists.txt << "EOFC"
DeclareCAmkESComponent(Watchdog SOURCES src/watchdog.c)
EOFC

# ---- Assembly (with severity port) ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/verse_unified.camkes << "EOFC"
import <std_connector.camkes>;
import "components/LogRing/LogRing.camkes";
import "components/Sentinel/Sentinel.camkes";
import "components/Hello/Hello.camkes";
import "components/Client/Client.camkes";
import "components/CortexMM/CortexMM.camkes";
import "components/MemClient/MemClient.camkes";
import "components/WorkerA/WorkerA.camkes";
import "components/WorkerB/WorkerB.camkes";
import "components/DharmaNet/DharmaNet.camkes";
import "components/CodexFS/CodexFS.camkes";
import "components/WriteClient/WriteClient.camkes";
import "components/ReadClient/ReadClient.camkes";
import "components/TestWorker/TestWorker.camkes";
import "components/Watchdog/Watchdog.camkes";
import "components/ProcMan/ProcMan.camkes";
assembly {
    composition {
        component LogRing logring;
        component Sentinel sentinel;
        component Hello hello;
        component Client client;
        component CortexMM cortexmm;
        component MemClient memclient;
        component WorkerA worker_a;
        component WorkerB worker_b;
        component DharmaNet dharmanet;
        component CodexFS codexfs;
        component WriteClient writeclient;
        component ReadClient readclient;
        component TestWorker testworker;
        component Watchdog watchdog;
        component ProcMan procman;
        connection seL4SharedData ls(from sentinel.logbuf, to logring.logbuf);
        connection seL4SharedData lh(from hello.logbuf, to logring.logbuf);
        connection seL4SharedData lc(from client.logbuf, to logring.logbuf);
        connection seL4SharedData lm(from cortexmm.logbuf, to logring.logbuf);
        connection seL4SharedData lmc(from memclient.logbuf, to logring.logbuf);
        connection seL4SharedData la(from worker_a.logbuf, to logring.logbuf);
        connection seL4SharedData lb(from worker_b.logbuf, to logring.logbuf);
        connection seL4SharedData ld(from dharmanet.logbuf, to logring.logbuf);
        connection seL4SharedData lx(from codexfs.logbuf, to logring.logbuf);
        connection seL4SharedData lw(from writeclient.logbuf, to logring.logbuf);
        connection seL4SharedData lr(from readclient.logbuf, to logring.logbuf);
        connection seL4SharedData lt(from testworker.logbuf, to logring.logbuf);
        connection seL4SharedData lwd(from watchdog.logbuf, to logring.logbuf);
        connection seL4SharedData lp(from procman.logbuf, to logring.logbuf);
        connection seL4RPCCall rpc(from client.h, to sentinel.client_h);
        connection seL4RPCCall rpc2(from sentinel.server_h, to hello.h);
        connection seL4SharedData mem(from cortexmm.page_allocatable, to memclient.allocated_page);
        connection seL4SharedData wa(from worker_a.shared, to dharmanet.workerA_buf);
        connection seL4SharedData wb(from worker_b.shared, to dharmanet.workerB_buf);
        connection seL4RPCCall fsw(from writeclient.fs, to codexfs.fs);
        connection seL4RPCCall fsr(from readclient.fs, to codexfs.fs);
        connection seL4SharedData fstore(from codexfs.store, to readclient.store);
        connection seL4SharedData hb(from testworker.heartbeat, to watchdog.heartbeat);
        connection seL4SharedData kf(from watchdog.kill_flag, to procman.kill_flag);
        connection seL4SharedData rf(from procman.restart_flag, to testworker.restart_flag);
        connection seL4SharedData sev(from dharmanet.severity_buf, to procman.severity_buf);
    }
}
EOFC

# ---- CMakeLists.txt ----
cat > /tmp/camkes/projects/camkes/apps/verse_unified/CMakeLists.txt << "EOFC"
cmake_minimum_required(VERSION 3.16.0)
project(verse_unified C)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/LogRing)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Sentinel)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Hello)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Client)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/CortexMM)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/MemClient)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/WorkerA)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/WorkerB)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/DharmaNet)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/CodexFS)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/WriteClient)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/ReadClient)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/TestWorker)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/Watchdog)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/components/ProcMan)
DeclareCAmkESRootserver(verse_unified.camkes)
EOFC

# ---- BUILD ----
cd /tmp/camkes && rm -rf build_unified && mkdir build_unified && cd build_unified
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified
ninja && echo BUILD_OK && ./simulate
