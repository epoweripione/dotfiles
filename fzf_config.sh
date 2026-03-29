#!/usr/bin/env bash

# shellcheck disable=SC1094,SC2086,SC2296

# https://github.com/junegunn/fzf
function fzf-tmux-popup() {
    fzf-tmux -p "${TMUX_POPUP_DIMENSION:-80%,80%}" "$@"
}

# Function to determine the preview command based on file type
if [[ -f "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/functions/fzf_preview.sh" ]]; then
    source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/functions/fzf_preview.sh"

    # Export the function so fzf can use it in a subshell
    # Listing Exported Functions: `declare -p -f` or `export -p`
    # Unexporting: `declare -f -n function_name`
    DEFALUT_SHELL=$(basename "$SHELL")
    if [[ "${DEFALUT_SHELL}" == "zsh" ]]; then
        if ! grep -q "fzf_preview.sh" "$HOME/.zshenv" 2>/dev/null; then
            echo "" | tee -a "$HOME/.zshenv" >/dev/null
            echo "# fzf: function to determine the preview command based on file type" | tee -a "$HOME/.zshenv" >/dev/null
            echo "source ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/functions/fzf_preview.sh" | tee -a "$HOME/.zshenv" >/dev/null
        fi
    elif [[ "${DEFALUT_SHELL}" == "bash" ]]; then
        export -f fzf_preview_file
    fi

    # [~/.lessfilter](https://github.com/Aloxaf/fzf-tab/wiki/Preview#show-file-contents)
    if [[ ! -f "$HOME/.lessfilter" ]]; then
        echo '#!/usr/bin/env bash' | tee "$HOME/.lessfilter" >/dev/null

        echo "" | tee -a "$HOME/.lessfilter" >/dev/null
        echo "# fzf: function to determine the preview command based on file type" | tee -a "$HOME/.lessfilter" >/dev/null
        echo "source ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/functions/fzf_preview.sh" | tee -a "$HOME/.lessfilter" >/dev/null

        echo "" | tee -a "$HOME/.lessfilter" >/dev/null
        echo 'fzf_preview_file "$1"' | tee -a "$HOME/.lessfilter" >/dev/null

        chmod +x "$HOME/.lessfilter"
    fi
fi

# tmux session
if [[ -n "$TMUX" ]]; then
    TMUX_VERSION_320=""
    TMUX_VERSION=$(tmux -V 2>&1 | grep -Eo '([0-9]{1,}\.)+[0-9]{1,}' | head -n1)
    if version_ge "${TMUX_VERSION}" "3.2"; then
        TMUX_VERSION_320="true"
    fi
fi

FZF_REAL_COMMAND="fzf"
if [[ -n "$TMUX" ]]; then
    [[ -n "${TMUX_VERSION_320}" ]] && FZF_REAL_COMMAND="fzf-tmux-popup" || FZF_REAL_COMMAND="fzf-tmux"
fi
export FZF_REAL_COMMAND="${FZF_REAL_COMMAND}"
export TMUX_POPUP_DIMENSION="90%,80%"

# A --preview=.... generator that is based on the shell's current dimensions
# https://github.com/bigH/auto-sized-fzf
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/auto-sized-fzf" ]]; then
    source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/auto-sized-fzf/auto-sized-fzf.sh"
fi

# use `bfs` or `fd` to generate input for fzf
if [[ -x "$(command -v bfs)" ]]; then
    # [Using bfs with fzf](https://github.com/tavianator/bfs/discussions/119)
    export FZF_DEFAULT_COMMAND="bfs -s -color -mindepth 1 -exclude \( -name .git -or -name .hg -or -name node_modules \) -printf '%P\n' 2>/dev/null"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="bfs -s -color -mindepth 1 -exclude \( -name .git -or -name .hg -or -name node_modules \) -type d -printf '%P\n' 2>/dev/null"

    _fzf_compgen_path() {
        bfs -H "$1" -color -exclude \( -name .git -or -name .hg -or -name node_modules \) 2>/dev/null
    }

    _fzf_compgen_dir() {
        bfs -H "$1" -color -exclude \( -name .git -or -name .hg -or -name node_modules \) -type d 2>/dev/null
    }
elif [[ -x "$(command -v fd)" ]]; then
    # export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --no-ignore --exclude .git'
    export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude .hg --exclude node_modules --color=always"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --strip-cwd-prefix --hidden --follow --exclude .git --exclude .hg --exclude node_modules --color=always"
fi

# export FZF_DEFAULT_OPTS="--ansi --multi $(fzf_sizer_preview_window_settings)"
FZF_DEFAULT_OPTS="--ansi --multi \
--bind='ctrl-j:preview-page-down,ctrl-k:preview-page-up,alt-j:preview-bottom,alt-k:preview-top' \
--bind='tab:toggle+down,btab:toggle+up,shift-tab:toggle+up,ctrl-a:toggle-all,ctrl-s:toggle-sort' \
--bind='ctrl-/:toggle-preview,alt-/:change-preview-window(down|hidden|),alt-w:toggle-preview-wrap,enter:accept' \
--bind='ctrl-e:execute(\$EDITOR {} < /dev/tty)' \
--layout='reverse' \
--preview-window='right,60%' \
--height='~60%'
--border"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}"

