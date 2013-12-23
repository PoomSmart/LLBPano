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

// Enable Low Light Boost if in Panorama mode
%hook PLCameraController

- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if ((mode == 2 || (kCFCoreFoundationVersionNumber > 793.00 && mode == 3)) && device == 0) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[self.currentDevice lockForConfiguration:nil];
			if ([self.currentDevice isLowLightBoostSupported])
				[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:LLBPano];
			[self.currentDevice unlockForConfiguration];
		});
	}
}

- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device HDRDetectionEnabled:(BOOL)enabled
{
	%orig;
	if (mode == 3 && device == 0) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[self.currentDevice lockForConfiguration:nil];
			if ([self.currentDevice isLowLightBoostSupported])
				[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:LLBPano];
			[self.currentDevice unlockForConfiguration];
		});
	}
}

%end
