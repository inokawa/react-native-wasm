#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Wasm, RCTEventEmitter)

RCT_EXTERN_METHOD(instantiate:(NSString *)bytes resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(call:(NSString *)name arguments:(NSString *)args)

@end
