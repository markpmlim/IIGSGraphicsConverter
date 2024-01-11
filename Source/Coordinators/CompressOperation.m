//
//  ConvertOperations.m
//  IIGSGraphicsConverter
//
//  Created by mark lim on 4/6/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "CompressOperation.h"
#import "ConvertProgressWinController.h"
#import "BrooksGraphic.h"
#import "APFGraphic.h"
#import "SHRGraphic.h"
#import "AppDelegate.h"
#import "Encoder_PackBytes.h"
#import "Encoder_LZWPack.h"
#import "Encoder_HackBytes.h"


@implementation CompressOperation

@synthesize fileURLs;
@synthesize destinationURL;
@synthesize delegate;

- (id)initWithURLs:(NSArray *)urls
withDestinationURL:(NSURL *)destURL
       andDelegate:(ConvertProgressWinController *)del
{
	self = [super init];
	if (self)
	{
		self.fileURLs = urls;
		self.destinationURL = destURL;	// folder
		self.delegate = del;
	}
	return self;
}

- (void)dealloc
{
	if (self.fileURLs != nil)
		self.fileURLs = nil;
	if (self.destinationURL != nil)
		self.destinationURL = nil;
	if (self.delegate != nil)
		self.delegate = nil;
	[super dealloc];
}

// We just compress the entire file at one go rather than 
// unpack into various components. srcFormat is not required
// A destination format of apf_format is handled separately since
// it involves separating the data from the original file into
// 2 or more blobs of data and then merging them into an APF file.
// Reference: APFGraphic.m
- (void)compressGraphicContents:(NSData *)fileData
                          atURL:(NSURL *)url
            toDestinationFormat:(FileFormat)destFormat

{
	//NSLog(@"convertGraphic");
	CompressionAlgorithm algo = [(AppDelegate *)[NSApp delegate] selectedAlgo];
	NSString *fileName = [[[url path] lastPathComponent] stringByDeletingPathExtension];
	NSData *compressedData = nil;

	// Call the encoder using the file contents
	if (algo == hack_bytes)
	{
		//NSLog(@"hack_bytes to compress shr/brooks to pak");
		compressedData = [Encoder hackBytes: fileData];
		fileName = [fileName stringByAppendingPathExtension:@"PAK"];
	}
	else if (algo == pack_bytes) {
		//NSLog(@"pack_bytes to compress shr/brooks to pak");
		compressedData = [Encoder packBytes: fileData];
		fileName = [fileName stringByAppendingPathExtension:@"PAK"];
	}
	else if (algo == lzw_pack) {
		//NSLog(@"lzw to compress shr/brooks to dg");
		compressedData = [Encoder lzwPack: fileData];
		fileName = [fileName stringByAppendingPathExtension:@"DG"];
	}
	NSString *destPath = [[destinationURL path] stringByAppendingPathComponent:fileName];
	NSURL *destURL = [NSURL fileURLWithPath:destPath];
	[compressedData writeToURL:destURL
					atomically:YES];
	unsigned short fType = 0xc0;        // PNT
	unsigned short auxType = 0x00;
	switch (destFormat) {
		case pak_format:
			auxType = 0x0001;
			break;
		case dg_format:
			auxType = 0x8005;
			break;
		default:
			break;
	}
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *errOut = nil;
	NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:destPath
														   error:&errOut];
	NSMutableDictionary *newFileAttr = [NSMutableDictionary dictionary];
	[newFileAttr addEntriesFromDictionary:fileAttr];
	// Set the creator and hfs code
	OSType typeCode = 0x70000000 + (fType<<16) + auxType;
	OSType creatorCode = 'pdos';
	[newFileAttr setObject:[NSNumber numberWithInt:typeCode]
					forKey:NSFileHFSTypeCode];
	[newFileAttr setObject:[NSNumber numberWithInt:creatorCode]
					forKey:NSFileHFSCreatorCode];
	[fileManager setAttributes:newFileAttr
				  ofItemAtPath:destPath
						 error:&errOut];
}

