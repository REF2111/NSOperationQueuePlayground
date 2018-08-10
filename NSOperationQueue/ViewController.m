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
#import "InternetConnectivityCheckOperation.h"
#import "ReadVendorListFromBundleOperation.h"


@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNotificationObservers];
}

- (void)setupNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidReadVendorListFromBundle" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"DidReadVendorListFromBundle");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidDownloadVendorList" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"DidDownloadVendorList");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"VendorListDownloadTimedOut" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"VendorListDownloadTimedOut");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidDownloadPurposeList" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"DidDownloadPurposeList");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PurposeListDownloadTimedOut" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"PurposeListDownloadTimedOut");
    }];
}

- (IBAction)startOperations:(UIButton *)sender {
    NSLog(@"");
    NSLog(@"");
    [self doTheStuffTheRightWay];
}

- (void)doTheStuffTheRightWay
{
    InternetConnectivityCheckOperation* internetConnectivityCheck = [[InternetConnectivityCheckOperation alloc] init];
    ReadVendorListFromBundleOperation* readVendorListFromBundle = [[ReadVendorListFromBundleOperation alloc] init];
    DownloadVendorListOperation* downloadVendorList = [[DownloadVendorListOperation alloc] init];
    DownloadPurposeListOperation* downloadPurposeList = [[DownloadPurposeListOperation alloc] init];
    
    [downloadVendorList addDependency:internetConnectivityCheck];
    [downloadPurposeList addDependency:internetConnectivityCheck];
    [downloadPurposeList addDependency:downloadVendorList];
    
    NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue addOperations:@[readVendorListFromBundle, internetConnectivityCheck, downloadVendorList, downloadPurposeList] waitUntilFinished:NO];
}


@end
