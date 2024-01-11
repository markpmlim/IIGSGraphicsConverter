//
//  APFGraphic.m
//  IIGSGraphicsConverter
//
//  Created by mark lim on 5/7/17.
//  Copyright 2017 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "APFGraphic.h"
#import "BrooksGraphic.h"
#import "SHRGraphic.h"
#import "Encoder_HackBytes.h"
#import "Encoder_PackBytes.h"

extern NSData *mainChunk;
extern NSData *multiPatChunk;
extern NSData *patternsChunk;
extern NSData *palChunk;
extern NSData *maskChunk;
extern NSData *scibChunk;
extern NSData *bgChunk;



@implementation APFGraphic

// Properties that are specific to APF Graphic class.
@synthesize bgColorData;
@synthesize patternsData;
@synthesize scanLineDirData;
@synthesize numScanLines;
@synthesize pixelsPerScanLine;
@synthesize masterMode;
@synthesize multiPaletteData;

- (id)initWithURL:(NSURL *)url
{
	//NSLog(@"initWithURL APFDoc");
	self = [super init];
	if (self)
	{
		NSString *path = [url path];
		path = [path stringByAppendingPathExtension:@"APF"];
		self.pathURL = [NSURL fileURLWithPath:path];
		//NSLog(@"%@", pathURL);
	}
	return self;
}

- (void)dealloc
{
	if (self.pathURL != nil)
		self.pathURL = nil;
	if (self.bgColorData != nil)
		self.bgColorData = nil;
	if (self.patternsData != nil)
		self.patternsData = nil;
	if (self.scanLineDirData != nil)
		self.scanLineDirData = nil;
	if (self.multiPaletteData != nil)
		self.multiPaletteData = nil;
	[super dealloc];
}

- (NSMutableData *)mainBlockData
{
	NSMutableData *blockData = [NSMutableData data];
	u_int32_t blockLen = 0;					// place holder
	[blockData appendBytes:(void *)&blockLen
					length:4];
	[blockData appendData:mainChunk];		// Kind
	u_int16_t tmp = NSSwapHostShortToLittle(masterMode);
	[blockData appendBytes:(void *)&tmp
					length:2];
	tmp = NSSwapHostShortToLittle(pixelsPerScanLine);
	[blockData appendBytes:(void *)&tmp
					length:2];
	tmp = NSSwapHostShortToLittle(numColorTables);					// can be 0
	[blockData appendBytes:(void *)&tmp
					length:2];
	[blockData appendData:colorData];		// ColorTableArray
	tmp = NSSwapHostShortToLittle(numScanLines);
	[blockData appendBytes:(void *)&tmp
					length:2];
	[blockData appendData:self.scanLineDirData];	// ScanLineDirectory
	[blockData appendData:pixelData];               // PackedScanlines
	// Finally set this block's length at the beginning of block
	NSRange range = NSMakeRange(0, 4);
	blockLen = NSSwapHostIntToLittle([blockData length]);
	[blockData replaceBytesInRange:range
						 withBytes:(void *)&blockLen
							length:4];
	//NSLog(@"%@", blockData);
	return blockData;
}

- (NSMutableData *)multiPalBlockData
{
	NSMutableData *blockData = [NSMutableData data];
	u_int32_t blockLen = 4 + [multiPatChunk length] + 2 + [self.multiPaletteData length];
	blockLen = NSSwapHostIntToLittle(blockLen);
	[blockData appendBytes:(void *)&blockLen
					length:4];
	[blockData appendData:multiPatChunk];
	// # of palettes or color tables can be computed
	u_int16_t tmp = [self.multiPaletteData length]/sizeof(IIgsColorTable);
	tmp = NSSwapHostShortToLittle(tmp);
	[blockData appendBytes:(void *)&tmp
					length:2];
	[blockData appendData:self.multiPaletteData];	// ColorTableArray
	//NSLog(@"# of patterns added:%d", tmp);
	//NSLog(@"%@", blockData);
	return blockData;
}

