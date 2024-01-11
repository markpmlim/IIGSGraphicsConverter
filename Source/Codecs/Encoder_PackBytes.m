/*
 A function that can compress data based on the "packBytes" algorithm developed
 by Apple for the AppleIIgs computer.
 */
// Author: Sheldon Simms
// http://wsxyz.net/tohgr.html

#include <stdlib.h>
#include <assert.h>
#import "Encoder_PackBytes.h"

#define sixtyFourK	65536

struct OutputBuffer {
	unsigned char *p;		// start of memblock
	unsigned char *n;		// next free slot
	unsigned int len, size;
};

// Ensure a 64K output buffer
// Bug fix: We should use malloc rather than realloc
static int initOutputBuffer (struct OutputBuffer *ob)
{
	ob->len = 0;				// # of bytes encoded so far
	ob->size = sixtyFourK;		// current size of ouput buffer in bytes
	//ob->n = ob->p = realloc(0, ob->size);
	ob->n = ob->p = malloc(ob->size);
	return ob->p != 0;
}

// Resize if necessary; len is the # of bytes required
static int checkOutputBuffer(struct OutputBuffer *ob, int len)
{
	unsigned char *p;

	if (ob->len + len <= ob->size)
		return 1;
	// Increase the size of the output buffer by another 64K
	p = realloc(ob->p, ob->size + sixtyFourK);
	if (!p)
		return 0;			// failed
	ob->n = p + (ob->n - ob->p);
	ob->p = p;
	ob->size = ob->size + sixtyFourK;
	return 1;
}

#define CaptureSingletons() {					\
	while (tmpCount > 0)						\
	{											\
		int k = tmpCount;						\
		if (k >= 64)							\
			k = 64;								\
			tmpCount -= k;						\
			if (!checkOutputBuffer(&ob, k + 1))	\
				return NULL;					\
		ob.len += (k + 1);						\
		*(ob.n)++ = (unsigned char)(k - 1);		\
		while (k--)								\
			*(ob.n)++ = *blockPtr++;			\
	}											\
}

// FTN 08/0x4000 - Packed Hi-Res File
// TN.IIGS.094 - see "PACKBYTES BUFFERS COUNT TOO" section
// Return a NULL pointer if unsuccessful especially if there is not enough mem.
// KIV: to convert to Objective-C method
static struct OutputBuffer *packBytes (void *vp, unsigned int len)
{
	u_int32_t bytesLeft, tmpCount, repeatCount;
	Byte *blockPtr, *inputPtr, *tmpPtr, *rp;
	Byte currByte;
	static struct OutputBuffer ob;

	if (!initOutputBuffer(&ob))				// Get a 64K buffer
		return NULL;

	blockPtr = vp;
	inputPtr = vp;
	bytesLeft = len;						// # of bytes to pack

	while (bytesLeft)
	{
		tmpPtr = inputPtr;
		tmpCount = bytesLeft;
		currByte = *tmpPtr++;				// get byte to be checked
		// Loop to check if the byte is repeated
		while (--tmpCount && currByte == *tmpPtr)
			tmpPtr++;

		// tmpPtr is pointing @ the next byte that's different from the byte being examined.
		repeatCount = tmpPtr - inputPtr;
		// No encoding for 2 identical bytes in a row; treated as singletons
		if (repeatCount > 2)				// (threshhold)
		{
			// Handles 2 or more repeats of the byte being examined
			// ie 3 or more identical bytes in a row: 3, 4, 5, ...
			// inputPtr is pointing @ the byte being examined
			tmpCount = inputPtr - blockPtr;
			// if tmpCount > 0, there are singletons to be captured
			CaptureSingletons();

			assert(blockPtr == inputPtr);			// abort if blockPtr != ip

			if (repeatCount < 8 && repeatCount % 4)
			{
				// case 1: 3,5,6,7 identical bytes in a row
				if (!checkOutputBuffer(&ob, 2))
					return NULL;
				// flag byte (flag bits = %01)
				*(ob.n)++ = 0x40 | ((unsigned char)(repeatCount - 1));
				*(ob.n)++ = currByte;
				ob.len += 2;
				bytesLeft -= repeatCount;
				inputPtr += repeatCount;
			}
			else
			{
				// case 3: multiple of 4 of a repeated byte (up to 64 x 4)
				repeatCount /= 4;
				if (repeatCount > 64)
					repeatCount = 64;
				if (!checkOutputBuffer(&ob, 2))
					return NULL;
				// flag byte (flag bits = %11)
				*(ob.n)++ = 0xC0 | ((unsigned char)(repeatCount - 1));
				*(ob.n)++ = currByte;		// byte that is repeated
				ob.len += 2;
				bytesLeft -= (repeatCount * 4);
				inputPtr += (repeatCount * 4);
			}
			blockPtr = inputPtr;
			continue;
		}

		if (bytesLeft >= 8)
		{
			// prepare to scan ahead 4 bytes from where we are
			rp = inputPtr;				// rp is pointing @ the byte being examined/repeated
			tmpPtr = inputPtr + 4;		// NB. tmpPtr is always 4 bytes ahead of rp
			tmpCount = bytesLeft - 4;
			while (tmpCount && *tmpPtr == *rp)
			{
				tmpPtr += 1;			// advance by pointers and check
				rp += 1;				// if the bytes pointed to are identical
				tmpCount -= 1;
			}

			repeatCount = tmpPtr - inputPtr;
			if (repeatCount >= 8)
			{
				// case 0 - all bytes different
				tmpCount = inputPtr - blockPtr;		// condition
				CaptureSingletons();
				assert(blockPtr == inputPtr);	// abort if blockPtr != ip

				// case 2 - handle repeats of 4 consecutive different bytes
				repeatCount /= 4;
				if (repeatCount > 64)
					repeatCount = 64;
				if (!checkOutputBuffer(&ob, 5))
					return NULL;
				// flag byte (flag bits = %10)
				*(ob.n)++ = 0x80 | ((unsigned char)(repeatCount - 1));
				*(ob.n)++ = inputPtr[0];
				*(ob.n)++ = inputPtr[1];
				*(ob.n)++ = inputPtr[2];
				*(ob.n)++ = inputPtr[3];
				ob.len += 5;
				bytesLeft -= (repeatCount * 4);
				inputPtr += (repeatCount * 4);
				blockPtr = inputPtr;
				continue;
			}
		}

		// We have a singleton
		inputPtr += 1;
		bytesLeft -= 1;
	} // while

	// capture all the stragglers which are singletons
	tmpCount = inputPtr - blockPtr;
	CaptureSingletons();
	return &ob;
}


@implementation Encoder(PackBytes)

// An entire file or just a scanline may be passed
// todo: bullet proof
+ (NSData *)packBytes:(NSData *)fileData
{
	//NSLog(@"packBytes");
	NSData *compressedData = nil;
	unsigned int fileSize = [fileData length];
	void *inputBuf = malloc(fileSize);

	[fileData getBytes:inputBuf
				length:fileSize];
	struct OutputBuffer *compressedBuf = packBytes(inputBuf, fileSize);

	if (compressedBuf)
	{
		compressedData = [NSData dataWithBytes:compressedBuf->p
										length:compressedBuf->len];
		free(compressedBuf->p);
	}
	free(inputBuf);
	return compressedData;
}

@end;











