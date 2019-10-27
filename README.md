![Screenshot](docs/clearent_logo.jpg)

# Demo app showing the Clearent Framework working with the IDTech VP3300 reader

Clearent Framework is here : https://github.com/clearent/ClearentIdtechIOSFramework

This demo is a version of the VP3300TestApp demo that's included in the 80149808-001-A.zip download from here: https://atlassian.idtechproducts.com/confluence/display/KB/VP3300+-+Home.

This demo closely resembles the demo app provided by IDTech in the download above. The difference between the two is the Clearent demo will show how to use the Clearent singleton and a Clearent delegate.

The design is similar to the IDTech design so you can reference IDTech's documentation. The big difference is the methods exposed by the IDTech framework's delegate that would return credit card data to you is now handled by the Clearent framework. The Clearent solution implements the emvTransactionData and swipeMSRData IDTech methods on your behalf. Instead of working directly with the card data, the card data is sent to Clearent. Clearent will issue a 'Transaction Token' (aka, JWT) for each card read. The token can then be presented to a Clearent endpoint (/rest/v2/mobile/transactions/sale) to run a sale.

Implement the successfulTransactionToken method and every time a successful card read occurs a response containing safe data about the card will be returned. This response is in json and has the following data :

  cvm - the card holder verification method

  last-four - last four of the credit card number

  track-data-hash - a hash representing the track data. This can be used as a unique id of the transaction.

  jwt - This is the jwt you will present when it is time to perform a payment transaction for the card that was read.

Monitor for card reader issues using the deviceMessage method.

In ViewController.m there is an example of running a payment transaction. The method is exampleUseJwtToRunPaymentTransaction.

Carthage was used to build the project. See Clearent Framework README for more details.


== Release Notes ==

1.0.26.1 - Uses the 1.0.26.1 release of the ClearentIdtechIOSFramework. You will notice audio jack logic commented out in areas. The demo was modified to show a feature recently added by IDTech to disable audio detection when you are exclusively using Bluetooth readers. By calling the following static methods before instantiating the Clearent_VP3300 object you can avoid an unpleasant microphone permission prompt, which might confuse your user.

[IDT_VP3300 disableAudioDetection];

[IDT_Device disableAudioDetection];

1.0.26.2 - Uses the 1.0.26.2 release of the ClearentIdtechIOSFramework. Contains a fix for an issue related to the iOS13. Bluetooth fix only

1.0.26.3 - another ios13 fix was discovered on the audio jack side.

1.0.26.4 - Fixed an issue where the framework was not handling the card data correctly when the user has been presented with the 'USE MAGSTRIPE' message after an invalid insert. The result was an NSInvalidArgumentException being thrown.
