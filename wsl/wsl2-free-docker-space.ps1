#Requires -RunAsAdministrator

# shutdown running WSL
wsl --shutdown

# open window diskpart with script file
@'
select vdisk file="%USERPROFILE%\AppData\Local\Docker\wsl\data\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
'@ | Tee-Object "$HOME\free-docker-space.txt" | Out-Null

diskpart /s "$HOME\free-docker-space.txt"
