//
//  PTCollection.h
//  Showtime
//
//  Created by Yaogang Lian on 3/8/13.
//  Copyright (c) 2013 HappenApps, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PTCollection : NSObject

@property (nonatomic, retain) id modelClass;
@property (nonatomic, retain) NSMutableArray * models;

// Basics
- (id)initWithOptions:(NSDictionary *)options;
- (NSInteger)count;
- (id)at:(NSUInteger)index;

// Custom Events
- (void)trigger:(NSString *)eventType;
- (void)trigger:(NSString *)eventType withOptions:(NSDictionary *)options;
- (void)on:(NSString *)eventType target:(id)target selector:(SEL)callback;

// Backbone style sync
- (NSString *)urlRoot;

- (void)fetch;
- (void)fetch:(NSDictionary *)options;

- (id)create;
- (id)create:(NSDictionary *)options;

@end
