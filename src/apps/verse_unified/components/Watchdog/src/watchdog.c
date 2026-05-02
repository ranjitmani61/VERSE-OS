#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
#define HEARTBEAT_MISS_LIMIT 50

#ifndef VERSE_TESTWORKER_REPEAT_DEADLOCK
#define NORMAL_PASS_MONITOR_POLLS (HEARTBEAT_MISS_LIMIT * 2)

static int normal_recovery_pass_window(volatile int *hb, int start)
{
    int last = start;
    int fc = 0;

    for (int poll = 0; poll < NORMAL_PASS_MONITOR_POLLS; poll++) {
        for (volatile int d = 0; d < 1000000; d++);
        int cur = *hb;
        if (cur == last) {
            fc++;
            if (fc >= HEARTBEAT_MISS_LIMIT) {
                return -1;
            }
        } else {
            fc = 0;
            last = cur;
        }
    }

    return 0;
}
#endif

int run(void){
    volatile int *hb = (volatile int*)heartbeat;
    volatile int *rd = (volatile int*)((char*)heartbeat+4092);
    volatile int *kflag = (volatile int*)kill_flag;
    volatile int *rsig = (volatile int*)recovery_signal;
    *kflag = 0;
    *rsig = 0;
    while (*rd == 0);
    printf("WDOG: active monitoring\n");
    int recovery_passes = 0;
#ifndef VERSE_TESTWORKER_REPEAT_DEADLOCK
    int normal_pass_printed = 0;
#endif
    while (1) {
        int last = *hb, fc = 0;
        while (1) {
            for (volatile int d=0; d<1000000; d++);
            int cur = *hb;
            if (cur == last) {
                fc++;
                if (fc >= HEARTBEAT_MISS_LIMIT) {
                    printf("WDOG: heartbeat lost after %d polls, setting kill flag\n", fc);
                    *kflag = 1;
                    break;
                }
            } else { fc = 0; }
            last = cur;
        }
        printf("WDOG: waiting for recovery heartbeat...\n");
        while (*hb == last) { for (volatile int d=0; d<1000000; d++); }
        int recovered = *hb;
        *kflag = 0;
        printf("WDOG: recovery heartbeat received (%d)\n", recovered);
        if (recovered >= 1000000) {
            recovery_passes++;
            *rsig = recovery_passes;
            printf("WDOG: recovered worker entry heartbeat proof\n");
            printf("VERSE_RECOVERY_PASS_%d\n", recovery_passes);
        }
        printf("WDOG: heartbeat resumed, re-armed and monitoring\n");
#ifndef VERSE_TESTWORKER_REPEAT_DEADLOCK
        if (!normal_pass_printed && recovery_passes == 1 &&
            normal_recovery_pass_window(hb, recovered) == 0) {
            printf("VERSE_NORMAL_RECOVERY_PASS\n");
            normal_pass_printed = 1;
        }
#endif
    }
    return 0;
}
