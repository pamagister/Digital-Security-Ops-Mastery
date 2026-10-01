![English](../_static/ico/uk.ico)[English](README_en.md) | ![Deutsch](../_static/ico/germany.ico)[Deutsch](README.md) 

# Introduction

## Why Nextcloud?

Nextcloud is an open-source platform for file storage and collaboration. Depending on installed apps and configuration, it can also synchronize calendars, contacts, and notes. With self-hosting, you are responsible for updates, access controls, backups, and recovery.

## Key features of Nextcloud
1. **Data control and privacy:** Self-hosting lets you manage storage and access, but protection depends on server configuration, updates, credentials, and backups.
1. **Customization and Flexibility:** Self-hosting allows you to tailor Nextcloud to your specific needs. You can install additional apps, customize the user interface, and integrate it with other services and tools.
1. **Cost Efficiency:** While there may be initial setup costs, self-hosting can be cost-effective in the long run. You won't incur recurring subscription fees, and you can choose hardware that fits your budget.
1. **Scalability:** With self-hosted Nextcloud, you have the flexibility to scale your infrastructure based on your requirements. This is particularly beneficial for businesses or individuals with growing storage needs.
1. **Configurable security:** You can manage measures such as firewalls, encryption, and updates yourself. This also creates ongoing maintenance responsibilities.
1. **Offline Access:** Self-hosted Nextcloud allows for offline access to your files. This is especially useful when you are in environments without consistent internet connectivity.
1. **Collaboration Features:** Nextcloud provides a suite of collaboration tools, including file sharing, calendar, contacts, and collaborative document editing. When self-hosted, these tools can be tailored to your specific collaboration needs.
1. **Integration with Existing Systems:** Self-hosting Nextcloud enables seamless integration with your existing infrastructure and authentication systems. This can streamline user management and make the user experience more cohesive.
1. **Community Support:** The Nextcloud community is active and provides support through forums, documentation, and other channels. Self-hosting allows you to benefit from this collaborative environment.
1. **Learning Opportunity:** Hosting Nextcloud on your own server provides a valuable learning experience. It allows you to deepen your understanding of server administration, security practices, and the inner workings of cloud services.

Consider your technical skills, resources, and ongoing maintenance before self-hosting. Synchronization is not an independent backup: plan and test separate backups.


# Setting up Nextcloud

## Set up a Nextcloud server
As an alternative to cloud services, you can self-host Nextcloud or choose a managed provider. Check storage limits, privacy terms, backups, and recovery options with the provider; plans and features change.
For syncing with your own PC, there is also Nextcloud PC client software to synchronize the files between Nextcloud, the phone and the PC.

## Install the required apps on the mobile device
1. ![app_image](../_static/ico/fdroid.ico) **F-Droid**: Catalog of free and open-source apps. Open source alone is not a security guarantee; check publishers, permissions, and updates.
1. ![app_image](../_static/ico/nextcloud.ico) **Nextcloud**: Client for synchronizing files and automatic uploads. Contacts, calendars, and tasks are usually synchronized through DAVx⁵ using CardDAV/CalDAV.
1. ![app_image](../_static/ico/davx5.ico) **DAVx⁵**: DAVx⁵ is a CalDAV/CardDAV management and synchronization app for Android that integrates seamlessly with calendar and contacts apps. With DAVx⁵ you have your contacts, appointments and tasks on your own server or a trusted CalDAV/CardDAV service under your own control.
1. ![app_image](../_static/ico/nextcloudnotes.ico) **[Nextcloud Notes](https://f-droid.org/packages/it.niedermann.owncloud.notes/)**: View and edit notes stored in Nextcloud.
1. ![app_image](../_static/ico/opentasks.ico) **[OpenTasks](https://f-droid.org/packages/org.dmfs.tasks/)**: Task manager that can synchronize tasks through a compatible CalDAV account.

## Configure Nextcloud server
1. Set up a Nextcloud service with a provider of your choice or self-host it.
1. Enable the required apps and features on the server (for example, calendar, contacts, notes, and tasks). Menus and available apps vary by provider and Nextcloud version.
1. Store the server address and credentials in a password manager. Do not put passwords in shared or unencrypted notes.
1. Sign in to the Nextcloud app with the server address and your account. Grant only the permissions required for the features you use.
1. Configure DAVx⁵ with the server address and credentials. Select the required CardDAV address books and CalDAV calendars. Availability and setup depend on the server and Android version.
1. If needed, install and configure OpenTasks for tasks and Nextcloud Notes for notes; check which server apps and integrations are required.
1. if necessary, install Collabora to be able to open and edit the documents from the Nextcloud

## Syncing Contacts
Contact synchronization can be tricky at first. Suggested steps:
1. prepare contacts in the existing system (e.g. google) properly and, if necessary, group them so that they can also be divided into "own contacts" and "contacts shared with partner/family", etc.
1. export contacts from google as VCF file(s)
1. If needed, create contact groups in the address book or DAVx⁵. Editing options depend on the server and contacts app. Synchronize again afterwards.
1. copy the VCF files to the phone or synchronize them to the phone via Nextcloud
1. Import the VCF files into the desired address books using the Contacts app (not the Calendar app). Menu names vary by Android device.

## Further tips on Nextcloud
* Do not share account credentials if separate access rights matter. Prefer separate accounts and explicit shares where available. A shared account does not provide reliable separation of personal data.
