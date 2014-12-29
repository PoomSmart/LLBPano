#import <AVFoundation/AVFoundation.h>
#import "../PS.h"

#define LLBPano [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.LLBPano.plist"][@"LLBPanoEnabled"] boolValue]

@protocol CameraControllerDelegate
@property(assign) AVCaptureDevice *currentDevice;
@end

@interface PLCameraController : NSObject <CameraControllerDelegate>
@end

@interface CAMCaptureController : NSObject <CameraControllerDelegate>
@end

%hook AVCaptureDevice

- (BOOL)isLowLightBoostSupported
{
	return LLBPano ? YES : %orig;
}

%end

static void enableLLB(id<CameraControllerDelegate> self)
{
	if (LLBPano) {
		[self.currentDevice lockForConfiguration:nil];
		if ([self.currentDevice isLowLightBoostSupported])
			[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
		[self.currentDevice unlockForConfiguration];
	}
}

%hook PLCameraController

%group iOS6

- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (mode == 2 && device == 0)
		enableLLB(self);
}

%end

%group iOS7

- (void)_setupPanoramaForDevice:(id)device output:(id)output options:(id)options
{
	%orig;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		enableLLB(self);
	});
}

%end

%end

%group iOS8

%hook CAMCaptureController

- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device options:(id)options
{
	%orig;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		enableLLB(self);
	});
}

%end

%end

%ctor
{
	%init();
	if (isiOS8) {
		%init(iOS8);
	}
	else if (isiOS7) {
		%init(iOS7);
	}
	else if (isiOS6) {
		%init(iOS6);
	}
}