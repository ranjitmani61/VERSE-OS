#include <camkes.h>
#include <stdio.h>
#include <camkes/dataport.h>

#ifdef VERSE_TCB_ENFORCED
#include <sel4/sel4.h>
#ifndef VERSE_WORKER_TCB_CPTR
#define VERSE_WORKER_TCB_CPTR ((seL4_CPtr)0x100)
#endif
#ifndef VERSE_WORKER_FAULT_EP_CPTR
#define VERSE_WORKER_FAULT_EP_CPTR ((seL4_CPtr)0x101)
#endif
#ifndef VERSE_PROCMAN_CNODE_CPTR
#define VERSE_PROCMAN_CNODE_CPTR ((seL4_CPtr)0x102)
#endif
#ifndef VERSE_WORKER_TCB_UNTYPED_CPTR
#define VERSE_WORKER_TCB_UNTYPED_CPTR ((seL4_CPtr)0x103)
#endif
#ifndef VERSE_FRESH_WORKER_TCB_CPTR
#define VERSE_FRESH_WORKER_TCB_CPTR ((seL4_CPtr)0x104)
#endif
#ifndef VERSE_WORKER_CSPACE_CPTR
#define VERSE_WORKER_CSPACE_CPTR ((seL4_CPtr)0x105)
#endif
#ifndef VERSE_WORKER_VSPACE_CPTR
#define VERSE_WORKER_VSPACE_CPTR ((seL4_CPtr)0x106)
#endif
#ifndef VERSE_WORKER_IPC_BUFFER_CPTR
#define VERSE_WORKER_IPC_BUFFER_CPTR ((seL4_CPtr)0x107)
#endif
#ifndef VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR
#define VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR ((seL4_CPtr)0x108)
#endif
#ifndef VERSE_CNODE_DEST_INDEX
#define VERSE_CNODE_DEST_INDEX 0
#endif
#ifndef VERSE_CNODE_DEST_DEPTH
#define VERSE_CNODE_DEST_DEPTH 0
#endif
#ifndef VERSE_WORKER_CSPACE_GUARD_BITS
#define VERSE_WORKER_CSPACE_GUARD_BITS 52
#endif
#ifndef VERSE_WORKER_VSPACE_ROOT_DATA
#define VERSE_WORKER_VSPACE_ROOT_DATA 0
#endif
#ifndef VERSE_WORKER_IPC_BUFFER_ADDR
#define VERSE_WORKER_IPC_BUFFER_ADDR 0
#endif
#ifndef VERSE_WORKER_ENTRY_IP
#define VERSE_WORKER_ENTRY_IP 0
#endif
#ifndef VERSE_WORKER_STACK_TOP
#define VERSE_WORKER_STACK_TOP 0
#endif
#ifdef CONFIG_KERNEL_MCS
#ifndef VERSE_WORKER_SCHED_CONTEXT_CPTR
#define VERSE_WORKER_SCHED_CONTEXT_CPTR ((seL4_CPtr)0)
#endif
#ifndef VERSE_SCHED_AUTH_TCB_CPTR
#define VERSE_SCHED_AUTH_TCB_CPTR ((seL4_CPtr)seL4_CapInitThreadTCB)
#endif
#ifndef VERSE_WORKER_PRIORITY
#define VERSE_WORKER_PRIORITY 254
#endif
#ifndef VERSE_WORKER_MAX_PRIORITY
#define VERSE_WORKER_MAX_PRIORITY 254
#endif
#endif
#endif

#define MAX_RESTARTS 3
#define BASE_BACKOFF 2000000
#define RECOVERY_POLL_DELAY 500000
#define RECOVERY_WAIT_POLLS 2000

static int cooperative_restart(volatile int *rf, volatile int *kflag)
{
    int ack_seen = 0;
    *rf = 1;
    for (int poll = 0; poll < RECOVERY_WAIT_POLLS; poll++) {
        if (!ack_seen && *rf == 0) {
            printf("ProcMan: restart flag acknowledged\n");
            ack_seen = 1;
        }
        if (*kflag == 0) {
            *rf = 0;
            return 0;
        }
        for (volatile int d = 0; d < RECOVERY_POLL_DELAY; d++);
    }
    *rf = 0;
    printf("ProcMan: cooperative restart timed out\n");
    return -1;
}

#ifdef VERSE_TCB_ENFORCED
static void fault_endpoint_handler_stub(void)
{
    (void)VERSE_WORKER_FAULT_EP_CPTR;
    // STUB: requires native seL4 build environment with ProcMan receiving
    // TestWorker's fault endpoint cap. The real handler must seL4_Recv on
    // VERSE_WORKER_FAULT_EP_CPTR, decode the fault badge, suspend the worker,
    // and decide whether the same recovery path as heartbeat loss should run.
}

static int suspend_worker_tcb(void)
{
    seL4_CPtr worker_tcb = VERSE_WORKER_TCB_CPTR;
    int err = seL4_TCB_Suspend(worker_tcb);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_TCB_Suspend failed (%d)\n", err);
        return -1;
    }
    printf("ProcMan: seL4_TCB_Suspend(worker_tcb) OK\n");
    return 0;
}

