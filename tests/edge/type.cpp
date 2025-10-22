// Complex type combinations
const volatile int cv_int;
static const int sc_int;
unsigned long long ull_val;

// Type aliases (should be handled by IDENTIFIER in type)
typedef int MyInt;
using MyFloat = float;

// Template-like syntax (even without full template support)
std::vector<int> vec;       // Template type