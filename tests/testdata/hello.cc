// Exercises the sysroot's libstdc++ headers and libraries, which the C sources
// in this directory never reach.
#include <iostream>
#include <string>
#include <vector>

int main() {
  const std::vector<std::string> words = {"hello", "from", "c++"};
  std::string greeting;
  for (const std::string& word : words) {
    if (!greeting.empty()) {
      greeting += " ";
    }
    greeting += word;
  }
  std::cout << greeting << std::endl;
  return 0;
}
