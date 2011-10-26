//
//  GBAdditionalInfoProvider.h
//  appledoc
//
//  Created by Martin Pilkington on 24/10/2011.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//



@class GBModelBase;

typedef enum {
	GBAdditionalInfoTypeConstant = 1,
	GBAdditionalInfoTypeDataType = 2,
	GBAdditionalInfoTypeFunction = 4,
	GBAdditionalInfoTypeNotification = 8
} GBAdditionalInfoType;

@interface GBAdditionalInfoProvider : NSObject {
	@private
	NSMutableArray *_constants;
	NSMutableArray *_dataTypes;
	NSMutableArray *_functions;
	NSMutableArray *_notifications;
}

- (void)registerAdditionalInfo:(GBModelBase *)info;
- (void)unregisterAdditionalInfo:(GBModelBase *)info;

- (NSArray *)additionaInfoOfTypes:(GBAdditionalInfoType)aTypes;

- (void)mergeDataFromAdditionalInfoProvider:(GBAdditionalInfoProvider *)source;

@property (readonly) NSArray *classConstants;
@property (readonly) NSArray *notifications;

@property (readonly) BOOL hasClassConstants;
@property (readonly) BOOL hasNotifications;

@end