// Since we are not calculating any file sizes, we don't need to twirl
// the progress indicator.
- (void)main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if ([NSThread isMainThread])
		[delegate didBeginFileConversion];
	else
	{
		[delegate performSelectorOnMainThread:@selector(didBeginFileConversion)
								   withObject:nil
								waitUntilDone:NO];
	}

	FileFormat srcFormat = [(AppDelegate *)[NSApp delegate] sourceFormat];
	FileFormat destFormat = [(AppDelegate *)[NSApp delegate] destinationFormat];
	unsigned long long fileCount = 0;
	for (NSURL *url in fileURLs)
	{
		IIgsGraphic *srcGraphic = nil;
		// We need to identify graphic so that the correct class can be initialized!
		// KIV: let the src doc check its file size 
		if (srcFormat == shr_format)
		{
			if (destFormat == pak_format || destFormat == dg_format)
			{
                NSData *fileData = [NSData dataWithContentsOfURL:url];
                // Just a simple check to validate an SHR graphic
                if (!([fileData length] != 32768 ||
                      [fileData length] != 33280))
                {
                    continue;       // skip this file
                }
				[self compressGraphicContents:fileData
										atURL:url
						  toDestinationFormat:destFormat];
				continue;			// next file please
			}
			else
			{
				// Blob of data needs to be separated into its various components
                // We will be converting an unpacked SHR graphic to APF
                // srcGraphic is an object of the class SHRGraphic.
				srcGraphic = [[[SHRGraphic alloc] initWithContentsOfURL:url] autorelease];
			}
		}
		else if (srcFormat == brooks_format)
		{
			if (destFormat == pak_format || destFormat == dg_format)
			{
                NSData *fileData = [NSData dataWithContentsOfURL:url];
                // Just a simple check to validate an Brooks graphic
                if ([fileData length] != 38400)
                {
                    continue;       // skip this file
                }
				[self compressGraphicContents:fileData
										atURL:url
						  toDestinationFormat:destFormat];
				continue;			// next file please
			}
			else
			{
				// Blob of data needs to be separated into its various components
                // We will be converting an unpacked Brooks graphic to APF
                // srcGraphic is an object of the class BrooksGraphic
				srcGraphic = [[[BrooksGraphic alloc] initWithContentsOfURL:url] autorelease];
			}
		}
		else
			continue;				// skip this on invalid file size

		if (srcGraphic != nil)
		{   // If we get here, then the destFormat should be APF.
            // The data of the various components is ready to be merged.
			NSString *fileName = [[[url path] lastPathComponent] stringByDeletingPathExtension];
			NSString *destPath = [[destinationURL path] stringByAppendingPathComponent:fileName];
			NSURL *destURL = [NSURL fileURLWithPath:destPath];
			IIgsGraphic *destGraphic = [[[APFGraphic alloc] initWithURL:destURL] autorelease];
			if (destGraphic)
			{
                // srcGraphic is either an object of the class SHRGraphic or BrooksGraphic
                // and destGraphic is an object of the class APFGraphic
				[destGraphic convertFrom:srcGraphic];
				NSError *err;
				[destGraphic writeToFile:&err];
			}

			fileCount++;

			if ([NSThread isMainThread])
				[delegate didUpdateFileCount:[NSNumber numberWithUnsignedLongLong:fileCount]];
			else
			{
				[delegate performSelectorOnMainThread:@selector(didUpdateFileCount:)
										   withObject:[NSNumber numberWithUnsignedLongLong:fileCount]
										waitUntilDone:NO];

			}
		}
		if ([self isCancelled])
		{
			goto bailOut;
		}
	}
	if ([NSThread isMainThread])
		[delegate didEndFileConversion];
	else
	{
		[delegate performSelectorOnMainThread:@selector(didEndFileConversion)
								   withObject:nil
								waitUntilDone:NO];
	}
bailOut:
	[pool drain];
}	
@end
