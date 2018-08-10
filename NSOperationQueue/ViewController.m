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
#import "OperationOne.h"
#import "OperationTwo.h"
#import "OperationThree.h"
#import "ReadVendorListOperation.h"

@interface ViewController ()
@property dispatch_group_t myGroup;
@property NSNotificationCenter* notificationCenter;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myGroup = dispatch_group_create();
    
    self.notificationCenter = [NSNotificationCenter defaultCenter];
    [self.notificationCenter addObserverForName:@"PurposesDownloaded" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"NOTIFIY ABOUT PURPOSES LIST COMPLETED DOWNLOAD");
    }];
    
}

- (IBAction)startOperations:(UIButton *)sender {
    NSLog(@"");
    NSLog(@"");
#if 1
    [self configureOperations];
#else
    [self doOperations];
#endif
}

- (IBAction)leaveDispatchGroup:(UIButton *)sender {

}

- (void)doOperations
{
    OperationOne* operationOne = [[OperationOne alloc] init];
    OperationTwo* operationTwo = [[OperationTwo alloc] init];
    OperationThree* operationThree = [[OperationThree alloc] init];
    
    [operationTwo addDependency:operationOne];
    [operationThree addDependency:operationTwo];
    
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue addOperations:@[operationOne, operationTwo, operationThree] waitUntilFinished:NO];
}


- (void)configureOperations
{
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];

    DownloadVendorListOperation* downloadVendorList = [[DownloadVendorListOperation alloc] init];
    DownloadPurposeListOperation* downloadPurposeList = [[DownloadPurposeListOperation alloc] init];
    ReadVendorListOperation* readVendorList = [[ReadVendorListOperation alloc] init];
    

    [downloadPurposeList addDependency:downloadVendorList];
    
    [operationQueue addOperations:@[downloadVendorList, downloadPurposeList, readVendorList] waitUntilFinished:NO];
}





@end
