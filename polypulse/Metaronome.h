//
//  Metaronome.h
//  polypulse
//
//  Created by geb on 2015-06-05.
//  Copyright (c) 2015 geb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Metaronome : NSObject

@property (nonatomic) long  period;
@property (nonatomic) float freq;
@property (nonatomic) float amp;
@property (nonatomic) float pan;

@end
