#!/usr/bin/env python3
"""
Crée un modèle Core ML simplifié pour tester l'intégration iOS
"""

import torch
import torch.nn as nn
import coremltools as ct
import numpy as np
from pathlib import Path

class SimpleAgePredictor(nn.Module):
    """Modèle très simple pour tester l'intégration"""
    def __init__(self):
        super().__init__()
        # Un modèle très simple qui prend une image et retourne des probabilités d'âge
        self.flatten = nn.Flatten()
        self.fc1 = nn.Linear(224 * 224 * 3, 512)
        self.relu1 = nn.ReLU()
        self.fc2 = nn.Linear(512, 128)
        self.relu2 = nn.ReLU()
        self.fc3 = nn.Linear(128, 99)  # 99 âges (1-99)
        self.softmax = nn.Softmax(dim=1)

    def forward(self, x):
        x = self.flatten(x)
        x = self.relu1(self.fc1(x))
        x = self.relu2(self.fc2(x))
        x = self.fc3(x)
        return self.softmax(x)

def create_simple_model():
    """Crée un modèle Core ML simple pour test"""
    print("🔨 Création d'un modèle simple pour test...")

    # Créer le modèle
    model = SimpleAgePredictor()
    model.eval()

    # Exemple d'entrée
    example_input = torch.randn(1, 3, 224, 224)

    print("🔄 Tracing du modèle...")
    with torch.no_grad():
        traced_model = torch.jit.trace(model, example_input)

    print("🔄 Conversion vers Core ML...")
    coreml_model = ct.convert(
        traced_model,
        inputs=[ct.ImageType(
            name="image",
            shape=(1, 3, 224, 224),
            scale=1.0/255.0,
            bias=[0, 0, 0],
            color_layout=ct.colorlayout.RGB
        )],
        outputs=[ct.TensorType(name="age_probabilities")],
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS17
    )

    # Métadonnées
    coreml_model.short_description = "Modèle simple de prédiction d'âge"
    coreml_model.input_description["image"] = "Image d'entrée (224x224 RGB)"
    coreml_model.output_description["age_probabilities"] = "Probabilités pour chaque âge (1-99 ans)"

    # Sauvegarde
    output_path = Path(__file__).parent / "SimpleAgeModel.mlpackage"
    coreml_model.save(str(output_path))

    print(f"✅ Modèle simple sauvegardé: {output_path}")

    # Test rapide
    test_image = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    from PIL import Image
    test_image_pil = Image.fromarray(test_image)

    try:
        prediction = coreml_model.predict({"image": test_image_pil})
        probabilities = prediction["age_probabilities"][0]
        predicted_age = np.argmax(probabilities) + 1
        confidence = probabilities[predicted_age - 1]

        print(f"✅ Test réussi - Âge prédit: {predicted_age} ans (confiance: {confidence:.2%})")
        return output_path
    except Exception as e:
        print(f"❌ Erreur de test: {e}")
        return None

if __name__ == "__main__":
    create_simple_model()