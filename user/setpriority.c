#include "../kernel/types.h"
#include "../kernel/param.h"
#include "../kernel/stat.h"
#include "./user.h"

int main(int argc, char *argv[])
{

    if (argc < 3)
    {
        fprintf(2, "Wrong number of arguments provided !\n");
        fprintf(2, "Usage: setpriority <priority> <pid>\n");
        exit(1);
    }

    int priority = atoi(argv[1]);
    int pid = atoi(argv[2]);

    if (priority < 0 || priority > 100)
    {
        fprintf(2, "Incorrect Range !\n");
        fprintf(2, "Correct Range: [0,100]\n");
        exit(1);
    }
    else
    {
        setpriority(priority, pid);
        exit(1);
    }
}