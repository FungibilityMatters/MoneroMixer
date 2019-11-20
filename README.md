## HOW TO SETUP: 
**COPY THIS COMMAND IN ITS ENTIRETY BEFORE YOU BEGIN THE SETUP STEPS BELOW:**

`mmdir="$(zenity --file-selection --title="Select folder where you would like to install MoneroMixer" --directory 2> /dev/null)"; [ -n "$mmdir" ] && cd "$mmdir" && ([ "$USER" = "amnesia" ] || sudo -p " Enter password for $USER to begin downloading MoneroMixer: " apt update 2> /dev/null) && (([ "$USER" = "amnesia" ] || sudo apt -y install git zenity python3-pip tor 2> /dev/null) && torsocks git clone https://github.com/FungibilityMatters/MoneroMixer) | (zenity --progress --title="Downloading MoneroMixer" --text="Please wait. MoneroMixer will start automatically once finished..." --pulsate --auto-close --auto-kill 2> /dev/null) && cd MoneroMixer && chmod 500 scripts/shell/setup.sh && ./scripts/shell/setup.sh; exit`

**SETUP STEPS:**
1. Right click anywhere on your desktop. On Tails or Ubuntu select "Open in Terminal" on Whonix select "Applications" > "Terminal Emulator". This will open a terminal window. 
2. Paste the command you copied above into the terminal window then press ENTER.
3. Select the folder where you would like to install MoneroMixer, then click "Ok".
4. If you are NOT using Tails, you will be asked for your password before the download begins. (Tails users can ignore this step)
5. Wait for the download and installation to complete. MoneroMixer will start automatically once finished.

Now all you have to do is follow the prompts within the program and your Monero Wallet will be generated for you. You will be asked for a name and password for your new wallet. 


## HOW TO START MANUALLY: 
**(TAILS USERS MUST DO THIS EACH TIME YOU REBOOT)**

1. Right click anywhere on your desktop. On Tails or Ubuntu select "Show Desktop in Files" on Whonix select "Applications" > "File Manager". This will open a file manager window.
2. In the file manager window, open your MoneroMixer folder then double-click the file named "start" to open it.
3. In start file find the line beginning with "Your startup command is:". Copy the whole command from "cd" to "exit".
4. Open a terminal window and paste the startup command into the terminal then press ENTER. 
    (See step 1 above if you forgot how to open a terminal)             


## FAQ:

**What does MoneroMixer do?**

- Simplifies the process of creating a Monero wallet on Tails/Whonix and setting it up to work over tor.
- Allows you to deposit or withdraw XMR, BTC, LTC, ETH and 100+ other coins to and from your wallet via non-KYC exchanges without using Javascript.  
- Objectively compares exchange rates between non-KYC exchanges to make sure that you always get the most bang for your buck. 


**How does MoneroMixer protect your privacy?**

- Monero: The inherent fungibility and immaculate cryptography of Monero allows your coins to become truly untraceable once you exchange them for XMR through a non-KYC exchange. 
- Non-KYC exchanges: Godex.io, MorphToken and XMR.to all do not have know your customer (KYC) policies, meaning that you are able to exchange without giving any personal information whatsoever. 
- Torsocks: Forces all network connections used by your Monero wallet and the Python script that facilitates the exchanges to be routed only through the Tor network. This prevents IP and DNS leaks so your real IP address is never associated with your wallet or any exchange orders you create.
- User-agent spoofing: A fake user-agent string is randomly selected for every HTTP request made by MoneroMixer. This hides information about your device from the exchange/price-query APIs and prevents correlation of subsequent requests.  
- NO JavaScript: Preventing you from being vulnerable to the many known JavaScript security vulnerabilities such as XSS, CSRF, clickjacking etc.
- NO Browser: Preventing you from being vulnerable to potentially undiscovered security vulnerabilities in the Tor Browser such as the recent Sandbox Escape. 
- Encryption and shredding: All your sensitive data used or created by MoneroMixer is piped through Openssl's AES-256-cbc encryption cipher before it is stored in disk memory. Your data is only decrypted in RAM when MoneroMixer passes it to the monero-wallet-cli and/or MoneroMixer.py to facilitate a transaction. All files that are no longer needed are immediately shredded (Deleted so they cannot be recovered).


**How do I send, receive, or mix my coins anonymously?**

Deposit: 
1. Select coins and enter an estimated deposit amount to compare deposit options.  
2. Choose a coin and exchange to deposit with from the list.
3. Enter a refund address so you don’t lose your coins if any errors occur. 
4. Send your coins to the deposit address shown, then press 1 to refresh until the exchange is complete. 
5. Go back to the main menu and press 4 to refresh your wallet until your XMR balance is unlocked.

**If you care about your privacy, you should wait at least an hour, ideally longer, between depositing and withdrawing to prevent the possibility of timing-based blockchain analysis being used to link your transactions.**

Withdraw:
1. Select coins and enter an estimated withdrawal amount to compare withdrawal options.
2. Choose a coin and exchange to withdraw with from the list.
3. Enter a destination address and amount in the coin indicated.
4. Confirm the withdrawal then your XMR will be sent to the exchange you selected, and the exchange will send the coin you selected to the destination address you entered. 


## A note from the developer:
I made this program with the intention of helping people, it is 100% free to use
and donations are not required by any means. However, if you're feeling generous, 
I would greatly appreciate a donation of any amount you're willing to give to help fund this project. 

Your donation would be used to fund: 
- Implementing additional non-KYC exchanges.
- Integrating additional secure withdrawal methods.  For example, XMR.to to Bitrefill to allow you to withdraw your XMR balance as gift cards.
- Building a real GUI for MoneroMixer so you never have to open up a terminal window ever again!

If you’re feeling generous donate XMR to: `4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn`
