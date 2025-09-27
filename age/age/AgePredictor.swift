import CoreML
import Vision
import UIKit
import Combine

class AgePredictor: ObservableObject {
    private var mlModel: MLModel?
    private var visionModel: VNCoreMLModel?

    @Published var isModelLoaded = false
    @Published var errorMessage: String?

    init() {
        loadModel()
    }

    private func loadModel() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                print("🔍 Recherche du modèle AgeModel.mlpackage...")

                // Vérifier les ressources du bundle
                if let bundlePath = Bundle.main.resourcePath {
                    print("📁 Bundle path: \(bundlePath)")
                    let contents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath)
                    print("📋 Bundle contents: \(contents?.filter { $0.contains("Age") || $0.contains(".ml") } ?? [])")
                }

                // Charger uniquement le modèle CLIP complet pour de vraies prédictions
                var modelURL = Bundle.main.url(forResource: "AgePredictor", withExtension: "mlmodelc")

                // Si le modèle compilé n'est pas trouvé, essayer .mlpackage
                if modelURL == nil {
                    print("📋 Modèle .mlmodelc non trouvé, recherche .mlpackage...")
                    modelURL = Bundle.main.url(forResource: "AgePredictor", withExtension: "mlpackage")

                    if let packageURL = modelURL {
                        print("✅ Trouvé modèle .mlpackage: \(packageURL.lastPathComponent)")
                    }
                }

                guard let finalModelURL = modelURL else {
                    print("❌ Aucun modèle Core ML trouvé (.mlmodelc ou .mlpackage)")
                    throw AgeError.modelNotFound
                }

                print("✅ Modèle trouvé à: \(finalModelURL.path)")
                print("🔄 Chargement du modèle Core ML...")

                let model = try MLModel(contentsOf: finalModelURL)
                print("✅ Modèle Core ML chargé")

                let visionModel = try VNCoreMLModel(for: model)
                print("✅ Vision Model créé")

                DispatchQueue.main.async {
                    self?.mlModel = model
                    self?.visionModel = visionModel
                    self?.isModelLoaded = true
                    print("✅ Modèle prêt à utiliser")
                }
            } catch {
                print("❌ Erreur de chargement: \(error)")
                DispatchQueue.main.async {
                    self?.errorMessage = "Erreur de chargement du modèle: \(error.localizedDescription)"
                }
            }
        }
    }

    func predictAge(from image: UIImage, completion: @escaping (AgePredictionResult?) -> Void) {
        guard let visionModel = visionModel else {
            completion(nil)
            return
        }

        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Erreur de prédiction: \(error.localizedDescription)"
                    completion(nil)
                    return
                }

                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let multiArray = results.first?.featureValue.multiArrayValue else {
                    completion(nil)
                    return
                }

                let result = self?.processModelOutput(multiArray)
                completion(result)
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func processModelOutput(_ multiArray: MLMultiArray) -> AgePredictionResult {
        let probabilities = (0..<multiArray.count).map { index in
            multiArray[index].doubleValue
        }

        let maxIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let predictedAge = maxIndex + 1 // Les âges commencent à 1
        let confidence = probabilities[maxIndex]

        // Top 3 prédictions
        let sortedPredictions = probabilities.enumerated().sorted { $0.element > $1.element }
        let topPredictions = Array(sortedPredictions.prefix(3)).map { (index, prob) in
            AgePrediction(age: index + 1, confidence: prob)
        }

        return AgePredictionResult(
            predictedAge: predictedAge,
            confidence: confidence,
            topPredictions: topPredictions
        )
    }
}

struct AgePredictionResult {
    let predictedAge: Int
    let confidence: Double
    let topPredictions: [AgePrediction]
}

struct AgePrediction {
    let age: Int
    let confidence: Double
}

enum AgeError: LocalizedError {
    case modelNotFound
    case predictionFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Le modèle de prédiction d'âge n'a pas été trouvé"
        case .predictionFailed:
            return "La prédiction a échoué"
        }
    }
}