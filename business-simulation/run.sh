#!/bin/bash

# Help functionality. Many command-line applications include functionality for showing help, like the "--help" parameter, or for showing various runtime information, like the "--verbose" parameter. I intentionally do not include such functionality within this script, neither through parameters, nor through internal commands, that is, at the level of the "borrow", "rent" and other commands. The reason is, I believe that the simplicity of a Bash script makes it significantly easier to debug. Such functionality should require, as far as I can imagine, duplication of command names, and that would introduce complexity.

# Notable commands. "CTRL-D" ends the day. The same does "ENTER", irrespectively whether there will or will not be any command invoked after the "ENTER". "CTRL-C" exits the simulation.

# Number of functions and commands used. The more functions and commands used, the harder to follow the code.

# Global variables. If a variable is global, it makes it easier to follow it than when it's local.

# Not indented "printf"'s "FORMAT" argument lines. As one might see, the lines of the "FORMAT" argument of every "printf" are not indented at all. It is due to the fact which I observe that if the "FORMAT" argument of a "printf" constist of multiple lines, and beginning from the second one they were indented, then Bash would, or at least I am taking a guess that it would, based on what I see, interpret the lines as separate arguments to the "printf". I don't like this formatting inconsistency compared to the rest of the lines of the script. I plan to change it if I happen to find a way.

# Not indented "echo"'s argument lines. Per Bash's manual part on "echo", it separates its arguments with spaces. So, to be able to split a long argument into separate lines, and not creating separate arguments in the same time, I must leave the lines not indented. As in the case of "printf" (see), I plan to change it someday.

# Thousands separation. I wanted to increase money amounts readability by visually separating thousands. So, I have replaced "echo" with "printf". "printf" calls the separator (separators?) that it is to use "thousands' grouping characters". No idea why there is plural used, but this functionality seems to do what I want. See "man bash" (search for "printf"), then "man 1 printf", then "man 3 printf", and optionally https://pubs.opengroup.org/onlinepubs/9799919799/functions/printf.html. If you want to change how thousands are separated, you need to, if I understood correctly, change the "LC_NUMERIC" environment variable.

# The maximum number of vehicles per manager. The maximum number of vehicles per manager is 50 because I assume https://www.gov.uk/become-transport-manager as a requirement. This in turn was implemented because I needed some upper limit for manager effectiveness so that just employing more managers, without renting new cars, not yield higher income ad infinitum.

# The storage of simulation parameters. Currently, simulation parameters are stored as plain old Bash variables in the same file as the rest of the program. One might happen to find the number of them big enough to consider using an array for storing them, or at least a separate file. This might be amplified by the fact that I predict more parameters to be introduced, that is, more than one or two. But, I am not sure which of those two proposals is going to introduce more complexity than just keeping storing the parameters like they are now. By "complexity" I understand any complexity related to the program, for example the complexity of maintenance of the parameters, or of keeping the code secure. Due to this unsureness, for now I change nothing.

save_file_path="$1"
if [[ -z "$save_file_path" ]]
then
    echo >&2 "Error, no save file path provided, exiting"
    exit 1
fi

# Variables
day=1
money=0
loans=0
savings=0
driver_count=0
manager_count=0
car_count=0
last_day_result=0

# Constants
car_rent_charge=1
salary=10
income=25
maximum_single_manager_vehicle_count=50
income_tax_rate_numerator=1
income_tax_rate_denominator=10
interest_rate_numerator=1
interest_rate_denominator=100
savings_interest_rate_numerator=1
savings_interest_rate_denominator=100

do_business () {
    prompt='(new day) > '

    money_change=0
    loans_change=0
    savings_change=0
    driver_count_change=0
    manager_count_change=0
    car_count_change=0

    while read -a c -p "$prompt"
    do
        if [[ -z "$c" ]]
        then break
        fi

        case "${c[0]}" in
            borrow)
                (( money_change += "${c[1]}" ))
                (( loans_change += "${c[1]}" ))
                ;;

            repay)
                (( money_change -= "${c[1]}" ))
                (( loans_change -= "${c[1]}" ))
                ;;

            save)
                (( money_change -= "${c[1]}" ))
                (( savings_change += "${c[1]}" ))
                ;;

            desave)
                (( money_change += "${c[1]}" ))
                (( savings_change -= "${c[1]}" ))
                ;;

            employ)
                case "${c[1]}" in
                    drivers) (( driver_count_change += "${c[2]}" )) ;;
                    managers) (( manager_count_change += "${c[2]}" )) ;;
                esac
                ;;

            dismiss)
                case "${c[1]}" in
                    drivers) (( driver_count_change -= "${c[2]}" )) ;;
                    managers) (( manager_count_change -= "${c[2]}" )) ;;
                esac
                ;;

            rent) (( car_count_change += "${c[1]}" )) ;;

            end)
                case "${c[1]}" in
                    renting) (( car_count_change -= "${c[2]}" )) ;;
                esac
                ;;

            show)
                case "${c[1]}" in
                    changes)
                        printf \
"\tMoney change %'i\n"\
"\tLoans change %'i\n"\
"\tSavings change %'i\n"\
"\tDriver count change %'i\n"\
"\tManager count change %'i\n"\
"\tCar count change %'i\n"\
                            "$money_change" \
                            "$loans_change" \
                            "$savings_change" \
                            "$driver_count_change" \
                            "$manager_count_change" \
                            "$car_count_change"
                        read
                        ;;

                    yesterday)
                        printf \
