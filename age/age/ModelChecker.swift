import Foundation
import CoreML

class ModelChecker {
    static func checkModelAvailability() {
        print("🔍 Vérification du modèle Core ML...")

        // Vérifier le bundle principal
        guard let bundlePath = Bundle.main.resourcePath else {
            print("❌ Bundle path non accessible")
            return
        }

        print("📁 Bundle path: \(bundlePath)")

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            let modelFiles = contents.filter { $0.contains("Age") || $0.contains(".ml") }
            print("📋 Fichiers modèle trouvés: \(modelFiles)")

            // Vérifier le modèle CLIP compilé (.mlmodelc)
            if let modelURL = Bundle.main.url(forResource: "AgePredictor", withExtension: "mlmodelc") {
                print("✅ AgePredictor.mlmodelc trouvé à: \(modelURL.path)")

                do {
                    let model = try MLModel(contentsOf: modelURL)
                    print("✅ Modèle CLIP chargé avec succès")
                    print("📊 Description: \(model.modelDescription)")

                    // Afficher les détails des entrées/sorties
                    if let inputDescription = model.modelDescription.inputDescriptionsByName.first {
                        print("📝 Entrée attendue: \(inputDescription.key) - \(inputDescription.value)")
                    }
                    if let outputDescription = model.modelDescription.outputDescriptionsByName.first {
                        print("📤 Sortie produite: \(outputDescription.key) - \(outputDescription.value)")
                    }
                } catch {
                    print("❌ Erreur de chargement du modèle CLIP: \(error)")
                }
            } else {
                print("❌ Aucun modèle .mlmodelc trouvé dans le bundle")

                // Lister tous les fichiers de modèles
                let modelFiles = contents.filter { $0.contains(".ml") }
                print("📋 Fichiers de modèles disponibles: \(modelFiles)")
            }

        } catch {
            print("❌ Erreur lors de la lecture du contenu du bundle: \(error)")
        }
    }
}