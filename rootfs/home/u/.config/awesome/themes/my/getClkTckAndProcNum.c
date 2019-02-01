#include <stdio.h>
#include <unistd.h>
#include <sys/sysinfo.h>

int main()
{
    fprintf(stdout, "%ld %d", sysconf(_SC_CLK_TCK), get_nprocs());
    return 0;
}
