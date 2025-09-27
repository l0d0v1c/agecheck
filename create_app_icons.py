#!/usr/bin/env python3
"""
Script pour convertir l'icône SVG en icônes Apple iOS
Génère toutes les tailles nécessaires pour AppIcon.appiconset
"""

import os
import subprocess
from pathlib import Path

# Tailles d'icônes requises pour iOS
ICON_SIZES = [
    # iPhone App Icon
    (60, 2, "iphone"),      # 120x120
    (60, 3, "iphone"),      # 180x180

    # iPad App Icon
    (76, 1, "ipad"),        # 76x76
    (76, 2, "ipad"),        # 152x152
    (83.5, 2, "ipad"),      # 167x167

    # App Store
    (1024, 1, "ios-marketing"),  # 1024x1024

    # Settings/Spotlight
    (29, 2, "iphone"),      # 58x58
    (29, 3, "iphone"),      # 87x87
    (40, 2, "iphone"),      # 80x80
    (40, 3, "iphone"),      # 120x120

    # iPad Settings/Spotlight
    (29, 1, "ipad"),        # 29x29
    (29, 2, "ipad"),        # 58x58
    (40, 1, "ipad"),        # 40x40
    (40, 2, "ipad"),        # 80x80

    # Notification
    (20, 2, "iphone"),      # 40x40
    (20, 3, "iphone"),      # 60x60
    (20, 1, "ipad"),        # 20x20
    (20, 2, "ipad"),        # 40x40
]

def check_rsvg_convert():
    """Vérifier si rsvg-convert est disponible"""
    try:
        subprocess.run(["rsvg-convert", "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def install_rsvg_convert():
    """Installer rsvg-convert via Homebrew"""
    print("📦 Installation de rsvg-convert...")
    try:
        subprocess.run(["brew", "install", "librsvg"], check=True)
        return True
    except subprocess.CalledProcessError:
        print("❌ Erreur d'installation. Assurez-vous que Homebrew est installé.")
        return False

def convert_svg_to_png(svg_path, output_path, size):
    """Convertir SVG en PNG avec la taille spécifiée"""
    cmd = [
        "rsvg-convert",
        "-w", str(size),
        "-h", str(size),
        "-o", str(output_path),
        str(svg_path)
    ]

    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur de conversion: {e}")
        return False

def create_contents_json():
    """Créer le fichier Contents.json pour Xcode"""
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    for size, scale, idiom in ICON_SIZES:
        pixel_size = int(size * scale)
        filename = f"AppIcon-{size}@{scale}x.png"

        image_entry = {
            "filename": filename,
            "idiom": idiom,
            "scale": f"{scale}x",
            "size": f"{size}x{size}"
        }

        contents["images"].append(image_entry)

    return contents

def main():
    print("🎨 Création des icônes Apple pour l'application Age Predictor...")

    # Vérifier les prérequis
    if not check_rsvg_convert():
        print("⚠️ rsvg-convert non trouvé. Installation en cours...")
        if not install_rsvg_convert():
            print("❌ Impossible d'installer rsvg-convert.")
            print("💡 Installez-le manuellement: brew install librsvg")
            return False

    # Chemins
    script_dir = Path(__file__).parent
    svg_path = script_dir / "age_icon.svg"

    if not svg_path.exists():
        print(f"❌ Fichier SVG non trouvé: {svg_path}")
        return False

    # Créer le dossier AppIcon.appiconset
    icons_dir = script_dir / "age" / "age" / "Assets.xcassets" / "AppIcon.appiconset"
    icons_dir.mkdir(parents=True, exist_ok=True)

    print(f"📁 Dossier de sortie: {icons_dir}")

    # Générer toutes les tailles d'icônes
    success_count = 0
    total_count = len(ICON_SIZES)

    for size, scale, idiom in ICON_SIZES:
        pixel_size = int(size * scale)
        filename = f"AppIcon-{size}@{scale}x.png"
        output_path = icons_dir / filename

        print(f"🖼️ Génération: {filename} ({pixel_size}x{pixel_size})")

        if convert_svg_to_png(svg_path, output_path, pixel_size):
            success_count += 1
        else:
            print(f"❌ Échec: {filename}")

    # Créer Contents.json
    import json
    contents = create_contents_json()
    contents_path = icons_dir / "Contents.json"

    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"📝 Fichier Contents.json créé")

    # Résumé
    print(f"\n✅ Génération terminée: {success_count}/{total_count} icônes créées")

    if success_count == total_count:
        print("🎉 Toutes les icônes ont été générées avec succès!")
        print(f"📂 Icônes disponibles dans: {icons_dir}")
        print("\n💡 Prochaines étapes:")
        print("1. Ouvrir le projet Xcode")
        print("2. Les icônes sont automatiquement intégrées dans Assets.xcassets")
        print("3. Compiler et tester l'application")
    else:
        print("⚠️ Certaines icônes n'ont pas pu être générées.")

    return success_count == total_count

if __name__ == "__main__":
    main()