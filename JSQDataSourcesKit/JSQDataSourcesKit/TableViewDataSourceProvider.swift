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

import CoreData
import Foundation
import UIKit


/**
 A `TableViewDataSourceProvider` is responsible for providing a data source object for a table view.

 - warning: **Clients are responsbile for the following:**
    - Registering cells with the table view
    - Adding, removing, or reloading cells and sections as the provider's `sections` are modified.
 */
public final class TableViewDataSourceProvider <
    SectionInfo: TableViewSectionInfo,
    CellFactory: TableViewCellFactoryType>: CustomStringConvertible
    where CellFactory.Item == SectionInfo.Item {

    // MARK: Typealiases

    /// The type of elements for the data source provider.
    public typealias Item = SectionInfo.Item

    /// A function for reacting to a user move of a row
    public typealias UserMovedHandler = (UITableView, CellFactory.Cell, Item,  IndexPath, IndexPath) -> Void

    /// A function for reacting to an insertion or deletion of a row
    public typealias EditHandler = (UITableView, CellFactory.Cell, Item, UITableViewCellEditingStyle, IndexPath) -> Void
    
    /// A function for deciding if an item at a certain index path can be edited or not
    public typealias CanEditHandler = (UITableView, Item, IndexPath) -> Bool
    
    // MARK: Properties

    /// The sections in the table view
    public var sections: [SectionInfo]

    /// Returns the cell factory for this data source provider.
    public let cellFactory: CellFactory

    /// Returns the object that provides the data for the table view.
    public var dataSource: UITableViewDataSource { return bridgedDataSource }


    // MARK: Initialization

    /**
    Constructs a new data source provider for a table view.

    - parameter sections:         The sections to display in the table view.
    - parameter cellFactory:      The cell factory from which the table view data source will dequeue cells.
    - parameter userMovedHandler: Enables drag 'n' drop reordering when set. Called whenever a user moves a row to a new index path.
    - parameter tableView:        The table view whose data source will be provided by this provider.

    - returns: A new `TableViewDataSourceProvider` instance.
    */
    public init(
        sections: [SectionInfo],
        cellFactory: CellFactory,
        userMovedHandler: UserMovedHandler? = nil,
        editHandler: EditHandler? = nil,
        canEditHandler: CanEditHandler? = nil,
        tableView: UITableView? = nil) {
            self.sections = sections
            self.cellFactory = cellFactory
            self.userMovedHandler = userMovedHandler
            self.editHandler = editHandler
            self.canEditHandler = canEditHandler
            tableView?.dataSource = dataSource
    }


    // MARK: Subscripts

    /**
    - parameter index: The index of the section to return.
    - returns: The section at `index`.
    */
    public subscript (index: Int) -> SectionInfo {
        get {
            return sections[index]
        }
        set {
            sections[index] = newValue
        }
    }

    /**
     - parameter indexPath: The index path of the item to return.
     - returns: The item at `indexPath`.
     */
    public subscript (indexPath: IndexPath) -> Item {
        get {
            return sections[indexPath.section].items[indexPath.row]
        }
        set {
            sections[indexPath.section].items[indexPath.row] = newValue
        }
    }


    // MARK: CustomStringConvertible

    /// :nodoc:
    public var description: String {
        get {
            return "<\(TableViewDataSourceProvider.self): sections=\(sections)>"
        }
    }


    // MARK: Private

    fileprivate let userMovedHandler: UserMovedHandler?
    
    fileprivate let editHandler: EditHandler?
    
    fileprivate let canEditHandler: CanEditHandler?
    
    fileprivate lazy var bridgedDataSource: BridgedTableViewDataSource = BridgedTableViewDataSource(
        numberOfSections: { [unowned self] () -> Int in
            self.sections.count
        },
        numberOfRowsInSection: { [unowned self] (section) -> Int in
            self.sections[section].items.count
        },
        cellForRowAtIndexPath: { [unowned self] (tableView, indexPath) -> UITableViewCell in
            let item = self.sections[indexPath.section].items[indexPath.row]
            let cell = self.cellFactory.cellForItem(item, inTableView: tableView, atIndexPath: indexPath)
            return self.cellFactory.configureCell(cell, forItem: item, inTableView: tableView, atIndexPath: indexPath)
        },
        titleForHeaderInSection: { [unowned self] (section) -> String? in
            self.sections[section].headerTitle
        },
        titleForFooterInSection: { [unowned self] (section) -> String? in
            self.sections[section].footerTitle
        },
        moveHandler: self.userMovedHandler.flatMap(self.tableViewMoveHandlerForUserMovedHandler),
        editHandler: self.editHandler.flatMap(self.tableViewEditHandlerForEditHandler),
        canEditHandler: self.canEditHandler.flatMap(self.tableViewCanEditHandlerForCanEditHandler))
    
    fileprivate func tableViewMoveHandlerForUserMovedHandler(_ userMovedHandler: @escaping UserMovedHandler) -> BridgedTableViewDataSource.MoveHandler {
        
        return { [unowned self] tableView, sourceIndexPath, destinationIndexPath in
            let item = self.sections[sourceIndexPath.section].items.remove(at: sourceIndexPath.item)
            self.sections[destinationIndexPath.section].items.insert(item, at: destinationIndexPath.item)
            
            // Dispatch to main queue so UITableView can update its internal state
            OperationQueue.main.addOperation {
                if let cell = tableView.cellForRow(at: destinationIndexPath) as? CellFactory.Cell {
                    userMovedHandler(tableView, cell, item, sourceIndexPath, destinationIndexPath)
                }
            }
        }
    }
    
    fileprivate func tableViewEditHandlerForEditHandler(_ editHandler: @escaping EditHandler) -> BridgedTableViewDataSource.EditHandler {
        
        return { [unowned self] tableView, editingStyle, indexPath in
            guard let cell = tableView.cellForRow(at: indexPath) as? CellFactory.Cell else {
                fatalError("Couldn't get cell for edited index path")
            }
            let section = self.sections[indexPath.section]
            let item = section.items[indexPath.row]
            
            if editingStyle ~= .delete {
                var items = section.items
                items.remove(at: indexPath.row)
                self.sections[indexPath.section].items = items
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            editHandler(tableView, cell, item, editingStyle, indexPath)
        }
    }
    
    fileprivate func tableViewCanEditHandlerForCanEditHandler(_ canEditHandler: @escaping CanEditHandler) -> BridgedTableViewDataSource.CanEditHandler {
        
        return { [unowned self] tableView, indexPath in
            let item = self.sections[indexPath.section].items[indexPath.row]
            
            return canEditHandler(tableView, item, indexPath)
        }
    }
}

/**
 A `TableViewFetchedResultsDataSourceProvider` is responsible for providing a data source object for a table view
 that is backed by an `NSFetchedResultsController` instance.

 - warning: The `CellFactory.Item` type should correspond to the type of objects that the `NSFetchedResultsController` fetches.
 - note: Clients are responsbile for registering cells with the table view.
 */
public final class TableViewFetchedResultsDataSourceProvider <CellFactory: TableViewCellFactoryType>: CustomStringConvertible {

    // MARK: Typealiases

    /// The type of elements for the data source provider.
    public typealias Item = CellFactory.Item


    // MARK: Properties

    /// Returns the fetched results controller that provides the data for the table view data source.
    public let fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>

    /// Returns the cell factory for this data source provider.
    public let cellFactory: CellFactory

    /// Returns the object that provides the data for the table view.
    public var dataSource: UITableViewDataSource { return bridgedDataSource }


    // MARK: Initialization

    /**
    Constructs a new data source provider for the table view.

    - parameter fetchedResultsController: The fetched results controller that provides the data for the table view.
    - parameter cellFactory:              The cell factory from which the table view data source will dequeue cells.
    - parameter tableView:                The table view whose data source will be provided by this provider.

    - returns: A new `TableViewFetchedResultsDataSourceProvider` instance.
    */
    public init(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, cellFactory: CellFactory, tableView: UITableView? = nil) {
        self.fetchedResultsController = fetchedResultsController
        self.cellFactory = cellFactory
        tableView?.dataSource = dataSource
    }


    // MARK: CustomStringConvertible

    /// :nodoc:
    public var description: String {
        get {
            return "<\(TableViewFetchedResultsDataSourceProvider.self): fetchedResultsController=\(fetchedResultsController)>"
        }
    }


    // MARK: Private

    fileprivate lazy var bridgedDataSource: BridgedTableViewDataSource = BridgedTableViewDataSource(
        numberOfSections: { [unowned self] () -> Int in
            self.fetchedResultsController.sections?.count ?? 0
        },
        numberOfRowsInSection: { [unowned self] (section) -> Int in
            return (self.fetchedResultsController.sections?[section])?.numberOfObjects ?? 0
        },
        cellForRowAtIndexPath: { [unowned self] (tableView, indexPath) -> UITableViewCell in
            let item = self.fetchedResultsController.object(at: indexPath) as! Item
            let cell = self.cellFactory.cellForItem(item, inTableView: tableView, atIndexPath: indexPath)
            return self.cellFactory.configureCell(cell, forItem: item, inTableView: tableView, atIndexPath: indexPath)
        },
        titleForHeaderInSection: { [unowned self] (section) -> String? in
            return (self.fetchedResultsController.sections?[section])?.name
        },
        titleForFooterInSection: { (section) -> String? in
            return nil
    })
}


/*
Avoid making DataSourceProvider inherit from NSObject.
Keep classes pure Swift.
Keep responsibilies focused.
*/
@objc private final class BridgedTableViewDataSource: NSObject, UITableViewDataSource {

    typealias NumberOfSectionsHandler = () -> Int
    typealias NumberOfRowsInSectionHandler = (Int) -> Int
    typealias CellForRowAtIndexPathHandler = (UITableView, IndexPath) -> UITableViewCell
    typealias TitleForHeaderInSectionHandler = (Int) -> String?
    typealias TitleForFooterInSectionHandler = (Int) -> String?
    typealias MoveHandler = (UITableView, IndexPath, IndexPath) -> Void
    typealias EditHandler = (UITableView, UITableViewCellEditingStyle, IndexPath) -> Void
    typealias CanEditHandler = (UITableView, IndexPath) -> Bool

    let numberOfSections: NumberOfSectionsHandler
    let numberOfRowsInSection: NumberOfRowsInSectionHandler
    let cellForRowAtIndexPath: CellForRowAtIndexPathHandler
    let titleForHeaderInSection: TitleForHeaderInSectionHandler
    let titleForFooterInSection: TitleForFooterInSectionHandler
    let moveHandler: MoveHandler?
    let editHandler: EditHandler?
    let canEditHandler: CanEditHandler?

    init(numberOfSections: @escaping NumberOfSectionsHandler,
        numberOfRowsInSection: @escaping NumberOfRowsInSectionHandler,
        cellForRowAtIndexPath: @escaping CellForRowAtIndexPathHandler,
        titleForHeaderInSection: @escaping TitleForHeaderInSectionHandler,
        titleForFooterInSection: @escaping TitleForFooterInSectionHandler,
        moveHandler: MoveHandler? = nil,
        editHandler: EditHandler? = nil,
        canEditHandler: CanEditHandler? = nil) {

            self.numberOfSections = numberOfSections
            self.numberOfRowsInSection = numberOfRowsInSection
            self.cellForRowAtIndexPath = cellForRowAtIndexPath
            self.titleForHeaderInSection = titleForHeaderInSection
            self.titleForFooterInSection = titleForFooterInSection
            self.moveHandler = moveHandler
            self.editHandler = editHandler
            self.canEditHandler = canEditHandler
    }

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections()
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellForRowAtIndexPath(tableView, indexPath)
    }

    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection(section)
    }
    
    @objc func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return titleForFooterInSection(section)
    }
    
    @objc func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return moveHandler != nil
    }
    
    @objc func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveHandler?(tableView, sourceIndexPath, destinationIndexPath)
    }
    
    @objc func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return editHandler != nil && (canEditHandler.flatMap { $0(tableView, indexPath) } ?? true)
    }
    
    @objc func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        editHandler?(tableView, editingStyle, indexPath)
    }
}
