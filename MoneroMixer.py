import re
import json
import argparse
import requests
import math
import qrcode
import random
from time import sleep
from time import time
from concurrent.futures import ThreadPoolExecutor
from sys import argv

#REQUEST HELPER FUNCTIONS
def get_random_user_agent(num_ua):
    uaList = []
    all_ua = open("../../Info/user-agents.txt").readlines()  
    for i in range(num_ua):
        uaList.append(all_ua[random.randint(0,len(all_ua))])
    return uaList

def make_header(args):
    return {"Accept": "application/json", "Content-Type": "application/json",
"User-Agent" : get_random_user_agent(1)[0].strip()}

# WALLET HELPER FUNCTIONS
def get_balance(index):
    with open("balance", "r+") as f:
        balances = (
            f.readline()
            .replace("Balance: ", "")
            .replace("unlocked balance: ", "")
            .replace(",", "")
            .split(" ")
        )
    return balances[index].strip()


def get_unlocked_balance(args):
    return float(get_balance(1))


def get_total_balance(args):
    return float(get_balance(0))


def get_blocks_left(args):
    try:
        return int(get_balance(2)[1])
    except:
        return 0


def get_address(args):
    with open("address", "r+") as f:
        address_str = f.readline().replace("  (Untitled address)", "")
    num, address = address_str.split("  ", 1)
    return address.strip()


def update_prices(args):
    try:
        with open("fiat-prices", "r") as f:
            last_update = float(f.readlines()[1])
    except:
        last_update = None

    if last_update is None or time() - last_update >= args.update:
        result = requests.get(
            "https://min-api.cryptocompare.com/data/price?fsym=XMR&tsyms={},EUR,BTC,LTC,ETH,BCH,DASH".format(
                args.fiat
            ), headers = make_header(0) 
        )
        with open("fiat-prices", "w+") as f:
            f.write(result.text + "\n{}".format(time()))


def print_address(args):
    address = get_address(args)

    print(
        "\nYour Current Monero Wallet Receiving Address is: \n\n\033[01;36;40m{}\033[00;33;40m".format(
            address
        )
    )
    print(
        "\n\n\033[01;31;40mIMPORTANT: For maximum security it is recommended that you send\n"
        "ONLY ONE TRANSACTION PER ADDRESS\033[00;33;40m\n"
    )
    print(
        "\033[00;37;40mA new receiving address is generated automatically every time you start this\n"
        "program or select 'View Current XMR Receiving Address' from the wallet menu.\033[00;33;40m\n"
    )


def print_balance(args):
    if args.fiat is None:
        fiat = "USD"
    else:
        fiat = args.fiat
    if args.symbol is None:
        fiat_symbol = "$"
    else:
        fiat_symbol = args.symbol

    xmr_balance_unlocked = get_unlocked_balance(args)
    xmr_balance_total = get_total_balance(args)

    blocks_to_unlock = get_blocks_left(args)
    unlock_est_time = blocks_to_unlock * 2

    with open("fiat-prices", "r") as f:
        result = json.loads(f.readline())

    xmr_fiat = float(result[fiat])
    total_fiat = xmr_balance_total * xmr_fiat
    unlocked_fiat = xmr_balance_unlocked * xmr_fiat

    xmr_btc = float(result["BTC"])
    total_btc = xmr_balance_total * xmr_btc
    unlocked_btc = xmr_balance_unlocked * xmr_btc

    print(
        "  1 \033[01;36;40mXMR\033[00;33;40m ≈ \033[00;37;40m{}{:.2f} \033[00;33;40m€{:.2f} \033[00;37;40m{:.4f} \033[01;36;40mBTC \033[00;33;40m{:.4f} \033[01;36;40mLTC \033[00;37;40m{:.4f} \033[01;36;40mETH \033[00;33;40m{:.4f} \033[01;36;40mBCH \033[00;37;40m{:.4f} \033[01;36;40mDASH\n".format(
            fiat_symbol,
            result[fiat],
            result["EUR"],
            result["BTC"],
            result["LTC"],
            result["ETH"],
            result["BCH"],
            result["DASH"],
        )
    )
    print_top("YOUR MONERO WALLET BALANCE", "~", "~", 0, 80)
    print(
        "Total Balance (Locked + Unlocked): \033[01;37;40m{} \033[01;36;40mXMR\033[00;33;40m ≈ \033[01;32;40m{}{:.2f}\033[00;33;40m ≈ \033[00;37;40m{:.6f} \033[01;36;40mBTC\033[00;33;40m".format(
            xmr_balance_total, fiat_symbol, total_fiat, total_btc
        )
    )
    print(
        "Unlocked Balance (Unlocked only): \033[01;37;40m{} \033[01;36;40mXMR\033[00;33;40m ≈ \033[01;32;40m{}{:.2f}\033[00;33;40m ≈ \033[00;37;40m{:.6f} \033[01;36;40mBTC\033[00;33;40m".format(
            xmr_balance_unlocked, fiat_symbol, unlocked_fiat, unlocked_btc
        )
    )

    if args.type != "limited":
        print(
            "\033[00;33;40mBlocks to Unlock: \033[00;37;40m{} \033[00;33;40mEstimated time: \033[00;37;40m~{} minutes \033[00;33;40m(Refresh balance to update)".format(
                blocks_to_unlock, unlock_est_time
            )
        )
    print_bottom("~", "~", 0, 80)

    if args.type == "full":
        print(
            "\033[00;37;40mTotal Balance is everything your Monero wallet has received so far.\033[00;33;40m\n\n"
            "Unlocked balance is the amount of XMR in your wallet that has confirmed\non the Monero blockchain and is withdrawable now.\n\n\033[00;37;40mLocked balance cannot be sent or converted until it is unlocked.\n\n"
            "\033[00;33;40mLocked balance typically takes ~2 minutes per block to become unlocked."
        )


