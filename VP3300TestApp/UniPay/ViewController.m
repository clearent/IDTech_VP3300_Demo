//
//  ViewController.m
//  VP3300
//
//  Created by zhong howard on 13-3-18.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController
@synthesize resultsTextView;
@synthesize dataTextView;
@synthesize connectedLabel;
@synthesize txtAPDUData;
@synthesize txtDirectIO;
@synthesize txtAmount;
@synthesize cmd;
@synthesize subcmd;
@synthesize friendlyName;

@synthesize sView;
@synthesize view1;
@synthesize view2;
@synthesize view4;
@synthesize view5;
@synthesize view6;
@synthesize view7;
@synthesize pcControlPanes;
@synthesize prompt_doConnection;
@synthesize prompt_doConnection_Low_Volume;

//CLEARENT: This is the object you will interact with.
Clearent_VP3300 *clearentVP3300;

extern int g_IOS_Type;

-(void) appendMessageToResults:(NSString*) message{
    [self performSelectorOnMainThread:@selector(_appendMessageToResults:) withObject:message waitUntilDone:false];
    
}
-(void) _appendMessageToResults:(id)object{
    [self.resultsTextView setText:[NSString stringWithFormat:@"%@\n%@\n", self.resultsTextView.text,(NSString*)object]];
    // [self.resultsTextView scrollRangeToVisible:NSMakeRange([self.resultsTextView.text length], 0)];
    
}

-(void) appendMessageToData:(NSString*) message{
    [self performSelectorOnMainThread:@selector(_appendMessageToData:) withObject:message waitUntilDone:false];
    
}
-(void) _appendMessageToData:(id)object{
    [self.dataTextView setText:[NSString stringWithFormat:@"%@\n%@\n", self.dataTextView.text, (NSString*)object]];
    // [self.dataTextView scrollRangeToVisible:NSMakeRange([self.dataTextView.text length], 0)];
    
}

- (IBAction) DoClearLog:(id)sender{
    [self.resultsTextView setText: @""];
    //[self.resultsTextView scrollRangeToVisible:NSMakeRange([self.resultsTextView.text length], 0)];
    [self.dataTextView setText: @""];
    //[self.dataTextView scrollRangeToVisible:NSMakeRange([self.resultsTextView.text length], 0)];
}

//for return IDTResult type function
-(void) displayUpRet2:(NSString*) operation returnValue: (RETURN_CODE)rt
{
    
    NSString * str = [NSString stringWithFormat:
                      @"%@ ERROR: ID-\"%i\", message: %@.",
                      operation, rt, [clearentVP3300 device_getResponseCodeString:rt]];
    [self appendMessageToResults:str];
    
}

- (IBAction) DoKeyboardOff:(id)sender{
    [sender resignFirstResponder];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if ([alertView.title isEqualToString:@"PIN REQUEST"]) {
        if(buttonIndex == 1){
            NSString* PIN = [[alertView textFieldAtIndex:0] text] ;
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            
            [clearentVP3300 emv_callbackResponsePIN:_mode KSN:nil PIN:[PIN dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@"PIN Value is %@",PIN);
        }
        else{
            [clearentVP3300 emv_callbackResponsePIN:EMV_PIN_MODE_CANCEL KSN:nil PIN:nil];
        }
        
    }
    
    if ([alertView.title isEqualToString:@"Please Select"]) {
        if(buttonIndex == 1){
            int selectedValue = [[[alertView textFieldAtIndex:0] text] intValue];
            [[alertView textFieldAtIndex:0] resignFirstResponder];
            
            [clearentVP3300 emv_callbackResponseLCD:_lcdDisplayMode selection:(unsigned char)selectedValue];
            NSLog(@"Selected Value is %i",selectedValue);
        }
        else{
            [clearentVP3300 emv_callbackResponseLCD:0 selection:0];
        }
        
    }
    
    if (alertView == prompt_doConnection || alertView == prompt_doConnection_Low_Volume)
    {
        //selected option to start the connection task at the reader attachment prompt
        if (1 == buttonIndex) {
            //[self appendMessageToResults: @"Start Connect Task..."];
            [clearentVP3300 device_connectToAudioReader];
            
        }
    }
    
    
}






#pragma mark - VP3300 Delegate methods
static int _lcdDisplayMode = 0;

- (void) lcdDisplay:(int)mode  lines:(NSArray*)lines{
    NSMutableString* str = [NSMutableString new];
    _lcdDisplayMode = mode;
    if (lines != nil) {
        for (NSString* s in lines) {
            [str appendString:s];
            [str appendString:@"\n"];
        }
    }
    
    switch (mode) {
        case 0x10:
            //clear screen
            NSLog(@"Clear screen");
            resultsTextView.text = @"";
            break;
        case 0x03:
            NSLog(@"Add to ResultsTextView %@", str);
            resultsTextView.text = str;
            break;
        case 0x01:
        case 0x02:
        case 0x08:{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Please Select" message:str delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        }
            
            break;
        default:
            NSLog(@"undefined mode ?");
            break;
    }
}
static EMV_PIN_MODE_Types _mode = EMV_PIN_MODE_CANCEL;
- (void) pinRequest:(EMV_PIN_MODE_Types)mode  key:(NSData*)key  PAN:(NSData*)PAN startTO:(int)startTO intervalTO:(int)intervalTO language:(NSString*)language{
    _mode = mode;
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"PIN REQUEST" message:@"Please Enter PIN" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert show];
}

- (void) dataInOutMonitor:(NSData*)data  incoming:(BOOL)isIncoming{
    [self appendMessageToData:[NSString stringWithFormat:@"%@: %@",isIncoming?@"IN":@"OUT",data.description]];
}


- (void) plugStatusChange:(BOOL)deviceInserted{
    if (deviceInserted) {
        //[self appendMessageToResults: @"device Attached."];
        
        if ([[AVAudioSession sharedInstance] outputVolume] < 1.0) {
            [prompt_doConnection_Low_Volume show];
        } else{
            [prompt_doConnection show];
        }
        
    }
    else{
        // [self appendMessageToResults: @"device removed."];
        [self dismissAllAlertViews];
    }
}

-(void)deviceConnected{
    NSLog(@"Connected --");
    connectedLabel.text = @"Connected";
    [self appendMessageToResults:@"(VP3300 Connected)"];
    [self appendMessageToResults:[NSString stringWithFormat:@"Framework Version: %@",[IDT_Device SDK_version]]];
    NSLog(@"Run the reader configuration once. For now it will run every time for demo purposes");
}

-(void)deviceDisconnected{
    NSLog(@"DisConnt --");
    connectedLabel.text = @"Disconnect";
    // [self appendMessageToResults:@"([VP3300 sharedController] Disconnect)"];
    
}


-(void) eventFunctionICC: (Byte) nICC_Attached{
    NSLog(@"VP3300_EventFunctionICC Return Status Code %2X ",  nICC_Attached);
    [self appendMessageToResults:[NSString stringWithFormat:@"\nVP3300_EventFunctionICC Return Status Code %2X ",  nICC_Attached]];
    
}

-(void) dismissAllAlertViews {
    [prompt_doConnection dismissWithClickedButtonIndex:-1 animated:FALSE];
    [prompt_doConnection_Low_Volume dismissWithClickedButtonIndex:-1 animated:FALSE];
}

- (void) deviceMessage:(NSString*)message{
    [self appendMessageToResults:message];
}



-(void) showAlertView:(NSString*)msg {
    [self dismissAllAlertViews];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"VP3300"
                              message:msg
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
    [alertView show];
    //[alertView release];
    alertView = nil;
}

#pragma mark - View methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //init alert views
    prompt_doConnection = [[UIAlertView alloc]
                           initWithTitle:@"VP3300"
                           message:@"Device detected in headphone jack. Try connecting it?"
                           delegate:self
                           cancelButtonTitle:@"Cancel"
                           otherButtonTitles:@"OK",nil];
    prompt_doConnection_Low_Volume = [[UIAlertView alloc]
                                      initWithTitle:@"VP3300"
                                      message:@"Device detected in headphone jack. Try connecting it? WARNING: Low volume detected. Please increase headphone volume to MAXIMUM before proceeding with connection attempt."
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"OK",nil];
    
    //for iPhone
    if (0 == g_IOS_Type) {
        CGRect frame = self.sView.frame;
        frame.size.width = [UIScreen mainScreen].bounds.size.width;
        CGSize contentSize = frame.size;
        contentSize.width *= 6;
        self.sView.contentSize = contentSize;
        
        // add to scroll view
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * 5   ;
        self.view7.frame = frame;
        [self.sView addSubview: self.view7];
        
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * 4   ;
        self.view2.frame = frame;
        [self.sView addSubview: self.view2];
        
        
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * 3   ;
        self.view6.frame = frame;
        [self.sView addSubview: self.view6];
        
        
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * 2   ;
        self.view5.frame = frame;
        [self.sView addSubview: self.view5];
        
        
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * 1;
        self.view4.frame = frame;
        [self.sView addSubview: self.view4];
        
        frame.origin.y = 0;
        frame.origin.x = frame.size.width * 0;
        self.view1.frame = frame;
        [self.sView addSubview: self.view1];
        
        self.pcControlPanes.numberOfPages = 5;
        self.pcControlPanes.currentPage = 0;
    }
    
    
    //init object
#ifndef __i386__
    //CLEARENT: Initialize the clearentVP3300 object with your public delegate, the Clearent Base Url, and the public key Clearent provided. In this example, the ViewController is your delegate (Clearent_Public_IDTech_VP3300_Delegate).
    clearentVP3300 = [[Clearent_VP3300 alloc]  init];
    [clearentVP3300 init:self clearentBaseUrl:@"https://gateway-qa.clearent.net" publicKey:@"307a301406072a8648ce3d020106092b240303020801010c0362000474ce100cfdf0f3e15782c96b41f20522d5660e8474a753722e2b9c0d3a768a068c377b524750dd89163866caad1aba885fd34250d3e122b789499f87f262a0204c6e649617604bcebaa730bf6c2a74cf54a69abf9f6bf7ecfed3e44e463e31fc"];
    NSLog(@"clearentVP3300 has been initialized");
#endif
    [friendlyName setText: [clearentVP3300 device_getBLEFriendlyName]];
    //[friendlyName setText: @"IDTECH-VP3300-66797"];
    //[friendlyName setText: @"VP-2722"];
}

