//
//  SHRGraphic.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/8/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IIgsGraphic.h"


@interface SHRGraphic : IIgsGraphic {
	NSData *scbsData;
}

//@property (assign) u_int16_t numScanLines;
@property (retain) NSData *scbsData;

- (id)initWithContentsOfURL:(NSURL *)url;
- (BOOL)load:(NSURL *)url;
- (BOOL)unpack:(NSData *)fileData;

@end
