//
//  SKTypeSelectHelper.h
//  Skim
//
//  Created by Christiaan Hofman on 8/21/07.
/*
 This software is Copyright (c) 2007-2016
 Christiaan Hofman. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Christiaan Hofman nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSInteger, SKTypeSelectMatchOption) {
    SKPrefixMatch,
    SKSubstringMatch,
    SKFullStringMatch
};

@protocol SKTypeSelectDelegate;

@interface SKTypeSelectHelper : NSObject <NSTextViewDelegate> {
    id <SKTypeSelectDelegate> delegatex;
    SKTypeSelectMatchOption matchOption;
    BOOL isProcessing;
    NSArray *searchCache;
    NSString *searchString;
    NSTimer *timer;
}

@property (nonatomic, assign) id <SKTypeSelectDelegate> delegate;
@property (nonatomic) SKTypeSelectMatchOption matchOption;

+ (id)typeSelectHelper;
+ (id)typeSelectHelperWithMatchOption:(SKTypeSelectMatchOption)aMatchOption;

- (id)initWithMatchOption:(SKTypeSelectMatchOption)aMatchOption;

- (void)rebuildTypeSelectSearchCache;

- (BOOL)handleEvent:(NSEvent *)keyEvent;

@end


@protocol SKTypeSelectDelegate <NSObject>

- (NSArray *)typeSelectHelperSelectionStrings:(SKTypeSelectHelper *)typeSelectHelper; // required
- (NSUInteger)typeSelectHelperCurrentlySelectedIndex:(SKTypeSelectHelper *)typeSelectHelper; // required
- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper selectItemAtIndex:(NSUInteger)itemIndex; // required

@optional

- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper didFailToFindMatchForSearchString:(NSString *)searchString; // optional
- (void)typeSelectHelper:(SKTypeSelectHelper *)typeSelectHelper updateSearchString:(NSString *)searchString; // optional

@end
