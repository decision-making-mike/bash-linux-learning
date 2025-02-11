#!/bin/bash

# Snow removal simulation. Arrows move the cursor, CTRL-C quits, and these are the only controls to be used. If the simulation quits by itself, the user will probably need to do "stty 'echo'" to start to see again anything they will type. The simulation is not to be run, but to show my Bash skills. The code was not tested in any other way than by manually playing the simulation. TODOs left for the time I will find it worth to handle them. Maybe never, as I wish to move on with my skills. I would like to be able to make such a snow removal simulation for VR instead of a terminal someday.
# TODO I would like to show the number of snows on the same position, or at least make the removal of more snows harder than of less. But as we currently iterate through all the snows at every cursor movement, I am roughly estimating it should not make the code more efficient.

# For testing and debugging.
set -euo 'pipefail'

# This has been employed only to solve the problem of characters being echoed back when a key is accidentally pressed too fast.
stty '-echo'
# The following is commented out since that "stty echo" apparently would not work when it was "read -n" that received the signal. I have no idea why. The only information about it I could find is https://stackoverflow.com/questions/67334588/trap-stty-echo-int-has-no-effect-when-used-with-read-s#comment119018118_67334588.
#trap 'status="$?" ; stty "echo" ; exit "$status"' 'int'

# TODO "min_site_y", and, for consistency, "min_site_x", "max_site_y" and "max_site_x" , had been designed to facilitate displaying a status in a separate line. But then I thought that I would rather avoid making the cursor jump all over the terminal. Should the simulation be rewritten in other technology someday, it should certainly be considered to implement a status in some way.
min_site_x=1
max_site_x="$( tput 'cols' )"
min_site_y=1
max_site_y="$( tput 'lines' )"
ground_tile=' '
street_tile='+'
snow_tile='@'
snows_count=1000
cursor_x="$min_site_x"
cursor_y="$min_site_y"
site_width="$(( max_site_x - min_site_x + 1 ))"
site_height="$(( max_site_y - min_site_y + 1 ))"
cursor_x_direction=0
cursor_y_direction=0
snows_xs_ys=()
sorted_snows_xs_ys=()
snows_xs=()
snows_ys=()
street_x_min="$(( site_width / 2 - 2 ))"
street_x_max="$(( site_width / 2 + 2 ))"

# Snow positions generation
# TODO Note that should some "RANDOM"s be the same, it shall cause the number of snows that will eventually be visible to be less than "snows_count". Should the simulation be improved someday, I believe it will be worth to try to align "snows_count" with what is visible, either by making all the snows have separate positions, or by indicating in some way that a certain position is occupied by more than one snow.
for (( k = 0 ; k < snows_count ; ++k ))
do
    snows_xs+=( "$(( RANDOM % site_width + min_site_x ))" )
    snows_ys+=( "$(( RANDOM % site_height + min_site_y ))" )
done

# Old code not removed in case I need it.
# According to "info sort", the "-n" option's description, the number "begins each line and consists of optional blanks, an optional '-' sign, and zero or more digits possibly separated by thousands separators, optionally followed by a decimal-point character and zero or more digits". From that I infer that a space makes "sort" treat the first character before the space, if there is any, as the last character of the number. And that should be why sorting pairs of numbers of the form "<number> <number>" seems to be equivalent to sorting only by the first number even without having any keys specified.
#readarray -t sorted_snows_xs_ys <<< "$(
#    printf '%s\n' "${snows_xs_ys[@]}" \
#        | sort -n
#)"

clear

# Street displaying
for (( x = "$street_x_min" ; x <= "$street_x_max" ; ++x ))
do
    for (( y = "$min_site_y" ; y <= "$max_site_y" ; ++y ))
    do
        echo -en "\e[${y};${x}H"
        echo -n "$street_tile"
    done
done

# Snow displaying
for (( k = 0 ; k < snows_count ; ++k ))
do
    echo -en "\e[${snows_ys[k]};${snows_xs[k]}H"
    echo -n "$snow_tile"
done

# Initial cursor position setting
echo -en "\e[${min_site_y};${min_site_x}H"

