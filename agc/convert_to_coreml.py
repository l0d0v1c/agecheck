#!/usr/bin/env python3
"""
Script de conversion du modèle CLIP vers Core ML pour iOS
Crée un modèle optimisé pour la prédiction d'âge sur mobile
"""

import os
import torch
import coremltools as ct
import numpy as np
from PIL import Image
import clip
from pathlib import Path
from transformers import CLIPProcessor, CLIPModel

def create_age_prediction_model():
    """
    Crée un modèle simplifié pour la prédiction d'âge
    en utilisant CLIP comme extracteur de features
    """

    device = "cpu"  # Force CPU pour la conversion
    print(f"Utilisation du device: {device}")

    # Chargement du modèle CLIP local
    script_dir = Path(__file__).parent
    model_path = script_dir / "clip-ViT-B-32"

    if model_path.exists():
        print(f"Chargement du modèle local depuis: {model_path}")
        try:
            processor = CLIPProcessor.from_pretrained(str(model_path))
            model = CLIPModel.from_pretrained(str(model_path)).to(device)
            use_transformers = True
        except Exception as e:
            print(f"Erreur avec transformers, utilisation de CLIP standard: {e}")
            model, preprocess = clip.load("ViT-B/32", device=device, jit=False)
            use_transformers = False
    else:
        print(f"Modèle local non trouvé, utilisation de CLIP standard...")
        model, preprocess = clip.load("ViT-B/32", device=device, jit=False)
        use_transformers = False

    model.eval()

    # Préparation des prompts textuels pour tous les âges
    ages = list(range(1, 100))
    texts = [f"this person is {age} years old" for age in ages]

    # Encodage des prompts selon le type de modèle
    with torch.no_grad():
        if use_transformers:
            text_inputs = processor(text=texts, return_tensors="pt", padding=True, truncation=True)
            text_outputs = model.get_text_features(**text_inputs)
            text_features = text_outputs
        else:
            prompts = clip.tokenize(texts).to(device)
            text_features = model.encode_text(prompts)

        # Normalisation
        text_features = text_features / text_features.norm(dim=-1, keepdim=True)

    class AgePredictor(torch.nn.Module):
        def __init__(self, clip_model, text_features, use_transformers=False):
            super().__init__()
            self.clip_model = clip_model
            self.text_features = text_features
            self.use_transformers = use_transformers

        def forward(self, image):
            # Extraction des features d'image
            if self.use_transformers:
                image_features = self.clip_model.vision_model(pixel_values=image)[1]
                image_features = self.clip_model.visual_projection(image_features)
            else:
                image_features = self.clip_model.encode_image(image)

            # Normalisation
            image_features = image_features / image_features.norm(dim=-1, keepdim=True)

            # Calcul de similarité avec tous les âges
            similarity = (100.0 * image_features @ self.text_features.T).softmax(dim=-1)

            # Retour des probabilités pour chaque âge
            return similarity

    # Création du modèle wrapper
    age_predictor = AgePredictor(model, text_features, use_transformers)

    return age_predictor, processor if use_transformers else preprocess, use_transformers

def convert_to_coreml():
    """
    Convertit le modèle CLIP vers Core ML
    """
    print("Création du modèle de prédiction d'âge...")
    model, preprocessor, use_transformers = create_age_prediction_model()

    # Taille d'image standard pour CLIP
    if use_transformers:
        # Pour transformers, utiliser les dimensions du processeur
        image_size = 224
        input_shape = (1, 3, image_size, image_size)
    else:
        # Pour CLIP standard
        image_size = 224
        input_shape = (1, 3, image_size, image_size)

    print(f"Taille d'entrée: {input_shape}")

    # Création d'une image exemple pour le tracing
    example_input = torch.randn(input_shape)

    print("Tracing du modèle...")
    with torch.no_grad():
        traced_model = torch.jit.trace(model, example_input)

    print("Conversion vers Core ML...")

    # Conversion avec Core ML Tools
    coreml_model = ct.convert(
        traced_model,
        inputs=[ct.ImageType(
            name="image",
            shape=input_shape,
            scale=1.0/255.0,  # Normalisation 0-1
            bias=[0, 0, 0],   # Pas de bias
            color_layout=ct.colorlayout.RGB
        )],
        outputs=[ct.TensorType(name="age_probabilities")],
        compute_units=ct.ComputeUnit.ALL
    )

    # Métadonnées du modèle
    coreml_model.short_description = "Prédicteur d'âge basé sur CLIP"
    coreml_model.input_description["image"] = "Image d'entrée (224x224 RGB)"
    coreml_model.output_description["age_probabilities"] = "Probabilités pour chaque âge (1-99 ans)"

    # Sauvegarde
    output_path = Path(__file__).parent / "AgePredictor.mlpackage"
    coreml_model.save(str(output_path))

    print(f"✅ Modèle Core ML sauvegardé: {output_path}")
    print(f"📏 Taille du fichier: {output_path.stat().st_size / (1024*1024):.1f} MB")

    return output_path

def test_coreml_model(model_path):
    """
    Test rapide du modèle Core ML
    """
    import coremltools as ct

    print(f"\nTest du modèle: {model_path}")

    try:
        # Chargement du modèle
        model = ct.models.MLModel(str(model_path))

        # Image de test
        test_image = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
        test_image_pil = Image.fromarray(test_image)

        # Prédiction
        prediction = model.predict({"image": test_image_pil})

        # Analyse des résultats
        probabilities = prediction["age_probabilities"][0]
        predicted_age = np.argmax(probabilities) + 1  # +1 car les âges commencent à 1
        confidence = probabilities[predicted_age - 1]

        print(f"✅ Test réussi!")
        print(f"🎯 Âge prédit: {predicted_age} ans")
        print(f"📊 Confiance: {confidence:.2%}")

        return True

    except Exception as e:
        print(f"❌ Erreur lors du test: {e}")
        return False

if __name__ == "__main__":
    try:
        # Installation des dépendances si nécessaire
        try:
            import coremltools
        except ImportError:
            print("Installation de coremltools...")
            os.system("pip install coremltools")
            import coremltools

        # Conversion
        model_path = convert_to_coreml()

        # Test
        if test_coreml_model(model_path):
            print(f"\n🎉 Conversion réussie! Le modèle est prêt pour iOS.")
            print(f"📁 Copiez le fichier {model_path} dans votre projet Xcode.")
        else:
            print(f"\n⚠️ La conversion s'est terminée mais le test a échoué.")

    except Exception as e:
        print(f"❌ Erreur lors de la conversion: {e}")
        import traceback
        traceback.print_exc()