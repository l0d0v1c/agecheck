#!/usr/bin/env python3
"""
Script de configuration et test du prédicteur d'âge
"""

import subprocess
import sys
import os


def install_requirements():
    """Installe les dépendances requises"""
    print("Installation des dépendances...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✅ Dépendances installées avec succès!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors de l'installation: {e}")
        return False


def test_imports():
    """Teste que tous les modules nécessaires peuvent être importés"""
    print("\nTest des imports...")
    modules = ['torch', 'clip', 'PIL', 'numpy']

    for module in modules:
        try:
            __import__(module)
            print(f"✅ {module}")
        except ImportError as e:
            print(f"❌ {module}: {e}")
            return False

    print("✅ Tous les modules sont disponibles!")
    return True


def check_torch_device():
    """Vérifie la disponibilité CUDA"""
    try:
        import torch
        print(f"\nDevice PyTorch disponible:")
        print(f"  - CPU: Oui")
        print(f"  - CUDA: {'Oui' if torch.cuda.is_available() else 'Non'}")
        if torch.cuda.is_available():
            print(f"  - GPU: {torch.cuda.get_device_name(0)}")
    except Exception as e:
        print(f"❌ Erreur lors de la vérification PyTorch: {e}")


def main():
    print("🚀 Configuration du prédicteur d'âge CLIP")
    print("=" * 50)

    # Installation des dépendances
    if not install_requirements():
        print("\n❌ Échec de l'installation des dépendances")
        return False

    # Test des imports
    if not test_imports():
        print("\n❌ Échec du test des imports")
        return False

    # Vérification des devices
    check_torch_device()

    print("\n" + "=" * 50)
    print("🎉 Configuration terminée avec succès!")
    print("\nVous pouvez maintenant utiliser le prédicteur:")
    print("  python age_predictor.py chemin/vers/image.jpg")

    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)