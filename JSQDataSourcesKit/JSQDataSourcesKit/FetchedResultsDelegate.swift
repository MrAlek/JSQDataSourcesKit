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
 A `CollectionViewFetchedResultsDelegateProvider` is responsible for providing a delegate object
 for an instance of `NSFetchedResultsController` that manages data to display in a collection view.

 - warning: The `CellFactory.Item` type should correspond to the type of objects that the `NSFetchedResultsController` fetches.
 */
public final class CollectionViewFetchedResultsDelegateProvider <CellFactory: CollectionViewCellFactoryType>: CustomStringConvertible {

    // MARK: Typealiases

    /// The type of elements for the delegate provider.
    public typealias Item = CellFactory.Item


    // MARK: Properties

    /**
    The collection view that displays the data from the `NSFetchedResultsController`
    for which this provider provides a delegate.
    */
    public weak var collectionView: UICollectionView?

    /// Returns the cell factory for this delegate provider.
    public let cellFactory: CellFactory

    /// Returns the delegate object for the fetched results controller
    public var delegate: NSFetchedResultsControllerDelegate { return bridgedDelegate }


    // MARK: Initialization

    /**
    Constructs a new delegate provider for a fetched results controller.

    - parameter collectionView:           The collection view to be updated when the fetched results change.
    - parameter cellFactory:              The cell factory from which the fetched results controller delegate will configure cells.
    - parameter fetchedResultsController: The fetched results controller whose delegate will be provided by this provider.

    - returns: A new `CollectionViewFetchedResultsDelegateProvider` instance.
    */
    public init(
        collectionView: UICollectionView,
        cellFactory: CellFactory,
        fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) {
            self.collectionView = collectionView
            self.cellFactory = cellFactory
            fetchedResultsController.delegate = delegate
    }


    // MARK: CustomStringConvertible

    /// :nodoc:
    public var description: String {
        get {
            return "<\(CollectionViewFetchedResultsDelegateProvider.self): collectionView=\(collectionView)>"
        }
    }


    // MARK: Private

    fileprivate typealias SectionChangeTuple = (changeType: NSFetchedResultsChangeType, sectionIndex: Int)
    fileprivate var sectionChanges = [SectionChangeTuple]()

    fileprivate typealias ObjectChangeTuple = (changeType: NSFetchedResultsChangeType, indexPaths: [IndexPath])
    fileprivate var objectChanges = [ObjectChangeTuple]()

    fileprivate var updatedObjects = [IndexPath: Item]()

    fileprivate lazy var bridgedDelegate: BridgedFetchedResultsDelegate = BridgedFetchedResultsDelegate(
        willChangeContent: { [unowned self] (controller) in
            self.sectionChanges.removeAll()
            self.objectChanges.removeAll()
            self.updatedObjects.removeAll()
        },
        didChangeSection: { [unowned self] (controller, sectionInfo, sectionIndex, changeType) in
            self.sectionChanges.append((changeType, sectionIndex))
        },
        didChangeObject: { [unowned self] (controller, anyObject, indexPath: IndexPath?, changeType, newIndexPath: IndexPath?) in
            switch changeType {
            case .insert:
                if let insertIndexPath = newIndexPath {
                    self.objectChanges.append((changeType, [insertIndexPath]))
                }
            case .delete:
                if let deleteIndexPath = indexPath {
                    self.objectChanges.append((changeType, [deleteIndexPath]))
                }
            case .update:
                if let indexPath = indexPath {
                    self.objectChanges.append((changeType, [indexPath]))
                    self.updatedObjects[indexPath] = anyObject as? Item
                }
            case .move:
                if let old = indexPath, let new = newIndexPath {
                    self.objectChanges.append((changeType, [old, new]))
                }
            }
        },
        didChangeContent: { [unowned self] (controller) in

            self.collectionView?.performBatchUpdates({ [weak self] in
                self?.applyObjectChanges()
                self?.applySectionChanges()
                },
                completion:{ [weak self] finished in
                    self?.reloadSupplementaryViewsIfNeeded()
                })
        })

    fileprivate func applyObjectChanges() {
        for (changeType, indexPaths) in objectChanges {

            switch(changeType) {
            case .insert:
                collectionView?.insertItems(at: indexPaths)
            case .delete:
                collectionView?.deleteItems(at: indexPaths)
            case .update:
                if let indexPath = indexPaths.first,
                    let item = updatedObjects[indexPath],
                    let cell = collectionView?.cellForItem(at: indexPath) as? CellFactory.Cell,
                    let view = collectionView {
                        cellFactory.configureCell(cell, forItem: item, inCollectionView: view, atIndexPath: indexPath)
                }
            case .move:
                if let deleteIndexPath = indexPaths.first {
                    self.collectionView?.deleteItems(at: [deleteIndexPath])
                }

                if let insertIndexPath = indexPaths.last {
                    self.collectionView?.insertItems(at: [insertIndexPath])
                }
            }
        }
    }

    fileprivate func applySectionChanges() {
        for (changeType, sectionIndex) in sectionChanges {
            let section = IndexSet(integer: sectionIndex)

            switch(changeType) {
            case .insert:
                collectionView?.insertSections(section)
            case .delete:
                collectionView?.deleteSections(section)
            default:
                break
            }
        }
    }

