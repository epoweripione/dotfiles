#!/usr/bin/env bash

# Terminal Colors
# https://gist.github.com/XVilka/8346728

for attr in 0 1 4 5 7 ; do
    echo "----------------------------------------------------------------"
    printf "ESC[%s;Foreground;Background - \n" $attr
    for fore in 30 31 32 33 34 35 36 37; do
        for back in 40 41 42 43 44 45 46 47; do
            printf '\033[%s;%s;%sm %02s;%02s  ' $attr $fore $back $fore $back
        done
    printf '\n'
    done
    printf '\033[0m'
done


# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# # The following shell script displays a lot of possible combination of the attributes 
# # (but not all, because it uses only one formatting attribute at a time).
# echo "Colors and formatting (16 colors)"
# #Background
# for clbg in {40..47} {100..107} 49 ; do
# 	#Foreground
# 	for clfg in {30..37} {90..97} 39 ; do
# 		#Formatting
# 		for attr in 0 1 2 4 5 7 ; do
# 			#Print the result
# 			echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
# 		done
# 		echo #Newline
# 	done
# done

# # The following script display the 256 colors available on some 
# # terminals and terminals emulators like XTerm and GNOME Terminal.
# color_support=$(tput colors)
# if [[ $color_support -eq 256 ]]; then
#     echo -e "\n\n256 colors"
#     for fgbg in 38 48 ; do # Foreground / Background
#         for color in {0..255} ; do # Colors
#             # Display the color
#             printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
#             # Display 6 colors per lines
#             if [ $((($color + 1) % 6)) == 4 ] ; then
#                 echo # New line
#             fi
#         done
#         echo # New line
#     done
# fi
