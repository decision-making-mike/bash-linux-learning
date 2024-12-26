#!/bin/bash

# Help commands. Many command-line applications include commands for showing help, like --help, or for showing various runtime information, like --verbose. This script does not. The reason is, I believe that the simplicity of a Bash script makes it significantly easier to debug.

# Notable commands. "CTRL-D" ends the day without waiting, "CTRL-C" exits the simulation.

save_file_path="$1"
if [[ -z "$save_file_path" ]]
then
    echo >&2 "Error, no save file path provided, exiting"
    exit 1
fi

day=1
money=0
loan=0
driver_count=0
manager_count=0
car_count=0
car_rent_charge=1
salary=10
income=25
# The maximum single manager vehicle count is 50 because I assume https://www.gov.uk/become-transport-manager as a requirement. This in turn was implemented because I needed some upper limit for manager effectiveness so that just employing more managers, without renting new cars, not yield higher income ad infinitum.
maximum_single_manager_vehicle_count=50
income_tax_rate_numerator=1
income_tax_rate_denominator=10
interest_rate_numerator=1
interest_rate_denominator=100

do_business () {
    read -a c -p ' > '
    case "${c[0]}" in
        borrow)
            (( money += "${c[1]}" ))
            (( loan += "${c[1]}" ))
            ;;

        repay)
            if [[ "${c[1]}" -gt "$money" ]]
            then money=0
            else (( money -= "${c[1]}" ))
            fi

            if [[ "${c[1]}" -gt "$loan" ]]
            then loan=0
            else (( loan -= "${c[1]}" ))
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
    esac
}

min () {
    echo "$(( "$1" <= "$2" ? "$1" : "$2" ))"
}

handle_day () {
    used_car_count="$(min "$driver_count" "$car_count")"
    total_income=0
    if [[ "$manager_count" -gt 0 ]]
    then
        # I'm adding 1 to the maximum single manager vehicle count since this count is the maximum one that should make the manager yield at least minimal result. If the 1 weren't added, the manager would yield a result equal to zero.
        fleet_management_efficiency_rate_numerator="$(( "$maximum_single_manager_vehicle_count" + 1 - "$car_count" / "$manager_count" ))"
        fleet_management_efficiency_rate_denominator="$(( "$maximum_single_manager_vehicle_count" + 1 ))"
        total_income="$(( "$fleet_management_efficiency_rate_numerator" * "$income" * "$used_car_count" / "$fleet_management_efficiency_rate_denominator" ))"
    fi
    (( money += "$total_income" ))
    total_income_tax="$(( "$total_income" * "$income_tax_rate_numerator" / "$income_tax_rate_denominator" ))"
    (( money -= "$total_income_tax" ))

    interest="$(( "$loan" * "$interest_rate_numerator" / "$interest_rate_denominator" ))"
    if [[ "$money" -lt "$interest" ]]
    then
        echo "Money $money, cannot pay the interest $interest, business closed"
        exit
    else (( money -= "$interest" ))
    fi

    total_car_rent_charge="$(( "$car_count" * "$car_rent_charge" ))"
    if [[ "$money" -lt "$total_car_rent_charge" ]]
    then
        echo "Money $money, cannot pay the total car rent charge $total_car_rent_charge, business closed"
        exit
    else (( money -= "$total_car_rent_charge" ))
    fi

    total_salary="$(( "$salary" * ("$driver_count" + "$manager_count") ))"
    if [[ "$money" -lt "$total_salary" ]]
    then
        echo "Money $money, cannot pay the total salary $total_salary, business closed"
        exit
    else (( money -= "$total_salary" ))
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
"loan=$loan\n"\
"driver_count=$driver_count\n"\
"manager_count=$manager_count\n"\
"car_count=$car_count"
}

run () {
    load
    while true
    do
        clear
        echo -e \
"Day $day | Money $money | Loan $loan\n"\
"Driver count $driver_count | Manager count $manager_count\n"\
"Car count $car_count | Used car count $(min "$car_count" "$driver_count")"
        read -n 1 -t 2 c
        case "$c" in
            d) do_business ;;
        esac
        handle_day
        save
    done
}

run
