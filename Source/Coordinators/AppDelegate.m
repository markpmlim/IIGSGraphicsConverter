//
// AppDelegate
// IIGSGraphicsConverter
//
//  Created by mark lim on 4/6/16.
//  Copyright 2016 IncrementalInnovation. All rights reserved.
//

#import "AppDelegate.h"
#import "ConvertProgressWinController.h"

// Globals needed elsewhere but must be initialized here
const NSData *mainChunk;
const NSData *multiPatChunk;
const NSData *patternsChunk;
const NSData *palChunk;
const NSData *maskChunk;
const NSData *scibChunk;
const NSData *bgChunk;

@implementation AppDelegate

@synthesize selectedAlgo;       // Bind to a Pop up Button
@synthesize destinationFormat;
@synthesize sourceView;
@synthesize destinationView;
@synthesize progressWinController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// One time initialization of data chunks needed by instances of APFGraphic.
	const char mainStr[] = "\004MAIN";
	mainChunk = [[NSData dataWithBytes:(void *)mainStr
							   length:strlen(mainStr)] retain];
	const char multiPalStr[] = "\010MULTIPAL";
	multiPatChunk = [[NSData dataWithBytes:(void *)multiPalStr
								   length:strlen(multiPalStr)] retain];
	const char patternStr[] = "\004PATS";
	patternsChunk = [[NSData dataWithBytes:(void *)patternStr
								   length:strlen(patternStr)] retain];
	const char palettesStr[] = "\010PALETTES";
	palChunk = [[NSData dataWithBytes:(void *)palettesStr
							  length:strlen(palettesStr)] retain];
	const char maskStr[] = "\004MASK";
	maskChunk = [[NSData dataWithBytes:(void *)maskStr
							   length:strlen(maskStr)] retain];
	const char scibStr[] = "\004SCIB";
	scibChunk = [[NSData dataWithBytes:(void *)scibStr
							   length:strlen(scibStr)] retain];
	const char backGrdStr[] = "\014BACKGRDCOLOR";	// for PaintWorks
	bgChunk = [[NSData dataWithBytes:(void *)backGrdStr
							 length:strlen(backGrdStr)] retain];
}

- (id)init
{

	if (NSAppKitVersionNumber < 1038)
	{
		// Pop up a warning dialog, 
		NSRunAlertPanel(@"Sorry, this program requires Mac OS X 10.6 or later", @"You are running %@", 
						@"OK", nil, nil, [[NSProcessInfo processInfo] operatingSystemVersionString]);
		
		// then quit the program
		[NSApp terminate:self]; 
		
	}
	self = [super init];
	if (self)
	{
		self.progressWinController = [[[ConvertProgressWinController alloc] initWithWindowNibName:@"ConvertProgressWindow"] autorelease];
		self.selectedAlgo = hack_bytes;
        // Set the instance variable `srcFormat` manually rather than calling
        // the setter accessor method setSourceFormat:.
        srcFormat = shr_format;
		self.destinationFormat = apf_format;
		[self.progressWinController showWindow:nil];
	}
	return self;
}

- (void)dealloc
{
	[mainChunk release];
	[multiPatChunk release];
	[patternsChunk release];
	[palChunk release];
	[maskChunk release];
	[scibChunk release];
	[bgChunk release];
	if (self.progressWinController != nil)
		self.progressWinController = nil;
	if (self.sourceView != nil)
		self.sourceView = nil;
	if (self.destinationView != nil)
		self.destinationView = nil;
	[super dealloc];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if ([[[self.progressWinController compressOperationQueue] operations] count] >= 1)
	{
		NSBeginAlertSheet(NSLocalizedString(@"Please cancel before quitting", @"Quit Alert"),
						  NSLocalizedString(@"OK", @"button label"),
						  nil,
						  nil,
						  [self.progressWinController window],
						  self,
						  nil,
						  nil,
						  nil,
						  NSLocalizedString(@"A compression is in progress. Cancel it before quitting NuShrinkItX.",
											@"alert message"));
		return NSTerminateCancel;
	}
	else
		return NSTerminateNow;
}

// We need to have an internal variable to store the previous choice
// Getter accessor method for the instance variable `srcFormat`
- (FileFormat)sourceFormat
{
	return srcFormat;
}

