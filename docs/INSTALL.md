# Getting the IPA without Xcode on your computer

1. Open the repository Actions page: https://github.com/1EDDD/Tik/actions
2. Open the latest Build unsigned iOS IPA workflow run.
3. When it succeeds, download the GlassVideo-unsigned-ipa artifact ZIP and extract the IPA file.
4. Import the IPA into a compatible sideloading app that signs apps with your Apple ID, then follow that app's trust/signing steps.

The CI artifact is unsigned because the repository has no Apple signing certificate or provisioning profile. It is not directly installable until signed. Do not add Apple private keys or passwords to source files. TestFlight/App Store distribution requires a secure signing configuration and the appropriate Apple Developer account.
