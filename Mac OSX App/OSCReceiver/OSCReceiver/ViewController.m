//
//  ViewController.m
//  ExampleOSC
//
//  Created by Charles Martin on 21/05/2014.
//  Copyright (c) 2014 Charles Martin. All rights reserved.
//

#import "ViewController.h"
#import "F53OSCServer.h"

#define RECEIVEPORT 3001

@interface ViewController ()
@property (strong, nonatomic) F53OSCServer* oscServer;
@property (strong, nonatomic) NSString* dataWritePath;

@property (strong, nonatomic) NSMutableArray* recentHeartRateValues;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.oscServer = [[F53OSCServer alloc] init];
    [self.oscServer setPort:RECEIVEPORT];
    [self.oscServer setDelegate:self];
    [self.oscServer startListening];
    
    self.recentHeartRateValues = [NSMutableArray arrayWithCapacity:3];
    
    // default path is @"/Users/benreynolds/Documents/MakeMIT/HeartonographSubmission/HeartRateData/data.txt"
    self.dataWritePath = self.heartrateFilepathTextField.stringValue;
    
    // create file for heart rate data to send to arduino
    [[NSFileManager defaultManager] createFileAtPath:self.dataWritePath contents:nil attributes:nil];
}

-(void)takeMessage:(F53OSCMessage *)message {
    NSLog(@"Message Received");
    if ([message.addressPattern isEqualToString:@"/heartrate"]) {
        if (message.arguments.count > 0) {
            int heartRate = [[message.arguments objectAtIndex:0] intValue];
            NSLog(@"heartRate = %i", heartRate);
            
            NSString *writeString = [NSString stringWithFormat:@"%i,", heartRate];
            
            // use this if you want to overwrite the file each time with a single value
            [writeString writeToFile:self.dataWritePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            // use this if you want to append another value with each write
            
//            NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:self.dataWritePath];
//            [myHandle seekToEndOfFile];
//            [myHandle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
}

- (IBAction)updateHeartRateFilepath:(NSButton *)sender {
    self.dataWritePath = self.heartrateFilepathTextField.stringValue;
    [[NSFileManager defaultManager] createFileAtPath:self.dataWritePath contents:nil attributes:nil];

}

@end
