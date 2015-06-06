//
//  AudioEngine.h
//  polypulse
//
//  Created by geb on 2015-06-04.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Metaronome.h"

@interface AudioEngine : NSObject

@property (nonatomic) float amp;
@property (nonatomic) long period;

- (void)start;
- (void)stop;
- (void)addMetronome:(Metaronome *)met;

@end
