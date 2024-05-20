//
//  PodSetupView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 5/17/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct PodSetupView: View {
    @Environment(\.dismissAction) private var dismiss
    
    private struct AlertIdentifier: Identifiable {
        enum Choice {
            case skipOnboarding
        }
        var id: Choice
    }
    @State private var alertIdentifier: AlertIdentifier?

    let nextAction: () -> Void
    let allowDebugFeatures: Bool
    let skipOnboarding: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            close
            ScrollView {
                content
            }
            Spacer()
            continueButton
                .padding(.bottom)
        }
        .padding(.horizontal)
        .navigationBarHidden(true)
        .alert(item: $alertIdentifier) { alert in
            switch alert.id {
            case .skipOnboarding:
                return skipOnboardingAlert
            }
        }
    }
    
    @ViewBuilder
    private var close: some View {
        HStack {
            Spacer()
            cancelButton
        }
        .padding(.top)
    }
        
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            title
                .padding(.top, 5)
                .onLongPressGesture(minimumDuration: 2) {
                    didLongPressOnTitle()
                }
            Divider()
            bodyText
                .foregroundColor(.secondary)
                .padding(.top)
        }
    }

    @ViewBuilder
    private var title: some View {
        Text(LocalizedString("POD设置", comment: "Title for PodSetupView"))
            .font(.largeTitle)
            .bold()
            .padding(.vertical)
    }
    
    @ViewBuilder
    private var bodyText: some View {
        Text(LocalizedString("现在，您将开始配置提醒的过程，用胰岛素填充POD，与设备配对并将其放在身体上。", comment: "bodyText for PodSetupView"))
    }
    
    private var cancelButton: some View {
        Button(LocalizedString("取消", comment: "Cancel button title"), action: {
            self.dismiss()
        })
    }

    private var continueButton: some View {
        Button(LocalizedString("继续", comment: "Text for continue button on PodSetupView"), action: nextAction)
            .buttonStyle(ActionButtonStyle())
    }
    
    private var skipOnboardingAlert: Alert {
        Alert(title: Text("跳过omnipod？"),
              message: Text("您确定要跳过Omnipod登机吗？"),
              primaryButton: .cancel(),
              secondaryButton: .destructive(Text("是的"), action: skipOnboarding))
    }
    
    private func didLongPressOnTitle() {
        if allowDebugFeatures {
            alertIdentifier = AlertIdentifier(id: .skipOnboarding)
        }
    }

}

struct PodSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PodSetupView(nextAction: {}, allowDebugFeatures: true, skipOnboarding: {})
    }
}
