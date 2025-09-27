//
//  ContentView.swift
//  age
//
//  Created by pro on 27/09/2025.
//

import SwiftUI
import PhotosUI
import StoreKit

struct ContentView: View {
    @StateObject private var agePredictor = AgePredictor()
    @State private var selectedImage: UIImage?
    @State private var predictionResult: AgePredictionResult?
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageSource = false
    @State private var showingShareSheet = false
    @State private var imageToShare: UIImage?
    @State private var showingInfoSheet = false

    // UserDefaults keys
    private let calculationCountKey = "AgeCalculationCount"
    private let hasRequestedReviewKey = "HasRequestedReview"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // Header avec design moderne
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("Prédicteur d'Âge")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .layoutPriority(1)

                        Spacer()

                        Button(action: {
                            showingInfoSheet = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading, 8)
                    }

                    Text("Intelligence artificielle pour l'estimation d'âge")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                .padding(.horizontal)

                if !agePredictor.isDeviceCompatible {
                    // Appareil incompatible
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        VStack(spacing: 10) {
                            Text("Appareil incompatible")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)

                            Text(agePredictor.errorMessage ?? "Cet appareil ne supporte pas Core ML")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        VStack(spacing: 8) {
                            Text("Appareils compatibles:")
                                .font(.headline)
                            Text("• iPhone 6s et plus récent")
                            Text("• iPad (5ème génération) et plus récent")
                            Text("• iPad Pro (toutes générations)")
                            Text("• iPad Air 2 et plus récent")
                            Text("• iPad mini 4 et plus récent")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                } else if !agePredictor.isModelLoaded {
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)

                        VStack(spacing: 8) {
                            Text("Chargement du modèle CLIP...")
                                .font(.headline)
                            Text("Ceci peut prendre quelques secondes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Button("Diagnostiquer") {
                            ModelChecker.checkModelAvailability()
                            // Debug: afficher les stats utilisateur
                            let count = UserDefaults.standard.integer(forKey: calculationCountKey)
                            let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
                            print("📊 Debug - Calculs: \(count), Évaluation demandée: \(hasRequested)")
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else {

                    // Image Display
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("Aucune image sélectionnée")
                                        .foregroundColor(.gray)
                                }
                            )
                    }

                    // Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            showingImageSource = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                Text("Sélectionner une photo")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        if isLoading {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                    .scaleEffect(1.2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Analyse en cours...")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                    Text("Veuillez patienter")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }

                    // Results
                    if let result = predictionResult {
                        VStack(spacing: 20) {
                            // Titre avec icône et bouton partage
                            HStack {
                                Image(systemName: "sparkles.rectangle.stack")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("Résultat de l'analyse")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()

                                Button(action: {
                                    generateAndShareImage()
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                            }

                            // Âge principal avec design mis en avant
                            VStack(spacing: 8) {
                                Text("Âge estimé")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                VStack(spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text("\(result.predictedAge)")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(.orange)

                                        Text("ans")
                                            .font(.title)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .offset(y: 8)
                                    }

                                    Text("± \(Int(round(result.standardDeviation))) ans")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                    )
                            )

                            // Top 3 prédictions avec design moderne
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "list.number")
                                        .foregroundColor(.blue)
                                    Text("Prédictions alternatives")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                ForEach(Array(result.topPredictions.enumerated()), id: \.offset) { index, prediction in
                                    HStack(spacing: 12) {
                                        // Badge du classement
                                        ZStack {
                                            Circle()
                                                .fill(index == 0 ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 28, height: 28)
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(index == 0 ? .white : .gray)
                                        }

                                        Text("\(prediction.age) ans")
                                            .font(.body)
                                            .fontWeight(index == 0 ? .semibold : .regular)

                                        Spacer()

                                        // Barre de confiance (visuelle uniquement)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(index == 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.4))
                                            .frame(width: 60 * (index == 0 ? 1.0 : index == 1 ? 0.7 : 0.4), height: 6)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 4)
                    }

                    if let errorMessage = agePredictor.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .confirmationDialog("Choisir une source", isPresented: $showingImageSource) {
            Button("Appareil photo") {
                showingCamera = true
            }
            Button("Galerie photos") {
                showingImagePicker = true
            }
            Button("Annuler", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldImage, newImage in
            if newImage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    predictAge()
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let compositeImage = generateCompositeImage() {
                ShareSheet(activityItems: [compositeImage])
            } else {
                VStack {
                    Text("Erreur lors de la génération de l'image")
                        .foregroundColor(.red)
                    Button("Fermer") {
                        showingShareSheet = false
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            InfoView()
        }
    }

    private func predictAge() {
        guard let image = selectedImage else { return }

        isLoading = true
        predictionResult = nil

        agePredictor.predictAge(from: image) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                self.predictionResult = result

                // Incrémenter le compteur et vérifier pour la demande d'évaluation
                if result != nil {
                    self.incrementCalculationCount()
                }
            }
        }
    }

    private func incrementCalculationCount() {
        let currentCount = UserDefaults.standard.integer(forKey: calculationCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: calculationCountKey)

        print("✅ Nombre de calculs d'âge: \(newCount)")

        // Demander une évaluation après 5 calculs (une seule fois)
        if newCount >= 5 && !UserDefaults.standard.bool(forKey: hasRequestedReviewKey) {
            requestAppReview()
        }
    }

    private func requestAppReview() {
        print("📱 Demande d'évaluation de l'application")
        UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)

        // Demander l'évaluation avec un léger délai pour ne pas interrompre l'expérience utilisateur
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    private func generateCompositeImage() -> UIImage? {
        guard let selectedImage = selectedImage,
              let result = predictionResult else {
            print("❌ Données manquantes pour le partage")
            return nil
        }

        print("✅ Génération de l'image composite...")

        let renderer = UIGraphicsImageRenderer(size: selectedImage.size)
        let compositeImage = renderer.image { context in
            // Dessiner l'image originale
            selectedImage.draw(at: .zero)

            // Configuration pour le texte
            let fontSize: CGFloat = min(selectedImage.size.width, selectedImage.size.height) * 0.08
            let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            let textColor = UIColor.white

            // Style de texte avec ombre
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0
            ]

            // Texte principal
            let mainText = "\(result.predictedAge) ± \(Int(round(result.standardDeviation))) ans"
            let mainTextSize = mainText.size(withAttributes: textAttributes)

            // Texte secondaire
            let subtitle = "Age inféré par MonAge iOS"
            let subtitleFont = UIFont.systemFont(ofSize: fontSize * 0.5, weight: .medium)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: textColor,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)

            // Position du texte (coin supérieur droit avec marge)
            let margin: CGFloat = fontSize * 0.5
            let backgroundPadding = margin * 0.8
            let maxTextWidth = max(mainTextSize.width, subtitleSize.width)

            let mainTextRect = CGRect(
                x: selectedImage.size.width - maxTextWidth - backgroundPadding + (maxTextWidth - mainTextSize.width) / 2,
                y: margin,
                width: mainTextSize.width,
                height: mainTextSize.height
            )

            let subtitleRect = CGRect(
                x: selectedImage.size.width - maxTextWidth - backgroundPadding + (maxTextWidth - subtitleSize.width) / 2,
                y: margin + mainTextSize.height + fontSize * 0.2,
                width: subtitleSize.width,
                height: subtitleSize.height
            )

            // Dessiner un fond rectangulaire semi-transparent
            let backgroundRect = CGRect(
                x: selectedImage.size.width - maxTextWidth - backgroundPadding * 2,
                y: margin - backgroundPadding * 0.5,
                width: maxTextWidth + backgroundPadding * 2,
                height: mainTextSize.height + subtitleSize.height + fontSize * 0.2 + backgroundPadding
            )

            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.75).cgColor)
            context.cgContext.fill(backgroundRect)
            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            context.cgContext.stroke(backgroundRect)

            // Dessiner le texte
            mainText.draw(in: mainTextRect, withAttributes: textAttributes)
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        }

        print("✅ Image composite générée, taille: \(compositeImage.size)")
        return compositeImage
    }

    private func generateAndShareImage() {
        showingShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Icône et titre
                    VStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("À propos de cette application")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    // Description de l'application
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fonctionnement")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Cette application tente de déterminer l'âge à partir d'une photo en utilisant une version du modèle CLIP (Contrastive Language-Image Pre-Training) d'OpenAI.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Confidentialité")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        Text("Aucune donnée n'est envoyée sur le web. Les calculs se font localement sur votre appareil.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Avertissement")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.top, 8)

                        Text("Elle est fournie à titre expérimental par Pseudoxia.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        // Lien cliquable
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Plus d'informations")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.top, 8)

                            Link("https://www.pseudoxia.org", destination: URL(string: "https://www.pseudoxia.org")!)
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
