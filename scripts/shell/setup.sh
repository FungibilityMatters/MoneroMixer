#!/bin/bash
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
    title="${WSTD}Welcome to ${MoneroMixer}${WSTD} v${STD}1.2${WSTD} by Fungibility${M}atters${STD}-"
    nocolor="Welcome to MoneroMixer v1.2 by FungibilityMatters-"
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
anonymously deposit or withdraw to and from your wallet with ${YAY}100${STD}+ other more 
easily obtainable, and commonly accepted cryptocurrencies like ${STD}${YAY}BTC${STD}, ${YAY}LTC${STD}, ${YAY}ETH${STD}, 
${YAY}BCH${STD} etc via the well trusted private ${WSTD}Godex.io${STD}, ${WSTD}XMR.to${STD}, and ${WSTD}MorphToken${STD} exchanges. 

${WSTD}Now you can ${ITL}${WBU}finally${WSTD} use the cryptocurrency of your choice without missing out 
on the ${ITL}${YAY}unbeatable anonymity, security, and privacy${WSTD} benefits of ${STD}Monero!

"
    zenity --info --ellipsize --title="Welcome to MoneroMixer!" \
    --text="Installation Complete. Welcome to MoneroMixer!" --ok-label="Get started" 2> /dev/null 

    title
    echo -e "${YAY}ONLY 2 STEPS ARE REQUIRED${STD} to spend your crypto anonymously with ${MoneroMixer}${WSTD}:"
    echo -e "(For this ${STD}example${WSTD} imagine you wanted to use ${YAY}LTC${WSTD} to send a private ${YAY}BTC${WSTD} payment)
"  
    echo -e "${STD}STEP ${STD}1${STD} (${WSTD}Deposit${STD}): ${WSTD}Convert your ${YAY}LTC${WSTD} to ${YAY}XMR${WSTD} via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} 

${STD}STEP ${STD}2${STD} (${WSTD}Withdraw${STD}): ${WSTD}Convert ${YAY}XMR${WSTD} back to ${YAY}BTC${WSTD} via ${STD}XMR.to${WSTD} to send exact ${YAY}BTC${WSTD} amount. 

(Or withdraw via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} to send ${YAY}100${STD}+${WSTD} other currencies.) "
    echo -e "
${WSTD}All ${STD}you will need ${WSTD}to provide is:${STD}
1. ${YAY}Refund Address${STD} to send coins back to if any errors occur during your deposits
2. ${YAY}Destination Address${STD} where each withdrawal should be sent.

"

    zenity --info --ellipsize --title="INFO: How to transact anonymously with MoneroMixer" \
    --text="(For this example imagine you wanted to use LTC to send a private BTC payment)

How to transact anonymously with MoneroMixer:
STEP 1 (Deposit): Convert your LTC to XMR via Godex.io or MorphToken 

STEP 2 (Withdraw): Convert XMR back to BTC via XMR.to to send exact BTC amount. 
(Or withdraw via Godex.io or MorphToken to send 100+ other currencies.) 

All you will need to provide is:
1. Refund Address to send coins back to if any errors occur during your deposits
2. Destination Address where each withdrawal should be sent.
" 2> /dev/null 

    title
    echo -e "${ERR}IMPORTANT: Between steps 1 and 2 you will need to wait a few hours in 
order to prevent timing based blockchain analysis.${STD}"
    echo -e "
${STD}While waiting you can view the status of your most recent deposits or 
withdrawals from the corresponding menus. 
${STD}
${STD}Make sure you ${WBU}read the instructions carefully${STD} and follow the prompts.

${WBU}NOTE: To quit securely press ${YAY}CTRL-C${WBU} at any time or select 
option ${YAY}8${WBU} 'Quit' from the main menu."

    zenity --info --ellipsize --icon-name="dialog-warning" \
    --title="IMPORTANT: Read this if you care about your privacy" \
    --text="IMPORTANT: Between steps 1 and 2 you will need to wait a few hours \nin order to prevent timing based blockchain analysis.

While waiting you can view the status of your most recent deposits or 
withdrawals from the corresponding menus. 

Make sure you read the instructions carefully and follow the prompts.

NOTE: To quit securely press CTRL-C at any time or select option 8 'Quit'
from the main menu." 2> /dev/null 
    title
}

disclaimer(){
    if ! zenity --text-info --title="The Shortest Disclaimer You'll Ever Read" \
         --filename=info/disclaimer.txt --ok-label="Continue" --cancel-label="" \
         --checkbox="I agree to use this software legally and responsibly." 2> /dev/null 
    then 
       disclaimer
    fi
}



