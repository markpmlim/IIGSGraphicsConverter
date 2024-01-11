//
//  BrooksGraphic.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/8/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IIgsGraphic.h"

@interface BrooksGraphic : IIgsGraphic {
	// no instance vars need to be declare since this format has
	// 1) 200 color tables/palette (6 400 bytes)
	// 2) 32 000-bytes  pixelData
}

- (id)initWithContentsOfURL:(NSURL *)url;
- (BOOL)unpack:(NSData *)fileData;
- (BOOL)load:(NSURL *)url;

@end
