******************
Manuel développeur
******************


Organisation générale du Collector
==================================
Le collecteur de Vigilo regroupe plusieurs bibliothèques de fonctions destinées
à faciliter la manipulation des données issues d'une collecte SNMP.
Le collecteur est organisé en plusieurs parties :

-   Des fichiers de configuration auto-générés, déployés par VigiConf et qui
    se trouvent dans des fichiers de la forme :
    :file:`/etc/vigilo/vigiconf/prod/collector/{nom_machine}.pm`

-   Le fichier :file:`Collector.pl.in` qui correspond à l'interface utilisateur
    et qui est donc le point d'entrée du collecteur.
    Ce fichier est un modèle : plusieurs variables sont substituées au moment
    de l'installation (par exemple, les chemins d'accès vers différents
    fichiers/dossiers du système) afin de coller à l'environnement d'exécution.
    Le résultat de ces substitutions est utilisé pour créer le fichier
    :file:`/usr/{lib64}/nagios/plugins/Collector` final installé sur la machine.

-   Le fichier :file:`base.pm` est un module Perl regroupant des fonctions
    basiques de conversion et/ou de vérification des données.

-   Les fichiers :file:`metro.pm` et :file:`sup.pm` sont des modules Perl
    qui contiennent des fonctions de haut niveau destinées à faciliter
    la manipulation des données relatives à la métrologie et au calcul
    des états Nagios.

-   Des modules d'extension écrits en Perl et permettant d'ajouter des fonctions
    de supervision ou de métrologie pour des équipements spécifiques.

Le reste de ce document s'applique à détailler le contenu de ces différents
fichiers, en particulier le contenu des 3 modules (:file:`base.pm`,
:file:`metro.pm`, :file:`sup.pm`).

Le chapitre :ref:`ajout_fonctions` détaille la procédure permettant d'ajouter
de nouvelles fonctions au collecteur. Il tente également d'apporter de bonnes
pratiques concernant l'extension des fonctionnalités du collecteur.

..  _`base.pm`:

Fonctions basiques de conversion/vérification
=============================================
Cette section recense les différentes fonctions de calcul/vérification
mises à disposition dans le fichier :file:`base.pm`.

.. _`checkOIDVal`:

``checkOIDVal``
---------------
Vérifie que la valeur retournée par un SNMP GET ou WALK semble correcte.

Arguments :

*   valeur retournée par un SNMP GET ou SNMP WALK à tester

Valeur de retour :

*   1 si la valeur passée est correcte
*   0 si la valeur passée est incorrecte

..  _`date2Time`:

``date2Time``
-------------
Convertit une date sous forme de texte en un nombre de secondes.

Arguments :

*   date (texte)

Valeur de retour :

Nombre de secondes (entier) qui séparent la date donnée du 1er Janvier 1970
à minuit.

..  _`genericHW`:

``genericHW``
-------------
Lit un sous-arbre à partir d'un OID d'état, et si au moins une des valeurs
ne correspond pas à la « valeur OK », retourne l'état *critical* avec
le message désiré et le contenu de l'OID de description.

..  _`genericIfOperStatus`:

``genericIfOperStatus``
-----------------------
Teste l'état d'une interface.
Si elle est indisponible, l'état retourné est CRITICAL.
Si elle a été configurée manuellement par un administrateur réseau
pour apparaître dans un état « indisponible », alors l'état retourné
est déterminé par la variable alerte_état_d'admin :

* « i » (ignore) pour OK
* « w » pour WARNING
* « c » pour CRITICAL

Si l'interface se trouve dans un état « dormant », l'état retourné
est déterminé par la variable alerte_état_dormant, en utilisant la même
codification que pour l'état précédent.

Dans le message retourné, l'alias et l'index de l'interface sont utilisés
pour comme identifiants de l'interface.

..  _`isOutOfBounds`:

``isOutOfBounds``
-----------------
Compare une valeur à un plage définie grâce au format de seuils de Nagios.
Voir http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT
pour plus d'information concernant le format.

Arguments :

*   valeur à tester
*   définition d'une plage de valeurs au format Nagios

