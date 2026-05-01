#include <camkes.h>
#include <stdio.h>

int run(void) {
    printf("PUBLIC: calling\n");
    h_say_hello();
    printf("PUBLIC: done\n");
    return 0;
}
