//
//  KeyboardLogic.m
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/16/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import "KeyboardLogic.h"

@implementation KeyboardLogic

+(BOOL)isWhiteKeyGivenScaleDegree:(NSNumber *)scaleDegree andTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSArray *theWhiteKeys;
  switch (tonesPerOctave) {
    case 12:
      theWhiteKeys = @[@0, @2, @4, @5, @7, @9, @11];
      break;
    case 17:
      theWhiteKeys = @[@0, @3, @6, @7, @10, @13, @16];
      break;
    case 19:
      theWhiteKeys = @[@0, @3, @6, @8, @11, @14, @17];
      break;
    case 24:
      theWhiteKeys = @[@0, @4, @8, @10, @14, @18, @22];
      break;
    case 31:
      theWhiteKeys = @[@0, @5, @10, @13, @18, @23, @28];
      break;
    case 41:
      theWhiteKeys = @[@0, @7, @14, @17, @24, @31, @38];
      break;
  }
  if ([theWhiteKeys containsObject:scaleDegree]) {
    return YES;
  } else {
    return NO;
  }
}

+(NSArray *)figureOutBlackKeysGivenTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSArray *theBlackKeys = @[@[]];
  switch (tonesPerOctave) {
    case 12:
      theBlackKeys = @[@[@1, @3, @6, @8, @10]];
      break;
    case 17:
      theBlackKeys = @[@[@2, @5, @9, @12, @15], @[@1, @4, @8, @11, @14]];
      break;
    case 19:
      theBlackKeys = @[@[@7, @18], @[@2, @5, @10, @13, @16], @[@1, @4, @9, @12, @15]];
      break;
    case 24:
      theBlackKeys = @[@[@9, @23], @[@3, @7, @13, @17, @21], @[@2, @6, @12, @16, @20], @[@1, @5, @11, @15, @19]];
      break;
    case 31:
      theBlackKeys = @[@[@4, @9, @17, @22, @27], @[@12, @30], @[@3, @8, @16, @21, @26], @[@2, @7, @15, @20, @25], @[@11, @29], @[@1, @6, @14, @19, @24]];
      break;
    case 41:
      theBlackKeys = @[@[@6, @13, @23, @30, @37], @[@5, @12, @22, @29, @36], @[@16, @40], @[@4, @11, @21, @28, @35], @[@3, @10, @20, @27, @34], @[@15, @39], @[@2, @9, @19, @26, @33], @[@1, @8, @18, @25, @32]];
      break;
  }
  return theBlackKeys;
}

+(CGFloat)getBlackKeyTypeGivenIndexRow:(NSUInteger)indexRow andTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSArray *blackKeyTypes;
  switch (tonesPerOctave) {
    case 12:
      blackKeyTypes = @[@(11/18.f + 0.00001f)]; // regular black key
      break;
    case 17:
      blackKeyTypes = @[@(2/3.f), @(1/3.f)];
      break;
    case 19:
      blackKeyTypes = @[@(11/18.f + 0.00001f), @(2/3.f - 1/15.f - 0.00001f), @(1/3.f + 1/15.f + 0.00001f)];
      break;
    case 24:
      blackKeyTypes = @[@(11/18.f + 0.00001f), @(3/4.f - 1/12.f - 0.00001f), @(2/4.f), @(1/4.f + 1/12.f + 0.00001f)];
      break;
    case 31:
      blackKeyTypes = @[@(4/5.f), @(2/3.f - 1/15.f - 0.00001f), @(3/5.f), @(2/5.f), @(1/3.f + 1/15.f + 0.00001f), @(1/5.f)];
      break;
    case 41:
      blackKeyTypes = @[@(6/7.f - 3/42.f - 0.00002f), @(5/7.f - 2/42.f - 0.00002f), @(2/3.f - 1/9.f - 0.00001f),
                        @(4/7.f - 1/42.f - 0.00002f), @(3/7.f + 1/42.f + 0.00002f), @(1/3.f + 1/9.f + 0.00001f),
                        @(2/7.f + 2/42.f + 0.00002f), @(1/7.f + 3/42.f + 0.00002f)];
      break;
  }
  return [blackKeyTypes[indexRow] floatValue];
}

