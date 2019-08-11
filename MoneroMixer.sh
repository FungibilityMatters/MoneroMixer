#!/bin/bash

#COLORS:
FG=33
BG=40
WT=37
STD="\033[00;${FG};${BG}m"
WSTD="\033[00;${WT};${BG}m"
LSTD="\033[00;34;${BG}m"
WBU="\033[01;37;40m"
ITL="\033[3;${FG};${BG}m"
WITL="\033[3;37;${BG}m"
ERR="\033[01;31;${BG}m"
YAY="\033[01;36;${BG}m"
GRN="\033[01;32;${BG}m"
M="\033[0;4;33;${BG}mM${WSTD}"
MoneroMixer="${M}onero${M}ixer${STD}"


#HELPER FUNCTIONS:
title() {
echo -e "${STD}SETTING BACKGROUND COLORS TO BLACK                     "
clear
print_title '-' "${WSTD}${MoneroMixer}${WSTD} v${STD}1.0${WSTD} by Fungibility${M}atters${STD}-" \
"MoneroMixer v1.0 by FungibilityMatters-" 
printf '\n'
}

title_welcome() {
echo -e "${STD}SETTING BACKGROUND COLORS TO BLACK                     "
clear
print_title '-' "${WSTD}Welcome to ${MoneroMixer}${WSTD} v${STD}1.0${WSTD} by Fungibility${M}atters${STD}-" \
"Welcome to MoneroMixer v1.0 by FungibilityMatters-"
printf '\n'
} 

print_title() {
char="$1"
title="$2"
nocolor="$3"
declare -i len
len=${#nocolor} 
shift=1
left="$(($((${COLUMNS:-$(tput cols)} - $len)) / 2))"
test $((${COLUMNS:-$(tput cols)} % 2)) -ne $(($len % 2)) && right="$((${left} + ${shift}))"
printf "${STD}%*s" "${left}" '' | tr ' ' "${char}" && printf "$title" 
printf '%*s' "${right-$left}" '' | tr ' ' "${char}"
printf '\n' #\n'
}

got_it() {
echo -n -e "	${YAY}Got it? ${STD}[${WSTD}When you are ${STD}ready${WSTD} press ${YAY}ENTER${WSTD} to continue${STD}]${WSTD}:"
read -r junk
title
}


back_to_previous() {
echo -e -n "
	    ${STD}Press ${YAY}ENTER${STD} to go back to previous Menu:"
read -r junk
$previous_menu
}

#MENUS AND CHOICE FUNCTIONS:
main_menu() {
previous_menu="main_menu"
title
print_balance
echo -e "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ${M}${WSTD} A I N - ${M}${WSTD} E N U ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
echo -e "	(${YAY}1${WSTD}) ${STD}Deposit (${GRN}RECEIVE ${YAY}XMR${STD},${YAY} BTC${STD},${YAY} LTC${STD},${YAY} ETH${STD},${YAY} BCH${STD}, & ${YAY}100${STD}+${YAY} other coins${STD})${WSTD}"
echo -e "	(${YAY}2${WSTD}) ${STD}Withdraw (${GRN}SEND ${YAY}XMR${STD},${YAY} BTC${STD},${YAY} LTC${STD},${YAY} ETH${STD},${YAY} BCH${STD}, & ${YAY}100${STD}+${YAY} other coins${STD})${WSTD}"
echo -e "	(${YAY}3${WSTD}) ${STD}Exchange Menus (View previous transactions and current rates)${WSTD}" 
echo -e "	(${YAY}4${WSTD}) ${STD}Refresh wallet and view updated balance${WSTD}"
echo -e "	(${YAY}5${WSTD}) ${STD}Settings and Utilities ${WSTD}"
echo -e "	(${YAY}6${WSTD}) ${STD}Help and Additional Info${WSTD}" 
echo -e "	(${YAY}7${WSTD}) ${STD}Donate (${GRN}Help support this project${STD})${WSTD}"
echo -e "	(${YAY}8${WSTD}) ${STD}Quit${STD}"	
main_menu_options
}

main_menu_options() {
local choice
echo -n -e "
			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}8${STD}]:${YAY} "
read -r choice
    case $choice in
		1) deposit_selector ;;
		2) withdraw_selector ;;
		3) exchange_menu_selector ;;
		4) wallet_view_balance ;;
		5) settings_menu ;;
        6) help_menu ;;
        7) donation_menu ;;
		8) clean_all_exit ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && main_menu
	esac
}

deposit_selector(){
tx_option_selector deposit deposit "Or select XMR to create and view a new XMR recieving address for your Monero wallet" wallet_view_address 
}

withdraw_selector() {
tx_option_selector withdraw withdrawal "Or select XMR to send XMR directly from your Monero wallet" wallet_transfer
}

tx_option_selector() {
get_coins
coins_choice=$(zenity --list --height=300 --checklist --multiple --separator=" " --title="Select coin(s) to view anonymous $1 options" --text="Select coin(s) to view currently available $2 options from non-KYC exchanges.
 
$3:" --column="Select coin(s)" --column="Currently Supported Coins:" --column="Name" XMR XMR Monero $coins 2> /dev/null)
test -z "$coins_choice" && required_error "coin to $1"
if ! test "$coins_choice" = "XMR"; then
    comp_amount=$(zenity --entry --width=300 --title="Enter an estimated $2 amount for rate comparison." --text="Enter the amount you plan to deposit in $fiat, XMR, or any coin 
you selected, to view currently available $2 options for this amount.
 
Enter an amount followed the currency's ticker such as: 
100 $fiat, 4.20 XMR, .05 BTC, 600 BAT, 2 ETH, etc." 2> /dev/null)
    test -z "$comp_amount" && required_error "amount to compare $1 options"
    title      
    $(torsocks python3 ../../Scripts/MoneroMixer.py calc --amount $comp_amount --fiat $fiat --symbol $fiat_symbol --compare $coins_choice --type $1 > pydisplay) | $(zenity --progress --height=150 --width=300 --title="Finding best $2 options" --text="Ranking current options for $1ing $comp_amount..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
    cat pydisplay && shred -u pydisplay
    python_error_check
    read -r options < options-list 
    shred -u options-list
    option_data_in=$(zenity --list --height=250 --width=200 --title="Choose a $2 option" --text="Select a option from the list or press cancel
to go back to the main menu and try again:" --hide-column=1 --column="option" --column="Coin" --column="Exchange" $options 2> /dev/null)       
    test -z "$option_data_in" && main_menu
    old_IFS="$IFS" && IFS='|'
    read -ra option_data <<< ${option_data_in}
    IFS="$old_IFS"
    exchange="${option_data[0]}"
    coin="${option_data[1]}"

    $1 "${coin}"
else
    $4 
fi
}

exchange_menu_selector(){
menu_choice=$(zenity --list --hide-column=1 --title="Select an exchange to view its menu" --text="You will be able to view previous transactions, current rates, and create new transactions for the exchange you select." --column="choice" --column="Exchanges" xmrto_menu XMR.to godex_menu Godex.io morph_menu MorphToken 2> /dev/null)
test -z "$menu_choice" && main_menu  
$menu_choice
}

exchange_menu() {
title
echo -e "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "${top}"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"      	
echo -e "	${WSTD}Exchange Anonymously through your Monero Wallet:"
echo -e "	(${YAY}1${WSTD}) ${STD}Deposit $menu_coins${STD} => ${GRN}RECEIVE${YAY} XMR${STD} to your Wallet${WSTD}"
echo -e "	(${YAY}2${WSTD}) ${STD}Withdraw ${YAY}XMR${STD} from your Wallet${STD} => ${GRN}SEND ${YAY}$menu_coins${WSTD}
"
echo -e "	${WSTD}View Status of Previous Exchanges:"
echo -e "	(${YAY}3${WSTD}) ${STD}View Status of Most Recent ${WSTD}$exchange${STD} Deposit${WSTD}"
echo -e "	(${YAY}4${WSTD}) ${STD}View Status of Most Recent ${WSTD}$exchange${STD} Withdrawal${WSTD}"
echo -e "	(${YAY}5${WSTD}) ${STD}View Status of ANY Exchange from ${WSTD}$exchange${STD} Order ID${WSTD}
"
echo -e "	${WSTD}Check Current Exchange Rates:"
echo -e "	(${YAY}6${WSTD}) ${STD}Check Current ${WSTD}$exchange${STD} Deposit Rates${WSTD}"
echo -e "	(${YAY}7${WSTD}) ${STD}Check Current ${WSTD}$exchange${STD} Withdrawal Rates${WSTD}
"
echo -e "	(${YAY}8${WSTD}) ${STD}Return to Main Menu${STD}" 
exchange_menu_options
}

exchange_menu_options() {
local choice
echo -n -e "
			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}8${STD}]:${YAY} "
read -r choice
	case $choice in
		1) deposit ;;
        2) withdraw ;;
		3) type="deposit" && view_last ;;
        4) type="withdrawal" && view_last ;;
		5) view_id ;;
		6) deposit_rates ;;
        7) withdrawal_rates ;;
		8) main_menu ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}

