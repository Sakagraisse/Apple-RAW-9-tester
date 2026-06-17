# Core Image RAW 8 vs RAW 9

Ce petit outil développe chaque fichier RAW deux fois avec `CIRAWFilter` :

- une fois avec le décodeur Core Image RAW 8 ;
- une fois avec le nouveau décodeur RAW 9 de macOS 27.

Il parcourt récursivement le dossier source, exporte des JPEG sRGB à qualité
identique et crée une galerie interactive pour comparer les deux rendus.

## Prérequis

- macOS 27 bêta ou plus récent ;
- les outils en ligne de commande Xcode 27, ou Xcode 27.

## Exécution

Depuis ce dossier :

```sh
zsh run_compare.sh
```

Par défaut, les sources sont lues dans `Sample raw` et les résultats sont écrits
dans `RAW comparison`.

Pour choisir d'autres dossiers :

```sh
zsh run_compare.sh "/chemin/vers/les/raw" "/chemin/vers/la/sortie"
```

Ouvrir ensuite `RAW comparison/index.html` dans un navigateur.

Chaque image possède un bouton `100 %`. Dans ce mode, un pixel de la photo
correspond à un pixel de l'écran. Faire glisser l'image pour se déplacer dans
les détails, puis cliquer sur `Ajusté` pour revenir à la vue complète.

Le script choisit automatiquement `version8DNG`/`version9DNG` pour les DNG et
`version8`/`version9` pour les autres formats RAW.

La galerie indique explicitement quand les deux exports sont identiques. C'est
notamment possible avec certains Apple ProRAW, dont les données ont déjà subi
une partie du pipeline photographique avant d'être enregistrées dans le DNG.

La disponibilité RAW 9 dépend aussi du modèle d'appareil et des mises à jour de
prise en charge RAW livrées par Apple. Un fichier non encore compatible est
signalé puis ignoré, sans interrompre le reste du lot.

## App graphique

Une petite app macOS SwiftUI permet d'inspecter les options RAW exposées par
`CIRAWFilter`.

```sh
./build_raw_options_app.sh
```

L'app est générée dans `.build/RAW Options.app`.

Elle accepte un ou plusieurs fichiers RAW/DNG par glisser-déposer. Le panneau de
droite permet de basculer entre RAW 8 et RAW 9, puis affiche les valeurs par
défaut du fichier sélectionné. Les options non disponibles pour la version et le
fichier courants sont grisées.

## Apple ProRAW

Apple ProRAW est un DNG linéarisé déjà dématricé et pouvant être issu de plusieurs
expositions fusionnées. Il a donc déjà bénéficié d'une grande partie du pipeline
photographique de l'iPhone avant son enregistrement.

RAW 9 peut être sélectionné pour ces fichiers, mais son nouveau modèle combinant
dématriçage et réduction du bruit peut ne rien changer aux pixels. Le générateur
marque alors la comparaison `sorties identiques`. C'est le résultat observé avec
les quatre ProRAW iPhone 17 Pro du dossier d'exemple sur macOS 27 bêta
`26A5353q`.
