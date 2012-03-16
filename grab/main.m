//
//  main.c
//  grab
//
//  Created by Andrey Kutejko on 3/16/12.
//  Copyright (c) 2012 Anahoret Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdio.h>

static void WindowListApplierFunction(const void *inputDictionary, void *context)
{
	NSDictionary *entry = (NSDictionary*)inputDictionary;
	
	// The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
	// However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
	int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
	if(sharingState != kCGWindowSharingNone)
	{
        int pid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
        int wid = [[entry objectForKey:(id)kCGWindowNumber] intValue];
        const char *app;

		NSString *applicationName = [entry objectForKey:(id)kCGWindowOwnerName];
		if (applicationName)
            app = [applicationName cStringUsingEncoding:NSUTF8StringEncoding];
        else
            app = "(unknown)";

        printf("%8d | %-20s |  %8d\n", pid, app, wid);
    }
}

static void printWindowList()
{
    printf("     PID | Application          | Window ID\n");
    printf("---------+----------------------+----------\n");

	CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll | kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
	CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, NULL);
	CFRelease(windowList);
}

static void createScreenshot(CGWindowID windowID, const char *filename)
{
	CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, windowID, kCGWindowImageBoundsIgnoreFraming);
    
    NSString *path = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, windowImage, nil);

    CGImageDestinationFinalize(destination);
    CFRelease(destination);
	CGImageRelease(windowImage);
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (argc == 1)
    {
        printWindowList();
    }
    else if (argc == 3)
    {
        CGWindowID wid = atoi(argv[1]);
        createScreenshot(wid, argv[2]);
    }
    else
    {
        printf("Usage: grab\n");
        printf("       grab <window-id> <output-file>\n");
    }

    [pool drain];
    return 0;
}
