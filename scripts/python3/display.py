import mmutils
import qrcode

class Display(object):
    #COLORS
    COLORS = {
    "DEFAULT":"\033[00;33;40m",
    "WHITE":"\033[00;37;40m",
    "WHITE_BOLD":"\033[01;37;40m",
    "RED":"\033[01;31;40m",
    "BLUE":"\033[01;36;40m",
    "GREEN":"\033[01;32;40m",
    "M":"\033[0;4;33;40mM\033[00;37;40m",
    "MM":"\033[0;4;33;40mM\033[00;37;40monero\033[0;4;33;40mM\033[00;37;40mixer{}\033[00;33;40m"
    }


    def __init__(self, title, data, colors=None, length=80, terminal_cols=80):
        self.data = data
        self.cols = int(terminal_cols)
        self.length = length
        self.shift = ((self.cols - length) // 2) * " "
        self.title = title
        self.title_color = "WHITE_BOLD"
        self.border_color = "DEFAULT"
        self.colors = colors
        for color, elements in colors.items():
            if "TITLE" in elements:
                self.title_color = color
            if "BORDERS" in elements:
                self.border_color = color
            
    
    def color_lines(self, raw_lines, colorDict):
        defaults = {"WHITE": ["Godex.io", "MorphToken", "XMR.to"]}
        self.colored_lines = []        
        for line in raw_lines:
            colored_line = []
            raw_words = line.strip().split()
            for raw_word in raw_words:
                word_color = "DEFAULT"
                for color, words_to_color in colorDict.items():
                    for word_to_color in words_to_color:
                        if raw_word == str(word_to_color):
                            word_color = color
                if raw_word in mmutils.Coinquery.get_tickers():
                    word_color = "BLUE"
                
                for default_color, default_words in defaults.items():
                    for default_word in default_words:
                        if default_word in raw_word:
                            raw_word = self.COLORS[default_color] + default_word + self.COLORS["DEFAULT"] + raw_word[len(default_word):]
                                    
                            
                colored_line.append("{}{}{}".format(self.COLORS[word_color],raw_word,self.COLORS["DEFAULT"]))
            self.colored_lines.append(" ".join(colored_line))

    
    def make_top(self, border, lend=None,rend=None):
        top_line = lend + self.title.center(self.length - 2, border) + rend
        top_line = str(self.COLORS[self.border_color]+ top_line.replace(self.title, self.COLORS[self.title_color] + self.title  + self.COLORS[self.border_color]))
        return (self.shift + top_line)


    def make_bottom(self, border, lend=None, rend=None):
        bottom = lend + border * (self.length - 2) + rend
        return(self.shift + self.COLORS[self.border_color] + bottom)


    def print_box(self):        
        self.color_lines(self.data, self.colors)
        h, v, tl, tr, bl, br = "═", "│", "╔", "╗", "╚", "╝"
        print(self.make_top(border=h, lend=tl, rend=tr))
        for i in range(len(self.colored_lines)):
            line = self.colored_lines[i]
            
            line = v + line
            line += " " * (self.length - len(self.data[i]) - 2) + v
                     
            print(self.shift + line)
        print(self.make_bottom(border=h, lend=bl, rend=br))
        

    def fit_headers(self, headers_data):
        headers = [[header.center(min_len), max_len, False] for header, min_len, max_len in headers_data]
        fitted_headers = "│".join([header[0] for header in headers])
        order_index = 0        
        while len("│".join([header[0] for header in headers])) < self.length - 2:
            if order_index >= len(headers):
                if not headers[0][2]:
                    order_index = 0
                else:
                    break
            
            header = headers[order_index]
            if not header[1] or len(header[0]) < header[1]:
                incremented = header[0].center(len(header[0]) + 1)  
                test_headers = headers[:]
                test_headers[order_index][0] = incremented

                if len("│".join([header[0] for test_header in test_headers])) <= self.length - 2:
                    headers[order_index][0] = incremented
                
            order_index += 1
            
        return [header[0] for header in headers]               


    def print_table(self):
        dh, sh, sv, dv, dtl, dtr, dbl, dbr = "═", "─","│", "║", "╔", "╗", "╚", "╝"
        lx, rx, dsx, dsd, dsu, = "╠", "╣", "╪", "╤", "╧"
        columns = []
        headers_data = []
        for col_data in self.data:
            column = []
            for datum in col_data[1:]:
                column.append(datum)
            headers_data.append(col_data[0])
            columns.append(column)
        
        col_colors = ["DEFAULT" for column in columns]
        header_colors = ["WHITE_BOLD" for column in columns]     
        for color, groups in self.colors.items():
            for group in groups:
                if "col" in group and "=" in group:         
                    for index in group.split("=")[1].split(","):
                        col_colors[int(index)] = color
                if "head" in group and "=" in group:         
                    for index in group.split("=")[1].split(","):
                        header_colors[int(index)] = color                    

            
        headers = self.fit_headers(headers_data)
        header_lines = [self.COLORS[self.border_color] + left for left in (lx,dv,lx)]
        bottom_line = self.COLORS[self.border_color] + dbl
        for index, header in enumerate(headers):
            header_len = len(header.center(len(header)))
            header_lines[0] += dh * header_len
            header_lines[1] += self.COLORS[header_colors[index]] + header.center(len(header)) + self.COLORS[self.border_color]
            header_lines[2] += dh * header_len
            bottom_line += dh * header_len
            if header is not headers[-1]:
                header_lines[0] += dsd
                header_lines[1] += sv
                header_lines[2] += dsx
                bottom_line += dsu    
            
        header_lines[0] += rx
        header_lines[1] += dv
        header_lines[2] += rx
        bottom_line += dbr
    
        tickers = mmutils.Coinquery.get_tickers()
        row_lines = []
        for row in range(len(columns[0])):
            row_lines.append(dv)
            for index, column in enumerate(columns):
                item = column[row]
                if item and type(item) != int and any([char.isnumeric() for char in str(item)]) and "$" not in item:
                    try:
                        fl, before, after = find_float(str(item))
                    except Exception as e:
                        print(item +" FAILED TO DISPLAY")                
                    f = 0
                    fitted_str = "{}{:.{}f}{}".format(before,fl, f,after)
                    while len(fitted_str) <= len(headers[index]) - 2:
                        fitted_str = "{}{:.{}f}{}".format(before,fl, f,after)
                        f += 1                     
                else:          
                    fitted_str = str(item)                    
                fitted_colored_str = self.color_coins(fitted_str.center(len(headers[index])))
                
                row_lines[row] += self.COLORS[col_colors[index]] + fitted_colored_str + self.COLORS[self.border_color]
                if index < len(columns) -1:
                    row_lines[row] += sv  
            row_lines[row] += dv 
        
        
        print(self.make_top(dh, dtl, dtr))
        for line in header_lines + row_lines + [bottom_line]:
            print(self.shift + line)
    

    def color_coins(self, fitted_str):
        for ticker in mmutils.Coinquery.get_tickers():
            if ticker in fitted_str and "XMR.to" not in fitted_str:
                fitted_str = fitted_str.replace(ticker, self.COLORS["BLUE"] + ticker)
        if "/" in fitted_str:
            fitted_str = fitted_str.replace("/", self.COLORS["WHITE_BOLD"] + "/")
        return fitted_str

   
    def print_display(self, border="~", end="~"):
        self.print_top(border, end)
        self.colored_lines
        print("\n".join(self.colored_lines))
        self.colored_lines
        self.print_bottom(border, end)

def find_float(string):
    if "e-" in string:
        fl, after = string.split()
        after = " " + after
        before = ""
    else:
        fl = "" 
        for char in string:
            if len(fl) > 0 and char == " ":
                break
            if char.isdigit() or char == ".":
                fl += char
        before, after = string.split(fl)
    return (float(fl), before, after)
    

def fit_float(float_to_fit, max_length):
    f = 0
    while len("{:.{}f}".format(float_to_fit, f)) < max_length:
        f += 1
    return "{:.{}f}".format(float_to_fit, f)  


def fit_floats(string, floats_to_fit, length, return_list=True):
    words = string.split()
    increment_order = []
    floats_index = 0 
    for index, word in enumerate(words):
        if word[0] == "{" and word[2] == "}":
            if type(floats_to_fit[floats_index]) == float:
                increment_order.insert(int(word[1]), {"float":floats_to_fit[floats_index],
                                             "index":index, "skipped":False,
                                             "f":0, "increment":1})
            elif type(floats_to_fit[0]) == tuple:
                increment_order.insert(int(word[1]), {"float":floats_to_fit[0][0], 
                                                 "index":index, "skipped": False,
                                                 "f":0, 
                                                 "increment":floats_to_fit[0][1]})
            floats_index += 1
        
    order_index = 0
    while len(" ".join(words)) <= length:
        
        if order_index >= len(increment_order):
            if not increment_order[0]["skipped"]:
                order_index = 0
            else:
                break
        
        ftf = increment_order[order_index]
        incremented = "{:.{}f}".format(ftf["float"], ftf["f"] + ftf["increment"])  
        test_words = words[:]
        test_words[ftf["index"]] = incremented

        if len(" ".join(test_words)) <= length:
            words[ftf["index"]] = incremented
            increment_order[order_index]["f"] += ftf["increment"]
            #order_index += 1
        else:
            if not ftf["skipped"]:
                increment_order[order_index]["skipped"] = True   
            else:
                break

        order_index += 1    
 
    if return_list:
        return (" ".join(words), ["{:.{}f}".format(ftf["float"], ftf["f"]) for ftf in increment_order])
    else:
        return " ".join(words)
    

def display(result, exchange):
    if exchange == "XMR.to":
        xmrto_display(result)
    elif exchange == "Godex.io":
        godex_display(result)
    else:
        morph_display(result)


def print_top(top, char, end, shift, length):
    fill = int((length - len(top)) / 2) - 1
    top = (
        end
        + char * fill
        + "\033[01;37;40m"
        + "{}".format(top)
        + "\033[00;33;40m"
        + char * fill
        + "{}".format(char if not (len(top) % 2 == 0) else end)
    )
    rjust = " " * shift
    print(
        rjust
        + "\033[00;33;40m{}\033[00;33;40m".format(top)
        + "{}".format(end if not (len(top) % 2 == 0) else "")
    )


def print_bottom(char, end, shift, length):
    bottom = end + char * (length - 2) + end
    rjust = " " * shift
    print(rjust + "\033[00;33;40m" + bottom)


def num_chars(amount, pos):
    decSplit = str(amount).split(".")
    return len(decSplit[pos])


def get_f(amount, max_len):
    if num_chars(amount, 0) + num_chars(amount, 1) > max_len:
        return max_len - num_chars(amount, 0)
    else:
        return num_chars(amount, 1)


def xmrto_display(result):
    if not (result.get("state") == "BTC_SENT" and result.get("btc_transaction_id") is None):
        top = result.get("state").upper().replace("_", " ")
    else:
        top = "SENDING"

    print()
    print_top(top, "~", "~", 0, 80)

    if result.get("state") in ["UNPAID", "UNDERPAID"]:
        print(
            "Waiting for a deposit, send {} XMR to: {}".format(
                result.get("xmr_amount_remaining"),
                result.get("xmr_receiving_integrated_address"),
            )
        )
        print("\nRate: {} BTC per XMR".format(result.get("xmr_price_btc")))
        minutes = result.get("seconds_till_timeout") // 60
        seconds = result.get("seconds_till_timeout") - (minutes * 60)
        print("Timeout in {} minutes {} seconds".format(minutes, seconds))

    elif result.get("state") in ["PAID", "PAID_UNCONFIRMED"]:
        print("\nYour order has been paid. BTC will be sent shortly")
        print("Refresh again until order status is: 'BTC_SENT'\n")

    elif result.get("state") in ["TIMED_OUT", "NOT_FOUND"]:
        print(
            "\n\033[01;31;40mERROR: ORDER {}\n".format(
                result.get("state").replace("_", " ")
            )
        )
        if result.get("state") == "TIMED_OUT":
            print(
                "\033[00;33;40mError message from \033[00;37;40mXMR.to\033[00;33;40m: \033[01;31;40morder timed out before payment was completed\033[00;33;40m\n"
            )
        else:
            print(
                "\033[00;33;40mError message from from \033[00;37;40mXMR.to\033[00;33;40m: \033[01;31;40morder wasn’t found in system (it never existed or was purged)\033[00;33;40m\n"
            )

    else:
        print(
            "\n\033[01;32;40mSuccess! \033[01;37;40m{} \033[01;36;40mBTC\033[00;33;40m has been sent anonymously by \033[00;37;40mXMR.to\033[00;33;40m to:\n\033[01;36;40m{}\033[00;33;40m\n".format(
                result.get("btc_amount"), result.get("btc_dest_address")
            )
        )
        print(
            "txid: \033[01;36;40m{}\033[00;33;40m ".format(
                result.get("btc_transaction_id"))
        )
    print_bottom("~", "~", 0, 80)


def godex_display(result):
    if result.get("status") == "wait" and result.get("coin_from") != "XMR":

        print()
        print_top("WAITING FOR DEPOSIT", "~", "~", 0, 80)
    else:
        if not (result.get("status") == "success" and result.get("hash_out") is None):
            top = result.get("status").upper()
        else:
            top = "EXCHANGING"

        print()
        print_top(top, "~", "~", 0, 80)

    if result.get("status") == "wait" and result.get("coin_from") != "XMR":
        print(
            "\n\033[00;37;40mWaiting for a deposit, send ~\033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;37;40m to deposit address:\n\033[01;36;40m".format(
                result.get("deposit_amount"), result.get("coin_from")
            )
        )
        print("{}".format(result.get("deposit")).center(80, " "))
        if result.get("deposit_extra_id") not in ["", None]:
            print(
                "                     \033[01;31;40mREQUIRED\033[01;37;40m {} {}: \033[01;36;40m{}\033[00;33;40m".format(
                    result.get("coin_from"),
                    mmutils.Coinquery.get_extra_id(result.get("coin_from")),
                    result.get("deposit_extra_id"),
                )
            )
        print(
            "\n\033[00;37;40mSend a single deposit. If the amount is significantly different from the\n"
            "expected input amount you entered a refund may happen.\033[00;33;40m"
        )

        print(
            "\n  Expected input amount: \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                result.get("deposit_amount"), result.get("coin_from")
            )
        )
        print(
            "  Estimated output amount: \033[01;32;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                result.get("withdrawal_amount"), result.get("coin_to")
            )
        )
        print(
            "\n  Rate: \033[01;37;40m{} \033[01;36;40m{}\033[00;33;40m per \033[01;36;40m{}\033[00;33;40m".format(
                result.get("rate"), result.get("coin_to"), result.get("coin_from")
            )
        )
    elif result.get("status") in ["confirmation", "confirmed", "exchanging"]:
        if result.get("status") == "confirmation":
            print(
                "Your transaction has been received and is waiting for confirmations."
            )
        elif result.get("status") in ["confirmed", "exchanging"]:
            print(
                "\033[01;32;40mYour transaction has been received and is confirmed. \033[00;33;40m\nGodex.io is now executing your trade.\n"
            )

        print(
            "\nConverting \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result.get("coin_from"), result.get("coin_to")
            )
        )
        print(
            "Anonymously sending \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result.get("coin_to"),
                result.get("withdrawal")
                if not result.get("coin_to") == "XMR"
                else "Your Monero Wallet",
            )
        )

    elif result.get("status") in ["sending", "sending_confirmation", "success"]:

        if result.get("hash_out") is None:
            print(
                "\033[01;32;40mYour transaction has been received and is confirmed. It will be sent shortly.\n"
            )

            print(
                "\033[00;37;40mGodex.io \033[00;33;40mwill send \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m to: \033[01;36;40m{}\033[00;33;40m".format(
                    (float(result.get("final_amount")) - float(result.get("fee"))),
                    result.get("coin_to"),
                    result.get("withdrawal")
                    if not result.get("coin_to") == "XMR"
                    else "Your Monero Wallet",
                )
            )
        else:
            print(
                "\n\033[01;32;40mSuccess! \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m has been sent anonymously \nto: \033[01;36;40m{}\033[00;33;40m\n\ntxid: \033[01;36;40m{}\033[00;33;40m".format(
                    (float(result.get("final_amount")) - float(result.get("fee"))),
                    result.get("coin_to"),
                    result.get("withdrawal")
                    if not result.get("coin_to") == "XMR"
                    else "Your Monero Wallet",
                    result.get("hash_out"),
                )
            )
    elif result.get("status") in ["refund", "error"]:
        print(
            "Godex.io will refund {} {}\nReason: {}".format(
                result.get("final_amount"), result.get("asset"), result.get("reason") #FIX THIS
            )
        )
        if result.get("hash_out"):
            print("txid: {}".format(result.get("hash_out")))
    elif result.get("status") == "refund":
        print(
            "\033[01;31;40mDeposit amount below network fee, too small to refund.\033[00;33;40m"
        )

    elif result.get("status") == "overdue":
        print(
            "\033[01;31;40mOrder timed out. All data has been purged by Godex.io. There is nothing to show.\033[00;33;40m"
        )

    elif result.get("status") == "wait" and result.get("coin_from") == "XMR":
        print(
            "\n\033[00;33;40mWaiting for \033[00;37;40mGodex.io \033[00;33;40mto receive your transaction.\n\n\033[01;36;40mOrder status will be updated as soon as the transaction is received. \n\n\033[01;31;40m(This may take some time, please wait.)"
        )
    print_bottom("~", "~", 0, 80)


