//
//  Metaronome.m
//  polypulse
//
//  Created by geb on 2015-06-05.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import "Metaronome.h"

@implementation Metaronome


- (instancetype)init{
    self = [super init];
    if (self) {
        
        //set the default
        _pgroup = 1.0;
        _tuplet = 1.0;
        _tgroup = 1.0;
        _freq = 220.0;
        _pan = 0.5;
        _amp = 1.0;
        
    }
    return self;
}

- (void)setPeriod:(double)master {
    _period = ((master * _pgroup) / _tuplet) * _tgroup;
    _bpm = 44100.0 * 60.0 / _period;
}

@end
