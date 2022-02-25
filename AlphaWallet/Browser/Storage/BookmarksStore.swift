// Copyright DApps Platform Inc. All rights reserved.

import Foundation
import RealmSwift

final class BookmarksStore {
    var bookmarks: Results<Bookmark> {
        return realm.objects(Bookmark.self)
            .sorted(byKeyPath: "order", ascending: true)
    }
    private let realm: Realm

    init(realm: Realm) {
        self.realm = realm

        if !UserDefaults.standard.bool(forKey: "defaultBookmarksCreated") {
            createDefaultBookmarks()
            UserDefaults.standard.set(true, forKey: "defaultBookmarksCreated")
        }
    }

    private func createDefaultBookmarks() {
        let bookmarks = [Bookmark(url: "https://app.orion.money", title: "Orion.Money"),
                         Bookmark(url: "https://stake.lido.fi", title: "Lido - Stake Ether"),
                         Bookmark(url: "https://www.tokensets.com/explore", title: "TokenSets"),
                         Bookmark(url: "https://cvi.finance/platform", title: "Crypto Volatility Index"),
                         Bookmark(url: "https://app.cozy.finance/protected-invest", title: "Protected Investing"),
                         Bookmark(url: "https://opensea.io/assets", title: "OpenSea - Browse NFTs")]

        add(bookmarks: bookmarks)
    }
   
    private func findOriginalBookmarks(matchingBookmarks bookmarksToFind: [Bookmark]) -> [Bookmark] {
        var originals = [Bookmark]()
        for toDelete in bookmarksToFind {
            var found = false
            for original in bookmarks where original.id == toDelete.id {
                originals.append(original)
                found = true
                break
            }
            if !found {
                for original in bookmarks where original.url == toDelete.url {
                    originals.append(original)
                    break
                }
            }
        }
        return originals
    }

    func add(bookmarks: [Bookmark]) {
        var bookmarkOrder = self.bookmarks.count
        try? realm.write {
            for each in bookmarks {
                each.order = bookmarkOrder
                bookmarkOrder += 1
            }
            realm.add(bookmarks, update: .all)
        }
    }

    func delete(bookmarks bookmarksToDelete: [Bookmark]) {
        //We may not receive the original Bookmark object(s), hence the lookup
        let originalsToDelete = findOriginalBookmarks(matchingBookmarks: bookmarksToDelete)

        try? realm.write {
            realm.delete(originalsToDelete)
            let bookmarksToChangeOrder = Array(bookmarks)
            var bookmarkOrder = 0
            for each in bookmarksToChangeOrder {
                each.order = bookmarkOrder
                bookmarkOrder += 1
            }
        }
    }

    func moveBookmark(fromIndex from: Int, toIndex to: Int) {
        try? realm.write {
            let bookmarkMoved = bookmarks[from]
            if from < to {
                let changed = bookmarks[(from+1)...to]
                for each in changed {
                    each.order -= 1
                }
            } else {
                let changed = bookmarks[to..<from]
                //`Array` is essential for this to work. Otherwise when accessing `each`, we may change the same bookmark twice when we reorder in a certain direction (up or down). Maybe a Realm oddity
                for each in Array(changed) {
                    each.order += 1
                }
            }
            bookmarkMoved.order = to
        }
    }
}