    fileprivate func reloadSupplementaryViewsIfNeeded() {
        if sectionChanges.count > 0 {
            collectionView?.reloadData()
        }
    }

}

/**
 A `TableViewFetchedResultsDelegateProvider` is responsible for providing a delegate object
 for an instance of `NSFetchedResultsController` that manages data to display in a table view.

 - warning: The `CellFactory.Item` type should correspond to the type of objects that the `NSFetchedResultsController` fetches.
 */
public final class TableViewFetchedResultsDelegateProvider <CellFactory: TableViewCellFactoryType>: CustomStringConvertible {

    // MARK: Typealiases

    /// The type of elements for the delegate provider.
    public typealias Item = CellFactory.Item


    // MARK: Properties

    /**
    The table view that displays the data from the `NSFetchedResultsController`
    for which this provider provides a delegate.
    */
    public weak var tableView: UITableView?

    /// Returns the cell factory for this delegate provider.
    public let cellFactory: CellFactory

    /// Returns the object that is notified when the fetched results changed.
    public var delegate: NSFetchedResultsControllerDelegate { return bridgedDelegate }


    // MARK: Initialization

    /**
    Constructs a new delegate provider for a fetched results controller.

    - parameter tableView:                The table view to be updated when the fetched results change.
    - parameter cellFactory:              The cell factory from which the fetched results controller delegate will configure cells.
    - parameter fetchedResultsController: The fetched results controller whose delegate will be provided by this provider.

    - returns: A new `TableViewFetchedResultsDelegateProvider` instance.
    */
    public init(tableView: UITableView, cellFactory: CellFactory, fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView = tableView
        self.cellFactory = cellFactory
        fetchedResultsController.delegate = delegate
    }


    // MARK: CustomStringConvertible

    /// :nodoc:
    public var description: String {
        get {
            return "<\(TableViewFetchedResultsDelegateProvider.self): tableView=\(tableView)>"
        }
    }


    // MARK: Private

    fileprivate lazy var bridgedDelegate: BridgedFetchedResultsDelegate = BridgedFetchedResultsDelegate(
        willChangeContent: { [unowned self] (controller) in
            self.tableView?.beginUpdates()
        },
        didChangeSection: { [unowned self] (controller, sectionInfo, sectionIndex, changeType) in
            switch changeType {
            case .insert:
                self.tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                self.tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                break
            }
        },
        didChangeObject: { [unowned self] (controller, anyObject, indexPath, changeType, newIndexPath) in
            switch changeType {
            case .insert:
                if let insertIndexPath = newIndexPath {
                    self.tableView?.insertRows(at: [insertIndexPath], with: .fade)
                }
            case .delete:
                if let deleteIndexPath = indexPath {
                    self.tableView?.deleteRows(at: [deleteIndexPath], with: .fade)
                }
            case .update:
                if let indexPath = indexPath,
                    let cell = self.tableView?.cellForRow(at: indexPath) as? CellFactory.Cell,
                    let view = self.tableView {
                        self.cellFactory.configureCell(cell, forItem: anyObject as! Item, inTableView: view, atIndexPath: indexPath)
                }
            case .move:
                if let deleteIndexPath = indexPath {
                    self.tableView?.deleteRows(at: [deleteIndexPath], with: .fade)
                }

                if let insertIndexPath = newIndexPath {
                    self.tableView?.insertRows(at: [insertIndexPath], with: .fade)
                }
            }
        },
        didChangeContent: { [unowned self] (controller) in
            self.tableView?.endUpdates()
        })
}


/*
Avoid making DelegateProvider inherit from NSObject.
Keep classes pure Swift.
Keep responsibilies focused.
*/
@objc private final class BridgedFetchedResultsDelegate: NSObject, NSFetchedResultsControllerDelegate {

    typealias WillChangeContentHandler = (NSFetchedResultsController<NSFetchRequestResult>) -> Void
    typealias DidChangeSectionHandler = (NSFetchedResultsController<NSFetchRequestResult>, NSFetchedResultsSectionInfo, Int, NSFetchedResultsChangeType) -> Void
    typealias DidChangeObjectHandler = (NSFetchedResultsController<NSFetchRequestResult>, AnyObject, IndexPath?, NSFetchedResultsChangeType, IndexPath?) -> Void
    typealias DidChangeContentHandler = (NSFetchedResultsController<NSFetchRequestResult>) -> Void

    let willChangeContent: WillChangeContentHandler
    let didChangeSection: DidChangeSectionHandler
    let didChangeObject: DidChangeObjectHandler
    let didChangeContent: DidChangeContentHandler

    init(willChangeContent: @escaping WillChangeContentHandler,
        didChangeSection: @escaping DidChangeSectionHandler,
        didChangeObject: @escaping DidChangeObjectHandler,
        didChangeContent: @escaping DidChangeContentHandler) {

            self.willChangeContent = willChangeContent
            self.didChangeSection = didChangeSection
            self.didChangeObject = didChangeObject
            self.didChangeContent = didChangeContent
    }

    @objc func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        willChangeContent(controller)
    }

    @objc func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType) {
            didChangeSection(controller, sectionInfo, sectionIndex, type)
    }

    @objc func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?) {
            didChangeObject(controller, anObject as AnyObject, indexPath, type, newIndexPath)
    }
    
    @objc func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        didChangeContent(controller)
    }
}