Valeur de retour :

*   1 si la valeur est comprise dans la plage de valeurs
*   0 si la valeur est hors de la plage

..  _`lookup`:

``lookup``
----------
Cherche un motif dans un sous-arbre d'OIDs SNMP d'un sous-niveau maximum
et retourne l'index de la première correspondance trouvée.

..  _`lookupMultiple`:

``lookupMultiple``
------------------
Fonctionne comme la fonction :ref:`lookup`, mais retourne la liste des indexes
de toutes les correspondances trouvées.

..  _`lookupText`:

``lookupText``
--------------
Convertit un motif textuel en sa valeur numérique, puis cherche
dans un sous-arbre d'OIDs d'un niveau maximum un OID qui commencerait
par la base de recherche et qui se terminerait par le motif convertit.
Retourne ensuite la portion d'OID contenue entre ces deux valeurs.

..  _`resultMap`:

``resultMap``
-------------
Teste une valeur selon une liste de correspondances valeur / état / message :
si la valeur correspond à une entrée « valeur » de la liste, alors l'état
et le message correspondants sont retournés. Si la valeur n'est pas trouvée,
on retourne l'état et le message « de secours ».

..  _`thresholdIt`:

``thresholdIt``
---------------
Vérifie l'état d'une valeur par rapport aux seuils *warning* et *critical*,
en utilisant la fonction :ref:`isOutOfBounds`.

Fonctions de haut niveau
========================

..  _`metro.pm`:

