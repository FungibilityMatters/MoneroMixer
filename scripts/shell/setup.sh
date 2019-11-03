#!/bin/bash

#DEFAULT SETTINGS:
daemon="zdhkwneu7lfaum2p.onion:18099"
declare -i ringsize
ringsize=11
priority="normal"
fiat="USD"
fiat_symbol="$"

#COLORS:
FG=33
BG=40
WT=37
STD="\033[00;${FG};${BG}m"
WSTD="\033[00;${WT};${BG}m"
WBU="\033[01;37;40m"
WUL="\033[00;04;${WT};${BG}m"
ITL="\033[3;${FG};${BG}m"
WITL="\033[3;37;${BG}m"
ERR="\033[01;31;${BG}m"
YAY="\033[01;36;${BG}m"
GRN="\033[01;32;${BG}m"
M="\033[0;4;33;${BG}mM${WSTD}"
MoneroMixer="${M}onero${M}ixer${STD}"

title() {
echo -e "${STD}SETTING BACKGROUND COLORS TO BLACK                     "
clear
title="${WSTD}Welcome to ${MoneroMixer}${WSTD} v${STD}1.1${WSTD} by Fungibility${M}atters${STD}-"
nocolor="Welcome to MoneroMixer v1.1 by FungibilityMatters-"
declare -i len
len=${#nocolor} 
shift=1
left="$(($((${COLUMNS:-$(tput cols)} - ${len})) / 2))"
test $((${COLUMNS:-$(tput cols)} % 2)) -ne $((${len} % 2)) && right="$((${left} + ${shift}))"
char="-"
printf "${STD}%*s" "${left}" '' | tr ' ' "${char}" && printf "$title" 
printf '%*s' "${right-$left}" '' | tr ' ' "${char}"
printf '\n\n'
}

got_it() {
echo -n -e "	${YAY}Got it? ${STD}[${WSTD}When you are ${STD}ready${WSTD} press ${YAY}ENTER${WSTD} to continue${STD}]${WSTD}:"
read discard
title
}

description() {
title
echo -e "${MoneroMixer} ${ITL}will create and manage a simple Monero wallet for you so that you 
can utilize the security benefits of Monero's privacy protocol without any
programming experience, time consuming setup, or prior knowledge required!${STD} 

${WSTD}Simply enter a ${YAY}name${STD} and ${YAY}password${WSTD} for your ${MoneroMixer} ${WSTD}wallet and it will be 
automatically configured then ready for you to use securely within seconds!${STD}
"
echo -e "${MoneroMixer} also provides an easy to use and ${WITL}JavaScript-free${STD} interface to 
anonymously deposit or withdraw to and from your wallet with ${YAY}210${STD}+ other more 
easily obtainable, and commonly accepted cryptocurrencies like ${STD}${YAY}BTC${STD}, ${YAY}LTC${STD}, ${YAY}ETH${STD}, 
${YAY}BCH${STD} etc via the well trusted private ${WSTD}Godex.io${STD}, ${WSTD}XMR.to${STD}, and ${WSTD}MorphToken${STD} exchanges. 

${WSTD}Now you can ${ITL}${WBU}finally${WSTD} use the cryptocurrency of your choice without missing out 
on the ${ITL}${YAY}unbeatable anonymity, security, and privacy${WSTD} benefits of ${STD}Monero!

" 
got_it
echo -e "${YAY}ONLY 2 STEPS ARE REQUIRED${STD} to spend your crypto anonymously with ${MoneroMixer}${WSTD}:"
echo -e "(For this ${STD}example${WSTD} imagine you wanted to use ${YAY}LTC${WSTD} to send a private ${YAY}BTC${WSTD} payment)
"  
echo -e "${STD}STEP ${STD}1${STD} (${WSTD}Deposit${STD}): ${WSTD}Convert your ${YAY}LTC${WSTD} to ${YAY}XMR${WSTD} via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} 

${STD}STEP ${STD}2${STD} (${WSTD}Withdraw${STD}): ${WSTD}Convert ${YAY}XMR${WSTD} back to ${YAY}BTC${WSTD} via ${STD}XMR.to${WSTD} to send exact ${YAY}BTC${WSTD} amount. 

(Or withdraw via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} to send ${YAY}210${STD}+${WSTD} other currencies.) "
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
got_it
}


