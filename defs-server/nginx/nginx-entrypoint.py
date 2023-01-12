#!/usr/bin/env python3

import os
import json
import re
import sys
import subprocess
from pathlib import Path


CONF_VARIABLE_NAME = 'DOCKER_PROXY'
TEMPLATE_PATH = Path('/nginx/nginx.conf.tpl')
OUTPUT_PATH = Path('/etc/nginx/nginx.conf')
LOCATIONS_MARKER = '##LOCATIONS_MARKER##'
DEFAULT_CMD = ['nginx', '-g', 'daemon off;']

if not OUTPUT_PATH.parent.exists():
    # Install nginx
    subprocess.check_call(['apk', 'update'])
    subprocess.check_call(['apk', 'add', 'nginx'])

config = json.loads(os.environ[CONF_VARIABLE_NAME])

if not isinstance(config, list):
    raise ValueError("{} variable is not JSON list".format(CONF_VARIABLE_NAME))

map_block = f"""
    map $http_x_real_ip $x_real_ip {{
        default $remote_addr;
        "~.+"   $http_x_real_ip;
    }}
    
    map $http_x_forwarded_proto $x_forwarded_proto {{
        default $scheme;
        "~.+"   $http_x_forwarded_proto;
    }}
"""
location_blocks = ''
for entry in config:

    repo = entry.get('repo')
    if repo:
        location_blocks += f"""
            location {entry['location']} {{
                alias /var/repos/{repo};
            }}
        """
    else:
        port = entry.get('port', 80)
        headers = '\n'.join(f'proxy_set_header {header_name} "{header_value}";'
                            for header_name, header_value in entry.get('headers', {}).items())

        location_blocks += f"""
            location {entry['location']} {{
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $x_real_ip;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $x_forwarded_proto;
                {headers}
                proxy_pass http://{entry['service']}:{port}{entry.get('upstreamLocation', entry['location'])};
              }}
        """

map_added = False
with open(TEMPLATE_PATH, 'r') as inf:
    with open(OUTPUT_PATH, 'w') as outf:
        for line in inf:
            if not map_added and re.match(r'\bhttp\s*\{', line):
                line = re.sub(r'(\bhttp\s*\{)', '\\1\n' + map_block, line)
            outf.write(line.replace(LOCATIONS_MARKER, location_blocks))

cmd = sys.argv[1:] if len(sys.argv) > 1 else DEFAULT_CMD
os.execvp(cmd[0], cmd)