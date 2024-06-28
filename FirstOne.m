//
//  FirstOne.m
//  Javelin3
//
//  Created by Novica Radonic on 31.05.2023..
//

#import "FirstOne.h"
#import "Version.h"

@interface FirstOne ()

@end

@implementation FirstOne

- (id)initWithParameter:(NSString*)sParameter
{
	self = [[FirstOne alloc] initWithWindowNibName:@"FirstOne"];
	if (self) 
	{
		// Initialization code here.
		_recents = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
		_colorBackground = [NSColor colorWithCalibratedRed:0.0f 
													 green:0.0f 
													  blue:0.0f 
													 alpha:1];
	}
	
	return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	self.window.backgroundColor = _colorBackground;
	
	[_lblVer setBackgroundColor:_colorBackground];
	[_lblVer setStringValue:[Version getAppNameAndVersion]];
	[_lblVer setTextColor:NSColor.whiteColor];
	
	[_lblCopyright setBackgroundColor:_colorBackground];
	[_lblCopyright setStringValue:[NSString stringWithFormat:@"(c) %@", [Version company]]];
	[_lblCopyright setTextColor:NSColor.whiteColor];
	
	[_lblTitle setBackgroundColor:_colorBackground];
	[_lblText setBackgroundColor:_colorBackground];
	[_lblText setTextColor:NSColor.whiteColor];
	
	[_table setDoubleAction:@selector(doubleClick:)];
	[_table setDataSource:self];
	[_table setDelegate:self];
/*	NSArray<NSView*>* views = _table.headerView.subviews;
	for( int i=0; i<views.count; i++ )
	{
		NSView* vv = views[i];
		vv.window.backgroundColor = NSColor.redColor;
	}*/
	
	//[_btnQuit setBordered:NO];
	[[_btnQuit cell] setBackgroundColor:[NSColor colorWithRed:0.6f green:0 blue:0 alpha:1]];
	[[_btnDocs cell] setBackgroundColor:NSColor.darkGrayColor];
	[[_btnCats cell] setBackgroundColor:NSColor.darkGrayColor];
	[[_btnDown cell] setBackgroundColor:NSColor.darkGrayColor];
	[[_btnHelp cell] setBackgroundColor:NSColor.darkGrayColor];
	[[_btnContact cell] setBackgroundColor:NSColor.darkGrayColor];
	[[_btnGuide cell] setBackgroundColor:NSColor.darkGrayColor];
	
	//[[_btnQuit cell] setColor:NSColor.whiteColor];
	[self setButton:_btnQuit fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnDocs fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnCats fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnDown fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnHelp fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnContact fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnGuide fontColor:[NSColor whiteColor]] ;
	[self setButton:_btnQuit fontColor:[NSColor whiteColor]] ;
}

-(void) setButton:(NSButton *)button fontColor:(NSColor *)color 
{
	NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitle]];
	[colorTitle addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, button.attributedTitle.length)];
	[button setAttributedTitle:colorTitle];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	//NSLog(@"Becomes a key");
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
	//NSLog(@"Becomes main");
	[self refreshTable];
}

- (void) refreshTable
{
	_recents = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	[_table reloadData];
}

-(IBAction) doubleClick:(id)sender
{
	NSTableView* t = (NSTableView*)sender;
	long row = [t selectedRow];
	if ( row>=0 && row<_recents.count)
	{
//		NSString* rrr = _recents[row].fi;
//		NSURL* url = [NSURL URLWithString:_recents[row].fileURL];

		//[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:nil];
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:_recents[row].filePathURL
																			   display:YES completionHandler:
		 ^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) 
		 {
			[self refreshTable];
		 }];
	}
}

- (IBAction) contact:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.drumlinsecurity.com/contact.php"]];
}

- (IBAction)openDrumlinWeb:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.drumlinsecurity.com"]];
}

- (IBAction)openDocument:(id)sender
{
	[[NSDocumentController sharedDocumentController] openDocument:nil];
}

- (IBAction) openUserGuide:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.drumlinsecurity.com/pdf/JM3userguide.pdf"]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return _recents.count;
}

- (IBAction) quit:(id)sender
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Are you sure you want to quit Javelin?"];
	[alert setInformativeText:@"All your files will be closed"];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setAlertStyle:NSWarningAlertStyle];

	[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
		if (returnCode != NSAlertSecondButtonReturn) {
			[NSApp terminate:nil];
			return;
		}
		
		NSLog(@"This project was deleted!");
	}];
}

// NSTableViewDelegate Protocol Method

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSLog(@"%@", _recents[row].path);
	[cell setStringValue:_recents[row].path];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *identifier = tableColumn.identifier;
	NSTableCellView *cell = [tableView makeViewWithIdentifier:identifier owner:self];
	if ([identifier isEqualToString:@"File"]) {
		cell.textField.stringValue = [_recents[row].path lastPathComponent];
	} else if ([identifier isEqualToString:@"Path"]){
		cell.textField.stringValue = _recents[row].path;
	} else {
		cell.textField.stringValue = @"Error";
	}
	cell.backgroundStyle = NSBackgroundStyleDark;
	//cell.textField.backgroundColor = NSColor.redColor;//_colorBackground;
	cell.textField.textColor = NSColor.whiteColor;//NSColor.lightGrayColor;
	//[[cell textField] setBackgroundColor:[NSColor redColor]];
	NSTableRowView* rowView = [tableView rowViewAtRow:row makeIfNecessary:NO];
	if ( row%2 == 1)
		[rowView setBackgroundColor:_colorBackground];
	else
		[rowView setBackgroundColor:NSColor.darkGrayColor];
	tableView.backgroundColor = _colorBackground;
	//tableView.headerView.  .window.backgroundColor = NSColor.darkGrayColor;
	return cell;
}

@end
