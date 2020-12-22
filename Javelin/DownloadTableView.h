//
//  DownloadTableView.h
//  Javelin
//
//  Created by harry on 27/08/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface DownloadTableView : NSTableView
{
	int		m_row;
}


@property(nonatomic,readonly) int rightClickedRow;

@end
