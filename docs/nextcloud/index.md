# Nextcloud

Nextcloud is an open-source platform for file storage and collaboration. Depending on the installed apps and configuration, it can also synchronize calendars, contacts, notes, and tasks. With self-hosting, you are responsible for updates, access controls, backups, and recovery.

## 🧭 Why Nextcloud?

Nextcloud can be a useful alternative to a consumer cloud service, but the benefits depend on how it is deployed and maintained.

- **Data control and privacy:** Self-hosting lets you manage storage and access. Protection still depends on server configuration, updates, credentials, and backups.
- **Customization and flexibility:** You can install additional apps, customize the interface, and integrate other services.
- **Cost control:** Self-hosting can be cost-effective over time, but hardware, power, maintenance, and backups also have costs.
- **Scalability:** You can expand storage and features as requirements grow.
- **Configurable security:** You can manage firewalls, encryption, and updates yourself. This also creates ongoing maintenance responsibilities.
- **Offline access:** Files can be synchronized for offline use, depending on the client and settings.
- **Collaboration:** File sharing, calendar, contacts, and collaborative document editing are available through Nextcloud apps.
- **Integration:** Nextcloud can integrate with existing infrastructure and authentication systems.
- **Community and learning:** The project has active community support and documentation. Self-hosting is also a practical way to learn server administration.

> Synchronization is not an independent backup. Plan and test separate backups.

## ⚙️ Set up Nextcloud

### 📋 Requirements

- A Nextcloud server, either self-hosted or managed by a provider.
- A Nextcloud account and, for mobile synchronization, the Nextcloud mobile client.
- For contacts and calendars, a CalDAV/CardDAV client such as DAVx⁵ on Android.
- Optional apps for notes, tasks, and document editing.

### 🖥️ Server

1. Choose a Nextcloud provider or self-host the server.
2. Check storage limits, privacy terms, backup options, and recovery options. Plans and features change.
3. Enable the apps and features you need, such as Files, Calendar, Contacts, Notes, and Tasks. Menu names and available apps vary by provider and Nextcloud version.
4. Store the server address and credentials in a password manager. Do not put passwords in shared or unencrypted notes.

For PC synchronization, install the Nextcloud desktop client and connect it to the same server.

### 📱 Mobile apps

- ![F-Droid](../_static/ico/fdroid.ico) **[F-Droid](https://f-droid.org/)**: Catalog of free and open-source apps. Open source alone is not a security guarantee; check publishers, permissions, and updates.
- ![Nextcloud](../_static/ico/nextcloud.ico) **[Nextcloud](https://f-droid.org/packages/com.nextcloud.client/)**: Client for file synchronization and automatic uploads.
- ![DAVx⁵](../_static/ico/davx5.ico) **[DAVx⁵](https://f-droid.org/packages/at.bitfire.davdroid/)**: CalDAV/CardDAV synchronization for contacts, calendars, and tasks.
- ![Nextcloud Notes](../_static/ico/nextcloudnotes.ico) **[Nextcloud Notes](https://f-droid.org/packages/it.niedermann.owncloud.notes/)**: View and edit notes stored in Nextcloud.
- ![OpenTasks](../_static/ico/opentasks.ico) **[OpenTasks](https://f-droid.org/packages/org.dmfs.tasks/)**: Task manager that can synchronize tasks through a compatible CalDAV account.

### 🔐 Configure synchronization

1. Sign in to the Nextcloud app with the server address and your account. Grant only the permissions required for the features you use.
2. Configure DAVx⁵ with the server address and credentials.
3. Select the required CardDAV address books and CalDAV calendars. Availability and setup depend on the server and Android version.
4. If needed, install and configure OpenTasks for tasks and Nextcloud Notes for notes. Check which server apps and integrations are required.
5. If you need to edit documents, install Collabora or another compatible office app. Check the current Nextcloud app and client requirements.

### 👥 Synchronize contacts

Contact synchronization can be confusing at first. A typical workflow is:

1. Prepare contacts in the existing system and, if necessary, group them, for example into “own contacts” and “contacts shared with family.”
2. Export contacts from the existing system as VCF file or files.
3. If needed, create contact groups in the address book or DAVx⁵. Editing options depend on the server and contacts app.
4. Copy the VCF files to the phone or synchronize them through Nextcloud.
5. Import the VCF files into the desired address books using the Contacts app, not the Calendar app. Menu names vary by Android device.
6. Synchronize again and verify that the contacts appear in the expected groups.

## 📝 Further tips

- Do not share account credentials if separate access rights matter. Prefer separate accounts and explicit shares where available.
- A shared account does not provide reliable separation of personal data.
- Test restore and synchronization with a small data set before relying on Nextcloud for important files.
- Review the provider's terms and the server's backup/restore options before storing sensitive data.

## 📚 Further links

- [Nextcloud official documentation](https://docs.nextcloud.com/)
- [DAVx⁵](https://www.davx5.com/)
- [F-Droid](https://f-droid.org/)