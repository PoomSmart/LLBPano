#import <AVFoundation/AVFoundation.h>

static BOOL LLBPano;

@interface PLCameraController
@property(assign) AVCaptureDevice *currentDevice;
@end

%hook AVCaptureDevice

- (BOOL)isLowLightBoostSupported { return LLBPano ? YES : %orig; }

%end

%hook PLCameraController

// Enable Low Light Boost if in Panorama mode
- (void)_configureSessionWithCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (mode == 2 && device == 0) {
   		[self.currentDevice lockForConfiguration:nil];
    	if ([self.currentDevice isLowLightBoostSupported])
    		[self.currentDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:LLBPano ? YES : NO];
    	[self.currentDevice unlockForConfiguration];
    }
}

%end

static void LLBPanoLoader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.LLBPano.plist"];
	id LLBPanoEnabled = [dict objectForKey:@"LLBPanoEnabled"];
	LLBPano = LLBPanoEnabled ? [LLBPanoEnabled boolValue] : YES;
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	LLBPanoLoader();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("com.PS.LLBPano.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	LLBPanoLoader();
  	%init
  	[pool release];
}
