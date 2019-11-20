#!/bin/bash
HISTSIZE=0
MMPATH="$PWD"
FILENAMES=( "welcome" "mmutils" "error" "settings" "wallet" "wallet_gen" \
            "main_menu" "exchange" "exchange_menus" "update" "help" "donate" )

for filename in "${FILENAMES[@]}"; do
    . "scripts/shell/${filename}.sh"
done

[ "$USER" = "amnesia" ] && ./scripts/shell/setup.sh launchers

trap clean_all_exit SIGINT
[ -n "$1" ] && $1
 
if !(test -d wallets); then
    description
    disclaimer
    mkdir wallets && cd wallets
    wallet_login "Welcome" "Create or import"
else
    cd wallets 
    wallet_login "Login" "Select"
fi

start_background_updates &
wallet_refresh fatal
main_menu
