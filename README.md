# SimpleCacheStore
SimpleCacheStore should allow you to save objects persistent in CoreData and recieve them fast via NSCache when you need them. The basic idea is a key-value store in CoreData with a overlaying cache. Once you save an object in SimpleCacheStore it lays persistent in CoreData and will be also available in the cache of your running instance. Also a not cached object will be saved in the cache when you recieve it for the first time.

**For further information look at our [Wiki](https://github.com/Mo0812/SimpleCacheStore/wiki)!**

**For more details about the development and architecture of SimpleCacheStore take a look at my [blog](http://moritzkanzler.de/wordpress/simplecachestore/)**.

##Table of Contents
* [Features](#features)
* [How to implement SimpleCacheStore](#how-to-implement-simplecachestore)
* [How to use SimpleCacheStore](#how-to-use-simplecachestore)
    * [Save and retrieve objecs](#save-and-retrieve-objects)
    * [Save and retrieve multiple objects](#save-and-retrieve-multiple-objects)
        * [Save object with a additional label](#save-object-with-a-additional-label)
        * [Retrieve objects queried by label](#retrieve-objects-queried-by-label)
    * [SCManager options](#scmanager-options)
        * [cache mode](#cache-mode)
        * [cache limit](#cache-limit)
* [Prepare Objects to get saved to SimpleCacheStore](#prepare-objects-to-get-saved-to-simplecachestore)
* [Roadmap](#roadmap)
* [Why should I use SimpleCacheStore?](#why-should-i-use-simplecachestore)

## Features
* key-value store
* persistent saving in CoreData
* additional holding used objects in cache for fast recieving
* secondary indexes for range queries on objects

## How to implement SimpleCacheStore
SimpleCacheStore is still under development, so don't use it in production enviorments at the moment. If you want to test or improve it, you're welcome!

To implement SimpleCacheStore just download the repo and open it up in XCode. After that you can create a framework-bundle via the Build function. Then just drag the SimpleCacheStore.framework file into your exisiting project as an embedded library.

## How to use SimpleCacheStore
First you have to import the Library in the files you want to use it:
```swift
import SimpleCacheStore
```
### Save and retrieve objects

After that you can instance the SCManager class and use the following commands:
```swift
let scm = SCManager(cacheMode: .rebuild, limit: 1000)
//save an object into SimpleCacheStore
scm.save(forKey: "KeyX", object: TestObject("Title 1", subtitle: "Subtitle 1"))
//get an object from SimpleCacheStore
let object = scm.get(forKey: "KeyX")
```
With the example above you retrieve your stored objects sequentially. There is also a async method to ~~save~~ and retrieve your objects:

**retrieve objects async**

```swift
let scm = SCManager(cacheMode: .rebuild, limit: 1000)
//retrieve an object async from SimpleCacheStore
scm?.get(forKey: String(i), answer: {
      success, data in
      let obj = data as! TestObject2
      //operate with the object
      print(obj.title)
  })
```

SimpleCacheStore operates the request in a seperate thread via GC.

### Save and retrieve multiple objects

To save single objects is the most basic way to hold an object to the phone for further using, but often there is a need to group objects in categories. For example objects which represents a person and label them as *friends* or *employees*.

#### Save object with a additional label

To enable this possibility there is a feature added, where you can assign a *label* to every object you save. Because of this the ```save``` function has an overloaded paramater ***label***:


```swift
let scm = SCManager(cacheMode: .rebuild, limit: 1000)
//save an object into SimpleCacheStore with a given label
scm.save(forKey: "KeyX", object: TestObject("Title 1", subtitle: "Subtitle 1"), label: "My Label")
```

#### Retrieve objects queried by label

To retrieve an object range for a given label you can use a specialized kind of the ```get``` function:

```swift
let scm = SCManager(cacheMode: .rebuild, limit: 1000)
scm?.get(byLabel: "friends", answer: {
    success, data in
    for friend in data {
      if let obj = friend as! TestObject2 {
        //operate with the object
        print(obj.title)
      }
    }      
})
```

### SCManager options

When you instance SCManager in your application you can decide between several options.

```swift
let scmanager = SCManager(cacheMode: SCManager.CacheMode, limit: Int)
```

#### cache mode

The cache mode represents how the cache gets initialized on start up of SimpleCacheStore. One of the benefits of SimpleCacheStore is a fast response on requests via a additional cache. So once an object being requested or first get stored SimpleCacheStore also saves it in it's on cache. The next time the same object will be requested SimpleCacheStore retrieve it much faster via the cache and not via CoreData. The additional caching is a simple way to improve the speed of answering requests, but there is also a problem. On every start of SimpleCacheStore the cache is empty. So for the first request of an object you won't get the benefits of additional speed up. To solve this problem we implemented two strategies.

---

> Cache modes get further development right now

**rebuild mode**

In the rebuild mode SimpleCacheStore reads the whole core data object library and puts every object in the cache. This task will start on the initalizing of SCManager and runs asynchronus, so it won't affect your application on running. The cache gets filled bit by bit. Even own cache fills via get or save commands doesn't get in conflict with this process.

Pro
* fast recovery of the cache over the whole object range
* runs in background and doesn't affect other processes
* fast startup of SimpleCacheStore

Contra
* depending on the core data and cache size, the cache doesn't get filled very clever and you have objects that you may not use
* cache may not filled on first requests (async task)

---

~~Overall the question, which cache mode you uses depends on your working scenario! If you have a small amount of objects in core data (~ 10k-100k) which all fit in SimpleCacheStore's own cache, you should use rebuild mode. If your object library grows all over the place (which we don't recommend - SimpleCacheStore isn't designed to be a data grave) you may can't hold all these objects in the cache memory. Because of the better distribution in these scenario, snapshot mode will be your friend. But please keep in mind that a double memory need may become a problem for your memory too. No matter which mode you use, always keep in mind that SimpleCacheMode adjust it's own cache via request and save commands. So apart from the start up moment, SimpleCacheStore will become more and more specific to what you load from it and saves this in it's cache.~~

#### cache limit

Cache limit indicates how much objects SimpleCacheStore's cache should hold in your application. You may test it via XCode to look after the RAM utilization and adjust the size of it. Like in the statement above, more cache space for SimpleCacheStore always stands for minor cache misses and faster object delivery. Also keep in mind, that the cache only aquire the space its needed, so a higher value of cache limit won't block more memory. The cache is implemented via NSCache so the object deletion is given by the NSCache class.

## Prepare Objects to get saved to SimpleCacheStore

If you want to store an object in SimpleCacheStore you have to implement the NSCoding protocol. The following code shows you an example:

```swift
import Foundation
import UIKit

class TestObject2: NSObject, NSCoding {

    var title: String
    var image: UIImage

    init(title: String, image: UIImage) {
        self.title = title
        self.image = image
    }

    required convenience init?(coder decoder: NSCoder) {
        guard let title = decoder.decodeObjectForKey("title") as? String,
            let image = decoder.decodeObjectForKey("image") as? UIImage
            else {
                return nil
        }

        self.init(title: title, image: image)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.title, forKey: "title")
        coder.encode(self.image, forKey: "image")
    }
}
```

SimpleCacheStore treat every given object as NSObject, you have to typecast an retrieving object in your app back to the object type you have store it. This flaw you have to keep in mind. Clear defined keys can help you to manage this.


##Roadmap
- [ ] Singleton instance for SCManager for project-wide easy use
- [x] automatic rebuild cache after creating new instance, for faster first time get-operations
- [x] cache size control and limits
- [x] load objects asynchronusly
- [x] get SimpleCacheStore used to secondary indexes
- [ ] multiple secondary indexes for any object
- [ ] caching rebuild mode based on most used objects

## Why should I use SimpleCacheStore?
The idea of creating SimpleCacheStore is to improve the performance of an self written app (for a university project). This app alwasys fetches informations from a server and has the problem, if no data connection exists the app can't show any content. So my idea was to be able to save downloaded content easily for the case that the data connection gets lost. The second advantage is that slow data connections can also delay the presentation of data in the GUI. So if an app can access (even old) data before the request from the server is answered, it would represent an adavantage too.
