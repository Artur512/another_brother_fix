//
//  GetNetPrintersMethodCall.m
//  another_brother
//
//  Created by admin on 4/16/21.
//

#import <Foundation/Foundation.h>
#import "GetNetPrintersMethodCall.h"

@implementation GetNetPrintersMethodCall {
    BOOL _isSearching;
}

static NSString * METHOD_NAME = @"getNetPrinters";

- (instancetype)initWithCall:(FlutterMethodCall *)call
                      result:(FlutterResult) result {
    self = [super init];
    if (self) {
        _call = call;
        _result = result;
        _foundPrinters = [[NSMutableArray<BRPtouchDeviceInfo *> alloc] init];
        _isSearching = NO;
    }
    return self;
}

+ (NSString *) METHOD_NAME {
    return METHOD_NAME;
}

- (void)execute {
    if (_isSearching) {
        _result([FlutterError errorWithCode:@"ALREADY_SEARCHING"
                                    message:@"A printer search is already in progress"
                                    details:nil]);
        return;
    }

    NSArray * printerModels = _call.arguments[@"models"];
    if (!printerModels || ![printerModels isKindOfClass:[NSArray class]]) {
        _result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                    message:@"Printer models array is required"
                                    details:nil]);
        return;
    }

    _netManager = [[BRPtouchNetworkManager alloc] initWithPrinterNames:printerModels];
    if (!_netManager) {
        _result([FlutterError errorWithCode:@"INITIALIZATION_ERROR"
                                    message:@"Failed to initialize network manager"
                                    details:nil]);
        return;
    }

    _isSearching = YES;

    [_netManager setDelegate:self];
    [_netManager setIsEnableIPv6Search:NO];

    BOOL started = [_netManager startSearch:2];
    if (!started) {
        _isSearching = NO;
        _result([FlutterError errorWithCode:@"SEARCH_FAILED"
                                    message:@"Failed to start printer search"
                                    details:nil]);
    }
}

- (void)didFindDevice:(BRPtouchDeviceInfo *)deviceInfo {
    if (deviceInfo) {
        [_foundPrinters addObject:deviceInfo];
    }
}

- (void)didFinishSearch:(id)sender {
    _isSearching = NO;

    NSArray<BRPtouchPrintInfo *> * scanResults = [_netManager getPrinterNetInfo];

    NSMutableArray<NSDictionary<NSString *, NSObject*> *> * dartNetPrinters = [NSMutableArray arrayWithCapacity:[scanResults count]];
    [scanResults enumerateObjectsUsingBlock:^(id printerInfo, NSUInteger idx, BOOL *stop) {
        id mapObj = [BrotherUtils bRPtouchDeviceInfoToNetPrinterMap:printerInfo];
        if (mapObj) {
            [dartNetPrinters addObject:mapObj];
        }
    }];

    _result(dartNetPrinters);
}
@end