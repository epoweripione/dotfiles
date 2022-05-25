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

# https://github.com/chubin/wttr.in/blob/master/lib/constants.py
declare -A WWO_CODE=(
    ["113"]="Sunny"
    ["116"]="PartlyCloudy"
    ["119"]="Cloudy"
    ["122"]="VeryCloudy"
    ["143"]="Fog"
    ["176"]="LightShowers"
    ["179"]="LightSleetShowers"
    ["182"]="LightSleet"
    ["185"]="LightSleet"
    ["200"]="ThunderyShowers"
    ["227"]="LightSnow"
    ["230"]="HeavySnow"
    ["248"]="Fog"
    ["260"]="Fog"
    ["263"]="LightShowers"
    ["266"]="LightRain"
    ["281"]="LightSleet"
    ["284"]="LightSleet"
    ["293"]="LightRain"
    ["296"]="LightRain"
    ["299"]="HeavyShowers"
    ["302"]="HeavyRain"
    ["305"]="HeavyShowers"
    ["308"]="HeavyRain"
    ["311"]="LightSleet"
    ["314"]="LightSleet"
    ["317"]="LightSleet"
    ["320"]="LightSnow"
    ["323"]="LightSnowShowers"
    ["326"]="LightSnowShowers"
    ["329"]="HeavySnow"
    ["332"]="HeavySnow"
    ["335"]="HeavySnowShowers"
    ["338"]="HeavySnow"
    ["350"]="LightSleet"
    ["353"]="LightShowers"
    ["356"]="HeavyShowers"
    ["359"]="HeavyRain"
    ["362"]="LightSleetShowers"
    ["365"]="LightSleetShowers"
    ["368"]="LightSnowShowers"
    ["371"]="HeavySnowShowers"
    ["374"]="LightSleetShowers"
    ["377"]="LightSleet"
    ["386"]="ThunderyShowers"
    ["389"]="ThunderyHeavyRain"
    ["392"]="ThunderySnowShowers"
    ["395"]="HeavySnowShowers"
)

declare -A WEATHER_SYMBOL=(
	["Unknown"]="✨"
	["Cloudy"]="☁️"
	["Fog"]="🌫"
	["HeavyRain"]="🌧"
	["HeavyShowers"]="🌧"
	["HeavySnow"]="❄️"
	["HeavySnowShowers"]="❄️"
	["LightRain"]="🌦"
	["LightShowers"]="🌦"
	["LightSleet"]="🌧"
	["LightSleetShowers"]="🌧"
	["LightSnow"]="🌨"
	["LightSnowShowers"]="🌨"
	["PartlyCloudy"]="⛅️"
	["Sunny"]="☀️"
	["ThunderyHeavyRain"]="🌩"
	["ThunderyShowers"]="⛈"
	["ThunderySnowShowers"]="⛈"
	["VeryCloudy"]="☁️"
)

WIND_DIRECTION=("↓" "↙" "←" "↖" "↑" "↗" "→" "↘")
DATE_WEEKDAY=("星期日" "星期一" "星期二" "星期三" "星期四" "星期五" "星期六")

WEATHER_CITY=${1:-""}
WEATHER_PNG=${2:-"$HOME/.config/conky/hybrid/weather.png"}
WEATHER_MINI_PNG=${3:-"$HOME/.config/conky/hybrid/weather_mini.png"}

WEATHER_JSON="${WORKDIR}/weather.json"
WEATHER_HTML="${WORKDIR}/weather_wttr.html"
WEATHER_HTML_PNG="${WORKDIR}/weather_wttr.png"

colorEcho "${BLUE}Getting weather from ${FUCHSIA}wttr.in${BLUE}..."
curl -fsL --connect-timeout 5 --max-time 15 \
        --noproxy '*' -H "Accept-Language: zh-cn" --compressed \
        "wttr.in/.png" \
    | convert - -transparent black "${WEATHER_PNG}"

colorEcho "${BLUE}Getting ${FUCHSIA}weather ${ORANGE}JSON${BLUE} from ${FUCHSIA}wttr.in${BLUE}..."
curl -fsL --connect-timeout 5 --max-time 15 \
    --noproxy '*' -H "Accept-Language: zh-cn" --compressed \
    "wttr.in/?format=j1" \
    -o "${WEATHER_JSON}"

# curl -fsL --connect-timeout 5 --max-time 15 \
#         --noproxy '*' -H "Accept-Language: zh-cn" --compressed \
#         "wttr.in/_Qtp_lang=zh_cn.png" \
#     | convert - -transparent black "$HOME/.config/conky/hybrid/weather_mini.png"

[[ ! -s "${WEATHER_JSON}" ]] && exit 0

