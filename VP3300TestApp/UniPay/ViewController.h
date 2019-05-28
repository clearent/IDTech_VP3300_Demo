//
//  ViewController.h
//  VP3300
//
//  Created by zhong howard on 13-3-18.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <IDTech/IDTech.h>
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
//CLEARENT: import the ClearentIdtechIOSFramework header
#import <ClearentIdtechIOSFramework/ClearentIdtechIOSFramework.h>

//CLEARENT make the view a Clearent_Public_IDTech_VP3300_Delegate

//CLEARENT make the view a ClearentManualEntryDelegate

@interface ViewController : UIViewController<UIAlertViewDelegate,Clearent_Public_IDTech_VP3300_Delegate, UIActionSheetDelegate,MFMailComposeViewControllerDelegate,ClearentManualEntryDelegate>
{
    
    IBOutlet UITextView *resultsTextView;
    IBOutlet UITextView *dataTextView;
    IBOutlet UILabel *connectedLabel;
    IBOutlet UITextField *txtAPDUData;
    IBOutlet UITextField *txtDirectIO;
    IBOutlet UITextField *cmd;
    IBOutlet UITextField *subcmd;
    IBOutlet UISwitch *autoAuth;
    IBOutlet UISwitch *autoConfigure;
    IBOutlet UISwitch *stressTest;
    IBOutlet UITextField *friendlyName;
    IBOutlet UITextField *txtAmount;
    IBOutlet UITextField *txtReceiptEmailAddress;
    
    
}

//only for iPhone
@property (strong, nonatomic) IBOutlet UIScrollView *sView;
@property (strong, nonatomic) IBOutlet UIView *view1;
@property (strong, nonatomic) IBOutlet UIView *view2;
@property (strong, nonatomic) IBOutlet UIView *view4;
@property (strong, nonatomic) IBOutlet UIView *view5;
@property (strong, nonatomic) IBOutlet UIView *view6;
@property (strong, nonatomic) IBOutlet UIView *view7;
@property (strong, nonatomic) IBOutlet UIPageControl *pcControlPanes;

//for all
@property(nonatomic, strong) UITextView *resultsTextView;
@property(nonatomic, strong) UITextView *dataTextView;
@property(nonatomic, strong) UILabel *connectedLabel;
@property(nonatomic, strong) UITextField *txtAPDUData;
@property(nonatomic, strong) UITextField *txtDirectIO;
@property(nonatomic, strong) UITextField *cmd;
@property(nonatomic, strong) UITextField *subcmd;
@property(nonatomic, strong) UIAlertView *prompt_doConnection;
@property(nonatomic, strong) UIAlertView *prompt_doConnection_Low_Volume;
@property(nonatomic, strong) UITextField *friendlyName;
@property(nonatomic, strong) UITextField *txtAmount;
@property(nonatomic, strong) UITextField *txtReceiptEmailAddress;

- (IBAction) f_cancelTrans:(id)sender;
- (IBAction) f_allowPIN:(id)sender;
- (IBAction) f_noPin:(id)sender;


- (IBAction) DoKeyboardOff:(id)sender;
- (IBAction) f_startAnyTransaction:(id)sender;

- (IBAction) f_getFirm:(id)sender;
- (IBAction) f_getL2:(id)sender;
- (IBAction) f_getSerialNumber:(id)sender;

- (IBAction) f_loadDefaultAID:(id)sender;
- (IBAction) f_loadDefaultCAPK:(id)sender;
- (IBAction) f_removeTermData:(id)sender;

- (IBAction) configGroup0:(id)sender;
- (IBAction) removeAllCAPK:(id)sender;
- (IBAction) ctlsAIDList:(id)sender;
- (IBAction) ctlsGetAid:(id)sender;

- (IBAction) f_testRKI:(id)sender;

- (IBAction) f_DisableMSR:(id)sender;
- (IBAction) f_passthroughON:(id)sender;
- (IBAction) f_passthroughOFF:(id)sender;
- (IBAction) f_EnableMSR_waitData: (id)sender;
- (IBAction) f_IccPowerON: (id)sender;
- (IBAction) f_IccPowerOFF: (id)sender;
- (IBAction) f_IccExchangeAPDU: (id)sender;

-(IBAction) startEMV:(id)sender;
-(IBAction) completeEMV:(id)sender;
-(IBAction) authEMV:(id)sender;
-(IBAction) capkListing:(id)sender;
-(IBAction) loadCTLSCAPK:(id)sender;

-(IBAction) createTerminalFile:(id)sender;
-(IBAction) getTerminalFile:(id)sender;
-(IBAction) createAIDFile:(id)sender;
-(IBAction) createCAPKFile:(id)sender;
-(IBAction) createCRLFile:(id)sender;
-(IBAction) getAIDFile:(id)sender;
-(IBAction) getCAPKFile:(id)sender;
-(IBAction) removeAIDFile:(id)sender;
-(IBAction) removeCAPKFile:(id)sender;
-(IBAction) removeCRL:(id)sender;
-(IBAction) getAIDFList:(id)sender;
-(IBAction) getCAPKList:(id)sender;
-(IBAction) getCRLList:(id)sender;

-(IBAction) autoPollON:(id)sender;
-(IBAction) autoPollOff:(id)sender;
-(IBAction) autoPollResults:(id)sender;


- (IBAction) f_DirectIO:(id)sender;


@end