download_monero_wallet_cli(){
    declare uaList 
    readarray -n 7478 uaList <<< $(cat info/user-agents.txt)
    ua=$(echo "User-Agent: ${uaList[$(( ( RANDOM % 7047 )  + 1 ))]}" | tr -d "\n")
    test -d monero-software || mkdir monero-software
    cd monero-software

    torsocks wget https://dlsrc.getmonero.org/cli/monero-linux-x64-v0.14.1.2.tar.bz2 \
    --show-progress \
    --secure-protocol="TLSv1_2" \
    --user-agent "$ua" \
    --max-redirect=0 -O linux64 | $(zenity --progress \
                                    --title="Downloading Monero software from getmonero.org" \
                                    --text="Downloading Linux64 Monero wallet command line tools from getmonero.org

Please wait. MoneroMixer will start automatically once finished..." \
                                    --pulsate --auto-close --auto-kill 2> /dev/null)

    test -e linux64 || failed_monero_wallet_cli
    read -ra cli_hash <<< $(openssl sha256 linux64)
    if test "${cli_hash[1]}" = "a4d1ddb9a6f36fcb985a3c07101756f544a5c9f797edd0885dab4a9de27a6228" 
    then 
        unzip_monero_wallet_cli
    else
        if zenity --question --ellipsize --icon-name='dialog-warning' \
            --title="WARNING: The Monero software you downloaded may be NOT be authentic" \
            --text="WARNING: The Monero software you downloaded may be NOT be authentic.

The SHA256 hash of the linux64 Monero CLI tools just downloaded are:       
${cli_hash[1]}

Which is different from the SHA256 hash posted on getmonero.org:
a4d1ddb9a6f36fcb985a3c07101756f544a5c9f797edd0885dab4a9de27a6228
   
You may be affected by an MITM (Man-in-the-middle) attack and should install the Monero software manually to ensure your security.

The potentially compromised software will be destroyed unless you select continue anyway." \
            --ok-label="View steps to download manually" \
            --cancel-label="Continue anyway (Potentially dangerous)" 2> /dev/null
        then 
            manual_monero_wallet_cli   
        else
            unzip_monero_wallet_cli     
        fi 
    fi
    cd ../
    test -x monero-software/monero-wallet-cli || failed_monero_wallet_cli
}

unzip_monero_wallet_cli(){
    tar -xzf linux64
    mv monero-x86_64-linux-gnu/monero-wallet-cli monero-wallet-cli
    chmod +x monero-wallet-cli
}

failed_monero_wallet_cli(){
    if zenity --question --ellipsize --icon-name='dialog-warning' \
              --title="Error: Failed to download Monero Software" \
              --text="Failed to download monero-wallet-cli from getmonero.org

Try again or download the Monero Software manually to continue" \
              --ok-label="Try automatic download again" \
              --cancel-label="Download manually" 2> /dev/null
    then 
        download_monero_wallet_cli
    else
        manual_monero_wallet_cli
    fi 
    test -x monero-software/monero-wallet-cli || failed_monero_wallet_cli
}

manual_monero_wallet_cli(){
    zenity --info --ellipsize --title="How to setup Monero software manually" \
           --text="1. Download the Monero Linux64 Command Line tool from this link:
https://downloads.getmonero.org/cli/linux64

2. Unzip the zip archive and find the file called monero-wallet-cli inside the unpacked file.

3. Copy monero-wallet-cli to the monero-software folder inside your MoneroMixer folder (MoneroMixer/monero-software) then press Ok to continue." 2> /dev/null
}


download_python_dependencies(){
    [ $USER = "amnesia" ] || $(pip3 install requests qrcode) \
    | zenity --progress --title "Downloading Python3 Dependencies" \
      --text "Please wait. MoneroMixer will start automatically once finished..." \
      --pulsate --auto-close --auto-kill 2> /dev/null
}

check_if_persistent(){
    if test "$(echo "print('Persistent' in '$PWD')" | python3)" = "False" -a $USER = "amnesia"
    then 
        if zenity --question --ellipsize \
                  --title="WARNING: MoneroMixer is NOT installed in your Persistent volume" \
                  --text="MoneroMixer should be installed to your Tails Persisent volume so that your Monero wallet(s) are saved permanently.

FAILURE TO INSTALL MONEROMIXER IN YOUR PERSISTENT VOLUME WILL CAUSE YOUR WALLETS TO BE DELETED UPON RESTARTING TAILS

Instructions on how to setup a persistent volume can be found here:
https://tails.boum.org/install/clone/index.en.html#create-persistence\n" \
                  --ok-label="Select a new folder to move MoneroMixer" \
                  --cancel-label="Continue without persistence" \
                  --icon-name="dialog-warning" 2> /dev/null 
        then 
            move_setup
            check_persistent
        else
            if zenity --question --ellipsize \
                --title="Are you sure you want to continue without persistence?" \
                --text="MoneroMixer will still work fine without being installed in your persistent volume, but all of your data (wallets, coins, order IDs) will be lost upon restarting Tails.

AGAIN, FAILURE TO INSTALL MONEROMIXER IN YOUR PERSISTENT VOLUME WILL CAUSE YOUR WALLETS TO BE DELETED UPON RESTARTING TAILS

You should only continue without persistence if you are aware of this fact." \
                --ok-label="Select a new folder to move MoneroMixer" \
                --cancel-label="Continue without persistence" \
                --icon-name="dialog-warning" 2> /dev/null 
            then 
                move_setup
                check_persistent            
            fi
        fi
    fi
}

move_setup(){
    new_dir="$(zenity --file-selection --title="Select a folder in your Persistent volume where you would like to move MoneroMixer" --directory 2> /dev/null)"
    cd ../
    mv MoneroMixer $new_dir/MoneroMixer
    cd $new_dir/MoneroMixer
}

file_setup() {
    rm -rf .git
    mv README.md info/README.md
    mkdir icons
    chmod +x start
}


if [ -z "$1" ]; then
    . scripts/shell/mmutils.sh
    . scripts/shell/settings.sh
    file_setup
    check_if_persistent
    $(download_new_icons &> /dev/null) &
    download_python_dependencies
    download_monero_wallet_cli    
    description
    disclaimer
    setup_choice
    ./start
elif [ "$1" = "update" ]; then 
    download_python_dependencies
    download_monero_wallet_cli
    file_setup
else
    read_settings 
    $1
    write_settings
fi
