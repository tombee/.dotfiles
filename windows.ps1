Write-Host " -> Installing Chocolatey" 
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex

refreshenv

Write-Host " -> Installing Required Packages" 
cinst git.install -y
cinst virtualbox -y
cinst vagrant -y
cinst vscode -y
cinst 7zip.install -y

vagrant plugin install vagrant-disksize

@"
Host vm
    User $($env:USERNAME)
    HostName 127.0.0.1
"@ | Set-Content "$env:ALLUSERSPROFILE/vscode.config"

$env:path+='C:\Program Files\Git\cmd'

$WScriptShell = New-Object -ComObject WScript.Shell
$LinuxVMStartMenu = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Linux VM\"
$Shortcuts = @(
    @{
        Location = "$env:Public\Desktop\Windows Bash.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~; exec bash'"
        Icon = "C:\Windows\System32\imageres.dll, 262"
        Admin = $False
    },
    @{
        Location = "$LinuxVMStartMenu\Windows Bash.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~; exec bash'"
        Icon = "C:\Windows\System32\imageres.dll, 262"
        Admin = $False
    },
    @{
        Location = "$env:Public\Desktop\Start Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~/.dotfiles; exec vagrant up'"
        Icon = "C:\Windows\System32\imageres.dll, 232"
        Admin = $True
    },
    @{
        Location = "$LinuxVMStartMenu\Start Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~/.dotfiles; exec vagrant up'"
        Icon = "C:\Windows\System32\imageres.dll, 232"
        Admin = $True
    },
    @{
        Location = "$env:Public\Desktop\Suspend Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~/.dotfiles; exec vagrant suspend'"
        Icon = "C:\Windows\System32\imageres.dll, 230"
        Admin = $True
    },
    @{
        Location = "$LinuxVMStartMenu\Suspend Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~/.dotfiles; exec vagrant suspend'"
        Icon = "C:\Windows\System32\imageres.dll, 230"
        Admin = $True
    },
    @{
        Location = "$env:Public\Desktop\Delete Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~/.dotfiles; exec vagrant destroy -f'"
        Icon = "C:\Windows\System32\imageres.dll, 229"
        Admin = $True
    },
    @{
        Location = "$LinuxVMStartMenu\Delete Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'cd ~/.dotfiles; exec vagrant destroy -f'"
        Icon = "C:\Windows\System32\imageres.dll, 229"
        Admin = $True
    },
    @{
        Location = "$env:Public\Desktop\SSH Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'linux'"
        Icon = "C:\Windows\System32\imageres.dll, 262"
        Admin = $True
    },
    @{
        Location = "$LinuxVMStartMenu\SSH Linux VM.lnk"
        Target = "C:\Program Files\Git\usr\bin\mintty.exe"
        Args = "/bin/bash -l -c 'linux'"
        Icon = "C:\Windows\System32\imageres.dll, 262"
        Admin = $True
    }
)

New-Item "$LinuxVMStartMenu" -ItemType Directory -Force
foreach ($s in $Shortcuts) {
    $Shortcut = $WScriptShell.CreateShortcut($s['Location'])
    $Shortcut.TargetPath = $s['Target']
    $Shortcut.Arguments = $s['Args']
    if($s['Icon']) {
        $Shortcut.IconLocation = $s['Icon']
    }
    $Shortcut.Save()
    if($s['Admin'] -eq $True) {
        # Make shortcuts run as admin
        $bytes = [System.IO.File]::ReadAllBytes($s['Location'])
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($s['Location'], $bytes)
    }
}

if((Test-Path $HOME/.dotfiles -Type 'Container') -eq $False) {
    Write-Host " -> Cloning Dotfiles" 
    git clone git@gh.riotgames.com:$env:UserName/.dotfiles ~/.dotfiles
}

Write-Host " -> Linking shell configuration"
$files = (Get-ChildItem '~\.dotfiles\shell\*')
ForEach ($file in $files) {
    if ($file -Match 'bash_' -AND $file -NotMatch 'bash_profile') {
        continue
    }    
    echo "Linking $HOME\.$($file.Name) to $($file.FullName)"
    New-Item -ItemType SymbolicLink -Path $HOME -Name ".$($file.Name)" -Value $file.FullName -Force
}

Write-Host " -> Linking vscode configuration"
New-Item $env:APPDATA\Code\User -ItemType Directory -Force
$files = (Get-ChildItem '~\.dotfiles\vscode\*')
ForEach ($file in $files) {
    echo "Linking $env:APPDATA\Code\User\$($file.Name) to $($file.FullName)"
    New-Item -ItemType SymbolicLink -Path $env:APPDATA\Code\User -Name $file.Name -Value $file.FullName -Force
}

Write-Host "Installation complete"
