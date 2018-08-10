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


typedef enum {
    DeviceLanguageIsEnglish,
    DeviceLanguageNotAvailableForDownload,
    DownloadFailed,
} PurposeListNotAvailableReason;

@interface ViewController ()
@property NSOperationQueue* operationQueue;
@property NSDictionary* vendorList;
@property NSDictionary* purposeList;
@property PurposeListNotAvailableReason purposeListNotAvailableReason;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNotificationObservers];
}

- (NSString*)getStringForPurposeListNotAvailableReason:(PurposeListNotAvailableReason)purposeListNotAvailableReason
{
    switch (purposeListNotAvailableReason) {
        case DeviceLanguageIsEnglish:
            return @"Device language is English";
            break;
        case DeviceLanguageNotAvailableForDownload:
            return @"Device language not available for Download";
            break;
        case DownloadFailed:
            return @"Download failed";
            break;
    }
}

- (void)setupNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidReadVendorListFromBundle" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"DidReadVendorListFromBundle");
        if (!self.vendorList) {
            self.vendorList = note.userInfo[@"vendorList"];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NoInternetConnectivity" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"NoInternetConnectivity");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidDownloadVendorList" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"DidDownloadVendorList");
        
        self.vendorList = note.userInfo[@"vendorList"];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"VendorListDownloadFailed" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"VendorListDownloadFailed");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DidDownloadPurposeList" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"DidDownloadPurposeList");
        
        self.purposeList = note.userInfo[@"purposeList"];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PurposeListDownloadFailed" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"PurposeListDownloadFailed");
        self.purposeListNotAvailableReason = DownloadFailed;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PurposeListDownloadNotNecessary" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"PurposeListDownloadNotNecessary");
        self.purposeListNotAvailableReason = DeviceLanguageIsEnglish;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"LanguageNotAvailableForPurpose" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"LanguageNotAvailableForPurpose");
        self.purposeListNotAvailableReason = DeviceLanguageNotAvailableForDownload;
    }];
    
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
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:nil];
    [self.operationQueue addOperations:@[readVendorListFromBundle, internetConnectivityCheck, downloadVendorList, downloadPurposeList] waitUntilFinished:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (self.operationQueue.operations.count == 0) {
        NSLog(@"\n");
        NSLog(@"Operation queue finished");
        NSLog(@"Vendor list available with version: %@", [self.vendorList objectForKey:@"vendorListVersion"]);
        if (self.purposeList) {
            NSLog(@"Purpose list available with version: %@", [self.purposeList objectForKey:@"vendorListVersion"]);
        } else {
            NSLog(@"Purpose list not available for reason: %@", [self getStringForPurposeListNotAvailableReason:self.purposeListNotAvailableReason]);
        }
    }
}

- (IBAction)startOperations:(UIButton *)sender {
    NSLog(@"");
    NSLog(@"");
    [self doTheStuffTheRightWay];
}


@end
