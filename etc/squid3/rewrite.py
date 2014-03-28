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

conn = psycopg2.connect(host="localhost", database="captive", user="captive", password="?fakingthecaptive?")
cur = conn.cursor()

log_file = open("/var/log/squid3/message.log","a")

android_ip="clients3.google.com"

# Annoying step of having to specifically look up the android ip address
with open("/etc/dnsmasq.conf") as search:
    for line in search:
        if "clients3.google.com" in line:
            print "google in line"
            match = re.search('[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+', line)
            if match:
                print "match"
                android_ip = match.group(0)


class Probe:
    def __init__(self, name, splash_regex, probe_regex):
        self.name = name
        self.splash_regex = splash_regex
        self.probe_regex = probe_regex


probes = [Probe("apple", "apple.com", "/library/test/success\.html"),
          Probe("android", "74.125.239.8", "generate_204")];

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
        timestamp = row[1]
        if (datetime.now() - timestamp) < timedelta (hours = 24):
            clicked = True
        else:
            clicked = False
    else:
        clicked = False

    debug("clicked = " + str(clicked))

    return clicked

def register_click(ip):

    cur.execute("INSERT INTO pass (ipv4) VALUES (%s)", [ip])
    conn.commit()
    debug("Inserted ip: " + ip)

debug("\n".join(sys.argv))
debug("android_ip = " + android_ip)

while(True):

    debug("loop once")
    redirecting = False
    this_is_a_click = False

    try:
        rinput = raw_input()
        debug("Input = " + rinput)
        d = rinput.split(' ')
        url = d[0]

        if(len(d) < 2):
            print url # passthrough
            continue

        ip = d[1]

        debug("ip = " + ip)
        debug("url = " + url)

        if(re.search(splash_click_regex, url)):

            debug(" splash page clicked by: " + ip)

            register_click(ip);
            this_is_a_click = True

        for probe in probes:
            if(re.search(probe.probe_regex, url)):

                debug(probe.name + "probe from: " + ip)

                if(did_user_already_click(ip)):

                    debug("user already clicked through. letting probe pass.")
                    debug("redirecting to:")
                    if this_is_a_click:
                        print success_redirect
                        redirecting = True
                    else:
                        print url

                else:

                    debug("blocking probe")
                    debug("printing: " + splash_url)
                    redirecting = True
                    print splash_url

            elif(re.search(probe.splash_regex, url)):

                debug(probe.name + " splash page fetch from: " + ip)
                debug("user already clicked?")

                if(did_user_already_click(ip)):

                    debug("user already clicked through. not showing splash page")
                    debug("redirecting to:")
                    if this_is_a_click:
                        print success_redirect
                        redirecting = True
                    else:
                        print url

                else:

                    debug("showing splash page")
                    debug("printing: " + splash_url)
                    redirecting = True
                    print splash_url

        if not redirecting:
            print url

    except EOFError:
        debug("End of File")
        break
    except Exception:
        debug("Unexpected error:")
        debug(str(sys.exc_info()[0]))

conn.close()

log_file.close()