#API SPECIFIC MENUS:        
godex_menu() {
previous_menu="godex_menu"
exchange="Godex.io"
abrev="godex"
top="~~~~~~~~~~~~~~~~~~~~~~~~~~ G O D E X . I O${WSTD} - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~"
menu_coins="${YAY}choice of 100${STD}+${YAY} Coins"
supported_coins=""
exchange_menu
}

morph_menu() {
previous_menu="morph_menu"
exchange="MorphToken"
abrev="morph"
top="~~~~~~~~~~~~~~~~~~~~~~~~ ${M} O R P H T O K E N${WSTD} - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~"
menu_coins="${YAY}BTC${STD}, ${YAY}LTC${STD}, ${YAY}ETH${STD}, ${YAY}BCH${STD}, or ${YAY}DASH${STD}"
supported_coins="BTC LTC ETH BCH DASH"    
exchange_menu
}


xmrto_menu() {
exchange="XMR.to"
previous_menu="xmrto_menu"
type="withdrawal"
abrev="xmrto"
title
echo -e "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~ X ${M} R . T O${WSTD} - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
echo -e "	${WSTD}Withdraw Anonymously from your Monero Wallet:"
echo -e "	(${YAY}1${WSTD}) ${STD}Withdraw/Send Anonymously (${WSTD}${YAY}XMR${WSTD} => ${YAY}EXACT BTC AMOUNT${STD})${WSTD}
"
echo -e "	${WSTD}View Status of Previous Withdrawals:"
echo -e "	(${YAY}2${WSTD}) ${STD}Check Status of Most Recent ${WSTD}XMR.to${STD} Withdrawal${WSTD}"
echo -e "	(${YAY}3${WSTD}) ${STD}Check Status of any Withdrawal from ${WSTD}XMR.to${STD} ID${WSTD}
"
echo -e "	${WSTD}Check Current Exchange Rates:"
echo -e "	(${YAY}4${WSTD}) ${STD}View Current ${WSTD}XMR.to${STD} Exchange Rates${WSTD}
"
echo -e "	(${YAY}5${WSTD}) ${STD}Return to Main Menu${STD}" 
xmrto_menu_options
}

xmrto_menu_options() {
local choice
echo -n -e "
			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}5${STD}]:${YAY} "
read -r choice
	case $choice in
		1) withdraw BTC ;;
		2) view_last ;;
		3) view_id ;;
        4) withdrawal_rates ;;
		5) main_menu ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}

settings_menu() {
previous_menu="settings_menu"
title
echo -e "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "~~~~~~~~~~~~~~~~ ${WSTD}S E T T I N G S / U T I L I T I E S - ${M}${WSTD} E N U ~~~~~~~~~~~~~~~~~"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
echo -e "	${WSTD}Settings:"
echo -e "	(${YAY}1${WSTD}) ${STD}Change Fiat Currency${WSTD}"
echo -e "	(${YAY}2${WSTD}) ${STD}Change Monero Daemon-Address${WSTD}"
echo -e "	(${YAY}3${WSTD}) ${STD}Change Transaction Priority Level${WSTD}
"
echo -e "	${WSTD}Utilities:"
echo -e "	(${YAY}4${WSTD}) ${STD}Decrypt Wallet Seed${WSTD}"
echo -e "	(${YAY}5${WSTD}) ${STD}Decrypt Deposit IDs${WSTD}"
echo -e "	(${YAY}6${WSTD}) ${STD}Decrypt Withdrawal IDs${WSTD}
"
 echo -e "	(${YAY}7${WSTD}) ${STD}Return to Main Menu${STD}" 
settings_menu_options
}

settings_menu_options() {
local choice
echo -n -e "
            Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}7${STD}]:${YAY} "
read -r choice
	case $choice in
        1) export_settings && ../Scripts/setup.sh set_fiat;;
		2) export_settings && ../Scripts/setup.sh set_daemon;;
        3) export_settings && ../Scripts/setup.sh set_priority;;
        # 4) clean_all_no_exit && ../../Scripts/setup.sh ;;
        4) decrypt_view_seed ;;
		5) decrypt_view_depositIDs ;;
		6) decrypt_view_withdrawalIDs ;;
		7) main_menu ;;
		*) printf "             ${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}

help_menu() {
previous_menu="help_menu"
title
echo -e "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~ ${WSTD}H E L P / I N F O - ${M}${WSTD} E N U ~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
echo -e "	(${YAY}1${WSTD}) ${STD}View Help${WSTD}"
echo -e "	(${YAY}2${WSTD}) ${STD}View Links for Additional Help${WSTD}"     
echo -e "	(${YAY}3${WSTD}) ${STD}View Advanced Info (Stuff for nerds)${WSTD}" 
echo -e "	(${YAY}4${WSTD}) ${STD}Return to Main Menu${STD}" 
help_menu_options
}

help_menu_options() {
local choice
echo -n -e "
            Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}4${STD}]:${YAY} "
read -r choice
	case $choice in
		1) show_help ;;
        2) help_links ;;  
		3) stuff_for_nerds ;;
		4) main_menu ;;
		*) printf "				      ${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

donation_menu() {
previous_menu="donation_menu"
title
echo -e "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"	
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~ D O N A T I O N - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
echo -e "${YAY}Thank you for considering donating a small amount of XMR to the community!
"
echo -e "	${WSTD}Who would you like to donate to?
"
echo -e "	(${YAY}1${WSTD}) ${STD}Donate to ${WSTD}Fungibility${M}atters${WSTD}"
echo -e "	(${YAY}2${WSTD}) ${STD}Donate to ${WSTD}Monero Core Team${WSTD}"
echo -e "	(${YAY}3${WSTD}) ${STD}Donate to ${WSTD}Thotbot${WSTD}
"
echo -e "	(${YAY}4${WSTD}) ${STD}Return to Main Menu without Donating :(${STD}" 
donation_menu_options
}

donation_menu_options() {
local choice
echo -n -e "
			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}4${STD}]:${YAY} "
read -r choice
	case $choice in
		1) donate_fungibilitymatters ;;
		2) donate_monero_core_team ;;
		3) donate_thotbot ;;
		4) main_menu ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}


#ENCRYPTION/DECRYPTION FUNCTIONS:

encrypt_file() {
test -e ${1} && openssl enc -aes-256-cbc -salt -in ${1} -out ${1}.enc -k ${password} $kdf_arg && shred -u ${1}
}

decrypt_file() {
test -e ${1}.enc && openssl enc -d -aes-256-cbc -salt -in ${1}.enc -out ${1} -k ${password} $kdf_arg && shred -u ${1}.enc
}

encrypt_balance() {
encrypt_file "balance" 
}
decrypt_balance() {
decrypt_file "balance" 
}
encrypt_address() {
encrypt_file "address" 
}
decrypt_address() {
decrypt_file "address" 
}
encrypt_withdrawalIDs() {
encrypt_file "withdrawalIDs" 
}
decrypt_withdrawalIDs() {
decrypt_file "withdrawalIDs" 
}
encrypt_depositIDs() {
encrypt_file "depositIDs" 
}
decrypt_depositIDs() {
decrypt_file "depositIDs" 
}

decrypt_view_depositIDs() {
pw_decrypt "depositIDs"
decrypt_depositIDs
tail -1 depositIDs | grep -m 15 "ID:" > view
title
echo -e "${WSTD}Your last 15 Deposit Order IDs: 
${STD}" 
cat view && encrypt_file "view"  && shred -u view.enc
echo -e -n "
${STD}Enter ${YAY}1${STD} to re-encrypt ${YAY}depositIDs${STD} and go back to previous menu
Or enter ${YAY}2${STD} to go back to previous menu ${WSTD}without${STD} re-encrypting:${YAY} "
read -r choice
	case $choice in
		1) encrypt_file "depositIDs" && settings_menu ;;
		2) settings_menu;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
