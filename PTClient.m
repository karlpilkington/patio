//
//  PTClient.m
//  Showtime
//
//  Created by Yaogang Lian on 5/17/13.
//  Copyright (c) 2013 HappenApps, Inc. All rights reserved.
//

#import "PTClient.h"

@implementation PTClient

static AFHTTPClient * _httpClient;

+ (AFHTTPClient *)httpClient
{
    if (_httpClient == nil) {
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:API_BASE_URL]];
        [_httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];

        // Accept HTTP header
        [_httpClient setDefaultHeader:@"Accept" value:@"application/json"];

        // Force GAE to compress the content by setting both "Accept-Encoding" and "User-Agent" to "gzip".
        [_httpClient setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
        [_httpClient setDefaultHeader:@"User-Agent" value:@"gzip"];

        // Set parameter encoding to JSON
        [_httpClient setParameterEncoding:AFJSONParameterEncoding];
    }
    return _httpClient;
}

@end
