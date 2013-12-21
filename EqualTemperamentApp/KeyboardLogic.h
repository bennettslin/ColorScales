//
//  KeyboardLogic.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/16/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyboardLogic : NSObject

+(BOOL)isWhiteKeyGivenScaleDegree:(NSNumber *)scaleDegree andTonesPerOctave:(NSUInteger)tonesPerOctave;
+(NSArray *)figureOutBlackKeysGivenTonesPerOctave:(NSUInteger)tonesPerOctave;
+(CGFloat)getBlackKeyTypeGivenIndexRow:(NSUInteger)indexRow andTonesPerOctave:(NSUInteger)tonesPerOctave;
+(CGFloat)getBlackKeyHeightMultiplierGivenBlackKeyType:(CGFloat)blackKeyType;
+(NSArray *)figureOutInitialExtraMultipliersGivenTonesPerOctave:(NSUInteger)tonesPerOctave;
+(CGFloat)getGapSizeGivenScaleDegree:(NSNumber *)scaleDegree andTonesPerOctave:(NSUInteger)tonesPerOctave;
+(NSUInteger)findPerfectFifthWithTonesPerOctave:(NSUInteger)tonesPerOctave;

@end
