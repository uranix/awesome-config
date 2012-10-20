#!/usr/bin/env python
# Based on wrapper.py

import sys
import json
import socket

bat_color = {
    'BAT' : '#ff0000',
    'CHR' : '#ffff00',
    'FUL' : '#ffffff',
    'NCH' : '#ffffff',
}

def query_icedove():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('localhost', 3411))
        reply = s.recv(8192)
        s.close()
        obj = json.loads(reply)
        cnt = 0;
        for accoutns in obj:
            cnt = cnt + accoutns['unread']
        if cnt == 0:
            return ['Mail: 0', '#ffffff']
        else:
            return ['Mail: %d' % cnt, '#ffff00']
    except Exception as e:
        return ['Mailer offline', '#ff0000']

def print_line(msg):
    sys.stdout.write(msg + '\n')
    sys.stdout.flush()

def read_line():
    try:
        line = sys.stdin.readline().strip();
        if not line:
            sys.exit(3);
        return line
    except KeyboardInterrupt:
        sys.exit()

if __name__ == '__main__':
    # {"version" : 1}
    print_line(read_line())
    # [
    print_line(read_line())

    while True:
        line, prefix = read_line(), ''
        if line.startswith(','):
            line, prefix = line[1:], ','

        j = json.loads(line)
        mail = query_icedove()
        j.insert(0, {'full_text' : mail[0], 'color' : mail[1], 'name' : 'icedove'})

        for x in j:
            # strip trailing spaces
            if x['full_text'][-1:] == ' ':
                x['full_text'] = x['full_text'][:-1]
            # colorize battery output if charging/recharging
            if x['name'] == 'battery':
                sig = x['full_text'][0:3]
                x['color'] = bat_color[sig]
            # colorize load avereage
            if x['name'] == 'load':
                la = float(x['full_text'].split()[-1])
                if la > 1:
                    x['color'] = '#ffff00'
                if la > 2:
                    x['color'] = '#ff0000'
            # colorize cpu_usage
            if x['name'] == 'cpu_usage':
                usage = int(x['full_text'].split()[-1][:-1])
                if usage > 10:
                    x['color'] = '#ffff00'
                if usage > 80:
                    x['color'] = '#ff0000'
            # colorize volume
            if x['name'] == 'volume':
                percent = x['full_text'].split()[-1]
                if percent[0] == 'M':
                    x['color'] = '#ff0000'
                    x['full_text'] = x['full_text'].replace(percent, percent[1:])

        print_line(prefix + json.dumps(j))
