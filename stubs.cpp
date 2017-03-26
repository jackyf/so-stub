#include <stdexcept>
extern "C" {

void exception_thrower() __attribute__ ((weak));

#define MESSAGE "real dynamic library " LNAME " not available"

void exception_thrower() {
	throw std::runtime_error(MESSAGE);
}

}

