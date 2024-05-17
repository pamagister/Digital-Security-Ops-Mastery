[:uk: English](README.md) | [:de: Deutsch](README_de.md) 

# Setting up a child-proof phone
The aim of this chapter is to set up a mobile phone that can be used safely by children.
The focus is on ensuring the following features:
- Limiting the screen time for certain apps and categories of apps
- Preventing the installation and uninstallation of certain apps
- Preventing the uninstallation of the app required to limit screen time
- Protection against inappropriate content
- Localization of the phone in case of loss or to determine the location of the child


<a name="recommended" />

## Recommended apps

- ![app_image](../res/ico/timelimit.ico) **[TimeLimit](https://timelimit.io/)** on [f-droid](https://f-droid.org/packages/io.timelimit.android.aosp.direct/): Flexibly limit the period of use 
- ![app_image](../res/ico/adaway.ico) **[AdAway](https://adaway.org/)** on [f-droid](https://f-droid.org/de/packages/org.adaway/): A free and open-source ad blocker for Android
- ![app_image](../res/ico/applock.ico) **[App Lock](https://play.google.com/store/apps/details?id=applock.lockapps.fingerprint.password.lockit)**: AppLock easily secures apps and protects your private data with one click. Protect your phone with a PIN, pattern or fingerprint
- ![app_image](../res/ico/findmydevice.ico) **[Find My Device](https://f-droid.org/de/packages/de.nulide.findmydevice/)** on [f-droid]((https://f-droid.org/de/packages/de.nulide.findmydevice/)): Locate and control your device remotely


## Set up device

### Set up screen time limit app
⚡ Quick start ⚡
1. Install the required TimeLimit App [as mentioned above](#recommended)
1. Grant the necessary authorizations
1. Add at least the following apps as explicitly allowed apps so that these apps can work unhindered:
   * AdAway content blocker
   * App Lock
1. Block these apps completely (time limit 0)
   * Settings (This increases security against unauthorized uninstallation)
1. Set time limits as required

<details>
<summary>ℹ️ Tips and Details about screen time limit app</summary>

To set up the screen time limit, individual apps can be grouped into categories using the app mentioned above.
An individual time limit can be set for each of these categories.

One problem is that the display time limit is more of a self-control mechanism. 
Although a pin can be set up, it is very easy to bypass, for example by uninstalling or deactivating the app. 
It is therefore necessary to combine the time limit app with an app for generally blocking other apps, see below.
</details>

### Set up content blocker
⚡ Quick start ⚡
1. Install the required ad-blocker App [as mentioned above](#recommended)
1. Add some individual block lists as required:
   * StevenBlack Unified hosts: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
   * StevenBlack fakenews-gambling-porn: https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn-only/hosts
   * Online Gaming: https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/child-proof-phone/online-games-hosts-blocklist/hosts


<details>
<summary>ℹ️ Tips and Details about content blocker</summary>

* For more details, refer to a detailed explanation in this [blog post](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/) (german).
* Most devices will not have root permissions, which means that you have to rely on the VPN-based ad blocker.
* Don't forget to update the sources regularly and check the desired function of the ad blocker.
</details>


<details>
<summary>Using unified blocked hosts</summary>

In addition to the already preset blocked hosts, further special hosts can be [found here](https://github.com/StevenBlack/hosts#list-of-all-hosts-file-variants).
The list of **Unified hosts** is often already pre-set so that specific categories like [gambling and porn](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts) or further hosts from [Stephen Black Hosts](https://github.com/StevenBlack/hosts) can be added for children. 
</details>


<details>
<summary>Build individual block lists</summary>

In some cases it will be necessary to block additional pages individually, like **online games**. 
Further information on this can be found in the [AdAway Wiki](https://github.com/AdAway/AdAway/wiki/HostsSources).

An additional [host list to block online games](https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/child-proof-phone/online-games-hosts-blocklist/hosts) has been created here in this repository using AdAway. 
This is based on the AdBlock-compatible list from [IREK-szef](https://raw.githubusercontent.com/IREK-szef/games-blocklist/main/lists/Adblock-dns/games.txt), which is adapted to the AdAway format and has been slightly expanded.
</details>


### Set up App locker
⚡ Quick start ⚡
1. Install the required App [as mentioned above](#recommended)
1. Grant the necessary authorizations
1. Block at least the following apps:
   * AdAway Content Blocker (to prevent deletions of host block lists)
   * Screen time limit app (Even if the time limiter app has its own security, this increases security against unwanted manipulation)
   * Settings (this prevents uninstallation)
1. Adjust App Settings
   * 🔴 **[off]** Use fingerprint (would allow unlocking with children fingerprint)
   * 🟢 **[on]** Lock new app
   * 🟢 **[on]** Set a passwort or pin that differs from children pin
   * 🔴 **[off]** Battery optimization (this might cause the app to run inactively in the background)
   * 🟢 **[on]** Symbol camouflage
   * 🟢 **[on]** Uninstall protection


<details>
<summary>ℹ️ Tips and Details about App Locker</summary>

* To prevent the above-mentioned app from being deactivated or even uninstalled, App Lock can be used to set up an access lock for certain apps.
* The settings menu can also be secured via this app to prevent the lock app from being uninstalled. A recovery email must be set up for this.
* It can also be used to protect harmless apps that require a special configuration (e.g. nextcloud) that should not be changed by the child.
</details>


### Set up Find my Device
The Find my Device app must be installed on the cell phone that is to be located, e.g. in the event of loss.
In addition, all devices that are to have permission to locate the device via SMS must first be authorized on the device to be located.
All settings must therefore be made on the device to be located, e.g. the child's phone. 

The app provides intuitive menu navigation for setup.

## Further links
- AdAway: [Comprehensive description of the functionality (german)](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/)