def morph_display(result):
    if result.get("state") == "PENDING" and result.get("asset") != "XMR":
        print()
        print_top("WAITING FOR DEPOSIT", "~", "~", 0, 80)
    else:
        if not (result.get("state") == "COMPLETE" and result.get("output")[0].get("txid") is None):
            top = result.get("state").upper()
        else:
            top = "EXCHANGING"

        print()
        print_top(top, "~", "~", 0, 80)

    if result.get("state") == "PENDING" and result.get("input").get("asset") != "XMR":
        print(
            "\n\033[00;37;40mWaiting for a deposit, send \033[01;36;40m{}\033[00;37;40m to deposit address:\n\033[01;36;40m".format(
                result.get("input").get("asset")
            )
        )
        print("{}".format(result.get("input").get("deposit_address")).center(80, " "))

        print(
            "\n\033[00;37;40mSend a single deposit. If the amount is outside the limits a refund will happen.\033[00;33;40m"
        )

        print(
            "\n  Minimum amount accepted: \033[01;31;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                mmutils.morph_format(
                    result.get("input").get("asset"), result.get("input").get("limits").get("min")
                ),
                result.get("input").get("asset"),
            )
        )
        print(
            "  Maximum amount accepted: \033[01;31;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                mmutils.morph_format(
                    result.get("input").get("asset"), result.get("input").get("limits").get("max")
                ),
                result.get("input").get("asset"),
            )
        )
        print(
            "\n  Rate: \033[01;37;40m{} \033[01;36;40m{}\033[00;33;40m per \033[01;36;40m{}\033[00;33;40m".format(
                result.get("output")[0].get("seen_rate"),
                result.get("output")[0].get("asset"),
                result.get("input").get("asset"),
            )
        )

    elif result.get("state") in ["PROCESSING", "TRADING", "CONFIRMING"]:
        if result.get("state") == "CONFIRMING":
            print("Your transaction has been received and is waiting for confirmations")
        elif result.get("state") == "TRADING":
            print(
                "Your transaction has been received and is confirmed. MorphToken is now executing your trade.\n"
                "Usually this step takes no longer than a minute, "
                "but there have been reports of it taking a couple of hours.\n"
            )
        print(
            "\nConverting \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result.get("input").get("asset"), result.get("output")[0].get("asset")
            )
        )
        print(
            "Anonymously sending \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result.get("output")[0].get("asset"),
                result.get("output")[0].get("address")
                if not result.get("output")[0].get("asset") == "XMR"
                else "Your Monero Wallet",
            )
        )

    elif result.get("state") == "COMPLETE":
        output = result.get("output")[0]
        if output.get("txid") is None:
            print(
                "\033[01;32;40mYour transaction has been received and is confirmed. It will be sent shortly.\n"
            )
            print(
                "\033[00;37;40mMorphtoken \033[00;33;40mwill send \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m to: \033[01;36;40m{}\033[00;33;40m".format(
                    mmutils.morph_format(
                        output.get("asset"),
                        output.get("converted_amount") -
                        output.get("network_fee").get("fee"),
                    ),
                    output.get("asset"),
                    output.get("address")
                    if not output.get("asset") == "XMR"
                    else "Your Monero Wallet",
                )
            )
        else:
            print(
                "\n\033[01;32;40mSuccess! \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m has been sent anonymously \nto: \033[01;36;40m{}\033[00;33;40m\n\ntxid: \033[01;36;40m{}\033[00;33;40m".format(
                    mmutils.morph_format(
                        output.get("asset"),
                        output.get("converted_amount") -
                        output.get("network_fee").get("fee"),
                    ),
                    output.get("asset"),
                    output.get("address")
                    if not output.get("asset") == "XMR"
                    else "Your Monero Wallet",
                    output.get("txid"),
                )
            )
    elif result.get("state") in ["PROCESSING_REFUND", "COMPLETE_WITH_REFUND"]:
        print(
            "Morphtoken will refund {} {}\nReason: {}".format(
                result.get("final_amount"), result.get("asset"), result.get("reason")
            )
        )
        if result.get("txid"):
            print("txid: {}".format(result.get("txid")))
    elif result.get("state") == "COMPLETE_WITHOUT_REFUND":
        print(
            "\033[01;31;40mDeposit amount below network fee, too small to refund.\033[00;33;40m"
        )

    elif result.get("state") == "PENDING" and result.get("input").get("asset") == "XMR":
        print(
            "\n\033[00;33;40mWaiting for \033[00;37;40mMorphToken \033[00;33;40mto receive your transaction.\n\n\033[01;36;40mOrder status will be updated as soon as the transaction is received. \n\n\033[01;31;40m(This may take some time, please wait.)"
        )
    print_bottom("~", "~", 0, 80)

      
