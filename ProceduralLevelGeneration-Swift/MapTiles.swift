//
//  MapTiles.swift
//  ProceduralLevelGeneration-Swift
//
//  Created by iOS Bucky on 7/16/15.
//  Copyright (c) 2015 iOS Bucky. All rights reserved.
//

import Foundation
import CoreGraphics

enum MapTileType: Int {
    case Invalid = -1
    case None = 0
    case Floor = 1
    case Wall = 2
}

class MapTiles: Printable {
    var gridSize = CGSizeZero
    
    private var tiles = [MapTileType]()
    
    init(gridSize: CGSize) {
        self.gridSize = gridSize
        tiles = [MapTileType](count: Int(gridSize.height * gridSize.width), repeatedValue: .None)
    }

    func isValidTileCoordinateAt(tileCoordinate: CGPoint) -> Bool {
        return !(tileCoordinate.x < 0 || tileCoordinate.x >= gridSize.width || tileCoordinate.y < 0 || tileCoordinate.y >= gridSize.height)
    }
    
    func tileIndexAt(tileCoordinate: CGPoint) -> Int {
        if !isValidTileCoordinateAt(tileCoordinate) {
            return -1
        }
        return Int(tileCoordinate.y) * Int(gridSize.width) + Int(tileCoordinate.x)
    }

    func tileTypeAt(tileCoordinate: CGPoint) -> MapTileType {
        let tileArrayIndex = tileIndexAt(tileCoordinate)
        if tileArrayIndex == -1 {
            NSLog("Not a valid tile coordinate at %.0f,%.0f", tileCoordinate.x, tileCoordinate.y)
            return .Invalid
        }
        return tiles[tileArrayIndex]
    }
    
    func setTileType(type: MapTileType, atTileCoordinate tileCooridinate: CGPoint) {
        let tileArrayIndex = tileIndexAt(tileCooridinate)
        if tileArrayIndex == -1 {
            return
        }
        tiles[tileArrayIndex] = type
    }
    
    func isEdgeTileAt(tileCoordinate: CGPoint) -> Bool {
        return tileCoordinate.x == 0 || tileCoordinate.x == gridSize.width - 1 || tileCoordinate.y == 0 || tileCoordinate.y == gridSize.height - 1
    }
    
    var description: String {
        var tileMapDescription = String(format: "<MapTiles = %p | \n", unsafeAddressOf(self))
        for var y = Int(gridSize.width) - 1; y >= 0; y-- {
            tileMapDescription += "[\(y)]"
            for var x = 0; x < Int(gridSize.height); x++ {
                tileMapDescription += "\(tileTypeAt(CGPoint(x: x, y: y)).rawValue)"
            }
            tileMapDescription += "\n"
        }
     return tileMapDescription
    }
}