# homelab-si-entreprise

Je suis en Bachelor Administrateur Systèmes et Réseaux au CESI d'Aix-en-Provence. En attendant de trouver mon alternance, j'ai décidé de monter chez moi le système d'information complet d'une petite entreprise, en partant de zéro, sur mon PC avec VMware Workstation.

Ce dépôt, c'est ma doc. Ce que j'ai installé, comment je l'ai réglé, pourquoi je l'ai fait comme ça, et surtout les pannes que j'ai eues en route et comment je les ai réglées. Le labo est en cours : les deux premières semaines sont terminées (pare-feu, Active Directory, GPO, partages, PowerShell, puis serveur Linux, GLPI et supervision), je complète au fur et à mesure.

## L'entreprise

Calanques Distribution n'existe pas, c'est mon entreprise fictive. Une PME marseillaise de 30 salariés qui vend du matériel aux commerces de la région, avec trois services : la compta, le commercial et l'entrepôt.

Le point de départ est simple. Je suis le nouvel admin et il n'y a rien, ni serveur, ni comptes, ni règles. Je construis tout dans l'ordre où on le ferait dans une vraie entreprise.

## Le schéma du labo

```
                         Internet
                            |
                     NAT de VMware (WAN)
                            |
                    +---------------+
                    |     FW01      |   pfSense
                    +---------------+
                     |             |
               10.10.10.1      10.10.20.1
                     |             |
         LAN-SRV (serveurs)    LAN-POSTES (postes, semaine 3)
          |        |       |             |
        DC01   SRV-LINUX  SRV-BACKUP   CLIENT01
```

Tout ce qui sort vers internet passe par FW01, et à partir de la semaine 3, tout ce qui passe d'une zone à l'autre aussi. En attendant, CLIENT01 est branché sur LAN-SRV.

## Le plan d'adressage

| Machine | Rôle | Zone | Adresse IP | Semaine |
| --- | --- | --- | --- | --- |
| FW01 | Pare-feu pfSense | WAN, LAN-SRV, LAN-POSTES | 10.10.10.1 et 10.10.20.1 | 1 |
| DC01 | Windows Server 2025 : AD DS, DNS, DHCP | LAN-SRV | 10.10.10.10 | 1 |
| CLIENT01 | Windows 11, le PC d'un salarié | LAN-SRV, puis LAN-POSTES | DHCP | 1 |
| SRV-LINUX | Ubuntu Server 24.04 : GLPI, Zabbix, Grafana | LAN-SRV | 10.10.10.20 | 2 |
| SRV-BACKUP | Windows Server : Veeam | LAN-SRV | 10.10.10.30 | 3 |

| Élément | Valeur |
| --- | --- |
| Domaine | lab.local (nom court LAB) |
| Zone serveurs | 10.10.10.0/24, passerelle 10.10.10.1 |
| Zone postes | 10.10.20.0/24, passerelle 10.10.20.1 |
| DNS de toutes les machines | 10.10.10.10 (DC01) |
| Plage DHCP | de .100 à .200 |

J'ai mis les serveurs en adresses fixes basses et les postes en DHCP à partir de .100, comme ça une adresse distribuée ne tombe jamais sur celle d'un serveur.

## Où j'en suis

| Semaine | Contenu | État |
| --- | --- | --- |
| 1 | VMware, pfSense, DC01 (AD, DNS, DHCP, NTP), CLIENT01, organisation de l'annuaire, GPO, modèle T0/T1/T2, partage de la compta, script PowerShell | Fait |
| 2 | Serveur Linux, GLPI relié à l'AD en LDAPS, inventaire et tickets, supervision Zabbix et Grafana | Fait |
| 3 | Séparation postes et serveurs avec règles de pare-feu, sauvegarde Veeam avec test de restauration, Fortinet, Proxmox | À venir |

## L'annuaire

J'ai rangé l'annuaire selon les règles qu'on veut appliquer, pas selon l'organigramme. Les personnes d'un côté, les machines de l'autre, parce qu'une GPO vise soit l'un soit l'autre.

```
lab.local
└── LAB
    ├── Admins          T0, T1, T2
    ├── Utilisateurs    Compta, Commercial, Entrepot, Informatique
    ├── Ordinateurs     Postes, Serveurs
    └── Groupes         GG_Compta, GG_Commercial, GG_Entrepot,
                        GG_T1_Admins_Serveurs, GG_T2_Admins_Postes
```