# VIEW PREVIOUS TRANSACTIONS:
def view(args):
    if args.id is None:
        id_file = "last" + args.type + ""
        with open(id_file, "r+") as f:
            id_str = f.readline()

        if args.exchange == "XMR.to":
            order_id = id_str[16:30].strip()
        elif args.exchange == "Godex.io":
            order_id = id_str[18:33].strip()
        else:
            order_id = id_str[20:35].strip()
    else:
        order_id = args.id.strip()

    print(
        "\033[00;37;40m{}\033[00;33;40m Order ID: \033[01;36;40m{}".format(
            args.exchange, order_id
        )
    )
    print(
        "\n\033[00;33;40mRequesting order status from \033[00;37;40m{}\033[00;33;40m...".format(
            args.exchange
        )
    )

    result = order_status(args.exchange, order_id)
    if args.type == "deposit":
        with open("qr", "a+") as f:
            if args.exchange == "Godex.io":
                f.write(result["deposit"])
            else:
                f.write(result["input"]["deposit_address"])
    display(args.exchange, result)


# UPDATE ORDER STATUS
def order_status(exchange, order_id):
    if exchange == "XMR.to":
        response = requests.post(
            "https://xmr.to/api/v2/xmr2btc/order_status_query/", headers = make_header(0), data={"uuid": order_id}
        )
    elif exchange == "Godex.io":
        response = requests.get("https://api.godex.io/api/v1/transaction/" + order_id, headers = make_header(0))
    else:
        response = requests.get("https://api.morphtoken.com/morph/" + order_id, headers = make_header(0))

    if response.status_code == 200 or response.status_code == 201:
        return response.json()
    else:
        error_out(
            "ERROR {}: {}".format(
                response.status_code,
                "Order ID not found."
                if response.status_code == 404
                else "Failed to load order",
            ),
            "{} order ID: {} not was not found.".format(exchange, order_id)
            if response.status_code == 404
            else "Failed to load {} order ID: {}".format(exchange, order_id),
        )


# QUERY AN VIEW EXCHANGE RATES
def rates(args):
    exchange = args.exchange
    coin_in = args.cin.upper()
    coin_out = args.out.upper()
    
    if exchange != "XMR.to":
        try:
            print(
                "\033[00;33;40mSecurely fetching latest \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m exchange rates from \033[00;37;40m{}\033[00;33;40m servers...\n".format(
                    coin_in, coin_out, exchange
                )
            )
            if exchange == "Godex.io":
                json_data = {"from": coin_in, "to": coin_out, "amount": 1.5}
                result = requests.post(
                    "https://api.godex.io/api/v1/info{}".format(
                        "-revert" if coin_out == "XMR" else ""
                    ),
                    headers = make_header(0),
                    json=json_data,
                ).json()
                rate = float(result["rate"])
                minimum = float(result["min_amount"])
                maximum = float(result["max_amount"])
                if coin_out == "XMR":
                    minimum = minimum / rate
            else:
                json_data = {
                    "input": {"asset": coin_in},
                    "output": [{"asset": coin_out, "weight": 10000}],
                }
                result = requests.post(
                    "https://api.morphtoken.com/limits", headers = make_header(0), json=json_data
                ).json()
                rate = float(result["output"][0]["seen_rate"])
                minimum = float(morph_format(coin_in, result["input"]["limits"]["min"]))
                maximum = float(morph_format(coin_in, result["input"]["limits"]["max"]))

            print_parameters(
                exchange, coin_in, coin_out, 1 / rate, minimum, maximum, None
            )
            if rate == 0:  # and float(result['min_amount']) >= 1:
                error_out(
                    "ERROR: Maximum amount you can exchange is 0.",
                    "{} to {} exchanges are not available at this time.\nCheck again later or try another coin.".format(
                        coin_in, coin_out
                    ),
                )

        except:
            error_out(
                "ERROR: Failed to get {} to {} rates from {}".format(
                    coin_in, coin_out, exchange
                ),
                "{} to {} exchanges may not be available at this time.\nCheck again later or try another coin.".format(
                    coin_in, coin_out
                ),
            )

    else:
        print(
            "\033[00;33;40mSecurely fetching latest \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m exchange rates from \033[00;37;40m{}\033[00;33;40m servers...\n".format(
                coin_in, coin_out, exchange
            )
        )
        try:
            response = requests.get(
                "https://xmr.to/api/v2/xmr2btc/order_parameter_query/",
                headers = make_header(0)
            )
            result = response.json()
            rate = result["price"]
            minimum = result["lower_limit"]
            maximum = result["upper_limit"]
            zero_conf = result["zero_conf_max_amount"]
            print_parameters(
                exchange, coin_out, coin_in, rate, minimum, maximum, zero_conf
            )
        except:
            try:
                result = response.json()
                error_out(
                    "ERROR: {}".format(result["error_msg"]),
                    "{}\nError message from XMR.to: {}\033[00;33;40m".format(
                        result["error"], result["error_msg"]
                    ),
                )
            except:
                error_out(
                    "ERROR: Failed to connect to XMR.to servers.",
                    "Failed to connect to XMR.to servers. Try again later.",
                )

    if coin_out != "XMR":
        print_estimates(rate, coin_out)


# ESTIMATE MAX YOU CAN SEND
def num_chars(amount, pos):
    decSplit = str(amount).split(".")
    return len(decSplit[pos])


def get_f(amount, max_len):
    if num_chars(amount, 0) + num_chars(amount, 1) > max_len:
        return max_len - num_chars(amount, 0)
    else:
        return num_chars(amount, 1)


def print_parameters(exchange, coin_in, coin_out, rate, minimum, maximum, zero_conf):
    rate_f = 8
    min_f = get_f(minimum, 8)
    max_f = get_f(maximum, 8)

    length = 50
    rs = int((80 - length) / 2)
    r = " " * rs
    print_top(
        "EXCHANGE PARAMETERS FROM {}".format(exchange.upper()), "~", "~", rs, length
    )
    print(
        r
        + "Estimated exchange rate: \033[01;37;40m{:.{}f} \033[01;36;40m{}\033[00;33;40m per \033[01;36;40m{}\033[0;33;40m ".format(
            rate, rate_f, coin_in, coin_out
        )
    )

    print(
        r
        + "Minimum \033[01;36;40m{}\033[00;33;40m amount you can exchange: \033[01;31;40m{:.{}f}\033[01;36;40m {}\033[00;33;40m ".format(
            coin_in, minimum, min_f, coin_in
        )
    )
    if rate == 0 or maximum != 0:
        print(
            r
            + "Maximum \033[01;36;40m{}\033[00;33;40m amount you can exchange: \033[01;31;40m{:.{}f}\033[01;36;40m {}\033[00;33;40m ".format(
                coin_in, maximum, max_f, coin_in
            )
        )
    if zero_conf is not None:
        print(
            r
            + "Instant transactions enabled up to: \033[01;37;40m{}\033[01;36;40m BTC\033[00;33;40m".format(
                zero_conf
            )
        )
    print_bottom("~", "~", rs, length)
    print()


