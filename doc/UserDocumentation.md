User Documentation
==============================

# How to begin

# Global overview of HCM

# Rôles dans HCM
## Administrator

Il pilote les ressources enregistrées dans Kanopya et définie les policies techniques (Compute, Storage, Monitoring,...) en collaboration avec le créateur de service qui seront utilisés pour composer des services.

Il a aussi accès aux instance de services (technique ou utilisateurs) afin de les suivre et d'effectuer des actions de maintenance si nécessaire.

C'est cet utilisateur qui peut aussi créer des comptes utilisateurs avec les profiles (administrator, business developer, sales)
Pour résumer, il a accès :

+ aux infrastructures techniques
+ aux policies et aux services templates
+ à la gestion des utilisateurs de Kanopya
+ aux instances de services

## Service developer

Il aide l'administrateur à créer les politiques et les compose afin de former des services.
C'est l'utilisateur qui reçoit les besoins de ses clients et les formalise sous forme d'offres afin d'être exploitées par les sales ou les clients.
Pour résumer, il a accès

+ aux policies et aux services templates

## Sales

Il accède au service disponible et peut les instancier (création + configuration) pour les attribuer à des clients. Il a aussi un rôle de supervision.

Pour résumer, il a accès

+ à l'instanciation d'un service (qu'il peut attribuer à ses clients)
+ aux notification et à la validation lors de la création des services
+ à la visualisation des instances de services de ses clients
+ à la visualisation des policies et service template
+ au management des customers

## Customer

C'est le client final du service, il peut uniquement visualiser et manager les instances de services qui lui sont attribuées.
Pour résumer, il a accès

+ à la visualisation de son infra
+ au management de ses instances de services (demarrer, scale, ...)
+ au monitoring et à la gestion des rules de ses instances de services

Les différents acteurs précédemment présentés interagisse comme présenté dans le diagramme suivant :

![roles](/home/xebech/Documents/Kanopya/src/hcm/doc/images/Service-policy-workflow-users.png)

# Infrastructure Management
HCM s'appuie sur des ressources existantes dans les infrastructures pour délivrer un service d'hébergement d'infrastructure de type cloud. 

Pour atteindre cet objectif, HCM permet d'enregistrer les ressources suivantes de l'infrastructure :

+ **Compute :** les ressources de calcul (les serveurs et les manageurs de blades) 
+ **Storage :** les systèmes de stockage
+ **IaaS :** les infrastructures de virtualisation qui seront exploités par HCM (Ces infrastructures peuvent être déployées ou enregistrées dans HCM)
+ **Network :** les réseaux présents sur l'infrastructure
+ **System :** Les images des systèmes à destination des Vms

Ces infrastructures déclarées permettront d'être exploitées dans les politiques et les définitions de services.

## Compute

HCM permet de déployer des services sur du bare metal (serveurs nus).

Pour cela. il faut enregistrer dans la solution les différents serveurs qui pourront être sollicités.

HCM permet d'enregistrer les serveurs par deux biais :

+ Manuellement, l'administrateur a à enregistrer les informations de chacun de ces serveurs (comme présenté dans la section [Hosts])
+ Automatiquement, via le système de gestion de blade. HCM supporte la synchronisation avec les blade Cisco UCS et HP C7000.

### Hosts

HCM permet la gestion des serveurs x86 standard. L'administrateur aura à les enregistrer dans l'interface. 
Ces serveurs seront groupés dans le référentiel HCM. Pour les utiliser il faut dans la policy de [Hosting Policy], utiliser *Physicalhoster* comme Host Type.

Ces serveurs peuvent être pilotés via leur interface IPMI ou via etherwake (pour les serveurs sans IPMI).

Depuis la page de listing des hosts, il est possible de :

-   supprimer un host, avec l'icone corbeille.
    Pour être supprimer le host doit être désactivé et non utilisé par HCM
-   désactiver un host, avec l'icone croix.
    Il est possible de désactiver les hosts non utilisés, un host désactivé ne sera pas choisi par le capacity manager de hcm.
-    enregistrer un host

![host-list](/home/xebech/Documents/Kanopya/src/hcm/doc/images/Screen-Hosts-List.png)

#### Enregistrement d'un host

Afin d'enregistrer un host un certain nombre d'information peuvent être renseigner:

+ Description : Pour localiser le serveur dans le datacenter
+ CPU Capability : 
+ RAM Capability : 
+ Specific kernel : 
+ Serial Number :

![Edit-host](/home/xebech/Documents/Kanopya/src/hcm/doc/images/Screen-Edit-Host.png)

## Storage

## IaaS

## Network

## System

# Service Management

Pour faciliter et accélérer le déploiement de service, HCM intègre
deux types d'abstraction.

-   **La notion de Policies**, permet aux Administrateurs de définir
    des templates d'infrastructures dans ses différentes composantes
    (compute, storage, scalability, …). Son niveau de précision dépend
    de l'équilibre technico-commerciale des équipes. (Compute low cost,
    storage redondé, IaaS avec haute dispo, ...).

