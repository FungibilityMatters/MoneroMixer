from json import loads as json
import sys
import mmutils
import display
import wallet


class ExchangeHandler(object):
    def __init__(self, inputDict):
        self.inputDict = inputDict
        self.exchange = inputDict.get("exchange")
        self.coin_in = inputDict.get("coin_in")
        self.coin_out = inputDict.get("coin_out")
        self.amount = inputDict.get("amount")
        self.display = inputDict.get("display")
        self.cols = inputDict.get("cols")

        if "balance_str" or "address_str" in inputDict:
            self.monero_wallet = wallet.MoneroWallet(inputDict)

        if "order_id" in inputDict:
            self.order_id = self.inputDict["order_id"].replace("Order ID:", "").replace(self.exchange, "").strip()
    
    def get_amount(self):
        if self.amount.split()[0] == "pp":
            return "pp"
        try:
            return mmutils.fix_amount(self.amount)[0]
        except:
            comp_coin = self.coin_in if self.exchange != "XMR.to" else "BTC"
            mmutils.error_out("ERROR: Invalid {} amount".format(comp_coin), "REASON: {} is not a valid {} amount.".format(amount[0], comp_coin))

    def deposit(self):
        self.tx_type = "deposit"
        amount = self.get_amount()
        refund_address = self.inputDict["refund_address"].split()[0]
        if refund_address in ["None", "|"]:
                refund_address = ""

        destination_address = self.monero_wallet.address
        
        self.create_order(amount, destination_address, refund_address)
    
    
    def withdraw(self):
        self.tx_type = "withdrawal"
        amount = self.get_amount()
        if self.exchange != "XMR.to":        
            refund_address =  self.monero_wallet.address 
        else:
            refund_address = None
        destination_address = self.inputDict["destination_address"].split()[0]

        self.create_order(amount, destination_address, refund_address)

    def API_request(self):
        url = self.API_base_url + self.API_endpoint

        response = mmutils.FakeUARequests.request(self.method, url, self.json_data)
        if response.status_code in (200, 201):
            return response.json()
    #    else:
    #        API_error_handler(response)

    #def API_error_handler(self, response)
        elif response.status_code == 403:
            mmutils.error_out(
                "ERROR: FORBIDDEN",
                "REASON: {} block US-based tor exit nodes.\n".format(self.exchange)
                + "\nTry disconnecting your network connection (Airplane Mode) wait a few seconds\n"
                + "then reconnect. Wait for the notification that Tor is ready then try again.")
        else:
            if self.error_handler == "status_error":
                mmutils.error_out("ERROR {}: {}".format(response.status_code,
                          "Order ID not found." if response.status_code == 404 
                                                else "Failed to load order",),
                          "{} order ID: {} not was not found.".format(self.exchange, self.order_id) 
                                                if response.status_code == 404 
                                                else "Failed to load {} order ID: {}".format(self.exchange, self.order_id))
            
            elif self.error_handler == "tx_error" or self.error_handler == "rates_error":
                if self.error_handler == "tx_error":
                    error_title = "ERROR {}: Failed to create order with {}".format(response.status_code, self.exchange)    
                elif self.error_handler == "rates_error":
                    error_title = "ERROR: Failed to get {} to {} rates from {}".format(
                    self.coin_in, self.coin_out, self.exchange)     
                try:
                    result = response.json()
                    error_text = "REASON: {}\n\n{} to {} exchanges may not be available at this time.\nCheck again later or try another coin.".format(mmutils.error_format(result.get(self.err_msg_key)), self.coin_in, self.coin_out)        
                except Exception as e:
                    print(response.status_code)
                    print(e)
            
                    error_text = "Try again later."
                        
            mmutils.error_out(error_title, error_text)

                
    def transact(self):
        self.error_handler = "tx_error"
        result = self.API_request()
        self.output_order_id(result)

    
    def output_order_id(self, result):
        sys.stdout, sys.stderr = sys.stderr, sys.stdout
        print("\n\033[00;37;40m{} \033[00;33;40mOrder ID: \033[01;36;40m{}\033[00;37;40m\n".format(
          self.exchange, result.get(self.id_key)))
        print("\033[00;37;40m{} \033[00;33;40mOrder ID \033[00;37;40msaved to encrypted file '\033[01;36;40m{}IDs.enc\033[00;37;40m'".format(
          self.exchange, self.tx_type))
        print("\n\033[01;37;40mYou can view the IDs of all your previous {} by decrypting this file \nby choosing option 3 'Exchange options' from the main menu.\033[00;33;40m".format("deposits" if self.tx_type == "deposit" else "withdrawals"))
        
        sys.stdout, sys.stderr = sys.stderr, sys.stdout
        print("{} Order ID: ".format(self.exchange) + result.get(self.id_key))

    # EXCHANGE FUNCTIONS
    def status(self):
        self.error_handler = "status_error"
        result = self.API_request()
        status_data = self.parse_status_response(result)
        self.output_status_data(result, status_data)
        
    def output_status_data(self, result, status_data):
        for output_sublist in status_data:
            print(" ".join(output_sublist))
        
        if self.display == "True":
            sys.stdout = sys.stderr
            display.display(result, self.exchange)

    
    def donatification_check(self, xmr_out, min_accepted, coin_out_rate): #min_accepted, rate): 
        min_acc = float(min_accepted)
        balance_remaining = self.monero_wallet.total_balance - float(xmr_out) * 0.995

        if coin_out_rate:
            max_coin_out = coin_out_rate * balance_remaining
            if max_coin_out < min_acc and balance_remaining > 0:
                return ["notify", "{:.12f}".format(balance_remaining), str(min_acc), str(coin_out_rate), "{:.6}".format(max_coin_out)]
        else:
            if balance_remaining < min_acc and balance_remaining > 0:
                return ["notify", "{:.12f}".format(balance_remaining), str(min_acc)]
        return []
    
    
    def rates(self):
        print(
                "\033[00;33;40mSecurely fetching latest \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m exchange rates from \033[00;37;40m{}\033[00;33;40m servers...\n".format(
                    self.coin_in, self.coin_out, self.exchange
                )
            )
        self.error_handler = "rates_error"
        result = self.API_request()
        rates_data = self.parse_rates_response(result)
            
        self.print_parameters(*rates_data)
        if self.coin_out != "XMR":
            self.print_estimates(rates_data[1])


    def print_parameters(self, in_out_rate, out_in_rate, min_in, max_in, lim_coin, zero_conf=None):
        rate_f = 8
        min_f = display.get_f(min_in, 8)
        max_f = display.get_f(max_in, 8)

        rates_lines = []
        rates_lines.append("{} to {} exchange rate: {:.{}f} {} per {}".format(self.coin_in, self.coin_out, in_out_rate, rate_f, self.coin_in, self.coin_out))
        rates_lines.append("{} to {} exchange rate: {:.{}f} {} per {}".format(self.coin_out, self.coin_in, out_in_rate, rate_f, self.coin_out, self.coin_in))
        colorDict = {"WHITE_BOLD":["{:.{}f}".format(in_out_rate, rate_f), "{:.{}f}".format(out_in_rate, rate_f)],
                     "BLUE": [self.coin_in, self.coin_out]}
        
        display.Display("EXCHANGE RATES", rates_lines, colorDict, 60, self.cols).print_box()
        print()
        
        limits_lines=[]
        limits_lines.append("Minimum {} amount accepted by {}: {:.{}f} {}".format(lim_coin, self.exchange, min_in, min_f, lim_coin))
        if in_out_rate == 0 or max_in != 0:
            limits_lines.append("Maximum {} amount accepted by {}: {:.{}f} {}".format(lim_coin, self.exchange, max_in, max_f, lim_coin))
        colorDict = {"RED":["{:.{}f}".format(min_in, min_f), "{:.{}f}".format(max_in, max_f)],
                     "WHITE":[self.exchange],
                     "WHITE_BOLD":["Minimum", "Maximum", "0.1"],
                     "BLUE":[self.coin_in, self.coin_out]}      

        if zero_conf:
            limits_lines.append("Instant transactions enabled up to: {} BTC".format(zero_conf))
            colorDict.get("WHITE_BOLD").append(zero_conf)
        
        display.Display("EXCHANGE LIMITS", limits_lines, colorDict, 60, self.cols).print_box()
        print()
        
        


    def print_estimates(self, out_in_rate):
        
        xmr_balance = self.monero_wallet.unlocked_balance
        est_output_after_fees = (xmr_balance * out_in_rate) * 0.995
        max_f = display.get_f(est_output_after_fees, 8)

        est_lines = []
        est_lines.append("Your Monero wallet unlocked balance: {} XMR".format(xmr_balance))
        est_lines.append("Estimated maximum {} you can send: {:.{}f} {}".format(
                self.coin_out, est_output_after_fees, max_f, self.coin_out))
        colorDict = {"WHITE_BOLD":["{:.{}f}".format(est_output_after_fees, max_f), str(xmr_balance), "maximum"],
                     "BLUE":[self.coin_in, self.coin_out]}
                           
        display.Display("MAX YOU CAN SEND", est_lines, colorDict, 60, self.cols).print_box()





