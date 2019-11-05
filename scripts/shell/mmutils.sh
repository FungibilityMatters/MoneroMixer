#!/bin/bash
torpydo(){
    local decrypted_data inputDict stdin_bytes fd_bytes
    decrypted_data="$2"
    if echo "$2" | grep -q "@A"; then 
        decrypted_data="address_str%%%$(degrept address address.enc)/$decrypted_data"
    fi

    if echo "$2" | grep -q "@B"; then
        decrypted_data="balance_str%%%$(degrept Balance balance.enc)/$decrypted_data"
    fi

    inputDict="fiat%%%${fiat:-"None"}/
symbol%%%${fiat_symbol:-"None"}/
crypto%%%${crypto:-"None"}/
update%%%${seconds_before_update:-"None"}/
type%%%${type:-"None"}/
exchange%%%${exchange:-"None"}/
coin_in%%%${coin_in:-"None"}/
coin_out%%%${coin_out:-"None"}/
amount%%%${amount:-"None"}/
coin%%%${coin:-"None"}/
qrdata%%%${qrdata:-"None"}/
selected_coins%%%${selected_coins:-"None"}/
display%%%${display:-"False"}/
cols%%%${COLUMNS:-$(tput cols)}/$decrypted_data"

    stdin_bytes=$(wc --bytes <<<"$inputDict")

    if [ -z "$3" ]; then
        echo "$inputDict" | torsocks python3 ../../scripts/python3/MoneroMixer.py \
                            --command $1 --stdin_bytes $stdin_bytes
    else
        fd_bytes=$(wc --bytes <<<"$3") 
        echo "$inputDict" | torsocks python3 ../../scripts/python3/MoneroMixer.py \
                            --command $1 --stdin_bytes $stdin_bytes \
                            --fd <(echo "$3") --fd_bytes $fd_bytes
    fi
}


#ENCRYPTION/DECRYPTION FUNCTIONS:
encrypt(){
    openssl enc -aes-256-cbc -pbkdf2 -salt -kfile <(echo ${password}) -out $1
}

decrypt(){
    openssl enc -d -aes-256-cbc -pbkdf2 -salt -kfile <(echo ${password}) -in $1
}

append_encrypted_id(){
    encrypt newID.enc
    [ -e $1 ] || touch $1
    [ -e $1 ] && mv $1 oldIDs.enc
    echo "$(decrypt newID.enc)
$([ -e oldIDs.enc ] && decrypt oldIDs.enc 2> /dev/null)" | encrypt $1
    shred -u newID.enc 
    [ -e oldIDs.enc ] && shred -u oldIDs.enc
}


degrept(){
    decrypt $2 | grep "$1"
}

#CLEANING FUNCTIONS
clean_all() {
    title
    printf "${STD}Encrypting and shredding all data before exiting...\n"
    [ -e updates ] && rm -rf updates
    [ -e wallet-cli-out.enc ] && shred -u wallet-cli-out.enc
    [ -e py_error ] && shred -u py_error
    [ -e ./../monero-software/monero-wallet-cli.log ] && shred -u ./../monero-software/monero-wallet-cli.log
    [ -e address.enc ] && shred -u address.enc
    [ -e balance.enc ] && shred -u balance.enc
    [ -e fiat-prices ] && shred -u fiat-prices
    [ -e options-list ] && shred -u options-list
    [ -e extraid ] && shred -u extraid
    [ -e pydisplay ] && shred -u pydisplay
    [ -e ../scripts/python3/__pycache__ ] && rm -rf ../scripts/python3/__pycache__
    [ -e ../../scripts/python3/__pycache__ ] && rm -rf ../../scripts/python3/__pycache__
    $(kill %1 %2 %3 &> /dev/null)
}

clean_all_exit() {
    clean_all
    while ! [ -d scripts -a -d monero-software ]; do 
        cd ../
    done
    printf "\n${GRN}Done. Your data is now secure.\n\n"
    printf "${STD}TO RUN MONEROMIXER AGAIN USE THIS COMMAND IN A NEW TERMINAL:
${WBU}cd $PWD && ./start\n\n"
    read discard
    exit
}

clean_all_no_exit() {
    clean_all
    cd ../
    printf "\n${GRN}Done. Your data is now secure.\n"
}




#bg process updatig prices icons and availaible coins
start_background_updates(){
    $(download_new_icons &> /dev/null) &

    [ -d updates ] && rm -rf updates
    mkdir updates
    while test -d updates ; do
        torpydo "update"
        sleep $seconds_before_update
    done
}

resync_prices(){
    kill %1 %2 %3 &> /dev/null
    start_background_updates &
}


download_new_icons(){
    while ! [ -d icons ]; do
        cd ../
    done
    cd icons && touch downloaded_icons.txt

    torsocks python3 ../scripts/python3/MoneroMixer.py --command "icons" --stdin_bytes 0 \
    | (while read -r icon && [ $icon != "DONE" ]; do
        inkscape -z -f $icon -w 25 -h 25 -e $(pngfy $icon) &> /dev/null &
    done)
    rm -rf $(find *.jpeg *.ico *.svg)
}

#HELPER FUNCTIONS:
print_title() {
    char="$1"
    title="$2"
    nocolor="$3"
    declare -i len
    len=${#nocolor} 
    shift=1
    left="$(($((${COLUMNS:-$(tput cols)} - $len)) / 2))"
    [ $((${COLUMNS:-$(tput cols)} % 2)) -ne $(($len % 2)) ] && right="$((${left} + ${shift}))"
    printf "${STD}%*s" "${left}" '' | tr ' ' "${char}" && printf "$title" 
    printf '%*s' "${right-$left}" '' | tr ' ' "${char}"
    printf '\n' #\n'
}

title() {
    printf "${STD}SETTING BACKGROUND COLORS TO BLACK                     "
    clear
    print_title '-' "${WSTD}${MoneroMixer}${WSTD} v${STD}1.2${WSTD} by Fungibility${M}atters${STD}-" \
"MoneroMixer v1.2 by FungibilityMatters-" 
    test "$1" = "nonl" || printf '\n'
}

title_welcome() {
    printf "${STD}SETTING BACKGROUND COLORS TO BLACK                     "
    clear
    print_title '-' "${WSTD}Welcome to ${MoneroMixer}${WSTD} v${STD}1.2${WSTD} by Fungibility${M}atters${STD}-" \
"Welcome to MoneroMixer v1.2 by FungibilityMatters-"
    printf '\n'
}

back_to_previous() {
    printf "\n	    ${STD}Press ${YAY}ENTER${STD} to go back to previous Menu:"
    read -r junk
    $previous_menu
}

set_IFS(){
    OG_IFS="$IFS"
    IFS="$1"
}

unset_IFS(){
    IFS="$OG_IFS"
}

zprog() {
    zenity --progress --modal --height=100 ${3-"--width=300"} \
           --title "$1" --text="$2" --pulsate --auto-close --auto-kill \
           ${4-"--no-cancel"} $5"$6" 2> /dev/null
}

zerror(){
    zenity --error --ellipsize --icon-name='dialog-warning' \
           --title="$1" --text="$2" 2> /dev/null
}

pyrand(){
    [ -z "$2" ] && range="0,$1" || range="$1,$2"
    printf "import random\nprint(random.randint($range))" | python3
}

pngfy(){
    set_IFS "."
    read -ra split_icon <<<$1
    echo "${split_icon[0]}.png"
}

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