static int rebuild_worker_tcb(void)
{
    /*
     * Cap contract, matching src/capdl/verse_tcb_handoff.cdl:
     * - 0x102 VERSE_PROCMAN_CNODE_CPTR: ProcMan CNode cap, destination root.
     * - 0x103 VERSE_WORKER_TCB_UNTYPED_CPTR: untyped for one fresh TCB.
     * - 0x104 VERSE_FRESH_WORKER_TCB_CPTR: empty destination slot for Retype.
     * - 0x105 VERSE_WORKER_CSPACE_CPTR: worker CSpace root.
     * - 0x106 VERSE_WORKER_VSPACE_CPTR: worker VSpace root.
     * - 0x107 VERSE_WORKER_IPC_BUFFER_CPTR: mapped worker IPC buffer frame.
     * - 0x108 VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR: worker fault endpoint.
     *
     * STUB: requires native seL4 build environment. The syscall sequence is
     * real, but the current Docker CAmkES build does not provide these caps or
     * the worker entry/stack addresses.
     */
    if (VERSE_WORKER_IPC_BUFFER_ADDR == 0 ||
        VERSE_WORKER_ENTRY_IP == 0 ||
        VERSE_WORKER_STACK_TOP == 0) {
        printf("ProcMan: TCB rebuild metadata missing; configure IPC addr, entry IP, and stack top\n");
        return -1;
    }

    int err = seL4_Untyped_Retype(VERSE_WORKER_TCB_UNTYPED_CPTR,
                                  seL4_TCBObject,
                                  seL4_TCBBits,
                                  VERSE_PROCMAN_CNODE_CPTR,
                                  VERSE_CNODE_DEST_INDEX,
                                  VERSE_CNODE_DEST_DEPTH,
                                  VERSE_FRESH_WORKER_TCB_CPTR,
                                  1);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_Untyped_Retype(TCB) failed (%d)\n", err);
        return -1;
    }

    seL4_Word cspace_data =
        seL4_CNode_CapData_new(0, VERSE_WORKER_CSPACE_GUARD_BITS).words[0];

#ifdef CONFIG_KERNEL_MCS
    err = seL4_TCB_Configure(VERSE_FRESH_WORKER_TCB_CPTR,
                             VERSE_WORKER_CSPACE_CPTR, cspace_data,
                             VERSE_WORKER_VSPACE_CPTR, VERSE_WORKER_VSPACE_ROOT_DATA,
                             VERSE_WORKER_IPC_BUFFER_ADDR,
                             VERSE_WORKER_IPC_BUFFER_CPTR);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_TCB_Configure failed (%d)\n", err);
        return -1;
    }

    err = seL4_TCB_SetSchedParams(VERSE_FRESH_WORKER_TCB_CPTR,
                                  VERSE_SCHED_AUTH_TCB_CPTR,
                                  VERSE_WORKER_MAX_PRIORITY,
                                  VERSE_WORKER_PRIORITY,
                                  VERSE_WORKER_SCHED_CONTEXT_CPTR,
                                  VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_TCB_SetSchedParams failed (%d)\n", err);
        return -1;
    }
#else
    err = seL4_TCB_Configure(VERSE_FRESH_WORKER_TCB_CPTR,
                             VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR,
                             VERSE_WORKER_CSPACE_CPTR, cspace_data,
                             VERSE_WORKER_VSPACE_CPTR, VERSE_WORKER_VSPACE_ROOT_DATA,
                             VERSE_WORKER_IPC_BUFFER_ADDR,
                             VERSE_WORKER_IPC_BUFFER_CPTR);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_TCB_Configure failed (%d)\n", err);
        return -1;
    }
#endif

    seL4_UserContext regs = {0};
#if defined(__x86_64__)
    regs.rip = VERSE_WORKER_ENTRY_IP;
    regs.rsp = VERSE_WORKER_STACK_TOP;
    regs.rflags = 0x202;
#else
    printf("ProcMan: unsupported architecture for worker register setup\n");
    return -1;
#endif

    err = seL4_TCB_WriteRegisters(VERSE_FRESH_WORKER_TCB_CPTR,
                                  false,
                                  0,
                                  sizeof(regs) / sizeof(seL4_Word),
                                  &regs);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_TCB_WriteRegisters failed (%d)\n", err);
        return -1;
    }

    err = seL4_TCB_Resume(VERSE_FRESH_WORKER_TCB_CPTR);
    if (err != seL4_NoError) {
        printf("ProcMan: seL4_TCB_Resume failed (%d)\n", err);
        return -1;
    }

    printf("ProcMan: fresh TestWorker TCB configured and resumed\n");
    return 0;
}

static int enforced_restart_worker(int attempt)
{
    printf("ProcMan: enforced TCB restart attempt %d/%d\n", attempt, MAX_RESTARTS);
    fault_endpoint_handler_stub();
    if (suspend_worker_tcb() != 0) {
        return -1;
    }
    if (rebuild_worker_tcb() != 0) {
        printf("ProcMan: enforced rebuild failed after suspend; quarantine required\n");
        return -2;
    }
    return 0;
}
#endif

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
#ifdef VERSE_TCB_ENFORCED
        int enforced_result = enforced_restart_worker(restarts);
        if (enforced_result == -1) {
            printf("ProcMan: enforced path unavailable, falling back to cooperative restart\n");
            if (cooperative_restart(rf, kflag) != 0) {
                continue;
            }
        } else if (enforced_result != 0) {
            printf("ProcMan: enforced path failed after taking TCB authority - quarantining\n");
            *rf=0;
            while(1){ for(volatile int d=0;d<1000000;d++); }
        }
#else
        if (cooperative_restart(rf, kflag) != 0) {
            continue;
        }
#endif
        printf("ProcMan: restart done\n");
        while(*kflag==1){ for(volatile int d=0;d<500000;d++); }
    }
}
