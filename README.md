# Local AI Library

Application macOS SwiftUI pour inventorier des modèles IA locaux et repérer les configurations Codex/Claude. Le projet explore les caches Hugging Face/Ollama, GGUF/Safetensors/BIN, les métadonnées, la détection de runtimes et les dossiers de scan personnalisés.

Sources et tests récupérés, reconstruction bloquée par la licence Xcode non acceptée. Aucun ancien bundle redistribué comme build nouvellement vérifié, aucune capture fabriquée ou application signée fournie.

## Compiler et lancer

macOS13+, Swift compatible avec swift-tools-version5.9, SDK Apple opérationnel. Examiner et accepter soi-même la licence Xcode si demandée, puis :

```sh
swift test
swift build
swift run LocalAILibrary
```

Aucune dépendance de package externe. Sources via GitHub Code → Download ZIP. L’application examine les racines locales de modèles/configurations ; ne pas publier chemins personnels, configurations ou captures contenant des secrets.

## Code et limites

Services séparés des vues, parseurs, enrichissement des tailles, recherche de programmes sur PATH, dossiers choisis et sélection conservés dans UserDefaults. La détection n’installe ni ne lance de runtime. Ce n’est pas un serveur d’inférence ; aucune génération IA validée.

Tests de configuration, découverte, métadonnées, parseurs et coordination avec fixtures temporaires présents. `swift test` échoue avant compilation (code69,licence Xcode), donc aucune suite actuelle déclarée passante.

## Reprendre

1. Débloquer les outils Apple et exécuter build/tests.
2. Lancer avec fixtures sans configurations personnelles ; vérifier scan,sélection,détails et ajout/retrait de racines.
3. Vérifier erreurs d’accès, liens symboliques, caches volumineux et annulation.
4. Capturer le runtime réel, puis empaqueter après validation.

Snapshot de l’état local incluant quatre fichiers Swift modifiés, source originale à `060e26ada568b5e735d92e5f257f9c3da169cb6c`, intacte. Sources/Tests/Package.swift conservés ; bundles .app,modèles,données,réglages et historique des binaires exclus. Aucune licence générale de redistribution inventée.

Voir [VERIFICATION.md](VERIFICATION.md).

## Dépôt et téléchargement

[Voir le dépôt](https://github.com/cpointis96-hue/local-ai-library) · [Télécharger les sources ZIP](https://github.com/cpointis96-hue/local-ai-library/archive/HEAD.zip). Le ZIP contient les sources et tests, sans application compilée.
