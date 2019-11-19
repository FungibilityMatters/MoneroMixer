import requests
import sys
from random import choice
from re import match as rematch
from time import time
from json import loads as json
from concurrent.futures import ThreadPoolExecutor
from shutil import copyfileobj
from PIL import Image

class FakeUARequests(object):
    cds = 0
    while cds < 4:
        try:
            all_user_agents = open("{}info/user-agents.txt".format("../"*cds)).readlines()
            header = {
                           "Accept":"application/json", 
                           "Content-Type":"application/json",
                           "User-Agent": choice(all_user_agents).strip(),
                          }
            break
        except IOError:
            cds += 1
    
    @classmethod
    def get(cls, url, stream=False):
        return requests.get(url, 
                            headers=cls.header, 
                            stream=stream, 
                            allow_redirects=False, 
                            timeout=30)
    @classmethod
    def get_tuple(cls, url_tuple):
        return (cls.get(url_tuple[0]), url_tuple[1])

    @classmethod
    def post(cls, url, json_data=None):
        return requests.post(url, 
                            json=json_data,
                            headers=cls.header,
                            allow_redirects=False, 
                            timeout=30)
    @classmethod
    def request(cls, method, url, json_data=None):
        if method == "GET":
            return cls.get(url)
        elif method == "POST":
            return cls.post(url, json_data)        


class Updater(object):
    @staticmethod
    def update(crypto, fiat):  
        urls = []
        urls.append(("https://min-api.cryptocompare.com/data/price?fsym=XMR&tsyms={},{},{},BTC,LTC,ETH,BCH,DASH".format(crypto, fiat, "EUR" if fiat == "USD" else "USD"), "fiat-prices"))
        urls.append(("https://api.godex.io/api/v1/coins", "coins"))

        with ThreadPoolExecutor() as updater:
            for response, filename in updater.map(FakeUARequests.get_tuple, urls):
                with open("updates/" + filename, "w+") as f:
                    f.write(response.text)
            
    @staticmethod
    def download_image(url_filename_tup):
        url, filename = url_filename_tup
        response = FakeUARequests.get(url, stream=True)
        response.raw.decode_content = True  
          
        with open(filename, 'wb') as f:
            copyfileobj(response.raw, f)
        if ".svg" not in filename:
            img = Image.open(filename).resize((25,25))
            img.save(filename.replace(filename.split(".")[1], "png"))
        else:
            print(filename)
        return filename
    
    @staticmethod        
    def download_icons():
        downloaded_icons = [line.strip() for line in open("downloaded_icons.txt").readlines()]
        url_filenameList = []
        for coin in FakeUARequests.get("https://api.godex.io/api/v1/coins").json():
            filename = (coin['code'] + "." + coin['icon'].split(".")[-1])
            if filename not in downloaded_icons:
                url_filenameList.append((coin['icon'], filename)) 

        with ThreadPoolExecutor() as downloader:
            new_icons = downloader.map(Updater.download_image, url_filenameList)
            print("DONE")
    
        with open("downloaded_icons.txt", "a+") as f:
            f.write("{}{}".format("\n" if len(downloaded_icons) > 0 else "", 
                                  "\n".join(list(new_icons))))

        