Les droits passent toujours par des groupes, jamais par des comptes. Et j'ai appliqué le modèle de tiering : j'ai un compte du quotidien sans aucun droit d'admin, plus un compte d'admin par niveau (T0 pour l'annuaire, T1 pour les serveurs, T2 pour les postes). Une GPO interdit aux comptes T0 et T1 de se connecter sur les postes, pour qu'un compte puissant ne se retrouve jamais exposé sur un PC de salarié.

## Ce qu'il y a dans le dépôt

| Dossier ou fichier | Contenu |
| --- | --- |
| [docs](docs) | Une page par module, avec ce que j'ai fait, comment je l'ai vérifié, et les captures |
| [journal-de-bord.md](journal-de-bord.md) | Toutes les pannes rencontrées, leur cause et ma solution |
| [scripts](scripts) | Le script PowerShell de création des comptes et un CSV d'exemple |

Les modules :

1. [VMware et les réseaux virtuels](docs/01-vmware-reseaux.md)
2. [Le pare-feu pfSense](docs/02-pfsense.md)
3. [DC01 : Active Directory, DNS, DHCP et heure](docs/03-dc01-ad-dns-dhcp.md)
4. [Le poste client et l'annuaire](docs/04-client-annuaire.md)
5. [GPO, tiering et partage de la compta](docs/05-gpo-tiering-partages.md)
6. [L'automatisation en PowerShell](docs/06-powershell.md)
7. [SRV-LINUX, le serveur Linux](docs/07-srv-linux.md)
8. [GLPI, le support et l'inventaire](docs/08-glpi.md)
9. [La supervision avec Zabbix et Grafana](docs/09-zabbix-grafana.md)

## Ce que j'ai appris

Le DNS, c'est vraiment la pièce maîtresse. Un PC ne trouve le domaine que parce que le DNS de DC01 lui dit où il est (les enregistrements SRV). La moitié des problèmes d'Active Directory, c'est en fait du DNS.

Une GPO a deux moitiés, une pour les machines et une pour les utilisateurs, et chacune n'est lue que si la cible est rangée dans l'OU liée. Si on se trompe, il n'y a aucun message d'erreur, il ne se passe juste rien. Je l'ai compris en cherchant pourquoi mes réglages ne s'appliquaient pas.

Sur un partage réseau, il y a deux portes, les droits du partage et les droits NTFS, et c'est la plus fermée qui gagne. Du coup on ouvre le partage et on règle tout dans NTFS, comme ça il n'y a qu'un seul endroit à gérer.

Un script doit pouvoir être relancé sans rien casser. Ma première version plantait à la deuxième exécution parce que les comptes existaient déjà, et en plus elle affichait "compte créé " alors que ça avait échoué. Depuis, je vérifie toujours le résultat dans l'annuaire et pas juste le message à l'écran.

Une application qui se branche sur l'annuaire a son propre compte, un compte de service, avec seulement les droits dont elle a besoin. Celui de GLPI lit l'AD et ne peut rien y modifier. Et quand Windows Server 2025 a refusé que GLPI lui envoie un mot de passe en clair, j'ai monté une autorité de certification pour passer en LDAPS au lieu de baisser la sécurité.

Une supervision, ça se teste. J'ai arrêté moi-même un service sur DC01 pour voir l'alerte arriver dans Zabbix, puis disparaître quand je l'ai relancé. Tant qu'on ne l'a pas vue sonner, on ne sait pas si elle marche.

Et le plus utile au final : lire le message d'erreur en entier. Plusieurs de mes pannes venaient d'un détail écrit noir sur blanc dans le message, comme un espace en trop à la fin d'un nom de groupe.

## Outils

VMware Workstation Pro, pfSense CE 2.9.0, Windows Server 2025 (version d'évaluation, en anglais), Windows 11, PowerShell, Ubuntu Server 24.04 LTS, Apache, MariaDB, GLPI et GLPI Agent, Zabbix (LTS) et Zabbix agent 2, Grafana.

Il n'y a aucun mot de passe dans ce dépôt, même ceux du labo. Dans le script, le mot de passe temporaire est demandé au lancement.