//CLEARENT: A public delegate implementation alerting you when the transaction token is successful. In this demo we've added code to use the JWT and immediately run a test payment transaction.
-(void) successfulTransactionToken:(NSString*) jsonString {
    NSLog(@"A clearent transaction token (JWT) has been created. Let's show an example of how to use it.");
    NSLog(@"%@",jsonString);
    [self appendMessageToResults:jsonString];
    
    NSDictionary *successfulResponseDictionary = [self jsonAsDictionary:jsonString];
    NSDictionary *payload = [successfulResponseDictionary objectForKey:@"payload"];
    NSDictionary *emvJwt = [payload objectForKey:@"mobile-jwt"];
    NSString *cvm = [emvJwt objectForKey:@"cvm"];
    NSString *lastFour = [emvJwt objectForKey:@"last-four"];
    NSString *trackDataHash = [emvJwt objectForKey:@"track-data-hash"];
    NSString *jwt = [emvJwt objectForKey:@"jwt"];
    NSLog(@"%@",jwt);
    NSLog(@"%@",cvm);
    NSLog(@"%@",lastFour);
    NSLog(@"%@",trackDataHash);
    
    [self exampleUseJwtToRunPaymentTransaction:jwt];
}

- (void) exampleUseJwtToRunPaymentTransaction:(NSString*)jwt {
    NSLog(@"%@Run the transaction...",jwt);
    //Construct the url
    NSString *targetUrl = [NSString stringWithFormat:@"%@/rest/v2/mobile/transactions", @"https://gateway-qa.clearent.net"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    //Create a sample json request.
    NSData *postData = [self exampleClearentTransactionRequestAsJson];
    //Build a url request. It's a POST.
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    //Use json
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //add a test apikey as a header
    [request setValue:@"12fa1a5617464354a72b3c9eb92d4f3b" forHTTPHeaderField:@"api-key"];
    
    //add the JWT as a header.
    [request setValue:jwt forHTTPHeaderField:@"mobilejwt"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    //Do the Post. Report the result to your user (this example sends the message to the console on the demo app (lower left corner of ui)).
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          //Clearent returns an object that is defined the same for both successful and unsuccessful calls with one exception. The 'payload' can be different.
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSLog(@"Clearent Transaction Response status code: %ld", (long)[httpResponse statusCode]);
          if(error != nil) {
              [self appendMessageToResults:error.description];
          } else if(data != nil && [httpResponse statusCode] == 200) {
              NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              NSDictionary *successfulResponseDictionary = [self jsonAsDictionary:responseStr];
              NSDictionary *payload = [successfulResponseDictionary objectForKey:@"payload"];
              NSDictionary *transaction = [payload objectForKey:@"transaction"];
              NSString *transactionId = [transaction objectForKey:@"id"];
              [self exampleRequestReceipt:transactionId];
              [self appendMessageToResults:responseStr];
              NSLog(@"Clearent Transaction : %s", responseStr);
          } else {
              NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              [self appendMessageToResults:responseStr];
              NSLog(@"Clearent Transaction : %s", responseStr);
          }
      }] resume];
}

- (NSData*) exampleClearentTransactionRequestAsJson {
    NSDictionary* dict = @{@"amount":txtAmount.text,@"type":@"SALE"};
    return [NSJSONSerialization dataWithJSONObject:dict
                                           options:NSJSONWritingPrettyPrinted error:nil];
}

- (NSDictionary *)jsonAsDictionary:(NSString *)stringJson {
    NSData *data = [stringJson dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:&error];
    if (error) {
        NSLog(@"Error json: %@", [error description]);
    }
    
    //let's send a receipt request
    return jsonDictionary;
}

- (void) exampleRequestReceipt:(NSString*)transactionId {
    if(transactionId == nil) {
        return;
    }
    NSLog(@"%@Request a receipt for transaction...",transactionId);
    //Construct the url
    NSString *targetUrl = [NSString stringWithFormat:@"%@/rest/v2/receipts", @"https://gateway-qa.clearent.net"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    NSDictionary* dict = @{@"id":transactionId,@"email-address":@"dhigginbotham@clearent.com"};
    NSData *postData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted error:nil];
    //Build a url request. It's a POST.
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    //Use json
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //add a test apikey as a header
    [request setValue:@"12fa1a5617464354a72b3c9eb92d4f3b" forHTTPHeaderField:@"api-key"];
    
    [request setURL:[NSURL URLWithString:targetUrl]];
    //Do the Post. Report the result to your user (this example sends the message to the console on the demo app (lower left corner of ui)).
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          //Clearent returns an object that is defined the same for both successful and unsuccessful calls with one exception. The 'payload' can be different.
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSLog(@"Clearent Transaction Response status code: %ld", (long)[httpResponse statusCode]);
          if(error != nil) {
              [self appendMessageToResults:error.description];
          } else if(data != nil) {
              NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
              [self appendMessageToResults:responseStr];
              NSLog(@"Clearent Receipt Request Response : %s", responseStr);
          }
      }] resume];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (IBAction) f_searchForBLE:(id)sender{
    [self appendMessageToResults: @"Enabling Search for BLE"];
    NSUUID* val = nil;
    //val = [[NSUUID alloc] initWithUUIDString:@"9D4FEF5F-D203-4DA8-B970-FC470D0CDC4D"];
    if ([friendlyName text].length > 0) [clearentVP3300 device_setBLEFriendlyName:[friendlyName text]];
    [clearentVP3300 device_enableBLEDeviceSearch:val];
}

