#include <stdexcept>
extern "C" {

void exception_thrower() __attribute__ ((weak));

void exception_thrower() {
	throw std::runtime_error("abc");
}

}

