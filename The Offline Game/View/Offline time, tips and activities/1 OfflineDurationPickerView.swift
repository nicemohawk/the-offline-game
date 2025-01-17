//
//  OfflineTimeView.swift
//  The Offline Game
//
//  Created by Daniel Crompton on 12/2/24.
//

import SwiftUI

struct OfflineDurationPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(OfflineViewModel.self) private var offlineViewModel
    @AppStorage(K.userDefaultsShouldShowActivitiesViewKey) private var shouldShowActivitiesView = true
    @State private var tipsViewPresented = false
    @State private var activitiesViewPresented = false
    @State private var wifiAnimate = true
    @State private var sliderSecsValue: TimeInterval = 0.0
    
    private let wifiLogoRotation: Double = 15
    
            
    var body: some View {
        
        @Bindable var offlineViewModel = offlineViewModel
        
        NavigationStack {
            
            VStack(spacing: 10) {
                
                Spacer()
                
                ZStack(alignment: .bottom) {
                    Image(.wifiBrushstrokeSlash)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .foregroundStyle(.smog)
                        .opacity(0.25)
                        .scaleEffect(1.75)
                        .offset(x: wifiAnimate ? -15 : 15)
                        .rotationEffect(
                            .degrees(wifiAnimate ? -wifiLogoRotation : wifiLogoRotation),
                            anchor: .bottom
                        )
                        .animation(.easeInOut(duration: 4.5).repeatForever(), value: wifiAnimate)
                        .onAppear {
                            wifiAnimate.toggle()
                        }
                    
                    Text("How long do you want to go offline for?")
                        .padding()
                }
                
                durationDisplay()
                
                Slider(value: $sliderSecsValue,
                       in: K.offlineDurationSecsRange,
                       step: K.secsStep) {
                    Text(offlineViewModel.durationSeconds.offlineDisplayFormat())
                    // for screen readers
                }
                .labelsHidden()
                
                Spacer()
                
                Button("CONTINUE", systemImage: K.systemArrowIcon, action: nextStage)
                .buttonStyle(FilledRedButtonStyle())
            }
            .font(.main30)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
            .onAppear {
                // Make sure the offline view model slider value is synchronised to here
                sliderSecsValue = offlineViewModel.durationSeconds.seconds
            }
            .navigationDestination(isPresented: $tipsViewPresented) {
                TipView()
            }
            .navigationDestination(isPresented: $activitiesViewPresented) {
                ActivitiesView()
            }

        }
        
        // When the offline duration picker shows, start listening for network connectivity changes.
        
        // This allows us to check if wifi is on or off
        // That is used to determine if we should present the tips view or not, since we don't ned to tell them to turn off wifi if they did already.
        .onAppear(perform: NetworkMonitor.shared.startListening)
        .onDisappear(perform: NetworkMonitor.shared.stopListening)
    }
    
    
    @ViewBuilder private func durationDisplay() -> some View {
        let timeComponents = Duration.seconds(sliderSecsValue).offlineDisplayFormatComponents(width: .abbreviated)
        
        if let firstComponent = timeComponents.first {
            Text("\(firstComponent.0)") // E.g. 9
                .textCase(.uppercase)
                .font(.display256)
                .foregroundStyle(.accent)
                .animation(.default, value: firstComponent.0) // FIX? YES // value is the number part
                .contentTransition(.numericText()) // NOT WORKING (on its own)
            
            let commaSeperatedComponents = timeComponents[1...]
                .map { "\($0.0) \($0.1)" }
                .joined(separator: ", ")
            
            Text(
                firstComponent.1 +
                (!commaSeperatedComponents.isEmpty ? ", " : "") +
                commaSeperatedComponents
            )
            
        } else {
            Text("No first component for duration. Components are \(timeComponents)")
        }
    }
    
    
    private func nextStage() {
        // 1. Make sure the slider value is synchronised to the view model
        offlineViewModel.durationSeconds = .seconds(sliderSecsValue)
        
        // If the wifi is turned on (use network monitor for this) then present the tips view sheet telling them to turn it off
        if NetworkMonitor.shared.isConnected {
            tipsViewPresented = true
            
            // tips view can navigate from there
        }
        
        // If we have wifi turned off BUT this is the first app usage, navigate to the activities view
        else if shouldShowActivitiesView {
            activitiesViewPresented = true
        }
        
        // If we already had wifi off AND don't need to see activities, just go offline
        else {
            offlineViewModel.goOffline()
        }
    }
    
}

#Preview {
    OfflineDurationPickerView()
        .environment(OfflineViewModel())
}
