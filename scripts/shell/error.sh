#ERROR HANDLING FUNCTIONS:
required_error() {
    zerror "ERROR: No $1 entered" "A $1 is required. Try again."
    $previous_menu
}


validation_error_check() {
    if [ -e validation_error ]; then
        read -ra error_type < validation_error
        shred -u validation_error
        ${error_type[0]} "${error_type[1]}" "${error_type[2]}"
    fi
}


invalid_address(){
    if ! zenity --question --ellipsize --icon-name='dialog-warning' \
                --title="The $1 address you entered may not be a valid $2 address." \
                --text="The $1 address you entered may not be a valid $2 address.\nDo you want to continue anyway?" \
                --ok-label="Continue anyway" 2> /dev/null 
    then 
        $previous_menu
    fi 
}


segwit_address() {
    if ! zenity --question --ellipsize --icon-name='dialog-warning' \
                --title="$1 does not support segwit addresses." \
                --text="$1 does not support segwit addresses. If you receive an error try again with a standard address instead. \nDo you want to continue with segwit address anyway?" \
               --ok-label="Continue anyway" 2> /dev/null
    then 
        $previous_menu
    fi 
}


python_error_check() {
    [ -e py_error ] && python_error_out
}


python_error_out() {
    readarray -n 2 -t error_message < py_error && shred -u py_error
    zerror "${error_message[0]}" "${error_message[1]}"
    $previous_menu
}


wallet_error_check() {
    unset -v error_type
    daemon_errors=( "set_daemon" "no connection to daemon" "failed to connect to daemon" "Daemon uses a different RPC major version")
    if wallet_grep -q "Error"; then
        for daemon_error in "${daemon_errors[@]}"; do
            if wallet_grep -q "$daemon_error"; then
                error_type="daemon"
            fi
        done
        error=$(wallet_grep "Error")
        [ $error_type = "daemon" ] && daemon_error_out || wallet_error_out $1
    fi
}


wallet_error_out() {
    title
    printf "${ERR}Uh-oh it seems that an error has occurred :( 
(Don't worry your funds are safe)${STD} 
\nThe error output is as follows:${ERR}\n$error
\n${WBU}TROUBLESHOOTING TIPS${STD}: 
If the error is due to not enough unlocked balance in your wallet, first make 
sure that your balance is unlocked, if not refresh your wallet ${WSTD}(menu option ${YAY}4${WSTD}). 
\n${WSTD}If your balance is unlocked try sending a slightly smaller amount.${STD}\n"

    zerror "$error" "Uh-oh it seems that an error has occurred :( \n(Don't worry your funds are safe)
\nThe error output is as follows:\n$error"

    [ "$1" != "fatal" ] && $previous_menu || clean_all_exit    
}


daemon_error_out() {
    title
    echo -e "${ERR}Uh-oh it seems that your wallet cannot connect to a Monero daemon :( 
(Don't worry your funds are safe)${STD} 
\nThe error output is as follows:${ERR}\n$error 
\n${WBU}Select another daemon-host or quit and try again later" 

    if zenity --question --ellipsize --icon-name='dialog-warning' --title="$error" \
              --text="Uh-oh it seems that your wallet cannot connect to a Monero daemon :( 
\nWould you like to try connecting to another daemon-host?" \
              --ok-label="Choose another daemon-host" \
              --cancel-label "Quit and try again later" 2> /dev/null; 
    then 
        set_daemon
        write_settings
        read_settings
        wallet_refresh
        $previous_menu
    else
        clean_all_exit
    fi 
}
