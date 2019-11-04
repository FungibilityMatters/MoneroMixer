**Changelog:**

Update v1.1:
- Easy (Automatic) setup now works on Whonix, and Ubuntu! Users on (almost) all 64bit systems, can now easily setup MoneroMixer and create a wallet by simply copy and pasting a line of code. Just like on Tails as shown in the video on my original post.
- All python requests now include a randomly selected user agent in their header, allow_redirects is set to false, and timeout after 30 seconds per the suggestions of /u/dsc__
- An update utility is now available in the utilities menu so user's can update their MoneroMixer and monero-wallet-cli software to the lastest version without having to manually copy over pre-existing wallets. The update feature must be manually selected by the user so that this feature can never be used to update a user's MoneroMixer setup with malicious code.
- Enter the Monero Wallet CLI is now also available in the utilities menu so users can easily access the full features available within the Monero CLI if neccessary, without having to worry about starting it with torsocks, a remote-daemon, --no-dns flags, etc.
- Sending entire XMR balance (sweep_all) option now available when withdrawing/sending XMR by entering 'ALL' as the amount to send. 
- The "Error: No withdrawal options" bug mentioned by /u/TheWubMunzta that sometimes occured when withdrawing only XMR has now been fixed properly. The issue was caused by the ticker of TrueChain which was added to Godex a few days ago. The ticker "TRUE" caused this coin to always be selected when passed to the zenity --list dialog used to select coins causing it to return incorrect selections.
- The Error causing no withdrawal/deposit options to show when Godex temporarily a disables a popular coin has also been fixed. 
- During setup if the Monero software is not downloaded correctly, the user is given the option to try again or shown how to download the files manually from getmonero.org
