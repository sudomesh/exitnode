#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import psycopg2
import re
import sys
from datetime import datetime, timedelta

DEBUG = False
success_redirect = "http://peoplesopen.net"

expiration = 24 # expiration in hours (you see the splash page again after this many hours)
splash_url = "http://127.0.0.1/splash.html"
splash_click_regex = "splash_click\.html"

url_regex = re.compile(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+')

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
    def __init__(self, name, probe_regexes):
        self.name = name
        self.probe_regexes = probe_regexes


probes = [Probe("apple", ["apple.com", "/library/test/success\.html", "captive.apple.com", "www.ibook.info", "www.itools.info", "www.airport.us", "www.thinkdifferent.us", "www.appleiphonecell.com"]),
          Probe("android", ["74.125.239.8", "generate_204"])];

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

    try:
        rinput = raw_input()
        debug("Input = " + rinput)
        d = rinput.split(' ')
        
        url = d[0]
        if(len(d) < 2):
            print url # passthrough
            continue

        url_match = re.findall(url_regex, d[0])

        if (len(url_match) == 0):
            print url
            continue

        url = url_match[0]

        ip_match = re.match('[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+', d[1])

        try:
            ip = ip_match.group(0)
        except AttributeError: # in case no ip is recognized
            print url
            continue

        debug("ip = " + ip)
        debug("url = " + url)

        if(re.search(splash_click_regex, url)):

            debug(" splash page clicked by: " + ip)

            register_click(ip);
            print success_redirect
            redirecting = True

        if not redirecting:

            for probe in probes:

                for regex in probe.probe_regexes:

                    if(re.search(regex, url) and not redirecting):

                        debug(probe.name + "probe for " + regex + " from: " + ip)

                        if(did_user_already_click(ip)):

                            debug("user already clicked through. letting probe pass.")
                            debug("redirecting to:")
                            debug(url)

                        else:

                            debug("blocking probe")
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
