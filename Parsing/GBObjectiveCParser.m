//
//  GBObjectiveCParser.m
//  appledoc
//
//  Created by Tomaz Kragelj on 25.7.10.
//  Copyright (C) 2010, Gentle Bytes. All rights reserved.
//

#import "RegexKitLite.h"
#import "ParseKit.h"
#import "PKToken+GBToken.h"
#import "GBTokenizer.h"
#import "GBStore.h"
#import "GBApplicationSettingsProvider.h"
#import "GBDataObjects.h"
#import "GBObjectiveCParser.h"

@interface GBObjectiveCParser ()

- (PKTokenizer *)tokenizerWithInputString:(NSString *)input;
@property (retain) GBTokenizer *tokenizer;
@property (retain) GBStore *store;
@property (retain) GBApplicationSettingsProvider *settings;
@property (assign) BOOL includeInOutput;
@property (retain) id primaryFileObject;
@property (retain) NSMutableArray *additionalInfoObjects;
@property (retain) GBConstantGroupData *currentConstantGroup;

@end

@interface GBObjectiveCParser (DefinitionParsing)

- (void)matchClassDefinition;
- (void)matchCategoryDefinition;
- (void)matchExtensionDefinition;
- (void)matchProtocolDefinition;
- (void)matchSuperclassForClass:(GBClassData *)class;
- (void)matchAdoptedProtocolForProvider:(GBAdoptedProtocolsProvider *)provider;
- (void)matchIvarsForProvider:(GBIvarsProvider *)provider;
- (void)matchMethodDefinitionsForProvider:(GBMethodsProvider *)provider defaultsRequired:(BOOL)required;
- (BOOL)matchMethodDefinitionForProvider:(GBMethodsProvider *)provider required:(BOOL)required;
- (BOOL)matchPropertyDefinitionForProvider:(GBMethodsProvider *)provider required:(BOOL)required;

@end

@interface GBObjectiveCParser (DeclarationsParsing)

- (void)matchClassDeclaration;
- (void)matchCategoryDeclaration;
- (void)matchMethodDeclarationsForProvider:(GBMethodsProvider *)provider defaultsRequired:(BOOL)required;
- (BOOL)matchMethodDeclarationForProvider:(GBMethodsProvider *)provider required:(BOOL)required;
- (void)consumeMethodBody;

@end

@interface GBObjectiveCParser (AdditionalInfoParsing) 

- (void)matchExtern;
- (void)matchDefine;
- (void)matchEnum;
- (void)matchStruct;
- (void)matchTypeDef;
- (GBConstantGroupData *)constantGroup;

@end


@interface GBObjectiveCParser (CommonParsing)

- (BOOL)matchNextObject;
- (BOOL)matchObjectDefinition;
- (BOOL)matchObjectDeclaration;
- (BOOL)matchAdditionalInfo;
- (BOOL)matchMethodDataForProvider:(GBMethodsProvider *)provider from:(NSString *)start to:(NSString *)end required:(BOOL)required;
- (void)registerComment:(GBComment *)comment toObject:(GBModelBase *)object;
- (void)registerLastCommentToObject:(GBModelBase *)object;
- (void)registerSourceInfoFromCurrentTokenToObject:(GBModelBase *)object;
- (NSString *)sectionNameFromComment:(GBComment *)comment;
- (NSString *)constantGroupNameFromComment:(GBComment *)comment;
- (void)updatePrimaryFileObject:(id)object;

@end

#pragma mark -

@implementation GBObjectiveCParser

#pragma mark ￼Initialization & disposal

+ (id)parserWithSettingsProvider:(id)settingsProvider {
	return [[[self alloc] initWithSettingsProvider:settingsProvider] autorelease];
}

- (id)initWithSettingsProvider:(id)settingsProvider {
	NSParameterAssert(settingsProvider != nil);
	GBLogDebug(@"Initializing objective-c parser with settings provider %@...", settingsProvider);
	self = [super init];
	if (self) {
		self.settings = settingsProvider;
	}
	return self;
}

#pragma mark Parsing handling

