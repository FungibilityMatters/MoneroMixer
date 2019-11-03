from json import loads as json
import mmutils
import display


class MoneroWallet(object):
    def __init__(self, inputDict):
        if "address_str" in inputDict:
            self.address = inputDict["address_str"].replace("  (Untitled address)", "").split("  ")[1].strip()
        if "balance_str" in inputDict:
            balanceList = inputDict["balance_str"].replace("Balance: ", "").replace("unlocked balance: ", "").split()
            self.total_balance = float(balanceList[0].replace(",", ""))
            self.unlocked_balance = float(balanceList[1])
            self.blocks = int(balanceList[2][1]) if len(balanceList) > 2 else 0
            self.unlock_est_time = self.blocks * 2

    def print_address(self):
        print(self.address)

    def print_balance(self, inputDict):
        cols = int(inputDict["cols"])
        fiat, fiat_symbol, crypto = inputDict["fiat"], inputDict["symbol"], inputDict["crypto"]
        fiat2, fiat_symbol2 = ("USD", "$") if fiat != "USD" else ("EUR", "€")
        cryptoList = [crypto] + [coin for coin in ('BTC', 'LTC', 'ETH', 'BCH', 'DASH') if coin != crypto]
        
        with open("updates/fiat-prices", "r") as f:
            result = json(f.readline())

        total_fiat, unlocked_fiat = (bal * float(result.get(fiat)) for bal in (self.total_balance, self.unlocked_balance))
        total_crypto, unlocked_crypto = (bal * float(result.get(crypto)) for bal in (self.total_balance, self.unlocked_balance))

        #NOTE TO SELF: USE display.fit_floats to make fit int larger displays
        print("  1 \033[01;36;40mXMR\033[00;33;40m ≈ \033[00;37;40m{}{:.2f} \033[00;33;40m{}{:.2f} \033[00;37;40m{:.4f} \033[01;36;40m{} \033[00;33;40m{:.4f} \033[01;36;40m{} \033[00;37;40m{:.4f} \033[01;36;40m{} \033[00;33;40m{:.4f} \033[01;36;40m{} \033[00;37;40m{:.4f} \033[01;36;40m{}\n".format(
            fiat_symbol,
            result.get(fiat),
            fiat_symbol2,
            result.get(fiat2),
            result.get(cryptoList[0]),
            cryptoList[0],
            result.get(cryptoList[1]),
            cryptoList[1],
            result.get(cryptoList[2]),
            cryptoList[2],
            result.get(cryptoList[3]),
            cryptoList[3],
            result.get(cryptoList[4]),
            cryptoList[4],
            )
       )
        
        length = cols - 2

        disp_total_fiat = "{}{:.2f}".format(fiat_symbol, total_fiat)
        disp_unlocked_fiat = "{}{:.2f}".format(fiat_symbol, unlocked_fiat)
        
        total_line = " Total Balance (Locked + Unlocked): {} XMR ≈ {} ≈ {}".format("{0}", disp_total_fiat, "{1} " + crypto)
        total_line, tfloats = display.fit_floats(total_line, [(self.total_balance, 1), total_crypto], length-2)

        unlocked_line = " Unlocked Balance (Unlocked only): {} XMR ≈ {} ≈ {}".format("{0}", disp_unlocked_fiat, "{1} " + crypto)
        unlocked_line, ufloats = display.fit_floats(unlocked_line, [(self.unlocked_balance, 1), unlocked_crypto], length-2)

        display_lines = [total_line, unlocked_line]
           
        if inputDict["type"] != "limited":
            display_lines.append("Blocks to Unlock: {} Estimated time: ~{} minutes {}".format(self.blocks, self.unlock_est_time, "(Refresh balance to update)" if cols >= 80 else " "))

        colorDict = {"GREEN":[disp_total_fiat, disp_unlocked_fiat],
                     "WHITE_BOLD":[self.total_balance, self.unlocked_balance] + [tfloats[0], ufloats[0]],
                     "WHITE": [tfloats[1], ufloats[1]] + [self.blocks, "~"+str(self.blocks), self.unlock_est_time]} 
        display.Display("YOUR MONERO WALLET BALANCE", display_lines, colorDict, length, cols).print_box()
        

        if inputDict["type"] == "full":
            print(
            "\033[00;37;40mTotal Balance is everything your Monero wallet has received so far.\033[00;33;40m\n\n"
            "Unlocked balance is the amount of XMR in your wallet that has confirmed\non the Monero blockchain and is withdrawable now.\n\n\033[00;37;40mLocked balance cannot be sent or converted until it is unlocked.\n\n"
            "\033[00;33;40mLocked balance typically takes ~2 minutes per block to become unlocked."
            )
    
    @staticmethod    
    def show_transfers(fdlines):
        txfrList = []
        #with open(fdpipe, "r") as f:
        for line in reversed(fdlines):
            try:
                txfrList.append(Txfr(line))
            except:
                break
        for txfr in txfrList:
            txfr.print_full()
    
class Txfr(object):
    def __init__(self, show_transfers_line):
        data = [datum for datum in show_transfers_line.strip().replace(" blks","").split()]
        self.block_num, self.direction, self.lock, self.date, self.time, self.amount, self.hash, self.payment_id, self.fee = data[:9]
        self.amount += " XMR"

        if self.lock in ("unlocked", "locked"):
            self.status = "Received ({})".format(self.lock) #self.lock.capitalize()
        elif self.block_num in ("pending", "failed"):
            self.status = self.block_num.replace("p","s").capitalize()
        elif self.direction == "out":
            self.status = "Sent"
        else:
            try:            
                self.status = "Received ({} blocks to unlock)".format(self.lock)
            except:
                self.status = "Error parsing tx"    
        data[2] = "%"
        dash = data.index("-")
        self.address = [addy.split(":") for addy in data[9:dash] if ":" in addy]
        self.subaddress = [sub.replace(",","") for sub in data[9:dash] if ":" not in sub]               
        self.notes = [note for note in data[dash + 1:]] if data[-1] != "-" else None
        
        if self.direction == "in":
            self.address[0][0] += " : address index {}".format(self.subaddress[0])

    def print_simple(self):
        address_str = self.address[0][0][:6]
        for datum in [self.date, self.time, self.status, self.amount, address_str]:
            print(datum)         
    
    def print_full(self):
        address_str = self.address[0][0] if len(self.address) == 1 else ",".join([addy[0] for addy in self.subaddress])
        subadd_str = self.subaddress[0] if len(self.subaddress) == 1 else ",".join(self.subaddress)
        for datum in [self.date, self.time, self.status, self.amount, self.fee, address_str, self.payment_id, self.hash, subadd_str]:
            print(datum)

                                           
