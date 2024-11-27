//
//  GetNetPrintersMethodCall.m
//  another_brother
//
//  Created by admin on 4/16/21.
//

#import <Foundation/Foundation.h>
#import "GetNetPrintersMethodCall.h"

@interface GetNetPrintersMethodCall() <BRPtouchNetworkDelegate>
@property (nonatomic, strong) BRPtouchNetworkManager *networkManager;
@end

@implementation GetNetPrintersMethodCall

static NSString * METHOD_NAME = @"getNetPrinters";

- (instancetype)initWithCall:(FlutterMethodCall *)call
                      result:(FlutterResult) result {
    self = [super init];
    if (self) {
        _call = call;
        _result = result;
        _foundPrinters = [[NSMutableArray<BRPtouchDeviceInfo *> alloc] init];
    }
    return self;
}

+ (NSString *) METHOD_NAME {
    return METHOD_NAME;
}
- (void)execute {
    NSArray * printerModels = _call.arguments[@"models"];
    if (!printerModels) {
        _result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                  message:@"Printer models array is required"
                                  details:nil]);
        return;
    }
    
    _networkManager = [[BRPtouchNetworkManager alloc] initWithPrinterNames:printerModels];
    if (!_networkManager) {
        _result([FlutterError errorWithCode:@"INITIALIZATION_ERROR"
                                  message:@"Failed to initialize network manager"
                                  details:nil]);
        return;
    }
    
    _networkManager.delegate = self;
    [_networkManager setIsEnableIPv6Search:false];
    [_networkManager startSearch:2];
}

- (void)didFindDevice:(BRPtouchDeviceInfo *)deviceInfo {
    if (deviceInfo) {
        [_foundPrinters addObject:deviceInfo];
    }
}

- (void)didFinishSearch:(id)sender {
    // Get found printer list. Array of BRPtouchDeviceInfo
    NSArray<BRPtouchDeviceInfo *> * scanResults = [_networkManager getPrinterNetInfo];
    
    // Map the paths into Dart Net Printers
    NSMutableArray<NSDictionary<NSString *, NSObject*> *> * dartNetPrinters = [NSMutableArray arrayWithCapacity:[scanResults count]];
    [scanResults enumerateObjectsUsingBlock:^(id printerInfo, NSUInteger idx, BOOL *stop) {
        id mapObj = [BrotherUtils bRPtouchDeviceInfoToNetPrinterMap:printerInfo];
        [dartNetPrinters addObject:mapObj];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _result(dartNetPrinters);
    });
    
    _networkManager.delegate = nil;
    _networkManager = nil;
}

- (void)dealloc {
    _networkManager.delegate = nil;
    _networkManager = nil;
}

@end
