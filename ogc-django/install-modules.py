#!/usr/bin/env python3

import sys
import subprocess
import json
import os
from pathlib import Path

DJANGO_PATH = Path(os.environ['DJANGO_PATH'])

already_installed = set(p['name'].lower() for p in json.loads(subprocess.check_output(['pip', 'list', '--format=json'])))

with open('/app/django-modules.json', 'rb') as f:
    mods = json.load(f)

installed_apps = []
urlpatterns = []
for mod in mods:
    name = mod['module']

    path = mod.get('path')
    pkg = mod.get('pkg', name)

    if name in already_installed:
        print(f"{name} is already installed")
    else:
        if mod.get('git'):
            pip_module = f"{name}@git+{mod['git']}"
        else:
            pip_module = name

        print(f"Installing module {pip_module}")
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', pip_module])

    installed_apps.append(pkg)
    if path:
        urlpatterns.append(f"urlpatterns += [ url(r'^{path}/', include('{pkg}.urls')) ]")

with open('/app/urls-base.py', 'r') as inputfile:
    with open(DJANGO_PATH / 'urls.py', 'w') as outputfile:
        outputfile.write('from django.conf.urls import include, url\n')
        for line in inputfile:
            outputfile.write(line)
        if installed_apps:
            outputfile.write('\n\n')
            for urlpattern in urlpatterns:
                outputfile.write(urlpattern)
                outputfile.write('\n')

with open('/app/settings-base.py', 'r') as inputfile:
    with open(DJANGO_PATH / 'settings.py', 'w') as outputfile:
        for line in inputfile:
            outputfile.write(line)
        if installed_apps:
            outputfile.write('\n\n')
            outputfile.write("INSTALLED_APPS += [\n  ")
            outputfile.write(',\n  '.join(f"'{app}'" for app in installed_apps))
            outputfile.write(',\n]\n')

if installed_apps:
    Path('/app/installed-modules').touch()