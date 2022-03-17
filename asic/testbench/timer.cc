#include <svdpi.h>
#include <time.h>

struct timespec start, stop;

extern "C" void timer_start() {
    clock_gettime( CLOCK_REALTIME, &start);
}

extern "C" long int timer_stop() {
    clock_gettime( CLOCK_REALTIME, &stop);
    return (stop.tv_sec - start.tv_sec) * 1000000000L + ( stop.tv_nsec - start.tv_nsec );
}