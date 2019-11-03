import mmutils
import display
from concurrent.futures import ThreadPoolExecutor

class Option(object):
    def __init__(
        self,
        priceDict,
        coin_in,
        coin_out,
        exchange,
        rate,
        network_fee,
        amount,
        fiat,
        is_withdrawal,
    ):
        self.coin_in = coin_in
        self.coin_out = coin_out
        self.exchange = exchange
        self.rate = float(rate)

        coin_out_fiat = float(priceDict.get(coin_out).get(fiat))
        coin_in_fiat = float(priceDict.get(coin_in).get(fiat))

        if self.exchange == "MorphToken":
            network_fee = float(mmutils.morph_format(
                self.coin_out, network_fee))

        if amount[1] == coin_in:
            self.amount_in = float(amount[0])
            self.fiat_in = self.amount_in * coin_in_fiat
            self.amount_out = (self.amount_in * self.rate) - network_fee
            self.fiat_out = self.amount_out * coin_out_fiat

        elif amount[1] == coin_out:
            self.amount_out = float(amount[0])
            self.fiat_out = self.amount_out * coin_out_fiat
            self.amount_in = (self.amount_out + network_fee) / self.rate
            self.fiat_in = self.amount_in * coin_in_fiat

        else:
            self.fiat_in = float(amount[0])
            self.amount_in = self.fiat_in / coin_in_fiat
            self.amount_out = (self.amount_in * self.rate) - network_fee
            self.fiat_out = self.amount_out * coin_out_fiat
        self.fee = (1 - (self.fiat_out / self.fiat_in)) * 100

        if is_withdrawal:
            zenity_data = "{}|{} {} ".format(self.exchange, coin_out, coin_out)
        else:
            zenity_data = "{}|{} {} ".format(self.exchange, coin_in, coin_in)
        self.zenity_data = zenity_data + self.exchange + " "

    def get_table_data(self, is_withdrawal, invert, fiat_symbol):
        if is_withdrawal:
            coin = self.coin_out
        else:
            coin = self.coin_in
        if invert:
            disp_amount = self.amount_in
            disp_coin = self.coin_in
            disp_value = self.fiat_in
            
        else:
            disp_amount = self.amount_out
            disp_coin = self.coin_out
            disp_value = self.fiat_out

        amount = "{} {}".format(disp_amount, disp_coin)
        value = "{}{:.2f}".format(fiat_symbol, disp_value)
        fee = str(self.fee) +"%"
        rate = "{} {}/{}".format(1/self.rate, self.coin_in, self.coin_out)
               
        return [coin, self.exchange, amount, value, fee, rate]


def make_option_dataList(coinsList, priceDict, is_withdrawal, amount, fiat):
    morph_coinsList = ["BTC", "LTC", "ETH", "BCH", "DASH"]
    exchangeList = ["Godex.io", "MorphToken", "XMR.to"]

    option_dataListList = []
    for coin in coinsList:
        if is_withdrawal:
            coin_out = coin
            coin_in = "XMR"
        else:
            coin_out = "XMR"
            coin_in = coin

        if coin in morph_coinsList:
           x_num = 3 if coin == "BTC" and is_withdrawal else 2
        else:
            x_num = 1

        for i in range(x_num):
            option_dataList = [
                exchangeList[i],
                coin_in,
                coin_out,
                priceDict,
                is_withdrawal,
                amount,
                fiat,
            ]
            option_dataListList.append(option_dataList)

    return option_dataListList


def get_option(option_dataList):
    exchange, coin_in, coin_out, priceDict, is_withdrawal, amount, fiat = (option_dataList[0:7])
    revert = ""

    try:
        if amount[1] == coin_in:
            comp_amount = float(amount[0])
        elif amount[1] == coin_out:
            if exchange == "Godex.io":
                comp_amount = float(amount[0])
                revert = "-revert"
            else:
                comp_amount = (
                    float(amount[0]) * priceDict.get(coin_out).get(fiat)
                ) / priceDict.get(coin_in).get(fiat)
        else:
            comp_amount = float(amount[0]) / priceDict.get(coin_in).get(fiat)

        if exchange == "XMR.to":
            result = mmutils.FakeUARequests.get("http://xmrto2bturnore26.onion/api/v2/xmr2btc/order_parameter_query/").json()

            minimum = float(result.get("lower_limit"))
            maximum = float(result.get("upper_limit"))
            rate = float(result.get("price"))
            network_fee = 0
        elif exchange == "MorphToken":
            url = "https://api.morphtoken.com/limits"
            json_data = {
                "input": {"asset": coin_in},
                "output": [{"asset": coin_out, "weight": 10000}],
            }

            result = mmutils.FakeUARequests.post(url, json_data).json()
            minimum = float(result.get("input").get("limits").get("min"))
            maximum = float(result.get("input").get("limits").get("max"))
            rate = float(result.get("output")[0].get("seen_rate"))
            network_fee = result.get("output")[0].get("network_fee")
        else:
            url = "https://api.godex.io/api/v1/info" + revert
            json_data = {"from": coin_in,
                         "to": coin_out, "amount": comp_amount}
            result = mmutils.FakeUARequests.post(url, json_data).json()

            minimum = float(result.get("min_amount"))
            maximum = float(result.get("max_amount"))
            rate = float(result.get("rate"))
            network_fee = float(result.get("fee"))

        if rate != 0:  # and comp_amount > minimum and (comp_amount < maximum or maximum == 0):
            return Option(
                priceDict,
                coin_in,
                coin_out,
                exchange,
                rate,
                network_fee,
                amount,
                fiat,
                is_withdrawal,
            )
    except Exception as e:
        print(e)
        print(
            "Failed to get {} to {} rates from {}, omitting from options list.".format(
                coin_in, coin_out, exchange
            )
        )


