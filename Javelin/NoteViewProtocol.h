//
//  NoteViewProtocol.h
//  JavelinM
//
//  Created by Novica Radonic on 11/05/2017.
//
//

#ifndef NoteViewProtocol_h
#define NoteViewProtocol_h

@class JAnnotation;

@protocol NoteViewProtocol <NSObject>
-(void)itemDoubleClicked:(JAnnotation*)annot;
-(void)deleteNote:(JAnnotation*)annot;
-(void)exportAllNotes;
@end

#endif /* NoteViewProtocol_h */
