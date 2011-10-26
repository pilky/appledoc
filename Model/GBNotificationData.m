//
//  GBNotificationData.m
//  appledoc
//
//  Created by Martin Pilkington on 26/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBNotificationData.h"

@implementation GBNotificationData

@synthesize name, owner;

+ (id)notificationWithName:(NSString *)name {
	return [[self alloc] initWithName:name];
}

- (id)initWithName:(NSString *)aName {
	if ((self = [super init])) {
		name = [aName copy];
	}
	return self;
}

@end
