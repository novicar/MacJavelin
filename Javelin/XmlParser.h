//
//  XmlParser.h
//  Javelin
//
//  Created by harry on 8/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

/*@interface myElement : NSObject
{
	NSMutableDictionary* parentDict;
	NSMutableDictionary* valueDict;
}

@property (nonatomic, retain) NSMutableDictionary *parentDict;
@property (nonatomic, retain) NSMutableDictionary *valueDict;

@end
*/
@interface XmlParser : NSObject <NSXMLParserDelegate> 
{
	NSMutableDictionary *result;
	NSString			*nodeName;
	NSString			*currentElementName;
	NSString			*currentElementValue;
	BOOL				found;
}

@property (nonatomic, retain) NSMutableDictionary *result;
//@property (nonatomic, retain) NSString *nodeName;

- (id) initWithName: (NSString*)name;
- (void)parserDidStartDocument:(NSXMLParser *)parser;
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;

@end