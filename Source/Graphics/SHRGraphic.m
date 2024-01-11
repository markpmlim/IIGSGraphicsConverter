//
//  SHRGraphic.m
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/8/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "APFGraphic.h"
#import "SHRGraphic.h"


@implementation SHRGraphic

//@synthesize numScanLines;
@synthesize scbsData;

// This method is called when we open an existing document, extract its data
// contents and pass it as a parameter to this initializer
- (id)initWithContentsOfURL:(NSURL *)url
{
	//NSLog(@"initWithContentsOfURL SHRDoc");
	self = [super init];		// calls its super-class IIgsGraphics
	if (self)
	{
		if (![self load:url])
		{
			// Cocoa Fundamentals Guide: Cocoa Objects
			[self release];		// added
			return nil;
		}
		self.pathURL = url;
	}
	return self;
}

- (void)dealloc
{
	if (self.scbsData)
		self.scbsData = nil;
    if (self.pathURL)
        self.pathURL = nil;
	[super dealloc];
}

// This method loads the entire SHR file and proceeds to unpack its components.
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

//  
- (BOOL)unpack:(NSData *)fileData
{
	BOOL status = NO;

	if (!([fileData length] != 32768 ||
		  [fileData length] != 33280))
	{
		NSLog(@"Not likely to be an unpacked IIgs screen");
		goto bailOut;
		// Note: no instance variables specific to this class have been initialized
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

	// 56 unused bytes were also saved but we ignore them
	currOffset = offsetScbTable;                // 32 000 (0x7D00)
	size = kRowsPerScreen;						// 200 of these
	range = NSMakeRange(currOffset, size);
	@try {
		self.scbsData = [fileData subdataWithRange:range];
	}
	@catch (NSException * e) {
		NSLog(@"Problem getting the data of the scbs:%@", e);
		goto bailOut;
	}

	currOffset = offsetColorTable;
	size = sizeof(IIgsColorTable) * 16;			// 32 x 16 bytes
	range = NSMakeRange(currOffset, size);
	@try {
		self.colorData = [fileData subdataWithRange:range];
	}
	@catch (NSException * e) {
		NSLog(@"Problem getting the data of the 16 color tables:%@", e);
		goto bailOut;
	}

	self.numColorTables = 16;
	pixelState = unpacked;			// always
	status = YES;
bailOut:
	return status;
}

@end