export FZF_CTRL_T_OPTS='--walker-skip .git,node_modules,target --preview="fzf_preview_file {}"'
export FZF_ALT_C_OPTS='--walker-skip .git,node_modules,target --preview="fzf_preview_file {}"'

COPY_TOOL=""
[[ -x "$(command -v xsel)" ]] && COPY_TOOL="xsel --clipboard --input"
[[ -x "$(command -v xclip)" ]] && COPY_TOOL="xclip -selection clipboard"
[[ -x "$(command -v wl-copy)" ]] && COPY_TOOL="wl-copy"
[[ -x "$(command -v pbcopy)" ]] && COPY_TOOL="pbcopy"
if [[ -n "${COPY_TOOL}" ]]; then
    export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo -n {2..} | ${COPY_TOOL})+abort' --color header:italic --header 'Press CTRL-Y to copy command into clipboard'"
fi

# Utility tool for using git interactively
# https://github.com/wfxr/forgit
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/forgit" ]]; then
    forgit_log=fzf-glo
    forgit_diff=fzf-gd
    forgit_add=fzf-ga
    forgit_reset_head=fzf-grh
    forgit_ignore=fzf-gi
    forgit_checkout_file=fzf-gcf
    forgit_checkout_branch=fzf-gcb
    forgit_checkout_commit=fzf-gco
    forgit_clean=fzf-gclean
    forgit_stash_show=fzf-gss
    forgit_cherry_pick=fzf-gcp
    forgit_rebase=fzf-grb
    forgit_fixup=fzf-gfu

    source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/forgit/forgit.plugin.zsh"
fi

# Utility for using systemctl interactively
# https://github.com/NullSense/fuzzy-sys
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fuzzy-sys" ]]; then
    source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fuzzy-sys/fuzzy-sys.plugin.zsh"
fi

# tab completion
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]]; then
    # [fzf-tab](https://github.com/Aloxaf/fzf-tab)
    # set list-colors to enable filename colorizing
    [[ ! -s "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab/modules/Src/aloxaf/fzftab.so" ]] && \
        zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

    # [kill/ps] preview of full commandline arguments
    zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
        '[[ "$group" == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags '--preview-window=down:3:wrap'

    # To make fzf-tab follow FZF_DEFAULT_OPTS.
    # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
    zstyle ':fzf-tab:*' use-fzf-default-opts yes

    # set descriptions format to enable group support
    # NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
    zstyle ':completion:*:descriptions' format '[%d]'

    # switch group using `<` and `>`
    zstyle ':fzf-tab:*' switch-group '<' '>'

    # Minimal height of fzf's prompt
    zstyle ':fzf-tab:*' fzf-min-height '50'

    # custom keybindings
    # zstyle ':fzf-tab:*' fzf-bindings 'tab:toggle+down' 'btab:toggle+up' 'shift-tab:toggle+up' 'enter:accept' 'ctrl-a:toggle-all'

    ## [Preview](https://github.com/Aloxaf/fzf-tab/wiki/Preview)
    # preview directory's content with eza when completing cd
    # zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
    # zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'eza --tree --icons --color=always --level=2 --group-directories-first $realpath || tree -C -L2 "$realpath"'
    # zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-flags '--height=50%'

    # show file contents
    zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
    export LESSOPEN='|~/.lessfilter %s'

    # To disable or override preview for command options and subcommands, use
    # zstyle ':fzf-tab:complete:*:options' fzf-preview
    # zstyle ':fzf-tab:complete:*:argument-1' fzf-preview

    # environment variable
    zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'

    # Homebrew
    zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview 'HOMEBREW_COLOR=1 brew info $word'

    if [[ -n "$TMUX" && -n "${TMUX_VERSION_320}" ]]; then
        # zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        zstyle ':fzf-tab:*' fzf-command fzf-tmux-popup
        zstyle ':fzf-tab:complete:cd:*' popup-pad 30 0
    fi
else
    # [fzf-tab-completion](https://github.com/lincheney/fzf-tab-completion)
    if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab-completion" ]]; then
        source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab-completion/zsh/fzf-zsh-completion.sh"
        bindkey '^I' fzf_completion
    fi
fi

## [fzf-tab-source: a collection of fzf-tab completion sources](https://github.com/Freed-Wu/fzf-tab-source)
# Git_Clone_Update_Branch "Freed-Wu/fzf-tab-source" "${ZSH_CUSTOM}/plugins/fzf-tab-source"
# source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab-source/fzf-tab-source.plugin.zsh"

