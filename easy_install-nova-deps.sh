#!/bin/sh

set -ex

MOCK="$1"

$MOCK --chroot "rm -rf /eggs"
$MOCK --chroot "mkdir /eggs"
$MOCK --copyin /distfiles/python/pypi/* "/eggs"

# Nova dependencies
# OS-158: install patched version of eventlet-0.9.14 from packages.hg rather than eventlet==0.9.13
$MOCK --chroot "easy_install-2.6 -vvv -H None -f /eggs -z \
                amqplib==0.6.1 \
                argparse==1.1 \
                anyjson==0.2.5 \
                boto==1.9b \
                carrot==0.10.7 \
                Cheetah==2.4.2.1 \
                greenlet==0.3.1 \
                httplib2==0.6.0 \
                IPy==0.72 \
                lockfile==0.8 \
                Markdown==2.0.3 \
                M2Crypto==0.20.2 \
                MySQL-python==1.2.3 \
                netaddr==0.7.5 \
                paste==1.7.5.1 \
                prettytable==0.5 \
                python-daemon==1.5.5 \
                Routes==1.12.3 \
                sqlalchemy==0.6.5 \
                sqlalchemy_migrate==0.6 \
                suds==0.4 \
                twisted==10.2.0 \
                WebOb==0.9.8 \
                zope.interface==3.6.1
"
