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
@property (atomic, assign) BOOL _executing;
@property (atomic, assign) BOOL _finished;
@end

@implementation ReadVendorListFromBundleOperation

- (void) start;
{
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

- (void) main;
{
    if ([self isCancelled]) {
        return;
    }
    [self readVendorList];
}

- (void)readVendorList
{
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
        
        [self completeOperation];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReadVendorListFromBundle" object:nil];
    });
}

- (void)cancel
{
    [self willChangeValueForKey:@"isFinished"];
    self._finished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL) isAsynchronous;
{
    return YES;
}

- (BOOL)isExecuting {
    return self._executing;
}

- (BOOL)isFinished {
    return self._finished;
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    self._executing = NO;
    self._finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end






