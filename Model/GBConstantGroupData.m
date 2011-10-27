//
//  GBConstantGroupData.m
//  appledoc
//
//  Created by Martin Pilkington on 24/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBConstantGroupData.h"

@implementation GBConstantGroupData

@synthesize owner;
@synthesize name;
@synthesize code;

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
		code = @"";
	}
	return self;
}

- (NSArray *)constants {
	return [_constants copy];
}

- (void)addConstant:(GBConstantData *)aConstant {
	[_constants addObject:aConstant];
	[aConstant setOwner:self];
}

- (void)appendCode:(NSString *)aCode {
	NSString *codeToAdd = [aCode stringByReplacingOccurrencesOfString:@"\t" withString:@"    "];
	[self setCode:[[self code] stringByAppendingString:codeToAdd]];
}

- (NSString *)description {
	return self.name;
}


@end
