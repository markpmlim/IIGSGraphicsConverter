#ifndef __USER_DEFINES_H__
#define __USER_DEFINES_H__

// std IIgs screen layout
#define kBytesPerScanline	160
#define kRowsPerScreen		200
#define offsetScbTable		0x7d00
#define offsetColorTable	0x7e00


typedef struct
{
	u_int16_t colorEntries[16];
} IIgsColorTable;

typedef struct
{
	u_int16_t size;
	u_int16_t modeWord;		// this is the scb of the scanline
} DirEntry;

// 
typedef struct
{
	u_int16_t patternEntries[16];
} IIgsPattern;

// custom
u_int16_t paintWorksBackGroundColor;

// the tags of the various UI elements in MainMenu.xib must be
// correctly or else ...
typedef enum
{
	hack_bytes = 0,
	pack_bytes,				// tag 1
	lzw_pack				// tag 2
} CompressionAlgorithm;

typedef enum
{
	pak_format = 0,			// tag 0
	apf_format,				// tag 1
	shr_format,				// tag 2
	brooks_format,			// tag 3
	dg_format				// tag 4
} FileFormat;

#endif