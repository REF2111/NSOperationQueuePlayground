//
//  InternetConnectivityCheckOperation.m
//  NSOperationQueue
//
//  Created by Raphael-Alexander Berendes on 8/10/18.
//  Copyright © 2018 Raphael-Alexander Berendes. All rights reserved.
//

#import "InternetConnectivityCheckOperation.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"


@implementation InternetConnectivityCheckOperation


- (void)main
{
    if ([self isCancelled]) {
        return;
    }
    
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    if (remoteHostStatus == NotReachable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NoInternetConnectivity" object:nil userInfo:nil];
        [self cancel];
        return;
    }
}


@end
