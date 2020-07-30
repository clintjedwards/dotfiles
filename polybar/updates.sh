#!/bin/sh

color_red="ff7675"
color_yellow="ffeaa7"
color_green="badc58"

if ! updates_arch=$(checkupdates 2> /dev/null | wc -l ); then
	    updates_arch=0
fi

if ! updates_aur=$(yay -Qum 2> /dev/null | wc -l); then
	# if ! updates_aur=$(cower -u 2> /dev/null | wc -l); then
	# if ! updates_aur=$(trizen -Su --aur --quiet | wc -l); then
	# if ! updates_aur=$(pikaur -Qua 2> /dev/null | wc -l); then
	# if ! updates_aur=$(rua upgrade --printonly 2> /dev/null | wc -l); then
	    updates_aur=0
fi

updates=$(("$updates_arch" + "$updates_aur"))

if [ "$updates" -gt 10 ]; then
	    echo "%{u#$color_red} %{F#555}Updates%{F-} $updates %{+u}"
    elif [ "$updates" -gt 5 ]; then
    	echo "%{u#$color_yellow} %{F#555}Updates%{F-} $updates %{+u}"
    else
	        echo ""
fi
