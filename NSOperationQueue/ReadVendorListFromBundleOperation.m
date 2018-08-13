//
//  ReadVendorListFromBundleOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/10/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "ReadVendorListFromBundleOperation.h"

@interface ReadVendorListFromBundleOperation()
// 'executing' and 'finished' exist in NSOperation, but are readonly
@property (atomic, assign) BOOL _cancelled;
@property (atomic, assign) BOOL _executing;
@property (atomic, assign) BOOL _finished;
@end

@implementation ReadVendorListFromBundleOperation

- (void) start
{
    NSLog(@"%s", __FUNCTION__);
    if ([self isCancelled])
    {
        // Move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        self._finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    self._executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
}

// If you are implementing a concurrent operation, you are not required to
// override this method but may do so if you plan to call it from your custom start method.
- (void)main
{
    NSLog(@"%s", __FUNCTION__);
    if ([self isCancelled]) {
        return;
    }
    [self readVendorList];
}

- (void)readVendorList
{
    NSLog(@"%s", __FUNCTION__);
    NSBundle* mainBundle = NSBundle.mainBundle;
    NSString* vendorListStr = @"Resources.bundle/vendorlist.json";
    NSString* vendorListPath = [mainBundle pathForResource:[vendorListStr stringByDeletingPathExtension] ofType:vendorListStr.pathExtension];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [NSURL URLWithString:vendorListPath];
    
    if(![fileManager fileExistsAtPath:documentsURL.path]) {
        [self cancel];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData* data = [NSData dataWithContentsOfFile:vendorListPath];
        NSError* serializationError;
        NSDictionary* vendorList = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&serializationError];
        if (!vendorList) {
            [self cancel];
            return;
        }
        NSLog(@"%@: finished reading Vendorlist from bundle -> posting notification!", self.class);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReadVendorListFromBundle" object:nil userInfo:@{@"vendorList" : vendorList}];
        [self completeOperation];
    });
}

- (void)cancel
{
    NSLog(@"%s", __FUNCTION__);
    [self willChangeValueForKey:@"isCancelled"];
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    self._cancelled = YES;
    self._executing = NO;
    self._finished  = YES;
    
    [self didChangeValueForKey:@"isCancelled"];
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isAsynchronous
{
    NSLog(@"%s: %@", __FUNCTION__, @"YES");
    return YES;
}

#define b2str(b) b ? @"YES" : @"NO"
- (BOOL)isCancelled
{
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._cancelled));
    return self._cancelled;
}

- (BOOL)isExecuting {
    return self._executing;
}

- (BOOL)isFinished {
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._finished));
    return self._finished;
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    self._executing = NO;
    self._finished  = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
