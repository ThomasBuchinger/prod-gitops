## HFS (Home File Server) Configuration

The configuration is persisted on a PV and only created/templated on the first run.
This is to preserve Changes to the Virtual-Directoy-Layout accross reboots. If you want to reset the Configuration, delete the ArgoCD **Application** (or Config PV) and ReSync from scratch


## Passwords

* **guest**: this-is-the-guest-account-password
* **admin**: default-admin-password
* **buc**:   default-admin-password