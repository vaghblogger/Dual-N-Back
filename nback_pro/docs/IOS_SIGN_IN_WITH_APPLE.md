# Sign in with Apple on iOS

## Why you saw the provisioning profile error

**Personal (free) Apple Developer accounts** cannot use the Sign in with Apple capability. Only **paid Apple Developer Program** members ($99/year) can create provisioning profiles that include it.

So the project is set up to **build without** the Sign in with Apple entitlement. That lets you develop and run on device with a free Apple ID. The “Sign in with Apple” button still appears on the login screen on iOS, but it will not work until you enable the capability (see below).

---

## Option A: Keep developing with a free account (current setup)

- You can build and run the app on your iPhone/simulator with your **Personal Team**.
- **Google Sign-In** and **Continue as Guest** work.
- **Sign in with Apple** will fail if tapped (capability not in the profile). You can hide or ignore that button until you enroll.

No further change needed.

---

## Option B: Enable Sign in with Apple (paid Apple Developer Program)

When you’re ready to ship and want Sign in with Apple:

1. **Enroll** in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).

2. **In Apple Developer portal**
   - Go to **Certificates, Identifiers & Profiles** → **Identifiers**.
   - Select your App ID (e.g. `com.vaghblogger.nbackPro`).
   - Enable **Sign in with Apple** and save.

3. **In Xcode**
   - Open `ios/Runner.xcworkspace`.
   - Select the **Runner** project → **Runner** target.
   - Open **Build Settings**, search for **Code Signing Entitlements**.
   - Set **Code Signing Entitlements** to: `Runner/Runner.entitlements`  
     (for Debug, Release, and Profile if you use it).

   Or in `ios/Runner.xcodeproj/project.pbxproj`, in each Runner target build configuration (Debug, Release, Profile), add inside `buildSettings`:
   ```text
   CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;
   ```

4. **Provisioning**
   - In Xcode, **Signing & Capabilities** for Runner: choose your **paid** team.
   - Let Xcode create a new Development (and later Distribution) provisioning profile, or create one in the Developer portal that includes Sign in with Apple.

5. **Clean and run**
   ```bash
   cd ios && pod install && cd ..
   flutter run
   ```

The file `ios/Runner/Runner.entitlements` is already in the repo with the correct `com.apple.developer.applesignin` entitlement; it’s only excluded from the build so that free accounts can build the app.
