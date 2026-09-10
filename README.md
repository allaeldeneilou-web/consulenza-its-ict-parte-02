# Portale corsi ITS

Repository del laboratorio di consulenza ITS-ICT. Il progetto parte da un
portale statico funzionante ma fragile e lo porta verso un processo ripetibile:

```text
codice -> test -> build -> artefatto -> approvazione -> pubblicazione
```

L'obiettivo non e' soltanto usare GitHub Actions o Terraform. E' rendere
esplicito chi puo' cambiare cosa, quale versione e' stata verificata e come si
torna indietro quando una modifica produce un errore.

## Struttura

```text
.
|-- data/corsi.json                 dati sorgente del portale
|-- src/build.mjs                   generatore statico Node.js
|-- site/style.css                  stile sorgente
|-- dist/                           artefatto generato
|-- test/                            test applicativi
|-- ci/nessun-segreto.sh            controllo locale sui segreti
|-- config/impostazioni.esempio.txt esempio senza valori sensibili
|-- infra/tf/                        infrastruttura Terraform
|-- .github/workflows/ci.yml        quality gate sulle pull request
|-- .github/workflows/release.yml   build e pubblicazione su GitHub Pages
|-- PERIZIA.md                      fatti, conseguenze e rimedi
|-- ROLLBACK.md                     procedura di ripristino
```

## Comandi locali

```bash
npm ci
bash ci/nessun-segreto.sh
npm test
npm run build
```

La build legge `data/corsi.json` e genera `dist/index.html` e
`dist/versione.json`. `npm ci` usa il lockfile e rende l'installazione
riproducibile; `npm test` verifica sia gli artefatti sia il totale di 320 ore.

Per Terraform:

```bash
terraform -chdir=infra/tf fmt -check -recursive
terraform -chdir=infra/tf init -backend=false
terraform -chdir=infra/tf validate
```

L'inizializzazione con `-backend=false` prepara i provider e controlla la
configurazione senza leggere o modificare lo stato remoto.

## Sicurezza e infrastruttura

Il bucket S3 e' gestito come codice. Il codice attuale:

- blocca ACL e policy pubbliche;
- non concede `s3:*` a `Principal: "*"`;
- abilita versioning;
- abilita server-side encryption AES256;
- cifra DynamoDB con una KMS Customer Managed Key a rotazione automatica;
- separa gli ambienti tramite la variabile Terraform `environment`.

La bucket policy pubblica non viene ristretta: viene rimossa. Il permesso di
pubblicare deve appartenere all'identita' della pipeline, con un ruolo e una
policy minima, non a una regola pubblica attaccata alla risorsa.

## Pipeline

`ci.yml` parte sulle pull request verso `main` e controlla:

1. installazione riproducibile;
2. secret scan;
3. test e build Node;
4. formattazione e validazione Terraform;
5. scansione Checkov dell'IaC.

`release.yml` parte dopo un push su `main` oppure manualmente. Il job
`costruisci` esegue test e build e carica l'artefatto Pages. Il job `pubblica`
lo usa senza ricostruirlo e dichiara l'environment `github-pages`, dove GitHub
puo' richiedere l'approvazione di un'altra persona.

Questa separazione applica il principio `build once, deploy many`: il pacchetto
pubblicato e' lo stesso che ha superato i controlli.

## GitHub da configurare

Per chiudere le evidenze che vivono fuori dai file servono impostazioni GitHub:

- ruleset su `main` con pull request obbligatoria;
- status check della CI obbligatorio;
- Pages con sorgente GitHub Actions;
- environment `github-pages` con almeno un reviewer richiesto.

Queste impostazioni non sono deducibili dal repository: vanno verificate nella
console e documentate con gli screenshot richiesti dal laboratorio.

Il ruleset `proteggi-main` e' attivo sulla repository e impedisce aggiornamenti
diretti a `main`. I check della CI verranno aggiunti al ruleset dopo la prima
pull request, quando GitHub avra' registrato i relativi risultati.

## Rollback

Il rollback e' un revert Git su un branch dedicato, seguito da pull request,
CI e nuovo rilascio approvato. La procedura e' in [ROLLBACK.md](ROLLBACK.md).
Il documento distingue l'obiettivo di 10 minuti dalla misura reale: il tempo
del deploy Pages va cronometrato durante una prova effettiva.

## Perizia

[PERIZIA.md](PERIZIA.md) contiene otto constatazioni formulate come fatto,
conseguenza, rimedio e stato. La perizia non e' decorazione: collega le scelte
tecniche al rischio operativo del cliente.
