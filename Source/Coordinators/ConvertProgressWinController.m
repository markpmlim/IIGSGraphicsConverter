//
//  ConvertProgressWinController.m
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/6/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "ConvertProgressWinController.h"
#import "CompressOperation.h"

const double kMaxProgress = 100.0;

@implementation ConvertProgressWinController
@synthesize compressOperationQueue;	
@synthesize progressIndicator;
@synthesize runningMessage;	
@synthesize shouldAnimate;
@synthesize isIndeterminate;
@synthesize progress;
@synthesize remainingTime;
@synthesize startTime;
@synthesize fileCount;
@synthesize totalFileCount;

// Designated initializer - will be called by convenience initializers
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
	if (self)
	{
		self.compressOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
		[self.compressOperationQueue setMaxConcurrentOperationCount:1];
		
	}
	return self;
}

- (void)dealloc
{
	if (self.compressOperationQueue)
		self.compressOperationQueue = nil;
	if (self.startTime)
		self.startTime = nil;
	if (self.runningMessage)
		self.runningMessage = nil;
	[super dealloc];
}

// Convert Graphic files and write the converted files to the destination URL 
- (BOOL)compressItemsAtURLs:(NSArray *)urls
             destinationURL:(NSURL *)destURL
{

	CompressOperation *op = [[CompressOperation alloc] initWithURLs:urls
											   withDestinationURL:destURL
													  andDelegate:self];
	[self.compressOperationQueue addOperation:op];
	[op release];

	self.totalFileCount = [urls count];
	self.fileCount = 0;

	return YES;
}

// Stop the file conversion process
- (IBAction)stop:(id) sender
{
	//NSLog(@"stop");
    self.progress = 0.0;
    self.remainingTime = 0.0;
    self.isIndeterminate = YES;
    self.runningMessage = NSLocalizedString(@"Cancelling conversion, please wait...", @"cancel message");
	[self.compressOperationQueue cancelAllOperations];
	[self.compressOperationQueue waitUntilAllOperationsAreFinished];
	//isIndeterminate = NO;
	//[progressIndicator stopAnimation:self];
}

- (void)startTwirling
{
	self.isIndeterminate = YES;
	self.shouldAnimate = YES;
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
}

- (void)twirlBar
{
	[progressIndicator displayIfNeeded];
}

- (void)stopTwirling
{
	self.isIndeterminate = NO;
	[progressIndicator stopAnimation:self];
}

- (void)didBeginFileConversion
{
	self.isIndeterminate = NO;
	self.progress = 0.0;
	self.runningMessage = NSLocalizedString(@"Starting File Conversion...", @"Start Conversion message");
	self.remainingTime = NSTimeIntervalSince1970;
	self.startTime = [NSDate date];
}

- (void)didEndFileConversion
{
	self.progress = kMaxProgress;
	self.remainingTime = 0.0;
	self.isIndeterminate = NO;
	self.runningMessage = [NSString stringWithFormat:NSLocalizedString(@"Finish converting %lld file(s)",
															   @"Finish message"),
						   self.totalFileCount];

}

- (void)didUpdateFileCount:(NSNumber *)count
{
	self.fileCount = [count unsignedLongLongValue];
	self.isIndeterminate = (self.fileCount == self.totalFileCount);	// false if fileCount is non-zero
	if (self.fileCount > 0)
		self.progress = kMaxProgress * ((double)self.fileCount) / ((double)self.totalFileCount);
	NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.startTime];
	NSTimeInterval rt = (100.0 * elapsed / self.progress) - elapsed;
	if (rt < self.remainingTime)
		self.remainingTime = rt;
	self.runningMessage = [NSString stringWithFormat:NSLocalizedString(@"Converted %lld file(s) of %lld file(s)",
															   @"Update message"),
                           self.fileCount, self.totalFileCount];
}
@end
