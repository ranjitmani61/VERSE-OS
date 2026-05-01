#include <camkes.h>
#include <camkes/dataport.h>
int run(void){ volatile unsigned long *c=(volatile unsigned long*)shared; *c=0; while(1){(*c)++; for(volatile int i=0;i<800000;i++);} return 0; }
