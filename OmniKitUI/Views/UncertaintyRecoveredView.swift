//
//  UncertaintyRecoveredView.swift
//  OmniKit
//
//  Created by Pete Schwamb on 8/25/20.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKitUI

struct UncertaintyRecoveredView: View {
    var appName: String
    
    var didFinish: (() -> Void)?
    
    var body: some View {
        GuidePage(content: {
            Text(LocalizedString("Loop 已恢复与您身体上的 Pod 的通信。\n\n胰岛素输送记录已更新，应与实际输送的记录相符。\n\n您现在可以继续正常使用 Loop。", comment: "Text body for page showing insulin uncertainty has been recovered."))
                .fixedSize(horizontal: false, vertical: true)
                .padding([.top, .bottom])
        }) {
            VStack {
                Button(action: {
                    self.didFinish?()
                }) {
                    Text(LocalizedString("继续", comment: "Button title to continue"))
                    .actionButtonStyle()
                    .padding()
                }
            }
        }
        .navigationBarTitle(Text("通讯恢复了"), displayMode: .large)
        .navigationBarBackButtonHidden(true)
    }    
}

struct UncertaintyRecoveredView_Previews: PreviewProvider {
    static var previews: some View {
        UncertaintyRecoveredView(appName: "Test App")
    }
}
