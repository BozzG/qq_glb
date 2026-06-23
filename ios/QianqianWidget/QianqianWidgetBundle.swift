//
//  QianqianWidgetBundle.swift
//  QianqianWidget
//
//  Widget 入口。本期仅提供只读「今日日程概览」Widget；
//  Control（控制中心）与 LiveActivity（灵动岛/实时活动）暂不使用。
//

import WidgetKit
import SwiftUI

@main
struct QianqianWidgetBundle: WidgetBundle {
    var body: some Widget {
        QianqianWidget()
    }
}
