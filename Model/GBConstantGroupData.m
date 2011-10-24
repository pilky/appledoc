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

- (NSArray *)constants {
	return [_constants copy];
}

- (void)addConstant:(GBConstantData *)aConstant {
	[_constants addObject:aConstant];
}


@end
