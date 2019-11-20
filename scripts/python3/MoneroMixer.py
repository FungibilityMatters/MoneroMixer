from sys import argv, stdin, stdout, stderr
import argparse
import mmutils
import display
import exchange
import wallet 
import excomp

REQUIRES_EXCHANGE = ("deposit", "withdraw", "rates", "status")
REQUIRES_WALLET = ("balance", "address", "show_transfers", "make_xmr_qr")
QRCODE = ("make_qr, print_qr, make_xmr_qr, print_xmr_qr")  


class TorPydoHandler(object):
    """Parses and handles input from MoneroMixer.sh when MoneroMixer.py 
       is run inside a torsocksified shell. See mmutils.sh"""

    def __init__(self, args):
        self.stdin_bytes = args.stdin_bytes
        self.fd_bytes = args.fd_bytes if args.fd_bytes else 0
        self.cmd = args.command
        
        self.inputDict = {}
        #Read exact number of bytes piped from torpydo (See mmutils.sh)
        for pair in stdin.read(self.stdin_bytes).split("/"):
            #Parse input from STDIN into dict
            try: 
                key, value = pair.split("%%%")
                self.inputDict[key.strip()] = value.strip()
            except:
                self.inputDict[pair.split("%%%")[0]] = ""

        #Read from anonymous pipe created via process substituion
        #Usually at /dev/fd/63 hence args.fd and fdlines
        if args.fd:
            with open(args.fd, "r") as fd:
                self.fdlines = fd.readlines()
        else:
            self.fdlines = []
        
        #Initialize a MoneroWallet if required to do command 
        if self.cmd in REQUIRES_WALLET:
            self.monero_wallet = wallet.MoneroWallet(self.inputDict)
        #Initialize the appropriate ExchangeHandler if required to do command
        if self.cmd in REQUIRES_EXCHANGE:
            if self.inputDict.get("exchange") == "Godex.io":
                self.exchange_handler = exchange.Godex(self.inputDict)
            elif self.inputDict.get("exchange") == "MorphToken":
                self.exchange_handler = exchange.Morph(self.inputDict)
            elif self.inputDict.get("exchange") == "XMR.to":
                self.exchange_handler = exchange.Xmrto(self.inputDict) 
            
            
    def do_command(self):
        #Run command with its appropriate cmd_handler.
        if self.cmd in REQUIRES_EXCHANGE:
            #Exchange commands: See exchange.py
            self.exchange_cmd_handler()
        elif "qr" in self.cmd:
            #QRCode commands: See display.py
            self.qrcode_cmd_handler()
        elif self.cmd in REQUIRES_WALLET:
            #Monero wallet commands: See wallet.py
            self.wallet_cmd_handler()
        else:
            #Utility/helper function commands: See mmutils.py and excomp.py
            self.utility_cmd_handler()
    
    
    #Exchange commands: See exchange.py
    def exchange_cmd_handler(self):
        if self.cmd == "deposit":
            #Deposit to Monero wallet
            self.exchange_handler.deposit()
        elif self.cmd == "withdraw":
            #Withdraw from Monero wallet
            self.exchange_handler.withdraw()
        elif self.cmd == "rates":
            #Query exchange rates from the specified exchange
            self.exchange_handler.get_rates()
        elif self.cmd == "status":
             #Query order status from the specified order id
            self.exchange_handler.get_order_status()
    
    
    #Monero wallet commands: See wallet.py
    def wallet_cmd_handler(self):
        if self.cmd == "balance":
            #Print wallet balance and crypto trading prices
            self.monero_wallet.print_balance(self.inputDict)
        elif self.cmd == "address":
            #Parse and strip and print current XMR receiving address
            self.monero_wallet.print_address()
        elif self.cmd == "show_transfers":
            #Create a table displaying all XMR transfers.
            self.monero_wallet.show_transfers(self.fdlines)

            
    #QRCode commands: See display.py         
    def qrcode_cmd_handler(self):
        #Read qr data from building QR
        qrdata = self.inputDict["qrdata"].split()
        #Read QRCode to format and print pretty
        qrlines = [line.replace("\n", "") for line in self.fdlines]
        
        if self.cmd == "make_xmr_qr":
            #Build a QRCode from the current XMR receiving address.
            display.make_qr("XMR", [self.monero_wallet.address])    
        elif self.cmd == "make_qr":
            #Build a QRCode for a non-XMR receiving address. 
            display.make_qr(self.inputDict["coin"], qrdata)
        elif self.cmd == "print_qr":
            #Format, could and prettyprint the QRCode
            display.print_qr(self.inputDict["coin"], qrdata, qrlines)        

            
    #Utility/helper function commands: See mmutils.py and excomp.py for compare
    def utility_cmd_handler(self):
        if self.cmd == "update":
            #Update current prices and available coin in backgroud.
            mmutils.Updater.update(self.inputDict["crypto"], self.inputDict["fiat"])
        elif self.cmd == "icons":
            #Download new coin icons
            mmutils.Updater.download_icons()
        elif self.cmd == "extraid":
            #Check if a given coin requires an extra id
            mmutils.Coinquery.check_extra_id(self.inputDict["coin"])   
        elif self.cmd == "coins":
            #Get all supported coins for a given exchange 
            mmutils.Coinquery.get_coins(self.inputDict["exchange"])
        elif self.cmd == "compare":
            #Compare exchanges by rate for multiple coins: See excomp.py
            excomp.compare_rates(self.inputDict)
        elif self.cmd == "validate":
            #Validate XMR,BTC,LTC,ETH,BCH, and DASH address by regex.
            mmutils.validate_address_arg(self.inputDict)

            
if __name__ == "__main__":
    #Parse command to run, and the number of bytes to read from input.
    parser = argparse.ArgumentParser(prog="torsocks python3 MoneroMixer.py")        
    parser.add_argument("--command", type=str)
    parser.add_argument("--stdin_bytes", type=int)
    parser.add_argument("--fd", type=str)
    parser.add_argument("--fd_bytes", type=int)
    args = parser.parse_args()
    
    #Initialize a TorPydoHandler from args to read the data passed from 
    #torpydo. See mmutils.sh
    torpydo_handler = TorPydoHandler(args)
    
    #Attempt to read additional data from STDIN. Exit if any unexpected bytes.
    unexpected_bytes = len(stdin.read())
    if unexpected_bytes > 0:
        error_out("ERROR: ADDITIONAL DATA READ FROM STDIN",
                  "{} unexpected bytes were read from standard input".format(unexpected_bytes))
    #Check if input was passed via process substitution.         
    if args.fd:
        #Attempt to read additional data from fd. Exit if any unexpected bytes.
        with open(args.fd) as fd:
            unexpected_bytes = len(fd.read())
            if unexpected_bytes > 0:
                error_out("ERROR: ADDITIONAL DATA READ FROM {}".format(args.fd),
                          "{} unexpected bytes were read from {}".format(args.fd))
    del args
    
    #Do command if no unexpected data was found.
    torpydo_handler.do_command()
    del torpydo_handler
