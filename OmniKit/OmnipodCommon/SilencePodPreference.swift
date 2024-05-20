//
//  SilencePodPreference.swift
//  OmniKit
//
//  Created by Joe Moran on 8/30/23.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation

public enum SilencePodPreference: Int, CaseIterable {
    case disabled
    case enabled

    public var title: String {
        switch self {
        case .disabled:
            return LocalizedString("禁用", comment: "Title string for SilencePodPreference.disabled")
        case .enabled:
            return LocalizedString("静音", comment: "Title string for SilencePodPreference.enabled")
        }
    }

    public var description: String {
        switch self {
        case .disabled:
            return LocalizedString("正常操作模式，其中所有POD警报使用可听见的POD哔哔声以及启用了置信点时。", comment: "Description for SilencePodPreference.disabled")
        case .enabled:
            return LocalizedString("All Pod alerts use no beeps and confirmation reminder beeps are suppressed. The Pod will only beep for fatal Pod faults and when playing test beeps.\n\n⚠️Warning - If your phone is out of range of the pod while this feature is enabled, you will not receive any in-app notifications; and the pod will not beep to alert you.", comment: "Description for SilencePodPreference.enabled")
        }
    }
}
