# MoneroMixer Changelog
## Update v1.2:

**New Features:**
- BitPay: Users can now anonymously pay BitPay (BTC) Payment Protocol URL invoices with XMR.to. This feature can be accessed from the XMR.to menu.
- Extra Id Support: Dual QRCodes and additional entry boxes allow users to now transact coins that require extra identifiers for transaction processing such as XRP destination tags or EOS memos. 
- XMR QRCodes: When a user views their current Monero receiving address they are now shown both a QRCode and a string of the address. This is to make it easier for users with mobile wallets such as CakeWallet to easily deposit XMR.
- XMR Transaction History: Users can now open window a that shows their complete XMR transaction history in a nicely formatted table. This requires a password and can be accessed via Wallet Options.
- Restore/Import: Users can now easily restore or import existing wallet's from seed. This option is available from the login screen.
- Background Updates: Current exchange rates and coin availabilty are now updated in the background so user's no longer have to wait for menu's to load. The amount of time between updates is can be changed from the settings and utilities menu. 
- Resizable Rate Tables: Users can now expand their window size to view more accurate details when comparing exchanges. (The wider the window, the more decimal places display)

**UI/UX Simplifications:**
- Application Launchers: Launchers are now created on a user's desktop and in Applications > Internet so that starting MoneroMixer no longer requires a terminal. 
- Icons: When viewing lists of available coins, each coin's icon is shown next to it in the list. MoneroMixer also now has it's own custom icon. 
- Improved navigation: Additional buttons have been added throughout the UI to simply the process of switching between screens/menus.  
- Simplified Setup: The installation and setup process has been simplified significantly.
- Seed Confirmation: User's must now check a box confirming that they have written down their seed before being able to continue.
- Dedicated Help Menus: Each exchange has a help option that shows user's how to contact support. The help menu now contains links to this r/moneromixer. 
- Tails users receive a warning if they attempt to install MoneroMixer outside of their Persistent storage. If the user does not have persistence setup, they are shown setup instructions.

**Security Improvements:**
- All sensitive user data that is either created or decrypted now gets piped directly through openssl's aes-256-cbc encryption cipher before it is written so that no sensitive data is ever stored in disk memory. (Decrypted data does exist in RAM for a short period of time but this is unavoidable since encrypted data must be decrypted in RAM so that it can be used.)
- Monero wallet passwords, addresses, amounts, etc are now passed to monero-wallet-cli via here string redirection rather than command line arguments so that nothing is visible locally to ps.
- Fake user-agents, secure protocol TLSv1.2, and redirect blocking are now used to improve the security of the wget request that downloads the monero software from getmonero.org. This is to reduce traceability and to prevent MITM attacks. 
- Monero binaries are automatically checked against hard-coded hashes also to prevent MITM attacks. If the hashes do not match users are shown a series of warnings about MITM attacks and instructions for how to prevent them by manually downloading the monero software.
- Password authentication is required for all actions that involve decrypting data and/or accessing a user's wallet. (Ex: viewing previous transactions, withdrawing, viewing seed, etc)
- Quitting with CTRL-C is no longer required to exit securely since all data is encrypted or shredded automatically.


**Structural Changes:**
- Upgrade from Monero v0.1.4.2.0 to v0.1.5.0.0.
- MoneroMixer.sh and MoneroMixer.py have been broken up into multiple smaller files that are sourced or imported respectively.
- The majority of the .py files have been converted to OOP. The exception to this is the display.py which has not been updated much because I plan to get rid of it entirely in the future when I redesign the UI . 


**Bug Fixes:**
- The Tails "unknown cipher" and "--pbkdf2 would be better" errors reported by /u/OWDpart2 have been fixed by making pbkdf2 the default password based key derivation function on all systems.  
- Sweep-all not sending from all indexes reported by /u/etan_ashman has been fixed by appending a comma separated list of all address indices to the sweep_all command.
- Slow refresh for new wallets was fixed by adding a --daemon-address argument when generating wallets. 
- Handling of server side daemon issues has been improved by expanding the list of daemon errors that caught by the daemon error handler so that users are prompted to change their daemon address when errors occur. 


## Update v1.1:
- Easy (Automatic) setup now works on Whonix, and Ubuntu! Users on (almost) all 64bit systems, can now easily setup MoneroMixer and create a wallet by simply copy and pasting a line of code. Just like on Tails as shown in the video on my original post.
- All python requests now include a randomly selected user agent in their header, allow_redirects is set to false, and timeout after 30 seconds per the suggestions of /u/dsc__
- An update utility is now available in the utilities menu so user's can update their MoneroMixer and monero-wallet-cli software to the latest version without having to manually copy over pre-existing wallets. The update feature must be manually selected by the user so that this feature can never be used to update a user's MoneroMixer setup with malicious code.
- Enter the Monero Wallet CLI is now also available in the utilities menu so users can easily access the full features available within the Monero CLI if necessary, without having to worry about starting it with torsocks, a remote-daemon, --no-dns flags, etc.
- Sending entire XMR balance (sweep_all) option now available when withdrawing/sending XMR by entering 'ALL' as the amount to send. 
- The "Error: No withdrawal options" bug mentioned by /u/TheWubMunzta that sometimes occured when withdrawing only XMR has now been fixed properly. The issue was caused by the ticker of TrueChain which was added to Godex a few days ago. The ticker "TRUE" caused this coin to always be selected when passed to the zenity --list dialog used to select coins causing it to return incorrect selections.
- The Error causing no withdrawal/deposit options to show when Godex temporarily a disables a popular coin has also been fixed. 
- During setup if the Monero software is not downloaded correctly, the user is given the option to try again or shown how to download the files manually from getmonero.org