settings_menu
}

decrypt_view_withdrawalIDs() {
pw_decrypt "withdrawalIDs"
decrypt_withdrawalIDs
tail -15 withdrawalIDs | grep -m 15 "ID:" > view
title
echo -e "${WSTD}Your last 15 Withdrawal Order IDs: 
${STD}" 
cat view && encrypt_file "view"  && shred -u view.enc
echo -e -n "
${STD}Enter ${YAY}1${STD} to re-encrypt ${YAY}withdrawalIDs${STD} and go back to previous menu
Or enter ${YAY}2${STD} to go back to previous menu ${WSTD}without${STD} re-encrypting:${YAY} "
read -r choice
	case $choice in
		1) encrypt_file "withdrawalIDs"  && settings_menu ;;
		2) settings_menu;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
settings_menu
}

decrypt_view_seed() {
seedfile="${name}-SEED"
pw_decrypt "${seedfile}" 
decrypt_file "${seedfile}"
title
echo -e "${WSTD}" && cat "${seedfile}"
echo -e -n "${STD}Enter ${YAY}1${STD} to re-encrypt ${YAY}${seedfile}${STD} and go back to previous menu
Or enter ${YAY}2${STD} to go back to previous menu ${WSTD}without${STD} re-encrypting:${YAY} "
read -r choice
	case $choice in
		1) encrypt_file "${seedfile}"  && settings_menu ;;
		2) settings_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
settings_menu
}

#CLEANING FUNCTIONS
clean_all() {
title
echo -e "${STD}Encrypting and shredding all data before exiting..."
test -e wallet-cli-out && shred -u wallet-cli-out 
test -e wallet-cli-out.enc && shred -u wallet-cli-out.enc
test -e error && shred -u error
test -e ../../Monero-Software/monero-wallet-cli.log && shred -u ../../Monero-Software/monero-wallet-cli.log
test -e qr && shred -u qr 
test -e qr.enc && shred -u qr.enc
test -e lastdeposit.enc && shred -u lastdeposit.enc
test -e lastdeposit && shred -u lastdeposit
test -e tx-out && shred -u tx-out 
test -e tx-out.enc && shred -u tx-out.enc
test -e extraid && shred -u extraid
test -e extraid.enc && shred -u extraid.enc
test -e d && shred -u d 
test -e d.enc && shred -u d.enc
test -e lastwithdrawal.enc && shred -u lastwithdrawal.enc
test -e lastwithdrawal && shred -u lastwithdrawal
test -e address && shred -u address 
test -e address.enc && shred -u address.enc
test -e balance && shred -u balance
test -e balance.enc && shred -u balance.enc
test -e withdrawalIDs && encrypt_withdrawalIDs
test -e depositIDs && encrypt_depositIDs
test -e fiat-prices && shred -u fiat-prices
test -e options-list && shred -u options-list 
test -e tickers && shred -u tickers
test -e coins-list && shred -u coins-list
test -e pydisplay && shred -u pydisplay
}

clean_all_exit() {
clean_all
cd ../
echo -e "
${GRN}Done. Your data is now secure.
"
exit
}

clean_all_no_exit() {
clean_all
cd ../
echo -e "
${GRN}Done. Your data is now secure.
"
}


