# creer-comptes.ps1
# Cree les comptes des nouveaux salaries a partir d'un fichier CSV (Prenom;Nom;Service)
# Chaque compte est range dans l'OU de son service et ajoute au groupe GG_<Service>.
# Le script peut etre relance sans risque : les comptes deja existants sont ignores.

Import-Module ActiveDirectory

$fichierCsv = "C:\Scripts\nouveaux.csv"
$domaine    = "DC=lab,DC=local"

# Le mot de passe temporaire est demande au lancement, il n'est jamais ecrit dans le script
$motDePasse = Read-Host "Mot de passe temporaire des nouveaux comptes" -AsSecureString

# Garde une trace de tout ce qui s'affiche, avec la date
Start-Transcript -Path "C:\Scripts\journal-creation.txt" -Append

$salaries = Import-Csv -Path $fichierCsv -Delimiter ";" -Encoding UTF8

foreach ($s in $salaries) {

    # Identifiant : premiere lettre du prenom + nom, sans accents, sans espaces, en minuscules
    $brut       = $s.Prenom.Substring(0,1) + $s.Nom
    $sansAccent = $brut.Normalize("FormD") -replace '\p{Mn}', ''
    $login      = ($sansAccent -replace '[^a-zA-Z0-9]', '').ToLower()

    # Si le compte existe deja, on passe au suivant
    if (Get-ADUser -Filter "SamAccountName -eq '$login'") {
        Write-Warning "$login existe deja, ignore"
        continue
    }

    $parametres = @{
        Name                  = "$($s.Prenom) $($s.Nom)"
        GivenName             = $s.Prenom
        Surname               = $s.Nom
        SamAccountName        = $login
        UserPrincipalName     = "$login@lab.local"
        Path                  = "OU=$($s.Service),OU=Utilisateurs,OU=LAB,$domaine"
        AccountPassword       = $motDePasse
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }

    try {
        New-ADUser @parametres -ErrorAction Stop
        Add-ADGroupMember -Identity "GG_$($s.Service)" -Members $login -ErrorAction Stop
        Write-Host "Cree : $login dans $($s.Service)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Echec pour $login : $($_.Exception.Message)"
    }
}

Stop-Transcript
