# Verifica adattamento risoluzione

Le modifiche mantengono FMX e Delphi 10 Seattle.

La camera in `Unit1.SetupCameraTopView` inquadra tutti i contenuti del
dashboard, considerando sia la larghezza sia l'altezza del viewport.
Le proporzioni restano costanti; con aspect ratio differenti rimane spazio
libero intorno alla scena. Se in futuro vengono spostate le griglie o aggiunti
elementi esterni, aggiornare i quattro limiti `SceneLeft`, `SceneRight`,
`SceneBottom` e `SceneTop`.

`u_ResponsiveLayout` riduce proporzionalmente i pannelli dei dialoghi quando
non entrano nello spazio disponibile, mantenendo il fondo a tutta finestra.
Usa le dimensioni logiche FMX, senza moltiplicarle nuovamente per i DPI.
Lo scaling viene ricalcolato anche mentre una finestra viene ridimensionata.

## Test automatici

Aprire `ResolutionChecks.dpr` con Delphi 10 e compilarlo/eseguirlo, oppure
eseguire da questa cartella in PowerShell:

```powershell
& 'C:\Program Files (x86)\Embarcadero\Studio\17.0\bin\dcc32.exe' '-B' '-Q' '-NSSystem' '-U..' '-I..' '-R..' 'ResolutionChecks.dpr'
.\ResolutionChecks.exe
```

I test controllano camera, centratura, bordi e proporzioni dei pannelli,
ridimensionamenti ripetuti e reset delle coordinate X/Z delle ragazze.
Dimensioni verificate: 640x480, 800x600, 1024x768, 1280x1024,
1366x768, 1920x1080, 2560x1440, 3440x1440, 3840x2160, 1080x1920.
Non modificano i salvataggi dell'applicazione.

## Anteprima separata

`ResolutionPreview.dpr` usa il dashboard reale e genera 40 nomi sintetici
nella sottocartella `preview-data`, senza caricare i salvataggi o la licenza
di produzione. Le interazioni dell'anteprima scrivono solo in tale cartella.

- F1: area client 640x480.
- F2: area client 1024x768.
- F3: area client 1280x720.
- F5: dialogo di inserimento.
- F6: dialogo durata.
- F7: dialogo attivita.

L'eseguibile completo e stato compilato con Delphi 10 Seattle ed EurekaLog
in `tests/build/LapDancePrive.exe`. Per la normale compilazione dall'IDE
aprire il progetto originale `LapDancePrive.dproj`.

Su aree molto piccole o molto strette tutto rimane inquadrato, ma testo e
pulsanti diventano inevitabilmente piccoli. La verifica automatica delle
dimensioni non sostituisce la prova su monitor con DPI Windows differenti.
