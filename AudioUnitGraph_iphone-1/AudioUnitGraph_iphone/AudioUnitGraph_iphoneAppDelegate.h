//
//  AudioUnitGraph_iphoneAppDelegate.h
//  AudioUnitGraph_iphone
//
//  Created by charlie on 4/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AudioUnitGraph_iphoneAppDelegate : NSObject <UIApplicationDelegate, UIAccelerometerDelegate> {
	AUGraph graph;
	AUNode mixerNode, outputNode;
	AudioComponentInstance output, mixer;
    
    int sineCount;
    
    UIAccelerometer *accelerometer;
}

    
@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) UIAccelerometer *accelerometer;

- (IBAction) removeMixerNode:(id)sender;
- (IBAction)downA:(id)sender;
- (IBAction)downB:(id)sender;
- (IBAction)downC:(id)sender;
- (IBAction)downD:(id)sender;
- (IBAction)downE:(id)sender;
- (IBAction)downF:(id)sender;
- (IBAction)downG:(id)sender;
- (IBAction)upA:(id)sender;
- (IBAction)upB:(id)sender;
- (IBAction)upC:(id)sender;
- (IBAction)upD:(id)sender;
- (IBAction)upE:(id)sender;
- (IBAction)upF:(id)sender;
- (IBAction)upG:(id)sender;


@end
