#!/bin/bash

echo "🚀 Lancement de l'application iOS Age Predictor..."

# Nettoyer le build
echo "🧹 Nettoyage du build..."
cd /Users/pro/github/agecheck/age
xcodebuild clean -quiet

# Construire l'application
echo "🔨 Construction de l'application..."
xcodebuild -scheme age -destination 'platform=iOS Simulator,OS=18.6,name=iPhone 16' build -quiet

if [ $? -eq 0 ]; then
    echo "✅ Build réussi"

    # Lancer le simulateur
    echo "📱 Lancement du simulateur iOS..."
    xcrun simctl boot 904069A6-0503-4A08-8E1F-768991A0CE5F 2>/dev/null || true

    # Installer et lancer l'app
    echo "📦 Installation de l'app..."
    xcrun simctl install 904069A6-0503-4A08-8E1F-768991A0CE5F /Users/pro/Library/Developer/Xcode/DerivedData/age-centapnizzbgsbequohmmtcdlmch/Build/Products/Debug-iphonesimulator/age.app

    echo "🎬 Lancement de l'application..."
    xcrun simctl launch 904069A6-0503-4A08-8E1F-768991A0CE5F pseudoxia.age

    echo "📊 Affichage des logs en temps réel..."
    echo "Appuyez sur Ctrl+C pour arrêter les logs"
    echo "----------------------------------------"

    # Afficher les logs de l'app
    xcrun simctl spawn 904069A6-0503-4A08-8E1F-768991A0CE5F log stream --predicate 'process == "age"' --style syslog

else
    echo "❌ Échec du build"
    exit 1
fi