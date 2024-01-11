## Converting Apple IIGS unpacked graphic files (filetype $C1) to a packed format (filetype $C0)

<br />
<br />
<br />

This simple utility can compress PIC files ($C1/$0000 and $C1/$0001) to one of the following formats:

a) Packed Super Hi-Res Image ($C0/$0001)
b) Apple Preferred Format ($C0/$0002)
c) DreamGrafix Document ($C0/$8005)

To facilitate file recognition by this macOS utility, the following file extensions must be assigned to files with the following Apple II file and auxiliary types: 

a) SHR  ($C1/$0000)
b) 3200 ($C1/$0001)

If a compression procedure succeeds, the utility will produce files with the following Apple II file and auxiliary types; a file extension will be appended to the file as well.

a) PAK ($C0/$0001)
b) APF ($C0/$0002)
c) DG  ($C0/$8005)

All file extensions mentioned above are also recognized by QuickViewSHR.

<br />
<br />
<br />


## Problem Encountered

The following extract is lifted from Apple's API documentation on NSSavePanel instance property `allowedFileTypes`:

**NSOpenPanel**: In versions of macOS earlier than v10.6, this property is ignored. For applications that link against v10.6 and higher, this property determines which files should be *enabled* in the open panel.

As a result, this project must be build using **v10.6** frameworks with the deployment target set at **v10.6**.

<br />
<br />

There is a Help file (Readme.rtf) included with the project and can be accessed via the program's **Help Menu**.

<br />
<br />
<br />

## Build Requirements:

XCode 3.2.x

<br />
<br />

## Runtime Requirements:

macOS v10.6 or later.

<br />
<br />

**Acknowledgements**:

Bill Buckets for his HackBytes function.
Sheldon Simms for his packBytes function.


