#Requires -RunAsAdministrator

# https://docs.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/about/
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V


# Get-Command -Module hyper-v | Out-GridView

# Get-VM | Where-Object {$_.State -eq 'Running'}
# Get-VM | Where-Object {$_.State -eq 'Off'}

# Start-VM -Name <virtual machine name>
# Get-VM | Where-Object {$_.State -eq 'Off'} | Start-VM
# Get-VM | Where-Object {$_.State -eq 'Running'} | Stop-VM

# Get-VM -Name <VM Name> | Checkpoint-VM -SnapshotName <name for snapshot>


# https://docs.microsoft.com/powershell/module/hyper-v/new-vm?view=win10-ps
$VMName = "Win7"
# Mem: 2GB, Disk: 50GB
$VM = @{
    Name = $VMName
    MemoryStartupBytes = 2*1024*1024*1024
    Generation = 2
    NewVHDPath = "C:\HyperVM\$VMName\$VMName.vhdx"
    NewVHDSizeBytes = 50*1024*1024*1024
    BootDevice = "VHD"
    Path = "C:\HyperVM\$VMName"
    SwitchName = (Get-VMSwitch).Name
}

New-VM @VM


## https://docs.microsoft.com/zh-cn/virtualization/hyper-v-on-windows/quick-start/connect-to-network
## 通过宿主机活动网络适配器连接外部网络
# $net = Get-NetAdapter `
#     | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Virtual*"}
# New-VMSwitch -Name "External VM Switch" -AllowManagementOS $True -NetAdapterName $net.Name


# https://www.cnblogs.com/wswind/p/11007613.html
# 为虚拟机创建虚拟交换机并设置固定 IP，避免网络位置在宿主机重启后会变动
# 创建虚拟交换机，等同于在 Hyper-V 管理器界面中新建虚拟网络交换机
New-VMSwitch -SwitchName "NAT-VM" -SwitchType Internal
# 查看 NAT-VM 的 ifindex
$net = Get-NetAdapter | Where-Object {$_.Name -like "*NAT-VM*"}
# 创建ip，InterfaceIndex 参数自行调整为上一步获取到的 ifindex。这一步等同于在 控制面版-网卡属性 中设置 IP
New-NetIPAddress -IPAddress 192.168.56.1 -PrefixLength 24 -InterfaceIndex $net.ifIndex
# 创建 nat 网络，这一步是教程中的关键命令，24 为子网掩码位数，即：255.255.255.0
New-NetNat -Name "NAT-VM" -InternalIPInterfaceAddressPrefix 192.168.56.0/24
# 在 Hyper-V 管理器中设置虚拟机的网络适配器为 NAT-VM
# 进入虚拟机，设置固定 IP，前缀：192.168.56.*，网关：192.168.56.1

# 删除创建的 nat 网络
# Get-NetNat -Name "NAT-VM"
# Remove-NetNat -Name "NAT-VM"