def make_qr(coin, qrdata):    
    for i in range(len(qrdata)):
        qr = qrcode.QRCode(border=1)
        qr.add_data(qrdata[i].strip())

        if coin != "XMR":
            if i == 0:
                qrtext = "{}: \033[01;36;40m{}\033[00;33;40m".format("\033[01;36;40m{} \033[01;37;40mDeposit Address".format(coin), qrdata[i])
            elif i == 1:
                qrtext = "\033[01;31;40mREQUIRED \033[01;37;40m{} {}\033[00;33;40m".format(coin, mmutils.Coinquery.get_extra_id(coin), qrdata[i].strip())
        else:
            qr.error_correction = qrcode.constants.ERROR_CORRECT_L 
            qrtext = "\033[01;37;40mYour Current Monero Receiving Address is: \033[01;36;40m{}\033[00;33;40m".format(qrdata[0])
        print(qrtext)
        qr.print_ascii(tty=False)
    
def print_qr(coin, qrdata, qrlines, cols=80):
    qrlines = [line.replace("\n", "") for line in qrlines]  
    req_line = None

    for line_num, line in enumerate(qrlines):
        if "REQUIRED" in line:
                req_line = line_num 
            
    if req_line is None:
        print(qrlines[0])
        for line in qrlines[1:]:
            print(int((cols -len(line))/2)*" " + line)

    else:
        left_len = len("{} Deposit address: {}".format(coin, qrdata[0].strip()))
        right_len = len("REQUIRED {} {}: {}".format(coin, mmutils.Coinquery.get_extra_id(coin), qrdata[1].strip()))
        top_len =  left_len + right_len
        
        if top_len <= cols - 2: 
            top_split = (cols - top_len) * " "  
            print(qrlines[0] + top_split + qrlines[req_line])
            print_bottom_row = False
        else:
            print("\033[01;37;40mLEFT: {}".format(qrlines[0]))
            print_bottom_row = True
            
        for i in range(1, max(req_line, (len(qrlines) - req_line))):
            left_qr = qrlines[i]
            if (i + req_line) < len(qrlines):
                right_qr = qrlines[req_line + i]
                qr_split = (cols - len(left_qr) - len(right_qr)) * " "
                print(left_qr + qr_split + right_qr)
            else:
                if req_line > (len(qrlines) - req_line):
                    if print_bottom_row and i - 1 == (len(qrlines) - req_line):
                        print(left_qr + (cols - len(left_qr) - len("RIGHT: ") - right_len) * " " + "\033[01;37;40mRIGHT: " + qrlines[req_line])
                        print_bottom_row = False
                    else:
                        print(left_qr + (cols - len(left_qr)) * " ")
                else:
                    right_qr = qrlines[req_line + i]
                    print((cols - len(right_qr)) * " " + right_qr)
        if print_bottom_row:
            print((cols - len("RIGHT: ") - right_len) * " " +"\033[01;37;40mRIGHT: " + qrlines[req_line])
          