- (IBAction) f_getBLEUDID:(id)sender{
    [self appendMessageToResults: [NSString stringWithFormat:@"Currently connected BLE UUID:  %@", [clearentVP3300 device_connectedBLEDevice].UUIDString]];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (sender != self.sView)
        return;
    
    //for iPhone
    if (0 == g_IOS_Type) {
        //update UIPageControl object
        CGFloat pageWidth = self.sView.frame.size.width;
        int page = floor((self.sView.contentOffset.x + pageWidth / 2) / pageWidth);
        self.pcControlPanes.currentPage = page;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"--viewDidAppear");
    BOOL b = [clearentVP3300 isConnected];
    if(b==YES)
    {
        [self deviceConnected];
        //[self appendMessageToResults:@"[[VP3300 sharedController] Open Success]"];
    }
    else
    {
        [self deviceDisconnected];
        //[self appendMessageToResults:@"Reader failed to connect. Check for any device messages. If you see a message RETURN_CODE_LOW_VOLUME turn up the Headphones volume and reconnect the reader."];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - spec methods


- (IBAction) f_getFirm:(id)sender
{
    
    NSString *result;
    RETURN_CODE rt = [clearentVP3300  device_getFirmwareVersion:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Get FM info:  %@", result]];
    }
    else{
        [self displayUpRet2: @"Get FM info" returnValue: rt];
    }
}
- (IBAction) f_getL2:(id)sender
{    NSString *result;
    RETURN_CODE rt = [clearentVP3300  emv_getEMVL2Version:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Get EMV L2 Version info:  %@", result]];
    }
    else{
        [self displayUpRet2: @"Get EMV L2 Version info" returnValue: rt];
    }
}

- (IBAction) f_cancelTrans:(id)sender{
    RETURN_CODE rt = [clearentVP3300  device_cancelTransaction];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"Cancel Transaction Successful"];
    }
    else{
        [self displayUpRet2: @"Cancel Transaction Failed " returnValue: rt];
    }
}
- (IBAction) f_allowPIN:(id)sender{
    [self appendMessageToResults:@"Setting Major Terminal Configuration to 1C"];
    RETURN_CODE rt = [clearentVP3300  emv_setTerminalMajorConfiguration:1];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"Major Config Set OK "];
    }
    else{
        [self displayUpRet2: @"Setting Major Config Failed " returnValue: rt];
        return;
    }
    [self appendMessageToResults:@"Setting Terminal Tags To Allow PIN"];
    
    
    NSString* TLVstring = @"5F3601029F1A0208409F3501229F3303E0F8C89F4005F000F0A0019F1E085465726D696E616C9F150212349F160F3030303030303030303030303030309F1C0838373635343332319F4E2231303732312057616C6B65722053742E20437970726573732C204341202C5553412EDF260101DF1008656E667265737A68DF110101DF270100DFEE150101DFEE160100DFEE170105DFEE180180DFEE1E08F0DC3CF0C29E9400DFEE1F0180DFEE1B083030303130353030DFEE20013CDFEE21010ADFEE2203323C3C";
    NSData* TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setTerminalData:[IDTUtility TLVtoDICT:TLV]];
    
    
    
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"Terminal Tags Set OK "];
    }
    else{
        [self displayUpRet2: @"Setting Terminal Tags Failed " returnValue: rt];
    }
}
- (IBAction) f_noPin:(id)sender{
    [self appendMessageToResults:@"Setting Major Terminal Configuration to 2C"];
    RETURN_CODE rt = [clearentVP3300  emv_setTerminalMajorConfiguration:2];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"Major Config Set OK "];
    }
    else{
        [self displayUpRet2: @"Setting Major Config Failed " returnValue: rt];
        return;
    }
    [self appendMessageToResults:@"Setting Terminal Tags To Not Allow PIN"];
    
    
    
    NSString* TLVstring = @"5F3601029F1A0208409F3501219F33036028C89F4005F000F0A0019F1E085465726D696E616C9F150212349F160F3030303030303030303030303030309F1C0838373635343332319F4E2231303732312057616C6B65722053742E20437970726573732C204341202C5553412EDF260101DF1008656E667265737A68DF110100DF270100DFEE150101DFEE160100DFEE170105DFEE180180DFEE1E08D0DC20D0C41E1400DFEE1F0180DFEE1B083030303130353030DFEE20013CDFEE21010ADFEE2203323C3C";
    NSData* TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setTerminalData:[IDTUtility TLVtoDICT:TLV]];
    
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"Terminal Tags Set OK "];
    }
    else{
        [self displayUpRet2: @"Setting Terminal Tags Failed " returnValue: rt];
    }
}


- (IBAction) f_loadDefaultAID:(id)sender{
    NSString* name = @"a0000000031010";
    NSString* TLVstring = @"5f5701005f2a0208409f090200095f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    NSData* TLV = [IDTUtility hexToData:TLVstring];
    RETURN_CODE rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    
    name = @"a00000999901";
    TLVstring = @"5f5701005f2a0208409f090299995f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    
    name = @"a000000003101003";
    TLVstring = @"5f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    
    name = @"a000000003101004";
    TLVstring = @"5f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    
    name = @"a000000003101005";
    TLVstring = @"5f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a000000003101006";
    TLVstring = @"5f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a000000003101007";
    TLVstring = @"5f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150100df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a0000000041010";
    TLVstring = @"5f5701005f2a0208409f090200025f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a0000000651010";
    TLVstring = @"5f5701005f2a0208409f090202005f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a000000025010501";
    TLVstring = @"5f5701005f2a0208409f090200015f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a0000001523010";
    TLVstring = @"5f5701005f2a0208409f090200015f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    
    name = @"a000000333010102";
    TLVstring = @"5f5701005f2a0208409f090200305f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a122334455";
    TLVstring = @"5f5701005f2a0208409f090212345f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    name = @"a0000000031010010203040506070809";
    TLVstring = @"5f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    TLV = [IDTUtility hexToData:TLVstring];
    rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid %@ Loaded",name]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"Aid %@ Load Error",name] returnValue: rt];
    }
    
    
    
    
}





