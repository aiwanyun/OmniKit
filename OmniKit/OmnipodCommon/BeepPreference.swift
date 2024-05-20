//
//  BeepPreference.swift
//  OmniKit
//
//  Created by Pete Schwamb on 2/14/22.
//  Copyright © 2022 LoopKit Authors. All rights reserved.
//

import Foundation

public enum BeepPreference: Int, CaseIterable {
    case silent
    case manualCommands
    case extended

    public var title: String {
        switch self {
        case .silent:
            return LocalizedString("禁用", comment: "Title string for BeepPreference.silent")
        case .manualCommands:
            return LocalizedString("启用", comment: "Title string for BeepPreference.manualCommands")
        case .extended:
            return LocalizedString("扩展", comment: "Title string for BeepPreference.extended")
        }
    }

    public var description: String {
        switch self {
        case .silent:
            return LocalizedString("没有使用信心提醒。", comment: "Description for BeepPreference.silent")
        case .manualCommands:
            return LocalizedString("信心提醒将听起来您发起的命令，例如推注，取消推注，暂停，简历，保存通知提醒等。当闭环自动调整交付时，不使用信心提醒。", comment: "Description for BeepPreference.manualCommands")
        case .extended:
            return LocalizedString("当闭环自动调整交付以及您发起的命令时，置信提醒将听起来。", comment: "Description for BeepPreference.extended")
        }
    }

    var shouldBeepForManualCommand: Bool {
        return self == .extended || self == .manualCommands
    }

    var shouldBeepForAutomaticCommands: Bool {
        return self == .extended
    }

    func shouldBeepForCommand(automatic: Bool) -> Bool {
        if automatic {
            return shouldBeepForAutomaticCommands
        } else {
            return shouldBeepForManualCommand
        }
    }
}
