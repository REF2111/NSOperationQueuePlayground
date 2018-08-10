//
//  DownloadPurposeListOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/10/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "DownloadPurposeListOperation.h"

#import "DownloadVendorListOperation.h"

@interface DownloadPurposeListOperation()
// 'executing' and 'finished' exist in NSOperation, but are readonly
@property (atomic, assign) BOOL _executing;
@property (atomic, assign) BOOL _finished;
@property NSUInteger vendorListVersion;
@property NSURL* URL;
@end

@implementation DownloadPurposeListOperation

- (void) start;
{
    for (NSOperation* operation in self.dependencies) {
        if (operation.isCancelled) {
            [self cancel];
            return;
        }
    }
    
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
    DownloadVendorListOperation* downloadVendorList;
    for (NSOperation* operation in self.dependencies) {
        if ([operation isKindOfClass:[DownloadVendorListOperation class]]) {
            downloadVendorList = (DownloadVendorListOperation*)operation;
        }
    }
    self.vendorListVersion = downloadVendorList.vendorListVersion;
    if (!self.vendorListVersion || [[[NSLocale currentLocale] languageCode] isEqualToString:@"en"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PurposeListDownloadNotNecessary" object:nil userInfo:nil];
        [self cancel];
        return;
    }
    [self updateURL];
    [self download];
}

- (void)updateURL
{
    NSString* languageCode = [[NSLocale currentLocale] languageCode];
    self.URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://vendorlist.consensu.org/v-%lu/purposes-%@.json", self.vendorListVersion, languageCode]];
}

- (void)download
{
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:self.URL];
    req.timeoutInterval = 3;
    NSURLSession* dlSession = NSURLSession.sharedSession;
    NSURLSessionTask* task = [dlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PurposeListDownloadFailed" object:nil userInfo:nil];
            [self cancel];
            return;
        }
        NSError* serializationError;
        NSDictionary* purposeList = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&serializationError];
        if (!purposeList) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PurposeListDownloadFailed" object:nil userInfo:nil];
            [self cancel];
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidDownloadPurposeList" object:nil userInfo:@{@"purposeList" : purposeList}];
        [self completeOperation];
    }];
    
    [task resume];
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