class Xmrto(ExchangeHandler):
    def __init__(self, inputDict):
        super().__init__(inputDict)
        self.exchange = "XMR.to"
        self.API_base_url = "http://xmr.to/api/v2/xmr2btc/"
        self.id_key = "uuid"
        self.err_msg_key = "error_msg"
        self.in_amount_key = "xmr_amount_remaining"
        self.in_address_in_ = "xmr_receiving_integrated_address"
        self.out_amount_key = "btc_amount"
        self.out_address_key = "btc_dest_address"
  
    def create_order(self, amount, dest_address, refund_address=None):
        self.method = "POST"
        if amount != "pp":
            self.API_endpoint = "order_create/"
            self.json_data = { "btc_dest_address": dest_address, 
                               "btc_amount": amount 
                            }
        else:
            self.API_endpoint = "order_create_pp/"
            self.json_data = {"pp_url" : dest_address}
        self.transact()

    def get_order_status(self):
        self.method = "POST"
        self.API_endpoint = "order_status_query/"
        self.json_data = {"uuid": self.order_id}

        self.status()
        
    def parse_status_response(self, result):
        coin_in_data=["XMR", str(result.get("xmr_amount_remaining")), result.get("xmr_receiving_integrated_address")]
        coin_out_data=["BTC", str(result.get("btc_amount")), result.get("btc_dest_address")]
        donation_data = self.donatification_check(result.get("xmr_amount_remaining"), 0.001, result.get("xmr_price_btc"))

        return (coin_in_data, coin_out_data, donation_data)
   
    def get_rates(self):
        self.method = "GET"
        self.API_endpoint = "order_parameter_query/"
        self.json_data = None

        self.rates()
 
    def parse_rates_response(self, result):
        if not result.get("error"):
            rate = result.get("price")
            minimum = result.get("lower_limit")
            maximum = result.get("upper_limit")
            zero_conf = result.get("zero_conf_max_amount")
            return (1/rate, rate, minimum, maximum, self.coin_out, zero_conf)
        else:    
            mmutils.error_out("ERROR: {}".format(result.get("error_msg")),
                              "{}\nError message from XMR.to: {}\033[00;33;40m".format(
                              result.get("error"), result.get("error_msg")))
        