-   **La notion de Service**, permet aux utilisateurs de regrouper des
    Policy pour fournir des services complexes cohérents vis à vis des
    utilisateurs finaux (VM low cost à performance limitée,
    Infrastructure web critique haute performance, etc...). Les services
    permettent ensuite d'industrialiser la définition, la création et la
    distribution de service d'infrastructure.

Les Policies et les services sont des systèmes de template permettant à
l'utilisateur de préciser au fur et à mesure la configuration des
infrastructures déployées.

Ainsi une information non précisée dans les Policy sera proposé pour
spécification à la création du service.

Si cette information n'est ni précisé dans la Policy ni dans le service,
elle sera demandée à la création de chaque instance de service.

Voici le workflow de création d'une instance de services
(policy-\>service-\>instance)

![service-policy-wfw](/home/xebech/Documents/Kanopya/src/hcm/doc/images/Policy_service_workflow.png)

Une fois qu'un service est mis à disposition des équipes commerciales,
ces dernières pourront en créer des instances qui seront attribués à des
clients.


## Policies

Les Policies sont des éléments de configuration qui permettent de
composer les services. Elles contiennent les spécifications unitaires
des différents aspects de définition des services.

Les différentes policies de Kanopya sont :

-   hosting,
-   storage,
-   network,
-   system,
-   scalability,
-   automation,
-   orchestrator
-   Billing/consumption management.

> Exemple 1 : il est possible d'imposer la haute disponibilité d'un
> service en précisant dans la policy de hosting que le nombre minimal de
> nœuds à déployer pour chaque instance est 2, sans pour autant définir la
> limite maximale.

> Exemple2 : il est possible de définir l’existence de 2 seuils de
> puissance alloués à un service sans pour autant préciser les valeurs
> palières qui seraient renseignés à la création de l'instance de service.

### Hosting Policy

La politique de 'Hosting' définie le type de solution de Hosting
(compute) utilisée par les services.

Le premier élément à choisir dans une policy de hosting est le host
Manager souhaité. En fonction des infrastructures déployées, il est
possible de choisir parmis

-   OpenNebula ("Virtual Machine")
-   Openstack("Virtual Machine")
-   Cisco Unified Computing System ("Physical Host")
-   Kanopya ("Physical Host")
-   VMware Center 5.1("Virtual Machine")

Kanopya manipule 2 types d'hôte "Virtual Machine" et "Physical Host",
chacun a des paramètres de spécification différentes

  -----------------------------------------------------------------------------------------------------------
  Virtual Machine                                      Physical Host
  ---------------------------------------------------- ------------------------------------------------------
  Maximum RAM amount :\                                \
  Maximum CPU number :\                                Required CPU number :\
  Initial CPU number :\                                Tags : \
  Initial RAM amount :                                 Required RAM amount :

  ![](/attachments/download/206/hosting-virtual.png)   \
                                                        ![](/attachments/download/205/hosting-hardware.png)
  -----------------------------------------------------------------------------------------------------------

