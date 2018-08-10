//
//  DownloadPurposeListOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/9/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "DownloadPurposeListOperation.h"

#import "DownloadVendorListOperation.h"

@protocol DownloadPurposeListOperationDelegate
- (void)shitIsReadyYo;
@end

@interface DownloadPurposeListOperation()
@property NSURLSessionTask* URLsessionTask;
@property NSURL* URL;
@property NSString* languageCode;
@property NSUInteger vendorListVersion;
@end

@implementation DownloadPurposeListOperation

- (instancetype)init
{
    self = [super init];
    return self;
}

- (NSURLSessionTask*)sessionTaskWithURL:(NSURL*)URL
{
    NSURLRequest* req = [NSURLRequest requestWithURL:URL];
    NSURLSession* dlSession = NSURLSession.sharedSession;
    NSURLSessionTask* task = [dlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
        
        if (error) {
            NSLog(@"Error while downloading: %@", error);
            [self cancel];
            return;
        }
        NSError* serializationError;
        NSDictionary* list = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingMutableContainers
                                                               error:&serializationError];
        if (!list) {
            NSLog(@"List could not be deserialized.");
            [self cancel];
            return;
        }
        
        NSLog(@"FINISHED DOWNLOAD PURPOSE LIST OPERATION");
        [self notify];
        [super start];
    }];
    
    return task;
}

- (void)notify
{
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:@"PurposesDownloaded" object:nil userInfo:nil];
}

- (void)updateURL
{
    self.URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://vendorlist.consensu.org/v-%lu/purposes-%@.json", (unsigned long)self.vendorListVersion, self.languageCode]];
}

- (void)start
{
    NSLog(@"STARTING DOWNLOAD PURPOSE LIST OPERATION");
    
    DownloadVendorListOperation* downloadVendorListOperation;
    for (NSOperation* operation in self.dependencies) {
        if ([operation isKindOfClass:[DownloadVendorListOperation class]]) {
            downloadVendorListOperation = (DownloadVendorListOperation*)operation;
        }
    }
    self.vendorListVersion = downloadVendorListOperation.vendorListVersion;
    self.languageCode = [[NSLocale currentLocale] languageCode];
    if (!self.vendorListVersion && !self.languageCode) {
        NSLog(@"DOWNLOAD PURPOSE LIST OPERATION CANCELED");
        [self cancel];
        return;
    }
    [self updateURL];
    self.URLsessionTask = [self sessionTaskWithURL:self.URL];
    [self.URLsessionTask resume];
}

- (void)cancel
{
    [super cancel];
    [self.URLsessionTask cancel];
}

@end
