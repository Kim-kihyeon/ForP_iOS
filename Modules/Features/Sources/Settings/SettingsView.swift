import SwiftUI
import ComposableArchitecture
import CoreSharedUI

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            if store.hasPartner {
                Section("파트너") {
                    ForPButton("파트너 초기화", style: .destructive) {
                        store.send(.resetPartnerTapped)
                    }
                }
            }
            Section {
                ForPButton("로그아웃", style: .secondary) {
                    store.send(.logoutTapped)
                }
            }
        }
        .navigationTitle("설정")
        .onAppear { store.send(.onAppear) }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