### Storage Policy[¶](#Storage-Policy)

La politique de stockage définit le 'datastore" utilisé pour créer et
exporter les disques pour les hosts des instance de service.

Généralement, l'administrateur va choisir le type de fournisseur de
stockage au sein de ses ressources existantes, ainsi que les
technologies de manipulation de disque et d'export parmi celles fournit
par la solution de stockage.

Suite à ces spécifications Kanopya automatisera, la gestion des disques
des instances de service.

Les Datastores peuvent :

-   soit être utilisé directement par les instances de services pour
    déploiement de leurs hosts (ou nodes) via des systèmes d'export en
    mode block.
-   soit être utilisé sur un IaaS comme répertoire partagé pour stocker
    les images de vms.

Ainsi il est possible d'utiliser les datastores dans les configurations
de policies suivantes :

-   Kanopya et Linux NAS (lvm + iscsi)
-   OpenNebula (repository NFS enregistré pour stocker les images de
    vms)
-   NetApp (iscsi, NFS ou FC)
-   Cinder (repository NFS enregistré pour stocker les images de vms)

Voici quelques exemples de configurations :

  ------------------------------------------------------------------------------------------------------------------
  lvm + iscsi                                            repository sur un IaaS
  ------------------------------------------------------ -----------------------------------------------------------
  ![](/attachments/download/208/storage_lvm_iscsi.png)   \
                                                         ![](/attachments/download/209/storage_nfs_repository.png)
  ------------------------------------------------------------------------------------------------------------------

### Network Policies[¶](#Network-Policies)

La politique de gestion du réseau définit les éléments de configuration
du réseau sur les nœuds des instances de service.

L'administrateur peut définir le nom de domaine, les serveurs DNS, la
gateway par defaut et les interfaces nécessaires.

Les champs suivant sont génériques à toutes les configurations réseaux :

-   Domain name : nom de domaine des hosts (physique et virtuel)
-   Name server 1 : adresse ip du premier serveur de nom
-   Name server 2 : adresse ip du second serveur de nom

![](/attachments/download/212/general_network.png)

Dans cette partie de la documentation nous ne reviendrons pas sur la
création des netconfs qui est détaillée dans la section [Network
Definition](/projects/mcs/wiki/Kanopya_concepts#Network-Definition)

Dans la network policy, nous allons uniquement définir la configuration
de chaque interface réseau devant être présentes sur chaque nœud (host).

Ainsi pour chaque interface réseau on définit :

-   **Name** : le nom de l'interface (par exemple eth0)
-   **Network Configuration** : la netconf que l'on veut utiliser (cela
    peut être une simple interface réseau sur un réseaux, une interface
    avec n Vlans, une interface de bridge pour les hyperviseurs)
-   **Bonding Slave Count** : utiliser seulement si on veut faire un
    bond entre deux interfaces pour agréger leur lien (à 0 par defaut)

### System policy[¶](#System-policy)

La politique system définit les paramétres utilisés lors de la création
des disques des nœuds des instances de service.

L'administrateur peut prédéfinir le type d'OS, la taille du disque et la
liste de software à installer sur les nœuds.

![](/attachments/download/213/system_policy.png)

La policy system permet de définir les informations suivantes :

-   **kernel** : C'est le kernel qui sera utilisé par tous les nœuds des
    toutes les instances de service. Il peut être laisser vide (par
    défaut) ou spécifier. (Info : si le kernel n'est pas spécifié
    jusqu'à l'instance de service, c'est le kernel des hosts qui sera
    choisi)