- (NSMutableData *)patternsBlockData
{
	NSMutableData *blockData = [NSMutableData data];
	u_int32_t blockLen = 4 + [patternsChunk length] + 2 + [self.patternsData length];
	blockLen = NSSwapHostIntToLittle(blockLen);
	[blockData appendBytes:(void *)&blockLen
					length:4];
	[blockData appendData:patternsChunk];
	u_int16_t tmp = [self.patternsData length]/sizeof(IIgsPattern);
	tmp = NSSwapHostShortToLittle(tmp);
	[blockData appendBytes:(void *)&tmp				// NumPats
					length:2];
	[blockData appendData:self.patternsData];		// PatternArray
	//NSLog(@"# of patterns added:%d", tmp);
	//NSLog(@"%@", blockData);
	return blockData;
}

/*
 Our custom block:
 Length				LongInt					- 4 bytes
 Kind				String "BACKGRDCOLOR"	- 13 bytes
 BackGroundColor	Integer					- 2 bytes
*/
- (NSMutableData *)bgBlockData
{
	NSMutableData *blockData = [NSMutableData data];
	u_int32_t blockLen = 4 + [bgChunk length] + [self.bgColorData length];	// place holder
	blockLen = NSSwapHostIntToLittle(blockLen);
	[blockData appendBytes:(void *)&blockLen
					length:4];
	[blockData appendData:bgChunk];
	[blockData appendData:self.bgColorData];
	//NSLog(@"added background block");
	return blockData;
}

// Construct one blob of data and write it out to the file
// It is assumed that if an instance of NSData is not created
// its value is NIL.
- (BOOL)writeToFile:(NSError **)errorPtr;
{
	NSMutableData *docData = [NSMutableData data];
	if (self.pixelData)
		[docData appendData:[self mainBlockData]];		// already encoded
	//NSLog(@"%@", docData);
	if ([self.patternsData length])
		[docData appendData:[self patternsBlockData]];
	if ([self.bgColorData length])
		[docData appendData:[self bgBlockData]];
	if ([self.multiPaletteData length])
		[docData appendData:[self multiPalBlockData]];
	//NSLog(@"writing to URL:%@", pathURL);
	BOOL result = [docData writeToURL:pathURL
						   atomically:YES];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = [pathURL path];
	NSDictionary *fileAttr = [fileManager attributesOfItemAtPath:path
														   error:errorPtr];
	NSMutableDictionary *newFileAttr = [NSMutableDictionary dictionary];
	[newFileAttr addEntriesFromDictionary:fileAttr];
	OSType typeCode = 0x70000000 + 0x00c00000 + 0x00000002;
	OSType creatorCode = 'pdos';
	[newFileAttr setObject:[NSNumber numberWithInt:typeCode]
					forKey:NSFileHFSTypeCode];
	[newFileAttr setObject:[NSNumber numberWithInt:creatorCode]
					forKey:NSFileHFSCreatorCode];
	[fileManager setAttributes:newFileAttr
				  ofItemAtPath:path
						 error:errorPtr];
	
	if (result)
		return YES;
	else
	{
		NSLog(@"Problem writing data");
		return NO;
	}
}

- (BOOL)convertFromSHR:(SHRGraphic *)srcGraphic
{
	//NSLog(@"convert SHR To APF");
	self.numColorTables = srcGraphic.numColorTables;	// Could be calculated
	self.colorData = srcGraphic.colorData;
	
	DirEntry entries[kRowsPerScreen];					// 200 of these
	NSUInteger currOffset = 0;
	NSMutableData *packedData = [NSMutableData data];
    // The compression algorithm should be hack_bytes or pack_bytes.
	CompressionAlgorithm algo = [(AppDelegate *)[NSApp delegate] selectedAlgo];
	Byte *scbs = (Byte *)[srcGraphic.scbsData bytes];
	for (int i=0; i<kRowsPerScreen; i++)
	{
		NSRange range = NSMakeRange(currOffset, kBytesPerScanline);
		NSData *lineData = [srcGraphic.pixelData subdataWithRange:range];
		NSData *packedLineData;
		if (algo == hack_bytes)
			packedLineData = [Encoder hackBytes:lineData];
		else
			packedLineData = [Encoder packBytes:lineData];
		entries[i].size = NSSwapHostShortToLittle([packedLineData length]);
		entries[i].modeWord = NSSwapHostShortToLittle(scbs[i]);
		currOffset += kBytesPerScanline;
		[packedData appendData:packedLineData];
	}
	self.pixelState = packed;
	self.pixelData = packedData;
	self.scanLineDirData = [NSData dataWithBytes:&entries
										  length:sizeof(DirEntry)*kRowsPerScreen];
	if ((scbs[0] & 0x80) == 0x00)
	{
		self.pixelsPerScanLine = 320;			// can be 640 -> look at scbs
		self.masterMode = scbs[0];				// 0x00 - 0x0f
	}
	else 
	{
		self.pixelsPerScanLine = 640;			// can be 640 -> look at scbs
		self.masterMode = scbs[0];				// 0x8z?
	}

	self.numScanLines = kRowsPerScreen;			// same for both 320 & 640 modes

	// KIV: Do we need to initialized these?
	self.patternsData = [NSMutableData data];	// use empty data objects
	self.bgColorData = [NSMutableData data];	// whose lengths = 0
	if (self.pixelData)
		return YES;
	else
		return NO;
}