def print_estimates(rate, coin_out):
    xmr_balance = get_unlocked_balance(1)
    est_output_after_fees = (xmr_balance * rate) * 0.995

    max_f = get_f(est_output_after_fees, 8)
    r = " " * 15
    print_top("ESTIMATED MAX YOU CAN SEND", "~", "~", 15, 50)
    print(
        r
        + "Your Monero Wallet unlocked balance: \033[01;37;40m{} \033[01;36;40mXMR\033[00;33;40m".format(
            xmr_balance
        )
    )
    print(
        r
        + "Estimated maximum \033[01;36;40m{}\033[00;33;40m you can send: \033[01;37;40m{:.{}f} \033[01;36;40m{}\033[00;33;40m".format(
            coin_out, est_output_after_fees, max_f, coin_out
        )
    )
    print_bottom("~", "~", 15, 50)
    print()


# EXCHANGE FUNCTIONS
def process_response(response, exchange, id_key, err_msg_key):
    if response.status_code == 200 or response.status_code == 201:
        result = response.json()
        print(
            "\n\033[00;37;40m{} \033[00;33;40mOrder ID: \033[01;36;40m{}\033[00;37;40m\n".format(
                exchange, result[id_key]
            )
        )
        return result
    else:
        if response.status_code != 403:
            error_title = "ERROR {}: BAD REQUEST".format(response.status_code)
            try:
                result = response.json()
                error_text = "REASON: {}".format(result[err_msg_key])
            except:
                error_text = "Try again later."
            error_out(error_title, error_text)
        else:
            error_out(
                "ERROR: FORBIDDEN",
                "REASON: {} block US-based tor exit nodes.\n".format(exchange)
                + "\nTry disconnecting your network connection (Airplane Mode) wait a few seconds\n"
                + "then reconnect. Wait for the notification that Tor is ready then try again.",
            )


def create_transaction(
    exchange, coin_in, coin_out, refund_address, dest_address, extra_id, amount
):
    print(
        "\n\033[00;33;40mSecurely connecting to \033[00;37;40m{}\033[00;33;40m servers to create order...\n".format(
            exchange
        )
    )

    if exchange == "XMR.to":
        APIurl = "https://xmr.to/api/v2/xmr2btc/order_create/"
        json_data = {"btc_dest_address": dest_address, "btc_amount": amount}
        id_key = "uuid"
        err_msg_key = "error_msg"

    elif exchange == "Godex.io":
        APIurl = "https://api.godex.io/api/v1/transaction"

        if coin_in == "XMR":
            withdrawal_extra_id = extra_id
            return_extra_id = None
        else:
            withdrawal_extra_id = None
            return_extra_id = extra_id

        json_data = {
            "coin_from": coin_in,
            "coin_to": coin_out,
            "deposit_amount": amount,
            "withdrawal": dest_address,
            "withdrawal_extra_id": withdrawal_extra_id,
            "return": refund_address,
            "return_extra_id": return_extra_id,
            "affiliate_id": "DObYfBjJxbebSF2H",
        }

        id_key = "transaction_id"
        err_msg_key = "error"

    elif exchange == "MorphToken":
        APIurl = "https://api.morphtoken.com/morph"
        json_data = {
            "input": {"asset": coin_in, "refund": refund_address},
            "output": [{"asset": coin_out, "weight": 10000, "address": dest_address}],
            "tag": "MoneroMixer",
        }
        id_key = "id"
        err_msg_key = "description"

    return process_response(
        requests.post(APIurl, headers = make_header(0), json=json_data),
        exchange,
        id_key,
        err_msg_key,
    )


def deposit(args):
    coin_out = "XMR"
    coin_in = args.cin.upper()

    exchange = args.exchange

    wallet_address = get_address(args)
    refund_address = args.refund.strip()
    if refund_address == "None":
        refund_address = ""

    if exchange == "Godex.io":
        extra_id = godex_get_extra_id(args)
        id_key = "transaction_id"
        amount = float(args.amount[0])
    else:
        extra_id = None
        id_key = "id"
        amount = None

    result = create_transaction(
        exchange, coin_in, coin_out, refund_address, wallet_address, extra_id, amount
    )

    with open("depositIDs", "a") as f:
        f.write("{} Order ID: ".format(exchange) + result[id_key] + "\n")

    print(
        "\n{} Order ID saved to '\033[01;36;40mdepositIDs.enc\033[00;33;40m'".format(
            exchange
        )
    )
    print(
        "\033[01;37;40mYou can view the IDs of all your previous deposits by decrypting this file \nthrough the settings and utilities menu.\033[00;33;40m"
    )


def withdraw(args):
    coin_in = "XMR"
    coin_out = args.out.upper()
    amount = float(args.amount[0])
    dest_address = args.dest.strip()

    exchange = args.exchange

    if exchange != "XMR.to":
        refund_address = get_address(args)
        if exchange == "Godex.io":
            extra_id = godex_get_extra_id(args)
        else:
            extra_id = None
    else:
        refund_address = None
        extra_id = None

    result = create_transaction(
        exchange, coin_in, coin_out, refund_address, dest_address, extra_id, amount
    )
    withdraw_data_out(exchange, result, amount)


