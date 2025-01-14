//
//  ActivitiesListView.swift
//  The Offline Game
//
//  Created by Daniel Crompton on 1/7/25.
//

import SwiftUI

struct ActivitiesListView: View {
    @Environment(ActivityViewModel.self) private var activityViewModel
    
    var body: some View {
        Group {
            if let preloadedActivities = activityViewModel.preloadedActivities {
                List {
                    
                    // BORED ACTIVITIES that were generated by the user
                    if !activityViewModel.boredActivities.isEmpty {
                        Section {
                            ForEach(activityViewModel.boredActivities) { activity in
                                boredActivityListRow(activity)
                            }
                            
                            Button("Clear",
                                   systemImage: "xmark.octagon",
                                   role: .destructive) {
                                activityViewModel.boredActivities.removeAll()
                            }
                        } header: {
                            Label("Your activities", systemImage: "figure.wave")
                                .font(.headline)
                        }
                        .transition(.slide)
                        .animation(.bouncy, value: activityViewModel.boredActivities)
                    }
                    
                    ForEach(preloadedActivities) { activityCollection in
                        Section {
                            ForEach(activityCollection.activities) { activity in
                                activityListRow(activity)
                            }
                        } header: {
                            Label(activityCollection.category, systemImage: activityCollection.systemImage)
                                .font(.headline)
                        }
                    }
                }
                
            } else {
                ContentUnavailableView("No preloaded activities yet...", systemImage: "questionmark")
            }
        }
        .onAppear(perform: activityViewModel.loadPreloadedActivities)
    }
    
    
    @ViewBuilder private func activityListRow(_ activity: PreloadedActivityCollection.Activity) -> some View {
        VStack(alignment: .leading) {
            Text(activity.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
                .bold()
            
            Text(activity.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption)
        }
        .padding(.vertical, 5)
    }
    
    
    @ViewBuilder private func boredActivityListRow(_ activity: BoredActivity) -> some View {
        HStack {
            HStack {
                Image(systemName: activity.systemImage)
                Text(activity.activity)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.callout)
            .bold()
            
            // Participants
            Text("\(activity.participants)")
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(.smog, in: .capsule)
            

        }
        .padding(.vertical, 5)
    }
}

#Preview {
    ActivitiesListView()
}
