//
//  ViewController.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/3/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "ViewController.h"

#import "DownloadPurposeListOperation.h"
#import "DownloadVendorListOperation.h"


@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidDownloadPurposeList" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"I was notified about this purpose list: %@", note.userInfo[@"purposeList"]);
    }];
}

- (IBAction)startOperations:(UIButton *)sender {
    NSLog(@"");
    NSLog(@"");
    [self doTheStuffTheRightWay];
}

- (void)doTheStuffTheRightWay
{
    DownloadVendorListOperation* downloadVendorList = [[DownloadVendorListOperation alloc] init];
    DownloadPurposeListOperation* downloadPurposeList = [[DownloadPurposeListOperation alloc] init];
    
    [downloadPurposeList addDependency:downloadVendorList];
    
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue addOperations:@[downloadVendorList, downloadPurposeList] waitUntilFinished:NO];
}


@end
