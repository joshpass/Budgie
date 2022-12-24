//
//  String.swift
//  Budgie
//
//  Created by Josh Pasricha on 20/12/22.
//

import Foundation

extension String {
    var firstUpperCased: String { prefix(1).capitalized + dropFirst() }
}
