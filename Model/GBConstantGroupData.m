//
//  GBConstantGroupData.m
//  appledoc
//
//  Created by Martin Pilkington on 24/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBConstantGroupData.h"

@implementation GBConstantGroupData

@synthesize owners;
@synthesize name;

+ (id)constantGroupWithName:(NSString *)name {
	return [[self alloc] initWithName:name];
}

- (id)initWithName:(NSString *)aName {
	if ((self = [super init])) {
		name = [aName copy];
		if (!name) {
			name = @"Untitled Constant Group";
		}
		_constants = [NSMutableArray array];
	}
	return self;
}

- (NSArray *)constants {
	return [_constants copy];
}

- (void)addConstant:(GBConstantData *)aConstant {
	[_constants addObject:aConstant];
}


@end