set_daemon(){
title
daemons="zdhkwneu7lfaum2p.onion:18099 MoneroWorld.com xmkwypann4ly64gh.onion:18081 pool.xmr.pt xmrag4hf5xlabmob.onion:18081 xmrlab.com xmrtolujkxnlinre.onion:18081 XMR.to Enter Custom" 
daemon=$(zenity --list --height=250 --title="Select Monero Daemon" --text "Select a trusted .onion remote node to use as your daemon-address:" --column="Daemon-address:" --column="Hosted by:" $daemons 2> /dev/null)
test "$daemon" = "Enter" && daemon=$(zenity --entry --title="Enter Custom Monero Daemon" --text="Enter daemon-address [address:port]:"  2> /dev/null)
test -z daemon && set_daemon
echo -e "
${STD}daemon-address set to: ${YAY}$daemon${STD}" && sleep 2
}

set_priority() {
title
echo -e "${WSTD}Priority levels unimportant, normal, elevated, and priority correspond to 
transaction fee multipliers of x1, x4, x20, and x166, respectively. 

${WBU}The higher you set the priority level the faster your transactions will confirm
and the higher your fee will be.

${STD}The default priority level used by $MoneroMixer is ${YAY}normal${STD}.

"     
levels="unimportant slow x1 normal normal x4 elevated fast x20 priority fastest x166" 
priority=$(zenity --list --height=220 --width=400 --title="Select Transaction Priority Level" --text "Select your default priority level:" --column="Priority levels" --column="Transaction speed" --column="Fee multiplier" $levels 2> /dev/null)
test -z $priority && set_priority
echo -e "
${STD}Priority level set to: ${YAY}$priority${STD}" && sleep 2
}

set_fiat() {
title
echo -e "${WSTD}Choose a Fiat currency to use to determine the value of your assets.

${STD}The default fiat currency used by $MoneroMixer is ${GRN}$fiat ${WSTD}(${GRN}$fiat_symbol${WSTD})${STD}.

"   
fiats="USD $ EUR € GBP £ CAD $ RUB ₽ JPY ¥ CNY ¥ KRW ₩ Enter Custom" 
fiat_data_in=$(zenity --list --height=350 --title="Select Fiat Currency" --text "Select your default fiat currency and symbol:" --print-column="All" --column="Currency" --column="Symbol" $fiats 2> /dev/null)
test "$fiat_data_in" = "Enter|Custom" && fiat_data_in=$(zenity --forms --title="Enter Custom Fiat Currency" --text= "Enter Custom Fiat Currency" --add-entry="Enter currency code:" --add-entry "Enter currency symbol:"  2> /dev/null) 
test -z "$fiat_data_in" && set_fiat
old_IFS="$IFS" && IFS='|'
read -ra fiat_data <<< ${fiat_data_in}
IFS="$old_IFS"
    
fiat="${fiat_data[0]}"
fiat_symbol="${fiat_data[1]}"
echo -e "
${STD}Fiat currency set to: ${GRN}$fiat${STD}
${STD}Fiat symbol set to: ${GRN}$fiat_symbol${STD}" && sleep 2  
}

custom_fiat() {
fiat_data_in=$(zenity --forms --title="Enter Custom Fiat Currency" --add-entry="Enter currency code:" --add-entry "Enter currency symbol:"  2> /dev/null)
test -z "$fiat_data_in" && set_fiat
old_IFS="$IFS" && IFS='|'
read -ra fiat_data <<< ${fiat_data_in}
IFS="$old_IFS"
    
fiat="${fiat_data[0]}"
fiat_symbol="${fiat_data[1]}"
}

set_update_time(){
seconds=$(zenity --scale --title="Slide to set time to wait  before updating XMR rates" --text="Slide the scale  to select number of seconds to wait before updating current XMR rates" --value=60 --max-value=600 --step=1 2> /dev/null)
}

determine_key_derivation_function(){
kdf_arg="-pbkdf2"
touch kdftest && echo "Password based key dirivation funtion test" > kdftest
openssl enc -aes-256-cbc -in kdftest -out kdftest.enc -k testpass $kdf_arg 
test -e kdftest.enc || kdf_arg=""
shred -u kdftest 
test -e kdftest.enc && shred -u kdftest.enc
}

