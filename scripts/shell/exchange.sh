deposit() {       
    if [ -z $1 ]; then 
        title
        printf "${STD}NOTE: To cancel deposit and exit press 'CTRL-C' at any time${STD}\n"
        print_title "~" \
                    "${WBU}DEPOSIT${STD}: Convert your coins to ${YAY}XMR${STD} via ${WSTD}$exchange${STD}" \
                    "DEPOSIT: Convert your coins to XMR via $exchange" \
    
        coin_in=$(exchange_coin_selector "Select a coin to deposit" \
                  "Select the coin you would like to convert to XMR and deposit to your wallet")
    else
        coin_in="$1"
    fi
    [ -z "$coin_in" ] && required_error "coin to deposit/receive"

    title
    printf "${STD}NOTE: To cancel deposit and exit press 'CTRL-C' at any time${STD}\n"

    print_title "~" \
                "${WBU}DEPOSIT${STD}: Convert ${YAY}$coin_in${STD} to ${YAY}XMR${STD} via ${WSTD}$exchange${STD}-" \
                "DEPOSIT: Convert $coin_in to XMR via $exchange-"

    printf "\n${WSTD}It is STRONGLY RECOMMENDED that you enter a refund address to ensure that your 
coins are not lost if any errors occur.
\n\n${ERR}IMPORTANT: DO NOT USE A REFUND ADDRESS ASSOCIATED WITH YOUR IDENTITY
Doing so could compromise the anonymity of your Monero wallet.${STD}\n"

    coin=$coin_in && torpydo "extraid"
    [ -e extraid ] && readarray -n 2 -t extraid_arg < extraid && shred -u extraid

    refund_address=$(zenity --forms --title="Enter $coin_in refund address" \
                            --text="Enter a $coin_in refund address where your refund will be sent if any errors occur. 
\nIMPORTANT: DO NOT USE A REFUND ADDRESS ASSOCIATED WITH YOUR IDENTITY\nDoing so could compromise the anonymity of your Monero wallet." \
                            --add-entry="$coin_in Refund Address:" $extraid_arg"${extraid_arg[1]}" \
                            --cancel-label="Continue without refund address" \
                            --ok-label="Use refund address entered above" 2> /dev/null)

    unset -v extraid_arg
    [ -z "$refund_address" ] && refund_address="None"
    
    coin=$coin_in && type="refund"
    torpydo "validate" "address%%%$refund_address"
    validation_error_check
     
    title
    coin_out="XMR"
    if [ "$exchange" = "Godex.io" ]; then 
        $(torpydo "rates" | encrypt pydisplay.enc) | \
        $(zprog "Fetching $coin_in to $coin_out rates" \
                "Securely fetching latest $coin_in to $coin_out rates from $exchange...")
        decrypt pydisplay.enc && shred -u pydisplay.enc
        python_error_check

        printf "${WSTD}Godex.io REQUIRES that you enter an estimate of the amount you plan to deposit."
        amount=$(zenity --entry --title="Enter Estimated $coin_in deposit amount" \
                        --text="Enter estimated amount you plan to deposit in $coin_in:" 2> /dev/null)
        [ -z "$amount" ] && required_error "estimated $coin_in deposit amount"
    else
        amount="n/a"
    fi

    title
    printf "${STD}Generating new ${YAY}XMR${STD} receiving subaddress for this deposit...${STD}"
    update_address    

    title
    printf "${STD}Securely connecting to ${WSTD}$exchange${STD} servers to create order...\n"
    torpydo "deposit" "refund_address%%%${refund_address-"None"}/@A" \
    | append_encrypted_id depositIDs.enc
    python_error_check

    unset -v amount refund_address
    sleep 5
    type="deposit"
    get_last_order_id
    display_deposit
}


withdraw_warning() {
    title
    printf "${ERR}IMPORTANT: This method can leave you vulnerable to timing based blockchain 
analysis if the amount you deposit and the amount you withdraw correlate within 
a small time span. 
\n${WBU}There are three ways to prevent this:
    ${YAY}1${WSTD})${STD} Wait at least 1-2 hours before withdrawing through an exchange.\n
    ${YAY}2${WSTD})${STD} Withdraw a much smaller amount than you deposited initially then
       withdraw the rest later.\n
    ${YAY}3${WSTD})${STD} Spend your Monero directly from $MoneroMixer or withdraw to another wallet"

    if ! zenity --question --ellipsize --title="IMPORTANT: Read this if you care about your privacy" \
                --text=\