#PASSWORD CHECKING FUNCTIONS
pw_error_check() {
$(echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command address > wallet-cli-out) | $(zenity --progress --height=150 --width=300 --title "Authenticating" --text="Authenticating your password..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
grep -q "invalid password" wallet-cli-out && shred -u "wallet-cli-out"  && pw_error_out
shred -u "wallet-cli-out" 
}

pw_error_out() {
echo -e -n "
${ERR}ERROR: The password you entered is not valid for wallet: ${YAY}$name${ERR}
 
YOU HAVE 1 MORE ATTEMPT BEFORE ALL DATA IS ENCRYPTED AND SHREDDED"
password=$(zenity --forms --icon-name='dialog-password' --title="ERROR: The password you entered is not valid for wallet: $name" --add-password="Password:" --text "YOU HAVE 1 MORE ATTEMPT BEFORE ALL DATA IS ENCRYPTED AND SHREDDED" 2> /dev/null)
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command address > wallet-cli-out
    grep -q "invalid password" wallet-cli-out && echo -e "
${ERR}INVALID PASSWORD
" && sleep 2 && clean_all_exit
shred -u "wallet-cli-out" 
}

pw_decrypt() {
title
unset -v password
echo -e "${ERR}To decrypt ${YAY}$1.enc${ERR} you must enter your password correctly.
"
password=$(zenity --forms --icon-name='dialog-password' --title="Enter your password to decrypt $1.enc" --add-password="Password:" --text "To decrypt $1.enc you must enter your password correctly." 2> /dev/null)
pw_error_check
}

#ERROR HANDLING FUNCTIONS:
required_error() {
zenity --error --icon-name='dialog-warning' --title="ERROR: No $1 entered" --text="A $1 is required. Try again." 2> /dev/null
$previous_menu
}

validation_error_check() {
test -e validation_error && read -ra error_type < validation_error 
test -e validation_error && shred -u validation_error && ${error_type[0]} "${error_type[1]}" "${error_type[2]}"
}

invalid_address(){
if ! zenity --question --icon-name='dialog-warning' --title="The $1 address you entered may not be a valid $2 address." --text="The $1 address you entered may not be a valid $2 address.
Do you want to continue anyway?" --ok-label="Continue anyway" 2> /dev/null
then 
    $previous_menu
fi 
}

segwit_address() {
if ! zenity --question --icon-name='dialog-warning' --title="$1 does not support segwit addresses." --text="$1 does not support segwit addresses. If you receive an error try again with a standard address instead. Do you want to continue with segwit address anyway?" \
--ok-label="Continue anyway" 2> /dev/null
then 
    $previous_menu
fi 
}

python_error_check() {
test -e error && python_error_out
}

python_error_out() {
deposit_data_cleanup
withdraw_data_cleanup
declare error_message    
readarray -n 2 -t error_message < error && shred -u error
zenity --error --title="${error_message[0]}" --text="${error_message[1]}" 2> /dev/null
$previous_menu
}

wallet_error_check() {
grep -q "wallet failed to connect to daemon" wallet-cli-out && daemon_error_out 
grep -q "Error" wallet-cli-out && wallet_error_out
}

wallet_error_out() {
title
echo -e "${ERR}Uh-oh it seems that an error has occurred :( 
(Don't worry your funds are safe)${STD} 

The error output is as follows:${ERR}" 
grep "Error" wallet-cli-out > wallet_error
read -r error < wallet_error && echo $error
test -e wallet-cli-out && shred -u wallet-cli-out 
test -e wallet_error && shred -u wallet_error
echo -e -n "
${WBU}TROUBLESHOOTING TIPS${STD}: 
If the error is due to not enough unlocked balance in your wallet, first make 
sure that your balance is unlocked, if not refresh your wallet ${WSTD}(menu option ${YAY}3${WSTD}). 

${WSTD}If your balance is unlocked try sending a slightly smaller amount.${STD}
"
zenity --error --icon-name='dialog-warning' --title="$error" --text="Uh-oh it seems that an error has occurred :( 
(Don't worry your funds are safe)

The error output is as follows:
$error" 2> /dev/null
$previous_menu  
}

daemon_error_out() {
title
echo -e "${ERR}Uh-oh it seems that your wallet cannot connect to a Monero daemon :( 
(Don't worry your funds are safe)${STD} 

The error output is as follows:${ERR}" 
grep "Error" wallet-cli-out > wallet_error
read -r error < wallet_error && echo $error
test -e wallet-cli-out && shred -u wallet-cli-out 
test -e wallet_error && shred -u wallet_error
echo -e "
${WBU}Select another daemon-host or quit and try again later" 
if zenity --question --icon-name='dialog-warning' --title="$error" --text="Uh-oh it seems that your wallet cannot connect to a Monero daemon :( 

Would you like to try connecting to another daemon-host?" --ok-label="Choose another daemon-host" --cancel-label "Quit and try again later" 2> /dev/null; then 
    export_settings 
    ../Scripts/setup.sh set_daemon
else
    clean_all_exit
fi 
}

#WALLET FUNCTIONS:
set_noconf() {  
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command set always-confirm-transfers 0 > wallet-cli-out
}
unset_noconf() { 
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command set always-confirm-transfers 1 > wallet-cli-out
}
set_noask() {  
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command set ask-password 0 > wallet-cli-out 
}
unset_noask() { 
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command set ask-password 2 > wallet-cli-out 
}
set_noauto() {  
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command set auto-refresh 0 > wallet-cli-out
}
unset_noauto() {  
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command set auto-refresh 0 > wallet-cli-out
}


wallet_config() {
dialog_title="Create a new Monero Wallet"  
cd Wallets && dialog_title="Login to your Monero Wallet" || mkdir Wallets && mv settings Wallets/settings && cd Wallets

title
echo -e "To begin enter a ${YAY}name${STD} and ${YAY}password${STD} for your Monero wallet. [${ERR}BOTH 1 WORD MAX${STD}] 
"
 echo -e "${WSTD}If you have used $MoneroMixer${WSTD} before, use the SAME name and password
you used previously to access any remaining ${YAY}XMR${WSTD} in your wallet.${STD}
"
old_IFS="$IFS" && IFS='|'
credentials_in=$(zenity --icon-name='dialog-password' --forms --text="To begin enter a name and password for your Monero Wallet" --add-entry="Wallet name:" --add-password="Password:" --title "${dialog_title}" --timeout 120 2> /dev/null)
test -z "$credentials_in" && clean_all_exit
test "$credentials_in" = "|" && clean_all_exit 
read -ra credentials <<< ${credentials_in}
name="${credentials[0]}"
password="${credentials[1]}"
IFS="$old_IFS"
    
test -d $name || mkdir $name
cd $name || clean_all_exit
test -e ../settings && mv ../settings settings
test -e settings && read_settings
test -e settings || ../../Scripts/setup.sh    

pw_error_check
test -e "${name}.keys" || gen_wallet_and_seed_file

title
echo -e -n "${YAY}Opening your Monero wallet...${STD}

${ERR}(This may take some time. Please wait.)${STD}

If you receive an error message such as:${WSTD} 
'1557855698 ERROR torsocks[21439]: 
Connection timed out (in socks5_recv_connect_reply() at socks5.c:553)'

${STD}Press ${YAY}CTRL-C${STD} to exit. Check your network and tor connections then try again."
set_noauto | $(zenity --progress --height=150 --width=300 --title="Opening wallet" --text="Opening wallet: $name..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
title
test -e wallet-cli-out && shred -u wallet-cli-out
echo -e "
${STD}Opened Wallet file: $name...${STD}
" 
wallet_refresh
echo -e "${STD}Loading your Updated Monero wallet balance...${STD}" 
update_balance
echo -e "
${GRN}Success! Your Monero Wallet is correctly setup and ready to send and receive ${YAY}XMR${STD}
" && sleep 1
}

update_balance() {
$(torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command balance > wallet-cli-out) | $(zenity --progress --height=150 --width=300 --title="Updating balance" --text="Updating your Monero wallet balance..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null) 
grep "Balance:" wallet-cli-out > balance
encrypt_balance
shred -u wallet-cli-out
}

update_address() {
$(torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command address new > wallet-cli-out) | $(zenity --progress --height=150 --width=300 --title="Updating address" --text="Updating your Monero recieving address..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
grep "address)" wallet-cli-out > address 
encrypt_address 
shred -u wallet-cli-out
}


gen_wallet_and_seed_file() {
title
echo -e "
${STD}Wallet name set to: '${YAY}$name${STD}'
"
echo -e "${STD}Wallet password set to: '${YAY}${password}${STD}'
"
echo -e "${ERR}Record your wallet name and password somewhere safe.
 ${STD}"

echo -e -n "${YAY}Generating your Monero wallet...${STD}"

$(echo "n
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --generate-new-wallet $name --password $password --mnemonic-language English > wallet-cli-out) | $(zenity --progress --height=150 --width=300 --title="Generating your Monero wallet" --text="Generating wallet: $name..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
wallet_error_check

declare array seed
readarray -n 24 seed < wallet-cli-out
shred -u wallet-cli-out

title
echo -e "${GRN}A new Monero wallet named ${YAY}$name${GRN} has been created!

${WSTD}The following mnemonic seed was used to generate: ${YAY}$name${STD}
*********************************************************************
${WBU}${seed[20]}${seed[21]}${seed[22]}${STD}
*********************************************************************

${ERR}IMPORTANT: These 25 words can be used to recover access to your wallet.
Write them down VERY carefully and store them somewhere safe and secure.${STD}
"

seedfile="${name}-SEED"
echo -e -n "Enter ${YAY}1${STD} to save an encrypted backup of your seed as ${YAY}${seedfile}.enc${STD}  
Or enter ${YAY}2${STD} to continue ${WSTD}without${STD} creating an encrypted backup file:${YAY} "

read -r choice
	case $choice in
		1) backup_seed ;;
		2) conf_no_backup ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

backup_seed() {
echo "${name} mnemonic seed:
*********************************************************************
${seed[20]}${seed[21]}${seed[22]}
*********************************************************************
IMPORTANT: these 25 words can be used to recover access to your wallet. 
Write them down and store them somewhere safe and secure.
 
DO NOT store this file in your email or on file storage services outside of 
your immediate control. You should store your seed in a file system that 
ONLY you can access such as your persistent volume or an encrypted flash drive. 
" > ${seedfile}
encrypt_file "${seedfile}" 
title
echo -e "
${WSTD}Encrypted mnemonic seed saved as ${YAY}${seedfile}.enc${WSTD} to folder '${STD}$name${WSTD}'

${ERR}NOTE: ${YAY}${seedfile}.enc${ERR} is encrypted so you will not be able to read it 
unless you decrypt it via the Settings and Utilities Menu by choosing 
option ${YAY}4${ERR} ""Decrypt Wallet Seed""
" 
got_it
}

conf_no_backup() {
title
echo -e "${ERR}Are you sure you want to continue without backing up your seed?${WSTD}

After this $MoneroMixer${WSTD} will ${ERR}NEVER${WSTD} be able to display or save your seed again.

${ERR}You should only continue if you have written it down somewhere safe and secure.
"
echo -e -n "${STD}Enter ${YAY}1${STD} to save a backup of your seed as ${YAY}$seedfile.enc${STD} 
Or enter ${YAY}2${STD} to confirm that you have actually written it down:${YAY} "
read -r choice
	case $choice in
		1) backup_seed ;;
		2) sleep 1 ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

wallet_refresh() {
title
echo -e "Refreshing your wallet and resynchronizing it with the Monero blockchain...

${ERR}(This may take some time. Please wait.)${WSTD}" 
    $(echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command refresh  > wallet-cli-out) | $(zenity --progress --title "Refreshing your wallet" --text="Refreshing your wallet and resynchronizing it with the Monero blockchain..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null) 
title
wallet_error_check
test -e wallet-cli-out && shred -u wallet-cli-out
}


wallet_view_balance() { 
title
wallet_refresh
echo -e "${YAY}Loading your Updated Monero wallet balance...${STD}
" 
update_balance
print_balance "--type full"
back_to_previous
}

print_balance(){
$(torsocks python3 ../../Scripts/MoneroMixer.py prices --fiat $fiat --update 60) | $(zenity --progress --title "Loading current rates" --text="Loading current XMR exchange rates..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
decrypt_balance  
torsocks python3 ../../Scripts/MoneroMixer.py balance --fiat $fiat --symbol $fiat_symbol $1
encrypt_balance
}


wallet_transfer() { 
title
update_balance
print_balance

old_IFS="$IFS" && IFS='|'
tx_data_in=$(zenity --forms --text="Enter Destination Address and Exact XMR Amount to send" --add-entry="Destination Address where XMR will be sent:" --add-entry="Exact XMR Amount to send:" --title "Enter Destination Address and XMR Amount" --timeout 120 2> /dev/null)
test -z "$tx_data_in" && $previous_menu
test "$tx_data_in" = "|" && clean_all_exit 
read -ra tx_data <<< ${tx_data_in}
IFS="$old_IFS"
xmr_address="${tx_data[0]}"
xmr_amount="${tx_data[1]}"

test -z "$xmr_address" && required_error "XMR destination address"
test -z "$xmr_amount" && required_error "XMR amount to send"
    
torsocks python3 ../../Scripts/MoneroMixer.py validate --address $address --coin XMR --type destination
validation_error_check
    
title
echo -e "${STD}You are about to send ${WBU}$xmr_amount${YAY} XMR${STD} to wallet address:
${YAY}$xmr_address. 
"
if zenity --question --title="Confirm withdrawal" \
--text="You are about to send $xmr_amount XMR to wallet address:
$xmr_address. " --ok-label="Confirm and proceed with withdrawal" --cancel-label="Cancel" 2> /dev/null
then         
    exchange="$xmr_address" 
    wallet_withdraw_confirmed
else
    $previous_menu
fi 
}

wallet_view_address() {
title
    echo -e "${STD}Generating new ${YAY}XMR${STD} receiving subaddress...${STD}"
    update_address
    decrypt_address
    torsocks python3 ../../Scripts/MoneroMixer.py address
    encrypt_address
back_to_previous
}

wallet_cli() {
title 
echo -e "You are now leaving ${MoneroMixer} and entering the Monero Wallet CLI..."
sleep 3
echo -e "\033[00;${FG};49mSETTING BACKGROUND COLORS TO WHITE...                   "
clear
clear
torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password
}

wallet_withdraw() {
title
echo -e "${STD}As after you confirm this withdrawal, ${WBU}$xmr_amount ${YAY}XMR${STD} 
will be transferred from your Monero Wallet to ${WSTD}$exchange${STD}.

${WSTD}Once ${STD}$exchange${WSTD} receives the transfer, ${WBU}$coin_amount ${YAY}$coin_out ${WSTD}will be sent ${STD}anonymously
${WSTD}to: ${YAY}$dest_address${STD} 
"
if zenity --question --title="Confirm withdrawal" --text="As after you confirm this withdrawal, $xmr_amount XMR will be transferred from your Monero Wallet to $exchange.

Once $exchange receives the transfer, $coin_amount $coin_out will be sent anonymously to: $dest_address " \
--ok-label="Confirm and proceed with withdrawal" --cancel-label="Cancel" 2> /dev/null
then 
    unset -v coin_amount dest_address && wallet_withdraw_confirmed
else
    unset -v coin_amount dest_address xmr_amount xmr_address && test -e d && shred -u d && $previous_menu || $previous_menu
fi 
}

wallet_withdraw_confirmed() {
title 
echo -e "${YAY}Your anonymous withdrawal is processing! 

${ERR}(This will take some time please wait.)${STD}"
echo -e "
Refreshing your wallet and resynchronizing it with the Monero blockchain...${STD}"
#unset_noauto
$(echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command refresh > wallet-cli-out) | $(zenity --progress --title "Refreshing your wallet" --text="Refreshing your wallet and resynchronizing it with the Monero blockchain..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null) 
wallet_error_check

echo -e "
Sending ${WBU}$xmr_amount ${YAY}XMR${STD} to ${WSTD}$exchange${STD}...
${GRN}"
set_noconf
$(echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --no-dns --daemon-address $daemon --wallet-file $name --password $password --command transfer $priority $ringsize $xmr_address $xmr_amount > wallet-cli-out ) | $(zenity --progress --title "Sending your transaction" --text="Sending $xmr_amount to $exchange..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null) 
unset -v xmr_amount xmr_address
grep "Transaction" wallet-cli-out
wallet_error_check
unset_noconf

echo -e "
${STD}Updating your ${YAY}XMR${STD} balance..."
set_noauto
update_balance
test -e wallet-cli-out && shred -u wallet-cli-out
}


withdraw_data_setup() {
decrypt_address 
decrypt_balance
test -e extraid.enc && decrypt_file "extraid" 
test -e withdrawalIDs.enc && decrypt_withdrawalIDs
}


withdraw_data_in(){
declare data_line
test -e tx-out && readarray -n 1 data_line < tx-out
test -e tx-out && shred -u tx-out
read -ra data <<< ${data_line[0]}
xmr_amount=${data[0]}
xmr_address=${data[1]}
coin_amount=${data[2]}    
dest_address=${data[3]}
withdraw_data_cleanup
}

withdraw_data_cleanup() {
encrypt_address 
encrypt_balance
encrypt_withdrawalIDs
test -e extraid && shred -u extraid
test -e wallet-cli-out && shred -u wallet-cli-out 
test -e lastwithdrawal.enc && shred -u lastwithdrawal.enc
test -e lastwithdrawal && shred -u lastwithdrawal
}


withdraw_warning() {
title
echo -e "${ERR}IMPORTANT: This method can leave you vulnerable to timing based blockchain 
analysis if you are not careful. It is important that the amount deposited via 
Morphtoken or Godex.io (STEP 1) and the amount of withdrawn by XMR.to, Godex.io 
or Morphtoken (STEP 2) DO NOT correlate within a small time span.${STD}

If you just completed a deposit via ${WSTD}Godex.io${STD} or ${WSTD}MorphToken${STD} you should 
wait a couple hours before continuing for maximum security and privacy.
 
${STD}If it has not been at least 1 hour since your last deposit you should press 
cancel to exit now and come back later.
"

if ! zenity --question --title="IMPORTANT: Read this if you care about your privacy" --text="IMPORTANT: This method can leave you vulnerable to timing based blockchain analysis if you are not careful. It is important that the amount deposited via Morphtoken or Godex.io (STEP 1) and the amount of withdrawn by XMR.to, Godex.io or Morphtoken (STEP 2) DO NOT correlate within a small time span.

If you just completed a deposit via Godex.io or MorphToken you should wait a couple hours before continuing for maximum security and privacy.
 
If it has not been at least 1 hour since your last deposit you should press cancel to exit now and come back later." --cancel-label="Cancel and exit securely" --ok-label="Continue with withdrawal" 2> /dev/null
then 
    clean_all_exit
else
    title
fi 
}

#WITHDRAWAL FUNCTIONS:
withdraw() {
withdraw_warning
echo -e "${STD}NOTE: To cancel withdrawal and exit press 'CTRL-C' at any time
"
if test -z $1; 
then 
    print_title '~' "${WBU}WITHDRAW${STD}: Convert ${YAY}XMR${STD} to your preferred coin via ${WSTD}$exchange${STD}" "WITHDRAW: Convert XMR to your preferred coin via $exchange"
    coins="BTC Bitcoin LTC Litecoin ETH Ethereum BCH Bitcoin-Cash DASH Dash"
    test "$exchange" = "Godex.io" && godex_get_coins
    printf "\nSupported coins: "
    for coin in ${supported_coins[@]}
    do 
        printf "${YAY}%s${STD}, " $coin
    done
    printf "\n"
    coin_out=$(zenity --list --title="Select a coin to withdraw anonymously" --text "Select the coin you would like to withdraw/send anonymously:" --column="Currently Supported Coins:" --column="Name" $coins 2> /dev/null)
else
    coin_out="$1"
    test "$exchange" = "XMR.to" && abrev="xmrto"
    test "$exchange" = "Godex.io" && abrev="godex"
    test "$exchange" = "MorphToken" && abrev="morph"
fi

test -z "$coin_out" && required_error "coin to withdraw/send"
title        
print_title '~' "${WBU}WITHDRAW${STD}: Convert ${YAY}XMR${STD} to ${YAY}$coin_out${STD} via ${WSTD}$exchange${STD}" "WITHDRAW: Convert XMR to $coin_out via $exchange" 
printf '\n'
coin_in="XMR"
decrypt_balance 
$(torsocks python3 ../../Scripts/MoneroMixer.py rates --exchange $exchange --cin $coin_in --out $coin_out> pydisplay) | $(zenity --progress --height=150 --width=300 --title="Fetching $coin_in to $coin_out rates" --text="Securely fetching latest $coin_in to $coin_out rates from $exchange..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
encrypt_balance
cat pydisplay && shred -u pydisplay
python_error_check

amount_coin="XMR"
test "$exchange" = "XMR.to" && amount_coin="BTC"

old_IFS="$IFS" && IFS='|'
tx_data_in=$(zenity --forms --text="Enter $coin_out Destination Address and $amount_coin Amount to Withdraw" --add-entry="Destination Address where $coin_out will be sent:" --add-entry="Exact $amount_coin Amount to Withdraw Anonymously:" --title "Enter $coin_out Destination Address and $amount_coin Amount" 2> /dev/null)
test -z "$tx_data_in" && $previous_menu
test "$tx_data_in" = "|" && clean_all_exit 
read -ra tx_data <<< ${tx_data_in}
IFS="$old_IFS"

dest_address="${tx_data[0]}"
amount="${tx_data[1]}"
test -z "$dest_address" && required_error "$coin_out destination address"
test -z "$amount" && required_error "$amount_coin amount to send"

torsocks python3 ../../Scripts/MoneroMixer.py validate --address $dest_address --coin $coin_out --type destination --exchange $exchange
test "$exchange" = "Godex.io" && godex_check_extra_id $coin_out destination 
validation_error_check

if ! test "$exchange" = "XMR.to"; 
then     
    title
    echo -e "${STD}Generating new ${YAY}XMR${STD} receiving subaddress to use as the refund address...${STD}"
    update_address
fi
    
title
withdraw_data_setup
torsocks python3 ../../Scripts/MoneroMixer.py withdraw --exchange $exchange --out $coin_out --amount $amount --dest $dest_address
unset -v amount dest_address
withdraw_data_in
python_error_check
sleep 2
wallet_withdraw
type="withdrawal"
view_last
}

#DEPOSIT FUNCTIONS:
deposit_data_setup() {
decrypt_balance 
decrypt_address
test -e extraid.enc && decrypt_file "extraid" 
test -e depositIDs.enc && decrypt_depositIDs
}

deposit_data_cleanup() {
encrypt_balance 
encrypt_address 
encrypt_depositIDs
test -e extraid && shred -u extraid
test -e extraid.enc && shred -u extraid.enc
test -e qr.enc && shred -u qr.enc
test -e wallet-cli-out.enc && shred -u wallet-cli-out.enc
test -e lastdeposit.enc && shred -u lastdeposit.enc
test -e lastdeposit && shred -u lastdeposit
}

deposit() {       
if test -z $1; 
then 
    title
    echo -e "${STD}NOTE: To cancel deposit and exit press 'CTRL-C' at any time${STD}
"
    print_title '~' "${WBU}DEPOSIT${STD}: Convert your coins to ${YAY}XMR${STD} via ${WSTD}$exchange${STD}" "DEPOSIT: Convert your coins to XMR via $exchange"
    coins="BTC Bitcoin LTC Litecoin ETH Ethereum BCH Bitcoin-Cash DASH Dash"
    test "$exchange" = "Godex.io" && godex_get_coins
    printf "\nSupported coins: "
    for coin in ${supported_coins[@]}
    do 
        printf "${YAY}%s${STD}, " $coin
    done
    printf "\n"
       
    coin_in=$(zenity --list --title="Select a coin to deposit" --text "Select the coin you would like to convert to XMR and deposit to your wallet" --column="Currently Supported Coins:" --column="Name" $coins 2> /dev/null)
else
    coin_in="$1"
fi
test -z "$coin_in" && required_error "coin to deposit/receive"

title
echo -e "${STD}NOTE: To cancel deposit and exit press 'CTRL-C' at any time${STD}
"
print_title '~' "${WBU}DEPOSIT${STD}: Convert ${YAY}$coin_in${STD} to ${YAY}XMR${STD} via ${WSTD}$exchange${STD}-" "DEPOSIT: Convert $coin_in to XMR via $exchange-"
echo -e "
${WSTD}It is STRONGLY RECOMMENDED that you enter a refund address to ensure that your 
coins are not lost if you any errors occur.


${ERR}IMPORTANT: DO NOT USE A REFUND ADDRESS ASSOCIATED WITH YOUR IDENTITY
Doing so could compromise the anonymity of this Monero Wallet.${STD}"

refund_address=$(zenity --entry --title="Enter $coin_in refund address" --text="Enter a $coin_in refund address to send refund if any errors occur or press 'Cancel' to continue without a refund address:" 2> /dev/null) 
test -z $refund_address && refund_address="None"

torsocks python3 ../../Scripts/MoneroMixer.py validate --address $refund_address --coin $coin_in --type refund --exchange $exchange
validation_error_check
test "$exchange" = "Godex.io" && godex_check_extra_id $coin_in refund   
    
title
coin_out="XMR"
if test "$exchange" = "Godex.io";
then 
    $(torsocks python3 ../../Scripts/MoneroMixer.py rates --exchange $exchange --cin $coin_in --out $coin_out> pydisplay) |  $(zenity --progress --height=150 --width=300 --title="Fetching $coin_in to $coin_out rates" --text="Securely fetching latest $coin_in to $coin_out rates from $exchange..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
    encrypt_balance
    cat pydisplay && shred -u pydisplay
    python_error_check
    echo -e -n "${WSTD}Godex.io REQUIRES that you enter an estimate of the amount you plan to deposit.
"
    amount=$(zenity --entry --title="Enter Estimated $coin_in deposit amount" --text="Enter estimated amount you plan to deposit in $coin_in:" 2> /dev/null)
    test -z "$amount" && required_error "estimated $coin_in deposit amount"
else
    amount="n/a"
fi

title
echo -e "${STD}Generating new ${YAY}XMR${STD} receiving subaddress for this deposit...${STD}"
update_address    

title
deposit_data_setup
torsocks python3 ../../Scripts/MoneroMixer.py deposit --exchange $exchange --cin $coin_in --amount $amount --refund $refund_address
unset -v amount refund_address
deposit_data_cleanup
python_error_check
sleep 3
type="deposit"
view_last
}


#VIEW PREVIOUS TRANSACTIONS:
view_last() {
idfile="${type}IDs"
lastfile="last${type}"   

decrypt_${type}IDs
tail -1 $idfile | grep -m 1 "${exchange}" > $lastfile
encrypt_${type}IDs
encrypt_file "${lastfile}" 
display_last_${type}
}

display_last_withdrawal() {
title
decrypt_file "${lastfile}" 
torsocks python3 ../../Scripts/MoneroMixer.py view --exchange ${exchange} --type ${type}
encrypt_file "${lastfile}" 
python_error_check

local choice
echo -n -e "
		${WSTD}Enter ${YAY}1${WSTD} to REFRESH or ${YAY}2${WSTD} to return to menu:${YAY} "
read -r choice
	case $choice in
		1) display_last_withdrawal ;;
		2) shred -u ${lastfile}.enc && test -e d && ${abrev}_donation || $previous_menu ;;
		*) printf "		${ERR}Invalid Choice...${STD}" && sleep 2 && display_last_withdrawal
	esac 
}

display_last_deposit() {
title
decrypt_file "${lastfile}" 
torsocks python3 ../../Scripts/MoneroMixer.py view --exchange ${exchange} --type ${type}
encrypt_file "${lastfile}" 
encrypt_file "qr" 
python_error_check

local choice
echo -n -e "
    ${WSTD}Enter ${YAY}1${WSTD} to REFRESH, ${YAY}2${WSTD} to view a ${STD}QRCode${WSTD} of this deposit address 
    for easy scanning or ${YAY}3${WSTD} to return to menu:${YAY} "
read -r choice
	case $choice in
		1) display_last_deposit ;;
        2) display_qrcode ;;
		3) shred -u qr.enc && shred -u ${lastfile}.enc && test -e d && ${abrev}_donation || $previous_menu ;;
		*) printf "		${ERR}Invalid Choice...${STD}" && sleep 2 && display_last_deposit
	esac
}

display_qrcode() {
title
echo -e "${WSTD}Here is a ${STD}QRCode${WSTD} containing your most recent ${YAY}$coin_in${WSTD} deposit address:"
decrypt_file "qr" 
torsocks python3 ../../Scripts/MoneroMixer.py qrcode
encrypt_file "qr" 

local choice
echo -n -e "
		${WSTD}Enter ${YAY}1${WSTD} to REFRESH trade, or ${YAY}2${WSTD} to return to menu:${YAY} "
read -r choice
	case $choice in
		1) display_last_deposit ;;
		2) shred -u qr.enc && shred -u ${lastfile}.enc && test -e d && ${abrev}_donation || $previous_menu ;;
		*) printf "		${ERR}Invalid Choice...${STD}" && sleep 2 && display_qrcode
	esac
}

view_id() {
title
declare ids
echo -e "${WBU}NOTE: You can view the order IDs of all your previous deposits or withdrawals
in the files named: ${YAY}depositIDs.enc${WBU} and ${YAY}withdrawalIDs.enc${WBU} respectively.${WSTD}

To open these files you must decrypt them via the Settings and Utilities Menu"
orderid=$(zenity --entry --title="Enter $exchange Order ID" --text="Enter $exchange Order ID to view order status:" 2> /dev/null)
test -z $orderid && required_error "$exchange order ID"
view
}

view() {
title
torsocks python3 ../../Scripts/MoneroMixer.py view --exchange $exchange --id ${orderid}
python_error_check

local choice
echo -n -e "
		${WSTD}Enter ${YAY}1${WSTD} to REFRESH or ${YAY}2${WSTD} to return to menu:${YAY} "
read -r choice
	case $choice in
		1) view ;;
        2) $previous_menu ;;
		*) printf "		${ERR}Invalid Choice...${STD}" && sleep 2 && view
	esac 
}