- (void)parseObjectsFromString:(NSString *)input sourceFile:(NSString *)filename toStore:(id)store {
	NSParameterAssert(input != nil);
	NSParameterAssert(filename != nil);
	NSParameterAssert([filename length] > 0);
	NSParameterAssert(store != nil);
	GBLogDebug(@"Parsing objective-c objects...");
	self.store = store;
	self.tokenizer = [GBTokenizer tokenizerWithSource:[self tokenizerWithInputString:input] filename:filename settings:self.settings];
    self.includeInOutput = YES;
	self.primaryFileObject = nil;
	self.additionalInfoObjects = [NSMutableArray array];
	self.currentConstantGroup = nil;
	
    for (NSString *excludeOutputPath in self.settings.excludeOutputPaths) {
        if ([filename isEqualToString:excludeOutputPath]) {
            self.includeInOutput = NO;
            break;
        }
        
        NSString *excludeOutputDir = excludeOutputPath;
        if (![excludeOutputDir hasSuffix:@"/"])
            excludeOutputDir = [NSString stringWithFormat:@"%@/", excludeOutputDir];
        if ([filename hasPrefix:excludeOutputDir]) {
            self.includeInOutput = NO;
            break;
        }
    }
	while (![self.tokenizer eof]) {
		if (![self matchNextObject]) {
			[self.tokenizer consume:1];
		}
	}
	
	for (id additionalObject in self.additionalInfoObjects) {
		[additionalObject setOwner:self.primaryFileObject];
	}
}

- (PKTokenizer *)tokenizerWithInputString:(NSString *)input {
	PKTokenizer *result = [PKTokenizer tokenizerWithString:input];
	[result setTokenizerState:result.wordState from:'_' to:'_'];	// Allow words to start with _
	[result.symbolState add:@"..."];	// Allow ... as single token
	return result;
}

#pragma mark Properties

@synthesize tokenizer;
@synthesize settings;
@synthesize store;
@synthesize includeInOutput;
@synthesize primaryFileObject;
@synthesize additionalInfoObjects;
@synthesize currentConstantGroup;

@end

#pragma mark -

@implementation GBObjectiveCParser (DefinitionParsing)

- (void)matchClassDefinition {
	// @interface CLASSNAME
	NSString *className = [[self.tokenizer lookahead:1] stringValue];
	GBClassData *class = [GBClassData classDataWithName:className];
    class.includeInOutput = self.includeInOutput;
	[self registerSourceInfoFromCurrentTokenToObject:class];
	GBLogDebug(@"Matched %@ class definition at line %lu.", className, class.prefferedSourceInfo.lineNumber);
	[self registerLastCommentToObject:class];
	[self.tokenizer consume:2];
	[self matchSuperclassForClass:class];
	[self matchAdoptedProtocolForProvider:class.adoptedProtocols];
	[self matchIvarsForProvider:class.ivars];
	[self matchMethodDefinitionsForProvider:class.methods defaultsRequired:NO];
	[self.store registerClass:class];
	[self updatePrimaryFileObject:class];
	self.currentConstantGroup = nil;
}

- (void)matchCategoryDefinition {
	// @interface CLASSNAME ( CATEGORYNAME )
	NSString *className = [[self.tokenizer lookahead:1] stringValue];
	NSString *categoryName = [[self.tokenizer lookahead:3] stringValue];
	GBCategoryData *category = [GBCategoryData categoryDataWithName:categoryName className:className];
    category.includeInOutput = self.includeInOutput;
	[self registerSourceInfoFromCurrentTokenToObject:category];
	GBLogVerbose(@"Matched %@(%@) category definition at line %lu.", className, categoryName, category.prefferedSourceInfo.lineNumber);
	[self registerLastCommentToObject:category];
	[self.tokenizer consume:5];
	[self matchAdoptedProtocolForProvider:category.adoptedProtocols];
	[self matchMethodDefinitionsForProvider:category.methods defaultsRequired:NO];
	[self.store registerCategory:category];
	[self updatePrimaryFileObject:category];
	self.currentConstantGroup = nil;
}

