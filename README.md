# Demo app showing the Clearent Framework working with the IDTech VP3300 device

Clearent Framework is here : https://github.com/clearent/ClearentIdtechIOSFramework

This demo is a version of the UniPayIIITestApp demo that's included in the 80149808-001-A.zip download from here: https://atlassian.idtechproducts.com/confluence/display/KB/VP3300+-+Home.

This demo closely resembles the demo app provided by IDTech in the download above. The difference between the two is the Clearent demo will show how to use the Clearent singleton and a Clearent delegate.

The design is similar to the IDTech design so you can reference IDTech's documentation. The big difference is the methods exposed by the IDTech framework's delegate that would return credit card data to you to process is now handled by the Clearent framework.

Implement the successfulTransactionToken method and every time a successful card read occurs a response containing safe data about the card will be returned. Returned as json, the data returned is :

  cvm - the card holder verification methods

  last-four - last four of the credit card number

  track-data-hash - a hash representing the track data. This can be used as a unique id of the transaction.

  jwt - This is the jwt you will present when it is time to perform a payment transaction for the card that was read.


Implement the errorTransactionToken method to monitor errors with the process of converting the credit card data to its safe (jwt) representation.

In ViewController.m there is an example of running a payment transaction. The method is exampleTransactionToClearentPayments.

Carthage was used to build the project. See Clearent Framework README for more details.
