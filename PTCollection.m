//
//  PTCollection.m
//  Showtime
//
//  Created by Yaogang Lian on 3/8/13.
//  Copyright (c) 2013 HappenApps, Inc. All rights reserved.
//

#import "PTCollection.h"
#import "PTClient.h"
#import "PTModel.h"
#import "NSDictionary+HAUtils.h"

@implementation PTCollection

@synthesize modelClass, models;

#pragma mark - Initialization

- (id)initWithOptions:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        models = [NSMutableArray array];
        if (options[@"model"]) {
            modelClass = NSClassFromString(options[@"model"]);
        }
    }
    return self;
}

- (NSInteger)count
{
    return models.count;
}

- (id)at:(NSUInteger)index
{
    if (index < [models count]) {
        return [models objectAtIndex:index];
    } else {
        return nil;
    }
}


#pragma mark - Custom events

- (void)trigger:(NSString *)eventType
{
    [[NSNotificationCenter defaultCenter] postNotificationName:eventType object:self];
}

- (void)trigger:(NSString *)eventType withOptions:(NSDictionary *)options
{
    [[NSNotificationCenter defaultCenter] postNotificationName:eventType object:self userInfo:options];
}

- (void)on:(NSString *)eventType target:(id)target selector:(SEL)callback
{
    [[NSNotificationCenter defaultCenter] addObserver:target selector:callback name:eventType object:self];
}


#pragma mark - Backbone style sync

- (NSString *)urlRoot
{
    // Subclass should override this.
    return @"";
}


// GET /models
- (void)fetch
{
    [self fetchWithPath:nil parameters:nil success:nil error:nil];
}

- (void)fetch:(NSDictionary *)options
{
    [self fetchWithPath:options[@"path"]
             parameters:options[@"params"]
                success:options[@"success"]
                  error:options[@"error"]];
}

- (void)fetchWithPath:(NSString *)path
           parameters:(NSDictionary *)parameters
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSArray *models))successCallback
                error:(void (^)(AFHTTPRequestOperation *operation, NSError *error))errorCallback
{
    AFHTTPClient * httpClient = [PTClient httpClient];
    NSString * fetchPath = path ? path : [self urlRoot];

    [httpClient getPath:fetchPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id JSON) {
        // Reset the models array
        [models removeAllObjects];

        // Parse the new models
        NSArray * collection = (NSArray *)JSON;
        for (NSDictionary * item in collection) {
            PTModel * model = [[self modelClass] findOrCreateById:NOTNULL([item valueForKey:@"id"])];
            [model parse:item];
            [models addObject:model];
        }

        // Purge from local datastore the models that no longer exist on the server
        NSArray * ids = [collection valueForKey:@"id"];
        [[self modelClass] deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"NOT (sid IN %@)", ids]];

        // Trigger success callback
        if (successCallback) successCallback(operation, JSON, models);

        // Save the changes
        if ([[NSManagedObjectContext defaultContext] hasChanges]) {
            [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                // Trigger a "reset" event
                [self trigger:@"reset"];
            }];
        } else {
            // Trigger an "unchanged" event
            [self trigger:@"unchanged"];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Trigger error callback
        if (errorCallback) errorCallback(operation, error);

        DDLogError(@"Failed to load collection with error: %@", error);

        // Trigger an "error" event
        [self trigger:@"error"];
    }];
}

// POST /models
- (id)create
{
    PTModel * model = [[self modelClass] createEntity];
    [model save];
    return model;
}

- (id)create:(NSDictionary *)options
{
    PTModel * model = [[self modelClass] createEntity];
    [model save:options];
    return model;
}

@end
