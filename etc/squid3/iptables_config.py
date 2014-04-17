import netfilter.rule
import netfilter.table
import sys

CLEAR = False

if len(sys.argv) > 1:
    if(sys.argv[1] == '-d'):
        CLEAR = True

def main():

    if (CLEAR):
        clear_rules()
    else:
        add_rules()

def add_rules():
    clear_rules()

    ip_list = [line.strip() for line in open('/etc/squid3/hosts')]
    port = '3128'

    jump = netfilter.rule.Target('REDIRECT', '--to-port %s' % (port))
    nat = netfilter.table.Table('nat')

    for ip in ip_list:

        rule = netfilter.rule.Rule(in_interface='bat0', protocol='tcp', destination=ip, matches=[netfilter.rule.Match('tcp', '--dport 80')], jump=jump)
        nat.append_rule('PREROUTING', rule)

def clear_rules():
    nat = netfilter.table.Table('nat')
    for rule in nat.list_rules('PREROUTING'):
        if rule.in_interface == "bat0":
            nat.delete_rule('PREROUTING', rule)

if __name__ == '__main__':
    main()
