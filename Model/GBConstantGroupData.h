//
//  GBConstantGroupData.h
//  appledoc
//
//  Created by Martin Pilkington on 24.10.11.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBModelBase.h"

@class GBConstantData;

@interface GBConstantGroupData : GBModelBase {
	NSMutableArray *_constants;
}

+ (id)constantGroupWithName:(NSString *)name;
- (id)initWithName:(NSString *)name;

@property (readonly) NSString *name;
@property (readonly) NSArray *constants;
@property (copy) NSArray *owners;

- (void)addConstant:(GBConstantData *)aConstant;

@end
