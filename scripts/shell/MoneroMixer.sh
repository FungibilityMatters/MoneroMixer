#!/bin/bash

#MENUS AND CHOICE FUNCTIONS:
main_menu() {
    previous_menu="main_menu"
    title
    print_balance
    printf "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ${M}${WSTD} A I N - ${M}${WSTD} E N U ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	(${YAY}1${WSTD}) ${STD}Deposit (${GRN}RECEIVE ${YAY}XMR${STD},${YAY} BTC${STD},${YAY} LTC${STD},${YAY} ETH${STD},${YAY} BCH${STD}, & ${YAY}100${STD}+${YAY} other coins${STD})${WSTD}
	(${YAY}2${WSTD}) ${STD}Withdraw (${GRN}SEND ${YAY}XMR${STD},${YAY} BTC${STD},${YAY} LTC${STD},${YAY} ETH${STD},${YAY} BCH${STD}, & ${YAY}100${STD}+${YAY} other coins${STD})${WSTD}
	(${YAY}3${WSTD}) ${STD}Exchange options (View previous transactions or goto exchange menu)${WSTD}
	(${YAY}4${WSTD}) ${STD}Wallet options (Refresh your wallet and view updated balance)${WSTD}
	(${YAY}5${WSTD}) ${STD}Settings and Utilities ${WSTD}
	(${YAY}6${WSTD}) ${STD}Help and Additional Info${WSTD}
	(${YAY}7${WSTD}) ${STD}Donate (${GRN}Help support this project${STD})${WSTD}
	(${YAY}8${WSTD}) ${STD}Quit${STD}"
    main_menu_options
}

main_menu_options() {
    local choice
    printf "\n\n			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}8${STD}]:${YAY} "
    read -r choice
    case $choice in
		1) deposit_selector ;;
		2) withdraw_selector ;;
		3) exchange_options ;;
		4) wallet_options ;;
		5) settings_menu ;;
        6) help_menu ;;
        7) donation_menu ;;
		8) clean_all_exit ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && main_menu
	esac
}

deposit_selector(){
    tx_option_selector deposit deposit \
"Or select Monero to create and view a new XMR recieving address for your wallet" \
    wallet_view_address 
}

withdraw_selector() {
    tx_option_selector withdraw withdrawal \
    "Or select Monero to send XMR directly from your wallet" \
    wallet_transfer
}

coin_selector() {
    if [ $coins_list_type = "imagelist" ]; then
        alt_list_type="checklist"
        toggle="Show checklist"
        select_help="(Hold down SHIFT to select multiple coins)\n"
    else
        alt_list_type="imagelist"
        toggle="Show images"
        select_help=""
    fi

    unset -v exchange
    selected_coins=$(torpydo "coins" | zenity --list --$coins_list_type \
                                       --height=350 --width=500 \
                                       --multiple --separator="|" \
                                       --title="Select coin(s) to view anonymous $2 options" \
                                       --text="Select coin(s) to view currently available $2 options from non-KYC exchanges.\n$select_help\n$3:" \
                                       --extra-button="$toggle" --ok-label="Continue with selected coin(s)" \
                                       --column="Select coin(s)" --column="Currently supported coins" --column="Ticker" \
                                       --print-column=3 $coins 2> /dev/null)

    if [ "$selected_coins" = "$toggle" ]; then
        coins_list_type="$alt_list_type"
        coin_selector "$1" "$2" "$3"
    fi
}


