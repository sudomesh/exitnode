#!/usr/bin/env python2.7

import socket
from os import path

apple_host = "www.apple.com"
android_host = "clients3.google.com"
win_host = "www.msftncsi.com"

apple_ip = socket.gethostbyname(apple_host)
android_ip = socket.gethostbyname(android_host)
win_ip = socket.gethostbyname(win_host)

ip_list = [line.strip() for line in open('/etc/squid3/hosts')]

if not (apple_ip in ip_list) or not (win_ip in ip_list) or not (android_ip in ip_list):
  f = open('/etc/squid3/hosts', 'w')
  f.write(socket.gethostbyname(apple_host) + '\n')
  f.write(socket.gethostbyname(android_host) + '\n')
  f.write(socket.gethostbyname(win_host) + '\n')
  f.close()