- (void)matchExtensionDefinition {
	// @interface CLASSNAME ( )
	NSString *className = [[self.tokenizer lookahead:1] stringValue];
	GBCategoryData *extension = [GBCategoryData categoryDataWithName:nil className:className];
    extension.includeInOutput = self.includeInOutput;
	GBLogVerbose(@"Matched %@() extension definition at line %lu.", className, extension.prefferedSourceInfo.lineNumber);
	[self registerSourceInfoFromCurrentTokenToObject:extension];
	[self registerLastCommentToObject:extension];
	[self.tokenizer consume:4];
	[self matchAdoptedProtocolForProvider:extension.adoptedProtocols];
	[self matchMethodDefinitionsForProvider:extension.methods defaultsRequired:NO];
	[self.store registerCategory:extension];
	self.currentConstantGroup = nil;
}

- (void)matchProtocolDefinition {
	// @protocol PROTOCOLNAME
	NSString *protocolName = [[self.tokenizer lookahead:1] stringValue];
	GBProtocolData *protocol = [GBProtocolData protocolDataWithName:protocolName];
    protocol.includeInOutput = self.includeInOutput;
	GBLogVerbose(@"Matched %@ protocol definition at line %lu.", protocolName, protocol.prefferedSourceInfo.lineNumber);
	[self registerSourceInfoFromCurrentTokenToObject:protocol];
	[self registerLastCommentToObject:protocol];
	[self.tokenizer consume:2];
	[self matchAdoptedProtocolForProvider:protocol.adoptedProtocols];
	[self matchMethodDefinitionsForProvider:protocol.methods defaultsRequired:YES];
	[self.store registerProtocol:protocol];
	[self updatePrimaryFileObject:protocol];
	self.currentConstantGroup = nil;
}

- (void)matchSuperclassForClass:(GBClassData *)class {
	if (![[self.tokenizer currentToken] matches:@":"]) return;
	class.nameOfSuperclass = [[self.tokenizer lookahead:1] stringValue];
	GBLogDebug(@"Matched superclass %@.", class.nameOfSuperclass);
	[self.tokenizer consume:2];
}

- (void)matchAdoptedProtocolForProvider:(GBAdoptedProtocolsProvider *)provider {
	[self.tokenizer consumeFrom:@"<" to:@">" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		if ([token matches:@","]) return;
		GBProtocolData *protocol = [[GBProtocolData alloc] initWithName:[token stringValue]];
		GBLogDebug(@"Matched adopted protocol %@.", protocol);
		[provider registerProtocol:protocol];
	}];
}

- (void)matchIvarsForProvider:(GBIvarsProvider *)provider {
	[self.tokenizer consumeFrom:@"{" to:@"}" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		return; // Ignore all ivars, no need to document these(?)
	}];
}

- (void)matchMethodDefinitionsForProvider:(GBMethodsProvider *)provider defaultsRequired:(BOOL)required {
	__block BOOL isRequired = required;
	[self.tokenizer consumeTo:@"@end" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		if ([token matches:@"@required"]) {
			isRequired = YES;
		} else if ([token matches:@"@optional"]) {
			isRequired = NO;
		} else if ([self matchMethodDefinitionForProvider:provider required:isRequired]) {
			*consume = NO;
		} else if ([self matchPropertyDefinitionForProvider:provider required:isRequired]) {
			*consume = NO;
		}
	}];
}

- (BOOL)matchMethodDefinitionForProvider:(GBMethodsProvider *)provider required:(BOOL)required {
	if ([self matchMethodDataForProvider:provider from:@"+" to:@";" required:required]) return YES;
	if ([self matchMethodDataForProvider:provider from:@"-" to:@";" required:required]) return YES;
	return NO;
}

