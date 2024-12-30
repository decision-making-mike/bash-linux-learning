#!/bin/bash

# Help functionality. Many command-line applications include functionality for showing help, like the "--help" parameter, or for showing various runtime information, like the "--verbose" parameter. I intentionally do not include such functionality within this script, neither through parameters, nor through internal commands, that is, at the level of the "borrow", "rent" and other commands. The reason is, I believe that the simplicity of a Bash script makes it significantly easier to debug. Such functionality should require, as far as I can imagine, duplication of command names, and that would introduce complexity.

# Notable commands. "CTRL-D" ends the day. The same does "ENTER", irrespectively whether there will or will not be any command invoked after the "ENTER". "CTRL-C" exits the simulation.

# Number of functions and commands used. The more functions and commands used, the harder to follow the code.

# Global variables. If a variable is global, it makes it easier to follow it than when it's local.

save_file_path="$1"
if [[ -z "$save_file_path" ]]
then
    echo >&2 "Error, no save file path provided, exiting"
    exit 1
fi

day=1
money=0
loans=0
savings=0
driver_count=0
manager_count=0
car_count=0
last_day_result=0
car_rent_charge=1
salary=10
income=25
# The maximum single manager vehicle count is 50 because I assume https://www.gov.uk/become-transport-manager as a requirement. This in turn was implemented because I needed some upper limit for manager effectiveness so that just employing more managers, without renting new cars, not yield higher income ad infinitum.
maximum_single_manager_vehicle_count=50
income_tax_rate_numerator=1
income_tax_rate_denominator=10
interest_rate_numerator=1
interest_rate_denominator=100
savings_interest_rate_numerator=1
savings_interest_rate_denominator=100

do_business () {
    read -a c -p '> '
    case "${c[0]}" in
        borrow)
            (( money += "${c[1]}" ))
            (( loans += "${c[1]}" ))
            ;;

        repay)
            if [[ "${c[1]}" -gt "$money" ]]
            then money=0
            else (( money -= "${c[1]}" ))
            fi

            if [[ "${c[1]}" -gt "$loans" ]]
            then loans=0
            else (( loans -= "${c[1]}" ))
            fi
            ;;

        save)
            if [[ "${c[1]}" -gt "$money" ]]
            then
                (( savings += "$money" ))
                money=0
            else
                (( money -= "${c[1]}" ))
                (( savings += "${c[1]}" ))
            fi
            ;;

        desave)
            if [[ "${c[1]}" -gt "$savings" ]]
            then
                (( money += "$savings" ))
                savings=0
            else
                (( savings -= "${c[1]}" ))
                (( money += "${c[1]}" ))
            fi
            ;;

        employ)
            case "${c[1]}" in
                drivers) (( driver_count += "${c[2]}" )) ;;
                managers) (( manager_count += "${c[2]}" )) ;;
            esac
            ;;

        dismiss)
            case "${c[1]}" in
                drivers)
                    if [[ "${c[2]}" -gt "$driver_count" ]]
                    then driver_count=0
                    else (( driver_count -= "${c[1]}" ))
                    fi
                    ;;

                managers)
                    if [[ "${c[2]}" -gt "$manager_count" ]]
                    then manager_count=0
                    else (( manager_count -= "${c[1]}" ))
                    fi
                    ;;
            esac
            ;;

        rent) (( car_count += "${c[1]}" )) ;;

        end)
            case "${c[1]}" in
                renting)
                    if [[ "${c[2]}" -gt "$car_count" ]]
                    then car_count=0
                    else (( car_count -= "${c[2]}" ))
                    fi
                    ;;
            esac
            ;;

        show)
            case "${c[1]}" in
                yesterday)
                    printf \
                        "\tLast day result %'i\n"\
                        "$last_day_result"
                    ;;
                loans)
                    printf \
"\tLoans %'i\n"\
"\tLoan interest rate %'i/%'i\n"\
                        "$loans"\
                        "$interest_rate_numerator"\
                        "$interest_rate_denominator"
                    ;;
                savings)
                    printf \
"\tSavings %'i\n"\
"\tSavings interest rate %'i/%'i\n"\
                        "$savings"\
                        "$savings_interest_rate_numerator"\
                        "$savings_interest_rate_denominator"
                    ;;
                cars)
                    printf \
"\tCar count %'i\n"\
"\tCar rent charge %'i\n"\
                        "$car_count"\
                        "$car_rent_charge"
                    ;;
                employees)
                    printf \
"\tDriver count %'i\n"\
"\tManager count %'i\n"\
"\tSalary %'i\n"\
                        "$driver_count"\
                        "$manager_count"\
                        "$salary"
                    ;;
            esac
            read
    esac
}

min () {
    echo "$(( "$1" <= "$2" ? "$1" : "$2" ))"
}

get_total_gross_income () {
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
    echo "$total_gross_income"
}

handle_day () {
    total_gross_income="$(get_total_gross_income)"
    total_income_tax="$(( "$total_gross_income" * "$income_tax_rate_numerator" / "$income_tax_rate_denominator" ))"
    total_net_income="$(( "$total_gross_income" - "$total_income_tax" ))"
    interest="$(( "$loans" * "$interest_rate_numerator" / "$interest_rate_denominator" ))"
    total_car_rent_charge="$(( "$car_count" * "$car_rent_charge" ))"
    total_salary="$(( "$salary" * ("$driver_count" + "$manager_count") ))"
    total_expenses="$(( "$total_car_rent_charge" + "$total_salary" ))"
    day_result="$(( "$total_net_income" - "$total_expenses" ))"

    if [[ "$(( "$day_result" + "$money" ))" -lt 0 ]]
    then
        # Notice that we don't add the day result to money here, but only if the check fails. It prevents to save the current, unfortunate state of the business. This in turn gives the user a small chance to take remedial action in the first day, by starting the simulation anew with the file with the current save.
        echo "Money $money, day result $day_result, balance is going to be negative, business closed"
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
        # I have introduced "printf" instead of "echo" to display money amounts with the, so-called, "thousands' grouping characters". No idea why there is plural used, but it seems to do what I want. By introducing it I aim for easier reading. See "man bash" (search for "printf"), "man 1 printf", "man 3 printf", https://pubs.opengroup.org/onlinepubs/9799919799/functions/printf.html. If you want to change how thousand groups are separated, you need to, if I understood correctly, change the "LC_NUMERIC" environment variable.
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
