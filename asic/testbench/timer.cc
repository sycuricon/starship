#include <svdpi.h>
#include <time.h>
#include <stdio.h>

struct timespec start, stop;

extern "C" void timer_start() {
    clock_gettime(CLOCK_REALTIME, &start);
}

extern "C" long int timer_stop() {
    clock_gettime(CLOCK_REALTIME, &stop);
    // printf("[timer(s)]: %ld %ld %ld\n", stop.tv_sec, start.tv_sec, stop.tv_sec - start.tv_sec);
    // printf("[timer(ns)]: %ld %ld %ld\n", stop.tv_nsec, start.tv_nsec, stop.tv_nsec - start.tv_nsec);
    return (stop.tv_sec - start.tv_sec) * 1000000000L + ( stop.tv_nsec - start.tv_nsec );
}