# [aria2 - The next generation download utility](https://aria2.github.io/)

## Install
`sudo pacman -S aria2`

## Run
```bash
aria2c --enable-rpc --rpc-secret "rpc-secret"

# configuration file: $HOME/.aria2/aria2.conf
mkdir -p "$HOME/.aria2" && touch "$HOME/.aria2/aria2.session"
tee "$HOME/.aria2/aria2.conf" <<-EOF
# The directory to store the downloaded file
dir=$HOME/Downloads

# Enable disk cache. If SIZE is 0, the disk cache is disabled. Default: 16M
disk-cache=32M

# Specify file allocation method. none doesn't pre-allocate file space.
# Possible Values: none, prealloc, trunc, falloc Default: prealloc
file-allocation=prealloc

## Download options
# Resuming Download
continue=true

# The maximum number of parallel downloads for every queue item. Default: 5
max-concurrent-downloads=10

# The maximum number of connections to one server for each download. Default: 1
max-connection-per-server=10

# aria2 does not split less than 2*SIZE byte range. Possible Values: 1M -1024M Default: 20M
min-split-size=20M

# Download a file using N connections. Default: 5
split=5

# Set max overall download speed in bytes/sec. 0 means unrestricted. Default: 0
max-overall-download-limit=0

# Set max download speed per each download in bytes/sec. 0 means unrestricted. Default: 0
max-download-limit=0

# Set max overall upload speed in bytes/sec. 0 means unrestricted. Default: 0
max-overall-upload-limit=0

# Set max upload speed per each torrent in bytes/sec. 0 means unrestricted. Default: 0
max-upload-limit=0

# Disable IPv6. Default: false
disable-ipv6=false

## sessions
# Downloads the URIs listed in FILE.
input-file=$HOME/.aria2/aria2.session

# Save error/unfinished downloads to FILE on exit.
save-session=$HOME/.aria2/aria2.session

# Save error/unfinished downloads to a file specified by --save-session option every SEC seconds.
# If 0 is given, file will be saved only when aria2 exits. Default: 0
save-session-interval=60

## RPC Options
# Enable JSON-RPC/XML-RPC server. Default: false
enable-rpc=true

# Add Access-Control-Allow-Origin header field with value * to the RPC response. Default: false
rpc-allow-origin-all=false

# Listen incoming JSON-RPC/XML-RPC requests on all network interfaces.
# If false is given, listen only on local loopback interface. Default: false
rpc-listen-all=false

# Specify a port number for JSON-RPC/XML-RPC server to listen to. Possible Values: 1024 -65535 Default: 6800
rpc-listen-port=6800

# Set RPC secret authorization token. 
rpc-secret=RPCSecretT0ken

# Save meta data as ".torrent" file. Default: false
bt-save-metadata=true

## PT
# enable-dht6=false
# bt-enable-lpd=false
# enable-peer-exchange=false
# peer-id-prefix=-TR2770-
# user-agent=Transmission/2.92

## Set the command to be executed after download completed. Possible Values: /path/to/command
# on-download-complete=$HOME/.aria2/aria2_download_complete.sh
EOF

chmod 600 "$HOME/.aria2/aria2.conf"

# Install as systemd service
Install_systemd_Service "aria2" "aria2c" "$USER" "$HOME/.aria2"
```

## Test
```bash
curl -fsL -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0", "id": "1", "method": "aria2.tellActive", "params": ["token:rpc-secret"]}' 'http://[::1]:6800/jsonrpc' | jq

## "params":["token:rpc-secret",["download url"],{"dir":"file save dir"}]
## "params":["token:rpc-secret",["http://xxx.com/xxx.xx"],{"dir":"/home/user/Downloads"}]

## method:
# addUri [<uri>]
# remove <gid>
# tellStatus <gid>
# getPeers <gid>
# tellActive
# tellStopped <m>,<n>
# getGlobalStat
# shutdown
```

## Run `aria2` in background on Windows
- Create `aria2.conf`
- Create `aria2.vbs` and fill with the following script
```cmd
set ws = WScript.CreateObject("WScript.Shell")
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)

ws.Run "aria2c.exe --conf-path=" & scriptDir & "\aria2.conf", 0
```

## [AriaNg, a modern web frontend making aria2 easier to use.](https://github.com/mayswind/AriaNg/)

## [Aria2 Explorer](https://chrome.google.com/webstore/detail/aria2-explorer/mpkodccbngfoacfalldjimigbofkhgjn)
- `Motrix` Aria2-RPC-Server `http://localhost:16800/jsonrpc`
