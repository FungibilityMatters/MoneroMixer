wallet_cmd(){
    (torsocks ../../monero-software/monero-wallet-cli \
              --no-dns \
              --daemon-address $daemon \
              --command $1 <<<"$name
$password
$password
Yes") | encrypt wallet-cli-out.enc
}

wallet_grep(){
    if [ -z "$2" ]; then
        decrypt wallet-cli-out.enc | grep "$1"
    else
        decrypt wallet-cli-out.enc | grep $1 "$2"
    fi
}


set_noconf() {  
    wallet_cmd "set always-confirm-transfers 0"
}
unset_noconf() { 
    wallet_cmd "set always-confirm-transfers 1"
}
set_noask() {  
    wallet_cmd "set ask-password 0" 
}
unset_noask() { 
    wallet_cmd "set ask-password 2" 
}
set_noauto() {  
    wallet_cmd "set auto-refresh 0"
}
unset_noauto() {  
    wallet_cmd "set auto-refresh 0"
}

print_balance(){
    torpydo "balance" "@B"
}

update_address() {
    (wallet_cmd "address new") \
    | (zprog "Updating address" "Updating your Monero recieving address...")
    wallet_grep "address)" | encrypt address.enc 
}




find_all_wallets(){
    for keyfile in $(find */*.keys 2> /dev/null); do
        set_IFS "/"
        read -ra name <<<"$keyfile"
        echo "${name[0]}"
        unset_IFS
    done
    echo "Create new wallet"
    #echo "Restore wallet from seed"
}

wallet_login(){
    title
    name=$(find_all_wallets | zenity --list --modal \
                                     --title="Login to MoneroMixer" \
                                     --text="Select a Monero wallet to login with." \
                                     --column="wallets" \
                                     --ok-label="Continue" \
                                     --hide-header 2> /dev/null )
    test -n "$name" || clean_all_exit

    if [ "$name" = "Create new wallet" ]; then
        gen_wallet_and_seed_file
    elif [ "$name" = "Restore wallet from seed" ]; then
        wallet_restore_from_seed    
    else
        cd "$name" || clean_all_exit 
        read_settings
        wallet_auth_password "Login to $name"
    fi
}


wallet_auth_password(){
    pw_in=$(zenity --password --modal \
                      --title="${2-""}Enter password for $name" \
                      --ok-label="${1-"Login"}" 2> /dev/null)
    
    if [ -n "$pw_in" ]; then
        password="$pw_in"
        unset -v pw_in
        wallet_cmd address | $(zprog "Authenticating" "Authenticating your password...")
        if wallet_grep -q "invalid password"; then
            if [ "$2" != "LAST ATTEMPT: " ]; then
                title
                title                
                printf "${ERR}ERROR: The password you entered is not valid for wallet: ${YAY}$name\n"
                printf "${ERR}YOU HAVE 1 ATTEMPT REMAINING\n"
                wallet_auth_password "$1" "LAST ATTEMPT: "
            else
                printf "\n${ERR}INVALID PASSWORD" && sleep 2
                clean_all_exit
            fi
        fi
    else
        [ $3 = "noexit" ] && $previous_menu
        clean_all_exit
    fi
}


wallet_refresh() {
    title
    printf "${YAY}Refreshing your wallet and resynchronizing it with the Monero blockchain...
\n${ERR}(This may take some time. Please wait.)${STD}
\nIf you receive an error message such as:${WSTD}\n'1557855698 ERROR torsocks[21439]: 
Connection timed out (in socks5_recv_connect_reply() at socks5.c:553)'
\n${STD}Close the progress dialog then press ${YAY}CTRL-C${STD} to exit securely. 
Check your network and Tor connection statuses then try again.\n${ERR}" 
    wallet_refresh_balance
    title
    wallet_error_check $1
}


wallet_refresh_balance(){
    $(wallet_cmd "refresh") | \
    zprog "Refreshing your wallet" \
    "Refreshing your wallet and resynchronizing it with the Monero blockchain..." "" \
    "--ok-label=Done" "--cancel-label=" "Close dialog"
    wallet_grep "Balance" | encrypt balance.enc
}


wallet_view_balance() { 
    title
    wallet_refresh
    type="full" && print_balance

    if zenity --question --ellipsize \
              --title="Would you like to refresh your wallet again?" \
              --text="Refresh your wallet again to view your updated balance or go back to the Main Menu to make a transaction" \
              --ok-label="Refresh wallet again" \
              --cancel-label="Go back to Main Menu" 2> /dev/null
    then 
        wallet_view_balance   
    else
        type="" && $previous_menu
    fi
}


wallet_view_address() {
    title
    echo -e "${STD}Generating new ${YAY}XMR${STD} receiving subaddress...${STD}"
    update_address
    title nonl
    coin="XMR"
    torpydo "print_qr" "" "$(torpydo make_xmr_qr @A)"
    if zenity --question --ellipsize --ellipsize \
              --title="A new XMR receiving address has been created for your wallet!" \
              --text="Your Current Monero Receiving Address is:\n$(torpydo address @A)\n\nYou can copy this address by right-clicking to copy it, or by scanning the QRCode displayed in the terminal.\nIMPORTANT: For maximum security you should ONLY SEND ONE TRANSACTION PER ADDRESS." \
              --ok-label="Refresh wallet and view updated balance now" \
              --cancel-label="Go back to menu" --icon-name=info  2> /dev/null
    then
        unset -v address && wallet_view_balance
    else
        unset -v address #&& $previous_menu
    fi 
    $previous_menu
}


wallet_transfer() { 
    title
    print_balance

    set_IFS "|"
    tx_data_in=$(zenity --forms --text="Enter Destination Address and Exact XMR Amount to send

    Enter 'ALL' as the amount to send your entire XMR balance (sweep_all)." \
                 --add-entry="Destination Address where XMR will be sent:" \
                 --add-entry="Exact XMR Amount to send:" \
                 --title "Enter Destination Address and XMR Amount" \
                 --timeout 200 2> /dev/null)

    [ -z "$tx_data_in" ] && unset_IFS && $previous_menu
    [ "$tx_data_in" = "|" ] && clean_all_exit 
    read -ra tx_data <<< ${tx_data_in}
    unset_IFS
    xmr_address="${tx_data[0]}"
    xmr_amount="${tx_data[1]}"

    [ -z "$xmr_address" ] && required_error "XMR destination address"
    [ -z "$xmr_amount" ] && required_error "XMR amount to send"
    [ "$xmr_amount" = "ALL" ] && xmr_amount="ALL of your remaining"
        
    type="destination"
    coin="XMR" 
    torpydo "validate" "address%%%$xmr_address"
    validation_error_check

    title
    printf "${STD}You are about to send ${WBU}$xmr_amount${YAY} XMR${STD} to wallet address:\n${YAY}$xmr_address.\n"

    exchange="the Monero receving address you entered"
    coin_out="XMR"
    coin_amount="$xmr_amount"
    dest_address="$xmr_address"

    wallet_confirm_withdrawal
    $previous_menu
}


wallet_withdraw() {
    title
    printf "${STD}As after you confirm this withdrawal, ${WBU}$xmr_amount ${YAY}XMR${STD} 
will be transferred from your Monero Wallet to ${WSTD}$exchange${STD}.
\n${WSTD}Once ${STD}$exchange${WSTD} receives the transfer, ${WBU}$coin_amount ${YAY}$coin_out ${WSTD}will be sent ${STD}anonymously\n${WSTD}to: ${YAY}$dest_address${STD}\n"
    wallet_confirm_withdrawal
}

wallet_confirm_withdrawal(){
    if zenity --list --title="Confirm withdrawal details" \
              --text="Confirm the following withdrawal details before continuing:" \
              --ok-label="Confirm and proceed with withdrawal" \
              --cancel-label="Cancel and go back to menu" \
              --column "" --hide-header <<<"Destination address: $dest_address
$coin_out amount that will be sent: $coin_amount $coin_out
XMR amount that will be withdrawn from your wallet: $xmr_amount XMR" &> /dev/null
    then
        wallet_auth_password "Initiate withdrawal" "" #"noexit"
        unset -v coin_amount dest_address
        wallet_withdraw_confirmed
    else
       unset -v coin_amount dest_address xmr_amount xmr_address
       $previous_menu
    fi
    
}


wallet_withdraw_confirmed() {
    title 
    printf "${YAY}Your anonymous withdrawal is processing! 
\n${ERR}(This will take some time please wait.)${STD}"

    if [ "$xmr_amount" != "ALL of your remaining" ]; then
        printf "\n\nSending ${WBU}$xmr_amount ${YAY}XMR${STD} to ${WSTD}$exchange${STD}...\n${GRN}"

        wallet_cmd "transfer $priority $ringsize $xmr_address $xmr_amount" \
        | zenity --progress --title "Sending your transaction" \
                 --text="Sending $xmr_amount XMR to $exchange..." \
                 --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null
    else
        printf "\n\nSending ${WBU}all of your remaining ${YAY}XMR${STD} to ${WSTD}$exchange${STD}...\n"

        wallet_cmd "sweep_all $(wallet_max_index) $priority 11 $xmr_address" \
        | zenity --progress --title "Sending your transaction" \
          --text="Sending all of your remaining XMR to $exchange..." \
          --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null
    fi
    unset -v xmr_amount xmr_address
    wallet_post_transfer
}


wallet_post_transfer(){
    set_IFS ":"
    read -ra xmr_tx <<<$(wallet_grep "Transaction successfully submitted")
    printf "\n${GRN}${xmr_tx[1]}\n" && unset -v xmr_tx
    unset_IFS    

    wallet_error_check
    unset_noconf

    printf "\n${STD}Updating your ${YAY}XMR${STD} balance..."
    wallet_refresh_balance
}


wallet_show_transfers(){
    wallet_auth_password "Show Transfers" "" "noexit"
    wallet_cmd "show_transfers"
    tx_do=$(torpydo "show_transfers" "" "$(decrypt wallet-cli-out.enc)" | \
                 zenity --list --title="$name Transfers" --timeout=300 \
                        --text="Showing all transfers to and from $name ordered from newest to oldest. (Formatted output of the show_transfers wallet command.)" \
                        --column="Date" --column="Time" --column="Status" --column="Amount" \
                        --column="Fee" --column="Address (receiving subaddress or destination address)" \
                        --column="Payment ID" --column="Transaction Hash" \
                        --column="Address Index (of receiving or input address)" \
                        --ok-label="Return to Main Menu" --cancel-label="Close" \
                        --extra-button="Refresh wallet and show again" \
                        --extra-button="Enter wallet CLI" 2> /dev/null)

    if [ "$tx_do" = "Refresh wallet and show again" ]; then
        wallet_refresh
        wallet_show_transfers
    elif [ "$tx_do" = "Enter wallet CLI" ]; then
        wallet_cli
    else 
        $previous_menu
    fi
}


wallet_cli() {
    clean_all
    title 
    echo -e "You are now leaving ${MoneroMixer} and entering the Monero Wallet CLI..."
    sleep 3
    echo -e "\033[00;${FG};49mSETTING BACKGROUND COLORS TO WHITE...                   "
    clear
    clear
    torsocks ../../monero-software/monero-wallet-cli --no-dns \
    --daemon-address $daemon $1 --wallet-file "$name"
}


wallet_max_index(){
    wallet_cmd "address all"
    read -ra lastaddy <<<$(wallet_grep "address)" | tail -n 1)
    declare -i max_index
    max_index=${lastaddy[0]}
    unset -v lastaddy
    index_str="index=0"
    for ((i = 1 ; i <= $max_index ; i++)); do
        index_str="${index_str},$i"
    done
    echo "$index_str"
}


wallet_decrypt_seed() {
    seedfile="${name}-SEED"
    title
    printf "${ERR}To decrypt ${YAY}${seedfile}.enc${ERR} you must enter your password correctly."
    wallet_auth_password "Decrypt ${seedfile}.enc" "" "noexit"
    zenity --text-info --width=520 --height=350 \
           --title="$name Seed" \
           --filename <(decrypt ${seedfile}.enc) 2> /dev/null
    $previous_menu
}

