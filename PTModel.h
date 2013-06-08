//
//  PTModel.h
//  Patio
//
//  Created by Yaogang Lian on 3/8/13.
//  Copyright (c) 2013 HappenApps, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface PTModel : NSManagedObject

@property (nonatomic, strong) NSNumber * sid;
@property (nonatomic, strong) NSDate * created;
@property (nonatomic, strong) NSDate * updated;

// Custom events
- (void)trigger:(NSString *)eventType;
- (void)trigger:(NSString *)eventType withOptions:(NSDictionary *)options;
- (void)on:(NSString *)eventType target:(id)target selector:(SEL)callback;

// Backbone-style sync
- (NSString *)urlRoot;
- (NSString *)url;
- (void)parse:(NSDictionary *)dict;
- (NSDictionary *)toJSON;

- (void)fetch;
- (void)fetch:(NSDictionary *)options;
- (void)save;
- (void)save:(NSDictionary *)options;
- (void)destroy;

// CoreData convenience methods
+ (NSArray *)findAll;
+ (id)findById:(NSNumber *)n;
+ (id)findOrCreateById:(NSNumber *)n;

@end
