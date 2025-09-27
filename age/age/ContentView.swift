//
//  ContentView.swift
//  age
//
//  Created by pro on 27/09/2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var agePredictor = AgePredictor()
    @State private var selectedImage: UIImage?
    @State private var predictionResult: AgePredictionResult?
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageSource = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // Header
                Text("Prédicteur d'Âge")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                if !agePredictor.isModelLoaded {
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
                    HStack(spacing: 20) {
                        Button(action: {
                            showingImageSource = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Choisir une image")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }

                        if selectedImage != nil {
                            Button(action: predictAge) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "brain.head.profile")
                                        Text("Prédire l'âge")
                                    }
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(isLoading ? Color.gray : Color.green)
                                .cornerRadius(10)
                            }
                            .disabled(isLoading)
                        }
                    }

                    // Results
                    if let result = predictionResult {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Résultats de la prédiction")
                                .font(.headline)
                                .padding(.top)

                            HStack {
                                Text("Âge prédit:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(result.predictedAge) ans")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }

                            Text("Top 3 prédictions:")
                                .font(.subheadline)
                                .padding(.top, 5)

                            ForEach(Array(result.topPredictions.enumerated()), id: \.offset) { index, prediction in
                                HStack {
                                    Text("\(index + 1).")
                                    Text("\(prediction.age) ans")
                                    Spacer()
                                }
                                .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
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
                .onDisappear {
                    predictionResult = nil
                }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImage)
                .onDisappear {
                    predictionResult = nil
                }
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
            }
        }
    }
}

#Preview {
    ContentView()
}
