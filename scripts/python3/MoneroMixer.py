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
    def __init__(self, args):
        self.stdin_bytes = args.stdin_bytes
        self.fd_bytes = args.fd_bytes if args.fd_bytes else 0
        
        self.inputDict = {}
        for pair in stdin.read(self.stdin_bytes).split("/"):
            try:    
                key, value = pair.split("%%%")
                self.inputDict[key.strip()] = value.strip()
            except:
                self.inputDict[pair.split("%%%")[0]] = ""

        if args.fd:
            with open(args.fd, "r") as fd:
                self.fdlines = fd.readlines()
        else:
            self.fdlines = []
        
        self.cmd = args.command
        del args

        if self.cmd in REQUIRES_WALLET:
            self.monero_wallet = wallet.MoneroWallet(self.inputDict)
        if self.cmd in REQUIRES_EXCHANGE:
            if self.inputDict.get("exchange") == "Godex.io":
                self.exchange_handler = exchange.Godex(self.inputDict)
            elif self.inputDict.get("exchange") == "MorphToken":
                self.exchange_handler = exchange.Morph(self.inputDict)
            elif self.inputDict.get("exchange") == "XMR.to":
                self.exchange_handler = exchange.Xmrto(self.inputDict)
    
            
    def do_command(self):
        if self.cmd in REQUIRES_EXCHANGE:
            self.exchange_cmd_handler()
        elif "qr" in self.cmd:
            self.qrcode_cmd_handler()
        elif self.cmd in REQUIRES_WALLET:
            self.wallet_cmd_handler()
        else:
            self.utility_cmd_handler()
    

    def exchange_cmd_handler(self):
        if self.cmd == "deposit":
            self.exchange_handler.deposit() #Wallet
        elif self.cmd == "withdraw":
            self.exchange_handler.withdraw() #Wallet
           
        elif self.cmd == "rates":
            self.exchange_handler.get_rates()
        elif self.cmd == "status":
            self.exchange_handler.get_order_status()
                
      
    def wallet_cmd_handler(self):
        if self.cmd == "balance":
            self.monero_wallet.print_balance(self.inputDict)
        elif self.cmd == "address":
            self.monero_wallet.print_address()
        elif self.cmd == "show_transfers":
            self.monero_wallet.show_transfers(self.fdlines)

             
    def qrcode_cmd_handler(self):
        qrdata = self.inputDict["qrdata"].split()
        qrlines = [line.replace("\n", "") for line in self.fdlines]

        if self.cmd == "make_xmr_qr":
            display.make_qr("XMR", [self.monero_wallet.address])    
        elif self.cmd == "make_qr": 
            display.make_qr(self.inputDict["coin"], qrdata)
        elif self.cmd == "print_qr":
            display.print_qr(self.inputDict["coin"], qrdata, qrlines)        


    def utility_cmd_handler(self):
        if self.cmd == "update":
            mmutils.Updater.update(self.inputDict["crypto"], self.inputDict["fiat"])
        elif self.cmd == "icons":
            mmutils.Updater.download_icons()
        elif self.cmd == "extraid":
            mmutils.Coinquery.check_extra_id(self.inputDict["coin"])   
        elif self.cmd == "coins":
            mmutils.Coinquery.get_coins(self.inputDict["exchange"])
        elif self.cmd == "compare":
            excomp.compare_rates(self.inputDict)
        elif self.cmd == "validate":
            mmutils.validate_address_arg(self.inputDict)

            
if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="torsocks python3 MoneroMixer.py")        
    parser.add_argument("--command", type=str)
    parser.add_argument("--stdin_bytes", type=int)
    parser.add_argument("--fd", type=str)
    parser.add_argument("--fd_bytes", type=int) 
    args = parser.parse_args()
     
    input_handler = TorPydoHandler(args)    
    input_handler.do_command()    
    del input_handler
   
