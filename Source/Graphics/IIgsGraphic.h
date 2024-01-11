//
//  IIgsGraphic.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 5/7/17.
//  Copyright 2017 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"
typedef enum
{
	unknown,
	unpacked,
	packed
} PixelState;

// This is the super class of all other Apple IIGS graphics
@interface IIgsGraphic : NSObject {
	NSURL		*pathURL;			// Set by sub-class
	u_int16_t	graphicMode;
	u_int16_t	numColorTables;		// This can be calculated [colorData length]/32
	PixelState	pixelState;
	NSData		*colorData;
	NSData		*pixelData;			// Can be packed or unpacked.
}

@property (retain) NSURL *pathURL;
@property (assign) u_int16_t numColorTables;
@property (assign) PixelState pixelState;
@property (retain) NSData *colorData;
@property (retain) NSData *pixelData;

- (BOOL)convertFrom:(IIgsGraphic *)srcGraphic;
- (BOOL)writeToFile:(NSError **)errorPtr;

@end
