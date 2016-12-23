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


// Fakes for testing

typealias CellFactory = CollectionViewCellFactory<FakeCollectionCell, FakeViewModel>
typealias SupplementaryViewFactory = CollectionSupplementaryViewFactory<FakeCollectionSupplementaryView, FakeViewModel>
typealias Section = CollectionViewSection<FakeViewModel>
typealias Provider = CollectionViewDataSourceProvider<Section, CellFactory, SupplementaryViewFactory>


class FakeCollectionCell: UICollectionViewCell {

}


class FakeCollectionSupplementaryView: UICollectionReusableView {

}


class FakeCollectionView: UICollectionView {

    var dequeueCellExpectation: XCTestExpectation?

    var dequeueSupplementaryViewExpectation: XCTestExpectation?

    override func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        dequeueCellExpectation?.fulfill()
        return super.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }

    override func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView {
        dequeueSupplementaryViewExpectation?.fulfill()
        return super.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for: indexPath)
    }
}


let FakeSupplementaryViewKind = "FakeSupplementaryViewKind"


class FakeFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == FakeSupplementaryViewKind {
            return UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        }

        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
}
