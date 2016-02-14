/*---------------------------------------------------------------------------------------------------
 *
 * Copyright (c) Microsoft Corporation All rights reserved.
 *
 * MIT License:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the  "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 * NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ------------------------------------------------------------------------------------------------*/

#import "HeartRateViewController.h"

#define SENDHOST @"18.189.11.222" // IMPORTANT!
#define SENDPORT 3001
//#define RECEIVEPORT 3000

@interface HeartRateViewController ()<MSBClientManagerDelegate, UITextViewDelegate>
@property (nonatomic, weak) MSBClient *client;
@property (strong, nonatomic) F53OSCClient* oscClient;
//@property (strong, nonatomic) F53OSCServer* oscServer;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *argumentsLabel;
@end

@implementation HeartRateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Setup View
    [self markSampleReady:NO];
    self.txtOutput.delegate = self;
    UIEdgeInsets insets = [self.txtOutput textContainerInset];
    insets.top = 20;
    insets.bottom = 20;
    [self.txtOutput setTextContainerInset:insets];
    
    self.hostIP = SENDHOST;
    
    // Setup Band
    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    self.client = [clients firstObject];
    if (self.client == nil)
    {
        [self output:@"Failed! No Bands attached."];
        return;
    }
    
    [[MSBClientManager sharedManager] connectClient:self.client];
    [self output:[NSString stringWithFormat:@"Please wait. Connecting to Band <%@>", self.client.name]];
    
    // Setup OSC Sender
    
    self.oscClient = [[F53OSCClient alloc] init];
//    self.oscServer = [[F53OSCServer alloc] init];
//    [self.oscServer setPort:RECEIVEPORT];
//    [self.oscServer setDelegate:self];
//    [self.oscServer startListening];
    
}

- (void)sendMessageWithPattern:(NSString *)pattern arguments:(NSArray *)arguments {
//    pattern = @"/derp";
//    arguments = @[@"A derpy message.",@1,@5.82];
    F53OSCMessage *message = [F53OSCMessage messageWithAddressPattern:pattern arguments:arguments];
    [self.oscClient sendPacket:message toHost:self.hostIP onPort:SENDPORT];
    NSLog(@"Send Message: %@", message);
}

- (IBAction)didTapStartHRSensorButton:(id)sender
{
    self.hostIP = self.hostIpTextField.text;
    NSLog(@"set hostIP to %@", self.hostIP);
    [self markSampleReady:NO];
    if ([self.client.sensorManager heartRateUserConsent] == MSBUserConsentGranted)
    {
        [self startHearRateUpdates];
    }
    else
    {
        [self output:@"Requesting user consent for accessing HeartRate..."];
        __weak typeof(self) weakSelf = self;
        [self.client.sensorManager requestHRUserConsentWithCompletion:^(BOOL userConsent, NSError *error) {
            if (userConsent)
            {
                [weakSelf startHearRateUpdates];
            }
            else
            {
                [weakSelf sampleDidCompleteWithOutput:@"User consent declined."];
            }
        }];
    }
}

- (void)startHearRateUpdates
{
    [self output:@"Starting Heart Rate updates..."];
    
    __weak typeof(self) weakSelf = self;
    void (^handler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
        weakSelf.hrLabel.text = [NSString stringWithFormat:@"Heart Rate: %3u %@",
                                 (unsigned int)heartRateData.heartRate,
                                 heartRateData.quality == MSBSensorHeartRateQualityAcquiring ? @"Acquiring" : @"Locked"];
        NSLog(@"%@", heartRateData);
        [weakSelf sendMessageWithPattern:@"/heartrate" arguments:@[ [NSNumber numberWithUnsignedLong: heartRateData.heartRate] ]];
    };
    
    NSError *stateError;
    if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:handler])
    {
        [self sampleDidCompleteWithOutput:stateError.description];
        return;
    }
    
//    [self performSelector:@selector(stopHeartRateUpdates) withObject:nil afterDelay:60];
}

- (void)stopHeartRateUpdates
{
    [self.client.sensorManager stopHeartRateUpdatesErrorRef:nil];
    [self sampleDidCompleteWithOutput:@"Heart Rate updates stopped..."];
}

#pragma mark - Helper methods

- (void)sampleDidCompleteWithOutput:(NSString *)output
{
    [self output:output];
    [self markSampleReady:YES];
}

- (void)markSampleReady:(BOOL)ready
{
    self.startHRSensorButton.enabled = ready;
    self.startHRSensorButton.alpha = ready ? 1.0 : 0.2;
}

- (void)output:(NSString *)message
{
    if (message)
    {
        self.txtOutput.text = [NSString stringWithFormat:@"%@\n%@", self.txtOutput.text, message];
        [self.txtOutput layoutIfNeeded];
        if (self.txtOutput.text.length > 0)
        {
            [self.txtOutput scrollRangeToVisible:NSMakeRange(self.txtOutput.text.length - 1, 1)];
        }
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

#pragma mark - MSBClientManagerDelegate

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client
{
    [self markSampleReady:YES];
    [self output:[NSString stringWithFormat:@"Band <%@> connected.", client.name]];
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    [self markSampleReady:NO];
    [self output:[NSString stringWithFormat:@"Band <%@> disconnected.", client.name]];
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    [self output:[NSString stringWithFormat:@"Failed to connect to Band <%@>.", client.name]];
    [self output:error.description];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

@end