"IMPORTANT: This method can leave you vulnerable to timing based blockchain analysis 
if the amount you deposit and the amount you withdraw correlate within a small time span. 
\nThere are three ways to prevent this:
    1) Wait at least 1-2 hours before withdrawing through an exchange.\n
    2) Withdraw a much smaller amount than you deposited initially then withdraw the rest later.\n
    3) Spend your Monero directly from MoneroMixer or withdraw it to another XMR wallet." \
                --cancel-label="Cancel and go back to menu" \
                --ok-label="Continue with withdrawal" --icon-name=dialog-warning 2> /dev/null
    then
        $previous_menu 
    fi 
}

withdraw() {
    withdraw_warning
    title
    printf "${STD}NOTE: To cancel withdrawal and exit press 'CTRL-C' at any time\n"

    if [ -z $1 ]; then
        print_title "~" \
                    "${WBU}WITHDRAW${STD}: Convert ${YAY}XMR${STD} to your preferred coin via ${WSTD}$exchange${STD}" \
                    "WITHDRAW: Convert XMR to your preferred coin via $exchange"
            
        coin_out=$(exchange_coin_selector "Select a coin to withdraw anonymously" \
                                          "Select the coin you would like to withdraw/send anonymously:")
    else
        coin_out="$1"
        abrev=$(echo $exchange | tr [:upper:] [:lower:] | tr -d ".")
        abrev="${abrev:0:5}"
    fi
    [ -z "$coin_out" ] && required_error "coin to withdraw/send"

    title        
    print_title "~" \
                "${WBU}WITHDRAW${STD}: Convert ${YAY}XMR${STD} to ${YAY}$coin_out${STD} via ${WSTD}$exchange${STD}" \
                "WITHDRAW: Convert XMR to $coin_out via $exchange" 
    printf '\n'

    coin_in="XMR"
    $(torpydo "rates" "@B" | encrypt pydisplay.enc) | \
    $(zprog "Fetching $coin_in to $coin_out rates" "Securely fetching latest $coin_in to $coin_out rates from $exchange...")
    decrypt pydisplay.enc && shred -u pydisplay.enc
    python_error_check

    amount_coin="XMR"
    [ "$exchange" = "XMR.to" ] && amount_coin="BTC"

    if [ "$2" != "pp_url" ]; then 
        coin=$coin_out && torpydo "extraid" #declare -a extraid_arg && 
        [ -e extraid ] && readarray -n 2 -t extraid_arg < extraid #&& shred -u extraid

        tx_data_in=$(zenity --forms --title "Enter $coin_out destination address and $amount_coin amount"\
                            --text="Enter a $coin_out destination address where your new 'mixed' $coin_out will be sent anonymously\nand an exact amount in $amount_coin to withdraw/send from your wallet." \
                            --add-entry="$coin_out destination address where new 'mixed' $coin_out will be sent:" \
                            $extraid_arg"${extraid_arg[1]}" \
                            --add-entry="Exact $amount_coin amount to withdraw/send from your wallet:"  2> /dev/null)
    else
        pp_in=$(zenity --entry --title "Enter a payment protocol url to pay with XMR.to" \
                       --text="Enter a payment protocol url such as: https://bitpay.com/i/KbMdd4EhnLXSbpWGKsaeo6 
to pay the order anonymously with your Monero balance via XMR.to.
\nThis alternative order creation endpoint allows you to create a new order at the current price, 
but instead of providing an explicit address and amount, you must provide a BIP70 url 
that once fetched by XMR.to will provide the address and amount.
\nNote: values such as https://bitpay.com/invoice?id=xxx or bitcoin:?r=https://bitpay.com/i/xxx 
will be corrected automatically to the correct form for Bitpay: 
https://bitpay.com/i/KbMdd4EhnLXSbpWGKsaeo6" \
                        --add-entry="Enter a payment protocol url:" 2> /dev/null)
        tx_data_in="$pp_in|pp"
    fi

    [ -z "$extraid_arg" ] || tx_data_in=$(echo "print('$tx_data_in'.replace('|','***',1))" | python3)
    unset -v extraid_arg

    set_IFS "|"
    read -ra tx_data <<< ${tx_data_in}
    unset_IFS

    dest_address="${tx_data[0]}"
    amount="${tx_data[1]}"
    [ -z "$dest_address" ] && required_error "$coin_out destination address"
    [ -z "$amount" ] && required_error "$amount_coin amount to send"

    coin=$coin_out
    type="destination"
    torpydo "validate" "address%%%$dest_address" 
    validation_error_check

    if [ "$exchange" != "XMR.to" ]; then 
        title
        printf "${STD}Generating new ${YAY}XMR${STD} receiving subaddress to use as the refund address...${STD}"
        update_address
        torpydo_args="@A@B"
    else
        torpydo_args="@B"
    fi
    
    title
    torpydo "withdraw" "destination_address%%%$dest_address/$torpydo_args" \
    | append_encrypted_id withdrawalIDs.enc
    python_error_check
    sleep 5

    type="withdrawal"
    display="False"
    get_last_order_id
    get_exchange_data
    xmr_amount="${coin_in_data[1]}"
    xmr_address="${coin_in_data[2]}"
    coin_amount="${coin_out_data[1]}"    
    dest_address="${coin_out_data[2]}"
    donation_data_in
    wallet_withdraw
    display_withdrawal
}