# PASS DATA BACK TO BASH SCRIPT
def withdraw_data_out(exchange, result, xmr_amount):
    data_str = ""
    if exchange == "XMR.to":
        id_key = "uuid"

        sleep(5)
        result = order_status(exchange, result[id_key])
        data_str += str(result["xmr_amount_remaining"]) + " "
        data_str += result["xmr_receiving_integrated_address"] + " "
        data_str += str(result["btc_amount"]) + " "
        data_str += result["btc_dest_address"] + " "

        donation_check(result["xmr_amount_remaining"], 0.001, result["xmr_price_btc"])

    elif exchange == "Godex.io":
        id_key = "transaction_id"

        result = order_status(exchange, result[id_key])
        data_str += result["deposit_amount"] + " "
        data_str += result["deposit"] + " "
        data_str += result["withdrawal_amount"] + " "
        data_str += result["withdrawal"] + " "

        result2 = requests.post(
            "https://api.godex.io/api/v1/info",
            headers = make_header(0),
            json={
                "from": result["coin_from"],
                "to": result["coin_to"],
                "amount": result["deposit_amount"],
            },
        ).json()

        donation_check(result["deposit_amount"], result2["min_amount"], None)

    elif exchange == "MorphToken":
        id_key = "id"

        result = order_status(exchange, result[id_key])
        data_str += str(xmr_amount) + " "
        data_str += result["input"]["deposit_address"] + " "
        data_str += (
            str((float(xmr_amount) * float(result["output"][0]["seen_rate"]))) + " "
        )
        data_str += result["output"][0]["address"] + " "

        donation_check(
            xmr_amount, morph_format("XMR", result["input"]["limits"]["min"]), None
        )

    with open("tx-out", "a") as f:
        f.write(data_str)
    with open("withdrawalIDs", "a") as f2:
        f2.write("{} Order ID: ".format(exchange) + result[id_key] + "\n")

    print(
        "\n\033[01;37;40m{} Order ID saved to '\033[01;36;40mwithdrawalIDs.enc\033[00;33;40m'".format(
            exchange
        )
    )
    print(
        "\033[01;37;40mYou can view the IDs of all your previous withdrawals by decrypting this file \nthrough the settings and utilities menu.\033[00;33;40m"
    )


def donation_check(xmr_amount, min_accepted, rate):
    xmr_balance = get_total_balance(1)
    xmr_out = float(xmr_amount)
    min_acc = float(min_accepted)
    balance_remaining = (xmr_balance - xmr_out) * 0.985

    data_str = ""
    if rate is not None:
        max_btc_out = rate * balance_remaining
        if max_btc_out < min_acc and balance_remaining > 0:
            data_str += str("{:.12f}".format(balance_remaining)) + " "
            data_str += str(min_acc) + " "
            data_str += str(rate) + " "
            data_str += str("{:.6}".format(max_btc_out)) + " "

            with open("d", "a") as f:
                f.write(data_str)
    else:
        if balance_remaining < min_acc and balance_remaining > 0:
            data_str += str("{:.12f}".format(balance_remaining)) + " "
            data_str += str(min_acc) + " "
            data_str += "None "
            data_str += "None "

            with open("d", "a") as f:
                f.write(data_str)


# DISPLAY FUNCTIONS
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


def view_qr(args):
    with open("qr", "r+") as f:
        deposit_address = f.readline()
    qr = qrcode.QRCode()
    qr.add_data(deposit_address)
    qr.make(fit=qr.best_fit())
    qr.print_ascii(tty=True)


def display(exchange, result):
    if exchange == "XMR.to":
        xmrto_display(result)
    elif exchange == "Godex.io":
        godex_display(result)
    else:
        morph_display(result)


def xmrto_display(result):
    if not (result["state"] == "BTC_SENT" and result["btc_transaction_id"] is None):
        top = result["state"].upper().replace("_", " ")
    else:
        top = "SENDING"

    print()
    print_top(top, "~", "~", 0, 80)

    if result["state"] in ["UNPAID", "UNDERPAID"]:
        print(
            "Waiting for a deposit, send {} XMR to: {}".format(
                result["xmr_amount_remaining"],
                result["xmr_receiving_integrated_address"],
            )
        )
        print("\nRate: {} BTC per XMR".format(result["xmr_price_btc"]))
        minutes = math.trunc(result["seconds_till_timeout"] / 60)
        seconds = result["seconds_till_timeout"] - (minutes * 60)
        print("Timeout in {} minutes {} seconds".format(minutes, seconds))

    elif result["state"] in ["PAID", "PAID_UNCONFIRMED"]:
        print("\nYour order has been paid. BTC will be sent shortly")
        print("Refresh again until order status is: 'BTC_SENT'\n")

    elif result["state"] in ["TIMED_OUT", "NOT_FOUND"]:
        print(
            "\n\033[01;31;40mERROR: ORDER {}\n".format(
                result["state"].replace("_", " ")
            )
        )
        if result["state"] == "TIMED_OUT":
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
                result["btc_amount"], result["btc_dest_address"]
            )
        )
        print(
            "txid: \033[01;36;40m{}\033[00;33;40m ".format(result["btc_transaction_id"])
        )
    print_bottom("~", "~", 0, 80)


