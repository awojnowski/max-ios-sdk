import Foundation

/// A thread-safe dictionary that ensures synchronous access to key-value pairs.
/// This can be used in place of Swift's Dictionary in cases where access might
/// happen off the main thread, e.g. in an HTTP request.
final class MAXConcurrentDictionary<KeyType:Hashable,ValueType>: NSObject, SequenceType, DictionaryLiteralConvertible {

    private var internalDictionary: [KeyType:ValueType]
    private let queue = dispatch_queue_create("dictionary access", DISPATCH_QUEUE_CONCURRENT)
    
    /// The number of key-value pairs in the dictionary
    var count: Int {
        var count = 0
        dispatch_sync(self.queue) { () -> Void in
            count = self.internalDictionary.count
        }
        return count
    }
    
    /// Safely get or set a copy of the internal dictionary value
    var dictionary: [KeyType:ValueType] {
        get {
            var dictionaryCopy: [KeyType:ValueType]?
            dispatch_sync(self.queue) { () -> Void in
                dictionaryCopy = self.dictionary
            }
            return dictionaryCopy!
        }
        
        set {
            let dictionaryCopy = newValue // create a local copy on the current thread
            dispatch_async(self.queue) { () -> Void in
                self.internalDictionary = dictionaryCopy
            }
        }
    }
    
    /// Initialize with an empty dictionary
    override convenience init() {
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
    init( dictionary: [KeyType:ValueType] ) {
        self.internalDictionary = dictionary
    }
    
    /// Provide subscript access to the dictionary, e.g. let a = dict["a"] and dict["a"] = someVar
    subscript(key: KeyType) -> ValueType? {
        get {
            var value: ValueType?
            dispatch_sync(self.queue) { () -> Void in
                value = self.internalDictionary[key]
            }
            return value
        }
        
        set {
            setValue(newValue, forKey: key)
        }
    }
    
    /// Assign the specified value while synchronizing writes for consistent modifications
    func setValue(value: ValueType?, forKey key: KeyType) {
        dispatch_barrier_async(self.queue) { () -> Void in
            self.internalDictionary[key] = value
        }
    }
    
    /// Remove a value while synchronizing removal for consistent modifications
    func removeValueForKey(key: KeyType) -> ValueType? {
        var oldValue: ValueType? = nil
        dispatch_barrier_sync(self.queue) { () -> Void in
            oldValue = self.internalDictionary.removeValueForKey(key)
        }
        return oldValue
    }
    
    
    /// Generator key-value pairs synchronously for for...in loops.
    func generate() -> Dictionary<KeyType,ValueType>.Generator {
        var generator : Dictionary<KeyType,ValueType>.Generator!
        dispatch_sync(self.queue) { () -> Void in
            generator = self.internalDictionary.generate()
        }
        return generator
    }
}
