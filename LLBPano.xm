#import <AVFoundation/AVFoundation.h>

#define LLBPano [[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.LLBPano.plist"] objectForKey:@"LLBPanoEnabled"] boolValue]

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice;
@end

%hook AVCaptureDevice

- (BOOL)isLowLightBoostSupported
{
	return LLBPano ? YES : %orig;
}

%end

%hook PLCameraController

// Enable Low Light Boost if in Panorama mode
- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (mode == 2 && device == 0) {
   		[self.currentDevice lockForConfiguration:nil];
    	if ([self.currentDevice isLowLightBoostSupported])
    		[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:LLBPano];
    	[self.currentDevice unlockForConfiguration];
    }
}

%end
