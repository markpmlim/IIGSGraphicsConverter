//
//  BrooksGraphic.m
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/8/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "BrooksGraphic.h"
#import "Encoder_PackBytes.h"
#import "Encoder_HackBytes.h"
#import "AppDelegate.h"

@implementation BrooksGraphic

// This method is called when we open an existing document at the given URL
// pass as a parameter to this initializer. 
- (id)initWithContentsOfURL:(NSURL *)url;
{
	//NSLog(@"initWithData Brooks");
	self = [super init];
	if (self)
	{
		if (![self load:url])
		{
			// Cocoa Fundamentals Guide: Cocoa Objects
			[self release];		// added
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	// Just pass to super class
	[super dealloc];
}

// Unpacks the 3200 file into its components which is
// a 32 000-byte pixel map (of indices) and 200 color tables.
// Both components are encapsulated as instances of NSData.
// The size of each color table is 16 color words,
// each color word being 16 bits. So a color table is 32 bytes in size.
- (BOOL)unpack:(NSData *)fileData
{
	BOOL status = NO;
	
	if ([fileData length] != 38400)
	{
		NSLog(@"Not likely to be an unpacked 3200 color image");
		goto bailOut;
	}

	unsigned int size = kBytesPerScanline * kRowsPerScreen;
	unsigned int currOffset = 0;
	NSRange range = NSMakeRange(currOffset, size);
	@try {
		self.pixelData = [fileData subdataWithRange:range];
	}
	@catch (NSException * e) {
		NSLog(@"Problem getting the data of the pixel map:%@", e);
		goto bailOut;
	}

	currOffset = offsetScbTable;			// 32 000 (0x7D00)
	size = sizeof(IIgsColorTable) * 200;	// 32 x 200 bytes
	range = NSMakeRange(currOffset, size);
	@try {
		self.colorData = [fileData subdataWithRange:range];
	}
	@catch (NSException * e) {
		NSLog(@"Problem getting the data of the 200 color tables:%@", e);
		goto bailOut;
	}

	// The 200 color palettes can be used to initialise a MULTIPAL data object.
	self.numColorTables = 200;
	pixelState = unpacked;					// Flag its state
	status = YES;
bailOut:
	return status;
}

// This method loads the entire 3200 file and proceeds to unpack its components.
- (BOOL)load:(NSURL *)url {
	NSError *outErr = nil;
	NSData *dataContents = [NSData dataWithContentsOfURL:url
												 options:NSUncachedRead
												   error:&outErr];
	if (outErr != nil) {
		NSLog(@"Error %@ reading file contents of %@", outErr, url);
		return NO;
	}
	if (![self unpack:dataContents]) {
        // The unpack method will use the file size as validation.
		NSLog(@"Error unpacking file contents of %@", url);
		return NO;
	}
	return YES;
}

@end
