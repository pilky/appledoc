//
//  GBObjectiveCParser-ConstantGroupParsingTesting.m
//  appledoc
//
//  Created by Martin Pilkington 23.10.11
//  Copyright (C) 2011 Gentle Bytes. All rights reserved.
//

#import "GBStore.h"
#import "GBDataObjects.h"
#import "GBObjectiveCParser.h"

// Note that we use class for invoking parsing of adopted protocols. Probably not the best option - i.e. we could isolate parsing code altogether and only parse relevant stuff here, but it seemed not much would be gained by doing this. Separating unit tests does avoid repetition in top-level objects testing code - we only need to test specific data there.

@interface GBObjectiveCParserConstantGroupParsingTesting : GBObjectsAssertor
@end

@implementation GBObjectiveCParserConstantGroupParsingTesting

- (void)testParseObjectsFromString_shouldRegisterAdoptedProtocol {
	// setup
	GBObjectiveCParser *parser = [GBObjectiveCParser parserWithSettingsProvider:[GBTestObjectsRegistry mockSettingsProvider]];
	GBStore *store = [[GBStore alloc] init];
	// execute
	[parser parseObjectsFromString:@"extern NSString *foo;" sourceFile:@"filename.h" toStore:store];
	[parser parseObjectsFromString:@"extern NSString * foo; extern NSString * foo;" sourceFile:@"filename.h" toStore:store];
	[parser parseObjectsFromString:@"/** @constants My Constants */\n/** Foo does this */\nextern int foo;" sourceFile:@"filename.h" toStore:store];
	[parser parseObjectsFromString:@"extern BOOL (^foo)(id bar, id baz);" sourceFile:@"filename.h" toStore:store];
	// verify
//	NSArray *protocols = [[[[store classes] anyObject] adoptedProtocols] protocolsSortedByName];
//	assertThatInteger([protocols count], equalToInteger(1));
//	assertThat([[protocols objectAtIndex:0] nameOfProtocol], is(@"MyProtocol"));
}

@end