- (IBAction) f_loadDefaultCAPK:(id)sender{
    NSString* CAPKString = @"a000009999e10101f8707b9bedf031e58a9f843631b90c90d80ed69500000003700099c5b70aa61b4f4c51b6f90b0e3bfb7a3ee0e7db41bc466888b3ec8e9977c762407ef1d79e0afb2823100a020c3e8020593db50e90dbeac18b78d13f96bb2f57eeddc30f256592417cdf739ca6804a10a29d2806e774bfa751f22cf3b65b38f37f91b4daf8aec9b803f7610e06ac9e6b";
    NSData* CAPK = [IDTUtility hexToData:CAPKString];
    RETURN_CODE rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    
    CAPKString = @"a000009999e20101c1056adce9e6f76ea77c89cb832f5a4817907a1a000000037000bd232e348b118eb3f6446ef4da6c3bac9b2ae510c5ad107d38343255d21c4bdf4952a42e92c633b1ce4bfec39afb6dfe147ecbb91d681dac15fb0e198e9a7e4636bdca107bcda3384fcb28b06afef90f099e7084511f3cc010d4343503e1e5a67264b4367daa9a3949499272e9b5022f";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000009999e301011b795cbb0830e2c5231704fa57424d1c4e50f3e4000100017000bc01e12223e1a41e88bffa801093c5f8cec5cd05dbbdbb787ce87249e8808327c2d218991f97a1131e8a25b0122ed11e709c533e8886a1259addfdcbb396604d24e505a2d0b5dd0384fb0002a7a1eb39bc8a11339c7a9433a948337761be73bc497b8e58736da4636538ad282d3cd3db";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000009999e40101ac8da3e12324d719c1d5c9e6e8580157196efeb9000000038000cbf2e40f0836c9a5e390a37be3b809bdf5d740cb1da38cfc05d5f8d6b7745b5e9a3fa6961e55ff20412108525e66b970f902f7ff4305dd832cd0763e3aa8b8173f84777100b1047bd1d744509312a0932ed25fed52a959430768ccd902fd8c8ad9123e6addb3f34b92e7924d729cb6473533ae2b2b55bf0e44964fdea8440117";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000009999e50101ada2349afd118d55af782d37b64651af1ca61ee5000000038000d4fdae94dedbecc6d20d38b01e91826dc6954338379917b2bb8a6b36b5d3b0c5eda60b337448baffebcc3abdba869e8dadec6c870110c42f5aab90a18f4f867f72e3386ffc7e67e7ff94eba079e531b3cf329517e81c5dd9b3dc65db5f9043190be0be897e5fe48adf5d3bfa0585e076e554f26ec69814797f15669f4a255c13";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000009999e601018aa4f4648f0dc62ab6aed92554ad1a831bafc9e4000100018000ebf9faecc3e5c315709694664775d3fbda5a504d89344dd920c55696e891d9ab622598a9d6ab8fbf35e4599cab7eb22f956992f8ab2e6535decb6b576fa0675f97c23dd4c374a66e6af419c9d204d0b9f93c08d789d63805660fbb629df1b488cfa1d7a13e9b729437eeafe718efa859348ba0d76812a99f31cd364f2a4fd42f";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000004fa01017f5acbb96b589f74cb959ed1c35bdb965c3f410600010001f800a4203e0c7beb27097b63c103c19fdcda671aea7f813065756f3b9b81810cbd4bc4dec548fbf1f3cdae51f847235cbf2c8badd8aca7c93bea3d44e80ed6a7b70e29622619db420accce07e1dd4e6c354f359fbdc9c5b70813926f77d827e52b19daf09bfae5274438bb8f61d17753c9ec0a8efa3b7e46f02692160d2653cdbcc71b7d48bd37968316eb444f6504b9421b7dd3035a2c117d8b1f76a8975440da9563618102397b881cef8ada7689edface32482a2dffed656e7f951db841da78368c6293bfc1053a86a845bfa6578e4b69f100b42b558fde1aecec6d250741bc783aa8a68a4261e7bb9246b10587a498d68dd955ce8b2b2433";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000004fb0101fc787db138f994a0c554cc6734eb3e48a55066cc0001000190009b170603a489c7546c45da57b8ffd1db2061240f0e8c6d1f9abdc6b265aa8911915c1a4eabd8d0ed4755d1b902ba06fe5a645b786cd241295517d44ef1a7c25d75afe0eb28066e4d69fee7abafdd5eeb230f14e402c9840825fa77ead12b5f1c5494701de1897f65fe6bf106d47545ebf70ce7c158068c61f0773534db742ab83c28038c1494f15905d0ad17cf1bd38d";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000004fc0101db50b5b0d966300760b1e42125277ba833b6523400010001f800b3296c91f4795bd97112606903407b6eff3ab39246e91095e51d17867da4ade59a48be2fe9b52710283d3d32260e2c7d247214c57d46aa6465e47e0a4b3ffaad8a7f6a190755bccfe3f3fb3989a9f6b1c9e1845bcccad6f20b1dac6033600234e81dac4153212b0f760c23099192aa6c4c9083beffd9a79d2a27b08fecc8e5d437d6c68550a839b1294151daba9d9cb2f160f60f749289f500c8c7f334bd20ebac4ab109cf3c182f1b781c7c097a7903530746c449b99e39e4db6493dd2a02e37c62ae8bc9a7470ecccf8dc06a18c33cd24b30d56f25d2755ce82aa4de4d2eaec07750a03db75ebd0d8ebc9f2a1d85a0d252eff40329be05";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000004fd0101fc505e4a83ff29a3b1bd28dabf52599b2ae9cb14000100019000c9485dbeb5e40415d1b397524f47685f306cfdc499d4e2e7d0cbaf222cfa8184bd111daeedc9cc6ec8540c3f7271ea9990119cc5c43180501d9f45252d6835053fae35696ae8cd67a325647449cf5e594da8f627209f7f03ae8d6dfc0db3e79e28e415df29a5b57d6814856cc30a96da5b8890363e507fcb2e283da1ebb5f18e8e24102b7d0192bb8e35a4f7cd05a435";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000004fe01018535f14cbd6b4ae5028618fab5ac1106549fd03c000100019000e76317965175a08bee510f58830e87b262c70d529803245fa8b88e0c753562de7aeb5a9e3e6c1a98e94d8db7c31407dac5d071e06b80b09e146f22db85f1d72d1ea18d22600032c6dd40e3714d5ada7de9d7d01e88391f893156d6f4bf13e9063559da0786de9bde6b1c9b0bb968edde07145abf877b931682ccb1fb800728724d04af241e2827e0fa1f62591914ff25";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000004ff0101439eb23d8a71b99f879c1a1f1765252d840b9a74000100019000f69dbb5e15983eae3ccf31cf4e47098c2fc16f97a0c710f84777efa99622d86502b138728ab12e3481a84d20e014ad2d634d2836f27f294924b895a87f91f81b8169d4dfdad8d7cbd741804cd61b467c7a9acfeceb71188caa73a907547699d45c9c7d2098ac2966266417f665a46bdd012c097dbd33d1d11aff6ec8a9c0ad814a65b48262ca011636079a328c1aaeb7";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000065020101b973e9f377b419c36ac9696ed95ffb25c8020687000100018000bb7f51983fd8707fd6227c23def5d5377a5a737cef3c5252e578efe136df87b50473f9341f1640c8d258034e14c16993fce6c6b8c3ceeb65fc8fbcd8eb77b3b05ac7c4d09e0fa1ba2efe87d3184db6718ae41a7cad89b8dce0fe80ceb523d5d647f9db58a31d2e71ac677e67fa6e75820736c9893761ee4acd11f31dbdc349ef";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a0000000650301017dc435dbde093d1f0ad0bae0fea4dc12056413dc00000003f800c9e6c1f3c6949a8a42a91f8d0224132b2865e6d953a5b5a54cffb0412439d54aeba79e9b399a6c104684df3fb727c7f55984db7a450e6aa917e110a7f2343a0024d2785d9ebe09f601d592362fdb237700b567ba14bbe2a6d3d23cf1270b3dd822b5496549bf884948f55a0d308348c4b723bafb6a7f3975ac397cad3c5d0fc2d178716f5e8e79e75beb1c84fa202f80e68069a984e008706b30c212305456201540787925e86a8b28b129a11af204b387cb6ee43db53d15a46e13901bebd5cecf4854251d9e9875b16e82ad1c5938a972842c8f1a42ebb5ae5336b04ff3da8b8dfbe606fca8b9084ee05bf67950ba89897cd089f924dbcd";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000003500101b769775668cacb5d22a647d1d993141edab7237b000100018000d11197590057b84196c2f4d11a8f3c05408f422a35d702f90106ea5b019bb28ae607aa9cdebcd0d81a38d48c7ebb0062d287369ec0c42124246ac30d80cd602ab7238d51084ded4698162c59d25eac1e66255b4db2352526ef0982c3b8ad3d1cce85b01db5788e75e09f44be7361366def9d1e1317b05e5d0ff5290f88a0db47";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000003510101b9d248075a3f23b522fe45573e04374dc4995d71000000039000db5fa29d1fda8c1634b04dccff148abee63c772035c79851d3512107586e02a917f7c7e885e7c4a7d529710a145334ce67dc412cb1597b77aa2543b98d19cf2cb80c522bdbea0f1b113fa2c86216c8c610a2d58f29cf3355ceb1bd3ef410d1edd1f7ae0f16897979de28c6ef293e0a19282bd1d793f1331523fc71a228800468c01a3653d14c6b4851a5c029478e757f";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000003530101ac213a2e0d2c0ca35ad0201323536d58097e4e5700000003f800bcd83721be52cccc4b6457321f22a7dc769f54eb8025913be804d9eabbfa19b3d7c5d3ca658d768caf57067eec83c7e6e9f81d0586703ed9dddadd20675d63424980b10eb364e81eb37db40ed100344c928886ff4ccc37203ee6106d5b59d1ac102e2cd2d7ac17f4d96c398e5fd993ecb4ffdf79b17547ff9fa2aa8eefd6cbda124cbb17a0f8528146387135e226b005a474b9062ff264d2ff8efa36814aa2950065b1b04c0a1ae9b2f69d4a4aa979d6ce95fee9485ed0a03aee9bd953e81cfd1ef6e814dfd3c2ce37aefa38c1f9877371e91d6a5eb59fdedf75d3325fa3ca66cdfba0e57146cc789818ff06be5fcc50abd362ae4b80996d";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a0000000039601017616e9ac8be014af88ca11a8fb17967b7394030e000000038000b74586d19a207be6627c5b0aafbc44a2ecf5a2942d3a26ce19c4ffaeee920521868922e893e7838225a3947a2614796fb2c0628ce8c11e3825a56d3b1bbaef783a5c6a81f36f8625395126fa983c5216d3166d48acde8a431212ff763a7f79d9edb7fed76b485de45beb829a3d4730848a366d3324c3027032ff8d16a1e44d8d";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000003570101251a5f5de61cf28b5c6e2b5807c0644a01d46ff5000100016000942b7f2ba5ea307312b63df77c5243618acc2002bd7ecb74d821fe7bdc78bf28f49f74190ad9b23b9713b140ffec1fb429d93f56bdc7ade4ac075d75532c1e590b21874c7952f29b8c0f0c1ce3aeedc8da25343123e71dcf86c6998e15f756e3";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000003580101753ed0aa23e4cd5abd69eae7904b684a34a57c2200010001c80099552c4a1ecd68a0260157fc4151b5992837445d3fc57365ca5692c87be358cdcdf2c92fb6837522842a48eb11cdffe2fd91770c7221e4af6207c2de4004c7dee1b6276dc62d52a87d2cd01fbf2dc4065db52824d2a2167a06d19e6a0f781071cdb2dd314cb94441d8dc0e936317b77bf06f5177f6c5aba3a3bc6aa30209c97260b7a1ad3a192c9b8cd1d153570afcc87c3cd681d13e997fe33b3963a0a1c79772acf991033e1b8397ad0341500e48a24770bc4cbe19d2ccf419504fdbf0389bc2f2fdcd4d44e61f";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a00000000354010106960618791a86d387301edd4a3baf2d34fef1b400010001f800c6ddc0b7645f7f16286ab7e4116655f56dd0c944766040dc68664dd973bd3bfd4c525bcbb95272b6b3ad9ba8860303ad08d9e8cc344a4070f4cfb9eeaf29c8a3460850c264cda39bbe3a7e7d08a69c31b5c8dd9f94ddbc9265758c0e7399adcf4362caee458d414c52b498274881b196dacca7273f687f2a65faeb809d4b2ac1d3d1efb4f6490322318bd296d153b307a3283ab4e5be6ebd910359a8565eb9c4360d24baaca3dbfe393f3d6c830d603c6fc1e83409dfcd80d3a33ba243813bbb4ceaf9cbab6b74b00116f72ab278a88a011d70071e06cab140646438d986d48281624b85b3b2ebb9a6ab3bf2178fcc3011e7caf24897ae7d";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000025600101894b8df19bdc691103c3b93979f5ee28c05888a7000100019000a8ee74edef3c0dca5102ff9b5707975ff67b60d64b5e7322d48de9d3bb6153f63512a091b606dd8fd5f6a14588324ef8827844c7ffc0bab2334ae5207770078b69cdc3f2c666cf69e28e16e1816714c4df313bef539cc01da9dd2d6f47de4f247c500b561c099166ad4fc16df12dfb684ac48d35cdd2c47a13a86a5a162306f64e33b092ab74eda71a4091d96e3daa47";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000025610101cccf27c49c15b2a9410ec6089223a3a01ea8433e00010001f80086c7254665e17ce6934df7d082569f208d1cc1ad8e9fb2fe23e3d7467be50b4f874f906adf2280ec9d204f6d10c037a23ce5fd8283c9ed47d1c669abdd7c1cb356c70bcdc44e5c8ae231555f7b786ac9c3155bcd51f28efbc1b33cc87277049219b2c890952736c4713487111678911d9f42e08074cf524e65d721d727f054e6b5e85ec92b3eb59ffee926dd6c314df555c94ad487a99b67cb7c7ba5e46a5b813ddb918b8e3e0423f4302a58686d1263c0baca9e82068c493289e3e6936eca5f9f77e06b0d6fbda718818b835020098c671c5dd7e9b8e8e841d2df32ee94a7f4748484ca44108ab241a5263ba1ff00d51360dddc749d30a1";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000152d00101de1bb8a37cddbceaab043aaef81634120349726d000100019000d05c2a09d09c9031366ec092bcac67d4b1b4f88b10005e1fc45c1b483ae7eb86ff0e884a19c0595a6c34f06386d776a21d620fc9f9c498adca00e66d129bcdd4789837b96dcc7f09da94ccac5ac7cfc07f4600df78e493dc1957deba3f4838a4b8bd4cefe4e4c6119085e5bb21077341c568a21d65d049d666807c39c401cdfee7f7f99b8f9cb34a8841ea62e83e8d63";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000152d10101ffda858cb2af08b79d750cc97fa6efe2ef228dda00010001f800a71af977c1079304d6dff3f665ab6db3fbdfa1b170287ac6d7bc0afcb7a202a4c815e1fc2e34f75a052564ee2148a39cd6b0f39cfaef95f0294a86c3198e349ff82eece633d50e5860a15082b4b342a90928024057dd51a2401d781b67ae7598d5d1ff26a441970a19a3a58011ca19284279a85567d3119264806caf761122a71fc0492ac8d8d42b036c394fc494e03b43600d7e02cb5267755ace64437cfa7b475ad40ddc93b8c9bcad63801fc492fd251640e41fd13f6e231f56f97283447ab44cbe11910db3c75243784aa9bdf57539c31b51c9f35bf8bc2495762881255478264b792bbdca6498777ae9120ed935bb3e8bea3eab13d9";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000333c001018b094d260bdf8bfc8b9a88b0c177a43fe2fae765000100019000c7cdb6f2a3fe80a8834cdddd326e1082aa2288f47c464d57b34718193431711a44119148055044cfe3313708bed0c98e1c589b0f53cf6d7e829fcd906d21a90fd4cb6baf13110c4685107c27e00981db29dc0ac186e6d701577f23865626244e1f9b2cd1ddfcb9e899b41f5084d8ccc178a7c3f4546cf93187106fab055a7ac67df62e778cb88823ba58cf7546c2b09f";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    CAPKString = @"a000000333c10101b6372db9919f8c6c9c88e83d3c600a4ad8adc7a900010001f80092f083cbe46f8dcc0c04e498ba9952ba9d4c09c80dd277e579f07e45772846fa43dd3ab31cc6b08dd18695715949fb108e53a071d393a7fddbf9c5fb0b0507138797317480fc48d633ed38b401a451443ad7f15facda45a62abe24ff6343add0909ea8389348e54e26f842880d1a69f9214368ba30c18de5c5e0cb9253b5abc55fb6ef0a738d927494a30bbf82e340285363b6faa15673829dbb210e710da58ee9e578e7ce55dc812ab7d6dcce0e3b1ae179d664f3356eb951e3c91a1cbbf6a7ca8d0c7ec9c6af7a4941c5051099b9784e56c9162067b8c3b15c5fa4480a645cd2526a69c80ba8ef361be2aa9417defce35b62b0c9cf097d";
    CAPK = [IDTUtility hexToData:CAPKString];
    rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    
}
- (IBAction) f_removeTermData:(id)sender{
    RETURN_CODE rt = [clearentVP3300 emv_removeTerminalData];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        
        [self appendMessageToResults: @"Remove Terminal Data Successful"];
    }
    else{
        [self displayUpRet2: @"Remove Terminal Data Unsuccessful" returnValue: rt];
    }
}



