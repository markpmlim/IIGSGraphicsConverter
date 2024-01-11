//
//  ConvertOperations.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/6/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ConvertProgressWinController;

@interface CompressOperation : NSOperation {
	NSArray *fileURLs;
	NSURL *destinationURL;
	ConvertProgressWinController *delegate;
}

@property (retain) NSArray *fileURLs;
@property (retain) NSURL *destinationURL;
@property (retain) ConvertProgressWinController *delegate;

- (id)initWithURLs:(NSArray *)urls
withDestinationURL:(NSURL *)destURL
       andDelegate:(ConvertProgressWinController *)del;

@end
