//
//  ReadVendorListOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/9/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "ReadVendorListOperation.h"

@implementation ReadVendorListOperation


- (void)start
{
    NSLog(@"STARTING READ VENDOR LIST OPERATION");
    [self readVendorListFromBundle];
}

- (void)readVendorListFromBundle
{
    NSBundle* mainBundle = NSBundle.mainBundle;
    NSString* vendorListStr = @"Resources.bundle/vendorlist.json";
    NSString* vendorListPath = [mainBundle pathForResource:[vendorListStr stringByDeletingPathExtension] ofType:vendorListStr.pathExtension];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsURL = [NSURL URLWithString:vendorListPath];
    
    if(![fileManager fileExistsAtPath:documentsURL.path]) {
        [super cancel];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData* data = [NSData dataWithContentsOfFile:vendorListPath];
        NSError* serializationError;
        NSDictionary* vendorList = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&serializationError];
        if (!vendorList) {
            [super cancel];
            return;
        }
        NSLog(@"FINISHED READ VENDOR LIST OPERATION");
        [super start];
    });
}

@end
