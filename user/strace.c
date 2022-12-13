#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// Assignment 4

int
main(int argc, char *argv[])
{
  if(argc < 3){
    fprintf(2, "Usage: strace <mask> <command>\n");
    exit(1);
  }
  int num_flag = 1;
  for (int i = 0; argv[1][i] != '\0'; i++) {
    if (argv[1][i] < '0' || argv[1][i] > '9') {
      num_flag = 0;
    }
  }
  if (num_flag == 0) {
    fprintf(2, "Usage: strace <mask> <command>\n");
    fprintf(2, "The mask must be a number\n");
    exit(1);
  }
  char *command[32];                                 // MAXARG for xv6
  for (int i = 2; i < argc; i++) {
    if (i == 32) {
      break;
    }
    command[i - 2] = argv[i];
  }
  int mask = atoi(argv[1]);
  if (trace(mask) < 0) {
    fprintf(2, "trace failed\n");
    exit(1);
  }
  exec(command[0], command);
  exit(0);
}