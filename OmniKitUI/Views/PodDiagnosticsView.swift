//
//  PodDiagnosticsView.swift
//  OmniKit
//
//  Created by Joseph Moran on 11/25/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import HealthKit
import OmniKit

protocol DiagnosticCommands {
    func playTestBeeps() async throws
    func readPulseLog() async throws -> String
    func readPulseLogPlus() async throws -> String
    func readActivationTime() async throws -> String
    func readTriggeredAlerts() async throws -> String
    func getDetailedStatus() async throws -> DetailedStatus
    func pumpManagerDetails() -> String
}

struct PodDiagnosticsView: View  {

    var title: String
    
    var diagnosticCommands: DiagnosticCommands
    var podOk: Bool
    var noPod: Bool

    var body: some View {
        List {
            NavigationLink(destination: ReadPodStatusView(getDetailedStatus: diagnosticCommands.getDetailedStatus)) {
                FrameworkLocalText("读取POD状态", comment: "Text for read pod status navigation link")
                    .foregroundColor(Color.primary)
            }
            .disabled(noPod)

            NavigationLink(destination: PlayTestBeepsView(playTestBeeps: {
                try await diagnosticCommands.playTestBeeps()
            })) {
                FrameworkLocalText("播放测试哔哔声", comment: "Text for play test beeps navigation link")
                    .foregroundColor(Color.primary)
            }
            .disabled(!podOk)

            NavigationLink(destination: ReadPodInfoView(
                title: LocalizedString("读取脉冲日志", comment: "Text for read pulse log title"),
                actionString: LocalizedString("阅读脉冲日志...", comment: "Text for read pulse log action"),
                failedString: LocalizedString("无法读取脉冲日志。", comment: "Alert title for error when reading pulse log"),
                action: { try await diagnosticCommands.readPulseLog() }))
            {
                FrameworkLocalText("读取脉冲日志", comment: "Text for read pulse log navigation link")
                    .foregroundColor(Color.primary)
            }
            .disabled(noPod)

            NavigationLink(destination: ReadPodInfoView(
                title: LocalizedString("读取脉冲日志加上", comment: "Text for read pulse log plus title"),
                actionString: LocalizedString("阅读脉冲日志加...", comment: "Text for read pulse log plus action"),
                failedString: LocalizedString("未能读取脉冲日志加。", comment: "Alert title for error when reading pulse log plus"),
                action: { try await diagnosticCommands.readPulseLogPlus() }))
            {
                FrameworkLocalText("读取脉冲日志加上", comment: "Text for read pulse log plus navigation link")
                    .foregroundColor(Color.primary)
            }
            .disabled(noPod)

            NavigationLink(destination: ReadPodInfoView(
                title: LocalizedString("读取激活时间", comment: "Text for read activation time title"),
                actionString: LocalizedString("阅读激活时间...", comment: "Text for read activation time action"),
                failedString: LocalizedString("未能读取激活时间。", comment: "Alert title for error when reading activation time"),
                action: { try await diagnosticCommands.readActivationTime() }))
            {
                FrameworkLocalText("读取激活时间", comment: "Text for read activation time navigation link")
                    .foregroundColor(Color.primary)
            }
            .disabled(noPod)

            NavigationLink(destination: ReadPodInfoView(
                title: LocalizedString("读取触发的警报", comment: "Text for read triggered alerts title"),
                actionString: LocalizedString("阅读触发警报...", comment: "Text for read triggered alerts action"),
                failedString: LocalizedString("未能读取触发警报。", comment: "Alert title for error when reading triggered alerts"),
                action: { try await diagnosticCommands.readTriggeredAlerts() }))
            {
                FrameworkLocalText("读取触发的警报", comment: "Text for read triggered alerts navigation link")
                    .foregroundColor(Color.primary)
            }
            .disabled(noPod)

            NavigationLink(destination: PumpManagerDetailsView() { diagnosticCommands.pumpManagerDetails() })
            {
                FrameworkLocalText("泵管理员详细信息", comment: "Text for pump manager details navigation link")
                    .foregroundColor(Color.primary)
            }
        }
        .insetGroupedListStyle()
        .navigationBarTitle(title)
    }
}
