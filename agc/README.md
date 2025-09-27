# Prédicteur d'Âge Autonome avec CLIP

Ce script utilise le modèle CLIP ViT-B/32 pour prédire l'âge d'une personne à partir d'une photo.

## Installation

1. Installez les dépendances :
```bash
pip install -r requirements.txt
```

## Utilisation

### Utilisation basique
```bash
python age_predictor.py chemin/vers/image.jpg
```

### Utilisation avec mode verbeux
```bash
python age_predictor.py chemin/vers/image.jpg --verbose
```

### Exemple de sortie
```
Utilisation du device: cpu
Chargement du modèle CLIP ViT-B/32...
Préparation des prompts textuels...
Prédicteur d'âge initialisé avec succès!

Analyse de l'image: photo.jpg

🎯 Âge prédit: 25 ans
📊 Confiance: 15.23%

📋 Top 3 des prédictions:
  1. 25 ans (confiance: 15.23%)
  2. 24 ans (confiance: 12.45%)
  3. 26 ans (confiance: 11.87%)
```

## Fonctionnement

Le script :
1. Charge le modèle CLIP ViT-B/32
2. Prépare des prompts textuels pour chaque âge (1-99 ans)
3. Encode l'image et calcule la similarité avec chaque prompt
4. Retourne l'âge le plus probable

## Configuration requise

- Python 3.7+
- PyTorch
- CLIP (OpenAI)
- PIL/Pillow
- NumPy

## Notes

- Utilise le modèle local dans `../clip-ViT-B-32` par défaut
- Fallback vers le téléchargement automatique si le modèle local n'est pas trouvé
- Utilise CUDA si disponible, sinon CPU
- Supporte les formats d'image courants (JPG, PNG, etc.)
- Compatible avec les modèles transformers et CLIP standard