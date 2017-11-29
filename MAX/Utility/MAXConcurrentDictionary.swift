import Foundation

/// A thread-safe dictionary that ensures synchronous access to key-value pairs.
/// This can be used in place of Swift's Dictionary in cases where access might
/// happen off the main thread, e.g. in an HTTP request.
final class MAXConcurrentDictionary<KeyType: Hashable, ValueType>: Sequence, ExpressibleByDictionaryLiteral {

    private var internalDictionary: Dictionary<KeyType, ValueType>
    private let queue = DispatchQueue(label: "MAXConcurrentDictionary", attributes: .concurrent)
    
    typealias Iterator = Dictionary<KeyType, ValueType>.Iterator
    
    /// The number of key-value pairs in the dictionary
    var count: Int {
        var count = 0
        self.queue.sync { () -> Void in
            count = self.internalDictionary.count
        }
        return count
    }
    
    /// Safely get or set a copy of the internal dictionary value
    var dictionary: [KeyType:ValueType] {
        get {
            var dictionaryCopy: [KeyType:ValueType]?
            self.queue.sync { () -> Void in
                dictionaryCopy = self.dictionary
            }
            return dictionaryCopy!
        }
        
        set {
            let dictionaryCopy = newValue // create a local copy on the current thread
            self.queue.async { () -> Void in
                self.internalDictionary = dictionaryCopy
            }
        }
    }
    
    /// Initialize with an empty dictionary
    convenience init() {
        self.init(dictionary: [KeyType:ValueType]())
    }
    
    /// Initialize the dictionary with a key-value literal, e.g. ["A": "B", "C": "D"]
    convenience required init(dictionaryLiteral elements: (KeyType, ValueType)...) {
        var dictionary = Dictionary<KeyType,ValueType>()
        
        for (key,value) in elements {
            dictionary[key] = value
        }
        
        self.init(dictionary: dictionary)
    }
    
    /// Initialize the dictionary from a pre-existing non-thread safe dictionary.
    init(dictionary: [KeyType:ValueType]) {
        self.internalDictionary = dictionary
    }
    
    /// Provide subscript access to the dictionary, e.g. let a = dict["a"] and dict["a"] = someVar
    subscript(key: KeyType) -> ValueType? {
        get {
            var value: ValueType?
            self.queue.sync { () -> Void in
                value = self.internalDictionary[key]
            }
            return value
        }
        
        set {
            self.setValue(value: newValue, forKey: key)
        }
    }
    
    /// Assign the specified value while synchronizing writes for consistent modifications
    func setValue(value: ValueType?, forKey key: KeyType) {
        self.queue.sync { () -> Void in
            self.internalDictionary[key] = value
        }
    }
    
    /// Remove a value while synchronizing removal for consistent modifications
    func removeValue(forKey key: KeyType) -> ValueType? {
        var oldValue: ValueType? = nil
        self.queue.sync { () -> Void in
            oldValue = self.internalDictionary.removeValue(forKey: key)
        }
        return oldValue
    }
    
    func makeIterator() -> MAXConcurrentDictionary<KeyType, ValueType>.Iterator {
        var iterator: Dictionary<KeyType, ValueType>.Iterator!
        self.queue.sync { () -> Void in
            iterator = self.internalDictionary.makeIterator()
        }
        return iterator
    }
}
