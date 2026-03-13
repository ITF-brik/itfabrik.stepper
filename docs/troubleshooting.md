# Dépannage

Accents illisibles dans CMTrace
- Utiliser `Encoding = UTF8BOM` (par défaut) ou `Unicode`.
- Recréer le fichier si déjà créé sans BOM.

CMTrace ne colore pas les lignes
- Vérifier le format XML-like (balises `<![LOG[...]]>` et attributs `time`, `date`, `type`).

Indentation non alignée
- En `Default`, l’indentation est après `[Component]`.
- En `Console`, l’indentation est avant le message.

Variable externe a `$null` dans `Invoke-Step -Parallel`
- Symptome typique: une variable attendue dans le worker arrive a `$null`, puis le traitement echoue avec un message du type `Cannot index into a null array.`.
- Cause: `Invoke-Step -Parallel` execute le `ScriptBlock` utilisateur dans un runspace/job isole. Les variables externes du scope appelant et les helpers utilisateur non recharges n'y sont pas garantis.
- Ce qui est fiable dans le worker:
  - `param($item, $index)`
  - le module ITFabrik.Stepper recharge par le worker
  - les cmdlets/commandes nativement disponibles dans ce worker
- Contournement recommande:
  - preparer toutes les donnees en amont,
  - construire un `ScriptBlock` autonome avec ses litteraux ou une logique entierement derivable depuis l'item,
  - recuperer ensuite les erreurs via l'arbre des steps retourne par `Invoke-Step -PassThru`.
