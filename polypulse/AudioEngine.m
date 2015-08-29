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
    __block BOOL            on;
    long long               sampleTime;
    NSMutableArray          *metronomes;
}
    
- (void)createAndConfigureComponents;
- (void)initAVAudioSession;
- (void)makeEngineConnections;

@end

@implementation AudioEngine


//MARK: Public methods
- (instancetype)init {
    
    self = [super init];
    if (self){
        _period = 44100;
        
        [self createAndConfigureComponents];
        [self initAVAudioSession];
        [self makeEngineConnections];
        
    }
    return self;
    
}

- (void)start {
    
    sampleTime = 0;
    on = YES;
    [self startEngine];
    [self render];
    
}

- (void)stop {
    on = NO;
    //this clears any previously scheduled events,
    //it's required in handling route changes, which cause the buffer player to deadlock otherwise
    [_bufferPlayer stop];
}

- (void)addMetronome:(Metaronome *)met{
    
    if (!metronomes){
        metronomes = [[NSMutableArray alloc] init];
    }
    
    [metronomes addObject:met];
}

- (void)removeMetronome:(Metaronome *)met{
    
    if (metronomes) {
        [metronomes removeObject:met];
    }
}

- (NSArray *)getMetronomes {
    return [NSArray arrayWithArray:metronomes];
}


//MARK: Private methods
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
    
    // node tap player, can monitor / record with this
    [_engine connect:_mixerOutputFilePlayer
                  to:mainMixer
              format:[mainMixer outputFormatForBus:0]];
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

//MARK: callback that fills the audio buffer
- (void)render {
    
    
    dispatch_async(audioQueue, ^{
        
        while (on) {
            
            // Wait for a buffer to become available using the audio semaphore, give an ad hoc time out though it should never happen
            dispatch_semaphore_wait(audioSemaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10));
            
            __block float *repval = calloc(3, sizeof(float));//on the heap, plays ok with GCD
            
            //get the reference to the current audio buffer
            AVAudioPCMBuffer *buffer = (AVAudioPCMBuffer *)[_audioBuffers objectAtIndex:bufferIndex]; // Fill the buffer with new samples.
            
            float *leftChannel = buffer.floatChannelData[0];
            float *rightChannel = buffer.floatChannelData[1];
            
            //copy the array of metronomes, in case a new one is added by the user
            NSArray *ms = [NSArray arrayWithArray:metronomes];
            
            float scalar = 1.0 / [ms count];
            
            for (int sampleIndex = 0; sampleIndex < kSamplesPerBuffer; sampleIndex++) {
                
                float sample = 0.0;
                float lsample = 0.0;
                float rsample = 0.0;
                
                int count = 0;
                
                //iterate through the refs and construct the sample, slow
                for (Metaronome *m in ms){
                    sample += sinf(2.0 * M_PI/kSampleRate * m.freq * sampleTime) * exp(-0.006 * (fmod( (double)sampleTime, m.period))) * m.amp;
                    lsample += sample * m.pan;
                    rsample += sample * (1-m.pan);
                    repval[count % 3] += (fabsf(lsample) + fabsf(rsample)) * 0.5;
                    count++;
                }
                
                lsample *= self.amp * scalar;
                rsample *= self.amp * scalar;
                
                leftChannel[sampleIndex] = lsample;
                rightChannel[sampleIndex] = rsample;
                
                sampleTime++;
                
                
            }
            
            buffer.frameLength = kSamplesPerBuffer;
            
            
            // Schedule the buffer for playback and release it for reuse after playback has finished.
            [_bufferPlayer scheduleBuffer:buffer completionHandler:^{
                
                //free the semaphore
                dispatch_semaphore_signal(audioSemaphore);
                
                //notify the delegate
                [self.delegate updatedRepresentativeBufferValue:repval];
                free(repval);
                repval = NULL;
                
                return;
            }];
            
                
            bufferIndex = (bufferIndex + 1) % [_audioBuffers count];
        }
        
    });
    
    [_bufferPlayer play];
    
}

//MARK: AVAudioSession boiler plate
- (void)initAVAudioSession
{
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
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
        if (on){
            [self start];
        }
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        {
            NSLog(@"     NewDeviceAvailable");
            [self stop];
            [self.delegate audioEngineStopped];
            break;
        }
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            NSLog(@"     OldDeviceUnavailable");
            [self stop];
            [self.delegate audioEngineStopped];
            break;
        }
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
    
    if (on){
        [self start];
    }
}

@end
