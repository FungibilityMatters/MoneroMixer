# MoneroMixer v1.0: The easiest way to use Monero to anonymously exchange and properly mix XMR, BTC, LTC, ETH, BCH, & 100+ other coins on Tails OS or Whonix.

TO SETUP: 
1. Right click anywhere on your desktop. Select "Open Terminal" on Tails or Ubuntu or "Applications" > "Terminal Emulator" on Whonix. This will open a terminal window. 
2. Copy and paste then line below in its entirety into the terminal window then press ENTER.

`cd "$(zenity --file-selection --title="Select folder where you would like to install MoneroMixer" --directory 2> /dev/null)" && (test $USER = "amnesia" || sudo -p "
Enter password for $USER to begin downloading MoneroMixer: " apt update 2> /dev/null) && ((test $USER = "amnesia" || sudo apt -y install git zenity python3-pip tor 2> /dev/null) && torsocks git clone https://github.com/FungibilityMatters/MoneroMixer) | (zenity --progress --title="Downloading MoneroMixer" --text="Please wait. MoneroMixer will start automatically once finished..." --pulsate --auto-close --auto-kill 2> /dev/null) && cd MoneroMixer && chmod +x setup.sh && ./setup.sh`

3. Select the location when you would like to install MoneroMixer, then click "Ok".
4. If you are NOT using Tails, you will be asked for your password before the download begins. (Tails users can ignore this step)
In the terminal window you will see that MoneroMixer has begun downloading. MoneroMixer will start automatically once the download is complete. 

Now all you have to do is follow the prompts within the program and your Monero Wallet will be generated for you. You will be asked for a name and password for your new wallet. 

TO RUN AGAIN AFTER YOUR FIRST TIME: 
1. Open the folder called "MoneroMixer" 
2. Right click and select "Open in terminal"
3. Type `./start` then press ENTER.

FAQ:

**What does MoneroMixer do?**
- Simplifies the process of creating a Monero wallet on Tails and setting it up to work over tor.
- Allows you to deposit or withdraw XMR, BTC, LTC, ETH and 100+ other coins to or from your wallet via non-KYC exchanges without using Javascript.  
- Objectively compares exchange rates between non-KYC exchanges to make sure that you always get the most bang for your buck. 

**How does MoneroMixer protect your privacy?**
- Monero: The inherent fungibility and immaculate cryptography of Monero allows your coins to become truly untraceable once you exchange them for XMR through a non-KYC exchange. 
- Non-KYC exchanges: Godex.io, MorphToken and XMR.to all do not have know your customer (KYC) policies, meaning that you are able to exchange without giving any personal information whatsoever. 
- Torsocks: Forces all network connections used by your Monero wallet and the Python script that facilitates the exchanges to be routed only through the tor network . This prevents IP and DNS leaks so your real IP address is never associated with your wallet or any exchange orders you create.  
- NO JavaScript: Preventing you from being vulnerable to the many known JavaScript security vulnerabilities such as XSS, CSRF, clickjacking etc.
- NO Browser: Preventing you from being vulnerable to potentially undiscovered security vulnerabilities in the Tor Browser such as the recent Sandbox Escape. 
- Encryption and shredding: All sensitive data used or created by MoneroMixer is stored in AES 256-bit encrypted files that are only decrypted when read, then immediately re-encrypted. All files that are no longer needed are immediately shredded (Deleted so they cannot be recovered).     

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


Note from the developer:
I made this program with the intention of helping people, it is 100% free to use
and donations are not required by any means. However, if you're feeling generous, 
I would greatly appreciate a donation of any amount you're willing to give to help fund this project. 

Your donation would be used to fund: 
-Implementing additional non-KYC exchanges.
-Integrating additional secure withdrawal methods.  For example, XMR.to to Bitrefill to allow you to withdraw your XMR balance as gift cards.
-Building a real GUI for MoneroMixer so you never have to open up a terminal window ever again!

If you’re feeling generous donate XMR to: `4AmmKxwNxezFuCsNPkujS2SxXqDTuchbE1BzGGMggFCfeGQm9ew2FTjYzVwZvwQhaMGmTAJKUNCc1LboGyVwUb4t1bUpvNn`

