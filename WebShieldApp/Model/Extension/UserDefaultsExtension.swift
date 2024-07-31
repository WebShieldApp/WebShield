//
//  UserDefaultsExtension.swift
//  WebShield
//
//  Created by Arjun on 2024-07-19.
//

import Foundation

extension UserDefaults {
    static func exists(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}
