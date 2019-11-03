donation_menu() {
    previous_menu="donation_menu"
    title
    printf "${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~ D O N A T I O N - ${M} E N U ${WSTD}~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n
    ${YAY}Thank you for considering donating XMR to the community!\n
	${WSTD}Who would you like to donate to?\n
	(${YAY}1${WSTD}) ${STD}Donate to ${WSTD}Fungibility${M}atters${WSTD}
	(${YAY}2${WSTD}) ${STD}Donate to ${WSTD}Monero Core Team${WSTD}
	(${YAY}3${WSTD}) ${STD}Donate to ${WSTD}Thotbot${WSTD}\n
	(${YAY}4${WSTD}) ${STD}Return to Main Menu without Donating :(${STD}\n"

    local choice
    printf "
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

donation_options() {
    local choice
    printf "\n\n${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
    read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) $previous_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

donate_fungibilitymatters() { 
    devaddress="4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn"
    dev="Fungibility${M}atters"
    dev_uncolored="FungibilityMatters"
    title
    printf "${YAY}Thank you for considering donating a small amount of ${YAY}XMR to ${WSTD}Fungibility${M}atters!
  \n${WSTD}I made this program with the intention of helping people, it is ${STD}100% free${WSTD} to use
and donations are not required. You can press CTRL-C at any time to cancel and 
your Monero Wallet will NOT be charged. However, if you're feeling ${STD}generous${WSTD}, 
I would greatly appreciate a donation of any amount you're willing to give.
\n${STD}Your donation would be used to fund: 
- ${WSTD}Integrating additional secure withdrawal methods to support more coins 
and allow you to withdraw your balance as... ${STD}AMAZON GIFT CARDS${WSTD} and more!${STD} 
- ${WSTD}Building a reliable GUI so you can use $MoneroMixer${WSTD} without having to 
open up a terminal window ever again! 
\n${YAY}I hope you have enjoyed using MoneroMixer and that it made using cryptocurrency
anonymously a little bit easier for you.${STD} "
    donation_options
}

donate_monero_core_team() {
    devaddress="44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A"
    dev="The Monero Core Team"
    dev_uncolored_="$dev"
    title
    printf "${YAY}Thank you for considering donating a small amount of XMR to the Monero Core Team
\n${WSTD}The Monero Core Team are the geniuses who really made this all possible. They
are funded entirely by donations and sponosorships so it is on users like us
to support them so they can continue the amazing work they do." 
    donation_options
}


donate_thotbot() {
    devaddress="4BD16rh8ww6Etf7VzzmkzCiWsNUJy99ifAi7cKkzHvMyDQtzYnmwwDgKLKrPz4gpzmZ28YNtJTwM9jkfUgVyMQQe1zZDpPe"
    dev="Thotbot"
    dev_uncolored="$dev"
    title
    echo -e "${YAY}Thank you for considering donating a small amount of ${YAY}XMR to Thotbot!
\n${WSTD}Thotbot runs xmrguide (${LSTD}xmrguide42y34onq.onion${WSTD}) the best Monero guide for Tails
and Whonix, that helped me learn the basics of using Monero back when I was a 
newbie and inspired me to create ${MoneroMixer}${WSTD}. He also wrote scripts that I 
borrowed some code from to improve this program so he deserves this credit
and hopefully your donation." 
    donation_options
}

donate_custom() {
    title
    print_balance "--type limited"
    read -ra donateamount <<<$(zenity --entry --title="Please Enter a Donation Amount" \
            --text="Thank you for donating! Your contribution helps make this project possible. 
\nPlease enter the amount in XMR that you would like to donate: " \
            --ok-label="Donate!" --cancel-label="Cancel :(")
    [ -z $donateamount ] && $previous_menu
    title
    printf "${YAY}Thank you for your donation of ${WBU}$donateamount ${YAY}XMR! You are awesome!
\n\n${STD}Your donation is processing please wait...\n"
    printf "\nSending ${WBU}$donateamount ${YAY}XMR${STD} to ${WSTD}$dev${STD}...\n${GRN}"

    wallet_cmd "transfer unimportant 11 $devaddress $donateamount" \
    | zprog "Sending your donation. You are awesome" \
            "Sending $donateamount XMR to $dev_uncolored..." ""
    wallet_post_transfer

    donation_thank_you
}

donate_remaining() {
    title
    printf "${YAY}Thank you for your donation to help support this project. You are awesome!\n\n"

    local choice
    printf "${STD}Press ${YAY}1${STD} to continue with dontation or ${YAY}2${STD} to cancel:${YAY} "

    read -r choice
	case $choice in
		1) title  ;;
		2) $previous_menu ;;
		*) echo -e "${ERR}Invalid Choice...${STD}" && sleep 2
	esac

    printf "\n${STD}Your donation is processing please wait a moment...\n"
    wallet_cmd "refresh"

    printf "\nSending your leftover ${YAY}XMR${STD} to ${WSTD}$dev...\n"

    wallet_cmd "sweep_all $(wallet_max_index) unimportant 11 $devaddress" \
    | zprog "Sending your donation. You are awesome!" "Donating your remaining XMR..." ""
    wallet_post_transfer

    donation_thank_you
}

donation_thank_you() {
    title
    printf "${YAY}Thank you for your donation! Your donation has been sent\nsuccessfully. You are awesome!!"
    zenity --info --ellipsize --icon-name="" --title="Thank You For Your Donation!" \
           --text="Thank you for your donation to help support this project. You are awesome!" \
           --ok-label="Return to Main Menu"
    main_menu
}

donation_data_in() {
    balremaining=${donation_data[1]}
    minacc=${donation_data[2]}
    rate=${donation_data[3]}    
    maxbtcout=${donation_data[4]}
    unset -v donation_data
}


xmrto_donation() { 
    devaddress="4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn"
    dev="Fungibility${M}atters"
    dev_uncolored="FungibilityMatters"
    title
    printf "${ERR}Important Reminder: ${STD}After completing your last withdrawal your
Monero wallet balance is only ${WBU}${balremaining} ${YAY}XMR${STD}. 
\nAt the current exchange rate of ${WBU}${rate} ${YAY}XMR${WSTD} per ${YAY}BTC${STD} this will not be enough 
to withdrawal since the minimum amount you can send anonymously via ${WSTD}XMR.to${STD} 
is ${WBU}0.001 ${YAY}BTC${STD} and you can only send ${ERR}${maxbtcout} ${YAY}BTC${STD}.
\n${WSTD}To withdrawal your leftover balance you can send ${YAY}XMR${WSTD} to an external address by 
choosing option ${YAY}3${WSTD} in the withdrawal menu. ${YAY}Or if you're feeling ${STD}generous${YAY} please
considering donating some of your leftover balance to the $MoneroMixer developer.
\n${STD}Your donation would be used to fund: 
- ${WSTD}Integrating additional secure withdrawal methods to support more coins 
and allow you to withdraw your balance as... ${STD}AMAZON GIFT CARDS${WSTD} and more!${STD} 
- ${WSTD}Building a reliable GUI so you can use $MoneroMixer${WSTD} without having to 
open up a terminal window ever again!\n"

    local choice
    printf "${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
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
    dev_uncolored="FungibilityMatters"
    title
    printf "${ERR}Important Reminder: ${STD}After completing your last withdrawal your
Monero wallet balance is only ${WBU}${balremaining} ${YAY}XMR${STD}. 
\nThe current minimum amount you can send anonymously via ${WSTD}${exchange}${STD} 
is ${WBU}${minacc} ${YAY}XMR${STD} and you can only send ${ERR}${balremaining} ${YAY}XMR${STD}.
\n${WSTD}To withdrawal your leftover balance you can send ${YAY}XMR${WSTD} to an external address by 
choosing option ${YAY}1${WSTD} in the withdrawal menu. ${YAY}Or if you're feeling ${STD}generous${YAY} please
considering donating some of your leftover balance to the developer.
\n${STD}Your donation would be used to fund: 
- ${WSTD}Integrating additional secure withdrawal methods to support more coins 
and allow you to withdraw your balance as... ${STD}AMAZON GIFT CARDS${WSTD} and more!${STD} 
- ${WSTD}Building a reliable GUI so you can use $MoneroMixer${WSTD} without having to 
open up a terminal window ever again! \n"
    local choice
    printf "${STD}Enter ${YAY}1${STD} to donate your leftover balance, ${YAY}2${STD} to donate a custom amount, 
or ${YAY}3${STD} to return to menu without donating:${YAY} "
	read -r choice
	case $choice in
		1) donate_remaining ;;
		2) donate_custom ;;
        3) withdrawal_menu ;;
		*) printf "${ERR}Invalid Choice...${STD}" && sleep 2
	esac
}

