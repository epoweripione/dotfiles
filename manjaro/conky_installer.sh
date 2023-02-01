#!/usr/bin/env bash

trap 'rm -rf "${WORKDIR}"' EXIT

[[ -z "${WORKDIR}" || "${WORKDIR}" != "/tmp/"* || ! -d "${WORKDIR}" ]] && WORKDIR="$(mktemp -d)"
[[ -z "${CURRENT_DIR}" || ! -d "${CURRENT_DIR}" ]] && CURRENT_DIR=$(pwd)

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi

colorEcho "${BLUE}Installing ${FUCHSIA}Conky${BLUE}..."
sudo pacman --noconfirm --needed -S conky-manager jq
sudo pacman --noconfirm --needed -S aur/conky-lua-nv

## System info
# lspci
# lscpu
# sudo lshw -class CPU
# sudo dmidecode --type processor
# lspci | grep VGA
# sudo lshw -C video
# sudo lshw -C network

# conky-colors
# https://github.com/helmuthdu/conky_colors
# http://forum.ubuntu.org.cn/viewtopic.php?f=94&t=313031
# http://www.manongzj.com/blog/4-lhjnjqtantllpnj.html
yay --noconfirm --needed -S aur/conky-colors-git

curl "${CURL_DOWNLOAD_OPTS[@]}" -o "$HOME/conky-convert.lua" \
    "https://raw.githubusercontent.com/brndnmtthws/conky/master/extras/convert.lua"

# conky-colors --help
conky-colors --theme=human --side=right --arch --cpu=2 --proc=5 \
    --swap --hd=mix --network --clock=modern --calendar
    # --weather=2161838 --bbcweather=1809858 --unit=C

# network interface
get_network_interface_default
[[ -n "${NETWORK_INTERFACE_DEFAULT}" ]] && \
    sed -i "s/ppp0/${NETWORK_INTERFACE_DEFAULT}/g" "$HOME/.conkycolors/conkyrc"

# display font
sed -i 's/font Liberation Sans/font Sarasa Term SC/g' "$HOME/.conkycolors/conkyrc" && \
    sed -i 's/font Liberation Mono/font Sarasa Mono SC/g' "$HOME/.conkycolors/conkyrc" && \
    sed -i 's/font ConkyColors/font Sarasa Term SC/g' "$HOME/.conkycolors/conkyrc" && \
    sed -i 's/font Sarasa Term SCLogos/font ConkyColorsLogos/g' "$HOME/.conkycolors/conkyrc" && \
    : && \
    lua "$HOME/conky-convert.lua" "$HOME/.conkycolors/conkyrc"
# conky -c "$HOME/.conkycolors/conkyrc"

# Hybrid
# https://bitbucket.org/dirn-typo
Git_Clone_Update_Branch "https://bitbucket.org/dirn-typo/hybrid.git" "$HOME/.conky/hybrid"
if [[ -d "$HOME/.conky/hybrid" ]]; then
    chmod +x "$HOME/.conky/hybrid/install.sh"
    cd "$HOME/.conky/hybrid" && "./install.sh"

    cp -f "$HOME/.conky/hybrid/fonts/"* "$HOME/.local/share/fonts/"
    sudo fc-cache -fv
fi

# if [[ ! -x "$(command -v inix)" ]]; then
#     colorEcho "${BLUE}  Installing ${FUCHSIA}inix${BLUE}..."
#     curl "${CURL_DOWNLOAD_OPTS[@]}" -o "${CURRENT_DIR}/inix" "smxi.org/inxi" && \
#         sudo mv "${CURRENT_DIR}/inix" "/usr/local/bin/inix" && \
#         chmod +x "/usr/local/bin/inix"
# fi

