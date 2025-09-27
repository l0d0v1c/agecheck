# Guide de débogage - Application iOS Age Predictor

## Problème identifié
Le chargement du modèle Core ML semble bloqué ou très lent.

## Solutions implementées

### 1. Modèle de test simplifié
- ✅ Créé `SimpleAgeModel.mlpackage` - modèle neural network simple
- ✅ Modifié `AgePredictor.swift` pour essayer le modèle simple d'abord
- ✅ Ajouté logs de débogage détaillés

### 2. Interface de débogage
- ✅ Ajouté bouton "Vérifier modèle" dans l'interface
- ✅ Créé `ModelChecker.swift` pour diagnostiquer les problèmes

### 3. Logs de débogage
- ✅ Messages détaillés du processus de chargement
- ✅ Vérification du bundle et des ressources

## Étapes pour tester

1. **Lancer l'application dans Xcode**
   - Ouvrir `age.xcodeproj`
   - Sélectionner simulateur iPhone 16
   - Appuyer sur ▶️ (Run)

2. **Diagnostiquer le problème**
   - Si le modèle ne se charge pas, appuyer sur "Vérifier modèle"
   - Vérifier les logs dans la console Xcode

3. **Vérifier les modèles disponibles**
   - `SimpleAgeModel.mlpackage` - Modèle simple (devrait marcher)
   - `AgeModel.mlpackage` - Modèle CLIP complexe (peut être lent)

## Améliorations possibles

1. **Optimiser le modèle CLIP**
   - Réduire la taille d'entrée
   - Quantifier le modèle
   - Utiliser une version plus légère

2. **Chargement asynchrone amélioré**
   - Barre de progression
   - Chargement en arrière-plan
   - Cache du modèle

3. **Interface utilisateur**
   - Meilleur feedback de chargement
   - Messages d'erreur informatifs
   - Mode dégradé si le modèle ne charge pas

## Commandes utiles

```bash
# Compiler l'app
cd /Users/pro/github/agecheck/age
xcodebuild -scheme age -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' build

# Lancer dans le simulateur
xcrun simctl launch 904069A6-0503-4A08-8E1F-768991A0CE5F pseudoxia.age

# Voir les logs
xcrun simctl spawn 904069A6-0503-4A08-8E1F-768991A0CE5F log stream --predicate 'process == "age"'
```