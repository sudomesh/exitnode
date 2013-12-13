#!/usr/bin/env python2.7

import socket

apple_host = "www.apple.com"
android_host = "clients3.google.com"

apple_ip = socket.gethostbyname(apple_host)
android_ip = socket.gethostbyname(android_host)

ip_list = [line.strip() for line in open('hosts')]

if not (apple_ip in ip_list) or not (android_ip in ip_list):
  f = open('hosts', 'w')
  f.write(socket.gethostbyname(apple_host) + '\n')
  f.write(socket.gethostbyname(android_host) + '\n')
  f.close()

