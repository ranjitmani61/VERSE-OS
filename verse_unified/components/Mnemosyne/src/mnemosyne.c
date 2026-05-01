#include <camkes.h>
#include <camkes/dataport.h>

static void log_write(const char *msg)
{
    volatile unsigned *head = (volatile unsigned *)logbuf;
    char *data = (char *)logbuf + 8;
    unsigned pos = *head;
    int len = 0;

    while (msg[len] && len < 80) {
        len++;
    }
    for (int i = 0; i < len; i++) {
        data[pos] = msg[i];
        pos = (pos + 1) % 4088;
    }
    *head = pos;
}

int run(void)
{
    log_write("MNEMOSYNE: scaffold ready\n");
    return 0;
}

