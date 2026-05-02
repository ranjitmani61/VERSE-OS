#include <camkes.h>
#include <stdio.h>
#include <string.h>
#include <camkes/dataport.h>
static void lw(const char *m){volatile unsigned *h=(volatile unsigned*)logbuf; char *d=(char*)logbuf+8; unsigned x=*h; int n; for(n=0;m[n]&&n<80;n++); for(int i=0;i<n;i++){d[x]=m[i]; x=(x+1)%4088;} *h=x;}
#define SMOOTH_WIN 4
#define WARN_ENTER 55
#define WARN_EXIT 45
#define WARN_DWELL 3
#define CRIT_EXIT_DWELL 5
#define CRIT_ENTER 80
#define CRIT_EXIT 70
#define CRIT_DWELL 8
#define CRIT_ESCALATE_EPOCHS 20
int run(void){
    volatile unsigned long *a=(volatile unsigned long*)workerA_buf;
    volatile unsigned long *b=(volatile unsigned long*)workerB_buf;
    volatile int *sev_out = (volatile int*)severity_buf;
    volatile int *recovery = (volatile int*)recovery_signal;
    unsigned long hist[SMOOTH_WIN]={0}; int hi=0,hcnt=0; unsigned long hsum=0;
    int warned=0,crit=0,aw=0,bo=0,ac=0,bc=0,ep=0,crit_ep=0,seen_recovery=0; char last='O';
    *sev_out=0;
    lw("DHARMA: strict hysteresis + escalation\n");
    while(1){
        for(volatile int i=0;i<5000000;i++);
        int recovery_pass = *recovery;
        if(recovery_pass!=0 && recovery_pass!=seen_recovery){
            seen_recovery=recovery_pass;
            warned=0; crit=0; aw=0; ac=0; bc=0; bo=0; crit_ep=0; ep=0; last='O'; *sev_out=0;
            lw("DHARMA: OK after recovery\n");
            continue;
        }
        unsigned long ta=*a,tb=*b; *a=*b=0;
        unsigned long t=ta+tb; if(!t)continue;
        int pa=(int)(ta*100/t);
        if(hcnt<SMOOTH_WIN){hist[hcnt]=pa;hsum+=pa;hcnt++;}else{hsum-=hist[hi];hist[hi]=pa;hsum+=pa;hi=(hi+1)%SMOOTH_WIN;}
        unsigned long sp=hcnt==SMOOTH_WIN?hsum/SMOOTH_WIN:pa;
        if(!crit){if(sp>CRIT_ENTER){ac++;if(ac>=CRIT_DWELL){crit=1;warned=0;aw=0;bo=0;ac=0;crit_ep=0;}}else{ac=0;}}
        else{if(sp<CRIT_EXIT){bc++;if(bc>=CRIT_EXIT_DWELL){crit=0;bc=0;crit_ep=0;}}else{bc=0;}}
        if(!crit){if(!warned){if(sp>WARN_ENTER){aw++;if(aw>=WARN_DWELL){warned=1;aw=0;bo=0;}}else{aw=0;}}else{if(sp<WARN_EXIT){bo++;if(bo>=WARN_DWELL){warned=0;bo=0;aw=0;}}else{bo=0;}}}
        char cur=crit?'C':(warned?'W':'O');
        if(crit){ crit_ep++; if(crit_ep>=CRIT_ESCALATE_EPOCHS) *sev_out=2; else *sev_out=1; }
        else if(warned) *sev_out=1;
        else *sev_out=0;
        if(cur!=last||ep>=10){char b[64];if(cur=='C')sprintf(b,"DHARMA: CRIT (%lu%%) sev=%d\n",sp,*sev_out);else if(cur=='W')sprintf(b,"DHARMA: WARN (%lu%%)\n",sp);else sprintf(b,"DHARMA: OK (%lu%%)\n",sp);lw(b);last=cur;ep=0;}
        ep++;
    }
}