-   **Master Image** : C'est l'image vierge utilisée pour les nœuds de
    l'instance de service. Par défaut Kanopya propose 2 distributions
    (Centos et Ubuntu). Il est cependant facile via le système d'upload
    de Master Image d'ajouter d'autres images (soit car elles sont basés
    sur des systèmes non présents sur Kanopya soit parce que ces images
    ont été customizé (ou sécurisées))
-   **cluster base hostname** : Ce champs va disparaitre, il permettait
    de définir le préfixe des hostnames des nœuds déployés dans chaque
    instance (ce paramètre est généralement spécifié durant
    l'instanciation du service afin que chaque hosts pilotés par Kanopya
    aient des hostnames différents.
-   **System image size** : Permet de spécifier la taille du disque
    généré pour les hosts.
-   **Persistent system image** : Ce champs permet de spécifier si
    l'image générée pour le nœud perdure au delà de l'extinction du
    nœud. S'il est configuré non, Kanopya supprimera l'image lors de
    l'arrêt du nœud.
-   **System image shared** : Cette option permet d'avoir un seul disque
    utilisé pour tous les nœuds des instances de services. Elle ne
    fonctionne qu'avec les boot pxe + iscsi ou pxe + nfs.
-   **Deploy on hard disk** : Cette option n'est valable que si le
    service est basé sur les nœuds physiques. Elle permet de spécifier à
    Kanopya de déployer le système sur le disque du nœud déployé.

Il est ensuite possible d'ajouter les applications à déployer sur les
noeuds des instances de service.\
Il est possible de choisir parmis :

-   Mettre la liste des components
-   ...

### Scalability policy[¶](#Scalability-policy)

La scalability policy permet de définir les contraintes de scalabilité
horizontale ainsi que la priorité d'accès aux ressources.

La politique de scalabilité permet de prédéfinir les informations
suivantes :

-   **Minimum number of nodes** : nombre minimum de nœuds dans une
    instance de service (pour de la HA, mettre 2)
-   **Maximum number of nodes** : nombre maximum de nœuds dans une
    instance de service (pour de simple vm, mettre 1)

![](/attachments/download/214/scalability_policy.png)

### Billing Policy[¶](#Billing-Policy)

Pour Kanopya le billing est une policy particulière. Elle repose sur le
système de monitoring interne à Kanopya. Plus précisément il est basé
sur la mesure de métrique système (CPU, RAM).

Elle permet de définir des seuils et une limite à la consommation des
instances de service pour chaque métrique.

#### Mesures[¶](#Mesures)

La fréquence et le temps de conservation des métriques mesurées sont
définis par défaut dans la version 1.8.

Les informations sont récupérées toutes les minutes et une moyenne est
faite sur 5 minutes pour créer les Node metrics qui seront utilisés pour
le reporting de la consommation (cf [Monitoring and rules engine
system](/projects/mcs/wiki/Kanopya_concepts#Monitoring-and-rules-system)).

#### Limites[¶](#Limites)

Des limites de consommation peuvent être définies dans la Resource
consumption policy. Elles sont de trois types :

-   Les limites non bloquantes qui permettent de définir des tranches de
    consommations et de calculer les dépassements.
-   La limite maximum.
-   Pas de limite.

Les limites sont paramétrables dans le temps (exemple : de 20h à 8h -
CPU : 8Core, RAM : 22 Go ; de 8h à 20h - CPU : 22Core, RAM : 102 Go).

Les limites sont définies sur les métriques de consommation CPU et RAM.

Les limites sont modifiables pendant l'ensemble du cycle de vie de
l'instance de service. Elles sont historicisées.

#### La restitution de la consommation pour le client final[¶](#La-restitution-de-la-consommation-pour-le-client-final)

Kanopya restitue les informations de consommation du client final à
partir de l'instance de service et des caractéristiques de la Resource
consumption policy associée.\
Cette restitution est effectuée sous la forme d'un export de fichier au
format csv.

## Services

# Instance Management

# Automation and Optimization

