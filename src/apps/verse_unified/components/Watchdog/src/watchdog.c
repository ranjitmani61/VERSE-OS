#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>
#define HEARTBEAT_MISS_LIMIT 50
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
            printf("WDOG: recovered worker entry heartbeat proof\n");
            printf("VERSE_RECOVERY_PASS\n");
        }
        printf("WDOG: heartbeat resumed, re-armed and monitoring\n");
    }
    return 0;
}
