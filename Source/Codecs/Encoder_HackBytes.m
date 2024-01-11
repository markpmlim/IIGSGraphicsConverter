#include <stdlib.h>
#import "Encoder_PackBytes.h"

#pragma mark Bill Buckels HackBytes function

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned long ulong;
typedef short sshort;
typedef struct tagRAWLIST
{
	ushort	CNT;
	uchar	VAL;
	uchar	Singleton;		/* this is a FIFO stack for processing singletons */
} RAWLIST;

#define SUCCESS	 0
#define FAILURE	 1
#define INVALID	 -1

sshort Pack4Singletons = INVALID;

// The following memory must be allocated everytime HackBytes is called
RAWLIST *RawBuf = NULL;
uchar *PackedBuf = NULL;
uchar *RawBuf4 = NULL;
uchar *PackedBuf4 = NULL;
uchar *UnPackBuf4 = NULL;			// we don't need this variable

ushort disable_HackQuads = 0;

/* helper function - called at start */
int PackAlloc(ushort rawlen)
{
	ushort packedlen;
	
	Pack4Singletons = INVALID; /* Quad Buffers */

	/* If HackBytes is used to pack long lines, this limits
	 the bounds of the raw buffer to a 64k segment. */
	if (rawlen > 32767)
		packedlen = 65535;
	else
		packedlen = rawlen * 2;

	if (NULL == (PackedBuf = (uchar *) malloc(sizeof(uchar)*packedlen))) {
		puts("Not Enough Memory for HackBytes Write Buffer...");
		return INVALID;
	}

	if (NULL == (RawBuf = (RAWLIST *) malloc(sizeof(RAWLIST)*rawlen))) {
		puts("Not Enough Memory for HackBytes List Buffer...");
		free(PackedBuf);
		PackedBuf = NULL;
		return INVALID;
	}

	/* 2 or 3 optional buffers - must all allocate or none allocate */
	if (NULL == (RawBuf4 = (uchar *) malloc(sizeof(uchar)*packedlen))) {
		PackedBuf4 = NULL;
		UnPackBuf4 = NULL;
	}
	else {
		if (NULL == (PackedBuf4 = (uchar *) malloc(sizeof(uchar)*packedlen))) {
			free(RawBuf4);
			RawBuf4 = NULL;
		}
#ifdef DEBUG
		else {
			if (NULL == (UnPackBuf4 = (uchar *) malloc(sizeof(uchar)*packedlen))) {
				free(RawBuf4);
				RawBuf4 = NULL;
				free(PackedBuf4);
				PackedBuf4 = NULL;
			}
			else {
				Pack4Singletons = SUCCESS;
			}
		}
#else
		else {
			Pack4Singletons = SUCCESS;
		}
		
#endif
	}


	return SUCCESS;
}


/* helper function - called on exit */
void PackFree()
{

	if (NULL != RawBuf)
		free(RawBuf);
	if (NULL != PackedBuf)
		free(PackedBuf);
	if (NULL != RawBuf4)
		free(RawBuf4);
	if (NULL != PackedBuf4)
		free(PackedBuf4);
	if (NULL != UnPackBuf4)
		free(UnPackBuf4);

	PackedBuf4 = NULL;
	RawBuf4 = NULL;
	PackedBuf = NULL;
	RawBuf = NULL;
	UnPackBuf4 = NULL;
	
}


