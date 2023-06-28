//
//  PodProgressStatus.swift
//  OmniKit
//
//  Created by Pete Schwamb on 9/28/18.
//  Copyright © 2018 Pete Schwamb. All rights reserved.
//

import Foundation

public enum PodProgressStatus: UInt8, CustomStringConvertible, Equatable {
    case initialized = 0
    case memoryInitialized = 1
    case reminderInitialized = 2
    case pairingCompleted = 3
    case priming = 4
    case primingCompleted = 5
    case basalInitialized = 6
    case insertingCannula = 7
    case aboveFiftyUnits = 8
    case fiftyOrLessUnits = 9
    case oneNotUsed = 10
    case twoNotUsed = 11
    case threeNotUsed = 12
    case faultEventOccurred = 13        // fault event occurred (a "screamer")
    case activationTimeExceeded = 14    // took > 2 hrs from progress 2 to 3 OR > 1 hr from 3 to 8
    case inactive = 15                  // pod deactivated or a fatal packet state error
    
    public var readyForDelivery: Bool {
        return self == .fiftyOrLessUnits || self == .aboveFiftyUnits
    }
    
    public var description: String {
        switch self {
        case .initialized:
            return LocalizedString("初始化", comment: "Pod initialized")
        case .memoryInitialized:
            return LocalizedString("记忆初始化", comment: "Pod memory initialized")
        case .reminderInitialized:
            return LocalizedString("提醒初始化", comment: "Pod pairing reminder initialized")
        case .pairingCompleted:
            return LocalizedString("配对完成", comment: "Pod status when pairing completed")
        case .priming:
            return LocalizedString("启动", comment: "Pod status when priming")
        case .primingCompleted:
            return LocalizedString("启动完成", comment: "Pod state when priming completed")
        case .basalInitialized:
            return LocalizedString("基础初始化", comment: "Pod state when basal initialized")
        case .insertingCannula:
            return LocalizedString("插入套管", comment: "Pod state when inserting cannula")
        case .aboveFiftyUnits:
            return LocalizedString("普通的", comment: "Pod state when running above fifty units")
        case .fiftyOrLessUnits:
            return LocalizedString("低水箱", comment: "Pod state when running with fifty or less units")
        case .oneNotUsed:
            return LocalizedString("牛肉", comment: "Pod state oneNotUsed")
        case .twoNotUsed:
            return LocalizedString("双胞胎", comment: "Pod state twoNotUsed")
        case .threeNotUsed:
            return LocalizedString("三局", comment: "Pod state threeNotUsed")
        case .faultEventOccurred:
            return LocalizedString("发生故障事件", comment: "Pod state when fault event has occurred")
        case .activationTimeExceeded:
            return LocalizedString("激活时间超出了", comment: "Pod state when activation not completed in the time allowed")
        case .inactive:
            return LocalizedString("停用", comment: "Pod state when deactivated")
        }
    }
}