class Morph(ExchangeHandler):
    def __init__(self, inputDict):
        super().__init__(inputDict)
        self.exchange = "MorphToken"
        self.API_base_url = "https://api.morphtoken.com/"
        self.id_key = "id"
        self.err_msg_key = "description"

  
    def create_order(self, amount, dest_address, refund_address=None):
        self.method = "POST"
        self.API_endpoint = "morph"
        self.json_data = {
            "input": {"asset": self.coin_in, "refund": refund_address},
            "output": [{"asset": self.coin_out, "weight": 10000, "address": dest_address}],
            "tag": "MoneroMixer",
            }

        self.transact()

    def get_order_status(self):
        self.method = "GET"
        self.API_endpoint = "morph/" + self.order_id
        self.json_data = None

        self.status()
        
    def parse_status_response(self, result):
        if result.get("input").get("asset") == "XMR":
            deposit_amount = mmutils.fix_amount(self.amount)[0]
            withdrawal_amount = deposit_amount * float(result.get("output")[0].get("seen_rate"))
            donation_data = self.donatification_check(deposit_amount, mmutils.morph_format("XMR", result.get("input").get("limits").get("min")), None)
        else:
            deposit_amount = "None"
            withdrawal_amount = "None"
            donation_data = []
        
        coin_in_data=[result.get("input").get("asset"), str(deposit_amount), result.get("input").get("deposit_address")]
        coin_out_data=[result.get("output")[0].get("asset"), str(withdrawal_amount), result.get("output")[0].get("address")]

        return (coin_in_data, coin_out_data, donation_data)
    
    def get_rates(self):
        self.method = "POST"
        self.API_endpoint = "limits"
        self.json_data = {"input": {"asset": self.coin_in},
                          "output": [{"asset": self.coin_out, "weight": 10000}]}
        self.rates()

    def parse_rates_response(self, result):
        rate = float(result.get("output")[0].get("seen_rate"))
        minimum = float(mmutils.morph_format(
                    self.coin_in, result.get("input").get("limits").get("min")))
        maximum = float(mmutils.morph_format(
                    self.coin_in, result.get("input").get("limits").get("max")))

        return (1/rate, rate, minimum, maximum, self.coin_in)
        

