//
//  ExpirationReminderSetupView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 5/17/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct ExpirationReminderSetupView: View {
    @State var expirationReminderDefault: Int = 2
    
    public var valueChanged: ((_ value: Int) -> Void)?
    public var continueButtonTapped: (() -> Void)?
    public var cancelButtonTapped: (() -> Void)?

    var body: some View {
        GuidePage(content: {
            VStack(alignment: .leading, spacing: 15) {
                Text(LocalizedString("应用程序会在 Pod 到期之前提前通知您。\n\n滚动以设置您希望提前通知的小时数。", comment: "Description text on ExpirationReminderSetupView")).fixedSize(horizontal: false, vertical: true)
                Divider()
                ExpirationReminderPickerView(expirationReminderDefault: $expirationReminderDefault, collapsible: false, showingHourPicker: true)
                    .onChange(of: expirationReminderDefault) { value in
                        valueChanged?(value)
                    }
            }
            .padding(.vertical, 8)
        }) {
            VStack {
                Button(action: {
                    continueButtonTapped?()
                }) {
                    Text(LocalizedString("下一个", comment: "Text of continue button on ExpirationReminderSetupView"))
                        .actionButtonStyle(.primary)
                }
            }
            .padding()
        }
        .navigationBarTitle(LocalizedString("到期提醒", comment: "Title for ExpirationReminderSetupView"), displayMode: .automatic)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedString("取消", comment: "Cancel button title"), action: {
                    cancelButtonTapped?()
                })
            }
        }
    }
}

struct ExpirationReminderSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ExpirationReminderSetupView()
    }
}
