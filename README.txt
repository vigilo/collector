Collector
=========

Collector est un plugin Nagios dédié au SNMP. Son objectif est de collecter en
un minimum de requêtes la totalité des informations attendues, et de les
redistribuer aux services Nagios appropriés.

Il gère aussi l'envoi de données de métrologie sur le bus.

Pour les détails du fonctionnement du Collector, se reporter à la
`documentation officielle`_.

Collector est un composant de Vigilo_.


Installation
------------
L'installation se fait par la commande ``make`` (exécutée en utilisateur
standard) suivie de la commande ``make install`` (exécutée en ``root``).


Options
-------
Il y a deux options à la ligne de commande :

-C  le chemin vers le fichier de configuration général (par défaut
     ``/etc/vigilo/collector/general.conf``)
-H  le nom de machine ou l'adresse IP à tester

Le fichier ``general.conf`` contient des paramètres supplémentaires, tels que
le chemin vers les fichiers de configuration spécifiques à chaque hôte. Ces
fichiers sont censés être générés par VigiConf, mais un exemple est fourni
dans le fichier ``host.example`` (pour information).

Voir la documentation interne du Collector pour plus d'informations::

    make man ; man ./Collector.1


License
-------
Collector est sous licence `GPL v2`_.


.. _documentation officielle: Vigilo_
.. _Vigilo: http://www.projet-vigilo.org
.. _GPL v2: http://www.gnu.org/licenses/gpl-2.0.html

.. vim: set syntax=rst :