// This method allows changes to the type of selectable files in
// the Convert Panel.
// Setter accessor method for the instance variable `srcFormat`
- (void)setSourceFormat:(FileFormat)fileFormat
{
    // The panel will not be nil if an instance of NSOpenPanel has been created.
	NSOpenPanel *convertPanel = (NSOpenPanel *)[self.sourceView window];
	NSArray *fileTypes = nil;
	if (fileFormat == shr_format)
	{
		fileTypes = [NSArray arrayWithObjects:
					 @"SHR", nil];
	}
	else if (fileFormat == brooks_format)
	{
		fileTypes = [NSArray arrayWithObjects:
					 @"3200", nil];
	}
    // The property `allowedFileTypes` will be ignored for 10.5 or earlier.
	[convertPanel setAllowedFileTypes: fileTypes];

	srcFormat = fileFormat;
}


// Set defaults for the destination file for cases in which
// an empty tab is displayed.
- (void)convertOptions
{
	// The method destinationTab is called but the tabview item does not changed!
	// Now working: the tabviewItem identifiers (IB attribute inspector) must begin with 0
	if (self.selectedAlgo == lzw_pack)
		self.destinationFormat = dg_format;
	else
		self.destinationFormat = apf_format;	// default
	[self willChangeValueForKey:@"destinationTab"];
	[self didChangeValueForKey:@"destinationTab"];
}

// This is called before the process Open Panel is displayed!
- (int)destinationTab
{
	if (self.selectedAlgo != lzw_pack)
	{
		//NSLog(@"should show destination tabview item");
		return 1;
	}
	else
	{
		//NSLog(@"should be an empty tabview item");
		return 0;
	}
}

/*
 The panel is displayed twice; once to get the files to be converted
 The second time to let the user choose the destination folder
 */
- (IBAction)compress:(id)sender
{
	if ([[[self.progressWinController compressOperationQueue] operations] count] >= 1)
	{
		NSBeginAlertSheet(NSLocalizedString(@"We are busy at this moment", @"Busy Alert"),
						  NSLocalizedString(@"OK", @"button label"),
						  nil,
						  nil,
						  [self.progressWinController window],
						  self,
						  nil,
						  nil,
						  nil,
						  NSLocalizedString(@"A File Conversion process is in progress. Stop it first.",
											@"alert message"));
		goto bailOut;
	}
	NSOpenPanel *convertOP = [NSOpenPanel openPanel];
	convertOP.canChooseDirectories = NO;
    [convertOP setCanChooseFiles:YES];
	convertOP.allowsMultipleSelection = YES;

    // Can't assign with self.sourceView - memory leak.
	convertOP.accessoryView = sourceView;
	convertOP.prompt = @"Convert";
	NSArray *fileTypes = nil;
	if ([self sourceFormat] == shr_format)
	{
		fileTypes = [NSArray arrayWithObjects:
					 @"SHR", nil];
	}
	else if ([self sourceFormat] == brooks_format)
	{
		fileTypes = [NSArray arrayWithObjects:
					 @"3200", nil];
	}
	[convertOP setTitle: @"Select Files to be compressed"];
	convertOP.prompt = @"Convert";
    // Requires 10.6 or later. Ignored if macOS 10.5 or earlier.
	[convertOP setAllowedFileTypes: fileTypes];

	// Get the source type and compression algorithm
	NSInteger buttonID = [convertOP runModal];

	[self convertOptions];
	if (buttonID == NSFileHandlingPanelOKButton)
	{
		NSArray *selectedURLs = [convertOP URLs];
		// Allow user to select the destination folder as well as create a new folder
		NSOpenPanel *processOP = [NSOpenPanel openPanel];
		processOP.canChooseDirectories = YES;			// folders can be selected ...
		processOP.canChooseFiles = NO;					// ... but not files
		processOP.allowsMultipleSelection = NO;			// only 1 folder can be selected
		processOP.canCreateDirectories = YES;
		processOP.accessoryView = self.destinationView;
		// How to set the correct tabview item based on srcFormat.
		processOP.prompt = @"Process";
		[processOP setTitle: @"Select Destination Folder"];
		buttonID = [processOP runModal];
		//NSLog(@"destination format:%d", self.destinationFormat);
		if (buttonID == NSFileHandlingPanelOKButton)
		{
			NSArray *url = [processOP URLs];
			NSURL *destURL = [url objectAtIndex:0];
			//NSLog(@"%@", destURL);			// folders have a trailing slash
			[self.progressWinController compressItemsAtURLs:selectedURLs
											 destinationURL:destURL];
		}
	}
bailOut:
	return;
}

- (IBAction)openHelp:(id)sender
{
	NSString *fullPathname;
	fullPathname = [[NSBundle mainBundle] pathForResource:@"Readme"
												   ofType:@"rtfd"];
	[[NSWorkspace sharedWorkspace] openFile:fullPathname];
}

// KIV
-(IBAction) expand:(id)sender
{
	
}
@end
