#include <camkes.h>
#include <camkes/dataport.h>
int run(void){ volatile unsigned long *c=(volatile unsigned long*)shared; *c=0; while(1){(*c)++;} return 0; }
