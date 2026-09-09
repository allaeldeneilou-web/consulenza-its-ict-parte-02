# Piano di rollback

## Scopo

Ripristinare la versione precedente del portale se una pubblicazione su `main`
introduce un errore visibile o funzionale.

Il rollback applicativo avviene tramite Git: non si modifica manualmente il sito
pubblicato e non si ricostruisce un artefatto diverso da quello verificato.

## Procedura

1. Identificare il commit attualmente online e quello precedente funzionante:
   `git log --oneline --decorate -5`.
2. Creare un branch dedicato dalla versione corrente:
   `git switch -c rollback/<descrizione-breve>`.
3. Creare un revert del commit difettoso:
   `git revert <sha-del-commit-difettoso> --no-edit`.
4. Eseguire localmente `npm ci`, `npm test` e `npm run build`.
5. Pubblicare il branch tramite pull request e attendere il passaggio della CI.
6. Unire la pull request in `main`: `release.yml` ricostruirà e pubblicherà
   l'artefatto dopo l'approvazione dell'environment `github-pages`.
7. Verificare la pagina online e annotare commit, orari e persona che ha
   approvato il rilascio.

## Misurazione

- Obiettivo operativo: ripristino online entro **10 minuti** dalla decisione.
- Tempo misurato in locale per creare il revert e completare i controlli: da
  rilevare durante la prima esercitazione.
- Tempo del deploy Pages e dell'approvazione: da rilevare con un run reale del
  workflow, perché dipende da GitHub e dall'approvatore.

La misura va registrata dopo una prova reale: un rollback mai esercitato è una
procedura ipotetica, non una capacità operativa.