def make_price_urlList(coinsList, fiat):
    fsyms = "XMR,"
    sym_num = 0
    price_urlList = []
    syms_per_url = 20

    url_num = int(len(coinsList) / syms_per_url)

    for u in range(url_num):
        for s in range(syms_per_url):
            fsyms += "{},".format(coinsList[(syms_per_url * u) + s])
        price_urlList.append(
            "https://min-api.cryptocompare.com/data/pricemulti?fsyms={}&tsyms={}".format(
                fsyms, fiat
            )
        )
        fsyms = ""
    if url_num == 0 or len(coinsList) % syms_per_url != 0:
        for r in range(len(coinsList) % syms_per_url):
            fsyms += "{},".format(
                coinsList[int(len(coinsList) / syms_per_url) + r])
        price_urlList.append(
            "https://min-api.cryptocompare.com/data/pricemulti?fsyms={}&tsyms={}".format(
                fsyms, fiat
            )
        )
    return price_urlList


def get_priceDictList(price_url):
    return mmutils.FakeUARequests.get(price_url).json()


def sync_priceDict(priceDictList):
    synced_priceDict = {}
    for partial_priceDict in priceDictList:
        synced_priceDict.update(partial_priceDict)
    return synced_priceDict


def compare_rates(inputDict):
    optionsList = []
    loaded_urlList = []
    amount = mmutils.fix_amount(inputDict["amount"])
    fiat = inputDict["fiat"]
    fiat_symbol = inputDict["symbol"]
    coinsList = inputDict["selected_coins"].split("|")

    print
    if amount[1] in coinsList and amount[1] != "XMR":
        coinsList = [amount[1]]

    elif "XMR" in coinsList:
        coinsList.remove("XMR")

    elif "TRUE_C" in coinsList:
        coinsList.remove("TRUE_C")
        coinsList.append("TRUE")

    if inputDict["type"] == "withdraw":
        is_withdrawal = True
        if amount[1] == coinsList[0]:
            invert = True
        else:
            invert = False
        error_title = "ERROR: No withdrawal options available for {} {}".format(
            amount[0], amount[1]
        )
    else:
        is_withdrawal = False
        if amount[1] == "XMR":
            invert = True
        else:
            invert = False
        error_title = "ERROR: No deposit options available for {} {}".format(
            amount[0], amount[1]
        )
    price_urlList = make_price_urlList(coinsList, fiat)

    with ThreadPoolExecutor() as executor:
        priceDictList = executor.map(get_priceDictList, price_urlList)
    priceDict = sync_priceDict(priceDictList)

    option_dataList = make_option_dataList(
        coinsList, priceDict, is_withdrawal, amount, fiat
    )

    with ThreadPoolExecutor() as executor:
        optionsMap = executor.map(get_option, option_dataList)
    initial_optionsList = list(optionsMap)

    optionsList = []
    for option in initial_optionsList:
        if type(option) is not None and option != None:
            optionsList.append(option)

    sortable = False
    while not sortable:
        try:
            sortedList = sorted(optionsList, key=lambda option: option.fee)
            sortable = True
        except (ValueError, AttributeError) as e:
            optionsList.remove(e.__cause__)

    if len(sortedList) < 1:
        mmutils.error_out(
            error_title, "Try again with a different amount and/or coin(s)")

    with open("options-list", "a") as f:
        for option in sortedList:
            f.write(option.zenity_data)

    size = int(inputDict["cols"])
    amount_len = size - 64
    #rate_len = size - 
    value_len = len(str(sortedList[0].fiat_out).split(".")[0]) + 6
    columns = [[("Rank",4,6)], [("Coin",6,6)],[("Exchange", 9, 10)], [("Amount You Send" if invert else "Amount You Get", 8, None)],
               [("Value", value_len, value_len)],[("Fee", 8, None)], [("Rate", 16, None)]]   
    
    rank = 0
    for option in sortedList:
        rank += 1
        table_data = [rank] + option.get_table_data(is_withdrawal, invert, fiat_symbol)
        for index, column in enumerate(columns):
            column.append(table_data[index])
            
    colorDict = {"WHITE_BOLD":["cols=0,2,3,5,6"],
                 "GREEN":["col=4"],
                 "BLUE":["col=1"]}
    
    title = "Current options for {}ing: {} {}".format("withdraw" if is_withdrawal else "deposit", amount[0], amount[1])
    display.Display(title, columns, colorDict, size, size).print_table()
