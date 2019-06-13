# Development Environment Configuration

This provides a reproducible Windows-based development environment. An Ubuntu VM provided by VirtualBox and managed by Vagrant is used
as the actual development workspace. Tooling such as Docker, go, etc. are installed within the VM and accessed over ssh.


## Pre-requisites

* SSH keys should be located in: `C:\Users\<username>\.ssh`
* (If required) Synced workspace directory should be created at `C:\Users\<username>\workspace`
* Contents of this repo should be located in `C:\Users\<username\.dotfiles`


## Usage

Start an Admin Powershell by pressing `Win+x`, then selecting the `Windows PowerShell (Admin)` option, then run:

```
PS> cd ~/.dotfiles
PS> ./windows.ps1
```

Icons in your Start Menu and on your Desktop should appear to control the development VM.
