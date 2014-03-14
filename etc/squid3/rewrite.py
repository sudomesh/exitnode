#!/usr/bin/env python2.7

import psycopg2
import re
import sys
from datetime import datetime, timedelta

DEBUG = False
success_redirect = "http://peoplesopen.net"

expiration = 24 # expiration in hours (you see the splash page again after this many hours)
splash_url = "http://127.0.0.1/splash.html"
splash_click_regex = "splash_click\.html"

probe_regex_apple = "apple\.com/library/test/success\.html"
splash_regex_apple = "apple.com"
#splash_regex_apple = "^http://www\.apple\.com(/?)"

probe_regex_android = "generate_204"
splash_regex_android = "74.125.224.142"

conn = psycopg2.connect(host="localhost", database="captive", user="captive", password="?fakingthecaptive?")
cur = conn.cursor()

#clicked = False # TODO remove


log_file = open("/var/log/squid3/message.log","a")



def debug(s):

    if(DEBUG):
        print("DEBUG: " + s + "\n")
    else:
        log_file.write("DEBUG: " + s + "\n")
        log_file.flush()


if len(sys.argv) > 1:
    if(sys.argv[1] == '-d'):
        DEBUG = True
        debug("Enabled debug output.")


def did_user_already_click(ip):

    debug("Trying sql query: ")
    debug("SELECT ipv4, created FROM pass WHERE ipv4 = '"+ip+"';")
    cur.execute("SELECT ipv4, created FROM pass WHERE ipv4 = '"+ip+"';")
    row = cur.fetchone()
    clicked = False

    if(row):
        debug(str(row))
        debug(str(row[1]))
        timestamp = row[1]
        debug(str(datetime.now()))
        debug(str(timestamp))
        if (datetime.now() - timestamp) < timedelta (hours = 24):
            clicked = True
        else:
            clicked = False
    else:
        clicked = False

    return clicked

def register_click(ip):

    cur.execute("INSERT INTO pass (ipv4) VALUES (%s)", [ip])
    conn.commit()
    debug("Inserted ip: " + ip)

debug("\n".join(sys.argv))

while(True):

    debug("loop once")

    try:
        rinput = raw_input()
        debug("Input = " + rinput)
        d = rinput.split(' ')
        url = d[0]

        if(len(d) < 2):
            print url # passthrough
            continue

        ip = d[1]
        #ip = string.replace(ip, '-', '')
        #ip = string.replace(ip, '/', '')


        debug("ip = " + ip)
        debug("url = " + url)

        if(re.search(splash_click_regex, url)):

            debug("splash page clicked by: " + ip)

            register_click(ip);


        if(re.search(probe_regex_apple, url)):

            debug("apple probe from: " + ip)

            if(did_user_already_click(ip)):

                debug("user already clicked through. letting probe pass.")

                print url

            else:

                debug("blocking probe")
                debug("printing: " + splash_url)

                print splash_url


        elif(re.search(probe_regex_android, url)):

            debug("android probe from: " + ip)

            if(did_user_already_click(ip)):

                debug("user already clicked through. letting probe pass.")

                print url

            else:

                debug("blocking probe")

                debug("printing: " + splash_url)
                print splash_url


        elif(re.search(splash_regex_apple, url)):

            debug("apple splash page fetch from: " + ip)
            debug("user already clicked?")

            if(did_user_already_click(ip)):

                debug("user already clicked through. not showing splash page")
                debug("redirecting to:")
                debug(success_redirect)

                print success_redirect

            else:

                debug("showing splash page")

                debug("printing: " + splash_url)
                print splash_url


        elif(re.search(splash_regex_android, url)):

            debug("android splash page fetch from: " + ip)

            if(did_user_already_click(ip)):

                debug("user already clicked through. not showing splash page")

                print success_redirect

            else:

                debug("showing splash page")

                debug("printing: " + splash_url)
                print splash_url

        else:

            print url
            debug("should've printed the url")

    except EOFError:
        debug("End of File")
        break
    except Exception:
        debug("Unexpected error:")
        debug(str(sys.exc_info()[0]))

conn.close()

log_file.close()
