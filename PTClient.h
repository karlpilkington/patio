//
//  PTClient.h
//  Patio
//
//  Created by Yaogang Lian on 5/17/13.
//  Copyright (c) 2013 HappenApps, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface PTClient : NSObject

// Default http client
+ (AFHTTPClient *)httpClient;

@end