- (BOOL)convertFrom3200:(BrooksGraphic *)srcGraphic
{
	//NSLog(@"APF convertFrom 3200:%@", srcGraphic);
	DirEntry entries[200];
	unsigned int currOffset = 0;
	NSRange range;
	NSMutableData *packedData = [NSMutableData data];
    // The compression algorithm should be hack_bytes or pack_bytes.
	CompressionAlgorithm algo = [(AppDelegate *)[NSApp delegate] selectedAlgo];
	for (int i=0; i<200; i++)
	{
		range = NSMakeRange(currOffset, kBytesPerScanline);
		NSData *lineData = [srcGraphic.pixelData subdataWithRange:range];
		NSData *packedLineData;
		if (algo == hack_bytes)
			packedLineData = [Encoder hackBytes:lineData];
		else
			packedLineData = [Encoder packBytes:lineData];
		entries[i].size = NSSwapHostShortToLittle([packedLineData length]);
		entries[i].modeWord = 0;
		currOffset += kBytesPerScanline;
		[packedData appendData:packedLineData];
	}
	self.pixelState = packed;
	self.pixelData = packedData;
	self.scanLineDirData = [NSData dataWithBytes:(void *)entries
										  length:sizeof(DirEntry)*200];

	// The 200 color tables are still in their original format
	IIgsColorTable colorTables[200];
	currOffset = 0;
	unsigned int size = sizeof(IIgsColorTable);
	for (int i=0; i<200; i++)
	{
		Byte colorBytes[32];			// buffer
		range = NSMakeRange(currOffset, size);
		[srcGraphic.colorData getBytes:(void *)colorBytes
								 range:range];
		// the color table entries is in reverse order
		for (int j=0; j < 16; ++j)
		{
			// The 16-bit color values are stored in Little Endian format
			u_int16_t colorWord = colorBytes[2*j] + (colorBytes[2*j+1] << 8);
			// APF expects the color values to be in Little Endian format
			// Color value for color 15 is stored first
			colorTables[i].colorEntries[15-j] = NSSwapHostShortToLittle(colorWord);
		}
		currOffset += size;
	}

	// Color entries are now in the order expected by APF
	self.multiPaletteData = [NSData dataWithBytes:colorTables
											  length:sizeof(IIgsColorTable) * 200];
	// Include a dummy IIgs color table (all zeroes)
	self.numColorTables = 1;
	Byte dummy[32];
	memset(dummy, 0x00, 32);
	self.colorData = [NSData dataWithBytes:(void *)dummy
									length:32];
	self.bgColorData = [NSData data];		// empty data object
	self.patternsData = [NSData data];		// --- ditto ---
	self.numScanLines = kRowsPerScreen;		// 200
	self.pixelsPerScanLine = 320;			// always
	self.masterMode = 0x00;					// ignored by APF viewers
	return YES;
}

// overridden method
- (BOOL)convertFrom:(IIgsGraphic *)srcGraphic
{
	if ([srcGraphic isKindOfClass: [APFGraphic class]])
		goto bailOut;
	if ([srcGraphic isKindOfClass: [BrooksGraphic class]])
		return [self convertFrom3200:(BrooksGraphic *)srcGraphic];
	if ([srcGraphic isKindOfClass: [SHRGraphic class]])
		return [self convertFromSHR:(SHRGraphic *)srcGraphic];
bailOut:
	return NO;
}
@end
