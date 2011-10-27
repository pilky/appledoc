//
//  GBConstantData.m
//  appledoc
//
//  Created by Martin Pilkington on 24/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBConstantData.h"

@implementation GBConstantData

@synthesize name, owner;

+ (id)constantDataWithName:(NSString *)aName {
	return [[self alloc] initWithName:aName];
}

- (id)initWithName:(NSString *)aName {
	if ((self = [super init])) {
		name = [aName copy];
	}
	return self;
}

- (BOOL)hasComment {
	return [self comment] != nil;
}

- (NSString *)description {
	return self.name;
}

@end
