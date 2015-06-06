//
//  Metaronome.m
//  polypulse
//
//  Created by geb on 2015-06-05.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import "Metaronome.h"

@implementation Metaronome


- (double)period:(double)master {
    return ((master * _pgroup) / _tuplet) * _tgroup;
}

@end
