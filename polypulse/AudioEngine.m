//
//  AudioEngine.m
//  polypulse
//
//  Created by geb on 2015-06-04.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import "AudioEngine.h"


#define kBufferCount 2
#define kSamplesPerBuffer 1024
#define kNumChannels 2
#define kSampleRate 44100.0

@import AVFoundation;
@import Accelerate;

@interface AudioEngine(){

    AVAudioEngine           *_engine;
    AVAudioPlayerNode       *_bufferPlayer;
    AVAudioPlayerNode       *_mixerOutputFilePlayer; //can be used to tap the output mix
    AVAudioFormat           *_audioFormat;
    dispatch_queue_t        audioQueue;
    dispatch_semaphore_t    audioSemaphore;
    NSMutableArray          *_audioBuffers;
    int                     bufferIndex;
}
    
- (void)createAndConfigureComponents;
- (void)initAVAudioSession;
- (void)makeEngineConnections;

@end

@implementation AudioEngine

- (instancetype)init {
    
    self = [super init];
    if (self){
        _period = 88100;
        
        [self createAndConfigureComponents];
        [self initAVAudioSession];
        [self makeEngineConnections];
        
        [self startEngine];
        [self render];
        
    }
    return self;
    
}


- (void)createAndConfigureComponents {
    
    _audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:kSampleRate
                                                                  channels:kNumChannels];
    
    _audioBuffers = [[NSMutableArray alloc] init];
    for (int i=0; i<kBufferCount; i++) {
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_audioFormat frameCapacity:kSamplesPerBuffer];
        [_audioBuffers addObject:buffer];
    }
    
    audioQueue = dispatch_queue_create("AudioBufferQueue", DISPATCH_QUEUE_SERIAL);
    audioSemaphore = dispatch_semaphore_create(kBufferCount);
    
    _engine = [[AVAudioEngine alloc] init];
    _mixerOutputFilePlayer = [[AVAudioPlayerNode alloc] init];
    _bufferPlayer = [[AVAudioPlayerNode alloc] init];
    
    //attach the engine nodes
    [_engine attachNode:_mixerOutputFilePlayer];
    [_engine attachNode:_bufferPlayer];
}

- (void)makeEngineConnections {
    
    // get the engine's optional singleton main mixer node
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    
    [_engine connect:_bufferPlayer to:mainMixer format:_audioFormat];
    
    // node tap player
    [_engine connect:_mixerOutputFilePlayer to:mainMixer format:[mainMixer outputFormatForBus:0]];
}

- (void)startEngine {
    // start the engine
    
    /*  startAndReturnError: calls prepare if it has not already been called since stop.
     
     Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
     the engine. Audio begins flowing through the engine.
     
     This method will return YES for sucess.
     
     Reasons for potential failure include:
     
     1. There is problem in the structure of the graph. Input can't be routed to output or to a
     recording tap through converter type nodes.
     2. An AVAudioSession error.
     3. The driver failed to start the hardware. */
    
    NSError *error;
    NSAssert([_engine startAndReturnError:&error], @"couldn't start engine, %@", [error localizedDescription]);
}

- (void)render {
    
    dispatch_async(audioQueue, ^{
        
        float sampleTime = 0;
        
        while (YES) {
            
            // Wait for a buffer to become available.
            dispatch_semaphore_wait(audioSemaphore, DISPATCH_TIME_FOREVER);
            AVAudioPCMBuffer *buffer = (AVAudioPCMBuffer *)[_audioBuffers objectAtIndex:bufferIndex]; // Fill the buffer with new samples.
            float *leftChannel = buffer.floatChannelData[0];
            float *rightChannel = buffer.floatChannelData[1];
            
            for (int sampleIndex = 0; sampleIndex < kSamplesPerBuffer; sampleIndex++) {
                //float sample =  ((((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * 2.0) - 1.0) * self.amp;
                
                
                float sample = sinf(2.0 * M_PI/kSampleRate * 5111.0 * sampleTime) * exp(-0.003 * ((int)sampleTime % self.period)) * 0.333333 + sinf(2.0 * M_PI/kSampleRate * 8800.0 * sampleTime) * exp(-0.003 * ((int)sampleTime % (int)(self.period / 4.0 * 3.0))) * 0.3333333 + sinf(2.0 * M_PI/kSampleRate * 6900.0 * sampleTime) * exp(-0.003 * ((int)sampleTime % (int)(self.period / 7.0 * 3.0))) * 0.333333;
                
                //float sample = 1.0 * exp(-0.01 * ((int)sampleTime % 22050));
                sample *= self.amp;
                leftChannel[sampleIndex] = sample;
                rightChannel[sampleIndex] = sample;
                sampleTime++;
            }
            
            buffer.frameLength = kSamplesPerBuffer;
                
                // Schedule the buffer for playback and release it for reuse after
                // playback has finished.
            [_bufferPlayer scheduleBuffer:buffer completionHandler:^{
                dispatch_semaphore_signal(audioSemaphore);
                return;
            }];
            
                
            bufferIndex = (bufferIndex + 1) % [_audioBuffers count];
        }
        
    });
    
    [_bufferPlayer play];
    
}

#pragma mark AVAudioSession boiler plate

- (void)initAVAudioSession
{
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.02321995464853;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:sessionInstance];
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        // the engine will pause itself
    }
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success) NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        
        // start the engine once again
        [self startEngine];
        [self render];
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // if we've received this notification, the media server has been reset
    // re-wire all the connections and start the engine
    NSLog(@"Media services have been reset!");
    NSLog(@"Re-wiring connections and starting once again");
    
    [self createAndConfigureComponents];
    [self makeEngineConnections];
    [self startEngine];
    [self render];
    
}

@end
