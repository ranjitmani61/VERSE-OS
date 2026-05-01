#include <camkes.h>
#include <stdio.h>

int run(void) {
    printf("SECRET: calling\n");
    h_say_hello();
    printf("SECRET: done\n");
    return 0;
}
