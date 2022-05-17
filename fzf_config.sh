#!/usr/bin/env bash

# shellcheck disable=SC1094,SC2086,SC2296

# https://github.com/junegunn/fzf
function fzf-tmux-popup() {
    fzf-tmux -p "${TMUX_POPUP_DIMENSION:-80%,80%}" "$@"
}

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

# use fd to generate input for fzf
if [[ -x "$(command -v fd)" ]]; then
    # export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --no-ignore --exclude .git'
    export FZF_DEFAULT_COMMAND="fd --type file --color=always"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# export FZF_DEFAULT_OPTS="--ansi --multi $(fzf_sizer_preview_window_settings)"
FZF_DEFAULT_OPTS="
--ansi
--multi
--bind='ctrl-j:preview-page-down,ctrl-k:preview-page-up,alt-j:preview-bottom,alt-k:preview-top'
--bind='tab:toggle+down,btab:toggle+up,shift-tab:toggle+up,ctrl-a:toggle-all,ctrl-s:toggle-sort'
--bind='?:toggle-preview,ctrl-space:toggle-preview,alt-w:toggle-preview-wrap,enter:accept'
--layout='reverse'
--preview-window='right,70%'
--height='70%'
"
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"

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
    # fzf-tab
    # https://github.com/Aloxaf/fzf-tab
    # set list-colors to enable filename colorizing
    [[ ! -s "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab/modules/Src/aloxaf/fzftab.so" ]] && \
        zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

    # [kill/ps] preview of full commandline arguments
    zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
        '[[ "$group" == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
    zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags '--preview-window=down:3:wrap'

    # custom keybindings
    zstyle ':fzf-tab:*' fzf-bindings 'tab:toggle+down' 'btab:toggle+up' 'shift-tab:toggle+up' 'enter:accept' 'ctrl-a:toggle-all'

    # preview directory's content with exa when completing cd
    # zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -T --git-ignore --icons -L1 $realpath'
    zstyle ':fzf-tab:complete:cd:*' fzf-flags '--height=50%'

    if [[ -n "$TMUX" && -n "${TMUX_VERSION_320}" ]]; then
        # zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        zstyle ':fzf-tab:*' fzf-command fzf-tmux-popup
        zstyle ':fzf-tab:complete:cd:*' popup-pad 30 0
    fi
else
    # fzf-tab-completion
    # https://github.com/lincheney/fzf-tab-completion
    if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab-completion" ]]; then
        source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab-completion/zsh/fzf-zsh-completion.sh"
        bindkey '^I' fzf_completion
    fi
fi

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
alias fzf-cat='${FZF_REAL_COMMAND:-fzf} --preview="cat {}"'

alias fzf-file='${FZF_REAL_COMMAND:-fzf} --layout=reverse --info=inline --border --preview-window=up,1,border-horizontal'\
' --color="fg:#bbccdd,fg+:#ddeeff,bg:#334455,preview-bg:#223344,border:#778899"'\
' --preview="file {}"'

alias fzf-tree='echo "$PWD" | ${FZF_REAL_COMMAND:-fzf} --preview="exa -T --git-ignore --icons {}"'

alias fzf-tree-dir='echo "$PWD" | ${FZF_REAL_COMMAND:-fzf} --preview="exa -T -D --git-ignore --icons {}"'

if [[ -x "$(command -v bat)" ]]; then
    alias bat-themes='bat --list-themes | ${FZF_REAL_COMMAND:-fzf} --preview="bat --theme={} --color=always ${ZSH}/oh-my-zsh.sh"'
    alias fzf-bat='${FZF_REAL_COMMAND:-fzf} --preview="bat --theme=TwoDark --style=numbers,changes --color=always {}"'
fi

if [[ -x "$(command -v pistol)" ]]; then
    alias fzf-pistol='${FZF_REAL_COMMAND:-fzf} --preview="pistol {}"'
fi

if [[ -x "$(command -v viu)" ]]; then
    alias fzf-viu='${FZF_REAL_COMMAND:-fzf} --preview="viu {}"'
fi

unset TMUX_VERSION
unset TMUX_VERSION_320