Fonctions relatives à la métrologie
-----------------------------------
Le module :file:`metro.pm` contient les différentes fonctions de conversion
destinées à faciliter les opérations de traitement relatives à la métrologie.
Chacune de ces fonctions reçoit en arguments un certain nombre de paramètres
(``$parameters``), des variables (``$variables``), le contenu de la réponse
à l'interrogation SNMP (``$response``), un drapeau indiquant si le mode de
débogage est actif ou non (``$debug``) et une référence aux fonctions basiques
de conversion/vérification (``$Primitive`` – voir la section :ref:`base.pm`
pour plus d'information).

Toutes les fonctions de ce module retournent un tuple de valeurs de la forme
``(état, message)`` où ``état`` correspond à l'état Nagios sous forme textuelle
(``OK``, ``WARNING``, ``CRITICAL`` ou ``UNKNOWN``) et ``message`` correspond
au message de supervision qui apparaîtra dans Nagios/Vigilo (par exemple,
``OK: The system was last rebooted 42 days ago``).

Ce module est nécessaire pour les services dont l'état de supervision est peu
pertinent, mais pour lesquels le suivi des performances est important.
Par exemple, il est peu intéressant d'utiliser des seuils sur l'utilisation
instantanée du processeur d'une machine car un pic de charge au moment de
l'exécution du Collector n'indique pas nécessairement un problème.
À l'inverse, il est intéressant de pouvoir suivre l'évolution de la charge
du processeur dans le temps afin de diagnostiquer correctement un problème
(par exemple, un processus effectuant un traitement long et consommateur
en ressources en arrière-plan).

De ce fait, les fonctions du module :file:`metro.pm` renvoient systématiquement
un état ``OK`` (état nominal) dès lors que le service en question est
effectivement présent sur l'équipement supervisé ou ``UNKNOWN`` (état inconnu)
s'il n'est pas possible d'interroger le service.

Les autres états de Nagios (``WARNING``, ``CRITICAL``) ne sont pas utilisés
pour les services pour lesquels on ne récupère que des informations de
métrologie.

Le reste de cette section décrit les différentes fonctions proposées
par ce module.

..  _`directValue`:

``directValue``
^^^^^^^^^^^^^^^
Retourne la valeur, sans aucune modification.

..  only:: enterprise

    ..  _`m_ciscoQOS`:

    ``m_ciscoQOS``
    ^^^^^^^^^^^^^^
    Retourne le débit sur une interface réseau selon un classe de service
    et une direction (flux entrant ou flux sortant).

..  _`m_mult`:

``m_mult``
^^^^^^^^^^
Retourne le produit de deux valeurs.

..  _`m_rpn`:

``m_rpn``
^^^^^^^^^

Effectue un calcul portant sur plusieurs variables à l'aide d'une formule
donnée en Notation Polonaise Inverse (:abbr:`RPN (Reversed Polish Notation)`).

Voir http://fr.wikipedia.org/wiki/Notation_polonaise_inverse pour plus
d'information sur la notation utilisée.

..  _`m_sysUpTime`:

``m_sysUpTime``
^^^^^^^^^^^^^^^
Retourne l'*uptime* (durée de disponibilité) converti en secondes grâce
à la fonction :ref:`date2Time`.

..  _`m_table`:

``m_table``
^^^^^^^^^^^
Cherche le nom dans l'OID de description, récupère l'index,
puis utilise cet index pour retourner la valeur de l'OID valeur.

..  _`m_table_add`:

``m_table_add``
^^^^^^^^^^^^^^^
Cherche les noms dans l'OID de description grâce à la fonction de base
:ref:`lookupMultiple`, récupère les indexes et utilise ces indexes
pour additionner les valeurs correspondantes dans l'OID valeur
avant de retourner le résultat de cette addition.

..  _`m_table_mult`:

``m_table_mult``
^^^^^^^^^^^^^^^^
Identique à la fonction :ref:`m_table_add`, mais multiplie les valeurs
des deux OIDs de valeurs correspondantes à l'index avant d'effectuer
l'addition. Cette fonction retourne donc la somme des produits.

..  _`m_valueAndPercentageToValue`:

``m_valueAndPercentageToValue``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Étant donné une valeur maximale et un pourcentage, retourne la valeur
approximative correspondant au pourcentage de la valeur maximale.
Cette fonction est utile pour représenter l'espace occupé sur une partition
par exemple lorsque l'équipement ne met à disposition que la capacité totale
de la partition et son taux d'occupation.

..  _`m_walk_grep_count`:

``m_walk_grep_count``
^^^^^^^^^^^^^^^^^^^^^
Cherche le motif demandé dans les valeurs du sous-arbre de recherche
et retourne le nombre de correspondances trouvées.

..  _`percentage`:

``percentage``
^^^^^^^^^^^^^^
Divise la valeur donnée par 100 et retourne le résultat.

..  _`percentage2values`:

``percentage2values``
^^^^^^^^^^^^^^^^^^^^^
Retourne le pourcentage de valeur 1 par rapport à valeur 2.


..  _`sup.pm`:

Fonctions relatives aux calculs d'états
---------------------------------------
Le module :file:`sup.pm` contient des fonctions simplifiant l'écriture de tests
de supervision. La signature des fonctions de ce module est la même que pour
les fonctions du module :file:`metro.pm` (voir la section :ref:`metro.pm`),
de même que la forme de la valeur de retour.

Cependant, contrairement au module :file:`metro.pm`, tous les états Nagios
relatifs aux services (``OK``, ``UNKNOWN``, ``WARNING``, ``CRITICAL``) sont
susceptibles d'être retournés par les fonctions de ce module.

Le reste de cette section décrit les différentes fonctions proposées
par ce module.

..  only:: enterprise

    ..  _`alcaltelFans`:

    ``alcatelFans``
    ^^^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des ventilateurs
    sur du matériel Alcatel.

    ..  _`ciscoFans`:

    ``ciscoFans``
    ^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des ventilateurs
    sur du matériel CISCO.

    ..  _`cisco_ipsla_simple`:

    ..  _`ciscoPsus`:

    ``ciscoPsus``
    ^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des alimentations
    sur du matériel CISCO.

    ..  _`ciscoTemps`:

    ``ciscoTemps``
    ^^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des capteurs de température
    sur du matériel CISCO.

    ..  _`DellDiskState`:

    ``DellDiskState``
    ^^^^^^^^^^^^^^^^^
     Retourne l'état des disques durs sur du matériel Dell en utilisant
     l'agent Dell OpenManage.

    ..  _`DellFANState`:

    ``DellFANState``
    ^^^^^^^^^^^^^^^^
     Retourne l'état des ventilateurs sur du matériel Dell en utilisant
     l'agent Dell OpenManage.

    ..  _`DellPowerSupplyState`:

    ``DellPowerSupplyState``
    ^^^^^^^^^^^^^^^^^^^^^^^^
     Retourne l'état des alimentations sur du matériel Dell en utilisant
     l'agent Dell OpenManage.

    ..  _`DellStatus`:

    ``DellStatus``
    ^^^^^^^^^^^^^^
     Retourne l'état global du matériel Dell en utilisant l'agent
     Dell OpenManage.

    ..  _`DellTemperatureState`:

    ``DellTemperatureState``
    ^^^^^^^^^^^^^^^^^^^^^^^^
     Retourne l'état des capteurs de température sur du matériel Dell
     en utilisant l'agent Dell OpenManage.

    ..  _`ExtremeNetworksFans`:

    ``ExtremeNetworksFans``
    ^^^^^^^^^^^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des ventilateurs
    sur du matériel Extreme Networks.

    ..  _`ExtremeNetworksPsus`:

    ``ExtremeNetworksPsus``
    ^^^^^^^^^^^^^^^^^^^^^^^
     Retourne l'état des alimentations sur du materiel Extreme Networks.

    ..  _`ExtremeNetworksTemps`:

    ``ExtremeNetworksTemps``
    ^^^^^^^^^^^^^^^^^^^^^^^^
     Retourne l'état des capteurs de température sur du matériel
     Extreme Networks.

    ..  _`hpFans`:

    ``hpFans``
    ^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des ventilateurs
    sur du matériel HP.

    ..  _`hpPsus`:

    ``hpPsus``
    ^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des alimentations
    sur du matériel HP.

    ..  _`hpRaid`:

    ``hpRaid``
    ^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état du RAID sur du matériel HP.

    ..  _`hpTemps`:

    ``hpTemps``
    ^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des capteurs de température
    sur du matériel HP.

..  _`ifOperStatus`:

``ifOperStatus``
^^^^^^^^^^^^^^^^
Cherche l'interface en parcourant l'OID de description, récupère l'index
et utilise cet index pour trouver l'état courant, l'état d'admin et l'alias
de l'interface.
Utilise ensuite la fonction :ref:`genericIfOperStatus` pour déterminer l'état
qui doit être retourner à Nagios.

..  only:: enterprise

    ..  _`ifOperStatus_ISG`:

    ``ifOperStatus_ISG``
    ^^^^^^^^^^^^^^^^^^^^
    Récupère l'état de l'interface à l'index demandé. Retourne cet état
    ou son contraire si l'inversion a été demandée (utilisé pour des tunnels
    redondants).

    ..  _`nortelFans5510`:

    ``nortelFans5510``
    ^^^^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état des ventilateurs sur du matériel
    de type Nortel 5510.

    ..  _`nortelFans8310`:

    ``nortelFans8310``
    ^^^^^^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des ventilateurs sur du matériel
    de type Nortel 8310.

    ..  _`nortelGBic8310`:

    ``nortelGBic8310``
    ^^^^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état du GBic sur du matériel
    de type Nortel 8310.

    ..  _`nortelPsus5510`:

    ``nortelPsus5510``
    ^^^^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état des alimentations
    sur du matériel de type Nortel 5510.

    ..  _`nortelPsus8310`:

    ``nortelPsus8310``
    ^^^^^^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des alimentations
    sur du matériel de type Nortel 8310.

    ..  _`nortelRcCards8310`:

    ``nortelRcCards8310``
    ^^^^^^^^^^^^^^^^^^^^^
    Utilise :ref:`genericHW` pour retourner l'état des cartes RC sur du matériel
    de type Nortel 8310.

    ..  _`nortelStack5510`:

    ``nortelStack5510``
    ^^^^^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état de la pile sur du matériel
    de type Nortel 5510.

    ..  _`overlandDST`:

    ``overlandDST``
    ^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état des disques sur du matériel
    Overland.

    ..  _`packeteerFans`:

    ``packeteerFans``
    ^^^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état des ventilateurs sur du matériel
    Packeteer.

    ..  _`packeteerPsus`:

    ``packeteerPsus``
    ^^^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état des alimentations
    sur du matériel Packeteer.

    ..  _`packeteerOs`:

    ``packeteerOs``
    ^^^^^^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état du contrôle de la qualité
    de service réseau sur du matériel Packeteer.