- (IBAction) f_getSerialNumber:(id)sender
{
    NSString* result;
    RETURN_CODE rt = [clearentVP3300 config_getSerialNumber:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Get Serial Number:  %@", result]];
    }
    else{
        [self displayUpRet2: @"Get Serial Number" returnValue: rt];
    }
}




- (IBAction) f_passthroughON:(id)sender{
    RETURN_CODE rt = [clearentVP3300 device_setPassThrough:true];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"f_passthroughON: OK."];
    }
    else{
        [self displayUpRet2: @"f_passthroughON" returnValue: rt];
    }
}
- (IBAction) f_passthroughOFF:(id)sender{
    RETURN_CODE rt = [clearentVP3300 device_setPassThrough:false];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"f_passthroughOFF: OK."];
    }
    else{
        [self displayUpRet2: @"f_passthroughOFF" returnValue: rt];
    }
}



- (IBAction) f_DisableMSR:(id)sender{
    RETURN_CODE rt = [clearentVP3300 msr_cancelMSRSwipe];
    if(RETURN_CODE_DO_SUCCESS == rt){
        [self appendMessageToResults:@"DisableMSR: OK."];
    }else
    {
        [self displayUpRet2: @"DisableMSR" returnValue:rt];
    }
}



- (IBAction) f_EnableMSR_waitData: (id)sender{
    RETURN_CODE rt = [clearentVP3300 msr_startMSRSwipe];
    if(RETURN_CODE_DO_SUCCESS == rt){
        [self appendMessageToResults:@"EnableMSR: OK."];
    }else
    {
        [self displayUpRet2: @"EnableMSR" returnValue:rt];
    }
}





