#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
int run(void){
    volatile int *kflag = (volatile int*)kill_flag;
    volatile int *rf = (volatile int*)restart_flag;
    *rf = 0;
    printf("ProcMan: waiting...\n");
    while (*kflag == 0) { for (volatile int d=0; d<500000; d++); }
    printf("ProcMan: kill flag detected! Restarting TestWorker.\n");
    *rf = 1;
    printf("ProcMan: restart signal sent, re-arming\n");
    return 0;
}
