//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://jessesquires.com/JSQDataSourcesKit
//
//
//  GitHub
//  https://github.com/jessesquires/JSQDataSourcesKit
//
//
//  License
//  Copyright © 2015 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import UIKit


/**
 An instance conforming to `TableViewCellFactoryType` is responsible for initializing
 and configuring table view cells to be consumed by an instance of `TableViewDataSourceProvider`.
 */
public protocol TableViewCellFactoryType {

    // MARK: Associated types

    /// The type of elements backing the table view.
    associatedtype Item

    /// The type of `UITableViewCell` that the factory produces.
    associatedtype Cell: UITableViewCell


    // MARK: Methods

    /**
    Creates and returns a new `Cell` instance, or dequeues an existing cell for reuse.

    - parameter item:      The item at `indexPath`.
    - parameter tableView: The table view requesting this information.
    - parameter indexPath: The index path that specifies the location of `cell` and `item`.

    - returns: An initialized or dequeued `UITableViewCell` of type `Cell`.
    */
    func cellForItem(_ item: Item, inTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> Cell

    /**
     Configures and returns the specified cell.

     - parameter cell:      The cell to configure.
     - parameter item:      The item at `indexPath`.
     - parameter tableView: The table view requesting this information.
     - parameter indexPath: The index path that specifies the location of `cell` and `item`.

     - returns: A configured `UITableViewCell` of type `Cell`.
     */
    @discardableResult func configureCell(_ cell: Cell, forItem item: Item, inTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> Cell
}
