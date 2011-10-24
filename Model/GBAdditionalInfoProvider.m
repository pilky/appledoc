//
//  GBAdditionalInfoProvider.m
//  appledoc
//
//  Created by Martin Pilkington on 24/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBAdditionalInfoProvider.h"
#import "GBDataObjects.h"

@implementation GBAdditionalInfoProvider 

- (id)init {
	if ((self = [super init])) {
		_constants = [NSMutableArray array];
		_dataTypes = [NSMutableArray array];
		_functions = [NSMutableArray array];
	}
	return self;
}

- (void)registerAdditionalInfo:(GBModelBase *)info {
	if ([info isKindOfClass:[GBConstantGroupData class]]) {
		[_constants addObject:info];
		[_constants sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
	}
}

- (void)unregisterAdditionalInfo:(GBModelBase *)info {
	if ([info isKindOfClass:[GBConstantGroupData class]]) {
		[_constants removeObject:info];
	}
}

- (NSArray *)additionaInfoOfTypes:(GBAdditionalInfoType)aTypes {
	return [_constants copy];
}

- (void)mergeDataFromAdditionalInfoProvider:(GBAdditionalInfoProvider *)source {
	
}

@end
