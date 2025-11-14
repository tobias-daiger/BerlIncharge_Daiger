//
//  ContentView.swift
//  BerlIncharge_Daiger
//
//  Created by Tobi on 24.10.25.
// https://www.youtube.com/watch?v=tnNFoZ7CkP8

import SwiftUI

struct InchargeView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            StationView()
                .tabItem {
                    Image(systemName: "ev.charger")
                    Text("Stations")
                }
        }
        .accentColor(Color("brandPrimary"))
    }
}

#Preview {
    InchargeView()
}
