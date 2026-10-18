#!/usr/bin/env python3
"""New optional teaching stimulus; NOT the original Python sender or a PEX exchange.
Run only on an isolated lab network. It never executes/acknowledges/fills orders.
"""
import argparse
import socket
import struct
import time

def quote(venue, seq, bid, ask, bid_size, ask_size):
    return struct.pack('!BBIIIIII', 1, venue, seq, 1, bid, ask, bid_size, ask_size)

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bind', required=True, help='IPv4 address of your WIRED adapter')
    p.add_argument('--broadcast', required=True, help='Lab subnet broadcast, e.g. 192.168.1.255')
    p.add_argument('--cycles', type=int, default=10)
    p.add_argument('--interval', type=float, default=0.05, help='Seconds between packets; >=0.01')
    p.add_argument('--allow-lab-broadcast', action='store_true')
    a = p.parse_args()
    if not a.allow_lab_broadcast: p.error('Explicit --allow-lab-broadcast is required')
    if not (1 <= a.cycles <= 1000) or a.interval < 0.01: p.error('Use 1..1000 cycles and interval >=0.01')
    socket.inet_aton(a.bind); socket.inet_aton(a.broadcast)
    # Prices in integer cents; symbol 1 is the legacy teaching namespace.
    scenarios = [
        ('PEX1 baseline', 1, 30000,30002,500,600),
        ('PEX2 baseline', 2, 29998,30005,400,500),
        ('BID cross', 2, 30006,30007,400,500),
        ('uncross', 2, 29998,30005,400,500),
        ('ASK cross', 2, 29995,29996,400,500),
        ('uncross', 2, 29998,30005,400,500),
        ('price cross but size 1: speculative abort', 2,30006,30007,1,500),
        ('uncross', 2,29998,30005,400,500),
    ]
    seq = 0
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        s.bind((a.bind,0))
        for _ in range(a.cycles):
            for label,v,bid,ask,bq,aq in scenarios:
                seq += 1
                s.sendto(quote(v,seq,bid,ask,bq,aq),(a.broadcast,5001))
                print(f'{seq}: {label}', flush=True)
                time.sleep(a.interval)
if __name__ == '__main__':
    try: main()
    except KeyboardInterrupt: pass
    except (OSError, ValueError) as e: raise SystemExit(f'Lab stimulus failed: {e}')
