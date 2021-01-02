#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Wasm, RCTEventEmitter)

RCT_EXTERN_METHOD(instantiate:(NSString *)modId bytesStr:(NSString *)bytes resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(call:(NSString *)modId funcName:(NSString *)name arguments:(NSString *)args)

@end
