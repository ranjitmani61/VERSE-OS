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