#QUERY AN VIEW EXCHANGE RATES
deposit_rates() {
if test "$exchange" = "Godex.io"; then
    godex_get_coins  
else
    coins="BTC Bitcoin LTC Litecoin ETH Ethereum BCH Bitcoin-Cash DASH Dash"
fi
coin_in=$(zenity --list --title="Select a Coin to view deposit rates" --text "Select the coin you would like to view deposit rates for:" --column="Currently Supported Coins:" --column="Name" ${coins} 2> /dev/null)
test -z "$coin_in" && $previous_menu    
coin_out="XMR"
display_rates
}

withdrawal_rates() {
if ! test "$exchange" = "XMR.to"; then
    if test "$exchange" = "Godex.io"; then
        godex_get_coins  
    else
        coins="BTC Bitcoin LTC Litecoin ETH Ethereum BCH Bitcoin-Cash DASH Dash"
    fi
    coin_out=$(zenity --list --title="Select a Coin to view withdrawal rates" --text "Select the coin you would like to view withdrawal rates for:" --column="Currently Supported Coins:" --column="Name" ${coins} 2> /dev/null)
else
    coin_out="BTC"
fi
test -z "$coin_out" && $previous_menu 
coin_in="XMR"
display_rates
}

display_rates() {
title
decrypt_balance
torsocks python3 ../../Scripts/MoneroMixer.py rates --exchange $exchange --cin $coin_in --out $coin_out
encrypt_balance
python_error_check

local choice
echo -n -e "
		${WSTD}Enter ${YAY}1${WSTD} to REFRESH rates or ${YAY}2${WSTD} to return to menu:${YAY} "
read -r choice
	case $choice in
		1) display_rates ;; #$last_rates && godex_rates ;;
		2) $previous_menu;;
		*) printf "	        ${ERR}Invalid Choice...${STD}" && sleep 2 && godex_rates
	esac
}