def godex_display(result):
    if result["status"] == "wait" and result["coin_from"] != "XMR":

        print()
        print_top("WAITING FOR DEPOSIT", "~", "~", 0, 80)
    else:
        if not (result["status"] == "success" and result["hash_out"] is None):
            top = result["status"].upper()
        else:
            top = "EXCHANGING"

        print()
        print_top(top, "~", "~", 0, 80)

    if result["status"] == "wait" and result["coin_from"] != "XMR":
        print(
            "\n\033[00;37;40mWaiting for a deposit, send ~\033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;37;40m to deposit address:\n\033[01;36;40m".format(
                result["deposit_amount"], result["coin_from"]
            )
        )
        print("{}".format(result["deposit"]).center(80, " "))
        if result["deposit_extra_id"] is not None:
            print(
                "                     \033[01;31;40mREQUIRED\033[01;37;40m {} {}: \033[01;36;40m{}\033[00;33;40m".format(
                    result["coin_from"],
                    godex_get_extra_id_name(result["coin_from"]),
                    result["deposit_extra_id"],
                )
            )
        print(
            "\n\033[00;37;40mSend a single deposit. If the amount is significantly different from the\n"
            "expected input amount you entered a refund may happen.\033[00;33;40m"
        )

        print(
            "\n  Expected input amount: \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                result["deposit_amount"], result["coin_from"]
            )
        )
        print(
            "  Estimated output amount: \033[01;32;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                result["withdrawal_amount"], result["coin_to"]
            )
        )
        print(
            "\n  Rate: \033[01;37;40m{} \033[01;36;40m{}\033[00;33;40m per \033[01;36;40m{}\033[00;33;40m".format(
                result["rate"], result["coin_to"], result["coin_from"]
            )
        )
    elif result["status"] in ["confirmation", "confirmed", "exchanging"]:
        if result["status"] == "confirmation":
            print(
                "Your transaction has been received and is waiting for confirmations."
            )
        elif result["status"] in ["confirmed", "exchanging"]:
            print(
                "\033[01;32;40mYour transaction has been received and is confirmed. \033[00;33;40m\nGodex.io is now executing your trade.\n"
            )

        print(
            "\nConverting \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result["coin_from"], result["coin_to"]
            )
        )
        print(
            "Anonymously sending \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result["coin_to"],
                result["withdrawal"]
                if not result["coin_to"] == "XMR"
                else "Your Monero Wallet",
            )
        )

    elif result["status"] in ["sending", "sending_confirmation", "success"]:

        if result["hash_out"] is None:
            print(
                "\033[01;32;40mYour transaction has been received and is confirmed. It will be sent shortly.\n"
            )

            print(
                "\033[00;37;40mGodex.io \033[00;33;40mwill send \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m to: \033[01;36;40m{}\033[00;33;40m".format(
                    (float(result["final_amount"]) - float(result["fee"])),
                    result["coin_to"],
                    result["withdrawal"]
                    if not result["coin_to"] == "XMR"
                    else "Your Monero Wallet",
                )
            )
        else:
            print(
                "\n\033[01;32;40mSuccess! \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m has been sent anonymously \nto: \033[01;36;40m{}\033[00;33;40m\n\ntxid: \033[01;36;40m{}\033[00;33;40m".format(
                    (float(result["final_amount"]) - float(result["fee"])),
                    result["coin_to"],
                    result["withdrawal"]
                    if not result["coin_to"] == "XMR"
                    else "Your Monero Wallet",
                    result["hash_out"],
                )
            )
    elif result["status"] in ["refund", "error"]:
        print(
            "Godex.io will refund {} {}\nReason: {}".format(
                result["final_amount"], result["asset"], result["reason"]
            )
        )
        if result.get("hash_out"):
            print("txid: {}".format(result["hash_out"]))
    elif result["status"] == "refund":
        print(
            "\033[01;31;40mDeposit amount below network fee, too small to refund.\033[00;33;40m"
        )

    elif result["status"] == "overdue":
        print(
            "\033[01;31;40mOrder timed out. All data has been purged by Godex.io. There is nothing to show.\033[00;33;40m"
        )

    elif result["status"] == "wait" and result["coin_from"] == "XMR":
        print(
            "\n\033[00;33;40mWaiting for \033[00;37;40mGodex.io \033[00;33;40mto receive your withdrawal.\n\033[01;36;40mOrder status will be updated as soon as the transaction is received. \n\n\033[01;31;40m(This may take some time, please wait.)"
        )
    print_bottom("~", "~", 0, 80)


def morph_display(result):
    if result["state"] == "PENDING" and result["input"]["asset"] != "XMR":
        print()
        print_top("WAITING FOR DEPOSIT", "~", "~", 0, 80)
    else:
        if not (result["state"] == "COMPLETE" and result["output"][0]["txid"] is None):
            top = result["state"].upper()
        else:
            top = "EXCHANGING"

        print()
        print_top(top, "~", "~", 0, 80)

    if result["state"] == "PENDING" and result["input"]["asset"] != "XMR":
        print(
            "\n\033[00;37;40mWaiting for a deposit, send \033[01;36;40m{}\033[00;37;40m to deposit address:\n\033[01;36;40m".format(
                result["input"]["asset"]
            )
        )
        print("{}".format(result["input"]["deposit_address"]).center(80, " "))

        print(
            "\n\033[00;37;40mSend a single deposit. If the amount is outside the limits a refund will happen.\033[00;33;40m"
        )

        print(
            "\n  Minimum amount accepted: \033[01;31;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                morph_format(
                    result["input"]["asset"], result["input"]["limits"]["min"]
                ),
                result["input"]["asset"],
            )
        )
        print(
            "  Maximum amount accepted: \033[01;31;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m".format(
                morph_format(
                    result["input"]["asset"], result["input"]["limits"]["max"]
                ),
                result["input"]["asset"],
            )
        )
        print(
            "\n  Rate: \033[01;37;40m{} \033[01;36;40m{}\033[00;33;40m per \033[01;36;40m{}\033[00;33;40m".format(
                result["output"][0]["seen_rate"],
                result["output"][0]["asset"],
                result["input"]["asset"],
            )
        )

    elif result["state"] in ["PROCESSING", "TRADING", "CONFIRMING"]:
        if result["state"] == "CONFIRMING":
            print("Your transaction has been received and is waiting for confirmations")
        elif result["state"] == "TRADING":
            print(
                "Your transaction has been received and is confirmed. MorphToken is now executing your trade.\n"
                "Usually this step takes no longer than a minute, "
                "but there have been reports of it taking a couple of hours.\n"
            )
        print(
            "\nConverting \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result["input"]["asset"], result["output"][0]["asset"]
            )
        )
        print(
            "Anonymously sending \033[01;36;40m{}\033[00;33;40m to \033[01;36;40m{}\033[00;33;40m".format(
                result["output"][0]["asset"],
                result["output"][0]["address"]
                if not result["output"][0]["asset"] == "XMR"
                else "Your Monero Wallet",
            )
        )

    elif result["state"] == "COMPLETE":
        output = result["output"][0]
        if output["txid"] is None:
            print(
                "\033[01;32;40mYour transaction has been received and is confirmed. It will be sent shortly.\n"
            )
            print(
                "\033[00;37;40mMorphtoken \033[00;33;40mwill send \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m to: \033[01;36;40m{}\033[00;33;40m".format(
                    morph_format(
                        output["asset"],
                        output["converted_amount"] - output["network_fee"]["fee"],
                    ),
                    output["asset"],
                    output["address"]
                    if not output["asset"] == "XMR"
                    else "Your Monero Wallet",
                )
            )
        else:
            print(
                "\n\033[01;32;40mSuccess! \033[01;37;40m{}\033[00;33;40m \033[01;36;40m{}\033[00;33;40m has been sent anonymously \nto: \033[01;36;40m{}\033[00;33;40m\n\ntxid: \033[01;36;40m{}\033[00;33;40m".format(
                    morph_format(
                        output["asset"],
                        output["converted_amount"] - output["network_fee"]["fee"],
                    ),
                    output["asset"],
                    output["address"]
                    if not output["asset"] == "XMR"
                    else "Your Monero Wallet",
                    output["txid"],
                )
            )
    elif result["state"] in ["PROCESSING_REFUND", "COMPLETE_WITH_REFUND"]:
        print(
            "Morphtoken will refund {} {}\nReason: {}".format(
                result["final_amount"], result["asset"], result["reason"]
            )
        )
        if result.get("txid"):
            print("txid: {}".format(result["txid"]))
    elif result["state"] == "COMPLETE_WITHOUT_REFUND":
        print(
            "\033[01;31;40mDeposit amount below network fee, too small to refund.\033[00;33;40m"
        )

    elif result["state"] == "PENDING" and result["input"]["asset"] == "XMR":
        print(
            "\n\033[00;33;40mWaiting for \033[00;37;40mMorphToken \033[00;33;40mto receive your withdrawal.\n\033[01;36;40mOrder status will be updated as soon as the transaction is received. \n\n\033[01;31;40m(This may take some time, please wait.)"
        )
    print_bottom("~", "~", 0, 80)


