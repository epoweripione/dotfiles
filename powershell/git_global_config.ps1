Param (
	[string]$Proxy = ""
)

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION = "$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

## If $Proxy not set, then use environment variable(http_proxy, https_proxy) by default
# if (!$Proxy) {
#     $Proxy = "127.0.0.1:7890"
# }

if ($Proxy) {
    if (check_http_proxy_up $Proxy) {
        $Proxy = "http://$Proxy"
    } elseif (check_socks5_proxy_up $Proxy) {
        $Proxy = "socks5://$Proxy"
    } else {
        $Proxy = ""
    }
}

## Fix: schannel: next InitializeSecurityContext failed: CRYPT_E_REVOCATION_OFFLINE (0x80092013)
# git config --system http.schannelCheckRevoke false
git config --system http.sslbackend openssl
# git config --system --list

if (Get-Command "git" -ErrorAction SilentlyContinue) {
    git config --global init.defaultBranch "main"

    git config --global core.autocrlf false
    git config --global core.safecrlf true
    git config --global core.filemode false

    git config --global color.ui true
    git config --global color.status true
    git config --global color.diff true
    git config --global color.branch true
    git config --global color.interactive true

    # git config --global pull.rebase false  # merge (the default strategy)
    # git config --global pull.rebase true   # rebase
    git config --global pull.ff only       # fast-forward only

    git config --global advice.detachedHead false

    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999

    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.ci commit
    git config --global alias.br branch
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

    ## [Always pull using HTTPS, push using SSH](https://stackoverflow.com/questions/43800726/always-pull-using-https-push-using-ssh-using-insteadof)
    # Github
    git config --global url."https://github.com/".insteadOf "git@github.com:"
    git config --global url."git@github.com:".pushInsteadOf "https://github.com/"
    git config --global url."git@github.com:".pushInsteadOf "git@github.com:" --append
    # Gitlab
    git config --global url."https://gitlab.com/".insteadOf "git@gitlab.com:"
    git config --global url."git@gitlab.com:".pushInsteadOf "https://gitlab.com/"
    git config --global url."git@gitlab.com:".pushInsteadOf "git@gitlab.com:" --append

    if ($Proxy) {
        git config --global http.proxy "$Proxy"
        git config --global https.proxy "$Proxy"

        ## Fix `ssh -T git@github.com` can't be established
        # ssh -v -i "$HOME/.ssh/id_ed25519" -o "ProxyCommand connect -H 127.0.0.1:7890 %h %p" -T git@github.com
        # git -c core.sshCommand="ssh -v -i $HOME/.ssh/id_ed25519 -o 'ProxyCommand connect -H 127.0.0.1:7890 %h %p'"
        ## or add `ProxyCommand` in `.ssh/config`:
        ## `ProxyCommand connect -H 127.0.0.1:7890 %h %p`
        # if (Get-Command "connect" -ErrorAction SilentlyContinue) {
        #     if ((${env:GLOBAL_PROXY_IP}) -and (${env:GLOBAL_PROXY_MIXED_PORT})) {
        #         git config --global core.sshCommand "ssh -o 'ProxyCommand connect -H ${env:GLOBAL_PROXY_IP}:${env:GLOBAL_PROXY_MIXED_PORT} %h %p'"
        #     }
        # }
    } else {
        git config --global --unset http.proxy
        git config --global --unset https.proxy
        git config --global --unset core.sshCommand
    }

    if (Get-Command "delta" -ErrorAction SilentlyContinue) {
        git config --global core.pager delta

        git config --global delta.features "side-by-side line-numbers decorations"
        git config --global delta.plus-style "syntax #003800"
        git config --global delta.minus-style "syntax #3f0001"
        git config --global delta.syntax-theme Dracula

        git config --global delta.decorations.commit-decoration-style "bold yellow box ul"
        git config --global delta.decorations.file-style "bold yellow ul"
        git config --global delta.decorations.file-decoration-style none
        git config --global delta.decorations.hunk-header-decoration-style "cyan box ul"

        git config --global delta.line-numbers.line-numbers-left-style cyan
        git config --global delta.line-numbers.line-numbers-right-style cyan
        git config --global delta.line-numbers.line-numbers-minus-style 124
        git config --global delta.line-numbers.line-numbers-plus-style 28

        git config --global interactive.diffFilter "delta --color-only"
    }
}
