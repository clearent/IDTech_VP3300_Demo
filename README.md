# Demo app showing the Clearent Framework working with the IDTech VP3300 device

Clearent Framework is here : https://github.com/clearent/ClearentIdtechIOSFramework

This demo is a version of the VP3300TestApp demo that's included in the 80149808-001-A.zip download from here: https://atlassian.idtechproducts.com/confluence/display/KB/VP3300+-+Home.

This demo closely resembles the demo app provided by IDTech in the download above. The difference between the two is the Clearent demo will show how to use the Clearent singleton and a Clearent delegate. 

The design is similar to the IDTech design so you can reference IDTech's documentation. The big difference is the methods exposed by the IDTech framework's delegate that would return credit card data to you is now handled by the Clearent framework. The Clearent solution implements the emvTransactionData and swipeMSRData IDTech methods on your behalf. Instead of working directly with the card data, the card data is sent to Clearent. Clearent will issue a 'Transaction Token' (aka, JWT) for each card read. The token can then be presented to a Clearent endpoint (/rest/v2/mobile/transactions) to run a sale.

Implement the successfulTransactionToken method and every time a successful card read occurs a response containing safe data about the card will be returned. This response is in json and has the following data :

  cvm - the card holder verification method

  last-four - last four of the credit card number

  track-data-hash - a hash representing the track data. This can be used as a unique id of the transaction.

  jwt - This is the jwt you will present when it is time to perform a payment transaction for the card that was read.

Implement the errorTransactionToken method to monitor errors with the process of converting the credit card data to its safe (jwt) representation.

In ViewController.m there is an example of running a payment transaction. The method is exampleUseJwtToRunPaymentTransaction.

Carthage was used to build the project. See Clearent Framework README for more details.