- (IBAction) f_GetIccReaderStatus: (id)sender
{
    ICCReaderStatus* response;
    RETURN_CODE rt = [clearentVP3300 icc_getICCReaderStatus:&response];
    if(RETURN_CODE_DO_SUCCESS != rt){
        [self displayUpRet2: @"GetICCReaderStatus" returnValue: rt];
        return;
    }
    
    NSString *sta;
    if(response->iccPower)
        sta =@"[ICC Powered]";
    else
        sta = @"[ICC Power not Ready]";
    if(response->cardSeated)
        sta =[NSString stringWithFormat:@"%@,[Card Seated]", sta];
    else
        sta =[NSString stringWithFormat:@"%@,[Card not Seated]", sta];
    
    [self appendMessageToResults:[NSString stringWithFormat:@"%@",sta]];
    
    
    
}

- (IBAction) f_IccPowerON: (id)sender{
    NSData* response;
    RETURN_CODE rt = [clearentVP3300 icc_powerOnICC:&response];
    
    if(RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:[NSString stringWithFormat:@"ICC Powered On, data: %@\n%@", response.description, [[NSString alloc] initWithData:response encoding:NSASCIIStringEncoding] ]];
        
    }else
    {
        [self displayUpRet2: @"ICC Powerd On" returnValue:rt];
    }
    
    return;
}


-(IBAction) autoPollON:(id)sender{
    RETURN_CODE rt = [clearentVP3300 device_setPollMode:0];
    if(RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"autoPollON: OK."];
    }else
    {
        [self displayUpRet2: @"autoPoll ON" returnValue:rt];
    }
}
-(IBAction) autoPollOff:(id)sender{
    RETURN_CODE rt = [clearentVP3300 device_setPollMode:1];
    if(RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"autoPoll Off: OK."];
    }else
    {
        [self displayUpRet2: @"autoPoll Off" returnValue:rt];
    }
}

-(IBAction) autoPollResults:(id)sender{
    IDTEMVData* cardData;
    RETURN_CODE rt = [clearentVP3300 device_getAutoPollTransactionResults:&cardData];
    if(RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"autoPollResults: OK."];
        //Clearent. You no longer have access to this method. Auto Poll won't work as it does in the IdTech demo. [self emvTransactionData:cardData errorCode:0];
    }else
    {
        [self displayUpRet2: @"autoPollResults" returnValue:rt];
    }
}

- (IBAction) f_IccPowerOFF: (id)sender{
    
    NSString* error;
    RETURN_CODE rt = [clearentVP3300 icc_powerOffICC:&error];
    if(RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults:@"ICC PowerOff: OK."];
    }else
    {
        [self displayUpRet2: @"ICC PowerOff" returnValue:rt];
    }
}

-(BOOL) isValidChar:(Byte)byChar{
    if ( ((byChar>(Byte)0x2F) && (byChar<(Byte)0x3A)) //'0' - '9'
        || ((byChar>(Byte)0x40) && (byChar<(Byte)0x47)) //'A' - 'F'
        || ((byChar>(Byte)0x60) && (byChar<(Byte)0x67)) //'a' - 'f'
        )
    {
        return YES;
    }
    return NO;
}


-(NSData*) hexStringToBytes:(NSString*)hexString{
    if (hexString.length<1) {
        return nil;
    }
    
    char tmpCh[1024] = {0};
    int count = 0;
    for (int k=0; k<hexString.length;k++) {
        char c = [hexString characterAtIndex:k];
        if (c == (char)0x20) {
            continue;
        }
        tmpCh[count] = c;
        count++;
    }
    tmpCh[count] = 0;
    
    if (count % 2) {
        return nil;
    }
    
    NSString *temp = [[NSString alloc] initWithUTF8String:tmpCh];
    int m = temp.length % 2;
    if (m>0) {
        return nil;
    }
    
    NSMutableData *result = [[NSMutableData alloc] init];
    unsigned char byte;
    char hexChars[3] = {0};
    for (int i=0; i < (temp.length/2); i++) {
        hexChars[0] = [temp characterAtIndex:i*2];
        hexChars[1] = [temp characterAtIndex:i*2+1];
        
        if (![self isValidChar:hexChars[0]] || ![self isValidChar:hexChars[1]]) {
            return nil;
        }
        byte = strtol(hexChars, NULL, 16);
        [result appendBytes:&byte length:1];
    }
    return [NSData dataWithData:result];
}

- (IBAction) f_DirectIO:(id)sender
{
    [txtDirectIO resignFirstResponder];
    
    unsigned int cmdVal;
    NSScanner* scanner = [NSScanner scannerWithString:cmd.text];
    [scanner scanHexInt:&cmdVal];
    
    unsigned int subcmdVal;
    scanner = [NSScanner scannerWithString:subcmd.text];
    [scanner scanHexInt:&subcmdVal];
    
    NSData* response;
    RETURN_CODE rt = [clearentVP3300 device_sendIDGCommand:cmdVal subCommand:subcmdVal data:[self hexToData:txtDirectIO.text] response:&response];
    if (RETURN_CODE_DO_SUCCESS == rt) {
        [self appendMessageToResults:[NSString stringWithFormat:@"Send Command Result: %@", response.description]];
        [self appendMessageToResults:[NSString stringWithFormat:@"Send Command Result ASCII: %@", [IDTUtility dataToPrintableString:response]]];
    }
    else
    {
        [self displayUpRet2: @"DirectIO" returnValue:rt];
    }
}

