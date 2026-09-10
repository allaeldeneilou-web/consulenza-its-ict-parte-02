# PERIZIA - Portale corsi ITS

Owner: ITS-ICT
Technical contact: allaeldene.ilou
Binario: Terraform
Data: 09/09/2026

## Sicurezza

### S1 - Credenziali versionate nel repository
- **Fatto**: il progetto originale prevedeva `config/impostazioni.txt` per credenziali FTP e token.
- **Conseguenza**: una credenziale pubblicata in Git resta recuperabile nella storia e può consentire accessi non autorizzati.
- **Rimedio**: rimuovere il file dal tracciamento, ignorarlo con `.gitignore`, ruotare le credenziali eventualmente esposte e bloccare i pattern noti in CI.
- **Stato**: chiuso lato repository; la rotazione resta un'azione del cliente se le credenziali erano reali.

### S2 - Bucket S3 aperto in scrittura a chiunque
- **Fatto**: la bucket policy originale concedeva `s3:*` a `Principal: "*"`.
- **Conseguenza**: chiunque su internet poteva sovrascrivere o cancellare il sito.
- **Rimedio**: eliminare la bucket policy pubblica e attivare tutte le impostazioni di blocco degli accessi pubblici; la pipeline userà un'identità AWS dedicata.
- **Stato**: chiuso nel codice Terraform.

### S3 - Il bucket non aveva cifratura esplicita
- **Fatto**: il bucket non dichiarava una configurazione di server-side encryption.
- **Conseguenza**: la protezione dei dati dipendeva da impostazioni esterne e non era verificabile dal codice.
- **Rimedio**: configurare la cifratura server-side AES256 come risorsa IaC.
- **Stato**: chiuso nel codice Terraform.

### S4 - DynamoDB usava una cifratura senza chiave sotto controllo del cliente
- **Fatto**: la tabella aveva la cifratura attiva, ma senza `kms_key_arn`; AWS usava quindi una chiave AWS-owned.
- **Conseguenza**: il cliente non poteva governare direttamente rotazione, policy e audit della chiave secondo i propri requisiti.
- **Rimedio**: creare una KMS Customer Managed Key con rotazione automatica, key policy esplicita limitata all'account e ARN passato alla tabella DynamoDB.
- **Stato**: chiuso nel codice Terraform.

## Affidabilita

### A1 - Mancanza di versioning sul bucket
- **Fatto**: il bucket non conservava in modo sistematico le versioni precedenti degli artefatti pubblicati.
- **Conseguenza**: un deploy errato o una cancellazione rendevano più difficile ripristinare il sito.
- **Rimedio**: abilitare il versioning S3 per ogni ambiente; il rollback potrà selezionare una versione precedente.
- **Stato**: chiuso nel codice Terraform.

### A2 - Dipendenze non bloccate
- **Fatto**: il progetto originale non aveva un `package-lock.json`.
- **Conseguenza**: due build eseguite in momenti diversi potevano installare dipendenze diverse.
- **Rimedio**: generare e versionare il lockfile, quindi usare `npm ci` nella pipeline.
- **Stato**: chiuso.

### A3 - Totale ore errato non rilevato automaticamente
- **Fatto**: il portale poteva pubblicare un totale ore non coerente con i corsi presenti.
- **Conseguenza**: il cliente poteva mostrare agli studenti un dato operativo sbagliato.
- **Rimedio**: aggiungere test automatici sul numero dei corsi, sul totale corretto e sull'assenza del valore errato.
- **Stato**: chiuso; i test devono restare un gate della CI.

## Operabilita

### O1 - Pubblicazione manuale legata a una persona
- **Fatto**: il deploy originale dipendeva da comandi eseguiti sul computer di un operatore.
- **Conseguenza**: il processo non era ripetibile e diventava fragile in caso di assenza o cambio del fornitore.
- **Rimedio**: automatizzare build, controlli e pubblicazione con GitHub Actions e un ambiente protetto.
- **Stato**: in lavorazione nel livello 3.

### O2 - Nessun registro operativo della pubblicazione
- **Fatto**: non esisteva un workflow che registrasse chi aveva pubblicato quale build e con quale esito.
- **Conseguenza**: diagnosi e responsabilita operativa dipendevano dalla memoria delle persone.
- **Rimedio**: usare run GitHub Actions, artefatti immutabili e approvazione esplicita dell'ambiente di rilascio.
- **Stato**: in lavorazione nel livello 3.
