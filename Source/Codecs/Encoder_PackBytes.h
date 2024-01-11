//
//  Encode_PackBytes.h
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/5/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Encoder.h"

// Category
@interface Encoder(PackBytes)

+ (NSData *)packBytes:(NSData *)fileData;
@end
