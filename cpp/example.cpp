#include "example.h"

using namespace facebook;

namespace example
{

  void setup(jsi::Runtime &jsiRuntime)
  {
    auto fn = jsi::Function::createFromHostFunction(
        jsiRuntime,
        jsi::PropNameID::forAscii(jsiRuntime, "example"),
        1,
        [](jsi::Runtime &runtime, const jsi::Value &thisValue, const jsi::Value *arguments, size_t count) -> jsi::Value
        {
          if (!arguments[0].isNumber() || !arguments[1].isNumber())
          {
            jsi::detail::throwJSError(runtime, "Non number arguments passed");
          }

          double res = arguments[0].asNumber() * arguments[1].asNumber();
          return jsi::Value(res);
        });

    jsiRuntime.global().setProperty(jsiRuntime, "example", std::move(fn));
  }

  void cleanUp()
  {
    // NOP
  }
}