- (BOOL)matchPropertyDefinitionForProvider:(GBMethodsProvider *)provider required:(BOOL)required {
	GBComment *comment = [self.tokenizer lastComment];
	NSString *sectionName = [self sectionNameFromComment:[self.tokenizer previousComment]];
	__block BOOL firstToken = YES;
	__block BOOL result = NO;
	__block GBSourceInfo *filedata = nil;
	[self.tokenizer consumeFrom:@"@property" to:@";" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		if (!filedata) filedata = [self.tokenizer sourceInfoForToken:token];
		if (firstToken) {
			[self.tokenizer resetComments];
			firstToken = NO;
		}
		
		// Get attributes.
		NSMutableArray *propertyAttributes = [NSMutableArray array];
		[self.tokenizer consumeFrom:@"(" to:@")" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
			if ([token matches:@","]) return;
			[propertyAttributes addObject:[token stringValue]];
		}];
		
		// Get property types and name. Handle block types properly!
		NSMutableArray *propertyComponents = [NSMutableArray array];
		__block BOOL parseAttribute = NO;
		__block NSUInteger parenthesisDepth = 0;
		[self.tokenizer consumeTo:@";" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
			if ([token matches:@"__attribute__"]) {
				parseAttribute = YES;
				parenthesisDepth = 0;
			} else if (parseAttribute) {
				if ([token matches:@"("]) {
					parenthesisDepth++;					
				} else if ([token matches:@")"]) {
					parenthesisDepth--;
					if (parenthesisDepth == 0) parseAttribute = NO;
				}					
			} else {
				[propertyComponents addObject:[token stringValue]];
			}
		}];
		
		// Register property.
		GBMethodData *propertyData = [GBMethodData propertyDataWithAttributes:propertyAttributes components:propertyComponents];
		[propertyData registerSourceInfo:filedata];
		GBLogDebug(@"Matched property definition %@ at line %lu.", propertyData, propertyData.prefferedSourceInfo.lineNumber);
		[self registerComment:comment toObject:propertyData];
		[propertyData setIsRequired:required];
		[provider registerSectionIfNameIsValid:sectionName];
		[provider registerMethod:propertyData];
		*consume = NO;
		*stop = YES;
		result = YES;
	}];
	return result;
}
	 
@end

#pragma mark -

@implementation GBObjectiveCParser (DeclarationsParsing)

- (void)matchClassDeclaration {
	// @implementation CLASSNAME
	NSString *className = [[self.tokenizer lookahead:1] stringValue];
	GBClassData *class = [GBClassData classDataWithName:className];
    class.includeInOutput = self.includeInOutput;
	[self registerSourceInfoFromCurrentTokenToObject:class];
	GBLogVerbose(@"Matched %@ class declaration at line %lu.", className, class.prefferedSourceInfo.lineNumber);
	[self registerLastCommentToObject:class];
	[self.tokenizer consume:2];
	[self matchMethodDeclarationsForProvider:class.methods defaultsRequired:NO];
	[self.store registerClass:class];
	[self updatePrimaryFileObject:class];
	self.currentConstantGroup = nil;
}

- (void)matchCategoryDeclaration {
	// @implementation CLASSNAME ( CATEGORYNAME )
	NSString *className = [[self.tokenizer lookahead:1] stringValue];
	NSString *categoryName = [[self.tokenizer lookahead:3] stringValue];
	GBCategoryData *category = [GBCategoryData categoryDataWithName:categoryName className:className];
    category.includeInOutput = self.includeInOutput;
	[self registerSourceInfoFromCurrentTokenToObject:category];
	GBLogVerbose(@"Matched %@(%@) category declaration at line %lu.", className, categoryName, category.prefferedSourceInfo.lineNumber);
	[self registerLastCommentToObject:category];
	[self.tokenizer consume:5];
	[self matchMethodDeclarationsForProvider:category.methods defaultsRequired:NO];
	[self.store registerCategory:category];
	[self updatePrimaryFileObject:category];
	self.currentConstantGroup = nil;
}

- (void)matchMethodDeclarationsForProvider:(GBMethodsProvider *)provider defaultsRequired:(BOOL)required {
	__block BOOL isRequired = required;
	[self.tokenizer consumeTo:@"@end" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		if ([self matchMethodDeclarationForProvider:provider required:isRequired]) {
			*consume = NO;
		}
	}];
}

- (BOOL)matchMethodDeclarationForProvider:(GBMethodsProvider *)provider required:(BOOL)required {
	if ([self matchMethodDataForProvider:provider from:@"+" to:@"{" required:required]) {
		[self consumeMethodBody];
		return YES;
	}
	if ([self matchMethodDataForProvider:provider from:@"-" to:@"{" required:required]) {
		[self consumeMethodBody];
		return YES;
	}
	return NO;
}

- (void)consumeMethodBody {
	// This method assumes we're currently pointing to the first token after method's opening brace!
	__block NSUInteger braceLevel = 1;
	[self.tokenizer consumeTo:@"@end" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		if ([token matches:@"{"]) {
			braceLevel++;
			return;
		}
		if ([token matches:@"}"]) {
			if (--braceLevel == 0) {
				*consume = NO;
				*stop = YES;
			}
			return;
		}
	}];
}