tx_option_selector() {
    coin_selector "$1" "$2" "$3"
    [ -z "$selected_coins" ] && required_error "coin to $1"
    if ! [ "$selected_coins" = "XMR" ]; then
        if grep -q "XMR" <<<"$selected_coins" ; then
            comp_currs="${fiat}|$selected_coins"
        else
            comp_currs="${fiat}|XMR|$selected_coins"
        fi
    
        read -ra amount_in <<<$(zenity --forms --width=350 \
                                --title="Select a currency and estimated $2 amount for rate comparison" \
                                --text="Select a currency to use for exchange rate comparison from the dropdown menu,\nthen enter an estimated $2 amount in the currency you selected.
\nClick 'Ok' to generate a list of all non-KYC $2 options currently available for this amount.
Options are ranked by exchange rate to ensure that you always get the best deal!" \
                                --add-combo="Select a currency to use for exchange rate comparison: " \
                                --combo-values="$comp_currs" \
                                --add-entry="Enter estimated $2 amount in the currency selected above: " \
                                --ok-label="Compare $2 options" --separator=" " 2> /dev/null)

        amount="${amount_in[1]} ${amount_in[0]}"
        [ -z $amount ] && required_error "amount to compare $2 options"

        title
        type="$1"
        $(torpydo "compare" >> pydisplay) | $(zprog "Finding best $2 options" "Ranking current options for $1ing $amount...")
        cat pydisplay && shred -u pydisplay
        python_error_check
    
        set_IFS "|"
        read -r exchange coin <<<$(unset_IFS && zenity --list --height=250 --width=200 \
                               --title="Choose a $2 option" --ok-label="Continue with selected $2 option" \
                               --text="Select a option from the list or press cancel\nto go back to the main menu and try again:" \
                               --column="option" --column="Coin" --column="Exchange" \
                               --hide-column=1 $(cat options-list && rm -f options-list) 2> /dev/null)
        unset_IFS
        [ -z "$exchange" ] && main_menu
        unset -v amount
        $1 "${coin}"
    else
        unset -v amount
        $4 
    fi
}

exchange_options(){
    local choice
    choice=$(zenity --list --height=240 --title="Exchange Options" \
             --text="Select an action from the list below then press 'Ok'" \
             --column="choice" --column="Exchange Options" --hide-column=1 \
             1 "View previous Deposit order IDs" \
             2 "View previous Withdrawal order IDs" \
             3 "Godex.io menu" \
             4 "MorphToken menu" \
             5 "XMR.to menu" 2> /dev/null)
    case $choice in
		1) view_order_IDs deposit ;;
        2) view_order_IDs withdrawal ;;
        3) godex_menu ;;
        4) morph_menu ;;
        5) xmrto_menu ;;
		*) $previous_menu 
	esac
}

wallet_options(){
#--extra-button="Refresh wallet and view updated balance"
    local choice
    choice=$(zenity --list --height=220 --title="Wallet Options" \
             --text="Select an action from the list below then press 'Ok'" \
             --column="choice" --column="Wallet Options:" --hide-column=1 \
             1 "Refresh wallet and view updated balance" \
             2 "Receive XMR" \
             3 "Send XMR" \
             4 "View all XMR transfers" \
             5 "Enter Monero Wallet CLI (Advanced)" \
             6 "Decrypt wallet seed" 2> /dev/null)
    case $choice in
		1) wallet_view_balance ;;
        "Refresh wallet and view updated balance") wallet_view_balance ;;
        2) wallet_view_address ;;
        3) wallet_transfer ;;
        4) wallet_show_transfers ;;
        5) wallet_cli ;; 
        6) wallet_decrypt_seed ;; 
		*) $previous_menu
	esac
}

main(){
    filenames=( "welcome" "mmutils" "error" "settings" "wallet" "wallet_gen" \
                "exchange" "exchange_menus" "update" "help" "donate" )

    for filename in "${filenames[@]}"; do
    . scripts/shell/$filename.sh
    done

    trap clean_all_exit SIGINT

    if [ "$1" = "restore" ]; then
        wallet_restore_from_seed
    else
        if !(test -d wallets); then
            description
            disclaimer
            #setup_choice
            mkdir wallets && cd wallets
            gen_wallet_and_seed_file
        else
            cd wallets
            wallet_login
        fi
        start_background_updates &
        test -n "$1" && $1
        fi

    wallet_refresh fatal
    main_menu
}

HISTSIZE=0
main
