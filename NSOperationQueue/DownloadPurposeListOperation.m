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
@property (atomic, assign) BOOL _cancelled;
@property (atomic, assign) BOOL _executing;
@property (atomic, assign) BOOL _finished;
@property NSUInteger vendorListVersion;
@property NSURL* URL;
@end

@implementation DownloadPurposeListOperation

- (void)start
{
    NSLog(@"%s", __FUNCTION__);
    for (NSOperation* operation in self.dependencies) {
        if (operation.isCancelled) {
            [self cancel];
            return;
        }
    }
    
    if ([self isCancelled])
    {
        [self cancel];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    self._executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self download];
    
}

- (void)main
{
    NSLog(@"%s", __FUNCTION__);
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
    NSLog(@"%s", __FUNCTION__);
    NSString* languageCode = [[NSLocale currentLocale] languageCode];
    self.URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://vendorlist.consensu.org/v-%lu/purposes-%@.json", self.vendorListVersion, languageCode]];
}

- (void)download
{
    NSLog(@"%s", __FUNCTION__);
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:self.URL];
    req.timeoutInterval = 3;
    NSURLSession* dlSession = NSURLSession.sharedSession;
    NSURLSessionTask* task = [dlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 403) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LanguageNotAvailableForPurpose" object:nil userInfo:nil];
            [self cancel];
            return;
        }
        
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
        NSLog(@"%@: finished downloading purpose list -> posting notification", self.class);

        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidDownloadPurposeList" object:nil userInfo:@{@"purposeList" : purposeList}];
        [self completeOperation];
    }];
    
    [task resume];
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

- (BOOL) isAsynchronous;
{
    NSLog(@"%s: %@", __FUNCTION__, @YES);
    return YES;
}
#define b2str(b) b ? @"YES" : @"NO"

- (BOOL)isCancelled
{
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._cancelled));
    return self._cancelled;
}

- (BOOL)isExecuting {
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._executing));
    return self._executing;
}

- (BOOL)isFinished {
    NSLog(@"%s: %@", __FUNCTION__, b2str(self._finished));
    return self._finished;
}

- (void)completeOperation {
    NSLog(@"%s", __FUNCTION__);
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    self._executing = NO;
    self._finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
