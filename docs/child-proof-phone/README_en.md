![English](../_static/ico/uk.ico)[English](README_en.md) | ![German](../_static/ico/germany.ico)[Deutsch](README.md) 

# Setting up a child-proof phone

The aim of this chapter is to set up a mobile phone that can be used safely by children.
The focus is on ensuring the following features:

- Limiting the screen time for certain apps and categories of apps
- Making it harder to install or uninstall selected apps (depending on the Android version and device)
- Protecting the screen-time app; a third-party app cannot reliably prevent bypass or uninstallation
- Protection against inappropriate content
- Localization of the phone in case of loss or to determine the location of the child


## Recommended apps

- ![app_image](../_static/ico/timelimit.ico) **[TimeLimit](https://timelimit.io/)** on [f-droid](https://f-droid.org/packages/io.timelimit.android.aosp.direct/): Flexibly limit the period of use 
- ![app_image](../_static/ico/adaway.ico) **[AdAway](https://adaway.org/)** on [f-droid](https://f-droid.org/de/packages/org.adaway/): A free and open-source ad blocker for Android
- ![app_image](../_static/ico/applock.ico) **[App Lock](https://play.google.com/store/apps/details?id=applock.lockapps.fingerprint.password.lockit)**: Third-party app for locking selected apps. This is not a reliable parental-control boundary and may be bypassed depending on the device.
- ![app_image](../_static/ico/findmydevice.ico) **[Find My Device](https://f-droid.org/packages/de.nulide.findmydevice/)**: Locate a device and issue selected remote commands by SMS


---

## Set up device

### Set up screen time limit app

1. Install TimeLimit [as mentioned above](#recommended-apps)
1. Grant the necessary authorizations
1. Add at least the following apps as explicitly allowed apps so that these apps can work unhindered:
   1. AdAway content blocker
   1. App Lock
1. Block these apps completely (time limit 0)
   1. Settings (This increases security against unauthorized uninstallation)
1. Set time limits as required

<details>
<summary>ℹ️ Tips and Details about screen time limit app</summary>

To set up the screen time limit, individual apps can be grouped into categories using the app mentioned above.
An individual time limit can be set for each of these categories.

One problem is that the display time limit is more of a self-control mechanism. 
Although a pin can be set up, it is very easy to bypass, for example by uninstalling or deactivating the app. 
It is therefore necessary to combine the time limit app with an app for generally blocking other apps, see below.
</details>


---

### Set up content blocker

1. Install AdAway [as mentioned above](#recommended-apps)
1. Add some individual block lists as required:
   * StevenBlack Unified hosts: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
   * StevenBlack fakenews-gambling-porn: https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-only/hosts
   * Online games: https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/child-proof-phone/online-games-hosts-blocklist/hosts


<details>
<summary>ℹ️ Tips and Details about content blocker</summary>

* For more details, refer to a detailed explanation in this [blog post](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/) (german).
* Most devices will not have root permissions, which means that you have to rely on the VPN-based ad blocker.
* Don't forget to update the sources regularly and check the desired function of the ad blocker.
</details>


<details>
<summary>Using unified blocked hosts</summary>

In addition to the default blocked hosts, further lists can be [found here](https://github.com/StevenBlack/hosts#list-of-all-hosts-file-variants).
The **Unified hosts** list may already be enabled. Additional categories such as [gambling and adult content](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts) can be added. Check each list for maintenance status and side effects.
</details>


<details>
<summary>Build individual block lists</summary>

In some cases it will be necessary to block additional pages individually, like **online games**. 
Further information on this can be found in the [AdAway Wiki](https://github.com/AdAway/AdAway/wiki/HostsSources).

An additional [host list to block online games](https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/child-proof-phone/online-games-hosts-blocklist/hosts) is available in this repository.
This is based on the AdBlock-compatible list from [IREK-szef](https://raw.githubusercontent.com/IREK-szef/games-blocklist/main/lists/Adblock-dns/games.txt), which is adapted to the AdAway format and has been slightly expanded.
</details>


---

### Set up App locker

1. Install the desired app [as mentioned above](#recommended-apps)
1. Grant the necessary authorizations
1. Block at least the following apps:

   * AdAway Content Blocker (to prevent deletions of host block lists)
   * Screen-time limit app (this may make unwanted changes more difficult, but is not a reliable security boundary)
   * Settings (this may make uninstallation more difficult, but does not prevent it reliably)

1. Adjust App Settings

   * 🔴 **[off]** Use fingerprint (would allow unlocking with children fingerprint)
   * 🟢 **[on]** Lock new app
   * 🟢 **[on]** Set a password or PIN that differs from the child's device PIN
   * 🔴 **[off]** Battery optimization for the app (to allow it to keep running in the background; the setting name varies by Android version)
   * 🟢 **[on]** Symbol camouflage
   * 🟢 **[on]** Uninstall protection


<details>
<summary>ℹ️ Tips and Details about App Locker</summary>

* An app lock may make changes harder, but cannot reliably prevent an app from being disabled or uninstalled. Device PIN, Android version, and permissions affect bypass options.
* Locking Settings is not a reliable parental-control boundary. Check that the app remains active in the background and that its protections work on the specific device.
* It can also be used to protect harmless apps that require a special configuration (e.g. nextcloud) that should not be changed by the child.
</details>


---

### Set up Find My Device
Install Find My Device on the device to be located. First authorize on that device every device allowed to send remote commands by SMS.
All settings must therefore be made on the device to be located, e.g. the child's phone. 

Location and remote commands can expose sensitive location and device data or erase data. Use them transparently, with consent, and in accordance with applicable rules. Check the current app documentation before using commands; `fmd delete` resets the device and erases local data.

Send the relevant command by SMS from a previously authorized device:

```
fmd locate - sends the current GPS location
fmd ring - triggers the phone to ring
fmd lock - locks the phone
fmd stats - sends device details
fmd delete - resets the phone to factory settings
fmd camera (back/front) - captures a photo with the selected camera and sends it to the configured server
```

## Further links
- AdAway: [Comprehensive description of the functionality (german)](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/)
- FindMyDevice: [github Wiki](https://github.com/ColoursofOSINT/findmydevice/tree/main)