//
//  CircularList.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/25/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation

enum ArgumentError : Error {
    case invalidArgument(String)
}

class CircularList<T> {
    
    var array: [T?]
    var startIndex: Int
    var count: Int {
        didSet {
            if count > oldValue {
                for i in count..<count {
                    array [i] = nil
                }
            } else {
                array.removeSubrange(oldValue..<array.count)
            }
        }
    }
    
    var maxLength: Int {
        didSet {
            guard maxLength != oldValue else {
                let empty : T? = nil
                var newArray = Array.init(repeating: empty, count:Int(maxLength))
                let top = min (maxLength, array.count)
                for i in 0..<top {
                    newArray [i] = array [getCyclicIndex(i)]!
                }
                startIndex = 0
                array = newArray
                return
            }
        }
    }

    public init (maxLength: Int)
    {
        array = Array.init(repeating: nil, count: Int(maxLength))
        self.maxLength = maxLength
        self.count = 0
        self.startIndex = 0
    }
    
    func getCyclicIndex (_ index: Int) -> Int {
        return Int(startIndex + index) % (array.count)
    }
    
    subscript (index: Int) -> T {
        get {
            return array [getCyclicIndex(index)]!
        }
        set (newValue){
            array [getCyclicIndex(index)] = newValue
        }
    }
    
    func push (_ value: T)
    {
        array [getCyclicIndex(count)] = value
        if count == array.count {
            startIndex = startIndex + 1
            if startIndex == array.count {
                startIndex = 0
            }
        } else {
            count = count + 1
        }
    }
    
    func recycle () -> T
    {
        if count != maxLength {
            print ("can only recycle when the buffer is full")
            abort ();
        }
        startIndex += 1
        startIndex = startIndex % maxLength
        return array [getCyclicIndex(count-1)]!
    }
    
    @discardableResult
    func pop () -> T {
        let v = array [getCyclicIndex(count-1)]!
        count = count - 1
        return v
    }
    
    func splice (start: Int, deleteCount: Int, items: [T])
    {
        if deleteCount > 0 {
            for i in start..<(count-deleteCount) {
                array [getCyclicIndex(i)] = array [getCyclicIndex(i+deleteCount)]
            }
            count = count - deleteCount
        }
        if items.count != 0 {
            // add items
            let ic = items.count
            for i in (start...count-1).reversed () {
                array [getCyclicIndex(i + ic)] = array [getCyclicIndex(i)]
            }
            for i in 0..<ic {
                array [getCyclicIndex(start + i)] = items [i]
            }
            
            // Adjust length as needed
            if Int(count) + ic > array.count {
                let countToTrim = count + items.count - array.count
                startIndex = startIndex + countToTrim
                count = array.count
            } else {
                count = count + items.count
            }
        }
    }
    
    func trimStart (count: Int)
    {
        let c = count > count ? count : count;
        startIndex = startIndex + c
        self.count = count - c
    }
    
    func shiftElements (start: Int, count: Int, offset: Int)
    {
        precondition (count >= 0)
        precondition (start >= 0)
        precondition (start <= count)
        precondition (start+offset > 0)
        if offset > 0 {
            for i in (0..<count).reversed() {
                self [start + i + offset] = self [start + i]
            }
            let expandListBy = start + count + offset - count
            if expandListBy > 0 {
                self.count += expandListBy
                while count > array.count {
                    self.count -= 1
                    startIndex += 1
                    // trimmed callback invoke
                }
            }
        } else {
            for i in 0..<count {
                self [start + i + offset] = self [start + i]
            }
        }
    }
    
    var isFull: Bool {
        get {
            return count == maxLength
        }
    }
}
