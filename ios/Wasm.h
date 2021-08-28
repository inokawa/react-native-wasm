#import <React/RCTBridgeModule.h>
#import "example.h"

@interface Wasm : NSObject <RCTBridgeModule>

@property (nonatomic, assign) BOOL setBridgeOnMainQueue;

@end