# EXCHANGE HELPER FUNCTIONS:
def godex_get_extra_id(args):
    try:
        with open("extraid", "r") as f:
            extra_id = f.readline().strip()
    except:
        extra_id = ""
    return extra_id


def godex_get_extra_id_name(coin):
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
        return extraDict[coin]
    except:
        return None


def godex_check_extraID(coin):
    extra_id_name = godex_get_extra_id_name(coin)
    if extra_id_name is not None:
        print(
            "\n\033[00;37;40mThe {} address you entered may require a \033[01;36;40m{} {} \033[00;37;40mfor transaction processing.".format(
                coin, coin, extra_id_name
            )
        )
        with open("extraid_name", "w+") as f:
            f.write(extra_id_name)


def get_coins(args):
    popularList = [
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
        "REP",
    ]
    coinDict = {}

    try:
        result = requests.get(
            "https://api.godex.io/api/v1/coins", headers = make_header(0), timeout=10
        ).json()

        for coin in result:
            if coin["disabled"] == 0 and coin["code"] != "XMR":
                coinDict[coin["code"]] = coin["name"]
        tickerList = sorted(coinDict.keys())
    except:
        popularList = popularList[0:5]
        tickerList = popularList
        coinDict = {
            "BTC": "Bitcoin",
            "LTC": "Litecoin",
            "ETH": "Ethereum",
            "BCH": "Bitcoin Cash",
            "DASH": "Dash",
        }

    coins = ""
    tickers = ""
    for ticker in popularList:
        if args.out == "checklist":
            coins += "{} {} {} ".format(
                ticker, ticker, coinDict[ticker].replace(" ", "-").replace("---", "-")
            )
        else:
            coins += "{} {} ".format(
                ticker, coinDict[ticker].replace(" ", "-").replace("---", "-")
            )
            if args.out == "tickers":
                tickers += "{} ".format(ticker)
        tickerList.remove(ticker)
    for ticker in tickerList:
        if args.out == "checklist":
            coins += "{} {} {} ".format(
                ticker if ticker != "TRUE" else "TRUE_C", 
                ticker, coinDict[ticker].replace(" ", "-").replace("---", "-")
            )
        else:
            coins += "{} {} ".format(
                ticker, coinDict[ticker].replace(" ", "-").replace("---", "-")
            )
            if args.out == "tickers":
                tickers += "{} ".format(ticker)

    if args.out == "tickers":
        with open("tickers", "w+") as f:
            f.write(tickers)
    print(coins)


def morph_format(asset, amount):
    if asset == "ETH":
        amount /= 10 ** 18
    elif asset == "XMR":
        amount /= 10 ** 12
    else:
        amount /= 10 ** 8
    return "{:.8f}".format(amount)


def error_out(error_title, error_text):
    print("\n\033[01;31;40m" + error_title + "\n" + error_text)
    with open("error", "w+") as f:
        f.write("{}\n{}".format(error_title, error_text))
    exit(1)


def validation_error_out(error_type, error_str):
    print("\n\033[01;31;40m" + error_str)
    with open("validation_error", "w+") as f:
        f.write("{}".format(error_type))
    exit(1)