..  _`simple_factor`:

``simple_factor``
^^^^^^^^^^^^^^^^^
Multiplie l'OID par le facteur et compare le résultat par rapport aux limites
indiquées grâce à la fonction :ref:`thresholdIt`.

..  only:: enterprise

    ..  _`solLMSensorsPsus`:

    ``solLMSensorsPsus``
    ^^^^^^^^^^^^^^^^^^^^
    Retourne l'état des alimentations sous Solaris, grâce à l'extension
    *lmsensors*.

..  _`staticIfOperStatus`:

``staticIfOperStatus``
^^^^^^^^^^^^^^^^^^^^^^
Identique à :ref:`ifOperStatus`, mais ne cherche pas l'index par recherche
de l'OID description : l'index est fourni en paramètre.
Utile quand plusieurs interfaces portant le même nom sont présentes.

..  _`statusWithMessage`:

``statusWithMessage``
^^^^^^^^^^^^^^^^^^^^^
Compare la valeur d'état aux valeurs OK et *warning*, puis retourne le message
de l'OID message.

..  _`storage`:

``storage``
^^^^^^^^^^^
Calcule l'espace total et l'espace utilisé en multipliant les unités
d'allocation par la taille d'une unité, puis calcule le rapport
entre la taille utilisée et la taille totale.
Le résultat est ensuite passé à :ref:`thresholdIt` pour comparer ce rapport
aux limites demandées. Si *pourcent* est vrai, la limite porte sur
le pourcentage utilisé et non la taille brute.

