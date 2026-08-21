// Deliberately requires -fPIC to end up in a shared library.
int greet_count = 0;

int greet(int x) {
  greet_count += 1;
  return x + greet_count;
}