- (IBAction) f_IccExchangeAPDU: (id)sender{
    [txtAPDUData resignFirstResponder];
    [friendlyName resignFirstResponder];
    
    NSData *dataBuffer = nil;
    NSString *valueEntered = txtAPDUData.text;
    if (valueEntered.length < 6)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid"
                                                        message:@"input APDU data is invalid."
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        dataBuffer = [self hexStringToBytes:valueEntered];
        if (dataBuffer.length<3) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid"
                                                            message:@"input value is invalid."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    APDUResponse* response;
    RETURN_CODE rt = [clearentVP3300 icc_exchangeAPDU:dataBuffer response:&response];
    [self displayUpRet2: @"ExchangeAPDU" returnValue:rt];
    
    
    [self appendMessageToResults:[NSString stringWithFormat:@"ExchangeAPDU Result: APDU %@", response.response.description ]];
    
    if (RETURN_CODE_DO_SUCCESS == rt)
        [self appendMessageToResults:[NSString stringWithFormat:@"ExchangeAPDU SW1 SW2: %02X, %02X", response.SW1,response.SW2]];
}



- (IBAction) f_testRKI:(id)sender{
    RETURN_CODE rt = [clearentVP3300  device_startRKI];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: @"Start RKI Success"];
        
    }
    else{
        [self displayUpRet2: @"Get Terminal File info" returnValue: rt];
    }
}

- (IBAction) removeAllCAPK:(id)sender{
    RETURN_CODE rt = [clearentVP3300  ctls_removeAllCAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Remove All CAPK Success"]];
        [self appendMessageToResults: [NSString stringWithFormat:@"Remove All CAPK Success"]];
        
    }
    else{
        [self displayUpRet2: @"Remove All CAPK Failure" returnValue: rt];
    }
}

-(IBAction) loadCTLSCAPK:(id)sender{
    RETURN_CODE rt = [clearentVP3300  ctls_setCAPK:[IDTUtility hexToData:@"a000000003500101b769775668cacb5d22a647d1d993141edab7237b000100018000d11197590057b84196c2f4d11a8f3c05408f422a35d702f90106ea5b019bb28ae607aa9cdebcd0d81a38d48c7ebb0062d287369ec0c42124246ac30d80cd602ab7238d51084ded4698162c59d25eac1e66255b4db2352526ef0982c3b8ad3d1cce85b01db5788e75e09f44be7361366def9d1e1317b05e5d0ff5290f88a0db47"]];
    rt = [clearentVP3300  ctls_setCAPK:[IDTUtility hexToData:@"a000000003510101b9d248075a3f23b522fe45573e04374dc4995d71000000039000db5fa29d1fda8c1634b04dccff148abee63c772035c79851d3512107586e02a917f7c7e885e7c4a7d529710a145334ce67dc412cb1597b77aa2543b98d19cf2cb80c522bdbea0f1b113fa2c86216c8c610a2d58f29cf3355ceb1bd3ef410d1edd1f7ae0f16897979de28c6ef293e0a19282bd1d793f1331523fc71a228800468c01a3653d14c6b4851a5c029478e757f"]];
    rt = [clearentVP3300  ctls_setCAPK:[IDTUtility hexToData:@"a000000004ff0101439eb23d8a71b99f879c1a1f1765252d840b9a74000100019000f69dbb5e15983eae3ccf31cf4e47098c2fc16f97a0c710f84777efa99622d86502b138728ab12e3481a84d20e014ad2d634d2836f27f294924b895a87f91f81b8169d4dfdad8d7cbd741804cd61b467c7a9acfeceb71188caa73a907547699d45c9c7d2098ac2966266417f665a46bdd012c097dbd33d1d11aff6ec8a9c0ad814a65b48262ca011636079a328c1aaeb7"]];
    
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Set CTLS Success"]];
        
    }
    else{
        [self displayUpRet2: @"Set CTLS Info " returnValue: rt];
    }
}



- (IBAction) ctlsAIDList:(id)sender{
    NSArray *result;
    RETURN_CODE rt = [clearentVP3300  ctls_retrieveAIDList:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CTLS Aid:\n%@", result.description]];
        
    }
    else{
        [self displayUpRet2: @"CTLS Aid info" returnValue: rt];
    }
}

-(IBAction) capkListing:(id)sender{
    NSArray *result;
    RETURN_CODE rt = [clearentVP3300  ctls_retrieveCAPKList:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CTLS CAPK:\n%@", result.description]];
        
    }
    else{
        [self displayUpRet2: @"CTLS CAPK info" returnValue: rt];
    }
    
}

- (IBAction) ctlsGetAid:(id)sender{
    NSDictionary *result;
    RETURN_CODE rt = [clearentVP3300  ctls_retrieveApplicationData:@"A0000000031010" response:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"AID info:\n%@", result.description]];
        
    }
    else{
        [self displayUpRet2: @"AID Info info" returnValue: rt];
    }
}

- (IBAction) configGroup0:(id)sender{
    NSDictionary *result;
    RETURN_CODE rt = [clearentVP3300  ctls_getConfigurationGroup:0 response:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Confg Group 0 Tiags:\n%@", result.description]];
        [self appendMessageToResults: [NSString stringWithFormat:@"TLV Stream:\n%@", [IDTUtility DICTotTLV:result]]];
        
    }
    else{
        [self displayUpRet2: @"Group 0 info" returnValue: rt];
    }
    
}



-(IBAction) getTerminalFile:(id)sender{
    NSDictionary *result;
    RETURN_CODE rt = [clearentVP3300  emv_retrieveTerminalData:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Terminal Tags Tags:\n%@", result.description]];
        [self appendMessageToResults: [NSString stringWithFormat:@"TLV Stream:\n%@", [IDTUtility DICTotTLV:result]]];
        
    }
    else{
        [self displayUpRet2: @"Get Terminal File info" returnValue: rt];
    }
    
}


-(IBAction)createTerminalFile:(id)sender{
    NSString* TLVstring = @"5F3601029F1A0208409F3501219F33036028C89F4005F000F0A0019F1E085465726D696E616C9F150212349F160F3030303030303030303030303030309F1C0838373635343332319F4E2231303732312057616C6B65722053742E20437970726573732C204341202C5553412EDF260101DF1008656E667265737A68DF110100DF270100DFEE150101DFEE160100DFEE170107DFEE180180DFEE1E08D0DC20D0C41E1400DFEE1F0180DFEE1B083030303135313030DFEE20013CDFEE21010ADFEE2203323C3C";
    NSData* TLV = [IDTUtility hexToData:TLVstring];
    RETURN_CODE rt = [clearentVP3300 emv_setTerminalData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Terminal Settings created"]];
    }
    else{
        [self displayUpRet2: @"Terminal Settings error " returnValue: rt];
    }
    
    
}

