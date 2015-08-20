//
//  Metaronome.h
//  polypulse
//
//  Created by geb on 2015-06-05.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Metaronome : NSObject

@property (nonatomic)           double    pgroup;
@property (nonatomic)           double    tuplet;
@property (nonatomic)           double    tgroup;
@property (nonatomic)           float     freq;
@property (nonatomic)           float     amp;
@property (nonatomic)           float     pan;
@property (nonatomic, readonly) double     bpm;
@property (nonatomic, readonly) double    period;

- (void)setPeriod:(double)master;

@end