@end

#pragma mark -

@implementation GBObjectiveCParser (AdditionalInfoParsing) 

- (void)matchExtern {
	NSMutableArray *tokens = [NSMutableArray array];
	__block PKToken *nameToken = nil;
	[self.tokenizer consumeTo:@";" options:GBTokenizerIncludeWhitespace usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		[tokens addObject:token];
		if ([token matches:@"("] && !nameToken) {
			nameToken = [self.tokenizer lookahead:2];
		}
	}];
	if (!nameToken) {
		nameToken = [tokens lastObject];
	}
	GBConstantData *constant = [GBConstantData constantDataWithName:[nameToken stringValue]];
	[constant setCode:[[tokens componentsJoinedByString:@""] stringByAppendingString:@";"]];
	[self registerSourceInfoFromCurrentTokenToObject:constant];
	[[self constantGroup] addConstant:constant];
	[self registerLastCommentToObject:constant];
}

- (void)matchDefine {
	
}

- (void)matchEnum {
	self.currentConstantGroup = nil;
}

- (void)matchStruct {
	self.currentConstantGroup = nil;
}

- (void)matchTypeDef {
	self.currentConstantGroup = nil;
}

- (GBConstantGroupData *)constantGroup {
	GBConstantGroupData *group = self.currentConstantGroup;
	//if we have a previous comment it means we have a new group
	if (!group || self.tokenizer.previousComment) {
		group = [GBConstantGroupData constantGroupWithName:[self constantGroupNameFromComment:self.tokenizer.previousComment]];
		[self registerComment:self.tokenizer.previousComment toObject:group];
		self.currentConstantGroup = group;
		[self.store.additionalInfoProvider registerAdditionalInfo:group];
		[self registerSourceInfoFromCurrentTokenToObject:group];
		[self.additionalInfoObjects addObject:group];
	}
	return group;
}

@end

#pragma mark -

@implementation GBObjectiveCParser (CommonParsing)

- (BOOL)matchNextObject {
	if ([self matchObjectDefinition]) return YES;
	if ([self matchObjectDeclaration]) return YES;
	if ([self matchAdditionalInfo]) return YES;
	return NO;
}

- (BOOL)matchObjectDefinition {
	// Get data needed for distinguishing between class, category and extension definition.
	BOOL isInterface = [[self.tokenizer currentToken] matches:@"@interface"];
	BOOL isOpenParenthesis = [[self.tokenizer lookahead:2] matches:@"("];
	BOOL isCloseParenthesis = [[self.tokenizer lookahead:3] matches:@")"];
	
	// Found class extension definition.
	if (isInterface && isOpenParenthesis && isCloseParenthesis) {
		[self matchExtensionDefinition];
		return YES;
	}
	
	// Found category definition.
	if (isInterface && isOpenParenthesis) {
		[self matchCategoryDefinition];
		return YES;
	}
	
	// Found class definition.
	if (isInterface) {
		[self matchClassDefinition];
		return YES;
	}
	
	// Get data needed for distinguishing between protocol definition and directive.
	BOOL isProtocol = [[self.tokenizer currentToken] matches:@"@protocol"];
	BOOL isDirective = [[self.tokenizer lookahead:2] matches:@";"] || [[self.tokenizer lookahead:2] matches:@","];
	
	// Found protocol definition.
	if (isProtocol && !isDirective) {
		[self matchProtocolDefinition];
		return YES;
	}
	
	return NO;
}

- (BOOL)matchObjectDeclaration {
	// Get data needed for distinguishing between class and category declaration.
	BOOL isImplementation = [[self.tokenizer currentToken] matches:@"@implementation"];
	BOOL isOpenParenthesis = [[self.tokenizer lookahead:2] matches:@"("];
	
	// Found category declaration.
	if (isImplementation && isOpenParenthesis) {
		[self matchCategoryDeclaration];
		return YES;
	}
	
	// Found class declaration.
	if (isImplementation) {
		[self matchClassDeclaration];
		return YES;
	}
	
	return NO;
}