-(IBAction) createCRLFile:(id)sender{
    
    NSString* CRLString = @"a000009999g1112233a000009999g2123456";
    NSData* CRL = [IDTUtility hexToData:CRLString];
    RETURN_CODE rt = [clearentVP3300 emv_setCRLEntries:CRL];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CRL Loaded"]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CRL Load Error"] returnValue: rt];
    }
    
    
}
-(IBAction) createCAPKFile:(id)sender{
    
    NSString* CAPKString = @"a000009999e10101f8707b9bedf031e58a9f843631b90c90d80ed69500000003700099c5b70aa61b4f4c51b6f90b0e3bfb7a3ee0e7db41bc466888b3ec8e9977c762407ef1d79e0afb2823100a020c3e8020593db50e90dbeac18b78d13f96bb2f57eeddc30f256592417cdf739ca6804a10a29d2806e774bfa751f22cf3b65b38f37f91b4daf8aec9b803f7610e06ac9e6b";
    NSData* CAPK = [IDTUtility hexToData:CAPKString];
    RETURN_CODE rt = [clearentVP3300 emv_setCAPKFile:CAPK];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK %@ Loaded",[CAPKString substringToIndex:12]]];
    }
    else{
        [self displayUpRet2:[NSString stringWithFormat:@"CAPK %@ Load Error",[CAPKString substringToIndex:12]] returnValue: rt];
    }
    
    
}
-(IBAction) createAIDFile:(id)sender{
    
    NSString* name = @"a0000000031010";
    NSString* TLVstring = @"9f01065649534130305f5701005f2a0208409f090200965f3601029f1b0400003a98df25039f3704df28039f0802dfee150101df13050000000000df14050000000000df15050000000000df180100df170400002710df190100";
    NSData* TLV = [IDTUtility hexToData:TLVstring];
    RETURN_CODE rt = [clearentVP3300 emv_setApplicationData:name configData:[IDTUtility TLVtoDICT:TLV]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"AID for a0000000031010 created"]];
    }
    else{
        [self displayUpRet2: @"AID for a0000000031010 error " returnValue: rt];
    }
    
    
}
-(IBAction) getCAPKFile:(id)sender{
    NSData *result;
    RETURN_CODE rt = [clearentVP3300  emv_retrieveCAPKFile:@"a000009999" index:@"e1" response:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK File:\n%@", result.description]];
        
    }
    else{
        [self displayUpRet2: @"CAPK File info" returnValue: rt];
    }
    
}
-(IBAction) getAIDFile:(id)sender{
    NSDictionary *result;
    RETURN_CODE rt = [clearentVP3300  emv_retrieveApplicationData:@"a0000000031010" response:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"AID Tags:\n%@", result.description]];
        [self appendMessageToResults: [NSString stringWithFormat:@"TLV Stream:\n%@", [IDTUtility DICTotTLV:result]]];
        
    }
    else{
        [self displayUpRet2: @"Installed AIDs info" returnValue: rt];
    }
    
}
-(IBAction) removeCAPKFile:(id)sender{
    RETURN_CODE rt = [clearentVP3300 emv_removeCAPK:@"a000009999" index:@"e1"];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CAPK Removed: %@", @"a000009999e1"]];
    }
    else{
        [self displayUpRet2: @"CAPK Not Removed " returnValue: rt];
    }
    
    
    
}

-(IBAction) removeCRL:(id)sender{
    RETURN_CODE rt = [clearentVP3300 emv_removeCRLList];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CRL Removed"]];
    }
    else{
        [self displayUpRet2: @"CRL Removed " returnValue: rt];
    }
    
    
    
}
-(IBAction) removeAIDFile:(id)sender{
    RETURN_CODE rt = [clearentVP3300 emv_removeApplicationData:@"a0000000031010"];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Aid Removed: %@", @"a0000000031010"]];
    }
    else{
        [self displayUpRet2: @"Aid Not Removed " returnValue: rt];
    }
    
    
    
}
-(IBAction) getAIDFList:(id)sender{
    NSArray *result;
    RETURN_CODE rt = [clearentVP3300  emv_retrieveAIDList:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Installed AIDs:\n%@", result.description]];
    }
    else{
        [self displayUpRet2: @"Installed AIDs info" returnValue: rt];
    }
}

-(IBAction) getCAPKList:(id)sender{
    NSArray *result;
    RETURN_CODE rt = [clearentVP3300  emv_retrieveCAPKList:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"Installed CAPKs:\n%@", result.description]];
    }
    else{
        [self displayUpRet2: @"Installed CAPKs info" returnValue: rt];
    }
}

-(IBAction) getCRLList:(id)sender{
    NSMutableArray *result;
    RETURN_CODE rt = [clearentVP3300  emv_retrieveCRLList:&result];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: [NSString stringWithFormat:@"CRL:\n%@", result.description]];
    }
    else{
        [self displayUpRet2: @"CRL info" returnValue: rt];
    }
}

-(IBAction) authEMV:(id)sender{
    RETURN_CODE rt = [clearentVP3300 emv_authenticateTransaction:nil];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: @"Authenticate Trasaction Command Accepted"];
    }
    else{
        [self displayUpRet2: @"Start Transaction info" returnValue: rt];
    }
}

- (IBAction) f_startAnyTransaction:(id)sender{
    if (stressTest.on){
        [autoAuth setOn:TRUE];
        [autoComplete setOn:TRUE];
    }
    [[IDT_VP3300 sharedController] emv_disableAutoAuthenticateTransaction:!autoAuth.on];
    double amount = [txtAmount.text doubleValue];
    RETURN_CODE rt = [clearentVP3300 device_startTransaction:amount amtOther:0 type:0 timeout:60 tags:nil forceOnline:false fallback:true];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: @"Start Transaction Command Accepted"];
    }
    else{
        [self displayUpRet2: @"Start Transaction info" returnValue: rt];
    }
}

-(IBAction)startEMV:(id)sender{
    
    if (stressTest.on){
        [autoAuth setOn:TRUE];
        [autoComplete setOn:TRUE];
    }
    [clearentVP3300 emv_disableAutoAuthenticateTransaction:!autoAuth.on];
    resultsTextView.text = @"";
    NSMutableDictionary *tags = [NSMutableDictionary new];
    double amount = [txtAmount.text doubleValue];
    RETURN_CODE rt = [clearentVP3300 emv_startTransaction:amount amtOther:0 type:0 timeout:60 tags:nil forceOnline:false fallback:true];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: @"Start Transaction Command Accepted"];
    }
    else{
        [self displayUpRet2: @"Start Transaction info" returnValue: rt];
    }
}

-(IBAction)completeEMV:(id)sender{
    
    resultsTextView.text = @"";
    RETURN_CODE rt = [clearentVP3300  emv_completeOnlineEMVTransaction:true hostResponseTags:[IDTUtility hexToData:@"8A023030"]];
    if (RETURN_CODE_DO_SUCCESS == rt)
    {
        [self appendMessageToResults: @"Complete Transaction Command Accepted"];
    }
    else{
        [self displayUpRet2: @"Complete Transaction info" returnValue: rt];
    }
}

-(unsigned int) char2hex:(char)c{
    
    switch (c) {
        case '0' ... '9': return c - '0';
        case 'a' ... 'f': return c - 'a' + 10;
        case 'A' ... 'F': return c - 'A' + 10;
        default: return -1;
    }
}

- (NSData *)hexToData:(NSString*)str {   //Example - Pass string that contains characters "30313233", and it will return a data object containing ascii characters "0123"
    if ([str length] == 0) {
        return nil;
    }
    
    unsigned stringIndex=0, resultIndex=0, max=(int)[str length];
    NSMutableData* result = [NSMutableData dataWithLength:(max + 1)/2];
    unsigned char* bytes = [result mutableBytes];
    
    unsigned num_nibbles = 0;
    unsigned char byte_value = 0;
    
    for (stringIndex = 0; stringIndex < max; stringIndex++) {
        unsigned int val = [self char2hex:[str characterAtIndex:stringIndex]];
        
        num_nibbles++;
        byte_value = byte_value * 16 + (unsigned char)val;
        if (! (num_nibbles % 2)) {
            bytes[resultIndex++] = byte_value;
            byte_value = 0;
        }
    }
    
    
    //final nibble
    if (num_nibbles % 2) {
        bytes[resultIndex++] = byte_value;
    }
    
    [result setLength:resultIndex];
    
    return result;
}

@end