get_coins() {
$(torsocks python3 ../../Scripts/MoneroMixer.py coins --out checklist > coins-list) | $(zenity --progress --height=150 --width=300 --title="Fetching list of available coins" --text="Fetching list of currently available coins..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
read -r coins < coins-list && shred -u coins-list
}

godex_get_coins() {
$(torsocks python3 ../../Scripts/MoneroMixer.py coins --out tickers > coins-list) | $(zenity --progress --height=150 --width=300 --title="Fetching list of available coins from Godex.io" --text="Fetching list of currently available coins from Godex.io..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
read -r coins < coins-list && shred -u coins-list
read -ra supported_coins < tickers && shred -u tickers
}

get_tickers() {
$(torsocks python3 ../../Scripts/MoneroMixer.py coins --out tickers > godex_coins) | $(zenity --progress --height=150 --width=300 --title="Fetching list of available coins" --text="Fetching list of currently available coins from Godex.io..." --pulsate --auto-close --auto-kill --no-cancel 2> /dev/null)
read -r coins < coins-list && shred -u coins-list
}

godex_check_extra_id(){
test -e extraid_name && read -r extra_id_name < extraid_name 
test -e extraid_name && extra_id=$(zenity --entry --title="$1 $extra_id_name may be required." --text="The $1 $2 address you entered may require a $extra_id_name for transaction processing.

Enter $1 $extra_id_name or press 'Cancel' to continue without a $1 $extra_id_name" 2> /dev/null) && echo "$extra_id" > extraid
unset -v extra_id_name extra_id
test -e extraid_name && shred -u extraid_name      
test -e extraid && encrypt_file "extraid" 
}

#SETTINGS FUNCTIONS
parse_setting() {
read -ra parsed <<< ${settings[$1]}
echo "${parsed[$2]}"
}

read_settings() {
declare settings
readarray -n 6 -t settings < settings
daemon=$(parse_setting 0 3) #"${settings[0]}"
ringsize=$(parse_setting 1 3) #"${settings[1]}"
priority=$(parse_setting 2 3) #"${settings[2]}"
fiat=$(parse_setting 3 3) #"${settings[3]}"
fiat_symbol=$(parse_setting 4 3) #"${settings[4]}"
kdf_arg="${settings[5]}"
}

export_settings(){
export daemon
export ringsize
export priority
export fiat
export fiat_symbol
export kdf_arg
clean_all_no_exit
}


#HELP FUNCTIONS:
show_help() {
title
echo -e "${YAY}ONLY 2 STEPS ARE REQUIRED${STD} to spend your crypto anonymously with ${MoneroMixer}${WSTD}:"
echo -e "(For this ${STD}example${WSTD} imagine you wanted to use ${YAY}LTC${WSTD} to send a private ${YAY}BTC${WSTD} payment)
"  
echo -e "${STD}STEP ${STD}1${STD} (${WSTD}Deposit${STD}): ${WSTD}Convert your ${YAY}LTC${WSTD} to ${YAY}XMR${WSTD} via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} 
${STD}STEP ${STD}2${STD} (${WSTD}Withdraw${STD}): ${WSTD}Convert ${YAY}XMR${WSTD} back to ${YAY}BTC${WSTD} via ${STD}XMR.to${WSTD} to send exact ${YAY}BTC${WSTD} amount. 
(Or withdraw via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} to send ${YAY}100${STD}+${WSTD} other coins.) "
    echo -e "
${WSTD}All ${STD}you will need ${WSTD}to provide is:${STD}
1. ${YAY}Refund Address${STD} to send coins back to if any errors occur during your deposits
2. ${YAY}Destination Address${STD} where each withdrawal should be sent.
"
got_it  
echo -e "${ERR}IMPORTANT: Between steps 1 and 2 you will need to wait a few hours in 
order to prevent timing based blockchain analysis.${STD}"
echo -e "
${STD}While waiting you can view the status of your most recent deposits or 
withdrawals from the corresponding menus. 
${STD}
${STD}Make sure you ${WBU}read the instructions carefully${STD} and follow the prompts.${STD}
"
back_to_previous
}

help_links() {
title
echo -e -n "${WSTD}Here's a collection of links to reference material and user guides
in case you get stuck or just want to learn more about Monero${STD}:
${WSTD}FAQs${STD}:
Official Monero Website: ${LSTD}https://www.getmonero.org/
${STD}MorphToken FAQ: ${LSTD}https://www.morphtoken.com/faq/ 
${STD}MorphToken API docs: ${LSTD}https://www.morphtoken.com/api/
${STD}XMR.to FAQ: ${LSTD}http://xmrto2bturnore26.onion/nojs/#faq
${STD}XMR.to API docs: ${LSTD}https://xmrto-api.readthedocs.io/en/latest/
${WSTD}Guides${STD}:  
${STD}Official Monero User Guides: ${LSTD}https://www.getmonero.org/resources/user-guides/
${STD}Official Monero Wallet CLI Guide: ${LSTD}https://web.getmonero.org/resources/user-guides/monero-wallet-cli.html
${STD}Reddit Noob Guide: ${LSTD}https://www.reddit.com/r/Monero/comments/80ucva/best_tails_os_tutorial_for_newbies_for_monero_cli/
${STD}Reddit Easy Guide: ${LSTD}https://www.reddit.com/r/Monero/comments/5e3zfz/easy_guide_to_monerotailstor/ 
${STD}My personal favorite Wallet CLI Guide: ${LSTD}http://xmrguide42y34onq.onion/tails/cli
"
back_to_previous
}

stuff_for_nerds() {
title
echo -e "${YAY}Stuff for nerds:${STD}"
echo -e -n "MoneroMixer works in conjunction with the Official Monero CLI to ensure 
that you are always using the latest and most secure Monero wallet interface 
available. Your MoneroMixer wallet will be automatically configured to 
synchronize with a trusted Monero .onion remote node and it will use a 
daemon-address connection at port 18081 so that you don't have to wait hours 
downloading the full ~80+GB blockchain like a traditional Monero wallet requires 
Every monero-wallet-cli command and API request from the Python script is
executed through a torsocksified connection so there is not a pattern amoung 
among the IP addresses your wallet has used. Lastly, all working files and
transaction history are 256 bit encrypted immediately after use or exiting.  
The default tor wrapping protocol is: ${WSTD}torsocks${STD}
The default Monero remote node is: ${WSTD}xmrtolujkxnlinre.onion:18081${STD}   
Github Link: ${LSTD}https://github.com/FungibilityMatters/MoneroMixer
"
back_to_previous
}

#DONATION FUNCTIONS:
donate_fungibilitymatters() { 
devaddress="4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn"
dev="Fungibility${M}atters"
title
echo -e "${YAY}Thank you for considering donating a small amount of ${YAY}XMR to ${WSTD}Fungibility${M}atters!
  
${WSTD}I made this program with the intention of helping people, it is ${STD}100% free${WSTD} to use
and donations are not required. You can press CTRL-C at any time to cancel and 
your Monero Wallet will NOT be charged. However, if you're feeling ${STD}generous${WSTD}, 
I would greatly appreciate a donation of any amount you're willing to give.
 
${STD}Your donation would be used to fund: 
- ${WSTD}Integrating additional secure withdrawal methods to support more coins 
and allow you to withdraw your balance as... ${STD}AMAZON GIFT CARDS${WSTD} and more!${STD} 
- ${WSTD}Building a reliable GUI so you can use $MoneroMixer${WSTD} without having to 
open up a terminal window ever again! 

${YAY}I hope you have enjoyed using MoneroMixer and that it made using cryptocurrency
anonymously a little bit easier for you.${STD} " 
local choice
echo -n -e "
${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) $previous_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

donate_monero_core_team() {
devaddress="44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A"
dev="The Monero Core Team"
title
echo -e "${YAY}Thank you for considering donating a small amount of XMR to the Monero Core Team
  
${WSTD}The Monero Core Team are the geniuses who really made this all possible. They
are funded entirely by donations and sponosorships so it is on users like us
to support them so they can continue the amazing work they do." 

local choice
echo -n -e "
${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) $previous_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

donate_thotbot() {
devaddress="notyetknown"
dev="Thotbot" 
title
echo -e "${YAY}Thank you for considering donating a small amount of ${YAY}XMR to Thotbot!
  
${WSTD}Thotbot runs xmrguide (${LSTD}xmrguide42y34onq.onion${WSTD}) the best Monero guide for Tails
and Whonix, that helped me learn the basics of using Monero back when I was a 
newbie and inspired me to create ${MoneroMixer}${WSTD}. He also wrote scripts that I 
borrowed some code from to improve this program so he deserves this credit
and hopefully your donation.    
" 
local choice
echo -n -e "
${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) $previous_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

donate_custom() {
title
update_balance
print_balance "--type limited"
echo -e -n "
Enter ${WBU}amount${STD} you would like to donate in ${YAY}XMR${STD}:${WBU} " 
read -r donateamount

title
echo -e "${YAY}Thank you for your donation of ${WBU}$donateamount ${YAY}XMR! You are awesome!

${STD}Your donation is processing please wait...
"
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command refresh > wallet-cli-out
wallet_error_check

echo -e "Sending ${WBU}$donateamount ${YAY}XMR${STD} to ${WSTD}$dev${STD}...
${GRN}"
set_noconf
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --no-dns --daemon-address $daemon --wallet-file $name --password $password --command transfer unimportant 11 $devaddress $donateamount > wallet-cli-out
grep "Transaction" wallet-cli-out
wallet_error_check
unset_noconf
echo -e "
Refreshing your ${YAY}XMR${STD} balance...
"
update_balance
test -e wallet-cli-out && shred -u wallet-cli-out
title
echo -e "${YAY}Thank you for your donation of ${WBU}$donateamount ${YAY}XMR! Your donation has been sent 
successfully. You are awesome!!" && sleep 4
back_to_previous
}

donate_remaining() {
title
echo -e "${YAY}Thank you for your donation to help support this project. You are awesome!"
local choice
echo -e -n "
${STD}Press ${YAY}1${STD} to continue with dontation or ${YAY}2${STD} to cancel:${YAY} "
read -r choice
	case $choice in
		1) title  ;;
		2) $previous_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
echo -e "${STD}Your donation is processing please wait a moment...
"
echo -n "${password}
" | torsocks ../../Monero-Software/monero-wallet-cli --daemon-address $daemon --wallet-file $name --password $password --command refresh > wallet-cli-out
wallet_error_check

echo -e "Sending your leftover ${YAY}XMR${STD} to ${WSTD}$dev...
"
echo -n "${password}
y
" | torsocks ../../Monero-Software/monero-wallet-cli --no-dns --daemon-address $daemon --wallet-file $name --password $password --command sweep_all unimportant $devaddress > wallet-cli-out
wallet_error_check

echo -e "
${STD}Refreshing your ${YAY}XMR${STD} balance...
"
update_balance

title
echo -e "${YAY}Thank you for your donation! Your donation has been sent 
successfully. You are awesome!!" && sleep 5
test -e wallet-cli-out && shred -u wallet-cli-out
back_to_previous
}

donation_data_in(){
declare data_line
readarray -n 1 data_line < d
shred -u d
read -ra data <<< ${data_line[0]}
balremaining=${data[0]}
minacc=${data[1]}
rate=${data[2]}    
maxbtcout=${data[3]}
}

xmrto_donation() { 
donation_data_in
devaddress="4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn"
dev="Fungibility${M}atters"

title
    echo -e "${ERR}Important Reminder: ${STD}After completing your last withdrawal your
Monero wallet balance is only ${WBU}${balremaining} ${YAY}XMR${STD}. 

At the current exchange rate of ${WBU}${rate} ${YAY}XMR${WSTD} per ${YAY}BTC${STD} this will not be enough 
to withdrawal since the minimum amount you can send anonymously via ${WSTD}XMR.to${STD} 
is ${WBU}0.001 ${YAY}BTC${STD} and you can only send ${ERR}${maxbtcout} ${YAY}BTC${STD}.

${WSTD}To withdrawal your leftover balance you can send ${YAY}XMR${WSTD} to an external address by 
choosing option ${YAY}3${WSTD} in the withdrawal menu. ${YAY}Or if you're feeling ${STD}generous${YAY} please
considering donating some of your leftover balance to the $MoneroMixer developer.

${STD}Your donation would be used to fund: 
- ${WSTD}Integrating additional secure withdrawal methods to support more coins 
and allow you to withdraw your balance as... ${STD}AMAZON GIFT CARDS${WSTD} and more!${STD} 
- ${WSTD}Building a reliable GUI so you can use $MoneroMixer${WSTD} without having to 
open up a terminal window ever again! 
"
local choice
echo -n -e "
${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) withdrawal_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}  

morph_donation() {
exchange="MorphToken"
exchange_donation
}

godex_donation() {
exchange="Godex.io"
exchange_donation
}

exchange_donation() {     
devaddress="4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn"
dev="Fungibility${M}atters"
donation_data_in
title
echo -e "${ERR}Important Reminder: ${STD}After completing your last withdrawal your
Monero wallet balance is only ${WBU}${balremaining} ${YAY}XMR${STD}. 

The current minimum amount you can send anonymously via ${WSTD}${exchange}${STD} 
is ${WBU}${minacc} ${YAY}XMR${STD} and you can only send ${ERR}${balremaining} ${YAY}XMR${STD}.

${WSTD}To withdrawal your leftover balance you can send ${YAY}XMR${WSTD} to an external address by 
choosing option ${YAY}1${WSTD} in the withdrawal menu. ${YAY}Or if you're feeling ${STD}generous${YAY} please
considering donating some of your leftover balance to the developer.

${STD}Your donation would be used to fund: 
- ${WSTD}Integrating additional secure withdrawal methods to support more coins 
and allow you to withdraw your balance as... ${STD}AMAZON GIFT CARDS${WSTD} and more!${STD} 
- ${WSTD}Building a reliable GUI so you can use $MoneroMixer${WSTD} without having to 
open up a terminal window ever again! 
"
local choice
echo -n -e "
${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
	read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) withdrawal_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}  


trap clean_all_exit SIGINT

test -z $1 || $1
test -z $1 && wallet_config
main_menu