- (BOOL)matchAdditionalInfo {
	if ([[self.tokenizer currentToken] matches:@"extern"]) {
		[self matchExtern];
		return YES;
	}
	return NO;
}

- (BOOL)matchMethodDataForProvider:(GBMethodsProvider *)provider from:(NSString *)start to:(NSString *)end required:(BOOL)required {
	// This method only matches class or instance methods, not properties!
	// - (void)assertIvar:(GBIvarData *)ivar matches:(NSString *)firstType,... NS_REQUIRES_NIL_TERMINATION;
	GBComment *comment = [self.tokenizer lastComment];
	GBComment *sectionComment = [self.tokenizer previousComment];
	NSString *sectionName = [self sectionNameFromComment:sectionComment];
	__block BOOL assertMethod = YES;
	__block BOOL result = NO;
	__block GBSourceInfo *filedata = nil;
	GBMethodType methodType = [start isEqualToString:@"-"] ? GBMethodTypeInstance : GBMethodTypeClass;
	[self.tokenizer consumeFrom:start to:end usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
		// In order to provide at least some assurance the minus or plus actually starts the method, we validate next token is opening parenthesis. Very simple so might need some refinement...
		if (assertMethod) {
			if (![token matches:@"("]) {
				[self.tokenizer resetComments];
				*stop = YES;
				return;
			}
			assertMethod = NO;
		}
		
		// Prepare source information and reset comments; we alreay read the values so as long as we have found a method, we should reset the comments to prepare ground for next methods. This is needed due to the way this method works - it actually ends by jumping to the first token after the given end symbol, which effectively positions tokenizer to the first token of the following method. Therefore it already consumes any comment preceeding the method. So we can't reset AFTER finished parsing, but rather before! Note that we should only do it once...
		if (!filedata) {
			filedata = [self.tokenizer sourceInfoForToken:token];
			[self.tokenizer resetComments];
		}
		
		// Get result types.
		NSMutableArray *methodResult = [NSMutableArray array];
		[self.tokenizer consumeFrom:@"(" to:@")" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
			[methodResult addObject:[token stringValue]];
		}];
		
		// Get all arguments. Note that we ignore semicolons which may "happen" in declaration before method opening brace!
		__block BOOL parseAttribute = NO;
		__block NSUInteger parenthesisDepth = 0;
		__block NSMutableArray *methodArgs = [NSMutableArray array];
		[self.tokenizer consumeTo:end usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
			if ([token matches:@"__attribute__"]) {
				parseAttribute = YES;
				parenthesisDepth = 0;
				return;
			}
			if (parseAttribute) {
				if ([token matches:@"("]) {
					parenthesisDepth++;
				} else if ([token matches:@")"]) {
					parenthesisDepth--;
					if (parenthesisDepth == 0) parseAttribute = NO;
				}
				return;
			}
			
			// If we receive semicolon, ignore it - this works for both - definition and declaration!
			if ([token matches:@";"]) {
				*stop = YES;
				return;
			}
			
			// Get argument name.
			NSString *argumentName = [token stringValue];
			[self.tokenizer consume:1];
			
			__block NSString *argumentVar = nil;
			__block NSMutableArray *argumentTypes = [NSMutableArray array];
			__block NSMutableArray *terminationMacros = [NSMutableArray array];
			if ([[self.tokenizer currentToken] matches:@":"]) {
				[self.tokenizer consume:1];
				
				// Get argument types.
				[self.tokenizer consumeFrom:@"(" to:@")" usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
					[argumentTypes addObject:[token stringValue]];
				}];
				
				// Get argument variable name.
				if (![[self.tokenizer currentToken] matches:end]) {
					argumentVar = [[self.tokenizer currentToken] stringValue];
					[self.tokenizer consume:1];
				}
				
				// If we have variable args block following, consume the rest of the tokens to get optional termination macros.
				if ([[self.tokenizer lookahead:0] matches:@","] && [[self.tokenizer lookahead:1] matches:@"..."]) {
					[self.tokenizer consume:2];
					[self.tokenizer consumeTo:end usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
						[terminationMacros addObject:[token stringValue]];
					}];
					*stop = YES; // Ignore the rest of parameters as vararg is the last and above block consumed end token which would confuse above block!
				}
                
                // If we have no more colon before end, consume the rest of the tokens to get optional termination macros.
                __block BOOL hasColon = NO;
                [self.tokenizer lookaheadTo:end usingBlock:^(PKToken *token, BOOL *stop) {
                    if ([token matches:@":"]) {
                        hasColon = YES;
                        *stop = YES;
                    }
                }];
                if (!hasColon) {
					[self.tokenizer consumeTo:end usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
						[terminationMacros addObject:[token stringValue]];
					}];
					*stop = YES; // Ignore the rest of parameters
                }
                
                if (terminationMacros.count == 0) {
                    terminationMacros = nil;
                }
			} else {
                // remaining tokens are termination macros
                [self.tokenizer consumeTo:end usingBlock:^(PKToken *token, BOOL *consume, BOOL *stop) {
                    [terminationMacros addObject:[token stringValue]];
                }];
                *stop = YES; // Ignore the rest of parameters
            }
            
            GBMethodArgument *argument = [GBMethodArgument methodArgumentWithName:argumentName types:argumentTypes var:argumentVar terminationMacros:terminationMacros];
            [methodArgs addObject:argument];
            *consume = NO;
		}];
		
		// Create method instance and register it.
		GBMethodData *methodData = [GBMethodData methodDataWithType:methodType result:methodResult arguments:methodArgs];
		[methodData registerSourceInfo:filedata];		
		GBLogDebug(@"Matched method %@%@ at line %lu.", start, methodData, methodData.prefferedSourceInfo.lineNumber);
		[self registerComment:comment toObject:methodData];
		[methodData setIsRequired:required];
		[provider registerSectionIfNameIsValid:sectionName];
		[provider registerMethod:methodData];
		*consume = NO;
		*stop = YES;
		result = YES;
	}];
	return result;
}

