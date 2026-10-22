# Journal de bord

Toutes les pannes que j'ai eues pendant le labo, dans l'ordre. Pour chacune : ce que j'ai vu, ce qui se passait vraiment, comment je l'ai réglé, et ce que j'en retiens.

## Semaine 1

### FW01 n'avait qu'une seule carte réseau

**Symptôme :** pendant l'installation de pfSense, impossible d'attribuer un WAN et un LAN, il ne proposait qu'une seule interface.

**Cause :** la VM avait été créée avec la carte NAT par défaut, et rien d'autre.

**Solution :** VM éteinte, ajout d'une deuxième carte (Network Adapter 2) en LAN segment `LAN-SRV`. J'en ai aussi profité pour passer la RAM de 256 Mo à 1 Go.

**Ce que j'en retiens :** un pare-feu a besoin d'au moins deux pattes, une dehors et une dedans. Je prépare le matériel de la VM avant de lancer l'installation.

### DC01 ne joignait pas le pare-feu

**Symptôme :** `ping 10.10.10.1` ne répondait pas depuis DC01, et la page de pfSense ne s'ouvrait pas (ERR_ADDRESS_UNREACHABLE).

**Cause :** FW01 était éteinte.

**Solution :** démarrer FW01.

**Ce que j'en retiens :** avant de chercher compliqué, je vérifie que la machine d'en face est allumée.

### DC01 en 169.254.x.x

**Symptôme :** `ipconfig` affichait une adresse en 169.254 au lieu de 10.10.10.10.

**Cause :** l'IP fixe n'avait pas été enregistrée dans les propriétés de la carte. Une adresse en 169.254, c'est Windows qui s'attribue une adresse tout seul quand il n'a ni IP fixe ni réponse DHCP.

**Solution :** refaire la config dans `ncpa.cpl` en validant bien avec OK puis Fermer.

**Ce que j'en retiens :** 169.254 veut toujours dire « pas d'adresse valide ». Après une config réseau, je vérifie avec `ipconfig /all`.

### Mauvais fuseau horaire sur DC01

**Symptôme :** l'heure du serveur était décalée de plusieurs heures.

**Cause :** la VM était sur le fuseau du Pacifique.

**Solution :** `tzutil /s "Romance Standard Time"`, puis synchronisation NTP sur `0.fr.pool.ntp.org` et `1.fr.pool.ntp.org` avec `w32tm`.

**Ce que j'en retiens :** Kerberos refuse les connexions au-delà de 5 minutes d'écart. L'heure du contrôleur de domaine, ce n'est pas un détail.

### Commande PowerShell coupée sur plusieurs lignes

**Symptôme :** erreur de PowerShell sur une commande longue tapée sur plusieurs lignes avec `^`.

**Cause :** `^` est le caractère de continuation de l'invite de commandes (cmd), pas de PowerShell.

**Solution :** utiliser l'accent grave `` ` `` en fin de ligne, ou tout écrire sur une seule ligne.

**Ce que j'en retiens :** cmd et PowerShell ne sont pas le même langage, même s'ils se ressemblent.

### Clavier qui ne tapait pas les bons caractères

**Symptôme :** dans les VM, la virgule, le point et certains symboles ne sortaient pas où je les attendais.

**Cause :** Windows avait activé la disposition « French (Standard, AZERTY) », qui est la nouvelle norme AFNOR, alors que mon clavier est un AZERTY classique.

**Solution :** passage sur la disposition Legacy (0000040C) en PowerShell avec `Set-WinUserLanguageList`, puis copie du réglage vers l'écran de connexion et les nouveaux comptes avec `Copy-UserInternationalSettingsToSystem`. J'ai vérifié avec le clavier visuel (`osk`).

**Ce que j'en retiens :** quand un mot de passe est refusé sans raison, je vérifie d'abord la disposition du clavier.

### CLIENT01 refusait de rejoindre le domaine

**Symptôme :** « The user name or password is incorrect » au moment de joindre `lab.local`.

**Cause :** je tapais `LAB\Administrateur`, alors que mon serveur est en anglais. Le compte s'appelle `LAB\Administrator`.

**Solution :** vérifier le nom réel avec `whoami` sur DC01, puis joindre avec `LAB\Administrator`. J'ai renommé le PC en CLIENT01 dans la même opération.

**Ce que j'en retiens :** les noms des comptes et groupes intégrés changent avec la langue de Windows.

### Conflit d'adresse entre deux VM

**Symptôme :** ma VM Linux d'un ancien TP et le WAN de FW01 avaient la même adresse, 192.168.65.130.

**Cause :** les deux reçoivent leur adresse du DHCP du NAT de VMware.

**Solution :** je n'allume jamais les deux en même temps.

