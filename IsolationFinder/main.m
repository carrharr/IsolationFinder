//
//  main.m
//  IsolationFinder
//
//  Created by Daniel Carrillo Harris on 6/20/18.
//  Copyright © 2018 dannyharris. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark PositionalObject
@interface PositionalObject : NSObject
-(instancetype _Nullable) initWithString: (NSString *) stringObject;
-(instancetype) initForCopy: (PositionalObject *) originalObject;

@property (nonatomic) NSString * name;
@property (nonatomic) NSPoint vector;
@property (nonatomic) double nearestDistance;

@end

@implementation PositionalObject

-(instancetype _Nullable) initWithString: (NSString *) stringObject {
    if (![self getItemsFromString:stringObject]) {
        return nil;
    }
    return self;
}

-(instancetype) initForCopy: (PositionalObject *) originalObject {
    self.name = [originalObject name];
    self.vector = [originalObject vector];
    self.nearestDistance = [originalObject nearestDistance];
    return self;
}

-(BOOL) getItemsFromString: (NSString *) string {
    NSString * noNewlinesString = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSArray* elements = [noNewlinesString componentsSeparatedByCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
    if (elements.count != 3) {
        return NO;
    }
    self.name = elements[0];
    self.vector = NSMakePoint([[elements objectAtIndex:1] intValue], [[elements objectAtIndex:2] intValue]);
    return YES;
}

@end

#pragma mark IsolationFinder
@interface IsolationFinder : NSObject

-(instancetype)initWithFile: (NSString *) file;
-(PositionalObject * _Nullable) findMostIsolated;
@property (nonatomic) NSMutableArray<PositionalObject*> * positionalObjects;

@end

@implementation IsolationFinder

- (instancetype) initWithFile: (NSString *) file {
    self.positionalObjects = [self getObjectsFromFile:file];
    if (self.positionalObjects == nil || self.positionalObjects.count < 3) {
        return nil;
    }
    return self;
}

- (PositionalObject * _Nullable) findMostIsolated {
    if (self.positionalObjects == nil) {
        printf("No objects found, you must have objects to execute this method.");
        return nil;
    }
    printf("Working...\n");
    float i = 0;
    PositionalObject * bestMatch;
    double farthest = 0.0;
    int amount = _positionalObjects.count;
    NSMutableArray * allObjects = _positionalObjects;
    for (int k = 0; k < amount; k++) {
        PositionalObject * object = allObjects[0];
        for (PositionalObject * compare in allObjects) {
            if (compare == object) { continue; }
            float distance = [self calculateDistanceBetween:object.vector and:compare.vector];
            if (compare.nearestDistance == 0.0) {
                compare.nearestDistance = distance;
            }
            if (object.nearestDistance == 0.0) {
                object.nearestDistance = distance;
            }
            if (compare.nearestDistance > distance) {
                compare.nearestDistance = distance;
            }
            if (object.nearestDistance > distance) {
                object.nearestDistance = distance;
            }
        }

        if (object.nearestDistance >= farthest) {
            farthest = object.nearestDistance;
            bestMatch = [[PositionalObject alloc] initForCopy:object];
        }
        
        [allObjects removeObjectAtIndex:0];
        i+=1;
        float percentage = (i/amount)*100;
        printf("\r%f%%, Best Guess is: %s", percentage, [bestMatch.name UTF8String]);
        fflush(stdout);
    }
    return bestMatch;
}

- (float)calculateDistanceBetween:(NSPoint)v1 and:(NSPoint)v2 {
    double dx = (v1.x-v2.x);
    double dy = (v1.y-v2.y);
    double dist = dx*dx + dy*dy;
    return dist;
}

- (NSMutableArray<PositionalObject*> *) getObjectsFromFile: (NSString *) string {
    NSMutableArray<PositionalObject*> * objects = [[NSMutableArray alloc] init];
    FILE *file = fopen([string UTF8String], "r");
    char buffer[256];
    while (fgets(buffer, sizeof(char)*256, file) != NULL){
        NSString* line = [NSString stringWithUTF8String:buffer];
        NSString * cleanLine = [line stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        PositionalObject * object = [[PositionalObject alloc] initWithString:cleanLine];
        if (object == nil) { continue; }
        [objects addObject:object];
    }
    return objects;
}

@end

#pragma mark Main

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSDate *startTime = [NSDate date];
        if (argc < 2) {
            printf("You need to add a path to a file  with the format <filename coordinate_x coordinate_y>");
            return (1);
        } else {
            NSString * file = [NSString stringWithFormat:@"%s", argv[1]];
            IsolationFinder * finder = [[IsolationFinder alloc] initWithFile: file];
            if (finder == nil) {
                printf("An error ocurred, check the file path and its internal format are correct");
                printf("Expected file format is a .txt with at least 3 objects. Objects must be on newlines");
                printf("Expected line format is <objectName coordinateX coordinateY>");
                return 1;
            }
            PositionalObject * result = [finder findMostIsolated];
            printf("\nCalculated most isolated %s in %f seconds\n", [result.name UTF8String], -[startTime timeIntervalSinceNow]);
            return 0;
        }
    }
    return 0;
}