# Main loop
while true
do
    read -n 1 c
    case "$c" in
        $'\e')
            # We skip "[".
            read -n 1
            read -n 1 cc
            # We can say that the zeroing of both directions below looks like we were saying to the cursor, "stop". Then, in the following "case", we would say to it, "think which direction you have been directed to go, and assign accordingly".
            cursor_x_direction=0
            cursor_y_direction=0
            # The below "echo"s makes no difference on my machine in case either coordinate of the cursor is 1. I guess it is the terminal which will not move the cursor beyond its boundaries. I was initially checking here if we are beyond the boundaries of the terminal, but for said reason and because the direction of the cursor will stay the same anyway, we can omit that checking.
            case "$cc" in
                'A') cursor_y_direction=-1 ;;
                'B') cursor_y_direction=1 ;;
                'C') cursor_x_direction=1 ;;
                'D') cursor_x_direction=-1 ;;
            esac
            # TODO Try to prevent occasional collision of the cursor and the snow currently being removed, thus blinking of the latter, by moving the change of cursor's position to some later time. By the way, the cursor seems to move onto the next position for some reason, causing itself to blink, but I don't know if this is related.
            echo -ne "\e[1${cc}"
            ;;
    esac

    if [[ "$(( cursor_x + cursor_x_direction ))" -ne "$(( min_site_x - 1 ))" ]] \
        && [[ "$(( cursor_x + cursor_x_direction ))" -ne "$(( max_site_x + 1 ))" ]]
    then (( cursor_x += cursor_x_direction ))
    fi

    if [[ "$(( cursor_y + cursor_y_direction ))" -ne "$(( min_site_y - 1 ))" ]] \
        && [[ "$(( cursor_y + cursor_y_direction ))" -ne "$(( max_site_y + 1 ))" ]]
    then (( cursor_y += cursor_y_direction ))
    fi

    # Snow removal handling
    # TODO Loop inefficiency. It might especially be visible for big numbers of snows, e.g. several thousands. At first glance, it seems riddiculous we process "x * y" snows when we seem to need to process at most "max(x, y)" of them (that is, the whole line or column, whichever can hold more snows), and probably less in many cases, given we expect not to move all the line or column of snows in every move of the cursor (that is, in many cases we start from the middle of the line or column). On the other hand, how to avoid it if we do not know the order of snows? It seems to be easier if Bash would support two-dimensional arrays. In such a case we would just check the elements with the indexes related to the field right before the cursor.
    for (( k = 0 ; k < snows_count ; ++k ))
    do
        # We check here both whether the position of the cursor equals the position of the snow, and whether the snow is not going to be outside the terminal. If we omitted checking the latter, then first, the position of the snow would be outside the terminal, but the terminal would display it at its old position, and second, the terminal would also display the cursor within its boundaries. In result, we would lose control over the snow. The cursor could move by itself, but could not anymore move the snow in any direction.
        if [[ "$cursor_x" -eq "${snows_xs[k]}" ]] \
            && [[ "$cursor_y" -eq "${snows_ys[k]}" ]] \
            && [[ "$(( snows_xs[k] + cursor_x_direction ))" -ne "$(( min_site_x - 1 ))" ]] \
            && [[ "$(( snows_xs[k] + cursor_x_direction ))" -ne "$(( max_site_x + 1 ))" ]] \
            && [[ "$(( snows_ys[k] + cursor_y_direction ))" -ne "$(( min_site_y - 1 ))" ]] \
            && [[ "$(( snows_ys[k] + cursor_y_direction ))" -ne "$(( max_site_y + 1 ))" ]]
        then
            echo -ne '\e[s'

            if [[ "$cursor_x" -ge "$street_x_min" ]] \
                && [[ "$cursor_x" -le "$street_x_max" ]]
            then echo -n "$street_tile"
            else echo -n "$ground_tile"
            fi

            (( snows_xs[k] += cursor_x_direction ))
            (( snows_ys[k] += cursor_y_direction ))

            echo -ne "\e[${snows_ys[k]};${snows_xs[k]}H"
            echo -n "$snow_tile"

            echo -ne '\e[u'

            # We cannot break here since more snows may have the same position. To remove them all, we need to check all the snows every cursor move.
        fi
    done
done

# Do not comment out if its above counterpart is not commented out.
stty 'echo'