if [[ -s "$HOME/.config/conky/hybrid/hybrid.conf" ]]; then
    sed -i "s|home_dir = .*|home_dir = \"${HOME}\"|" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    # Disk
    sed -i 's|/opt|/var|g' "$HOME/.config/conky/hybrid/hybrid.conf"
    sed -i 's|/opt|/var|g' "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    ## monitor the temperature of CPU & GPU
    # sensors
    # grep -d skip . /sys/class/hwmon/hwmon[0-5]/*
    ## http://conky.pitstop.free.fr/wiki/index.php5?title=Using_Sensors_(en)
    ## https://askubuntu.com/questions/1322971/temperature-sensors-hwmon5-and-hwmon6-keep-swapping-around-how-can-i-consistent
    ## https://askubuntu.com/questions/5417/how-to-get-the-gpu-info
    # ls -la /sys/class/hwmon/
    ## https://bbs.archlinux.org/viewtopic.php?id=242492
    # echo /sys/devices/platform/*/hwmon/hwmon*
    sed -i "s|name='platform',|name='hwmon',|g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"
    sed -i "s|pt.name == 'platform'|pt.name == 'platform' or pt.name == 'hwmon'|g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    # CPU
    CPU_HWMON_DEVICE=$(echo /sys/devices/platform/*/hwmon/hwmon* | head -n1 | awk -F"/" '{print $NF}')
    [[ -f "/sys/class/hwmon/${CPU_HWMON_DEVICE}/name" ]] && \
        CPU_HWMON_NAME=$(< "/sys/class/hwmon/${CPU_HWMON_DEVICE}/name")

    [[ -n "${CPU_HWMON_NAME}" ]] && \
        sed -i "s|coretemp.0/hwmon/hwmon5|${CPU_HWMON_NAME}|g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    # GPU
    GPU_HWMON=$(grep -d skip . /sys/class/hwmon/hwmon[0-9]/* 2>/dev/null | grep 'GPU' | grep 'temp' | head -n1)
    if [[ -n "${GPU_HWMON}" ]]; then
        GPU_HWMON_DEVICE=$( (grep -Eo 'hwmon[0-9]+' | grep -Eo '[0-9]+') <<<"${GPU_HWMON}")
        GPU_HWMON_SENSOR=$( (grep -Eo 'temp[0-9]+' | grep -Eo '[0-9]+') <<<"${GPU_HWMON}")
    fi

    if [[ -n "${GPU_HWMON_DEVICE}" && -n "${GPU_HWMON_SENSOR}" ]]; then
        GPU_HWMON_ARG="${GPU_HWMON_DEVICE} temp ${GPU_HWMON_SENSOR}"
        sed -i -e "s|name='nvidia',|name='hwmon',|" \
            -e "s|arg='temp',|arg='${GPU_HWMON_ARG}',|" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"
    fi

    ## Battery
    # upower -i $(upower -e | grep BAT)
    # acpi -V
    # acpi -b
    BATTERY_DEVICE=$(upower -e | grep -Eo 'BAT[0-9]+' | sort | head -n1)
    [[ -n "${BATTERY_DEVICE}" ]] && \
        sed -i "s/BAT1/${BATTERY_DEVICE}/g" "$HOME/.config/conky/hybrid/lua/hybrid-rings.lua"

    sed -i -e 's/own_window_transparent.*/own_window_transparent = true,/' \
        -e 's/update_interval.*/update_interval = 3.0,/' \
        -e 's/minimum_width.*/minimum_width = 550,/' \
        -e 's/font NotoSans/font Sarasa Term SC/g' \
        -e 's/time %A %d %b %Y/time %Y年%b%-d日 %A 第%W周/g' "$HOME/.config/conky/hybrid/hybrid.conf"

    [[ -n "${NETWORK_INTERFACE_DEFAULT}" ]] && \
        sed -i "s/enp7s0f1/${NETWORK_INTERFACE_DEFAULT}/g" "$HOME/.config/conky/hybrid/hybrid.conf"
fi

# wttr.in weather
# Conky Objects: http://conky.sourceforge.net/variables.html
tee "$HOME/.config/conky/hybrid/weather.conf" >/dev/null <<-'EOF'
conky.config = {
    background = false,
    use_xft = true,
    xftalpha = 0.8,
    update_interval = 60.0,
    total_run_times = 0,
    temperature_unit = 'celsius',

    own_window_class = 'Conky',
    own_window = true,
    own_window_type = 'normal',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 0,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    alignment = 'bottom_left',

    double_buffer = true,
    minimum_width = 1000,
    minimum_height = 500,

    draw_shades = false,
    draw_outline = false,
    draw_borders = false,
    draw_graph_borders = false,

    stippled_borders = 8,
    border_inner_margin = 4,
    border_width = 1,

    gap_x = 10,
    gap_y = 10,

    no_buffers = true,
    uppercase = false,
    
    cpu_avg_samples = 12,
    net_avg_samples = 2,
    
    use_spacer = 'none',
    text_buffer_size = 256,
    override_utf8_locale = true,

    default_color = 'a8a8a8',
    default_shade_color = 'darkgray',
    default_outline_color = 'darkgray',

    color2 = '3458eb'
};

conky.text = [[
${texeci 3600 $HOME/.dotfiles/snippets/weather_wttr.sh >/dev/null}
${image $HOME/.config/conky/hybrid/weather.png -p 0,0 -n}
]]
EOF

tee "$HOME/.config/conky/hybrid/weather_mini.conf" >/dev/null <<-'EOF'
conky.config = {
    background = false,
    use_xft = true,
    xftalpha = 0.8,
    update_interval = 60.0,
    total_run_times = 0,
    temperature_unit = 'celsius',

    own_window_class = 'Conky',
    own_window = true,
    own_window_type = 'normal',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 0,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',

    alignment = 'bottom_left',

    double_buffer = true,
    minimum_width = 300,
    minimum_height = 450,

    draw_shades = false,
    draw_outline = false,
    draw_borders = false,
    draw_graph_borders = false,

    stippled_borders = 8,
    border_inner_margin = 4,
    border_width = 1,

    gap_x = 10,
    gap_y = 10,

    no_buffers = true,
    uppercase = false,
    
    cpu_avg_samples = 12,
    net_avg_samples = 2,
    
    use_spacer = 'none',
    text_buffer_size = 256,
    override_utf8_locale = true,

    default_color = 'a8a8a8',
    default_shade_color = 'darkgray',
    default_outline_color = 'darkgray',

    color2 = '3458eb'
};

conky.text = [[
${texeci 3600 $HOME/.dotfiles/snippets/weather_wttr.sh >/dev/null}
${image $HOME/.config/conky/hybrid/weather_mini.png -p 0,0 -n}
]]
EOF

# A Conky theme pack
# https://github.com/closebox73/Leonis
Git_Clone_Update_Branch "closebox73/Leonis" "$HOME/.conky/Leonis"
if [[ -d "$HOME/.conky/Leonis/Regulus" ]]; then
    cp -r "$HOME/.conky/Leonis/Regulus/" "$HOME/.conky/"

    sed -i 's|~/.config/conky/|~/.conky/|g' "$HOME/.conky/Regulus/Regulus.conf"
    [[ -n "${NETWORK_INTERFACE_DEFAULT}" ]] && \
        sed -i "s/wlp9s0/${NETWORK_INTERFACE_DEFAULT}/g" "$HOME/.conky/Regulus/Regulus.conf"

    # export OpenWeatherMap_Key="" && export OpenWeatherMap_CityID="" && OpenWeatherMap_LANG="zh_cn"
    [[ -n "$OpenWeatherMap_Key" ]] && \
        sed -i "s/api_key=.*/api_key=${OpenWeatherMap_Key}/" "$HOME/.conky/Regulus/scripts/weather.sh"

    [[ -n "$OpenWeatherMap_CityID" ]] && \
        sed -i "s/city_id=.*/city_id=${OpenWeatherMap_CityID}/" "$HOME/.conky/Regulus/scripts/weather.sh"

    [[ -n "$OpenWeatherMap_LANG" ]] && \
        sed -i "s/lang=en/lang=${OpenWeatherMap_LANG}/" "$HOME/.conky/Regulus/scripts/weather.sh"
fi

# Conky Showcase
# https://forum.manjaro.org/tag/conky
# Manjaro logo: /usr/share/icons/logo_green.png

# Minimalis
# https://www.gnome-look.org/p/1112273/

# Sci-Fi HUD
# https://www.gnome-look.org/p/1197920/

## Custom Conky Themes for blackPanther OS
## https://github.com/blackPantherOS/Conky-themes
# Git_Clone_Update_Branch "blackPantherOS/Conky-themes" "$HOME/.conky/blackPantherOS"

## Aureola: A conky collection of great conky's following the lua syntax
## https://github.com/erikdubois/Aureola
# git clone --depth 1 https://github.com/erikdubois/Aureola "$HOME/conky-theme-aureola"
# cd "$HOME/conky-theme-aureola" && ./get-aureola-from-github-to-local-drive-v1.sh
# cd "$HOME/.aureola/lazuli" && ./install-conky.sh

## conky-ubuntu
## https://fanqxu.com/2019/04/03/conky-ubuntu/
## echo "$HOME/.config/conky/startconky.sh &" >> "$HOME/.xprofile"
# git clone https://github.com/FanqXu/conkyrc "$HOME/.conky/conky-ubuntu" && \
#     cd "$HOME/.conky/conky-ubuntu" && \
#     ./install.sh

## Harmattan
## https://github.com/zagortenay333/Harmattan
# git clone --depth=1 https://github.com/zagortenay333/Harmattan "$HOME/Harmattan" && \
#     cp -rf "$HOME/Harmattan/.harmattan-assets" "$HOME"
## cd Harmattan && ./preview
## set conky theme
# cp -f "$HOME/Harmattan/.harmattan-themes/Numix/God-Mode/normal-mode/.conkyrc" "$HOME"
## postions
# sed -i 's/--alignment="middle_middle",/alignment="top_right",/' "$HOME/.conkyrc" && \
#     sed -i 's/gap_x.*/gap_x=10,/' "$HOME/.conkyrc" && \
#     sed -i 's/gap_y.*/gap_y=100,/' "$HOME/.conkyrc"
## settings
# get_network_interface_default
# colorEchoN "${ORANGE}[OpenWeatherMap Api Key? "
# read -r OpenWeatherMap_Key
# colorEchoN "${ORANGE}OpenWeatherMap City ID? "
# read -r OpenWeatherMap_CityID
# colorEchoN "${ORANGE}OpenWeatherMap LANG?[${CYAN}zh_cn${ORANGE}]: "
# read -r OpenWeatherMap_LANG
# [[ -z "$OpenWeatherMap_LANG" ]] && OpenWeatherMap_LANG="zh_cn"
# sed -i 's/template6=\"\"/template6=\"${OpenWeatherMap_Key}\"/g' "$HOME/.conkyrc" && \
#     sed -i 's/template7=\"\"/template7=\"${OpenWeatherMap_CityID}\"/g' "$HOME/.conkyrc" && \
#     sed -i 's/ppp0/${NETWORK_INTERFACE_DEFAULT}/g' "$HOME/.conkyrc"
## star script
# cat > "$HOME/.conky/start.sh" <<-EOF
# #!/usr/bin/env bash
# killall conky
# apiKey=${OpenWeatherMap_Key}
# cityId=${OpenWeatherMap_CityID}
# unit=metric
# lang=${OpenWeatherMap_LANG}
# curl -fsSL "api.openweathermap.org/data/2.5/forecast?id=\${cityId}&cnt=5&units=\${unit}&appid=\${apiKey}&lang=\${lang}" -o "$HOME/.cache/harmattan-conky/forecast.json"
# curl -fsSL "api.openweathermap.org/data/2.5/weather?id=\${cityId}&cnt=5&units=\${unit}&appid=\${apiKey}&lang=\${lang}" -o "$HOME/.cache/harmattan-conky/weather.json"
# sleep 2
# conky 2>/dev/null &
# EOF

# auto start conky
cat > "$HOME/.conky/autostart.sh" <<-'EOF'
#!/usr/bin/env bash

killall conky conky

# time (in s) for the DE to start; use ~20 for Gnome or KDE, less for Xfce/LXDE etc
sleep 10

# pre exec script for weather from wttr.in
source "$HOME/.dotfiles/snippets/weather_wttr.sh"

## the main conky
## /usr/share/conkycolors/bin/conkyStart

# conky -c "$HOME/.conkycolors/conkyrc" --daemonize --quiet
conky -c "$HOME/.config/conky/hybrid/hybrid.conf" --daemonize --quiet

# time for the main conky to start
# needed so that the smaller ones draw above not below 
# probably can be lower, but we still have to wait 5s for the rings to avoid segfaults
sleep 5

# if [[ -s "$HOME/.config/conky/hybrid/weather.png" ]]; then
#     conky -c "$HOME/.config/conky/hybrid/weather.conf" --daemonize --quiet
# fi

if [[ -s "$HOME/.config/conky/hybrid/weather_mini.png" ]]; then
    conky -c "$HOME/.config/conky/hybrid/weather_mini.conf" --daemonize --quiet
fi

# conky -c "$HOME/.conky/conky-weather/conkyrc_mini" --daemonize --quiet
EOF

chmod +x "$HOME/.conky/autostart.sh"

if ! grep -q "autostart.sh" "$HOME/.xprofile" 2>/dev/null; then
    echo -e "\n# conky" >> "$HOME/.xprofile"
    echo "$HOME/.conky/autostart.sh >/dev/null 2>&1 & disown" >> "$HOME/.xprofile"
fi

cd "${CURRENT_DIR}" || exit
