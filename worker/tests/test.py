# -*- coding: utf-8 -*-

from __future__ import unicode_literals, print_function, absolute_import

import os
import sys
import time
import socket
import random
import subprocess
from os.path import dirname, join


devnull = open(os.devnull, 'w+')

class UnixSocket(object):
    """
    Un gestionnaire de contexte qui retourne une socket UNIX en écoute.

    La socket est automatiquement fermée à la sortie du contexte
    (y compris lorsqu'une exception est levée dans le code).
    """

    def __init__(self, sockpath, limit=1):
        self.sockpath = sockpath
        self.socket = None
        self.limit = limit

    def __enter__(self):
        try:
            os.unlink(self.sockpath)
        except Exception:
            pass

        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.socket.bind(self.sockpath)
        self.socket.listen(self.limit)
        return self.socket

    def __exit__(self, *args):
        self.socket.close()
        os.unlink(self.sockpath)


class NagiosWorker(object):
    """
    Un gestionnaire de contexte qui exécute le worker "vigilo-collector".

    Le worker est automatiquement arrêté (tué) en cas d'exception.
    """

    def __init__(self, sockpath):
        self.sockpath = sockpath
        self.proc = None

    def __enter__(self):
        collector = join(dirname(dirname(__file__)), 'vigilo-collector')
        args = {}
        # Désactive STDOUT/STDERR, sauf si le mode de débogage est activé.
        if not os.environ.get('VIGILO_DEBUG', 0):
            args['stdout'] = devnull
            args['stderr'] = devnull

        self.proc = subprocess.Popen(
            [collector, '--nagios', self.sockpath],
            close_fds=True,
            stdin=devnull,
            env={'VIGILO_TEST': '1'},
            **args
        )

    def __exit__(self, *args):
        self.proc.terminate()
        time.sleep(1)
        self.proc.kill()


def run_test(script, expected):
    """
    Exécute une sonde Nagios au travers du worker "vigilo-collector"
    et vérifie les résultats transmis au query handler de Nagios.
    """

    basedir = dirname(__file__)
    sockpath = join(basedir, 'nagios_qh.sock')

    with UnixSocket(sockpath) as sock:
        with NagiosWorker(sockpath) as collector:
            client, addr = sock.accept()
            try:
                data = client.recv(512)
                client.sendall('OK\0')

                jobid = random.randint(0, 65535)
                job = [
                    'job_id=%d',
                    'type=0',
                    'command=%s',
                    'timeout=30',
                ]
                client.sendall( "\0".join(job + ['\1\0\0\0']) %
                                (jobid, join(basedir, 'data', script)) )

                data = client.recv(512)
                variables = {"id": jobid}
                assert (data == (expected % variables)), (
                    "Failed test for script '%s'\n"
                    "received: %r\n"
                    "expected: %r"
                ) % (script, data, expected % variables)
            finally:
                client.close()


def main():
    """Point d'entrée des tests"""

    res = 0
    tests = [
        ('die.pl', [
            'job_id=%(id)d',
            'stop=0.000000',
            'wait_status=768',
            'outerr=I want to break free!',
            'runtime=0.000000',
            'outstd=',
            'exited_ok=1',
            'type=0',
            'start=0.000000',
        ]),
        ('OK.pl', [
            'job_id=%(id)d',
            'stop=0.000000',
            'wait_status=0',
            'outerr=',
            'runtime=0.000000',
            'outstd=OK',
            'exited_ok=1',
            'type=0',
            'start=0.000000',
        ]),
        ('WARNING.pl', [
            'job_id=%(id)d',
            'stop=0.000000',
            'wait_status=256',
            'outerr=',
            'runtime=0.000000',
            'outstd=WARNING',
            'exited_ok=1',
            'type=0',
            'start=0.000000',
        ]),
        ('CRITICAL.pl', [
            'job_id=%(id)d',
            'stop=0.000000',
            'wait_status=512',
            'outerr=',
            'runtime=0.000000',
            'outstd=CRITICAL',
            'exited_ok=1',
            'type=0',
            'start=0.000000',
        ]),
        ('UNKNOWN.pl', [
            'job_id=%(id)d',
            'stop=0.000000',
            'wait_status=768',
            'outerr=',
            'runtime=0.000000',
            'outstd=UNKNOWN',
            'exited_ok=1',
            'type=0',
            'start=0.000000',
        ]),
    ]

    for (script, expected) in tests:
        try:
            run_test(script, '\0'.join(expected + ['\1\0\0\0']))
        except AssertionError as e:
            if res:
                print("---")
            print(e)
            res = 1

    if not res:
        print("No failures detected")
    sys.exit(res)


if __name__ == '__main__':
    main()
