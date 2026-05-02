#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>

__attribute__((used, noinline, noreturn))
void verse_recovery_entry(void)
{
    volatile int *hb = (volatile int*)heartbeat;
    volatile int *rf = (volatile int*)restart_flag;

    *rf = 0;

    int counter = 1000000;

#ifdef VERSE_TESTWORKER_REPEAT_DEADLOCK
    for (int i = 0; i < 5; i++) {
        *hb = ++counter;
        for (volatile int d = 0; d < 10000000; d++);
    }

    /*
     * Recovered worker deliberately stops heartbeating again.
     * This probes whether ProcMan can perform repeated TCB recovery.
     */
    while (1) {
        for (volatile int d = 0; d < 1000000; d++);
    }
#else
    while (1) {
        *hb = ++counter;
        for (volatile int d = 0; d < 10000000; d++);
    }
#endif
}

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
