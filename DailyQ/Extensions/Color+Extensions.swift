//
//  Color+Extensions.swift
//  DailyQ
//
//  Created by mac034 on 6/17/25.
//
import SwiftUI

extension Color {
    // 기본 색상들 (에셋 기반)
    static let mainColor = Color("MainColor")
    static let letterColor = Color("LetterColor")
    static let blueGrayColor = Color("BlueGrayColor")
    static let lightGrayColor = Color("LightGrayColor")
    static let blueColor = Color("BlueColor")
    static let grayColor = Color("GrayColor")
    static let backgroundColor = Color("BackgroundColor")
    
    // 폴백 색상들 (에셋이 없을 때)
    static let mainColorFallback = Color(red: 0.65, green: 0.75, blue: 0.88)
    static let backgroundColorFallback = Color(red: 0.98, green: 0.98, blue: 0.98)
}
