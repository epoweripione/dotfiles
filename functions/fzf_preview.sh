#!/usr/bin/env bash

# fzf: function to determine the preview command based on file type
fzf_preview_file() {
    local file="$1"
    local mime_type mime_category mime_kind
    local archive_ext_list archive_ext TargetExt

    if [[ -d "$file" ]]; then
        # Preview directories using tree' or 'eza'
        eza --tree --icons --color=always --level=2 --group-directories-first "$file" || tree -C -L2 "$file"
        return
    fi

    # [All MIME types](https://mimetype.io/all-types)
    mime_type=$(file -bL --mime-type "$file")
    mime_category=${mime_type%%/*}
    mime_kind=${mime_type##*/}

    if [[ "$mime_category" == "text" ]]; then
        # preview text files with syntax highlighting using 'bat'
        # Fallback to 'cat' or 'less' if 'bat' is not installed
        bat --theme=TwoDark --color=always "$file" || cat "$file" || less "$file"
        return
    fi

    if [[ "$mime_category" == "image" ]]; then
        # preview images using a terminal image viewer, e.g., chafa, viu
        if [[ -x "$(command -v chafa)" ]]; then
            chafa -s "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" "$file"
        elif [[ -x "$(command -v viu)" ]]; then
            viu "$file"
        fi

        [[ -x "$(command -v exiftool)" ]] && exiftool "$file" && return
    fi

    if [[ "$mime_kind" == "pdf" ]]; then
        # preview PDFs by converting to text
        # pacman -S poppler-utils, brew install poppler
        [[ -x "$(command -v pdftotext)" ]] && pdftotext "$file" - && return
    fi

    if [[ "$mime_kind" == "vnd.openxmlformats-officedocument.spreadsheetml.sheet" || "$mime_kind" == "vnd.ms-excel" ]]; then
        # pip_Package_Install "csvkit[zstandard]"
        [[ -x "$(command -v in2csv)" ]] && in2csv "$1" | xsv table | bat -ltsv --theme=TwoDark --color=always && return
    fi

    if [[ "$file" =~ .(zip|tar|zst|tbz2|tbz|tgz|txz|rar|7z|bz2|bz|gz|xz)$ ]]; then
        # List contents of archives
        case "$file" in
            *.zip)
                unzip -l "$file"
                # unzip -Z1 "$file"
                ;;
            *.tar.bz2 | *.tar.bz | *.tbz2 | *.tbz)
                tar -jtvf "$file"
                ;;
            *.tar.gz | *.tgz)
                tar -ztvf "$file"
                ;;
            *.tar.xz | *.txz)
                tar -Jtvf "$file"
                ;;
            *.tar.zst)
                tar -I zstd -tvf "$file"
                ;;
            *.tar)
                tar -tvf "$file"
                ;;
            *.rar)
                [[ -x "$(command -v unrar)" ]] && unrar l "$file"
                ;;
            *.bz2 | *.bz)
                bzcat "$file"
                ;;
            *.gz)
                zcat "$file"
                ;;
            *.xz)
                xzcat "$file"
                ;;
            *.7z)
                [[ -x "$(command -v 7zz)" ]] && 7zz l "$file" || 7z l "$file"
                ;;
        esac
    fi

    if [[ "$mime_category" == "application" ]] && [[ "$mime_kind" =~ (executable|msi|x-|vnd|octet|stream) ]]; then
        file -bL --mime-type "$file" && return
    fi

    if [[ "$mime_category" == "audio" || "$mime_category" == "video" ]]; then
        file -bL --mime-type "$file" && return
    fi

    bat --theme=TwoDark --color=always "$file" || file -bL --mime-type "$file"
}
