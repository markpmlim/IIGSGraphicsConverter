#include <stdlib.h>
#import "Encoder_PackBytes.h"

static const unsigned int bitMasks[] = {
	0x0000, 0x0001, 0x0003, 0x0007,
	0x000f, 0x001f, 0x003f, 0x007f,
	0x00ff, 0x1ff, 0x3ff, 0x7ff, 0xfff
};

#define kTableSize		5021			// 9-12 bits
#define kLimit			4096			// 2 ^ 12
#define kShift			4
#define kMaxBits		12				// max # of bits for an lzw code

#define INITTABLE() {						\
	for (int k=0; k<kTableSize; ++k)		\
	{										\
		hashTable[k] = -1;					\
	}										\
	freeCode = clearCode + 2;				\
	currCodeSize = iniCodeSize;				\
	currMaxCode	= (1 << (iniCodeSize)) - 1;	\
};



// Basically, the code for a Dream Grafix Encoder can be modified from
// the source code of a GIF encoder. We just pass the entire file contents
// through the LZW compressor and some trailing 8-bit numbers.

// Stores the lzw code for a particular entry
int hashTable[kTableSize];
// For output purposes
int currCodeSize = 0;
unsigned short currMaxCode = 0;
unsigned short iniCodeSize = 9;
unsigned short clearCode;
unsigned short eofCode;
unsigned short freeCode = 0;

// The 2 vars below need to retain their values after each call to
// addCode:toData so that they are available for the next call (if any)
static int accumBits = 0;			// This var must be at least 32 bits in size
static int currBits = 0;

@implementation Encoder (LZW)


//===== output(code:) =====
// Add code to the instance of NSMutableData
+ (void)addCode:(unsigned short)code
         toData:(NSMutableData *)data
{
	Byte byte;
	
	// NB. the values in the entire array of bit masks are used
	accumBits &= bitMasks[currBits];
	if (currBits > 0)
	{
		accumBits |= code << currBits;
	}
	else
	{
		accumBits = code;
	}
	currBits += currCodeSize;
	while (currBits >= 8)
	{
		byte = accumBits & 0xff;
		[data appendBytes:&byte
				   length:1];
		accumBits >>= 8;
		currBits -= 8;
	}
	
	if (code == clearCode)
	{
		// init the tables
		INITTABLE();
	}
	
	if (freeCode > currMaxCode)
	{
		++currCodeSize;
		if (currCodeSize == kMaxBits)
		{
			currMaxCode = kLimit;
		}
		else
		{
			currMaxCode = (1 << currCodeSize) - 1;
		}
	}
	if (code == eofCode)
	{
		//print("eofCode")
		while (currBits > 0)
		{
			byte = accumBits & 0xff;
			[data appendBytes:&byte
					   length:1];
			accumBits >>= 8;
			currBits -= 8;
		}
	}
} // aka outputCode

// This encoder is a stripped down version of a GIF encoder.
// We pass the entire contents of a SHR/3200 file thru this.

+ (NSData *)lzwPack:(NSData *)fileData
{
	// These 11 bytes are appended to the end of the compressed data.
	Byte trailer[] = {
		0x00, 0xC8, 0x00, 0x40, 0x01,
		0x0A, 0x44, 0x72, 0x65, 0x61, 0x6D, 0x57, 0x6F, 0x72, 0x6C, 0x64
	};
	NSMutableData *compressedData = [NSMutableData data];
	unsigned short codeTable[kTableSize];
	accumBits = 0;			// These 2 vars must be zeroed on
	currBits = 0;			// every invocation of lzwPack

	int numRemaining = fileData.length;
	unsigned short stringCode = 0;
	clearCode = (1 << (iniCodeSize - 1));	// may be declared as a constant
	eofCode = clearCode + 1;				//			--- ditto ---
	freeCode = 0;
	unsigned char *srcBuf = (unsigned char *)[fileData bytes];

	// Init the hash table
	INITTABLE();
	[self addCode:clearCode
		   toData:compressedData];
	stringCode = srcBuf[0];					// Get the first char
	numRemaining--;
	int currIndex = 1;

outerloop:
	while (numRemaining > 0)
	{
		int K = srcBuf[currIndex++];		// current char being examined
		numRemaining--;
		int codeK = (K << 12) + stringCode;
		int hashedValue = (K << kShift) ^ stringCode;
		if (hashTable[hashedValue] == codeK)
		{
			stringCode = codeTable[hashedValue];
			continue;
		}
		else if (hashTable[hashedValue] >= 0)	// non-empty slot
		{
			int disp = kTableSize - hashedValue;
			if (hashedValue == 0)
			{
				disp = 1;
			}
			do {
				hashedValue -= disp;
				if (hashedValue < 0)
				{
					hashedValue += kTableSize;
				}
				if (hashTable[hashedValue] == codeK)
				{
					// full code found
					stringCode = codeTable[hashedValue];
					goto outerloop;
				}
			} while (hashTable[hashedValue] >= 0);
		}

		// key is not in the hash table
		[self addCode:stringCode
			   toData:compressedData];
		stringCode = K;
		if (freeCode < kLimit)
		{
			codeTable[hashedValue] = freeCode++;
			hashTable[hashedValue] = codeK;
		}
		else
		{
			// Table is full
			[self addCode:clearCode
				   toData:compressedData];
		}
	} // no more bytes to encode

	[self addCode:stringCode
		   toData:compressedData];
	[self addCode:eofCode
		   toData:compressedData];

	// Finally output some trailer numbers
	if (fileData.length == 32768 || fileData.length == 33280)
	{
		Byte zero = 0;
		// 32 768 + additional 512 (= 33280)
		[compressedData appendBytes:&zero
							 length:1];
	}
	else
	{
		// 38 400 + additional 512 (= 38 912)
		Byte one = 1;
		[compressedData appendBytes:&one
							 length:1];
	}
	[compressedData appendBytes:trailer
						 length:16];
	return compressedData;
}

@end