..  _`sup_rpn`:

``sup_rpn``
^^^^^^^^^^^
Effectue un calcul à partir de plusieurs valeurs à l'aide d'une formule
donnée en Notation Polonaise Inverse (:abbr:`RPN (Reversed Polish Notation)`).

Voir http://fr.wikipedia.org/wiki/Notation_polonaise_inverse pour plus
d'information sur la notation utilisée.

..  _`sysUpTime`:

``sysUpTime``
^^^^^^^^^^^^^
Convertit l'*uptime* (disponibilité de la machine) en nombre de secondes
grâce à :ref:`date2Time`, puis compare le résultat aux valeurs *warning*
et *critical* grâce à la fonction :ref:`thresholdIt`.

..  _`table`:

``table``
^^^^^^^^^
Cherche le nom dans le sous-arbre débutant à l'OID description,
récupère l'index, utilise cet index pour trouver la valeur correspondante
dans l'OID valeur et compare cette valeur aux limites indiquées grâce
à la fonction :ref:`thresholdIt`.
Cela correspond au fonctionnement d'une *table* en SNMP.

..  _`table_factor`:

``table_factor``
^^^^^^^^^^^^^^^^
Similaire à :ref:`table`, mais multiplie le résultat par le facteur donné
avant de le comparer aux limites avec :ref:`thresholdIt`.

..  _`table_mult`:

``table_mult``
^^^^^^^^^^^^^^
Similaire à :ref:`table`, mais utilise l'index pour trouver les valeurs
des deux OIDs demandés, multiplie ces valeurs entre elles, puis compare
le résultat aux limites indiquées avec :ref:`thresholdIt`.

..  _`table_mult_factor`:

``table_mult_factor``
^^^^^^^^^^^^^^^^^^^^^
Similaire à :ref:`table_mult`, mais le résutat est multiplié par un facteur
avant d'être comparé aux limites avec :ref:`thresholdIt`.

..  _`table_total_free`:

``table_total_free``
^^^^^^^^^^^^^^^^^^^^
Fonctionnement similaire à celui de :ref:`table`, mais calcule d'abord
le pourcentage de *free* par rapport au *total*, avant de procéder
à la comparaison avec les limites en utilisant la fonction :ref:`thresholdIt`.

..  _`table_used_free`:

