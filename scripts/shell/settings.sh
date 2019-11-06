#DEFAULT SETTINGS:
use_default_settings(){
    daemon="xmrlab.com xmrtolujkxnlinre.onion:18081"
    ringsize=11
    priority="normal"
    fiat="USD"
    fiat_symbol="$"
    crypto="BTC"
    coins_list_type="imagelist"
    seconds_before_update=180
}

parse_setting() {
    read -ra parsed <<< ${settings[$1]}
    echo "${parsed[$2]}"
}

read_settings() {
    if [ -e settings ]; then
        declare settings
        readarray -n 8 -t settings < settings 
        daemon=$(parse_setting 0 3) 
        ringsize=$(parse_setting 1 3) 
        priority=$(parse_setting 2 3) 
        fiat=$(parse_setting 3 3) 
        fiat_symbol=$(parse_setting 4 3)
        crypto=$(parse_setting 5 3)
        coins_list_type=$(parse_setting 6 3)
        seconds_before_update=$(parse_setting 7 4)
        [ -z "$crypto" ] && crypto="BTC" && write_settings
        [ "$coins_list_type" = "imagelist" -o "$coins_list_type" = "checklist" ] || coins_list_type="imagelist" && write_settings
        [ -z "$seconds_before_update" ] && seconds_before_update=180 && write_settings
    else
        use_default_settings
        write_settings
    fi
}

write_settings() {
#    [ -f settings ] && shred -u settings
    echo "Monero daemon address: $daemon
Transaction ring size: $ringsize
Transaction priority level: $priority
Fiat currency code: $fiat
Fiat currency symbol: $fiat_symbol
Crypto valuation asset: $crypto
Coins list type: $coins_list_type
Seconds before updating rates: $seconds_before_update" > settings
}


set_daemon(){
    title
    daemons="zdhkwneu7lfaum2p.onion:18099 MoneroWorld.com xmkwypann4ly64gh.onion:18081 pool.xmr.pt xmrag4hf5xlabmob.onion:18081 xmrlab.com xmrtolujkxnlinre.onion:18081 XMR.to Enter Custom" 
    daemon=$(zenity --list --height=250 --title="Select Monero Daemon" \
             --text "Select a .onion remote node to use as your daemon-address:" \
             --column="Daemon-address:" \
             --column="Hosted by:" $daemons 2> /dev/null)
    [ "$daemon" = "Enter" ] && daemon=$(zenity --entry --title="Enter Custom Monero Daemon" \
                                        --text="Enter daemon-address [address:port]:"  2> /dev/null)

    [ -z $daemon ] && set_daemon
    printf "\n${STD}daemon-address set to: ${YAY}$daemon${STD}" && sleep 2
}

set_priority() {
    title
    printf "${WSTD}Priority levels unimportant, normal, elevated, and priority correspond to 
transaction fee multipliers of x1, x4, x20, and x166, respectively. 
\n${WBU}The higher you set the priority level the faster your transactions will confirm
and the higher your fee will be.
\n${STD}The default priority level used by $MoneroMixer is ${YAY}normal${STD}.\n"     

    levels="unimportant slow x1 normal normal x4 elevated fast x20 priority fastest x166" 
    priority=$(zenity --list --height=220 --width=400 \
                --title="Select Transaction Priority Level" \
                --text "Select your default priority level:" \
                --column="Priority levels" --column="Transaction speed" \
                --column="Fee multiplier" $levels 2> /dev/null)

    [ -z $priority ] && set_priority
    printf "\n${STD}Priority level set to: ${YAY}$priority${STD}" && sleep 2
}

set_fiat() {
    title
    printf "${WSTD}Choose a Fiat currency to use to determine the fiat value of your ${YAY}XMR${WSTD} balance.${STD}
\n(The currency you choose will display in your wallet)
\n${WSTD}The default fiat currency used by $MoneroMixer ${WSTD}is: ${GRN}$fiat ${WSTD}(${GRN}$fiat_symbol${WSTD})${STD}.\n" 
  
    fiats="USD $ EUR € GBP £ CAD $ RUB ₽ JPY ¥ CNY ¥ KRW ₩ Enter Custom" 
    fiat_data_in=$(zenity --list --height=350 --title="Select Fiat Currency" \
                    --text "Select your default fiat currency and symbol:" \
                    --print-column="All" --column="Currency" --column="Symbol" \
                    $fiats 2> /dev/null)

    [ "$fiat_data_in" = "Enter|Custom" ] && \
    fiat_data_in=$(zenity --forms \
                    --title="Enter Custom Fiat Currency" \
                    --text= "Enter Custom Fiat Currency" \
                    --add-entry="Enter currency code:" \
                    --add-entry "Enter currency symbol:"  2> /dev/null)
 
    [ -z "$fiat_data_in" ] && set_fiat
    set_IFS "|"
    read -ra fiat_data <<< ${fiat_data_in}
    unset_IFS

    
    fiat="${fiat_data[0]}"
    fiat_symbol="${fiat_data[1]}"
    printf "\n${STD}Fiat currency set to: ${GRN}$fiat${STD}
${STD}Fiat symbol set to: ${GRN}$fiat_symbol${STD}" && sleep 2  
}