colorEcho "${BLUE}Parsing ${ORANGE}JSON${BLUE} to ${FUCHSIA}HTML${BLUE}..."
tee "${WEATHER_HTML}" >/dev/null <<-'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
	<head>
		<meta charset="utf-8" />
		<meta name="viewport" content="width=device-width,initial-scale=1" />
		<title>天气预报</title>
		<style type="text/css">
			body {
				background: black;
				color: #bbbbbb;
			}

			table {
				border-collapse: collapse;
				border: 1px dashed rgb(200, 200, 200);
				letter-spacing: 1px;
				font-size: 0.8rem;
			}

			td,
			th {
				border: 1px dashed rgb(190, 190, 190);
				padding: 2px 2px;
			}

			td {
				text-align: center;
			}

			.ef118 { color: #87ff00; }
			.ef220 { color: #ffd700; }
			.ef226 { color: #ffff00; }
			.weekday { color: #ab47bc; }
			.date { color: #42a5f5; }

			.colwidth { width: 90px; }
			.bordersolid { border: 1px solid rgb(200, 200, 200); }
			.fontbold { font-weight: bold; }
		</style>
	</head>
	<body>
		<table id="weather">
			<colgroup>
				<col class="colwidth" />
			</colgroup>
EOF

for ((i=0; i<3; i++)); do
    V_DATE=$(jq -r ".weather[$i] | .date" "${WEATHER_JSON}")
    V_WEEKDAY=$(date --date="${V_DATE}" +%w)

    WEATHER_DATE=$(cut -d"-" -f2- <<<"${V_DATE}")
    WEATHER_WEEKDAY="${DATE_WEEKDAY[${V_WEEKDAY}]}"

    WEATHER_TEMP_MIN=$(jq -r ".weather[$i] | .mintempC" "${WEATHER_JSON}")
    WEATHER_TEMP_MAX=$(jq -r ".weather[$i] | .maxtempC" "${WEATHER_JSON}")

    tee -a "${WEATHER_HTML}" >/dev/null <<-EOF
			<tr class="bordersolid">
				<td colspan="3" class="fontbold">
					<span class="date">${WEATHER_DATE}</span>
                    <span class="weekday">${WEATHER_WEEKDAY}</span>
                    <span class="ef220">${WEATHER_TEMP_MIN}</span>(<span class="ef220">${WEATHER_TEMP_MAX}</span>)°C
				</td>
			</tr>
EOF
    # 0000 0300 0600 0900 1200 1500 1800 2100
    WEATHER_CNT=0
    WEATHER_ICON=()
    WEATHER_TEMP=()
    WEATHER_TEMP_FEEL=()
    WEATHER_DESC=()
    WEATHER_WIND_DIRECTION=()
    WEATHER_WIND_SPEED=()
    WEATHER_WIND_GUSTSPEED=()
    WEATHER_VISIBILITY=()
    WEATHER_RAIN_MM=()
    WEATHER_RAIN_CHANCE=()
    for j in 2 4 6; do
        WEATHER_CNT=$((WEATHER_CNT + 1))

        V_CODE=$(jq -r ".weather[$i] | .hourly[$j] | .weatherCode" "${WEATHER_JSON}")
        WEATHER_ICON+=("${WEATHER_SYMBOL[${WWO_CODE["${V_CODE}"]}]}")

        V_TEMP=$(jq -r ".weather[$i] | .hourly[$j] | .tempC" "${WEATHER_JSON}")
        V_TEMP_FEEL=$(jq -r ".weather[$i] | .hourly[$j] | .FeelsLikeC" "${WEATHER_JSON}")
        WEATHER_TEMP+=("${V_TEMP}")
        WEATHER_TEMP_FEEL+=("${V_TEMP_FEEL}")

        V_DESC=$(jq -r ".weather[$i] | .hourly[$j] | .lang_zh[0] | .value" "${WEATHER_JSON}")
        WEATHER_DESC+=("${V_DESC}")

        V_WIND_DEGREE=$(jq -r ".weather[$i] | .hourly[$j] | .winddirDegree" "${WEATHER_JSON}")
        V_WIND_DIRECTION=$(echo "(((${V_WIND_DEGREE}+22.5)%360)/45.0)" | bc)
        V_WIND_SPEED=$(jq -r ".weather[$i] | .hourly[$j] | .windspeedKmph" "${WEATHER_JSON}")
        V_WIND_GUSTSPEED=$(jq -r ".weather[$i] | .hourly[$j] | .WindGustKmph" "${WEATHER_JSON}")
        WEATHER_WIND_DIRECTION+=("${WIND_DIRECTION[${V_WIND_DIRECTION}]}")
        WEATHER_WIND_SPEED+=("${V_WIND_SPEED}")
        WEATHER_WIND_GUSTSPEED+=("${V_WIND_GUSTSPEED}")

        V_VISIBILITY=$(jq -r ".weather[$i] | .hourly[$j] | .visibility" "${WEATHER_JSON}")
        WEATHER_VISIBILITY+=("${V_VISIBILITY}")

        V_RAIN_MM=$(jq -r ".weather[$i] | .hourly[$j] | .precipMM" "${WEATHER_JSON}")
        V_RAIN_CHANCE=$(jq -r ".weather[$i] | .hourly[$j] | .chanceofrain" "${WEATHER_JSON}")
        WEATHER_RAIN_MM+=("${V_RAIN_MM}")
        WEATHER_RAIN_CHANCE+=("${V_RAIN_CHANCE}")
    done

    tee -a "${WEATHER_HTML}" >/dev/null <<-EOF
			<tr>
				<td>${WEATHER_ICON[0]}<span class="ef220">${WEATHER_TEMP[0]}</span>(<span class="ef220">${WEATHER_TEMP_FEEL[0]}</span>)</td>
				<td>${WEATHER_ICON[1]}<span class="ef220">${WEATHER_TEMP[1]}</span>(<span class="ef220">${WEATHER_TEMP_FEEL[1]}</span>)</td>
				<td>${WEATHER_ICON[2]}<span class="ef220">${WEATHER_TEMP[2]}</span>(<span class="ef220">${WEATHER_TEMP_FEEL[2]}</span>)</td>
			</tr>
			<tr>
				<td>${WEATHER_DESC[0]}</td>
				<td>${WEATHER_DESC[1]}</td>
				<td>${WEATHER_DESC[2]}</td>
			</tr>
			<tr>
				<td><span class="ef118">${WEATHER_WIND_DIRECTION[0]}</span><span class="ef226">${WEATHER_WIND_SPEED[0]}</span>-<span class="ef220">${WEATHER_WIND_GUSTSPEED[0]}</span>km/h</td>
				<td><span class="ef118">${WEATHER_WIND_DIRECTION[1]}</span><span class="ef226">${WEATHER_WIND_SPEED[1]}</span>-<span class="ef220">${WEATHER_WIND_GUSTSPEED[1]}</span>km/h</td>
				<td><span class="ef118">${WEATHER_WIND_DIRECTION[2]}</span><span class="ef226">${WEATHER_WIND_SPEED[2]}</span>-<span class="ef220">${WEATHER_WIND_GUSTSPEED[2]}</span>km/h</td>
			</tr>
			<tr>
				<td>${WEATHER_VISIBILITY[0]}km</td>
				<td>${WEATHER_VISIBILITY[1]}km</td>
				<td>${WEATHER_VISIBILITY[2]}km</td>
			</tr>
			<tr>
				<td>${WEATHER_RAIN_MM[0]}mm ${WEATHER_RAIN_CHANCE[0]}%</td>
				<td>${WEATHER_RAIN_MM[1]}mm ${WEATHER_RAIN_CHANCE[1]}%</td>
				<td>${WEATHER_RAIN_MM[2]}mm ${WEATHER_RAIN_CHANCE[2]}%</td>
			</tr>
EOF
done

tee -a "${WEATHER_HTML}" >/dev/null <<-'EOF'
		</table>
	</body>
</html>
EOF

colorEcho "${BLUE}Converting ${ORANGE} HTML ${BLUE}to${FUCHSIA} PNG${BLUE}..."
## Print output in table format
# echo -e '05-25\t05-26\t05-27\t\n🌦25(28)\t🌦29(34)\t🌦26(30)' | column -t -s $'\t' --table-empty-lines

## Save output to image file
## Imagemagick
# convert label:"$(ls)" result.png && display result.png
# ls | convert -fill red -background yellow label:@- result.png && display result.png
# convert label:@"scriptfile.sh" result.png && display result.png

## Render Unicode & emoji characters
## convert -list format | grep -i pango
# ls | convert pango:@- result.png && display result.png

## Convert html to image file
# convert pango:@"${WEATHER_HTML}" "${WEATHER_HTML_PNG}" && display "${WEATHER_HTML_PNG}"

## wkhtmltopdf
# yay --noconfirm --needed -S wkhtmltopdf
# wkhtmltopdf "${WEATHER_HTML}" "${WEATHER_HTML_PNG}" && display "${WEATHER_HTML_PNG}"

## Chorme headless
## https://developers.google.com/web/updates/2017/04/headless-chrome
# if [[ -x "/opt/google/chrome/google-chrome" ]]; then
#     /opt/google/chrome/google-chrome --headless --disable-gpu --window-size=300,500 \
#             --screenshot="${WEATHER_HTML_PNG}" "${WEATHER_HTML}" \
#         && convert -transparent black "${WEATHER_HTML_PNG}" "${WEATHER_MINI_PNG}"
# fi

# Puppeteer
cd "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}" && \
    node ./nodejs/puppeteer_screenshot.js \
            --url="file://${WEATHER_HTML}" \
            --element="#weather" \
            --output="${WEATHER_HTML_PNG}" \
    && convert -transparent black "${WEATHER_HTML_PNG}" "${WEATHER_MINI_PNG}"


cd "${CURRENT_DIR}" || exit
