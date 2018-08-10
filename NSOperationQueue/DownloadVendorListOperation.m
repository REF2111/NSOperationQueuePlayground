//
//  DownloadVendorListOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/9/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "DownloadVendorListOperation.h"

@interface DownloadVendorListOperation()
@property NSURLSessionTask* URLsessionTask;
@end

@implementation DownloadVendorListOperation

- (instancetype)init
{
    self = [super init];
    NSURL* URL = [NSURL URLWithString:@"https://vendorlist.consensu.org/vendorlist.json"];
    self.URLsessionTask = [self sessionTaskWithURL:URL];
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
        
        NSLog(@"FINISHED DOWNLOAD VENDOR LIST OPERATION");
        self.vendorListVersion = [self listVersion:list];
        [super start];
    }];
    
    return task;
}

- (NSUInteger)listVersion:(nonnull NSDictionary*)list
{
    NSUInteger listVersion = [[list objectForKey:@"vendorListVersion"] intValue];
    return listVersion;
}

- (void)start
{
    NSLog(@"STARTING DOWNLOAD VENDOR LIST OPERATION");
    [self.URLsessionTask resume];
}

- (void)cancel
{
    [super cancel];
    [self.URLsessionTask cancel];
}


@end