custom_fiat() {
    fiat_data_in=$(zenity --forms --title="Enter Custom Fiat Currency" \
                    --add-entry="Enter currency code:" \
                    --add-entry "Enter currency symbol:"  2> /dev/null)

    [ -z "$fiat_data_in" ] && set_fiat
    set_IFS "|"
    read -ra fiat_data <<< ${fiat_data_in}
    unset_IFS

    
    fiat="${fiat_data[0]}"
    fiat_symbol="${fiat_data[1]}"
}

set_crypto(){
    title
    printf "${WSTD}Choose a coin to use to determine the crypto value of your ${YAY}XMR${WSTD} balance.${STD}\n\n(The coin you choose will display in your wallet)
\n${WSTD}The default crypto valuation asset used by $MoneroMixer ${WSTD}is: ${YAY}BTC${STD}\n"


    exchange="Godex.io"
    crypto=$(torpydo coins | zenity --list --imagelist --title="Select a coin" \
            --text "Select a coin to use to determine the value of your assets" \
            --column="Currently Supported Coins:" --column="Name" --column="Ticker" \
            --print-column=3 2> /dev/null)
    [ -z "$crypto" ] && set_crypto
    printf "\n${STD}Crypto valuation asset set to: ${YAY}$crypto${STD}" && sleep 2

}

set_seconds_before_update(){
    seconds_before_update=$(zenity --scale \
                            --title="How many seconds do you want to wait before updating rates?" \
                            --text="Adjust the slider to the number of SECONDS you want to wait before updating rates then click 'Ok'" \
                            --value=180 --min-value=30 --max-value=600 --step=1 2> /dev/null)
}


setup_choice() {
    use_default_settings
    title
    printf "${WSTD}How would you like to configure your ${MoneroMixer}${WSTD} settings for ${YAY}$name${WSTD}?${STD}\n\n"
    printf "Select '${WBU}Use default settings${STD}' to automatically configure ${YAY}$name${STD} with the 
default ${MoneroMixer} settings. (Recommended for new users)${STD} 


    ${WBU}Default Settings:                           

    ${STD}Monero daemon address:              ${YAY}xmrtolujkxnlinre.onion:18081
    ${STD}Transaction priority level:         ${YAY}normal
    ${STD}Fiat currency code:                 ${GRN}USD
    ${STD}Fiat currency symbol:               ${GRN}$
    ${STD}Crypto valuation asset:             ${YAY}BTC
    ${STD}Seconds before updating rates:      ${WBU}180 

${WSTD}NOTE: You can modify your settings later from the Settings and Utilities Menu." 

    if ! zenity --question --ellipsize \
         --title="How would you like to configure your MoneroMixer settings for $name?" \
         --text="Select 'Use default settings' to automatically configure $name \nwith the default MoneroMixer settings. (Recommended for new users)" \
         --cancel-label="Choose custom settings" \
         --ok-label="Use default settings" 2> /dev/null
    then
        mkdir updates
        set_daemon
        set_priority
        set_fiat
        set_crypto
        #set_seconds_before_update
        #set_ring_size
        #write_settings
        title
    fi

    write_settings
    [ -e settings ] && printf "\n\n${GRN}Success! You are done setting up $MoneroMixer" && sleep 2
    #printf "\n${WBU}Use responsibly. ${STD}" && sleep 3
}

settings_menu() {
    read_settings
    previous_menu="settings_menu"
    title
    printf "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~ ${WSTD}S E T T I N G S / U T I L I T I E S - ${M}${WSTD} E N U ~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	${WSTD}Modifiable Settings:                  ${WBU}Your current settings:${WSTD}
	(${YAY}1${WSTD}) ${STD}Fiat Currency                          ${GRN}$fiat ${WSTD}(${GRN}$fiat_symbol${WSTD})
	(${YAY}2${WSTD}) ${STD}Crypto Valuation Asset                 ${YAY}$crypto${WSTD}
	(${YAY}3${WSTD}) ${STD}Monero Daemon-Address                  ${YAY}$daemon${WSTD}
	(${YAY}4${WSTD}) ${STD}Transaction Priority Level             ${YAY}$priority${WSTD}
	(${YAY}5${WSTD}) ${STD}Seconds Before Updating Rates:         ${WBU}$seconds_before_update${WSTD}

	${WSTD}Utilities:
	(${YAY}6${WSTD}) ${STD}Update MoneroMixer now${WSTD}
	(${YAY}7${WSTD}) ${STD}Enter Monero Wallet CLI (Advanced)${WSTD}
	(${YAY}8${WSTD}) ${STD}Decrypt Wallet Seed${WSTD}

	(${YAY}9${WSTD}) ${STD}Return to Main Menu${STD}" 
    settings_menu_options
}

settings_menu_options() {
    local choice
    printf "\n\n            Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}9${STD}]:${YAY} "
    read -r choice
	case $choice in
        1) set_fiat; torpydo "update" && resync_prices ;;
        2) set_crypto;  torpydo "update" && resync_prices ;;
	3) set_daemon;;
        4) set_priority;;
        5) set_seconds_before_update;;
        6) confirm_update ;;
        7) wallet_cli ;;
        8) wallet_decrypt_seed ;;
	9) main_menu ;;
	*) printf "             ${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
    write_settings
    $previous_menu
}
