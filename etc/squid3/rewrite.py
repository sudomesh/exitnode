#!/usr/bin/env python2.7

import psycopg2
import re
import sys

DEBUG = False

expiration = 24 # expiration in hours (you see the splash page again after this many hours)
splash_url = "http://127.0.0.1/splash.html"
splash_click_regex = "^http://click.splash.*"

probe_regex_apple = "^http://www\.apple\.com/library/test/success\.html.*"
splash_regex_apple = "^http://www.apple.com(/?)"

probe_regex_android = "^http://clients3\.google\.com/generate_204\.html.*"
splash_regex_android = "^http://clients3.google.com(/?)"

conn = psycopg2.connect(host="127.0.0.1", database="captive", user="captive", password="?fakingthecaptive?")
cur = conn.cursor()

#clicked = False # TODO remove

def debug(s):

    if(DEBUG):
        print "DEBUG: " + s

if len(sys.argv) > 1:
    if(sys.argv[1] == '-d'):
        DEBUG = True
        debug("Enabled debug output.")


def did_user_already_click(ip):

    cur.execute("SELECT ipv4, created FROM pass WHERE ipv4 = '"+ip+"';")
    row = cur.fetchone()

    if(row):
        # TODO check expiration time
        return True
    else:
        return False

    return clicked

def register_click(ip):

    cur.execute("INSERT INTO pass (ipv4) VALUES (%s)", [ip])
    conn.commit()
    debug("Inserted ip: " + ip)


while(True):
    d = raw_input().split(' ')
    url = d[0]

    if(len(d) < 2):
        print url # passthrough
        continue

    ip = d[1]

    if(re.match(probe_regex_apple, url)):

        debug("apple probe from: " + ip)

        if(did_user_already_click(ip)):

            debug("user already clicked through. letting probe pass.")

            print url

        else:

            debug("blocking probe")

            print splash_url

    elif(re.match(probe_regex_android, url)):

        debug("android probe from: " + ip)

        if(did_user_already_click(ip)):

            debug("user already clicked through. letting probe pass.")

            print url

        else:

            debug("blocking probe")

            print splash_url


    elif(re.match(splash_regex_apple, url)):

        debug("apple splash page fetch from: " + ip)

        if(did_user_already_click(ip)):

            debug("user already clicked through. not showing splash page")

            print url

        else:

            debug("showing splash page")

            print splash_url

    elif(re.match(splash_regex_android, url)):

        debug("android splash page fetch from: " + ip)

        if(did_user_already_click(ip)):

            debug("user already clicked through. not showing splash page")

            print url

        else:

            debug("showing splash page")

            print splash_url

    elif(re.match(splash_click_regex, url)):

        debug("splash page clicked by: " + ip)

        register_click(ip);

        print splash_url

    else:

        print url

conn.close()


