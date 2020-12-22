//
//  XmlParser.m
//  Javelin
//
//  Created by harry on 8/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "XmlParser.h"
/*
@implementation myElement

@synthesize parentDict;
@synthesize valueDict;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
	parentDict = nil;
	valueDict = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@end
*/

@implementation XmlParser
@synthesize result;

- (id) initWithName:(NSString *)name
{
	self = [super init];
	if ( self ){
		found = NO;
	}
	nodeName = [[NSString alloc] initWithString:name];
	//stringWithString:name];
	currentElementName = [[NSString alloc] initWithString:@""];
	currentElementValue = [[NSString alloc] initWithString:@""];
	
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		found = NO;
    }
    
	currentElementName = [[NSString alloc] initWithString:@""];
    currentElementValue = [[NSString alloc] initWithString:@""];
	nodeName = [[NSString alloc] initWithString:@""];
	
	return self;
}
/*
- (void)dealloc
{
	[nodeName release];
	[currentElementName release];
	[currentElementValue release];
	
    [super dealloc];
}
*/
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	result=[[NSMutableDictionary alloc] init];
	currentElementName=@"";
	currentElementValue=@"";
}

-	(void)parser:(NSXMLParser *)parser 
		didStartElement:(NSString *)elementName 
			namespaceURI:(NSString *)namespaceURI 
			qualifiedName:(NSString *)qName 
			attributes:(NSDictionary *)attributeDict
{
	//NSLog( @"START element:%@ uri:%@ qual:%@", elementName, namespaceURI, qName );
	currentElementValue=@"";
	if ( found == FALSE && [elementName isEqualToString:nodeName] )
	{
		found = TRUE;
	}
	currentElementName=elementName;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
	//NSLog( @"END element:%@ uri:%@ qual:%@ currName=%@ currVal=%@", elementName, namespaceURI, qName, currentElementName, currentElementValue );

	
	if (currentElementName.length > 0 && found )
	{
		[result setObject:currentElementValue forKey:currentElementName];
		//NSLog( @"Added %@ -> %@", currentElementName, currentElementValue );
	}
	currentElementName=@"";
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	currentElementValue= [NSString stringWithString:string];
	//NSLog(@"Value=%@", string );
}

@end
