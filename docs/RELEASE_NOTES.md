![Screenshot](clearent_logo.jpg)

# Release Notes

1.0.26.1 - Uses the 1.0.26.1 release of the ClearentIdtechIOSFramework. You will notice audio jack logic commented out in areas. The demo was modified to show a feature recently added by IDTech to disable audio detection when you are exclusively using Bluetooth readers. By calling the following static methods before instantiating the Clearent_VP3300 object you can avoid an unpleasant microphone permission prompt, which might confuse your user.

``` smalltalk
[IDT_VP3300 disableAudioDetection];

[IDT_Device disableAudioDetection];
```

1.0.26.2 - Uses the 1.0.26.2 release of the ClearentIdtechIOSFramework. Contains a fix for an issue related to the iOS13. Bluetooth fix only

1.0.26.3 - another ios13 fix was discovered on the audio jack side.

1.0.26.4 - Fixed an issue where the framework was not handling the card data correctly when the user has been presented with the 'USE MAGSTRIPE' message after an invalid insert. The result was an NSInvalidArgumentException being thrown.

1.1.0-beta - uses the beta release of the framework that supports contactless
