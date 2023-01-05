
#include <stdio.h>
#include <malloc.h>

int main() {
  void *p = malloc(16);
  printf("%p\n", p);
  free(p);
  return 0;
}