# HelloWorld – IIS Automated Provisioning

## 1. Overview

This PowerShell script automates the provisioning of an IIS environment for the Hello World application.

The script configures the required Windows and IIS resources, including:

* Local Windows security group;
* Membership of the specified service account in the local group;
* IIS Application Pool;
* Application Pool identity using a specific Windows account;
* IIS website;
* HTTP binding;
* IIS log directory;
* IIS application (sub-application);
* Application Pool association.

The objective is to make the IIS environment reproducible and reduce the amount of manual configuration required.

---

## 2. Requirements

The script must be executed on a Windows machine with administrative privileges.

The following components are required:

* Windows Server or Windows with IIS installed;
* IIS Management Tools;
* PowerShell;
* `WebAdministration` PowerShell module;
* A Windows user account to run the IIS Application Pool;
* Administrative privileges.

The script imports the IIS management module automatically:

```powershell
Import-Module WebAdministration
```

---

## 3. IIS Service

Before running the provisioning script, IIS can be started with:

```cmd
iisreset /start
```

The IIS service must be running before the website and application configuration is validated.

---

## 4. Script

The provisioning script is:

```text
iis.ps1
```

The script accepts the configuration through command-line parameters, allowing the same script to be reused in different environments.

---

## 5. Parameters

| Parameter          | Description                                  |
| ------------------ | -------------------------------------------- |
| `SiteName`         | IIS website name                             |
| `SitePhysicalPath` | Physical path of the website                 |
| `Port`             | HTTP port                                    |
| `HostHeader`       | Host name used by the website                |
| `GroupName`        | Local Windows security group                 |
| `UserName`         | Windows account used by the Application Pool |
| `UserPassword`     | Password of the Windows account              |
| `AppPoolName`      | IIS Application Pool name                    |
| `LogFilePath`      | IIS log directory                            |
| `AppName`          | IIS sub-application name                     |
| `AppPhysicalPath`  | Physical path of the sub-application         |

---

## 6. Example

The following command provisions the HelloWorld IIS environment:

```powershell
.\iis.ps1 `
    -SiteName "HelloWorld" `
    -SitePhysicalPath "C:\Apps\HelloWorldiis" `
    -Port 80 `
    -HostHeader "helloworld.local" `
    -GroupName "HelloWorldGroup" `
    -UserName "hp-01\helloworld_svc" `
    -UserPassword (Read-Host -AsSecureString "Password") `
    -AppPoolName "HelloWorldPool" `
    -LogFilePath "C:\Logs\HelloWorld" `
    -AppName "app" `
    -AppPhysicalPath "C:\Apps\HelloWorldApp\app"
```

The password is requested interactively and is not stored in the command or script.

---

## 7. Provisioning Process

### 7.1 Local Windows Group

The script checks whether the specified local group already exists.

If the group does not exist, it is created.

The specified Windows account is then added to the group.

This provides a dedicated security group for the application.

---

### 7.2 IIS Application Pool

The script checks whether the specified Application Pool already exists.

If necessary, it creates the Application Pool.

The Application Pool is configured to run using the specified Windows account:

```text
Identity Type: SpecificUser
```

This allows the application to execute using a dedicated service account rather than the default IIS identity.

---

### 7.3 IIS Website

The script creates the IIS website if it does not already exist.

Example:

```text
Site Name:       HelloWorld
Physical Path:   C:\Apps\HelloWorldiis
HTTP Port:       80
Host Header:     helloworld.local
```

The HTTP binding is configured as:

```text
*:80:helloworld.local
```

The application can then be accessed through:

```text
http://helloworld.local
```

---

### 7.4 IIS Logging

The script creates the configured log directory if necessary:

```text
C:\Logs\HelloWorld
```

The IIS website logging directory is then configured to use this location.

This makes the application's IIS logs easier to locate and manage.

---

### 7.5 IIS Sub-Application

The script creates an IIS application below the main website.

Example:

```text
Site:
HelloWorld

Application:
app

Result:
HelloWorld/app
```

The physical path is:

```text
C:\Apps\HelloWorldApp\app
```

The application is configured to use:

```text
HelloWorldPool
```

as its Application Pool.

---

## 8. Resulting IIS Structure

After successful execution, the expected IIS structure is:

```text
IIS
└── Sites
    └── HelloWorld
        └── app
            ├── Physical Path:
            │   C:\Apps\HelloWorldApp\app
            │
            └── Application Pool:
                HelloWorldPool
```

The Application Pool runs using the configured Windows service account.

The website is available through:

```text
http://helloworld.local
```

---

## 9. Idempotent Provisioning

The script checks whether several resources already exist before creating them.

For example:

* Local group;
* Application Pool;
* IIS website;
* Log directory;
* IIS application.

This allows the script to be executed again without unnecessarily recreating existing IIS resources.

If a resource already exists, the script reports the condition and continues with the remaining configuration.

---

## 10. Expected Output

When the provisioning completes successfully, the script displays messages indicating the status of each operation.

The final message is:

```text
Provisionamento concluido.
```

At this point, the IIS environment has been provisioned and is ready for application deployment and validation.

---

## 11. Security Considerations

The script requires administrative privileges because it modifies:

* Windows local groups;
* Windows group membership;
* IIS configuration;
* IIS Application Pools;
* IIS bindings;
* Application directories.

The password for the Application Pool account should not be stored directly in source code, Git history, or configuration files.

The script uses:

```powershell
Read-Host -AsSecureString
```

to request the password interactively.

For production automation, credentials should be supplied through an appropriate secret-management mechanism.

---

## 12. Summary

This script automates the IIS provisioning process for the HelloWorld application.

Instead of manually configuring IIS, the required environment can be created using a single PowerShell command.

The provisioning workflow is:

```text
PowerShell Script
       |
       +-- Local Windows Group
       |
       +-- Service Account
       |
       +-- IIS Application Pool
       |
       +-- IIS Website
       |      |
       |      +-- HTTP Binding
       |
       +-- IIS Logging
       |
       +-- IIS Application
       |
       v
  IIS Environment Ready
```
