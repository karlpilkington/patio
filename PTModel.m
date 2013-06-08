//
//  PTModel.m
//  Showtime
//
//  Created by Yaogang Lian on 3/8/13.
//  Copyright (c) 2013 HappenApps, Inc. All rights reserved.
//

#import "PTModel.h"
#import "PTClient.h"
#import "NSDictionary+HAUtils.h"

@implementation PTModel

@dynamic sid, created, updated;


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

// Specify a urlRoot if you're using a model outside of a collection.
- (NSString *)urlRoot
{
    return @"";
}

- (NSString *)url
{
    return [NSString stringWithFormat:@"%@/%@", [self urlRoot], self.sid];
}

- (void)parse:(NSDictionary *)dict
{
    // Override in subclasses.
}

- (NSDictionary *)toJSON
{
    return @{
             @"id": NOTNIL(self.sid),
             @"created": NOTNIL(self.created),
             @"updated": NOTNIL(self.updated)
             };
}


// GET /models/{id}
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
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCallback
                error:(void (^)(AFHTTPRequestOperation *operation, NSError *error))errorCallback
{
    AFHTTPClient * httpClient = [PTClient httpClient];
    NSString * requestPath = path ? path : [self url];

    [httpClient getPath:requestPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self parse:(NSDictionary *)responseObject];

        // Trigger success callback
        if (successCallback) successCallback(operation, responseObject);

        // Save the changes
        if ([[NSManagedObjectContext defaultContext] hasChanges]) {
            [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                // Trigger a change event
                [self trigger:@"change"];
            }];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Trigger error callback
        if (errorCallback) errorCallback(operation, error);

        DDLogError(@"Failed to load model with error: %@", error);

        // Trigger an "error" event
        [self trigger:@"error"];
    }];
}


// POST /models or PUT /models/{id}
- (void)save
{
    [self saveWithPath:nil parameters:nil success:nil error:nil];
}

- (void)save:(NSDictionary *)options
{
    [self saveWithPath:options[@"path"]
            parameters:options[@"params"]
               success:options[@"success"]
                 error:options[@"error"]];
}

- (void)saveWithPath:(NSString *)path
          parameters:(NSDictionary *)parameters
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCallback
               error:(void (^)(AFHTTPRequestOperation *operation, NSError *error))errorCallback
{
    AFHTTPClient * httpClient = [PTClient httpClient];
    NSDictionary * merged = [[self toJSON] mergeWithDict:parameters];

    if (parameters != nil) {
        // Calling save with new attributes will cause a "change" event immediately
        [self trigger:@"change"];
    }

    if (self.sid != nil) {
        NSString * requestPath = path ? path : [self url];
        [httpClient putPath:requestPath parameters:merged success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self parse:(NSDictionary *)responseObject];

            // Trigger success callback
            if (successCallback) successCallback(operation, responseObject);

            // Save the changes
            if ([[NSManagedObjectContext defaultContext] hasChanges]) {
                [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    // Trigger a sync event
                    [self trigger:@"sync"];
                }];
            }

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Trigger error callback
            if (errorCallback) errorCallback(operation, error);

            DDLogError(@"Failed to create model with error: %@", error);

            // Trigger an "error" event
            [self trigger:@"error"];
        }];
    } else {
        NSString * requestPath = path ? path : [self urlRoot];
        [httpClient postPath:requestPath parameters:merged success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self parse:(NSDictionary *)responseObject];

            // Trigger success callback
            if (successCallback) successCallback(operation, responseObject);

            // Save the changes
            if ([[NSManagedObjectContext defaultContext] hasChanges]) {
                [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    // Trigger a change event
                    [self trigger:@"sync"];
                }];
            }

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // Trigger error callback
            if (errorCallback) errorCallback(operation, error);

            DDLogError(@"Failed to create model with error: %@", error);

            // Trigger an "error" event
            [self trigger:@"error"];
        }];
    }
}


// DELETE /models/{id}
- (void)destroy
{
    [self destroyWithPath:nil parameters:nil success:nil error:nil];
}

- (void)destroy:(NSDictionary *)options
{
    [self destroyWithPath:options[@"path"]
               parameters:options[@"params"]
                  success:options[@"success"]
                    error:options[@"error"]];
}

- (void)destroyWithPath:(NSString *)path
             parameters:(NSDictionary *)parameters
                success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCallback
                  error:(void (^)(AFHTTPRequestOperation *operation, NSError *error))errorCallback
{
    AFHTTPClient * httpClient = [PTClient httpClient];
    NSString * requestPath = path ? path : [self url];

    [httpClient deletePath:requestPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self deleteInContext:[NSManagedObjectContext defaultContext]];

        // Trigger success callback
        if (successCallback) successCallback(operation, responseObject);

        // Save the changes
        if ([[NSManagedObjectContext defaultContext] hasChanges]) {
            [[NSManagedObjectContext defaultContext] saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                // Trigger a remove event
                [self trigger:@"destroy"];
            }];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Trigger error callback
        if (errorCallback) errorCallback(operation, error);

        DDLogError(@"Failed to create model with error: %@", error);

        // Trigger an "error" event
        [self trigger:@"error"];
    }];
}


#pragma mark - CoreData convenience methods

+ (NSArray *)findAll
{
    return [[self class] findAllSortedBy:@"sid" ascending:YES];
}

+ (id)findById:(NSNumber *)n
{
    return [[self class] findFirstByAttribute:@"sid" withValue:n];
}

+ (id)findOrCreateById:(NSNumber *)n
{
    id entity = [[self class] findFirstByAttribute:@"sid" withValue:n];
    if (entity == nil) {
        entity = [[self class] createEntity];
        [entity setValue:n forKey:@"sid"];
    }
    return entity;
}

@end
