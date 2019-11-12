#HELP FUNCTIONS:
help_menu() {
    previous_menu="help_menu"
    title
    printf "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~ ${WSTD}H E L P / I N F O - ${M}${WSTD} E N U ~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	${WSTD}What do you need help with?

	(${YAY}1${WSTD}) ${STD}I am having an issue with an exchange${WSTD}
	(${YAY}2${WSTD}) ${STD}I am experiencing an issue or bug with $MoneroMixer${WSTD}
	(${YAY}3${WSTD}) ${STD}I need a refresher on how to use $MoneroMixer${WSTD}

	(${YAY}4${WSTD}) ${STD}View Advanced Info (Stuff for nerds)${WSTD}
	(${YAY}5${WSTD}) ${STD}Return to Main Menu${STD}" 
    help_menu_options
}

help_menu_options() {
    local choice
    printf "\nEnter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}5${STD}]:${YAY} "
    read -r choice
	case $choice in
		1) help_menu_selector ;;
        	2) help_links ;; 
        	3) show_help ;; 
		4) stuff_for_nerds ;;
		5) main_menu ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}

help_menu_selector(){
    help_choice=$(zenity --list --title="Select the exchange you need help with" \
                         --text="You will be shown the support email, FAQ, privacy policy, etc for the exchange you select." \
                         --column="choice" --column="Exchanges" --hide-column=1 \
                         xmrto_help XMR.to \
                         godex_help Godex.io \
                         morph_help MorphToken 2> /dev/null)
    [ -n "$help_choice" ] && $help_choice || help_menu  
}

show_help() {
    title
    printf "${YAY}ONLY 2 STEPS ARE REQUIRED${STD} to spend your crypto anonymously with ${MoneroMixer}${WSTD}:
(For this ${STD}example${WSTD} imagine you wanted to use ${YAY}LTC${WSTD} to send a private ${YAY}BTC${WSTD} payment)\n  
${STD}STEP ${STD}1${STD} (${WSTD}Deposit${STD}): ${WSTD}Convert your ${YAY}LTC${WSTD} to ${YAY}XMR${WSTD} via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} 
${STD}STEP ${STD}2${STD} (${WSTD}Withdraw${STD}): ${WSTD}Convert ${YAY}XMR${WSTD} back to ${YAY}BTC${WSTD} via ${STD}XMR.to${WSTD} to send exact ${YAY}BTC${WSTD} amount. 
(Or withdraw via ${STD}Godex.io${WSTD} or ${STD}MorphToken${WSTD} to send ${YAY}100${STD}+${WSTD} other coins.) 

${WSTD}All ${STD}you will need ${WSTD}to provide is:${STD}
1. ${YAY}Refund Address${STD} to send coins back to if any errors occur during your deposits
2. ${YAY}Destination Address${STD} where each withdrawal should be sent.\n\n"

    printf "	${YAY}Got it? ${STD}[${WSTD}When you are ${STD}ready${WSTD} press ${YAY}ENTER${WSTD} to continue${STD}]${WSTD}:"
    read -r junk

    title  
    printf "${ERR}IMPORTANT: Between steps 1 and 2 you will need to wait a few hours in 
order to prevent timing based blockchain analysis.${STD}\n
${STD}While waiting you can view the status of your deposits or withdrawals.\n
${STD}Make sure you ${WBU}read the instructions carefully${STD} and follow the prompts.${STD}\n"
    back_to_previous
}

help_links() {
    title
    printf "${WSTD}
Use the following links to contact the developer if you need help, have any 
questions, or want to report an unfixed bug${STD}:
\n$MoneroMixer subreddit (Post here for support): ${LSTD}https://www.reddit.com/r/moneromixer/
\n${STD}Message FungibilityMatters on Reddit: ${LSTD}https://www.reddit.com/message/compose/?to=FungibilityMatters
\n${STD}Link to original post: ${LSTD}https://www.reddit.com/r/Monero/comments/cqyjqo/moneromixer_a_simple_tool_to_help_you_anonymously/
\n${STD}Read the README on GitHub: ${LSTD}https://github.com/FungibilityMatters/MoneroMixer/blob/master/README.md\n"
    back_to_previous
}

stuff_for_nerds() {
    title
    printf "${YAY}Stuff for nerds:${STD}
MoneroMixer works in conjunction with the Official Monero CLI to ensure 
that you are always using the latest and most secure Monero wallet interface 
available. Your MoneroMixer wallet will be automatically configured to 
synchronize with a trusted Monero .onion remote node and it will use a 
daemon-address connection at port 18081 so that you don't have to wait hours 
downloading the full ~80+GB blockchain like a traditional Monero wallet requires 
Every monero-wallet-cli command and API request from the Python script is
executed through a torsocksified connection so there is not a pattern amoung 
the IP addresses your wallet has used. Lastly, all working files and
transaction history are 256 bit encrypted immediately after use or exiting.  
The default tor wrapping protocol is: ${WSTD}torsocks${STD}
The default Monero remote node is: ${WSTD}xmrtolujkxnlinre.onion:18081${STD}   
Github Link: ${LSTD}https://github.com/FungibilityMatters/MoneroMixer\n"
    back_to_previous
}

exchange_help() {
    title
    printf "${STD}Need help with a ${WSTD}$exchange${STD} transaction?${STD}
\n${WSTD}$exchange${STD} Support Email: ${LSTD}$support_email${WSTD}
\n${WSTD}$exchange${STD} FAQ: ${LSTD}$faq_link${WSTD}\n"

    [ -z "$pp_link" ] || printf "${WSTD}$exchange${STD} Privacy Policy: ${LSTD}$pp_link${WSTD}\n"
    [ -z "$tc_link" ] || printf "${WSTD}$exchange${STD} Terms and Conditions: ${LSTD}$tc_link${WSTD}\n"
    printf "${WSTD}$exchange${STD} API documentation: ${LSTD}$api_link${WSTD}\n"
    back_to_previous
}

xmrto_help(){
    exchange="XMR.to"
    support_email="support@xmr.to"
    faq_link="https://xmr.to/nojs/#faq"
    pp_link="https://xmr.to/privacy-policy"
    tc_link="https://xmr.to/terms-of-service"
    api_link="https://xmrto-api.readthedocs.io/en/latest/"
    exchange_help
}

morph_help(){
    exchange="MorphToken"
    support_email="contact@morphtoken.com"
    faq_link="https://www.morphtoken.com/faq/"
    pp_link=""
    tc_link="https://www.morphtoken.com/terms/"
    api_link="https://www.morphtoken.com/api/"
    exchange_help
}

godex_help(){
    exchange="Godex.io"
    support_email="support@godex.io"
    faq_link="https://godex.io/faq"
    pp_link="https://godex.io/privacy_policy"
    tc_link="https://godex.io/terms_of_use"
    api_link="https://www.morphtoken.com/api/"
    exchange_help
}
