#!/bin/bash

read_var() {

    VAR_NAME=$1; shift
    MESSAGE=$1; shift
    REQUIRED=$1; shift
    DEFAULT=$1; shift
    
    # If a set of choices has been provided
    if [[ -n $1 ]]; then
        CHOICES=( $* )
    else
        CHOICES=()
    fi

    # Preparing default message
    DEFAULT_MSG=" [${DEFAULT}]"
    [[ -n ${DEFAULT} ]] && HAS_DEFAULT=true || HAS_DEFAULT=false

    # Save cursor and clear rest of screen
    tput sc
    tput ed
    while true; do
        # Write valid choices
        if [[ ${#CHOICES[@]} -gt 0 ]]; then
            tput el
            tput cud 1
            tput el
            echo "Valid options: [${CHOICES[@]}]"
            tput cuu 2
        fi
        
        tput el
        echo -n "${MESSAGE}${DEFAULT_MSG}: "
        read value
        [[ -z ${value} && -n ${DEFAULT} ]] && value=${DEFAULT}

        # Value is empty but marked as required
        if [[ -z "${value}" && "${REQUIRED}" = "true" ]]; then
            tput el
            echo "You must provide a value (press ENTER to try again)"
            read
            tput rc
            tput ed
            continue
        fi
        
        # If choices provided, validate
        if [[ ${#CHOICES[@]} -gt 0 ]]; then
            found=false
            for choice in ${CHOICES[@]}; do
                if [[ ${choice} == ${value} ]]; then
                    found=true
                    break
                fi
            done
            tput el
            if [[ ${found} == false ]]; then
                echo "Invalid choice (press ENTER to try again)"
                read
                tput rc
                tput ed
                continue
            fi
        fi
        
        # All good
        eval $VAR_NAME=\"${value}\"
        break

    done

}

