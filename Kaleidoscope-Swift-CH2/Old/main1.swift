//
//  main1.swift
//  Kaleidoscope-Swift-CH2
//
//  Created by Yu Liu on 2024-03-31.
//

import Foundation

func startConsole() {
    var line = ""
    while true {
        print("ready> ", terminator: "")
        if let input = readLine() {
            line = input// + "\0"
        } else { 
            line = String(eof)
            exit(0)
        } //  return }
//        source = Array(line)
        getNextToken()
        mainLoop()
    }
}

func testReadline() {
    while true {
        if var text = readLine() {
            print(text)
        } else {
            print("EOF")
            return
        }
    }
}

func testReadline1() {
    while true {
        let c = getchar()
        print(c)
        if c == -1 {
            break
        }
    }
}