get_last_order_id(){
    read -ra orderid <<<$(decrypt "${type}IDs.enc" | grep -m 1 "${exchange}")
    orderid=${orderid[3]}
}

get_exchange_data(){
    declare exchange_data
    readarray -t exchange_data <<<$(torpydo "status" "order_id%%%$orderid/@B")
    read -ra coin_in_data <<<"${exchange_data[0]}"
    read -ra coin_out_data <<<"${exchange_data[1]}"
    read -ra donation_data <<<"${exchange_data[2]}"
    unset -v exchange_data
    python_error_check
}


get_order_status(){
    title
    printf "${WSTD}$exchange ${STD}Order ID: ${YAY}$orderid${STD}
\nRequesting order status from ${WSTD}$exchange${STD}...\n"
    get_exchange_data
}

display_withdrawal() {
    type="withdrawal"
    display="True"
    get_order_status

    if zenity --question --ellipsize --title="Refresh order status?" \
              --text="Refresh order now to view the latest order status.
\nOr go back to the menu to check your balance and make new transactions." \
              --ok-label="Refresh order now" --cancel-label="Go back to menu" 2> /dev/null
    then 
        display_withdrawal        
    else
        test ${donation_data[0]} = "notify" && ${abrev}_donation || $previous_menu 
    fi
}

display_deposit() {
    type="deposit"
    display="True"
    get_order_status
    qrdata="${coin_in_data[2]} ${coin_in_data[3]}"
    unset -v exchange_data #qrdata
    deposit_display_options
}

deposit_display_options(){
    local choice
    choice=$(zenity --list --title="Select an action from the list below" \
                    --text="Select an action from the list below then press 'Ok'" \
                    --column="choice" --column="Options:" --hide-column=1 --hide-header=2 \
                    1 "Refresh order status now" \
                    2 "View a QRCode of the deposit address" \
                    3 "Refresh your wallet and view updated balance" \
                    4 "Go back to menu"  2> /dev/null)
    case $choice in
		1) display_deposit ;;
        2) display_qrcode ;;
        3) unset -v qrdata && wallet_view_balance ;;
        4) unset -v qrdata && $previous_menu ;;
		*) deposit_display_options 
	esac
}

display_qrcode() {
    title
    torpydo "print_qr" "" "$(torpydo make_qr)"
    if zenity --question --ellipsize --title="Refresh order status?" \
              --text="Refresh order now to view the latest order status.
\nOr go back to the menu to check your balance and make new transactions." \
              --ok-label="Refresh order now" \
              --cancel-label="Go back to menu" 2> /dev/null
    then 
        display_deposit        
    else
        unset -v result_str qrdata
        $previous_menu  
    fi
}


