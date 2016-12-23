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

import Foundation
import UIKit
import XCTest

import JSQDataSourcesKit


class CollectionViewDataSourceTests: XCTestCase {

    fileprivate let fakeCellReuseId = "fakeCellId"
    fileprivate let fakeSupplementaryViewReuseId = "fakeSupplementaryId"

    fileprivate let fakeCollectionView = FakeCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 600), collectionViewLayout: FakeFlowLayout())
    fileprivate let dequeueCellExpectationName = "collectionview_dequeue_cell_expectation"
    fileprivate let dequeueSupplementaryViewExpectationName = "collectionview_dequeue_supplementaryview_expectation"

    override func setUp() {
        super.setUp()

        fakeCollectionView.register(FakeCollectionCell.self,
            forCellWithReuseIdentifier: fakeCellReuseId)

        fakeCollectionView.register(FakeCollectionSupplementaryView.self,
            forSupplementaryViewOfKind: FakeSupplementaryViewKind,
            withReuseIdentifier: fakeSupplementaryViewReuseId)
    }

    func test_ThatCollectionViewDataSource_ReturnsExpectedData_ForSingleSection() {

        // GIVEN: a single CollectionViewSection with data items
        let expectedModel = FakeViewModel()
        let expectedIndexPath = IndexPath(row: 3, section: 0)

        let section0 = CollectionViewSection(items: FakeViewModel(), FakeViewModel(), FakeViewModel(), expectedModel, FakeViewModel())
        let allSections = [section0]

        let cellFactoryExpectation = expectation(description: "\(#function)")
        fakeCollectionView.dequeueCellExpectation = expectation(description: dequeueCellExpectationName + "\(#function)")

        // GIVEN: a cell factory
        let factory = CollectionViewCellFactory(reuseIdentifier: fakeCellReuseId)
            { (cell: FakeCollectionCell, model: FakeViewModel, view: UICollectionView, indexPath: IndexPath) -> FakeCollectionCell in
                XCTAssertEqual(cell.reuseIdentifier!, self.fakeCellReuseId, "Dequeued cell should have expected identifier")
                XCTAssertEqual(model, expectedModel, "Model object should equal expected value")
                XCTAssertEqual(view, self.fakeCollectionView, "CollectionView should equal the collectionView for the data source")
                XCTAssertEqual(indexPath, expectedIndexPath, "IndexPath should equal expected value")

                cellFactoryExpectation.fulfill()
                return cell
        }

        // GIVEN: a data source provider
        typealias CellFactory = CollectionViewCellFactory<FakeCollectionCell, FakeViewModel>
        typealias SupplementaryViewFactory = CollectionSupplementaryViewFactory<FakeCollectionSupplementaryView, FakeViewModel>
        typealias Section = CollectionViewSection<FakeViewModel>
        typealias Provider = CollectionViewDataSourceProvider<Section, CellFactory, SupplementaryViewFactory>

        let dataSourceProvider: Provider = CollectionViewDataSourceProvider(sections: allSections, cellFactory: factory, collectionView: fakeCollectionView)
        let dataSource = dataSourceProvider.dataSource

        // WHEN: we call the collection view data source methods
        let numSections = dataSource.numberOfSections?(in: fakeCollectionView)
        let numRows = dataSource.collectionView(fakeCollectionView, numberOfItemsInSection: 0)
        let cell = dataSource.collectionView(fakeCollectionView, cellForItemAt: expectedIndexPath)

        // THEN: we receive the expected return values
        XCTAssertNotNil(numSections, "Number of sections should not be nil")
        XCTAssertEqual(numSections!, dataSourceProvider.sections.count, "Data source should return expected number of sections")

        XCTAssertEqual(numRows, section0.count, "Data source should return expected number of rows for section 0")

        XCTAssertEqual(cell.reuseIdentifier!, fakeCellReuseId, "Data source should return cells with the expected identifier")

        // THEN: the collectionView calls `dequeueReusableCellWithReuseIdentifier`
        // THEN: the cell factory calls its `ConfigurationHandler`
        waitForExpectations(timeout: DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expectation should not error")
        })
    }

    func test_ThatCollectionViewDataSource_ReturnsExpectedData_ForMultipleSections() {

        // GIVEN: some collection view sections
        let section0 = CollectionViewSection(items: FakeViewModel(), FakeViewModel(), FakeViewModel(), FakeViewModel(), FakeViewModel(), FakeViewModel())
        let section1 = CollectionViewSection(items: FakeViewModel(), FakeViewModel())
        let section2 = CollectionViewSection(items: FakeViewModel(), FakeViewModel(), FakeViewModel(), FakeViewModel())
        let allSections = [section0, section1, section2]

        var cellFactoryExpectation = expectation(description: "cell_factory_\(#function)")

        // GIVEN: a cell factory
        let cellFactory = CollectionViewCellFactory(reuseIdentifier: fakeCellReuseId)
            { (cell: FakeCollectionCell, model: FakeViewModel, view: UICollectionView, indexPath: IndexPath) -> FakeCollectionCell in
                XCTAssertEqual(cell.reuseIdentifier!, self.fakeCellReuseId, "Dequeued cell should have expected identifier")
                XCTAssertEqual(model, allSections[indexPath.section][indexPath.item], "Model object should equal expected value")
                XCTAssertEqual(view, self.fakeCollectionView, "CollectionView should equal the collectionView for the data source")

                cellFactoryExpectation.fulfill()
                return cell
        }

        var supplementaryFactoryExpectation = expectation(description: "supplementary_factory_\(#function)")

        // GIVEN: a supplementary view factory
        let supplementaryViewFactory = CollectionSupplementaryViewFactory(reuseIdentifier: fakeSupplementaryViewReuseId)
            { (view: FakeCollectionSupplementaryView, model: FakeViewModel, kind: String, collectionView: UICollectionView, indexPath: IndexPath) -> FakeCollectionSupplementaryView in
                XCTAssertEqual(view.reuseIdentifier!, self.fakeSupplementaryViewReuseId, "Dequeued supplementary view should have expected identifier")
                XCTAssertEqual(model, allSections[indexPath.section][indexPath.item], "Model object should equal expected value")
                XCTAssertEqual(kind, FakeSupplementaryViewKind, "View kind should have expected kind")
                XCTAssertEqual(collectionView, self.fakeCollectionView, "CollectionView should equal the collectionView for the data source")

                supplementaryFactoryExpectation.fulfill()
                return view
        }

        // GIVEN: a data source provider
        let dataSourceProvider = CollectionViewDataSourceProvider(
            sections: allSections,
            cellFactory: cellFactory,
            supplementaryViewFactory: supplementaryViewFactory,
            collectionView: fakeCollectionView)

        let dataSource = dataSourceProvider.dataSource

        // WHEN: we call the collection view data source methods
        let numSections = dataSource.numberOfSections?(in: fakeCollectionView)

        // THEN: we receive the expected return values
        XCTAssertNotNil(numSections, "Number of sections should not be nil")
        XCTAssertEqual(numSections!, dataSourceProvider.sections.count, "Data source should return expected number of sections")

        for sectionIndex in 0..<dataSourceProvider.sections.count {
            for rowIndex in 0..<dataSourceProvider[sectionIndex].items.count {

                let expectationName = "\(#function)_\(sectionIndex)_\(rowIndex)"
                fakeCollectionView.dequeueCellExpectation = expectation(description: dequeueCellExpectationName + expectationName)
                fakeCollectionView.dequeueSupplementaryViewExpectation = expectation(description: dequeueSupplementaryViewExpectationName + expectationName)

                let indexPath = IndexPath(item: rowIndex, section: sectionIndex)

                // WHEN: we call the collection view data source methods
                let numRows = dataSource.collectionView(fakeCollectionView, numberOfItemsInSection: sectionIndex)
                let cell = dataSource.collectionView(fakeCollectionView, cellForItemAt: indexPath)
                let supplementaryView = dataSource.collectionView?(fakeCollectionView, viewForSupplementaryElementOfKind: FakeSupplementaryViewKind, at: indexPath)

                // THEN: we receive the expected return values
                XCTAssertEqual(numRows, dataSourceProvider[sectionIndex].count, "Data source should return expected number of rows for section \(sectionIndex)")

                XCTAssertEqual(cell.reuseIdentifier!, fakeCellReuseId, "Data source should return cells with the expected identifier")

                XCTAssertNotNil(supplementaryView, "Supplementary view should not be nil")
                XCTAssertEqual(supplementaryView!.reuseIdentifier!, fakeSupplementaryViewReuseId, "Data source should return supplementary views with the expected identifier")

                // THEN: the collectionView calls `dequeueReusableCellWithReuseIdentifier`
                // THEN: the cell factory calls its `ConfigurationHandler`
                
                // THEN: the collectionView calls `dequeueReusableSupplementaryViewOfKind`
                // THEN: the supplementary view factory calls its `ConfigurationHandler`
                waitForExpectations(timeout: DefaultTimeout, handler: { (error) -> Void in
                    XCTAssertNil(error, "Expections should not error")
                })

                // reset expectation names for next loop, ignore last item
                if !(sectionIndex == dataSourceProvider.sections.count - 1 && rowIndex == dataSourceProvider[sectionIndex].count - 1) {
                    cellFactoryExpectation = expectation(description: "cell_factory_" + expectationName)
                    supplementaryFactoryExpectation = expectation(description: "supplementary_factory_" + expectationName)
                }
            }
        }
    }
    
    func test_ThatCollectionViewDataSource_ReturnsFalseOnCanMoveItemAtIndexPath_ForNilUserMovedHandler() {
        // GIVEN: some collection view sections
        let section = CollectionViewSection(items: FakeViewModel())
        
        // GIVEN: a cell factory
        let cellFactory = CollectionViewCellFactory(reuseIdentifier: fakeCellReuseId) { (cell: FakeCollectionCell, _: FakeViewModel, _, _) in
            return cell
        }
        
        // GIVEN: a supplementary view factory
        let supplementaryViewFactory = CollectionSupplementaryViewFactory(reuseIdentifier: fakeSupplementaryViewReuseId) { (view: FakeCollectionSupplementaryView, model: FakeViewModel, _, _, _) in
            return view
        }
        
        // GIVEN: a data source provider without a userMovedHandler
        let dataSourceProvider = CollectionViewDataSourceProvider(
            sections: [section],
            cellFactory: cellFactory,
            supplementaryViewFactory: supplementaryViewFactory,
            collectionView: fakeCollectionView)
        
        let dataSource = dataSourceProvider.dataSource

        // WHEN; we call canMoveItemAtIndexPath
        let canMove = dataSource.collectionView!(fakeCollectionView, canMoveItemAt: IndexPath(item: 0, section: 0))
        
        // THEN; the return value should be false
        XCTAssertFalse(canMove, "Data source should return false for canMoveItemAtIndexPath if a userMovedHandler was not provided")
    }
    
    func test_ThatCollectionViewDataSource_CallsUserMovedHandler_WhenReorderingItems() {
        
        return // This test is impossible to pass right now
        
        // GIVEN: some collection view sections
        let section = CollectionViewSection(items: FakeViewModel(), FakeViewModel())
        
        // GIVEN: a cell factory
        let cellFactory = CollectionViewCellFactory(reuseIdentifier: fakeCellReuseId) { (cell: FakeCollectionCell, _: FakeViewModel, _, _) in
            return cell
        }
        
        // GIVEN: a supplementary view factory
        let supplementaryViewFactory = CollectionSupplementaryViewFactory(reuseIdentifier: fakeSupplementaryViewReuseId) { (view: FakeCollectionSupplementaryView, model: FakeViewModel, _, _, _) in
            return view
        }
        
        let userMovedExpectation = expectation(description: "cell_factory_\(#function)")
        
        // GIVEN: a data source provider with a userMovedHandler
        let dataSourceProvider = CollectionViewDataSourceProvider(
            sections: [section],
            cellFactory: cellFactory,
            supplementaryViewFactory: supplementaryViewFactory,
            userMovedHandler: { collectionView, item, cell, sourceIndexPath, destinationIndexPath in
                userMovedExpectation.fulfill()
            },
            collectionView: fakeCollectionView)
        
        let dataSource = dataSourceProvider.dataSource
        
        // WHEN; we call canMoveItemAtIndexPath
        let canMove = dataSource.collectionView!(fakeCollectionView, canMoveItemAt: IndexPath(item: 0, section: 0))
        
        // THEN; the return value should be false
        XCTAssertTrue(canMove, "Data source should return true for canMoveItemAtIndexPath if a userMovedHandler was provided")
        
        let fromIndexPath = IndexPath(item: 0, section: 0)
        let toIndexPath = IndexPath(item: 1, section: 0)
        
        // WHEN; we call moveItemAtIndexPath
        dataSource.collectionView?(fakeCollectionView, moveItemAt: fromIndexPath, to: toIndexPath)
        
        // THEN: the collection view data source provider calls its `UserMoveHandler`
        waitForExpectations(timeout: DefaultTimeout, handler: { (error) -> Void in
            XCTAssertNil(error, "Expections should not error")
        })
    }
}