"\tLast day result %'i\n"\
                            "$last_day_result"
                        read
                        ;;

                    loans)
                        printf \
"\tLoans %'i\n"\
"\tLoan interest rate %'i/%'i\n"\
                            "$loans"\
                            "$interest_rate_numerator"\
                            "$interest_rate_denominator"
                        read
                        ;;

                    savings)
                        printf \
"\tSavings %'i\n"\
"\tSavings interest rate %'i/%'i\n"\
                            "$savings"\
                            "$savings_interest_rate_numerator"\
                            "$savings_interest_rate_denominator"
                        read
                        ;;

                    cars)
                        printf \
"\tCar count %'i\n"\
"\tCar rent charge %'i\n"\
                            "$car_count"\
                            "$car_rent_charge"
                        read
                        ;;

                    employees)
                        printf \
"\tDriver count %'i\n"\
"\tManager count %'i\n"\
"\tSalary %'i\n"\
                            "$driver_count"\
                            "$manager_count"\
                            "$salary"
                        read
                        ;;
                esac
                ;;
        esac
        # The screen is cleared from line 5 because the first 4 lines contain the status of the business.
        tput 'cup' 4 0
        tput 'ed'

        if [[ "$money_change" -ne 0 ]] \
            || [[ "$loans_change" -ne 0 ]] \
            || [[ "$savings_change" -ne 0 ]] \
            || [[ "$driver_count_change" -ne 0 ]] \
            || [[ "$manager_count_change" -ne 0 ]] \
            || [[ "$car_count_change" -ne 0 ]]
        then prompt='(changes) > '
        fi
    done

    (( money += "$money_change" ))

    if [[ "$(( loans + loans_change ))" -lt 0 ]]
    then loans=0
    else (( loans += loans_change ))
    fi

    if [[ "$(( savings + savings_change ))" -lt 0 ]]
    then savings=0
    else (( savings += savings_change ))
    fi

    if [[ "$(( driver_count + driver_count_change ))" -lt 0 ]]
    then driver_count=0
    else (( driver_count += driver_count_change ))
    fi

    if [[ "$(( manager_count + manager_count_change ))" -lt 0 ]]
    then manager_count=0
    else (( manager_count += manager_count_change ))
    fi

    if [[ "$(( car_count + car_count_change ))" -lt 0 ]]
    then car_count=0
    else (( car_count += car_count_change ))
    fi
}

min () {
    echo "$(( "$1" <= "$2" ? "$1" : "$2" ))"
}

get_total_net_income () {
    used_car_count="$(min "$driver_count" "$car_count")"
    savings_interest="$(( "$savings" * "$savings_interest_rate_numerator" / "$savings_interest_rate_denominator" ))"
    total_gross_income="$savings_interest"
    if [[ "$manager_count" -gt 0 ]]
    then
        # I'm adding 1 to the maximum single manager vehicle count since this count is the maximum one that should make the manager yield at least minimal result. If the 1 weren't added, the manager would yield a result equal to zero.
        fleet_management_efficiency_rate_numerator="$(( "$maximum_single_manager_vehicle_count" + 1 - "$car_count" / "$manager_count" ))"
        fleet_management_efficiency_rate_denominator="$(( "$maximum_single_manager_vehicle_count" + 1 ))"
        (( total_gross_income += "$fleet_management_efficiency_rate_numerator" * "$income" * "$used_car_count" / "$fleet_management_efficiency_rate_denominator" ))
    fi
    total_income_tax="$(( "$total_gross_income" * "$income_tax_rate_numerator" / "$income_tax_rate_denominator" ))"
    total_net_income="$(( "$total_gross_income" - "$total_income_tax" ))"
    echo "$total_gross_income"
}

handle_day () {
    total_net_income="$(get_total_net_income)"
    interest="$(( "$loans" * "$interest_rate_numerator" / "$interest_rate_denominator" ))"
    total_car_rent_charge="$(( "$car_count" * "$car_rent_charge" ))"
    total_salary="$(( "$salary" * ("$driver_count" + "$manager_count") ))"
    total_expenses="$(( "$total_car_rent_charge" + "$total_salary" ))"
    day_result="$(( "$total_net_income" - "$total_expenses" ))"

    if [[ "$(( "$day_result" + "$money" ))" -lt 0 ]]
    then
        # Notice that we don't add the day result to money here, but only if the check fails. It prevents to save the current, unfortunate state of the business. This in turn gives the user a small chance to take remedial action in the first day, by starting the simulation anew with the file with the current save.
        printf "Money %'i, day result %'i, balance is going to be negative, business closed" "$money" "$day_result"
        exit 0
    else
        (( money += "$day_result" ))
        last_day_result="$day_result"
    fi

    (( ++day ))
}

load () {
    source "$save_file_path"
}

save () {
    echo -e \
        > "$save_file_path" \
"day=$day\n"\
"money=$money\n"\
"loans=$loans\n"\
"savings=$savings\n"\
"driver_count=$driver_count\n"\
"manager_count=$manager_count\n"\
"car_count=$car_count\n"\
"last_day_result=$last_day_result"
}

run () {
    load
    while true
    do
        clear
        printf \
"Day %'i | Money %'i\n"\
"Loans %'i | Savings %'i\n"\
"Driver count %'i | Manager count %'i\n"\
"Car count %'i | Used car count %'i\n"\
            "$day"\
            "$money"\
            "$loans"\
            "$savings"\
            "$driver_count"\
            "$manager_count"\
            "$car_count"\
            "$(min "$car_count" "$driver_count")"
        do_business
        handle_day
        save
    done
}

run
