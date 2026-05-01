#include <camkes.h>
#include <stdio.h>

#define LABEL_PUBLIC 0
#define LABEL_SECRET 2
#define LABEL_SERVER 0

static int label_allowed(int src, int dst) { return src <= dst; }

void public_h_say_hello(void) {
    if (label_allowed(LABEL_PUBLIC, LABEL_SERVER)) {
        printf("SENTINEL: FORWARD public(0)->server(0) ALLOWED\n");
        server_h_say_hello();
    } else {
        printf("SENTINEL: BLOCK public(0)->server(0)\n");
    }
}

void secret_h_say_hello(void) {
    if (label_allowed(LABEL_SECRET, LABEL_SERVER)) {
        printf("SENTINEL: FORWARD secret(2)->server(0)\n");
        server_h_say_hello();
    } else {
        printf("SENTINEL: BLOCK secret(2)->server(0) LATTICE VIOLATION\n");
    }
}