view_id() {
    title
    printf "${WBU}NOTE: You can view the order IDs of all your previous deposits or withdrawals
in the files named: ${YAY}depositIDs.enc${WBU} and ${YAY}withdrawalIDs.enc${WBU} respectively.${WSTD}
\nTo open these files you must decrypt them via the Main Menu option 3"
    orderid=$(zenity --entry --title="Enter $exchange Order ID" \
                     --text="Enter $exchange Order ID to view order status:" 2> /dev/null)
    [ -z $orderid ] && required_error "$exchange order ID"
    view 
}

view() {
    title
    printf "${WSTD}$exchange ${STD}Order ID: ${YAY}$orderid${STD}
\nRequesting order status from ${WSTD}$exchange${STD}...\n\n"
    get_exchange_data

    if zenity --question --ellipsize --title="Refresh order status?" \
              --text="Refresh order now to view the latest order status.
\nOr go back to the menu to check your balance and make new transactions." \
              --ok-label="Refresh order now" --cancel-label="Go back to menu" 2> /dev/null
    then 
        view      
    else
        $previous_menu
    fi
}

get_all_orderIDs() {
    readarray -t ID_lines <<<$(decrypt "${1}IDs.enc")
    for split_ID in ${ID_lines[@]}; do
        if ! [ $split_ID = "Order" -o $split_ID = "ID:" ]; then
            if [ -n "$orderIDs_str" ]; then
                orderIDs_str="${orderIDs_str}
$split_ID"
            else
                orderIDs_str="$split_ID"
            fi
        fi
    done
    echo "$orderIDs_str"
}

view_order_IDs() {
    wallet_auth_password "Decrypt $1 IDs" "" "noexit"
    ID_line=$(zenity --list --height=260 --title="Select a $1 Order ID" \
                     --text="Select a $1 Order ID then press 'Ok'\nto view the latest order status.
\nYour $1 Order IDs from newest to oldest:" \
                    --print-column=ALL --column "Exchange:" --column "Order ID:" \
                    <<<"$(get_all_orderIDs $1)" 2> /dev/null)

    set_IFS "|"
    read -r exchange orderid <<<"$ID_line"
    unset  -v ID_line
    unset_IFS

    [ -n "$orderid" ] && display_${1}
    $previous_menu
}


exchange_coin_selector() {
    unset -v coin

    if [ -z "$coin" ]; then
        coin=$(torpydo "coins" | zenity --list --imagelist --height=250 --width=500 \
                      --title="$1" --text "$2" \
                      --column="Select coin" --column="Name" --column="Ticker" \
                      --print-column=3 $coins 2> /dev/null)
    fi
    echo "$coin"
}

#QUERY AN VIEW EXCHANGE RATES
rates() {
    coin=$(exchange_coin_selector "Select a coin to view $1 rates" \
                                  "Select a coin to view $1 rates from $exchange:")
    [ -z "$coin" ] && $previous_menu

    if [ "$1" = "deposit" ]; then
        coin_in="$coin"
        coin_out="XMR"
        display_rates
    else
        coin_in="XMR"
        coin_out="$coin"
        display_rates "@B"
    fi
}

display_rates() {
    title
    $(torpydo "rates" "$1" | encrypt pydisplay.enc) | \
    $(zprog "Fetching $coin_in to $coin_out rates" \
            "Securely fetching latest $coin_in to $coin_out rates from $exchange...")
    decrypt pydisplay.enc
	python_error_check 
    shred -u pydisplay.enc

    if zenity --question --ellipsize --title="Refresh rates?" \
              --text="Refresh rates again to view the latest $coin_in to $coin_out rates from $exchange.
\nOr go back to the menu to check your balance and make new transactions." \
              --ok-label="Refresh rates now" --cancel-label="Go back to menu" 2> /dev/null
    then 
        display_rates $1      
    else
        $previous_menu
    fi
}