``table_used_free``
^^^^^^^^^^^^^^^^^^^
Fonctionnement similaire à celui de :ref:`table`, mais calcule d'abord
le pourcentage de *used* par rapport à *free + used*, avant de procéder
à la comparaison avec les limites en utilisant la fonction :ref:`thresholdIt`.

..  _`thresholds_mult`:

``thresholds_mult``
^^^^^^^^^^^^^^^^^^^
Multiplie les deux OIDs et compare le résultat aux limites demandées
grâce à la fonction :ref:`thresholdIt`.

..  _`thresholds_OID_plus_max`:

``thresholds_OID_plus_max``
^^^^^^^^^^^^^^^^^^^^^^^^^^^
Calcule le pourcentage de l'OID analysé par rapport à l'OID max
et le compare aux limites demandées grâce à la fonction :ref:`thresholdIt`.

..  _`thresholds_OID_simple`:

``thresholds_OID_simple``
^^^^^^^^^^^^^^^^^^^^^^^^^
Récupère la valeur de l'OID analysé et la compare aux limites *warning*
et *critical* grâce à la fonction :ref:`thresholdIt`.

..  _`walk_grep_count`:

``walk_grep_count``
^^^^^^^^^^^^^^^^^^^
Cherche le motif demandé dans les valeurs du sous-arbre de recherche
et compare le nombre de correspondances aux limites grâce à :ref:`thresholdIt`.

..  only:: enterprise

    ..  _`winsvc`:

    ``winsvc``
    ^^^^^^^^^^
    Utilise :ref:`resultMap` pour retourner l'état d'un service Windows.


Débogage
========
Le Collector peut être lancé manuellement (indépendamment de Nagios).
De plus, le passage de l'option « -d » lors de l'appel au Collector
permet d'obtenir des informations de débogage sur au cours de l'exécution.

Par exemple, pour tester l'hôte « testlinux » ::

    /usr/lib64/nagios/plugins/Collector -d -H testlinux

Le Collector affichera alors les OIDs SNMP demandés à l'hôte, les réponses
obtenues, ainsi que les valeurs (états et métrologie) à envoyer aux autres
composants.

..  warning::
    Même lorsqu'il est exécuté en mode déboguage, le Collector continue
    d'envoyer les valeurs qu'il a calculées (états et métrologie) aux
    autres composants de Vigilo.

.. _`ajout_fonctions`:

Ajout de fonctions
==================

L'ajout de fonctions personnalisées se fait en créant un nouveau module Perl
dans le répertoire :file:`/usr/{lib64}/vigilo-collector/ext/`.
Par convention, le nom du module est un court représentatif de l'entreprise
responsable de l'ajout.

..  warning::
    Vous devez impérativement créer un **nouveau** module Perl dans le
    répertoire. Si vous modifiez l'un des modules existants fournis avec
    Vigilo, vos modifications seront automatiquement écrasées lors d'une
    réinstallation ou d'une mise à jour.

Le nom des nouvelles fonctions dans ce module ne doit pas entrer en conflit
avec les noms des fonctions déjà existantes. Il est ainsi conseillé d'adopter
la politique de nommage suivante pour les fonctions :

-   :samp:`{entreprise}_{NomFonction}` pour les fonctions liées au calcul
    d'un état (équivalent des fonctions disponibles dans le fichier
    :file:`sup.pm`)

  - :samp:`m_{entreprise}_{NomFonction}` pour les fonctions liées aux données
    de métrologie (équivalent des fonctions disponibles dans le fichier
    :file:`metro.pm`)


Annexes
=======

Glossaire - Terminologie
------------------------

Ce chapitre recense les différents termes techniques employés dans ce document
et donne une brève définition de chacun de ces termes.

.. glossary::

    MIB (Management Interface Base)
        Fichier contenant une interface pour l'interrogation d'informations
        sur des équipements compatibles avec le protocole SNMP.

    OID (Object IDentifier)
        Identifiant des objets à interroger dans la MIB SNMP.

    SNMP (Simple Network Management Protocol)
        Protocole simplifié de gestion des équipements au travers d'un réseau.

.. vim: set tw=79 :
