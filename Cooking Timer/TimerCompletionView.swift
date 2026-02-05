//
//  TimerCompletionView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct TimerCompletionView: View {
    let timer: CookingTimer
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = true
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated timer icon
                ZStack {
                    Circle()
                        .fill(.orange.gradient)
                        .frame(width: 200, height: 200)
                        .shadow(color: .orange, radius: 40)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isPlaying ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPlaying)
                
                VStack(spacing: 12) {
                    Text(timer.name)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(meal.name)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Stop button
                Button {
                    stopTimer()
                } label: {
                    Text("Stop")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.orange.gradient)
                        }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            playTimerSound()
        }
        .onDisappear {
            stopSound()
        }
    }
    
    private func playTimerSound() {
        // Play system sound for timer completion
        AudioServicesPlaySystemSound(1005) // Timer sound
        
        // Schedule repeated playback
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if isPlaying {
                AudioServicesPlaySystemSound(1005)
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func stopSound() {
        isPlaying = false
        audioPlayer?.stop()
    }
    
    private func stopTimer() {
        stopSound()
        dismiss()
    }
}