write_settings() {
test -f settings && shred -u settings
echo "Monero Daemon Address: $daemon
Transaction Ring Size: $ringsize
Transaction Priority Level: $priority
Fiat Currency Code: $fiat
Fiat Currency Symbol: $fiat_symbol
$kdf_arg" > settings
}

setup_choice() {
determine_key_derivation_function
title        

echo -e "	${STD}Choose your preffered $MoneroMixer setup type:${WSTD}" 
echo -e "	(${YAY}1${WSTD}) ${STD}Easy${WSTD} (Automatic setup)"
echo -e "	(${YAY}2${WSTD}) ${STD}Advanced${WSTD} (Manual setup)"
    
local choice
echo -n -e "
			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}2${STD}]:${YAY} "
read choice
	case $choice in
		1) auto_setup ;;
		2) manual_setup ;;
		*) printf "				      ${ERR}Invalid Choice...${STD}" && sleep 2 && setup_choice
	esac
test -e settings && echo -e "
${GRN}Success! You are done setting up $MoneroMixer ${GRN}and are ready to create a wallet. " & sleep 1
echo -e "${WBU}Use responsibly. ${STD}" && sleep 3
}

download_monero_wallet_cli(){
test -d Monero-Software || mkdir Monero-Software
cd Monero-Software
torsocks wget https://downloads.getmonero.org/cli/linux64 | $(zenity --progress --title="Downloading Monero software from getmonero.org" --text="Downloading Linux64 Monero wallet command line tools from getmonero.org

Please wait. MoneroMixer will start automatically once finished..." --pulsate --auto-close --auto-kill 2> /dev/null)
tar -xzf linux64
mv monero-x86_64-linux-gnu/monero-wallet-cli monero-wallet-cli
chmod +x monero-wallet-cli
cd ../
test -x Monero-Software/monero-wallet-cli || failed_monero_wallet_cli
}

failed_monero_wallet_cli(){
if zenity --question --icon-name='dialog-warning' --title="Error: Failed to download Monero Software" --text="Failed to download monero-wallet-cli from getmonero.org

Try again or download the Monero Software manually to continue" --ok-label="Try automatic download again" --cancel-label="Download manually" 2> /dev/null
then 
    download_monero_wallet_cli
else
    zenity --info --title="How to setup Monero software manually" --text="1. Download the Monero Linux64 Command Line tool from this link:
https://downloads.getmonero.org/cli/linux64

2. Unzip the zip archive and find the file called monero-wallet-cli inside the unpacked file.

3. Copy monero-wallet-cli to the Monero-Software folder inside your MoneroMixer folder (MoneroMixer/Monero-Software) then press Ok to continue." 2> /dev/null
fi 
test -x Monero-Software/monero-wallet-cli || failed_monero_wallet_cli
}


download_python_dependencies(){
test $(whoami) = "amnesia" || $(pip3 install requests qrcode) | zenity --progress --title "Downloading Python3 Dependencies" --text "Please wait. MoneroMixer will start automatically once finished..." --pulsate --auto-close --auto-kill 2> /dev/null
}

file_setup() {
mkdir Scripts Info    
mv MoneroMixer.py Scripts/MoneroMixer.py 
mv MoneroMixer.sh Scripts/MoneroMixer.sh
mv setup.sh Scripts/setup.sh
mv user-agents.txt Info/user-agents.txt 
mv README.md Info/README.md
mv FungibilityMatters_PGP_Key.asc Info/FungibilityMatters_PGP_Key.asc

chmod +x Scripts/MoneroMixer.sh
chmod +x start
}

auto_setup() {
write_settings
}

manual_setup() {
set_fiat
set_daemon
set_priority
#set_ring_size
write_settings
}


if test -z "$1"; then 
    download_python_dependencies
    download_monero_wallet_cli 
    file_setup
    description    
    setup_choice
    ./Scripts/MoneroMixer.sh
elif test "$1" = "anotha_one"; then 
    setup_choice
    while ! test -d Scripts 
    do 
        cd ../
    done
    ./Scripts/MoneroMixer.sh
elif test "$1" = "update"; then 
    download_python_dependencies
    download_monero_wallet_cli
    file_setup
else 
    $1
    write_settings
    cd ../
    ./Scripts/MoneroMixer.sh
fi