+(CGFloat)getBlackKeyHeightMultiplierGivenBlackKeyType:(CGFloat)blackKeyType {
  if (blackKeyType == 11/18.f + 0.00001f) {
    return 11/18.f;
  } else if (blackKeyType == 2/3.f - 1/15.f - 0.00001f) {
    return 2/3.f;
  } else if (blackKeyType == 1/3.f + 1/15.f + 0.00001f) {
    return 1/3.f;
  } else if (blackKeyType == 3/4.f - 1/12.f - 0.00001f) {
    return 3/4.f;
  } else if (blackKeyType == 1/4.f + 1/12.f + 0.00001f) {
    return 1/4.f;
  } else if (blackKeyType == 6/7.f - 3/42.f - 0.00002f) {
    return 6/7.f;
  } else if (blackKeyType == 5/7.f - 2/42.f - 0.00002f) {
    return 5/7.f;
  } else if (blackKeyType == 4/7.f - 1/42.f - 0.00002f) {
    return 4/7.f;
  } else if (blackKeyType == 3/7.f + 1/42.f + 0.00002f) {
    return 3/7.f;
  } else if (blackKeyType == 2/7.f + 2/42.f + 0.00002f) {
    return 2/7.f;
  } else if (blackKeyType == 1/7.f + 3/42.f + 0.00002f) {
    return 1/7.f;
  } else if (blackKeyType == 2/3.f - 1/9.f - 0.00001f) {
    return 2/3.f;
  } else if (blackKeyType == 1/3.f + 1/9.f + 0.00001f) {
    return 1/3.f;
  }
  return blackKeyType;
}

+(NSArray *)figureOutInitialExtraMultipliersGivenTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSArray *initialExtraMultipliers = @[];
  switch (tonesPerOctave) {
    case 12:
      initialExtraMultipliers = @[@0];
      break;
    case 17:
      initialExtraMultipliers = @[@0, @0];
      break;
    case 19:
      initialExtraMultipliers = @[@2, @0, @0];
      break;
    case 24:
      initialExtraMultipliers = @[@2, @0, @0, @0];
      break;
    case 31:
      initialExtraMultipliers = @[@0, @2, @0, @0, @2, @0];
      break;
    case 41:
      initialExtraMultipliers = @[@0, @0, @2, @0, @0, @2, @0, @0];
      break;
  }
  return initialExtraMultipliers;
}

+(CGFloat)getGapSizeGivenScaleDegree:(NSNumber *)scaleDegree andTonesPerOctave:(NSUInteger)tonesPerOctave {
  NSArray *lastBlackKeysBeforeGap;
  NSArray *gapSizes = @[];
  switch (tonesPerOctave) {
    case 12:
      lastBlackKeysBeforeGap = @[@3, @10];
      gapSizes = @[@1, @1];
      break;
    case 17:
      lastBlackKeysBeforeGap = @[@4, @5, @14, @15];
      gapSizes = @[@1, @1, @1, @1];
      break;
    case 19:
      lastBlackKeysBeforeGap = @[@4, @5, @7, @15, @16, @18];
      gapSizes = @[@1, @1, @3, @1, @1, @2];
      break;
    case 24:
      lastBlackKeysBeforeGap = @[@5, @6, @7, @9, @19, @20, @21, @23];
      gapSizes = @[@1, @1, @1, @3, @1, @1, @1, @2];
      break;
    case 31:
      lastBlackKeysBeforeGap = @[@6, @7, @8, @9, @11, @12, @24, @25, @26, @27, @29, @30];
      gapSizes = @[@1, @1, @1, @1, @3, @3, @1, @1, @1, @1, @2, @2];
      break;
    case 41:
      lastBlackKeysBeforeGap = @[@8, @9, @10, @11, @12, @13, @15, @16, @32, @33, @34, @35, @36, @37, @39, @40];
      gapSizes = @[@1, @1, @1, @1, @1, @1, @3, @3, @1, @1, @1, @1, @1, @1, @2, @2];
  }
  if ([lastBlackKeysBeforeGap containsObject:scaleDegree]) {
    NSInteger gapRowIndex = [lastBlackKeysBeforeGap indexOfObject:scaleDegree];
    return [gapSizes[gapRowIndex] floatValue];
  }
  return 0.f;
}

+(NSUInteger)findPerfectFifthWithTonesPerOctave:(NSUInteger)tonesPerOctave {
  float semitoneInterval = pow(2.f, (1.f / tonesPerOctave));
  NSUInteger scaleDegree = 1;
  float tempRatio = semitoneInterval;
    // find scale degree that results in first ratio greater than 1.5
  while (tempRatio < 1.5f) {
    tempRatio *= semitoneInterval;
      //    NSLog(@"%f", tempRatio);
    scaleDegree += 1;
  }
    // compare the two ratio to see which is closer to 1.5
  float lowerRatioDiff = 1.5 - (tempRatio / semitoneInterval);
  float higherRatioDiff = tempRatio - 1.5;
  if (lowerRatioDiff < higherRatioDiff) {
    return scaleDegree - 1;
  } else {
    return scaleDegree;
  }
}

@end