/* Helper Function called By HackQuads */
unsigned PackQuads(uchar *inbuff, unsigned NumQuads, uchar *outbuff)
{
	unsigned runcount, x, idx, PackedCount = 0;
	uchar msk, this[4], last[4];

	/* ********************************************* */
	/* ========== RLE for Quad Runs in Singletons == */
	/* ********************************************* */

	memcpy((uchar *)&last[0], (uchar*)&inbuff[0], 4);
	runcount = 1;

	/* When I tried shifting the line using a more complicated
	 segmented algorithm, the savings were at best only a few bytes
	 on some images and none at all on others. It really wasn't worth
	 the extra overhead, so I decided to use classic run-length encoding
	 below for the sake of readability. */

	for (x = 1, idx = 4; x < NumQuads; x++, idx+=4) {
		memcpy((uchar *)&this[0], (uchar *)&inbuff[idx], 4);
		if (memcmp(&this[0], &last[0], 4) == 0) {
			runcount++;
			if (runcount == 64) {
				msk = (uchar) (runcount - 1);
				outbuff[PackedCount] = (uchar) (msk | 0x80);
				PackedCount++;
				memcpy((uchar*)&outbuff[PackedCount], (uchar *)&this[0], 4);
				PackedCount+=4;
				runcount = 0;
			}
		}
		else {
			if (runcount > 0) {
				msk = (uchar) (runcount - 1);
				outbuff[PackedCount] = (uchar) (msk | 0x80);
				PackedCount++;
				memcpy((uchar *)&outbuff[PackedCount], (uchar *)&last[0], 4);
				PackedCount+=4;
			}
			memcpy((uchar *)&last[0], (uchar *)&this[0], 4);
			runcount = 1;
		}
	}

	/* straggler Quads */
	/* straggler singletons are appended to the line
	 after returning to HackQuads() */
	if (runcount > 0) {
		msk = (uchar) (runcount - 1);
		outbuff[PackedCount] = (uchar) (msk | 0x80);
		PackedCount++;
		memcpy((uchar *)&outbuff[PackedCount],(uchar *)&this[0],4);
		PackedCount+=4;
	}

	return PackedCount;
}

/* Helper Function called By HackBytes */
/* Singletons Only - Repeated Patterns of 4 Bytes - Mask 0x80 */
unsigned HackQuads(unsigned SingleCount)
{
	unsigned singlerun, NumQuads, remaining, runcount, PackedCount = 0;
	uchar msk;

	if (disable_HackQuads == 1)
		return 0; /* for demo purposes */

	/* if flag is not set, no memory is allocated so just return */
	if (Pack4Singletons == INVALID)
		return 0;

	/* in order for a repeat of 4 to occur we need a minimum of 8 bytes */
	NumQuads = SingleCount / 4;
	if (NumQuads < 2)
		return 0;

	/* expand bytes into look-ahead mini-buffer */
	/* singlerun starts at base 0 */
	for (singlerun = 0; singlerun < SingleCount; singlerun++) {
		RawBuf4[singlerun] = RawBuf[singlerun].Singleton;
	}

	/* RLE for Quad pattern runs */
	singlerun = (NumQuads * 4);
	remaining = SingleCount - singlerun;

	/* shifted segment optimization here makes little difference */
	/* see notes in PackQuads (above) */
	/* however this is an interesting area of the code to play with */
	/* I have left a "ping" test in place below left over from my last
	 test code before the production version of this function for
	 possible future drill-down to try some pattern matching stuff
	 here... but I thought I'd better keep it simple for the first
	 release. */

	PackedCount = PackQuads((uchar *)&RawBuf4[0], NumQuads, (uchar *)&PackedBuf4[0]);

	/* Straggletons - encode as a single run of 1-3 bytes */
	if (remaining > 0) {
		msk = (uchar) (remaining - 1);
		PackedBuf4[PackedCount] = msk;
		PackedCount++;
		memcpy((uchar *)&PackedBuf4[PackedCount],(uchar *)&RawBuf4[singlerun],remaining);
		PackedCount+=remaining;
	}

#ifdef DEBUG

	/* if you are mucking about with PackQuads set DEBUG and
	 redirect to a file for clues */

	if (UnPackBytes((uchar *)&UnPackBuf4[0], (uchar *)&PackedBuf4[0],(long) SingleCount,(long) PackedCount)!=0) {
		puts("PackQuads Error!");
		return 0;
	}

	if (memcmp((uchar *)&RawBuf4[0],(uchar *)&UnPackBuf4[0],SingleCount) != 0) {
		puts("Compare PackQuads Error!");
		return 0;
	}
	
#endif

	return PackedCount;
} //HackQuads