## fzf-tmux-pane & fzf-tmux-popup
## https://github.com/kevinhwang91/fzf-tmux-script
# if [[ -n "${TMUX_VERSION_320}" && -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tmux-script" ]]; then
#     if ! grep -q "fzf-tmux-pane" "$HOME/.tmux.conf.local" 2>/dev/null; then
#         tee -a "$HOME/.tmux.conf.local" >/dev/null <<-'EOF'
# ## fzf-tmux-pane
# set -s focus-events on
# if-shell '[ -f ~/.oh-my-zsh/custom/plugins/fzf-tmux-script/panes/fzf-panes.tmux ]' {
# #   if you want to exclude specified session, please set @fzf_panes_ex_session_pat
# #   for example, value equal to '^(floating)$', will exclude panes in session named 'floating':
# #   set -g '@fzf_panes_ex_session_pat' '^(floating)$'
# set-hook -g pane-focus-in[10] \
# "run -b 'bash ~/.oh-my-zsh/custom/plugins/fzf-tmux-script/panes/fzf-panes.tmux update_mru_pane_ids'"
# bind w run -b 'bash ~/.oh-my-zsh/custom/plugins/fzf-tmux-script/panes/fzf-panes.tmux new_window'
# bind \; run -b 'bash ~/.oh-my-zsh/custom/plugins/fzf-tmux-script/panes/fzf-panes.tmux select_last_pane'
# } {
# set-hook -ug pane-focus-in[10]
# bind w choose-tree -Z
# }
# EOF

#     # fzfp
#     # ls --color=always | fzfp --ansi --width=50% --height=50%
#     if [[ ! "$(command -v fzfp)" ]]; then
#         sudo cp -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tmux-script/popup/fzfp" "/usr/local/bin/fzfp" && \
#             sudo chmod 755 "/usr/local/bin/fzfp"
#     fi
#     # Setup fzfp in zsh
#     if [[ -n $TMUX_PANE ]] && (( $+commands[tmux] )) && (( $+commands[fzfp] )); then
#         # fallback to normal fzf if current session name is `floating`
#         export TMUX_POPUP_NESTED_FB='test $(tmux display -pF "#{==:#S,floating}") == 1'
#         export TMUX_POPUP_WIDTH=80%
#     fi
# fi

## Better git diffs with FZF
## https://medium.com/@GroundControl/better-git-diffs-with-fzf-89083739a9cb
# function fzf-git-diff() {
#     ## only work from the root of your git project
#     ## comparing your current branch to master
#     # fzf-git-diff master...
#     ## comparing the changes between two commits
#     # fzf-git-diff 4c674950..6d88a7bfd8
#     local preview='git diff $@ --color=always -- {-1}'
#     git diff --name-only $@ | ${FZF_REAL_COMMAND:-fzf} -m --preview "$preview"
# }

# fzf alias
alias fzf-preview='${FZF_REAL_COMMAND:-fzf} --preview="fzf_preview_file {}"'

alias fzf-cat='${FZF_REAL_COMMAND:-fzf} --preview="cat {}"'

alias fzf-file='${FZF_REAL_COMMAND:-fzf} --layout=reverse --info=inline --border --preview-window=up,1,border-horizontal'\
' --color="fg:#bbccdd,fg+:#ddeeff,bg:#334455,preview-bg:#223344,border:#778899"'\
' --preview="file {}"'

alias fzf-tree='echo "$PWD" | ${FZF_REAL_COMMAND:-fzf} --preview="exa -T --git-ignore --icons {}"'

alias fzf-tree-dir='echo "$PWD" | ${FZF_REAL_COMMAND:-fzf} --preview="exa -T -D --git-ignore --icons {}"'

if [[ -x "$(command -v bat)" ]]; then
    alias bat-themes='bat --list-themes | ${FZF_REAL_COMMAND:-fzf} --preview="bat --theme={} --color=always ${ZSH}/oh-my-zsh.sh"'
    alias fzf-bat='${FZF_REAL_COMMAND:-fzf} --preview="bat --theme=TwoDark --color=always {}"'
fi

if [[ -x "$(command -v pistol)" ]]; then
    alias fzf-pistol='${FZF_REAL_COMMAND:-fzf} --preview="pistol {}"'
fi

if [[ -x "$(command -v viu)" ]]; then
    alias fzf-viu='${FZF_REAL_COMMAND:-fzf} --preview="viu {}"'
fi

# [fix: image stays in the screen after the fzf is done](https://github.com/junegunn/fzf/issues/3228#issuecomment-1803402184)
autoload -Uz add-zsh-hook
fzf_preview_cleanup() {
    printf "\x1b_Ga=d,d=A\x1b\\"
}
add-zsh-hook precmd fzf_preview_cleanup

unset TMUX_VERSION
unset TMUX_VERSION_320
