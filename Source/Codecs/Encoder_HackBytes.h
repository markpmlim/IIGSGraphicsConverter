/*
 *  Encoder_HackBytes.h
 *  IIGSGraphicsConverter
 *
 *  Created by mark lim on 8/10/16.
 *  Copyright 2016 IncrementalInnovation. All rights reserved.
 *
 */

#import "Encoder.h"
// Category
@interface Encoder(HackBytes)

+ (NSData *)hackBytes:(NSData *)fileData;
@end