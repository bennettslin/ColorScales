//
//  DataModel.h
//  EqualTemperamentApp
//
//  Created by Bennett Lin on 12/11/13.
//  Copyright (c) 2013 Bennett Lin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataModel : NSObject <NSCoding>

@property (strong, nonatomic) NSNumber *tonesPerOctave;
@property (strong, nonatomic) NSString *instrument;
@property (strong, nonatomic) NSString *keyCharacter;
@property (strong, nonatomic) NSString *keyboardStyle;
@property (strong, nonatomic) NSNumber *gridInterval;
@property (strong, nonatomic) NSString *colourStyle;
@property (strong, nonatomic) NSString *userButtonsPosition;

@end
