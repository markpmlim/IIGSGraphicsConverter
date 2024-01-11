//
//  ConvertProgressWinController.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/6/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ConvertProgressWinController : NSWindowController {
	NSOperationQueue				*compressOperationQueue;
	IBOutlet NSProgressIndicator	*progressIndicator;	
	NSString						*runningMessage;
	NSDate							*startTime;
	NSTimeInterval					remainingTime;
	double							progress;
	BOOL							shouldAnimate;		// YES = the NSProgressIndicator should animate
	BOOL							isIndeterminate;	// YES = show a twirling barpole
	unsigned long long				fileCount;			// # of files converted thus far
	unsigned long long				totalFileCount;		// # of files to be converted
}

// Looks like all these must be declared as properties since the progress
// bar is likely to be called from a secondary thread.
@property (retain) NSOperationQueue		*compressOperationQueue;	
@property (retain) NSDate				*startTime;
@property (copy) NSString				*runningMessage;	
@property (assign) NSProgressIndicator	*progressIndicator;	
@property (assign) NSTimeInterval		remainingTime;
@property (assign) BOOL					shouldAnimate;
@property (assign) BOOL					isIndeterminate;
@property (assign) double				progress;
@property (assign) unsigned long long	fileCount;
@property (assign) unsigned long long	totalFileCount;

- (IBAction) stop:(id) sender;

- (void)startTwirling;
- (void)twirlBar;
- (void)stopTwirling;
- (void)didBeginFileConversion;
- (void)didEndFileConversion;
- (void)didUpdateFileCount:(NSNumber *)count;

- (BOOL)compressItemsAtURLs:(NSArray *)urls
             destinationURL:(NSURL *)destURL;

@end
