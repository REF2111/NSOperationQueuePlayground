//
//  DownloadVendorListOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/10/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "DownloadVendorListOperation.h"

@interface DownloadVendorListOperation()
// 'executing' and 'finished' exist in NSOperation, but are readonly
@property (atomic, assign) BOOL _cancelled;
@property (atomic, assign) BOOL _executing;
@property (atomic, assign) BOOL _finished;
@end

@implementation DownloadVendorListOperation

- (void)start
{
    NSLog(@"%s", __FUNCTION__);
    for (NSOperation* operation in self.dependencies) {
        if (operation.isCancelled) {
            [self cancel];
            return;
        }
    }
    
    if (self.isCancelled) {
        [self cancel];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    // WTF is this?
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    self._executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self download];
}

//If you are implementing a concurrent operation, you are not required to override
// this method but may do so if you plan to call it from your custom start method.
//- (void) main;
//{
//    NSLog(@"%s", __FUNCTION__);
//    if ([self isCancelled]) {
//        return;
//    }
//    [self download];
//}

- (void)download
{
    NSLog(@"%s", __FUNCTION__);
    NSURL* URL = [NSURL URLWithString:@"https://vendorlist.consensu.org/vendorlist.json"];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:URL];
    req.timeoutInterval = 3;
    NSURLSession* dlSession = NSURLSession.sharedSession;
    NSURLSessionTask* task = [dlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"VendorListDownloadFailed" object:nil userInfo:nil];
            [self cancel];
            return;
        }
        NSError* serializationError;
        NSDictionary* vendorList = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&serializationError];
        if (!vendorList) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"VendorListDownloadFailed" object:nil userInfo:nil];
            [self cancel];
            return;
        }
        
        self.vendorListVersion = [self vendorListVersion:vendorList];
        NSLog(@"%@: finished downloading vendor list -> posting notification", self.class);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidDownloadVendorList" object:nil userInfo:@{@"vendorList" : vendorList}];
        [self completeOperation];
    }];
    
    [task resume];
}

- (NSUInteger)vendorListVersion:(nonnull NSDictionary*)vendorList
{
    NSLog(@"%s", __FUNCTION__);
    NSUInteger vendorListVersion = [[vendorList objectForKey:@"vendorListVersion"] intValue];
    return vendorListVersion;
}

- (void)cancel
{
    NSLog(@"%s", __FUNCTION__);
    [self willChangeValueForKey:@"isCancelled"];
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    self._cancelled = YES;
    self._executing = NO;
    self._finished = YES;
    
    [self didChangeValueForKey:@"isCancelled"];
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isAsynchronous;
{
    NSLog(@"%s: YES", __FUNCTION__);
    return YES;
}
#define b2str(b) b ? @"YES" : @"NO"
- (BOOL)isCancelled
{
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._cancelled));
    return self._cancelled;
}

- (BOOL)isExecuting
{
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._executing));
    return self._executing;
}

- (BOOL)isFinished
{
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._finished));
    return self._finished;
}

- (void)completeOperation
{
    NSLog(@"%s", __FUNCTION__);
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    self._executing = NO;
    self._finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