class Coinquery(object):
    popularList = [ "XMR",
                "BTC",
                "LTC",
                "ETH",
                "BCH",
                "DASH",
                "XRP",
                "EOS",
                "XLM",
                "ZEC",
                "BAT",
                "REP" ]
    

    coinDict = {          "XMR":"Monero",
                          "BTC":"Bitcoin",
                          "LTC":"Litecoin",
                          "ETH":"Ethereum",
                          "BCH":"Bitcoin Cash",
                          "DASH":"Dash",
                        }
    extraDict = {
        "EOS": "MEMO",
        "ARDR": "Message",
        "XRP": "Destination Tag",
        "XEM": "Message",
        "IOST": "MEMO",
        "GTO": "MEMO",
        "BTS": "MEMO",
        "STEEM": "Destination tag",
        "GXS": "MEMO",
        "BNB": "MEMO",
        "MITH": "MEMO",
        "ETN": "Payment Id",
        "XLM": "Memo",
        "ATOM": "MEMO",
    }

    try:
        for coin in json(open("updates/coins", "r").readline()):
            if coin.get("disabled") == 0 and coin.get("code") not in coinDict and coin.get("code"): # not in cls.exclude:
                coinDict[coin.get("code")] = coin.get("name")
                if coin.get("has_extra") == 1 and coin.get("extra_name"):
                    extraDict[coin.get("code")] = coin.get("extra_name")
       
        tickerList = sorted(coinDict.keys())
        for coin in popularList:
            tickerList.remove(coin)
    
        tickerList = popularList[:] + tickerList 
    except:
        tickerList = popularList[:6]
    
    @classmethod
    def get_tickers(cls):
        return cls.tickerList
    
    @classmethod
    def get_coins(cls, exchange=None):
        if exchange == "MorphToken":
            outputList = cls.tickerList[1:6]
        elif exchange == "XMR.to":
            outputList = cls.tickerList[1:2]
        elif exchange == "Godex.io":
            outputList = cls.tickerList[1:]
        else:
            outputList = cls.tickerList

        for ticker in outputList:
            print("../../icons/{}.png".format(ticker))
            print(cls.coinDict.get(ticker))
            print(ticker)

    @classmethod
    def write_all(cls):
        outputDict ={filename:"" for filename in ("imagelist", "tickers")}
        for ticker in cls.tickerList:
            nt = "{} {} ".format(coinDict.get(ticker).replace(" ", "-").replace("---", "-"), ticker)
            outputDict["imagelist"] += "{} {}".format("../../icons/{}.png".format(ticker), nt)
            outputDict["tickers"] += "{} ".format(ticker)

        for filename, ticker_str in outputDict.items():
            with open("updates/{}".format(filename), "w+") as f:
                f.write(ticker_str) 
    
    @classmethod      
    def get_extra_id(cls, ticker):
        return cls.extraDict.get(ticker)      

    @classmethod
    def check_extra_id(cls, coin):
        extra_id_name = cls.get_extra_id(coin)
        if extra_id_name:
            print(
            "\n\033[01;37;40mNOTE: \033[01;36;40m{}\033[01;37;40m addresses may require a{} \033[01;36;40m{} {} \033[01;37;40mfor transaction processing.".format(
                coin,"n" if coin[0] in ["A","E","I","O","U"] else "", coin, extra_id_name
            )
        )
            with open("extraid", "w+") as f:
                f.write("--add-entry=\n{} {} (if applicable):".format(coin, extra_id_name))


def fix_amount(usr_amount):
    amount = usr_amount.split(" ")
    if len(amount) < 2:
        char = str(amount[0])[0]
        last_num = 0
        while not char.isalpha() and last_num < len(amount[0]) - 1:
            last_num += 1
            char = str(amount[0])[last_num]

        if last_num < len(amount[0]) - 1:
            amount.append(amount[0][last_num: len(amount[0])])
            amount[0] = amount[0].replace(amount[1], "")
        else:
            amount.append("XMR")
    try:
        amount[0] = float(amount[0])
    except ValueError:
        amount[0] = 0
    amount[1] = amount[1].upper().strip()
    return amount


def morph_format(asset, amount):
    if asset == "ETH":
        amount /= 10 ** 18
    elif asset == "XMR":
        amount /= 10 ** 12
    else:
        amount /= 10 ** 8
    return "{:.8f}".format(amount)


def error_format(error_message):
    return str(error_message).rsplit(':')[-1].replace("'","").replace("{","").replace("}","").replace("[","").replace("]","").strip()


def error_out(error_title, error_text):
    sys.stdout = sys.stderr
    print("\n\033[01;31;40m" + error_title + "\n" + error_text)
    with open("py_error", "w+") as f:
        f.write("{}\n{}".format(error_title, error_text))
    exit(1)


def validation_error_out(error_type, error_str):
    sys.stdout = sys.stderr
    print("\n\033[01;31;40m" + error_str)
    with open("validation_error", "w+") as f:
        f.write("{}".format(error_type))
    exit(1)


def validate_address_arg(inputDict):
    reDict = {"XMR": "^(4|8)[1-9A-HJ-NP-Za-km-z]{94}([1-9A-HJ-NP-Za-km-z]{11})?$",
              "BTC": "^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$",
              "LTC": "^[LM3][a-km-zA-HJ-NP-Z1-9]{26,33}$",
              "ETH": "0x[a-fA-F0-9]{40}",
              "BCH": "[13][a-km-zA-HJ-NP-Z1-9]{33}",
              "DASH": "^X[1-9A-HJ-NP-Za-km-z]{33}$",}

    address = inputDict["address"]
    coin = inputDict["coin"]
    tx_type = inputDict["type"]
    try:
        if not rematch(reDict.get(coin), address) and "bitpay.com" not in address:
            validation_error_out("invalid_address {} {}".format(tx_type, coin),
                                 "\nThe {} address you entered may not be a valid {} address.\n".format(tx_type, coin)
                                 + "Do you want to continue anyway?",)

        elif address.lower().startswith("bc1") and coin == "BTC":
            validation_error_out("segwit_address {}".format(inputDict["exchange"]),
                                 "The Morphtoken and XMR.to APIs do not support segwit addresses.\n"
                               + "If you receive an error try again with a standard address instead.\n"
                               + "Do you want to continue with segwit address anyway?")
    except:
        exit(0)
