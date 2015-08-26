//
//  AudioEngine.h
//  polypulse
//
//  Created by geb on 2015-06-04.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Metaronome.h"

@protocol AudioEngineDelegate <NSObject>

- (void)updatedRepresentativeBufferValue:(float)val;

@end


@interface AudioEngine : NSObject

@property (nonatomic) float amp;
@property (nonatomic) double period;
@property (nonatomic, weak) id <AudioEngineDelegate> delegate;

- (void)start;
- (void)stop;

- (void)addMetronome:(Metaronome *)met;
- (void)removeMetronome:(Metaronome *)met;
- (NSArray *)getMetronomes;

@end
