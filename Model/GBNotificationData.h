//
//  GBNotificationData.h
//  appledoc
//
//  Created by Martin Pilkington on 26/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBModelBase.h"

@interface GBNotificationData : GBModelBase 

+ (id)notificationWithName:(NSString *)name;
- (id)initWithName:(NSString *)name;

@property (copy) NSString *name;
@property (retain) GBModelBase *owner;

@end
