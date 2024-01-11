//
//  APFGraphic.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 5/7/17.
//  Copyright 2017 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "UserDefines.h"
#import "IIgsGraphic.h"

// Destination Format
@interface APFGraphic : IIgsGraphic {
	NSData		*bgColorData;		// 2 bytes
	NSData		*patternsData;		// 32 x 16 bytes
	NSData		*scanLineDirData;	// 32 x numScanLines bytes
	NSData		*multiPaletteData;
	u_int16_t	numScanLines;		// 200, 396 or any size
	u_int16_t	pixelsPerScanLine;	// may be weird values
	u_int16_t	masterMode;			// need further investigation
}

@property (retain) NSData		*bgColorData;
@property (retain) NSData		*patternsData;
@property (retain) NSData		*scanLineDirData;
@property (retain) NSData		*multiPaletteData;
@property (assign) u_int16_t	numScanLines;
@property (assign) u_int16_t	pixelsPerScanLine;
@property (assign) u_int16_t	masterMode;

- (id)initWithURL:(NSURL *)url;
- (BOOL)writeToFile:(NSError **)errorPtr;
@end
