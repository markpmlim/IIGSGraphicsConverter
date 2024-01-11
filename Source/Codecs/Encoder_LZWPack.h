/*
 *  Encoder_LZWPack.h
 *  IIGSGraphicsConverter
 *
 *  Created by mark lim on 8/10/16.
 *  Copyright 2016 IncrementalInnovation. All rights reserved.
 *
 */

#import "Encoder.h"
// Category
@interface Encoder (LZWPack)

+ (NSData *)lzwPack:(NSData *)fileData;
@end