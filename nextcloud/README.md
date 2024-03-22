# Introduction

## Why Nextcloud?

Nextcloud is a versatile, open-source platform facilitating secure file storage and collaboration. Beyond file syncing, it seamlessly integrates calendar, contacts, and notes synchronization. Empowering users to manage their digital lives, Nextcloud offers a unified solution for seamless access and collaboration across devices, ensuring efficient and synchronized personal and professional workflows.

## Key features of Nextcloud
1. **Data Control and Privacy:** Hosting Nextcloud on your own server gives you complete control over your data. You decide where it's stored, who has access, and how it's managed, enhancing your privacy.
1. **Customization and Flexibility:** Self-hosting allows you to tailor Nextcloud to your specific needs. You can install additional apps, customize the user interface, and integrate it with other services and tools.
1. **Cost Efficiency:** While there may be initial setup costs, self-hosting can be cost-effective in the long run. You won't incur recurring subscription fees, and you can choose hardware that fits your budget.
1. **Scalability:** With self-hosted Nextcloud, you have the flexibility to scale your infrastructure based on your requirements. This is particularly beneficial for businesses or individuals with growing storage needs.
1. **Enhanced Security:** You have direct control over the security measures implemented on your server. This includes choosing encryption methods, configuring firewalls, and staying on top of security updates, reducing reliance on external providers.
1. **Offline Access:** Self-hosted Nextcloud allows for offline access to your files. This is especially useful when you are in environments without consistent internet connectivity.
1. **Collaboration Features:** Nextcloud provides a suite of collaboration tools, including file sharing, calendar, contacts, and collaborative document editing. When self-hosted, these tools can be tailored to your specific collaboration needs.
1. **Integration with Existing Systems:** Self-hosting Nextcloud enables seamless integration with your existing infrastructure and authentication systems. This can streamline user management and make the user experience more cohesive.
1. **Community Support:** The Nextcloud community is active and provides support through forums, documentation, and other channels. Self-hosting allows you to benefit from this collaborative environment.
1. **Learning Opportunity:** Hosting Nextcloud on your own server provides a valuable learning experience. It allows you to deepen your understanding of server administration, security practices, and the inner workings of cloud services.

While self-hosting Nextcloud offers these advantages, it's important to consider your technical skills, available resources, and the level of maintenance required before deciding on a self-hosted solution.


# Setting up Nextcloud

## Set up a Nextcloud server
As an alternative to various big tech clouds (google, dropbox), you can set up your own Nextcloud, e.g. on a Raspberry, or alternatively choose a hosted "Managed Nextcloud". 
A limited, but nevertheless recommendable and free Nextcloud is offered by https://www.hosting.de/.
For syncing with your own PC, there is also Nextcloud PC client software to synchronize the files between Nextcloud, the phone and the PC.

## Install the required apps on the mobile device
1. ![fdroid.png](../de-googled-phone/img/fdroid.png) **F-Droid**: Alternative Playstore with generally secure open source apps
1. ![fdroid.png](../de-googled-phone/img/nextcloud.png) **Nextcloud**: Synchronization client for the Nextcloud app, basis for syncing files, contacts, calendars, tasks, etc.
1. ![fdroid.png](../de-googled-phone/img/dav5x.png) **DAVx⁵**: DAVx⁵ is a CalDAV/CardDAV management and synchronization app for Android that integrates seamlessly with calendar and contacts apps. With DAVx⁵ you have your contacts, appointments and tasks on your own server or a trusted CalDAV/CardDAV service under your own control.

## Configure Nextcloud server
1. set up the Nextcloud service, e.g. at Hosting.de. 
2. configure Nextcloud so that the corresponding functions of the service are available. To do this, activate the Nextcloud function online at hosting.de and the corresponding apps in the App Center (calendar, contacts, notes, tasks, etc.).
3. write down the server address together with the password (preferably stored in a password management system such as KeePass on the PC). This is something like: https://xxxxxxxxxxxxxxxxxxxx.Nextcloud.hosting.zone 
4. tip: To make it easier to have the (hopefully long and therefore secure) passwords to hand, it is advisable to transfer the KeePass.kdbx password container from the PC to the phone via USB at this point and then use it with KeePassDX.
5. set up the Nextcloud app: Open the Nextcloud app and log in with the server address. → Then "Connect to the account" by entering the hosting.de access data via "Login". → Finally, the Nextcloud app must be granted permission to access the phone's file system. 
6. setup DAVx5: Open the DAVx5 app → grant permissions → add account with "URL and user name" (enter the server address, the hosting.de user name and password here again. Now you can select the desired CARDDAV contacts and CALDAV calendars to be synchronized. Integration into the native Android apps such as Calendar and Contacts takes place automatically. The OpenTasks app is now also synchronized.
7. if necessary, install Collabora to be able to open and edit the documents from the Nextcloud

## Syncing Contacts
The contacts sync is a bit tricky at first. Here is a small guide to the procedure
1. prepare contacts in the existing system (e.g. google) properly and, if necessary, group them so that they can also be divided into "own contacts" and "contacts shared with partner/family", etc.
2. export contacts from google as VCF file(s)
3. create the corresponding groups for the contacts via DAVx5. Attention - the name of the group and the description text cannot be changed later. Click on Synchronize again in DAVx5
4. copy the VCF files to the phone or synchronize them to the phone via Nextcloud
5. now in the regular calendar app via Settings → Import the contacts from the VCF into the respective contact group

## Further tips on Nextcloud
* The free plan of the Managed Nextcloud from hosting.de only allows one user. However, several calendars and contact groups can be created, each of which can then only be used by one partner (i.e. intended for synchronization) or can be used jointly, e.g. for a family calendar. You then share a single Nextcloud account and can view practically all calendars and contacts, but only subscribe to those you are entitled to on a trust basis.


