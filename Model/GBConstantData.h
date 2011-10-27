//
//  GBConstantData.h
//  appledoc
//
//  Created by Martin Pilkington on 24/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBModelBase.h"

@interface GBConstantData : GBModelBase 

+ (id)constantDataWithName:(NSString *)aName;

- (id)initWithName:(NSString *)aName;

@property (copy) NSString *name;
@property (retain) GBModelBase *owner;
@property (readonly) BOOL hasComment;

@end
