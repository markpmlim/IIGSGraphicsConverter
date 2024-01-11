//
//  AppDelegate.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/6/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"
		
@class ConvertProgressWinController;

//@interface AppDelegate : NSObject <NSApplicationDelegate> {
@interface AppDelegate : NSObject {
	IBOutlet NSView					*sourceView;
	IBOutlet NSView					*destinationView;
	ConvertProgressWinController	*progressWinController;
	CompressionAlgorithm			selectedAlgo;
	FileFormat						srcFormat;				// instance var
	FileFormat						destinationFormat;
}

@property (retain) IBOutlet NSView				*sourceView;
@property (retain) IBOutlet NSView				*destinationView;
@property (retain) ConvertProgressWinController *progressWinController;
@property (assign) CompressionAlgorithm			selectedAlgo;
@property (assign) FileFormat					destinationFormat;

- (IBAction)compress:(id)sender;
- (IBAction)openHelp:(id)sender;

- (int)destinationTab;
// NB. the following are not generated properties.
// Getter and Setter methods for the instance variable `srcFormat`
// These 2 methods are bind to a Popup Button
- (FileFormat)sourceFormat;
- (void)setSourceFormat:(FileFormat)fileFormat;

@end
