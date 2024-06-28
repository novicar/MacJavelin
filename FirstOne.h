//
//  FirstOne.h
//  Javelin3
//
//  Created by Novica Radonic on 31.05.2023..
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FirstOne : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTextField* _lblVer;
	IBOutlet NSTextField* _lblCopyright;
	IBOutlet NSTableView* _table;
	IBOutlet NSTextField* _lblTitle;
	IBOutlet NSTextField* _lblText;
	IBOutlet NSButton*	  _btnQuit;
	
	IBOutlet NSButton*	  _btnDocs;
	IBOutlet NSButton*	  _btnCats;
	IBOutlet NSButton*	  _btnDown;

	IBOutlet NSButton*	  _btnGuide;
	IBOutlet NSButton*	  _btnHelp;
	IBOutlet NSButton*	  _btnContact;
	
	NSArray<NSURL*>*      _recents;
	NSColor*			  _colorBackground;
}


- (id)initWithParameter:(NSString*)sParameter;

-(void) setButton:(NSButton *)button fontColor:(NSColor *)color;

- (IBAction) openDrumlinWeb:(id)sender;
- (IBAction) openDocument:(id)sender;
- (IBAction) openUserGuide:(id)sender;
- (IBAction) doubleClick:(id)sender;
- (IBAction) quit:(id)sender;
- (IBAction) contact:(id)sender;

- (void) refreshTable;
@end

NS_ASSUME_NONNULL_END