/* The Crux of the Biscuit */
int HackBytes(uchar *inbuff,
			  ushort inlen,
			  ushort SingletonThreshold)
{
	uchar this, last, msk;
	ushort runcount, repeats, singlerun, maxpack;
	ushort idx, jdx, i;
	unsigned RawCount = 0, SingleCount = 0, PackedCount = 0, QuadCount = 0;

	/* ********************************************* */
	/* ========== Build the List for this line ===== */
	/* ********************************************* */

	/* Build a list of count,value pairs */

	RawCount = 0;
	last = inbuff[0];			// last char seen
	runcount = 1;
	for (idx=1; idx<inlen; idx++) {
		this = inbuff[idx];
		if (this == last) {
			// same char
			runcount++;
		}
		else {
			// we have encountered a different char during a run
			// NB. a run of just 1 char is also recorded!
			if (runcount > 0) {
				RawBuf[RawCount].CNT = runcount;
				RawBuf[RawCount].VAL = last;
				RawCount++;
			}
			// reset for next run
			last = this;
			runcount = 1;
		}
	} // for

	/* stragglers */
	if (runcount > 0) {
		RawBuf[RawCount].CNT = runcount;
		RawBuf[RawCount].VAL = last;
		RawCount++;
	}

	/* ********************************************* */
	/* ====== Encode the List for this line ======== */
	/* ********************************************* */

	/* Process a list of count,value pairs */

	SingletonThreshold++;
	if (SingletonThreshold < 2 || SingletonThreshold > 5) {
		/* default - 1 and 2 bytes are encoded as Singletons */
		SingletonThreshold = 3;
	}

	PackedCount = SingleCount = 0;

	for (idx=0;idx<RawCount;) {
		runcount = RawBuf[idx].CNT;
		if (runcount == 0) {
			/* list nodes should never have a zero count */
			idx++;
			continue;
		}

		if (runcount < SingletonThreshold) {
			/* push singleton nodes onto the stack
			 until we hit a repeat node */
			for (i=0;i<runcount;i++) {
				RawBuf[SingleCount].Singleton = RawBuf[idx].VAL;
				SingleCount++;
			}
			idx++;
			continue;
		}

		/* if we have hit a repeat list node... */
		/* before encoding the repeat, pop singleton nodes (if any) off the stack and encode 'em first */
		/* two modes of encoding... Mask 0x80 and Mask 0x00 - decide which is more efficient */
		while (SingleCount > 0) {

			/* ********************************************* */
			/* ========== Singleton Option 1 - Mask 0x80 === */
			/* ********************************************* */
			/* ========== Build a Quad Run of Singletons === */
			/* ********************************************* */

			singlerun = 0; /* needed later on */

			/* check for repeats of 4 byte patterns in Singletons */
			QuadCount = HackQuads(SingleCount);

			if (QuadCount == 0) break;

			/* the following calculates the raw encoding for a run of singletons */
			/* we don't need to actually run singleton option 2 to get a line
			 length for comparison because that's pretty well defined */
			maxpack = (ushort)(SingleCount/64);
			if ((SingleCount % 64) != 0)
                maxpack++;
			maxpack+=SingleCount;

			/* if no efficiency gain, just encode as raw singletons */
			/* it could very well be that at the end of encoding the line
			 that the entire line gets replaced with a singleton run
			 depending on how expanded the encoded line becomes */

			if (QuadCount > maxpack)
                break;
			/* otherwise append encoded 4 byte patterns to the packed line */
			memcpy(&PackedBuf[PackedCount],&PackedBuf4[0],QuadCount);

			/* Advance the count and pop the Singleton Stack */
			PackedCount += QuadCount;
			SingleCount = 0;
			break;

		}

		while (SingleCount > 0) {
			
			/* ********************************************* */
			/* ========== Singleton Option 2 - Mask 0x00 === */
			/* ********************************************* */
			/* ========== Build a Raw Run of Singletons ==== */
			/* ********************************************* */

			if (SingleCount < 65) {
				msk = (uchar)(SingleCount - 1);
				PackedBuf[PackedCount] = msk;
				PackedCount++;
				for (i=0;i<SingleCount;i++) {
					PackedBuf[PackedCount] = RawBuf[singlerun].Singleton;
					singlerun++;
					PackedCount++;
				}
				SingleCount = 0;
				break;
			}

			PackedBuf[PackedCount] = (uchar)63;
			PackedCount++;
			for (i=0; i<64; i++) {
				PackedBuf[PackedCount] = RawBuf[singlerun].Singleton;
				singlerun++;
				PackedCount++;
			}
			SingleCount -= 64;
		} //while

		/* Hi-Low Split */

		/* ********************************************* */
		/* ========== Quad Count Repeats Mask 0xc0 ===== */
		/* ********************************************* */
		/* ========== Build Full Runs of Repeated Pairs	 */
		/* ********************************************* */

		/* Mask 0xc0 - use full quads to reduce repeats */
		while (runcount > 256) {
			PackedBuf[PackedCount] = 0xff; /* 63 | 0xc0 */
			PackedCount++;
			PackedBuf[PackedCount] = RawBuf[idx].VAL;
			PackedCount++;
			runcount-= 256; /* decrement runcount until 256 or below */
		}

		/* 1 byte runs are a loss at the end of any repeat run...
		 PUSH 1 BYTE onto the singleton stack and give it a second chance */
		if (runcount < 2) {
			if (runcount == 1) {
				/* push singletons on the stack */
				RawBuf[SingleCount].Singleton = RawBuf[idx].VAL;
				SingleCount++;
			}
			idx++;
			continue;
		}

		/* ********************************************* */
		/* ========== Single Count Repeats Mask 0x40 === */
		/* ********************************************* */
		/* ========== Build Low Runs of Repeated Pairs	 */
		/* ********************************************* */

		/* Mask 0x40 for repeats of 2 to 64 */
		if (runcount < 65) {
			msk = (uchar)(runcount - 1);
			PackedBuf[PackedCount] = (uchar) (msk | 0x40);
			PackedCount++;
			PackedBuf[PackedCount] = RawBuf[idx].VAL;
			PackedCount++;
			idx++;
			continue;
		}

		/* End of High-Low Split */
		
		/* ********************************************* */
		/* ========== Quad Count Repeats Mask 0xc0 ===== */
		/* ********************************************* */
		/* ========== Build Low Runs of Quad Pairs ===== */
		/* ********************************************* */

		/* Mask 0xc0 - use quads for repeats of 65 to 255 */
		repeats = runcount / 4;

		msk = (uchar) (repeats	- 1);
		PackedBuf[PackedCount] = (uchar) (msk | 0xc0);
		PackedCount++;
		PackedBuf[PackedCount] = RawBuf[idx].VAL;
		PackedCount++;
		runcount -= (repeats * 4);

		/* a 1 byte run is a loss */
		if (runcount < 2) {
			if (runcount == 1) {
				/* push singletons on the stack */
				RawBuf[SingleCount].Singleton = RawBuf[idx].VAL;
				SingleCount++;
			}
			idx++;
			continue;
		}

		/* ********************************************* */
		/* ========== Straggler Repeats Mask 0x40 ====== */
		/* ********************************************* */
		/* ========== Build Quad Overflow Trailer ====== */
		/* ********************************************* */

		/* Mask 0x40 for stragglers - repeats of 2 or 3 */
		/* this breaks even or gains a byte in efficiency */
		msk = (uchar)(runcount - 1);
		PackedBuf[PackedCount] = (uchar) (msk | 0x40);
		PackedCount++;
		PackedBuf[PackedCount] = RawBuf[idx].VAL;
		PackedCount++;
		/* on to the next list member */
		idx++;

	}
	
	/* clear straggletons */
	
	/* two modes of encoding... Mask 0x80 and Mask 0x00 - decide which is more efficient */
	while (SingleCount > 0) {

		/* ********************************************* */
		/* ========== Build a Quad Run of Straggletons	 */
		/* ********************************************* */

		singlerun = 0; /* needed later on */

		/* check for repeats of 4 byte patterns in Singletons */
		QuadCount = HackQuads(SingleCount);

		if (QuadCount == 0) break;

		/* the following calculates the encoding for a run of singletons */
		maxpack = (ushort)(SingleCount/64);
		if ((SingleCount % 64) != 0)
			maxpack++;
		maxpack+=SingleCount;

		/* if no efficiency gain, just encode as singletons */
		if (QuadCount > maxpack)
			break;

		/* otherwise append encoded 4 byte patterns to the packed line */
		memcpy(&PackedBuf[PackedCount],&PackedBuf4[0],QuadCount);

		/* Advance the count and pop the Singleton Stack */
		PackedCount += QuadCount;
		SingleCount = 0;
		break;
	}

	while (SingleCount > 0) {

		/* ********************************************* */
		/* ========== Build a Raw Run of Straggletons	 */
		/* ********************************************* */

		/* pop any remaining singleton nodes off the stack and finish-up */
		if (SingleCount < 65) {
			msk = (uchar)(SingleCount - 1);
			PackedBuf[PackedCount] = msk;
			PackedCount++;
			for (i=0;i<SingleCount;i++) {
				PackedBuf[PackedCount] = RawBuf[singlerun].Singleton;
				singlerun++;
				PackedCount++;
			}
			SingleCount = 0;
			break;
		}

		PackedBuf[PackedCount] = (uchar)63;
		PackedCount++;
		for (i=0; i<64; i++) {
			PackedBuf[PackedCount] = RawBuf[singlerun].Singleton;
			singlerun++;
			PackedCount++;
		}
		SingleCount -= 64;
	}


	/* ********************************************* */
	/* ========== Build a Raw Line of Singletons === */
	/* ********************************************* */
	
	/* a raw line of singletons incurs 1 count byte for every 64 data bytes */
	/* a line of 160 singletons is expanded by 3 count bytes to 163 bytes */
	/* if the packed line expands beyond this length then simply encode it as singletons */

	/* the following calculates the most efficient encoding for a line of singletons */
	maxpack = (ushort)(inlen/64);
	if ((inlen % 64) != 0)
		maxpack++;
	maxpack+=inlen;

	/* if the length of a packed line goes beyond this, run individual bytes */
	if (PackedCount > maxpack) {

		PackedCount = RawCount = 0;
		maxpack = (ushort) (inlen / 64);
		for (idx = 0;idx < maxpack; idx++) {
			/* runs of 64 individual bytes */
			PackedBuf[PackedCount] = 63; PackedCount++;
			for (jdx = 0; jdx < 64; jdx++, RawCount++, PackedCount++) {
				PackedBuf[PackedCount] = inbuff[RawCount];
			}

		}

		inlen -= (maxpack*64);

		if (inlen > 0) {
			/* stragglers if any */
			PackedBuf[PackedCount] = (uchar)(inlen-1); PackedCount++;
			for (jdx = 0; jdx < inlen; jdx++, RawCount++, PackedCount++) {
				PackedBuf[PackedCount] = inbuff[RawCount];
			}
		}
	} /* end of raw chunk */

	/* in either case return length of packed buffer */
	return PackedCount;

} // HackBytes

@implementation Encoder (HackBytes)

+ (NSData *)hackBytes:(NSData *)fileData
{
	//NSLog(@"hackBytes");
	NSData *compressedData = nil;
	unsigned int fileSize = [fileData length];

    if (PackAlloc(fileSize) == INVALID) {
		goto bailOut;
	}

	void *inputBuf = malloc(fileSize);
	[fileData getBytes:inputBuf
				length:fileSize];
	int packedLen = HackBytes(inputBuf, fileSize, 2);

	if (packedLen) 
    {
		compressedData = [NSData dataWithBytes:PackedBuf
										length:packedLen];
    }
    // We should free all memory so that the next file or scanline
    // can start on a clean slate.
    PackFree();
	free(inputBuf);

bailOut:
	return compressedData;
}


@end











