# Setting up a child-proof phone
The aim of this chapter is to set up a mobile phone that can be used safely by children.
The focus is on ensuring the following features:
- Limiting the screen time for certain apps and categories of apps
- Preventing the installation and uninstallation of certain apps
- Preventing the uninstallation of the app required to limit screen time
- Protection against inappropriate content
- Localization of the phone in case of loss or to determine the location of the child

## Recommended apps

- ![app_image](../res/ico/stayfree.ico) **[StayFree](https://stayfreeapps.com/)**: Screen time tracker & app usage limit is an app for self-control, more productivity and to combat cell phone addiction
- ![app_image](../res/ico/applock.ico) **[App Lock](https://play.google.com/store/apps/details?id=applock.lockapps.fingerprint.password.lockit)**: AppLock easily secures apps and protects your private data with one click. Protect your phone with a PIN, pattern or fingerprint
- ![app_image](../res/ico/adaway.ico) **[AdAway](https://f-droid.org/de/packages/org.adaway/)**: A free and open-source ad blocker for Android
- ![app_image](../res/ico/findmydevice.ico) **[Find My Device (FMD)](https://f-droid.org/de/packages/de.nulide.findmydevice/)**: Locate and control your device remotely

## Set up device

### Set up scree time limit
To set up the screen time limit, individual apps can be grouped into categories using the app mentioned above.
An individual time limit can be set for each of these categories.

One problem is that the display time limit is more of a self-control mechanism. Although a pin can be set up, it is very easy to bypass.

### Set up App locker
To prevent the above-mentioned app from being deactivated or even uninstalled, App Lock can be used to set up an access lock for certain apps.

The settings menu can also be secured via this app to prevent the lock app from being uninstalled. A recovery email must be set up for this.

It can also be used to protect harmless apps that require a special configuration (e.g. nextcloud) that should not be changed by the child.

### Set up content blocker
First, get the required ad-blocker App [AdAway](https://f-droid.org/de/packages/org.adaway/). 
For more details, refer to a detailled explanation in this [blog post](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/) (german).

Most devices will not have root permissions, which means that you have to rely on the VPN-based ad blocker.

In addition to the already preset blocked hosts, further special hosts can be [found here](https://github.com/StevenBlack/hosts#list-of-all-hosts-file-variants).
The list of **Unified hosts** is often already pre-set so that specific categories like [gambling and porn](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn-only/hosts) or further hosts from [Stephen Black Hosts](https://github.com/StevenBlack/hosts) can be added for children. 

#### Build individual block lists
In some cases it will be necessary to block additional pages individually. 
Further information on this can be found in the [AdAway Wiki](https://github.com/AdAway/AdAway/wiki/HostsSources).

An additional host list has been created here in this repository to block online games. 
This is based on the AdBlock-compatible list from [IREK-szef](https://raw.githubusercontent.com/IREK-szef/games-blocklist/main/lists/Adblock-dns/games.txt), which is adapted to the AdAway format and has been slightly expanded.




Don't forget to update the sources and check the desired function of the ad blocker.

### Set up Find my Device
The Find my Device app must be installed on the cell phone that is to be located, e.g. in the event of loss.
In addition, all devices that are to have permission to locate the device via SMS must first be authorized on the device to be located.
All settings must therefore be made on the device to be located, e.g. the child's phone. 

The app provides intuitive menu navigation for setup.

## Further links
- AdAway: [Comprehensive description of the functionality (german)](https://www.kuketz-blog.de/adaway-werbe-und-trackingfrei-im-android-universum/)