def validate_address_arg(args):
    reDict = {
        "XMR": "^(4|8)[1-9A-HJ-NP-Za-km-z]{94}([1-9A-HJ-NP-Za-km-z]{11})?$",
        "BTC": "^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$",
        "LTC": "^[LM3][a-km-zA-HJ-NP-Z1-9]{26,33}$",
        "ETH": "0x[a-fA-F0-9]{40}",
        "BCH": "[13][a-km-zA-HJ-NP-Z1-9]{33}",
        "DASH": "^X[1-9A-HJ-NP-Za-km-z]{33}$",
    }

    try:
        if not re.match(reDict[args.coin], args.address):
            validation_error_out(
                "invalid_address {} {}".format(args.type, args.coin),
                "The {} address you entered may not be a valid {} address.\n".format(
                    args.type, args.coin
                )
                + "Do you want to continue anyway?",
            )

        elif args.address.lower().startswith("bc1") and args.coin == "BTC":
            validation_error_out(
                "segwit_address {}".format(args.exchange),
                "The Morphtoken and XMR.to APIs do not support segwit addresses.\n"
                + "If you receive an error try again with a standard address instead.\n"
                + "Do you want to continue with segwit address anyway?",
            )

    except:
        godex_check_extraID(args.coin.upper())


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

        coin_out_fiat = float(priceDict[coin_out][fiat])
        coin_in_fiat = float(priceDict[coin_in][fiat])

        if self.exchange == "MorphToken":
            network_fee = float(morph_format(self.coin_out, network_fee))

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

    def get_self(self):
        return self


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
            if coin == "BTC" and is_withdrawal:
                x_num = 3
            else:
                x_num = 2
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
    exchange = option_dataList[0]
    coin_in = option_dataList[1]
    coin_out = option_dataList[2]
    priceDict = option_dataList[3]
    is_withdrawal = option_dataList[4]
    amount = option_dataList[5]
    fiat = option_dataList[6]

    try:
        revert = ""
        if amount[1] == coin_in:
            comp_amount = float(amount[0])
        elif amount[1] == coin_out:
            if exchange == "Godex.io":
                comp_amount = float(amount[0])
                revert = "-revert"
            else:
                comp_amount = (
                    float(amount[0]) * priceDict[coin_out][fiat]
                ) / priceDict[coin_in][fiat]
        else:
            comp_amount = float(amount[0]) / priceDict[coin_in][fiat]

        if exchange == "XMR.to":
            url = "https://xmr.to/api/v2/xmr2btc/order_parameter_query/"
            result = requests.get(url, headers = make_header(0)).json()

            minimum = float(result["lower_limit"])
            maximum = float(result["upper_limit"])
            rate = float(result["price"])
            network_fee = 0
        elif exchange == "MorphToken":
            url = "https://api.morphtoken.com/limits"
            json_data = {
                "input": {"asset": coin_in},
                "output": [{"asset": coin_out, "weight": 10000}],
            }

            result = requests.post(url, headers = make_header(0), json=json_data).json()
            minimum = float(result["input"]["limits"]["min"])
            maximum = float(result["input"]["limits"]["max"])
            rate = float(result["output"][0]["seen_rate"])
            network_fee = result["output"][0]["network_fee"]
        else:
            url = "https://api.godex.io/api/v1/info" + revert
            json_data = {"from": coin_in, "to": coin_out, "amount": comp_amount}
            result = requests.post(url, headers = make_header(0), json=json_data).json()
            minimum = float(result["min_amount"])
            maximum = float(result["max_amount"])
            rate = float(result["rate"])
            network_fee = float(result["fee"])

        if (
            rate != 0
        ):  # and comp_amount > minimum and (comp_amount < maximum or maximum == 0):
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
    except:
        print(
            "Failed to get {} to {} rates from {}, omitting from options list.".format(
                coin_in, coin_out, exchange
            )
        )


def make_price_urlList(coinsList, fiat):
    price_urlList = []
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
            fsyms += "{},".format(coinsList[int(len(coinsList) / syms_per_url) + r])
        price_urlList.append(
            "https://min-api.cryptocompare.com/data/pricemulti?fsyms={}&tsyms={}".format(
                fsyms, fiat
            )
        )
    return price_urlList


def get_priceDictList(price_url):
    partial_priceDict = requests.get(price_url, headers = make_header(0)).json()
    return partial_priceDict


def sync_priceDict(priceDictList):
    synced_priceDict = {}
    for partial_priceDict in priceDictList:
        synced_priceDict.update(partial_priceDict)
    return synced_priceDict


def get_amount(args):
    amount = args.amount

    if len(amount) < 2:
        char = str(amount[0])[0]
        last_num = 0
        while not char.isalpha() and last_num < len(amount[0]) - 1:
            last_num += 1
            char = str(amount[0])[last_num]

        if last_num < len(amount[0]) - 1:
            amount.append(amount[0][last_num : len(amount[0])])
            amount[0] = amount[0].replace(amount[1], "")
        else:
            amount.append("XMR")

    amount[0] = float(amount[0])
    amount[1] = amount[1].upper().strip()

    return amount