- (void)registerLastCommentToObject:(GBModelBase *)object {
	[self registerComment:[self.tokenizer lastComment] toObject:object];
	[self.tokenizer resetComments];
}

- (void)registerComment:(GBComment *)comment toObject:(GBModelBase *)object {
	[object setComment:comment];
	if (comment) GBLogDebug(@"Assigned comment '%@' to '%@'...", [comment.stringValue normalizedDescription], object);
}

- (void)registerSourceInfoFromCurrentTokenToObject:(GBModelBase *)object {
	GBSourceInfo *info = [self.tokenizer sourceInfoForCurrentToken];
	[object registerSourceInfo:info];
}

- (NSString *)sectionNameFromComment:(GBComment *)comment {
	// If comment has nil or whitespace-only string value, ignore it.
	NSCharacterSet* trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];	
	if ([[comment.stringValue stringByTrimmingCharactersInSet:trimSet] length] == 0) return nil;
	
	// If comment doesn't contain section name, ignore it, otherwise return the name.
	NSString *name = [comment.stringValue stringByMatching:self.settings.commentComponents.methodGroupRegex capture:1];
	if ([[name stringByTrimmingCharactersInSet:trimSet] length] == 0) return nil;
	return [name stringByWordifyingWithSpaces];
}

- (NSString *)constantGroupNameFromComment:(GBComment *)comment {
	// If comment has nil or whitespace-only string value, ignore it.
	NSCharacterSet* trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];	
	if ([[comment.stringValue stringByTrimmingCharactersInSet:trimSet] length] == 0) return nil;
	
	// If comment doesn't contain section name, ignore it, otherwise return the name.
	NSString *name = [comment.stringValue stringByMatching:self.settings.commentComponents.constantGroupRegex capture:2];
	if ([[name stringByTrimmingCharactersInSet:trimSet] length] == 0) return nil;
	return [name stringByWordifyingWithSpaces];
}

- (void)updatePrimaryFileObject:(id)object {
	//Register the first object for this file so we can assign all additional info to it (all additional info with owners are sorted in the processing stage)
	if (!self.primaryFileObject) {
		self.primaryFileObject = object;
	//Classes take precedence over categories & protocols. The first class listed wins
	} else if ([object isKindOfClass:[GBClassData class]] && ![self.primaryFileObject isKindOfClass:[GBClassData class]]) {
		self.primaryFileObject = object;
	}
}

@end