**Ce que j'en retiens :** deux machines avec la même adresse, c'est des pannes aléatoires des deux côtés.

### Identifiant déjà utilisé

**Symptôme :** « The user logon name you have chosen is already in use in this enterprise » en créant un compte de test.

**Cause :** j'avais essayé de créer un compte avec un identifiant qui existait déjà dans une autre OU.

**Solution :** un identifiant différent.

**Ce que j'en retiens :** l'identifiant est unique dans tout le domaine, pas seulement dans une OU. Un compte est rangé dans une seule OU, et pour lui donner plusieurs rôles, on le met dans plusieurs groupes.

### Mot de passe refusé à la création d'Alice

**Symptôme :** « Unable to update the password. The value provided does not meet the length, complexity, or history requirements ».

**Cause :** mot de passe trop simple pour la politique du domaine (complexité, et il ne doit pas contenir le nom de la personne).

**Solution :** un mot de passe temporaire qui respecte les règles, avec « changer à la prochaine connexion ».

**Ce que j'en retiens :** ces règles viennent de la Default Domain Policy.

### « Name Not Found » sur Domain Admins

**Symptôme :** en ajoutant `LAB\Domain Admins` dans un droit de la GPO de tiering, Windows ne trouvait pas le groupe.

**Cause :** un espace en trop à la fin du nom. Le message l'affichait entre guillemets, `"LAB\Domain Admins "`.

**Solution :** retaper le nom sans l'espace. Depuis, j'utilise Browse puis Check Names avec le début du nom, ça évite les fautes de frappe.

**Ce que j'en retiens :** lire le message d'erreur en entier, la réponse était dedans.

### Un réglage de la GPO pas enregistré

**Symptôme :** « Deny log on locally » affichait toujours Not Defined.

**Cause :** à cause de l'erreur précédente, j'avais fermé la fenêtre sans valider.

**Solution :** refaire le réglage et vérifier dans la colonne Policy Setting.

**Ce que j'en retiens :** après chaque réglage, je regarde la liste pour confirmer qu'il est bien pris.

### Le tiering ne bloquait rien

**Symptôme :** après `gpupdate /force`, je pouvais encore me connecter sur CLIENT01 avec le compte T0.

**Cause :** j'avais lancé `gpupdate` sur DC01. DC01 stocke les GPO, mais il n'applique que les siennes. CLIENT01 n'avait encore rien reçu.

**Solution :** `gpupdate /force` sur CLIENT01, puis redémarrage. Le compte T0 est bien refusé.

**Ce que j'en retiens :** une GPO se rafraîchit sur la machine qui doit la recevoir. Pour vérifier : `gpresult /r` sur le client.

### Le groupe T2 n'apparaissait pas dans les admins du PC

**Symptôme :** `net localgroup Administrators` sur CLIENT01 ne listait pas `LAB\GG_T2_Admins_Postes`. (Au passage, `net localgroup Administrateurs` ne marche pas, mon Windows 11 est en anglais.)

**Cause :** dans la préférence de la GPO, le nom du groupe avait été tapé à la main en français, « Administrateurs (intégré) ». Windows cherchait un groupe qui porte exactement ce nom et n'en trouvait pas.

**Solution :** choisir « Administrators (built-in) » dans la liste déroulante. Cette option désigne le groupe par son identifiant, quelle que soit la langue du PC.

**Ce que j'en retiens :** pour un groupe intégré, toujours choisir dans la liste. Et l'onglet Settings d'une GPO dans `gpmc.msc` permet de relire tout son contenu d'un coup.

### Fichiers en .csv.txt et .ps1.csv

**Symptôme :** PowerShell ne trouvait pas mon script, « is not recognized as the name of a cmdlet ».

**Cause :** Windows cache les extensions. Mon CSV s'appelait en réalité `nouveaux.csv.txt`, et mon script `creer-comptes.ps1.csv`.

**Solution :** affichage des extensions dans l'Explorateur (View, Show, File name extensions), puis `Rename-Item`.

**Ce que j'en retiens :** je garde les extensions affichées en permanence. `dir` montre le vrai nom.

### Le script plantait à la relance

**Symptôme :** « The specified account already exists » pour chaque salarié, alors que le script affichait quand même « Compte cree ».

**Cause :** les comptes avaient déjà été créés au premier lancement. Le script ne vérifiait rien et affichait son message même en cas d'échec.

**Solution :** une deuxième version qui vérifie si le compte existe avant de le créer, gère les erreurs avec `try` et `catch`, et nettoie les accents des identifiants.

**Ce que j'en retiens :** un script doit pouvoir être relancé sans rien casser (on dit idempotent). Et un message de réussite n'est pas une preuve, je vérifie dans l'annuaire.
