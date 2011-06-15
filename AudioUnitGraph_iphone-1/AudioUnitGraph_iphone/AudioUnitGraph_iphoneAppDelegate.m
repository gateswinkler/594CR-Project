//
//  AudioUnitGraph_iphoneAppDelegate.m
//  AudioUnitGraph_iphone
//
//  Created by charlie on 4/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioUnitGraph_iphoneAppDelegate.h"

#define NUM_CHANNELS 1
#define MAX_SINES 22

typedef struct  {
    float phase;
    float frequency;
} sine;

sine Sines[MAX_SINES];

BOOL shouldSweep = YES;
BOOL Low = FALSE;
BOOL High = FALSE;
SInt16 LowA[44100/220];

@implementation AudioUnitGraph_iphoneAppDelegate

@synthesize window=_window;

@synthesize accelerometer;


static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlag, 
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber, 
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
	
    sine * thisSine = (sine *)inRefCon;
	float samp;
	float incr = ((M_PI * 2.0) * thisSine->frequency) / 44100.0f;
	short * outputBuffer = ioData->mBuffers[0].mData;
    
	
	for(UInt16 n = 0; n < inNumberFrames; ++n) {
		samp = 0.0;
		
        
        /*if(thisSine->frequency == 220.00f){
            for(int i = 0; i<360; i++){
                samp += LowA[i];
                if(i == 359){
                    i = 0;
                }
            }
        }
        else{*/
            samp += sinf(thisSine->phase);
        
		thisSine->phase += incr;
		samp *= 32768.0/8;
        //}
		
		outputBuffer[n] = (SInt16)samp;
        
        if (thisSine->phase > (M_PI * 2)) {
			thisSine->phase -= M_PI * 2;
		}

	}
	
	//thisSine->frequency += 1.0;
	
	return noErr;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    if(acceleration.x < -0.5){
        //Low = TRUE;
        Sines[1].frequency = 220.00f;
        Sines[2].frequency = 246.94f;
        Sines[3].frequency = 261.63f;
        Sines[4].frequency = 293.66f;
        Sines[5].frequency = 329.63f;
        Sines[6].frequency = 349.23f;
        Sines[7].frequency = 392.00f;
    }
    else if(acceleration.x > 0.5){
        //High = TRUE;
        Sines[1].frequency = 2*440.00f;
        Sines[2].frequency = 2*493.88f;
        Sines[3].frequency = 2*523.26f;
        Sines[4].frequency = 2*587.32f;
        Sines[5].frequency = 2*659.26f;
        Sines[6].frequency = 2*698.46f;
        Sines[7].frequency = 2*784.00f;
    }
    else{
        //High = FALSE;
        Sines[1].frequency = 440.00f;
        Sines[2].frequency = 493.88f;
        Sines[3].frequency = 523.26f;
        Sines[4].frequency = 587.32f;
        Sines[5].frequency = 659.26f;
        Sines[6].frequency = 698.46f;
        Sines[7].frequency = 784.00f;
    }
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self.window makeKeyAndVisible];
    
    self.accelerometer = [UIAccelerometer sharedAccelerometer];
    self.accelerometer.updateInterval = .1;
    self.accelerometer.delegate = self;
    
    
    //for(int i = 0; i<44100/220; i = i+((M_PI * 2.0) * 220) / 44100.0f){
    //    LowA[i] = sinf(220*(i*3.14/180))*32768;
    //}
    
    
    
    
    sineCount = 0;
    
    /***************************** CREATE GRAPH *********************************/
    
    AudioComponentDescription mixerDescription, outputDescription;
    
    NewAUGraph(&graph);
    
    mixerDescription.componentFlags = 0;
    mixerDescription.componentFlagsMask = 0;
    mixerDescription.componentType = kAudioUnitType_Mixer;
    mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer; 
    mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    OSErr err = AUGraphAddNode(graph, &mixerDescription, &mixerNode);
    NSAssert(err == noErr, @"Error creating mixer node.");
    
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple; 
    
    err = AUGraphAddNode(graph, &outputDescription, &outputNode);
    NSAssert(err == noErr, @"Error creating output node.");
    
    err = AUGraphOpen(graph);
    NSAssert(err == noErr, @"Error opening graph.");
    
    err = AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0);
    NSAssert(err == noErr, @"Error connecting mixer to output.");
    
    //get the 2 audio units
    err = AUGraphNodeInfo(graph, outputNode, &outputDescription, &output);
    err = AUGraphNodeInfo(graph, mixerNode,  &mixerDescription,  &mixer);
    
    // set number of channels for mixer audio unit
    int channelCount = MAX_SINES;
	AudioUnitSetProperty(mixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &channelCount, sizeof(channelCount));
    
    err = AUGraphInitialize(graph);
    NSAssert(err == noErr, @"Error initializing graph.");
    err = AUGraphStart(graph);
    NSAssert(err == noErr, @"Error starting graph.");
    
    CAShow(graph);
    
    /***************************** ADD NODES *********************************/
    
    
    //Low A
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	AURenderCallbackStruct callback;
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[1];
	AUGraphSetNodeInputCallback(graph, mixerNode, 1, &callback);
	
    // set stream description for bus on mixer audio unit
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate =       44100.00;
	audioFormat.mFormatID =         kAudioFormatLinearPCM;
	audioFormat.mFormatFlags	 =  kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked; 
	audioFormat.mFramesPerPacket =  1;
	audioFormat.mChannelsPerFrame = NUM_CHANNELS;
	audioFormat.mBitsPerChannel =   16;
	audioFormat.mBytesPerPacket =   2 * NUM_CHANNELS;
	audioFormat.mBytesPerFrame =    2 * NUM_CHANNELS;
	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 1, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
        //Sines[1].frequency = 220.0f;

    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph);
    
        
     //Low B
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[2];
     AUGraphSetNodeInputCallback(graph, mixerNode, 2, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 2, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 2, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     //Sines[2].frequency = 246.94f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //Low C
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[3];
     AUGraphSetNodeInputCallback(graph, mixerNode, 3, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 3, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 3, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     //Sines[3].frequency = 261.63f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //D
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[4];
     AUGraphSetNodeInputCallback(graph, mixerNode, 4, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 4, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 4, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     //Sines[4].frequency = 293.66f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //E
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[5];
     AUGraphSetNodeInputCallback(graph, mixerNode, 5, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 5, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 5, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     //Sines[5].frequency = 329.63f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //F
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[6];
     AUGraphSetNodeInputCallback(graph, mixerNode, 6, &callback);
     
     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 6, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 6, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     //Sines[6].frequency = 349.23f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph); 
     
     //G
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[7];
     AUGraphSetNodeInputCallback(graph, mixerNode, 7, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 7, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 7, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     //Sines[7].frequency = 392.00f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
   /* //A
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[8];
	AUGraphSetNodeInputCallback(graph, mixerNode, 8, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 8, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 8, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
    Sines[8].frequency = 440.0f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph);
    
    
    //B
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[9];
	AUGraphSetNodeInputCallback(graph, mixerNode, 9, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 9, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 9, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
    Sines[9].frequency = 493.88f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph);
    
    //C
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[10];
	AUGraphSetNodeInputCallback(graph, mixerNode, 10, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 10, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 10, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
    Sines[10].frequency = 523.25f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph);
    
    //D
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[11];
	AUGraphSetNodeInputCallback(graph, mixerNode, 11, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 11, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 11, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
    Sines[11].frequency = 587.33f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph);
    
    //E
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[12];
	AUGraphSetNodeInputCallback(graph, mixerNode, 12, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 12, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 12, 0, 0 );    
    
    // setfrequency value for sine based on freqSlider
    Sines[12].frequency = 659.26f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph);
    
    //F
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[13];
	AUGraphSetNodeInputCallback(graph, mixerNode, 13, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 13, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 13, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
    Sines[13].frequency = 698.46f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph); 
    
    //G
    // Set callback for input on mixer node. sineCount determines bus on mixer node.
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[14];
	AUGraphSetNodeInputCallback(graph, mixerNode, 14, &callback);

	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 14, &audioFormat, sizeof(audioFormat));
    
    // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 14, 0, 0 );    
    
    // set frequency value for sine based on freqSlider
    Sines[14].frequency = 783.99f;
    
    // update Graph
	AUGraphUpdate(graph, nil);
    
    CAShow(graph); 
      
     //High A
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[15];
     AUGraphSetNodeInputCallback(graph, mixerNode, 15, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 15, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 15, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[15].frequency = 880.0f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     
     //High B
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[16];
     AUGraphSetNodeInputCallback(graph, mixerNode, 16, &callback);
     
     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 16, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 16, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[16].frequency = 987.77f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //High C
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[17];
     AUGraphSetNodeInputCallback(graph, mixerNode, 17, &callback);
     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 17, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 17, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[17].frequency = 1046.50f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //High D
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[18];
     AUGraphSetNodeInputCallback(graph, mixerNode, 18, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 18, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 18, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[18].frequency = 1174.66f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //High E
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[19];
     AUGraphSetNodeInputCallback(graph, mixerNode, 19, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 19, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 19, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[19].frequency = 1318.51f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     
     //High F
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[20];
     AUGraphSetNodeInputCallback(graph, mixerNode, 20, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 20, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 20, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[20].frequency = 1396.91f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph); 
     
     //High G
     // Set callback for input on mixer node. sineCount determines bus on mixer node.
     callback.inputProc = playbackCallback;
     callback.inputProcRefCon = &Sines[21];
     AUGraphSetNodeInputCallback(graph, mixerNode, 21, &callback);

     
     AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 21, &audioFormat, sizeof(audioFormat));
     
     // set pan value for input based on panSlider (-1 left, 0 center, 1 right)
     AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 21, 0, 0 );    
     
     // set frequency value for sine based on freqSlider
     Sines[21].frequency = 1567.98f;
     
     // update Graph
     AUGraphUpdate(graph, nil);
     
     CAShow(graph);
     */
    
    /*************************** INITIALIZE AUDIO SESSION ***********************************/
    AudioSessionInitialize(NULL, NULL, NULL, self);
	
	//set the audio category
	UInt32 audioCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory); 
    
	Float32 preferredBufferSize = .001;
	AudioSessionSetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
	
	AudioSessionSetActive(YES);
    
    return YES;
}


- (IBAction)downA:(id)sender {
    
        AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 1, 1, 0 );
}

- (IBAction)downB:(id)sender {
// if(Low == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 2, 1, 0 );
 /*}
 if(High == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 16, 1, 0 );
 }
 else{
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 9, 1, 0 );
 }*/
 }
 
 - (IBAction)downC:(id)sender {
 //if(Low == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 3, 1, 0 );
 /*}
 if(High == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 17, 1, 0 );
 }
 else{
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 10, 1, 0 );
 }*/
 }
 
 - (IBAction)downD:(id)sender {
 //if(Low == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 4, 1, 0 );
 /*}
 if(High == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 18, 1, 0 );
 }
 else{
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 11, 1, 0 );
 }*/
 }
 
 - (IBAction)downE:(id)sender {
 //if(Low == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 5, 1, 0 );
 /*}
 if(High == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 19, 1, 0 );
 }
 else{
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 12, 1, 0 );
 }*/
 }
 
 - (IBAction)downF:(id)sender {
 //if(Low == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 6, 1, 0 );
 /*}
 if(High == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 20, 1, 0 );
 }
 else{
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 13, 1, 0 );
 }*/
 }
 
 - (IBAction)downG:(id)sender {
 //if(Low == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 7, 1, 0 );
 /*}
 if(High == TRUE){
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 21, 1, 0 );
 }
 else{
 AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 14, 1, 0 );
 }*/
 }

- (IBAction)upA:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 1, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 8, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 15, 0, 0 );
}

- (IBAction)upB:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 2, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 9, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 16, 0, 0 );
}

- (IBAction)upC:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 3, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 10, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 17, 0, 0 );
}

- (IBAction)upD:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 4, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 11, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 18, 0, 0 );
}

- (IBAction)upE:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 5, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 12, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 19, 0, 0 );
}

- (IBAction)upF:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 6, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 13, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 20, 0, 0 );
}

- (IBAction)upG:(id)sender {
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 7, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 14, 0, 0 );
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 21, 0, 0 );
}


- (IBAction) removeMixerNode:(id)sender {
    AUGraphRemoveNode(graph, mixerNode);
    AUGraphUpdate(graph, nil);
}





- (void)dealloc {
    DisposeAUGraph(graph);
    
    [_window release];
    [super dealloc];
}

@end