class Godex(ExchangeHandler):
    def __init__(self, inputDict):
        super().__init__(inputDict)
        self.exchange = "Godex.io"
        self.API_base_url = "https://api.godex.io/api/v1/"
        self.id_key = "transaction_id"
        self.err_msg_key = "error"

  
    def create_order(self, amount, dest_address, refund_address=None):
        self.method = "POST"
        self.API_endpoint = "transaction"
        
        extra_id = None
        if self.coin_out == "XMR":
            
            if mmutils.Coinquery.get_extra_id(self.coin_in) and refund_address != "":
                refund_address, extra_id = refund_address.split("|")

        if self.coin_in == "XMR":
            if mmutils.Coinquery.get_extra_id_name(self.coin_out) and dest_address[0:3] != "***":
                dest_address, extra_id = dest_address.split("***")
            else:
                dest_address = dest_address.replace("***", "")
        

        self.json_data = {
            "coin_from": self.coin_in,
            "coin_to": self.coin_out,
            "deposit_amount": amount,
            "withdrawal": dest_address,
            "withdrawal_extra_id": extra_id if self.coin_in == "XMR" else None,
            "return": refund_address,
            "return_extra_id": extra_id if self.coin_in != "XMR" else None,
            "affiliate_id": "DObYfBjJxbebSF2H",
        }

        self.transact()

    def get_order_status(self):
        self.method = "GET"
        self.API_endpoint = "transaction/" + self.order_id
        self.json_data = None

        self.status()
        
    def parse_status_response(self, result):
        coin_in_data=[result.get("coin_from"), result.get("deposit_amount"), result.get("deposit")] 
        if result.get("deposit_extra_id"):
            coin_in_data.append(result.get("deposit_extra_id"))
        
        coin_out_data=[result.get("coin_to"), result.get("withdrawal_amount"), result.get("withdrawal")] 
        if result.get("withdrawal_extra_id"):
            coin_out_data.append(result.get("withdrawal_extra_id"))

        donation_data = []
        if result.get("coin_from") == "XMR":
            result2 = mmutils.FakeUARequests.post("https://api.godex.io/api/v1/info",
                                  {"from": result.get("coin_from"),
                                   "to": result.get("coin_to"),
                                   "amount": result.get("deposit_amount")}).json()
            donation_data = donatification_check(result.get("deposit_amount"), result2.get("min_amount"), None)
        
        return (coin_in_data, coin_out_data, donation_data)
    
    def get_rates(self):
        self.method = "POST"
        self.API_endpoint = "info{}".format("-revert" if self.coin_out == "XMR" else "")
        self.json_data = {"from": self.coin_in, "to": self.coin_out, "amount": 1.5}

        self.rates()

    def parse_rates_response(self, result):
        rate = float(result.get("rate"))
        minimum = float(result.get("min_amount"))
        maximum = float(result.get("max_amount"))
				
        if self.coin_out == "XMR":
            minimum = minimum / rate

        return (1/rate, rate, minimum, maximum, self.coin_in)





