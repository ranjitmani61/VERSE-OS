#include <camkes.h>
#include <camkes/dataport.h>

static void lw(const char *m) {
    volatile unsigned *h = (volatile unsigned *)logbuf;
    char *d = (char *)logbuf + 8;
    unsigned x = *h;
    int n;
    for (n = 0; m[n] && n < 100; n++);
    for (int i = 0; i < n; i++) {
        d[x] = m[i];
        x = (x + 1) % 4088;
    }
    *h = x;
}

int run(void) {
    volatile unsigned long *a = (volatile unsigned long *)workerA_buf;
    volatile unsigned long *b = (volatile unsigned long *)workerB_buf;
    int warn_count = 0;
    int ok_count = 0;
    int warned = 0;
    int previous_severity = -1;

    lw("DHARMA: standalone hysteresis\n");
    while (1) {
        for (volatile int i = 0; i < 5000000; i++);
        unsigned long ta = *a;
        unsigned long tb = *b;
        *a = 0;
        *b = 0;
        unsigned long total = ta + tb;
        if (!total) {
            continue;
        }

        int percent_a = (int)(ta * 100 / total);
        if (!warned) {
            if (percent_a > 55) {
                warn_count++;
                if (warn_count >= 3) {
                    warned = 1;
                    warn_count = 0;
                    ok_count = 0;
                }
            } else {
                warn_count = 0;
            }
        } else {
            if (percent_a < 45) {
                ok_count++;
                if (ok_count >= 3) {
                    warned = 0;
                    ok_count = 0;
                    warn_count = 0;
                }
            } else {
                ok_count = 0;
            }
        }

        int severity = warned ? 1 : 0;

        if (severity != previous_severity) {
            if (severity == 0) {
                lw("DHARMA: OK\n");
            } else if (severity == 1) {
                lw("DHARMA: WARN\n");
            } else {
                lw("DHARMA: CRIT\n");
            }
            previous_severity = severity;
        }
    }
    return 0;
}
