#!/usr/bin/perl

# This script is for squid version 3.1

$splash_response = "http://localhost/splash.html\n";

$|=1;
while (<>) {
    chomp;
    @line = split;
    $url = $line[0];
    if ($url =~ /^http:\/\/www\.apple\.com\/library\/test\/success\.html/) {

        print $splash_response;

    } elsif ($url =~ /^http:\/\/www\.apple\.com\/$/) {

        print $splash_response;

    } else {
        print $url . "\n";
    }
}