def calc_rates(args):
    optionsList = []
    loaded_urlList = []

    amount = get_amount(args)

    if args.fiat is None:
        fiat = "USD"
        fiat_symbol = "$"
    else:
        fiat = args.fiat
        fiat_symbol = args.symbol

    if args.compare is None:
        coinsList = ["BTC", "LTC", "ETH", "BCH", "DASH"]
    else:
        coinsList = args.compare

    if amount[1] in coinsList:
        coinsList = []
        coinsList.append(amount[1])

    elif "XMR" in coinsList:
        coinsList.remove("XMR")

    elif "TRUE_C" in coinsList:
        coinsList.remove("TRUE_C") 
        coinsList.append("TRUE")

    if args.type == "withdraw":
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
    while sortable != True:
        try:
            sortedList = sorted(optionsList, key=lambda option: option.fee)
            sortable = True
        except (ValueError, AttributeError) as e:
            optionsList.remove(e.__cause__)

    if len(sortedList) < 1:
        error_out(error_title, "Try again with a different amount and/or coin(s)")

    with open("options-list", "a") as f:
        for option in sortedList:
            f.write(option.zenity_data)
    if invert:
        value_spaces = (
            len(str(int(max(sortedList, key=lambda option: option.fiat_in).fiat_in)))
            - 1
        )
    else:
        value_spaces = (
            len(str(int(max(sortedList, key=lambda option: option.fiat_out).fiat_out)))
            - 1
        )
    rate_spaces = 9 - value_spaces

    if is_withdrawal:
        print_top(
            "Current options for withdrawing: {} {}".format(amount[0], amount[1]),
            "-",
            "|",
            0,
            80,
        )
        print_bottom("~", "|", 0, 80)
    else:
        print_top(
            "Current options for depositing: {} {}".format(amount[0], amount[1]),
            "-",
            "|",
            0,
            80,
        )
        print_bottom("~", "|", 0, 80)
    print(
        "\033[00;33;40m|\033[01;37;40mRank\033[00;33;40m| \033[01;37;40mCoin \033[00;33;40m| \033[01;37;40mExchange \033[00;33;40m|\033[01;37;40m{}\033[00;33;40m|{}\033[01;37;40mValue{}\033[00;33;40m|   \033[01;37;40mFee   \033[00;33;40m|{}\033[01;37;40mRate\033[00;33;40m{}|".format(
            " Amount You Send " if invert else " Amount You Get ",
            " " * value_spaces,
            " " * value_spaces,
            " " * rate_spaces,
            " " * (rate_spaces - 1) if invert else (" " * rate_spaces),
        )
    )
    print_bottom("~", "|", 0, 80)
    rank = 0
    for option in sortedList:
        rank += 1
        if invert:
            disp_amount = option.amount_in
            disp_coin = option.coin_in
            disp_value = option.fiat_in
            amount_f = 10 - len(str(int(option.amount_in)))
            rate_f = (
                2 * rate_spaces + -1 - len(option.coin_in) - len(option.coin_out)
            ) - len(str(int(option.rate)))
        else:
            disp_amount = option.amount_out
            disp_coin = option.coin_out
            disp_value = option.fiat_out
            amount_f = 9 - len(str(int(option.amount_out)))
            rate_f = (
                2 * rate_spaces - len(option.coin_in) - len(option.coin_out)
            ) - len(str(int(option.rate)))

        fee_f = 4
        if num_chars(option.fee, 0) > 3:
            fee_f -= 1
            if num_chars(option.fee, 0) > 4:
                amount_f -= num_chars(option.fee, 0) - 4
        disp_coin = disp_coin + " " * (4 - len(disp_coin))
        if len(disp_coin) > 4:
            amount_f -= 1
        if rate_f < 0:
            rate_f = 0
        print(
            "\033[00;33;40m|\033[01;37;40m{}\033[00;33;40m|\033[01;36;40m{}\033[00;33;40m|\033[01;37;40m{}\033[00;33;40m|\033[01;37;40m{}\033[01;36;40m{}\033[00;33;40m|\033[01;32;40m{}\033[00;33;40m|\033[01;37;40m{}\033[00;33;40m|\033[01;37;40m{}\033[01;36;40m{}\033[01;37;40m/\033[01;36;40m{}\033[00;33;40m|".format(
                str(rank).center((len("Rank") + 0), " "),
                option.coin_out.center((len("Coin") + 2), " ")
                if is_withdrawal
                else option.coin_in.center((len("Coin") + 2), " "),
                option.exchange.center((len("Exchange") + 2), " "),
                str(" {:.{}f} ".format(disp_amount, amount_f)),
                disp_coin,
                str("{}{:.2f}".format(fiat_symbol, disp_value)).center(
                    (len("Value") + (2 * value_spaces)), " "
                ),
                str("{:.{}f}%".format(option.fee, fee_f)).center((len("Fee") + 6), " "),
                str(" {:.{}f} ".format(option.rate, rate_f)),
                option.coin_out,
                option.coin_in,
            )
        )
    print_bottom("~", "|", 0, 80)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="torsocks python3 MoneroMixer.py")
    subparsers = parser.add_subparsers()

    parser_prices = subparsers.add_parser("prices")
    parser_prices.add_argument("--fiat", type=str)
    parser_prices.add_argument("--update", type=int)
    parser_prices.set_defaults(func=update_prices)

    parser_balance = subparsers.add_parser("balance")
    parser_balance.add_argument("--type", type=str)
    parser_balance.add_argument("--fiat", type=str)
    parser_balance.add_argument("--symbol", type=str)
    parser_balance.set_defaults(func=print_balance)

    parser_address = subparsers.add_parser("address")
    parser_address.set_defaults(func=print_address)

    parser_validate = subparsers.add_parser("validate")
    parser_validate.add_argument("--address", type=str)
    parser_validate.add_argument("--coin", type=str)
    parser_validate.add_argument("--exchange", type=str)
    parser_validate.add_argument("--type", type=str)
    parser_validate.set_defaults(func=validate_address_arg)

    parser_view = subparsers.add_parser("view")
    parser_view.add_argument("--exchange", type=str)
    parser_view.add_argument("--type", type=str)
    parser_view.add_argument("--id", type=str)
    parser_view.set_defaults(func=view)

    parser_viewQRCode = subparsers.add_parser("qrcode")
    parser_viewQRCode.add_argument("--address", type=str)
    parser_viewQRCode.set_defaults(func=view_qr)

    parser_coins = subparsers.add_parser("coins")
    parser_coins.add_argument("--out", type=str)
    parser_coins.add_argument("--tickers", type=str)
    parser_coins.set_defaults(func=get_coins)

    parser_calc = subparsers.add_parser("calc")
    parser_calc.add_argument("--type", type=str)
    parser_calc.add_argument("--compare", nargs="*")
    parser_calc.add_argument("--amount", nargs="*")
    parser_calc.add_argument("--fiat", type=str)
    parser_calc.add_argument("--symbol", type=str)
    parser_calc.set_defaults(func=calc_rates)

    parser_rates = subparsers.add_parser("rates")
    parser_rates.add_argument("--exchange", type=str)
    parser_rates.add_argument("--cin", type=str)
    parser_rates.add_argument("--out", type=str)
    parser_rates.add_argument("--amount", type=str)
    parser_rates.set_defaults(func=rates)

    parser_deposit = subparsers.add_parser("deposit")
    parser_deposit.add_argument("--exchange", type=str)
    parser_deposit.add_argument("--cin", type=str)
    parser_deposit.add_argument("--amount", nargs="*")
    parser_deposit.add_argument("--refund", type=str)
    parser_deposit.set_defaults(func=deposit)

    parser_withdraw = subparsers.add_parser("withdraw")
    parser_withdraw.add_argument("--exchange", type=str)
    parser_withdraw.add_argument("--out", type=str)
    parser_withdraw.add_argument("--amount", nargs="*")
    parser_withdraw.add_argument("--dest", type=str)
    parser_withdraw.add_argument("--refund", type=str)
    parser_withdraw.set_defaults(func=withdraw)

    parser_args = parser.parse_args()
    if argv[1:]:
        parser_args.func(parser_args)

    else:
        print("Error no args")
        exit(1)
