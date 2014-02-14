#import <AVFoundation/AVFoundation.h>
#define isiOS7 (kCFCoreFoundationVersionNumber >= 800.00)

%config(generator=MobileSubstrate);

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

%group iOS6

- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (LLBPano && mode == 2 && device == 0) {
		[self.currentDevice lockForConfiguration:nil];
		if ([self.currentDevice isLowLightBoostSupported])
			[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
		[self.currentDevice unlockForConfiguration];
	}
}

%end

%group iOS7

- (void)_setupPanoramaForDevice:(id)device output:(id)output options:(id)options
{
	%orig;
	if (LLBPano) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[self.currentDevice lockForConfiguration:nil];
			if ([self.currentDevice isLowLightBoostSupported])
				[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
			[self.currentDevice unlockForConfiguration];
		});
	}
}

%end

%end

%ctor {
	%init();
	if (isiOS7) {
		%init(iOS7);
	} else {
		%init(iOS6);
	}
}