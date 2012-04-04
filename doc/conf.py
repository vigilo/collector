# -*- coding: utf-8 -*-

name = 'collector'
project = u'Collector'

pdf_documents = [
    ('dev', "dev-%s" % name, u"%s : Manuel développeur" % project, u'Vigilo'),
]

latex_documents = [
    ('dev', 'dev-%s.tex' % name, u"%s : Manuel utilisateur" % project,
     'AA100004-2/DEV00003', 'vigilo'),
]

execfile("../buildenv/doc/conf.py")
