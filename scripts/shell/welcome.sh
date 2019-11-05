welcome_title() {
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


description() {
    welcome_title
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

    welcome_title
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

    welcome_title
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
    welcome_title
}

disclaimer(){
    if ! zenity --text-info --title="The Shortest Disclaimer You'll Ever Read" \
         --filename=info/disclaimer.txt --ok-label="Continue" --cancel-label="" \
         --checkbox="I agree to use this software legally and responsibly." 2> /dev/null 
    then 
       disclaimer
    fi
}
