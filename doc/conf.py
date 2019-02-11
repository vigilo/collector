# -*- coding: utf-8 -*-
# Copyright (C) 2012-2019 CS-SI
# License: GNU GPL v2 <http://www.gnu.org/licenses/gpl-2.0.html>

name = 'collector'
project = u'Collector'

pdf_documents = [
    ('dev', "dev-%s" % name, u"%s : Manuel développeur" % project, u'Vigilo'),
]

latex_documents = [
    ('dev', 'dev-%s.tex' % name, u"%s : Manuel développeur" % project,
     'AA100004-2/DEV00003', 'vigilo'),
]

execfile("../buildenv/doc/conf.py")
