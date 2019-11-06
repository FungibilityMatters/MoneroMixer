#UPDATE FUNCTIONS
confirm_update() {
    if zenity --question --ellipsize \
              --title="Confirm update" \
              --text="All data inside your current MoneroMixer folder will be destroyed after your wallet(s) are copied to your new updated MoneroMixer folder.

If you created any files inside your current MoneroMixer folder that you would like to keep, you should relocate them to another folder before continuing.
    
Are you sure you want to continue?" \
              --ok-label="Update MoneroMixer now" 2> /dev/null
    then 
        clean_all_no_exit && update
    else
        $previous_menu
    fi 
}

update() {
    pre_update_wd=$PWD
    title 
    printf "Updating MoneroMixer and it's dependencies...
\n${ERR}(This may take some time. Please wait.)${WSTD}"

    #while ! [ -d MoneroMixer ]; do 
    #    cd ../
    #done
    cd "$MMPATH"
    cd ../
    if ! test -e MoneroMixer_v1.2; then
        mv MoneroMixer MoneroMixer_v1.2 
        printf "\n"
        ([ $USER = "amnesia" ] || sudo -p " Enter password for $USER to begin downloading MoneroMixer: " apt update 2> /dev/null) \
        || (test $USER = "amnesia" && update_error)

        ((([ $USER = "amnesia" ] || sudo apt -y install git zenity python3-pip tor 2> /dev/null) \
        && torsocks git clone https://github.com/FungibilityMatters/MoneroMixer) \
        | (zenity --progress --title="Updating MoneroMixer" \
                  --text="Please wait. MoneroMixer will start automatically once finished..." \
                  --pulsate --auto-close --auto-kill 2> /dev/null)) || update_error

        if [ -d MoneroMixer -a -d MoneroMixer_v1.2 ] ; then 
            cd MoneroMixer
            chmod +x scripts/shell/setup.sh 
            [ -d ../MoneroMixer_v1.2/Wallets ] && mv ../MoneroMixer_v1.2/Wallets ../MoneroMixer_v1.2/wallets
            ./scripts/shell/setup.sh update && mv ../MoneroMixer_v1.2/wallets wallets         
            if [ -d wallets ]; then 
                rm -rf ../MoneroMixer_v1.2
                ./start
            else
                update_error
            fi
        else
            update_error
        fi
    else
    cd $pre_update_wd
        zerror "ERROR: A folder/file named 'MoneroMixer_v1.2' already exists" "A folder or file named 'MoneroMixer_v1.2' already exists in the directory where you installed MoneroMixer. 

Remove or relocate this folder/file to another directory then press 'Ok' to continue updating MoneroMixer."
    update
    fi
}

update_error(){
    while ! [ -d MoneroMixer_v1.2 ]; do 
        cd ../
    done
    [ -d MoneroMixer ] && rm -rf MoneroMixer
    mv MoneroMixer_v1.2 MoneroMixer
    cd MoneroMixer

    zerror "ERROR: Failed to update MoneroMixer" "Error failed to update MoneroMixer. 

Your current installation has not been modified but the folder name has been changed to MoneroMixer_v1.2 to prevent it from being removed by git in the case of a failed download. 

Try again or update manually with the following steps:
1. Open Tor browser and go to https://github.com/FungibilityMatters/MoneroMixer

2. Reinstall MoneroMixer in another directory. (Any folder without MoneroMixer)

3. Copy the 'wallets' folder from your current MoneroMixer folder and paste in to the MoneroMixer folder of your new installation.

4. Start MoneroMixer from your new installation and you will be able to access your wallet(s).
"
    ./start
}
