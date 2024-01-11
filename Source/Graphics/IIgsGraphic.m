//
//  IIgsGraphic.m
//  IIGSGraphicsConverter
//
//  Created by mark lim on 5/7/17.
//  Copyright 2017 IncrementalInnovation. All rights reserved.

#import "IIgsGraphic.h"

@implementation IIgsGraphic

@synthesize pathURL;
@synthesize numColorTables;
@synthesize pixelState;
@synthesize colorData;
@synthesize pixelData;

// This method is always called when a new/old graphic is instantiated
// since it is the super-class of all AppleIIGS graphics
- (id)init
{
	self = [super init];
	if (self)
	{
		pathURL = nil;			// The sub-class must set this
		pixelState = unknown;
	}
	return self;
}

- (void)dealloc
{
	if (colorData)
		[colorData release];
	if (pixelData)
		[pixelData release];
    if (pathURL != nil)
        [pathURL release];
	[super dealloc];
}

// Sub-classes to override this method
- (BOOL)convertFrom:(IIgsGraphic *)srcGraphic
{
	return YES;
}

// Sub-classes should override this method.
- (BOOL)writeToFile:(NSError **)errorPtr
{
	return YES;
}
@end
