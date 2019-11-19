wallet_set_login(){
    title
    printf "$1"

    set_IFS "|"
    read -r name password <<<$(zenity --forms --icon-name="dialog-password" \
                               --title="$2" --text="$3" \
                               --add-entry="Wallet name:" \
                               --add-password="Password:"  \
                               --timeout 200 2> /dev/null)
    unset_IFS

    [ -z "$name$password" ] && clean_all_exit
    [ -z "$name" ] && required_error "wallet name"
    [ -z "$password" ] && required_error "wallet password"

    if ! [ -e "$name/$name".keys ]; then
        mkdir "$name"
        cd "$name"
    else
        zerror "Error: $name already exits" "Error: A wallet named $name already exists.\nTry again with another name."
        wallet_set_login "$1" "$2" "$3"
    fi
}

gen_wallet_and_seed_file() {
    wallet_set_login "To begin enter a ${YAY}name${STD} and ${YAY}password${STD} for your new Monero wallet. [${ERR}BOTH 1 WORD MAX${STD}]\n" \
    "Create a new Monero wallet" \
    "Set a name and password for your new Monero Wallet"
    
    
    [ -e ../../settings ] && mv ../../settings settings || echo " "
    [ -e settings ] || setup_choice
    read_settings

    #$previous_menu="gen_wallet_and_seed_file"
    title
    printf "${YAY}Generating your Monero wallet...\n${STD}
${STD}Wallet name set to: '${YAY}$name${STD}'
\n${STD}Wallet password set to: '${YAY}${password}${STD}'
\n${ERR}Record your wallet name and password somewhere safe.
 ${STD}"

    $(torsocks ../../monero-software/monero-wallet-cli \
    --generate-new-wallet "$name" --daemon-address $daemon --no-dns \
    --mnemonic-language English <<<"$password" | encrypt wallet-cli-out.enc ) \
    | zprog "Generating your Monero wallet" "Generating wallet: $name..."
    wallet_display_seed
}


wallet_display_seed(){
    declare -a seed
    [ -z "${seed[20]}" ] && readarray -n 24 seed <<<$(decrypt wallet-cli-out.enc)

    title
    printf "${GRN}A new Monero wallet named ${YAY}$name${GRN} has been created!

${WSTD}The following mnemonic seed was used to generate: ${YAY}$name${STD}
*********************************************************************
${WBU}${seed[20]}${seed[21]}${seed[22]}${STD}*********************************************************************
${WSTD}To copy your seed highlight it then right click and select 'Copy'. 
DO NOT attempt to use CTRL-C to copy your seed. 

${ERR}IMPORTANT: These 25 words can be used to recover access to your wallet.
Write them down VERY carefully and store them somewhere safe and secure.

THIS IS EXTREMELY IMPORTANT. ONLY CONTINUE IF YOU HAVE WRITTEN DOWN YOUR SEED.${STD}\n"

    seedfile="${name}-SEED"
    echo "The following mnemonic seed was used to generate: $name
****************************************************************
${seed[20]}${seed[21]}${seed[22]}****************************************************************
Creation date: $(date)

IMPORTANT: these 25 words can be used to recover access to your wallet. 
Write them down and store them somewhere safe and secure." | encrypt ${seedfile}.enc
    conf_write_down_seed
}

conf_write_down_seed(){
    if ! zenity --text-info --filename <(decrypt ${seedfile}.enc) \
                --title="IMPORTANT: Write down this seed before continuing!" \
                --ok-label="I have written down my seed and am ready to continue" \
                --checkbox="I understand that these 25 words can be used to recover access to my wallet 
    and I have written them down somewhere safe and secure." \
                --cancel-label="" 2> /dev/null 
    then 
        conf_write_down_seed
    fi
}

backup_seed() {
    title
    printf "${STD}Encrypted mnemonic seed ${YAY}${seedfile}.enc${STD} saved to: 

${WBU}$PWD/${YAY}$seedfile.enc${WSTD}


${ERR}NOTE: ${YAY}${seedfile}.enc${ERR} is encrypted so you will not be able to read it 
unless you decrypt it via the Settings and Utilities Menu by choosing 
option ${YAY}4${ERR} ""Decrypt Wallet Seed""
" 

zenity --info --ellipsize --title="An encrypted backup of your seed has been saved as: ${seedfile}.enc" --text="An encrypted backup of your mnemonic seed has been sucessfully saved as: ${seedfile}.enc

NOTE: ${seedfile}.enc is encrypted so you will not be able to read it unless you decrypt it via the Settings and Utilities Menu by choosing option 4 'Decrypt Wallet Seed'." --icon-name="dialog-password" 2> /dev/null
}

#not currently implemented
wallet_restore_from_seed(){
    previous_menu="clean_all_exit"
    wallet_set_login "Enter a new ${YAY}name${STD} and ${YAY}password${STD} the Monero Wallet you would like to restore.
\n${WBU}You will need to enter your 25 word mnemonic seed in the next step." \
    "Restore a wallet from seed"\
    "Enter a new name and password the Monero Wallet you would like to restore.
\nYou will need to enter your 25 word mnemonic seed in the next step."
    
    use_default_settings
    write_settings

    seed=$(zenity --text-info \
           --title="Enter your 25 word mnemonic seed to restore your wallet" \
           --ok-label="Restore wallet from this seed" \
           --editable 2> /dev/null)
    [ -z "$seed" ] && clean_all_exit

    restore_date=$(zenity --calendar \
                    --title="Select the date when you first created $name" \
                    --text="This date will be used to determine the block height to restore your wallet from.\n\nNOTE: If you cannot remember the date exactly,\nchoose a date EARLIER than you think to insure that all your coins are resored\n" \
                    --date-format='%Y-%m-%d' 2> /dev/null)
    [ -z "$restore_date" ] && clean_all_exit

    title
    printf "${YAY}Restoring $name from seed...\n
${WBU}Once completed this window will close and you will be asked to login."
    (torsocks ../../monero-software/monero-wallet-cli \
                     --restore-deterministic-wallet \
                     --restore-date=$restore_date \
                     --daemon-address $daemon \
                     --generate-new-wallet "$name" \
                     --password "$password" <<<"$seed
"   | encrypt wallet-cli-out.enc) \
    | $(zprog "Restoring your Monero wallet" "Restoring wallet: $name...")
    
    cd "$MMPATH"
    if [ -e "wallets/$name/$name.keys" ]; then  
        zenity --notification \
               --text="$name has been succesfully restored!" 2> /dev/null
    else
        rm -rf "wallets/$name"
        zerror "Error: the seed you entered is not valid" "Error: the seed you entered is not valid. Try again."
    fi
    ./start
    exit
}
