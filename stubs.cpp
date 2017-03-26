#include <stdexcept>
extern "C" {

#define MESSAGE "real dynamic library " LNAME " not available"

void FNAME () {
	throw std::runtime_error(MESSAGE);
}

}

