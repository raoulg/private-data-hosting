# Group Setup for Shared Data

If multiple users need to transfer files to the same server, you can set up a shared directory with group permissions. This allows all members of a group to read and write to the shared folder.

## Choosing the Right Setup
In both scenariors, everyone with an API key can download files from the server.
The main difference is who can upload files to the server.
Before proceeding, decide which setup fits your team best:

### Option A: Single Sender (Simpler)
**Scenario**: One person has the hardware/resources to generate the data files.
-   **Pros**: simpler setup. No need to manage groups or permissions.
-   **Cons**: Only one person can upload files. If someone else wants to upload, they need to set up their own server or send the file to the "sender".
-   **Action**: You do **not** need this guide. Just follow the main `README.md`.

### Option B: Multiple Senders (Flexible)
**Scenario**: Multiple team members have the hardware and need to upload files to the same server.
-   **Pros**: Everyone can upload directly to the shared server. 
-   **Cons**: Requires setting up a group and shared directory (as described below).
-   **Action**: Follow the instructions below to set up a shared environment.

## 1. Overview
We will use the standard `/srv` folder for shared data.

## 2. List Groups and Owners
To see an overview of all users and groups on the system:
```bash
getent group
```

To check permissions of the shared folder (if it exists):
```bash
ls -ls /srv/shared
```

## 3. Create Group and Give Rights
Run the following commands on the server to create a group and configure the shared directory:

```bash
# Create a new group named 'collaborators'
sudo groupadd collaborators

# Create the shared directory
sudo mkdir -p /srv/shared

# Set the group ownership of the directory to 'collaborators'
sudo chgrp collaborators /srv/shared

# Set permissions:
# g+rws: Give group read, write, and execute (setgid) permissions.
# o-w: Remove write permission for others (security).
sudo chmod g+rws,o-w /srv/shared

# Add a user to the group (replace 'another_user' with the actual username)
sudo usermod -aG collaborators another_user
```

Repeat the `usermod` command for each user you want to add to the group. Users will need to log out and log back in for the group membership to take effect.

## 4. Local Configuration
Each user in the group needs to configure their local environment.

1.  **Run Setup**:
    ```bash
    make setup-uploader
    ```
2.  **Enter Details**:
    -   **Server IP**: The IP address of the shared server.
    -   **Remote Username**: Your personal username on the server.
3.  **Set Shared Path**:
    Open your `.env` file and manually set `REMOTE_PATH`:
    ```bash
    REMOTE_PATH=/srv/shared/
    ```

Now, when you run `make transfer`, files will be uploaded to `/srv/shared/` using your credentials.
