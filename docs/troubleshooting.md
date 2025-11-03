# Dépannage

Accents illisibles dans CMTrace
- Utiliser `Encoding = UTF8BOM` (par défaut) ou `Unicode`.
- Recréer le fichier si déjà créé sans BOM.

CMTrace ne colore pas les lignes
- Vérifier le format XML-like (balises `<![LOG[...]]>` et attributs `time`, `date`, `type`).

Indentation non alignée
- En `Default`, l’indentation est après `[Component]`.
- En `Console`, l’indentation est avant le message.

