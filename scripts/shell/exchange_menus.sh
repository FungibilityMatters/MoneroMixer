#Prints MorphToken or Godex specific menu
exchange_menu() {
    title
    printf "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
${top}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      	
	${WSTD}Exchange Anonymously through your Monero Wallet:
	(${YAY}1${WSTD}) ${STD}Deposit $menu_coins${STD} => ${GRN}RECEIVE${YAY} XMR${STD} to your Wallet${WSTD}
	(${YAY}2${WSTD}) ${STD}Withdraw ${YAY}XMR${STD} from your Wallet${STD} => ${GRN}SEND ${YAY}$menu_coins${WSTD}

	${WSTD}View Status of Previous Exchanges:
	(${YAY}3${WSTD}) ${STD}View Status of Most Recent ${WSTD}$exchange${STD} Deposit${WSTD}
	(${YAY}4${WSTD}) ${STD}View Status of Most Recent ${WSTD}$exchange${STD} Withdrawal${WSTD}
	(${YAY}5${WSTD}) ${STD}View Status of ANY Exchange from ${WSTD}$exchange${STD} Order ID${WSTD}

	${WSTD}Check Current Exchange Rates:
	(${YAY}6${WSTD}) ${STD}Check Current ${WSTD}$exchange${STD} Deposit Rates${WSTD}
	(${YAY}7${WSTD}) ${STD}Check Current ${WSTD}$exchange${STD} Withdrawal Rates${WSTD}

	(${YAY}8${WSTD}) ${STD}View ${WSTD}$exchange${STD} support email, FAQ, and other helpful info${WSTD}

	(${YAY}9${WSTD}) ${STD}Return to Main Menu${STD}" 

    local choice
    printf "\n\n			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}9${STD}]:${YAY} "
    read -r choice
	case $choice in
		1) deposit ;;
        2) withdraw ;;
		3) wallet_auth_password "View most recent $exchange deposit" "" "noexit"; display_deposit ;;
        4) wallet_auth_password "View most recent $exchange withdrawal" "" "noexit"; display_withdrawal ;;
		5) view_id ;;
		6) rates deposit;;
        7) rates withdrawal;;
        8) ${abrev}_help ;;
		9) main_menu ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}

#Create Godex exchange menu:        
godex_menu() {
    previous_menu="godex_menu"
    exchange="Godex.io"
    abrev="godex"
    top="~~~~~~~~~~~~~~~~~~~~~~~~~~ G O D E X . I O${WSTD} - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    menu_coins="${YAY}choice of 100${STD}+${YAY} Coins"
    supported_coins=""
    exchange_menu
}

#Create MorphToken exchange menu:
morph_menu() {
    previous_menu="morph_menu"
    exchange="MorphToken"
    abrev="morph"
    top="~~~~~~~~~~~~~~~~~~~~~~~~ ${M} O R P H T O K E N${WSTD} - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~"
    menu_coins="${YAY}BTC${STD}, ${YAY}LTC${STD}, ${YAY}ETH${STD}, ${YAY}BCH${STD}, or ${YAY}DASH${STD}"
    supported_coins="BTC LTC ETH BCH DASH"    
exchange_menu
}

#Prints XMR.to specific menu
xmrto_menu() {
    exchange="XMR.to"
    previous_menu="xmrto_menu"
    type="withdrawal"
    abrev="xmrto"
    title
    printf "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~ X ${M} R . T O${WSTD} - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	${WSTD}Withdraw/Send BTC Anonymously from your Monero Wallet:
	(${YAY}1${WSTD}) ${STD}Withdraw/Send an Exact BTC Amount to a BTC address (${WSTD}${YAY}XMR${WSTD} => ${YAY}BTC${STD})${WSTD}
	(${YAY}2${WSTD}) ${STD}Withdraw/Send BTC with a BitPay Payment Protocol URL (${WSTD}${YAY}XMR${WSTD} => ${YAY}BitPay${STD})${WSTD}

	${WSTD}View Status of Previous Withdrawals:
	(${YAY}3${WSTD}) ${STD}Check Status of Most Recent ${WSTD}XMR.to${STD} Withdrawal${WSTD}
	(${YAY}4${WSTD}) ${STD}Check Status of any Withdrawal from ${WSTD}XMR.to${STD} ID${WSTD}

	${WSTD}Check Current Exchange Rates:
	(${YAY}5${WSTD}) ${STD}View Current ${WSTD}XMR.to${STD} Exchange Rates${WSTD}

	(${YAY}6${WSTD}) ${STD}View ${WSTD}XMR.to${STD} support email, FAQ, and other helpful info${WSTD}

	(${YAY}7${WSTD}) ${STD}Return to Main Menu${STD}"

    local choice
    printf "\n\n			Enter ${WSTD}choice${STD} [${YAY}1${STD} - ${YAY}7${STD}]:${YAY} "
    read -r choice
	case $choice in
		1) withdraw BTC ;;
        2) withdraw BTC pp_url ;;
		3) wallet_auth_password "View most recent XMR.to withdrawal" "" "noexit"; display_withdrawal ;;
		4) view_id ;;
        5) rates withdrawal;;
        6) xmrto_help ;;
		7) main_menu ;;
		*) printf "			${ERR}Invalid Choice...${STD}" && sleep 2 && $previous_menu
	esac
}
