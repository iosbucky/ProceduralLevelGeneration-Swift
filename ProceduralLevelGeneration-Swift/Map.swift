//
//  Map.swift
//  ProceduralLevelGeneration-Swift
//
//  Created by iOS Bucky on 7/16/15.
//  Copyright (c) 2015 iOS Bucky. All rights reserved.
//

import SpriteKit

class Map : SKNode {
    
    let gridSize: CGSize!
    var spawnPoint = CGPointZero
    var exitPoint = CGPointZero
    var maxFloorCount: UInt = 110
    
    var turnResistance = 20
    var floorMakerSpawnProbability = 25
    var maxFloorMakerCount = 5
    var roomProbability = 20
    
    var roomMinSize = CGSize(width: 2, height: 2)
    var roomMaxSize = CGSize(width: 6, height: 6)
    
    var tiles: MapTiles!
    let tileAtlas: SKTextureAtlas!
    let tileSize: CGFloat!
    var floorMakers = [FloorMaker]()

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(gridSize: CGSize) {
        self.gridSize = gridSize
        
        tileAtlas = SKTextureAtlas(named: "tiles")
        let textureNames = tileAtlas.textureNames
        let textureName = textureNames.first as? String
        let tileTexture = tileAtlas.textureNamed(textureName!)
        tileSize = tileTexture.size().width
        
        super.init()
    }
    
    func generateTileGrid() {
        let startPoint = CGPoint(x: tiles.gridSize.width / 2, y: tiles.gridSize.height / 2)
        spawnPoint = convertMapCoordinateToWorldCoordinate(startPoint)
        
        
        tiles.setTileType(.Floor, atTileCoordinate: startPoint)
        var currentFloorCount: UInt = 1
        floorMakers.append(FloorMaker(currentPosition: startPoint, direction: 0))
        
        while currentFloorCount < maxFloorCount {
            for floorMaker in floorMakers {
                if floorMaker.direction == 0 || randomNumberBetween(0, max: 100) <= turnResistance {
                    floorMaker.direction = randomNumberBetween(1, max: 4)
                }
                
                var newPosition = CGPointZero
                switch floorMaker.direction {
                case 1:     // Up
                    newPosition = CGPoint(x: floorMaker.currentPosition.x, y: floorMaker.currentPosition.y - 1)
                case  2:    // Down
                    newPosition = CGPoint(x: floorMaker.currentPosition.x, y: floorMaker.currentPosition.y + 1)
                case 3:     // Left
                    newPosition = CGPoint(x: floorMaker.currentPosition.x - 1, y: floorMaker.currentPosition.y)
                case 4:     // Right
                    newPosition = CGPoint(x: floorMaker.currentPosition.x + 1, y: floorMaker.currentPosition.y)
                default:
                    break
                }
                
                if tiles.isValidTileCoordinateAt(newPosition) && !tiles.isEdgeTileAt(newPosition) && tiles.tileTypeAt(newPosition) == .None && currentFloorCount < maxFloorCount {
                    floorMaker.currentPosition = newPosition
                    tiles.setTileType(.Floor, atTileCoordinate: floorMaker.currentPosition)
                    currentFloorCount++
                    
                    if randomNumberBetween(0, max: 100) <= roomProbability {
                    
                        let roomSizeX = randomNumberBetween(Int(roomMinSize.width), max: Int(roomMaxSize.width))
                        let roomSizeY = randomNumberBetween(Int(roomMinSize.height), max: Int(roomMaxSize.height))
                        currentFloorCount += generateRoomAt(floorMaker.currentPosition, size: CGSize(width: roomSizeX, height: roomSizeY))
                    }
                    
                    exitPoint = convertMapCoordinateToWorldCoordinate(floorMaker.currentPosition)
                }
                
                if randomNumberBetween(0, max: 100) <= floorMakerSpawnProbability && floorMakers.count < Int(maxFloorMakerCount) {
                    let newFloorMaker = FloorMaker(currentPosition: floorMaker.currentPosition, direction: randomNumberBetween(1, max: 4))
                    floorMakers.append(newFloorMaker)
                }
            }
        }
        NSLog("%@", tiles.description)
    }
    
    func generate() {
        tiles = MapTiles(gridSize: gridSize)
        generateTileGrid()
        generateWalls()
        generateTiles()
        generateCollisionWalls()
    }
    
    func randomNumberBetween(min:Int, max: Int) -> Int{
        return min + Int(arc4random()) % (max - min)
    }
    
    func generateTiles() {
        for var y = 0; y < Int(tiles.gridSize.height); y++ {
            for var x = 0; x < Int(tiles.gridSize.width); x++ {
                let tileCoordinate = CGPoint(x: x, y: y)
                let tileType = tiles.tileTypeAt(tileCoordinate)
                if tileType != .None {
                    var textureImageName: String?
                    switch tileType {
                        case .Invalid, .None:
                            println("shouldn't happen")
                            break
                        case .Floor:
                            textureImageName = "1"
                        case .Wall:
                            textureImageName = "2"
                    }
                    
                    let tileTexture = tileAtlas.textureNamed(textureImageName!)
                    let tile = SKSpriteNode(texture: tileTexture)
                    tile.position = convertMapCoordinateToWorldCoordinate(CGPoint(x:tileCoordinate.x, y: tileCoordinate.y))
                    addChild(tile)
                }
            }
        }
        
    }
    
    func convertMapCoordinateToWorldCoordinate(mapCoordinate: CGPoint) -> CGPoint {
        return CGPoint(x: mapCoordinate.x * tileSize, y: (tiles.gridSize.height - mapCoordinate.y) * tileSize)
    }
    
    func generateWalls() {
        for var y = 0; y < Int(tiles.gridSize.height); y++ {
            for var x = 0; x < Int(tiles.gridSize.width); x++ {
                let tileCoordinate = CGPoint(x: x, y: y)
                
                if tiles.tileTypeAt(tileCoordinate) == .Floor {
                    for var neighborY = -1; neighborY < 2; neighborY++ {
                        for var neighborX = -1; neighborX < 2; neighborX++ {
                            if !(neighborX == 0 && neighborY == 0) {
                                let coordinate = CGPoint(x: x + neighborX, y: y + neighborY)
                                
                                if tiles.tileTypeAt(coordinate) == .None {
                                    tiles.setTileType(.Wall, atTileCoordinate: coordinate)
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    func addCollisionWallAtPosition(position: CGPoint, size: CGSize) {
        let wall = SKNode()
        
        wall.position = CGPoint(x: position.x + size.width * 0.5 - 0.5 * tileSize, y: position.y - size.height * 0.5 + 0.5 * tileSize)
        wall.physicsBody = SKPhysicsBody(rectangleOfSize: size)
        wall.physicsBody?.dynamic = false
        wall.physicsBody?.categoryBitMask = CollisionType.Wall
        wall.physicsBody?.contactTestBitMask = 0
        wall.physicsBody?.collisionBitMask = CollisionType.Player
        
        addChild(wall)
    }
    
    func generateCollisionWalls() {
        for var y = 0; y < Int(tiles.gridSize.height); y++ {
            var startPointForWall = CGFloat(0)
            var wallLength = CGFloat(0)
            
            for var x = 0; x < Int(tiles.gridSize.width); x++ {
                let tileCoordinate = CGPoint(x: x, y: y)
                if tiles.tileTypeAt(tileCoordinate) == .Wall {
                    if startPointForWall == 0 && wallLength == 0 {
                        startPointForWall = CGFloat(x)
                    }
                    wallLength += 1
                } else if wallLength > 0 {
                    let wallOrigin = CGPoint(x: startPointForWall, y: CGFloat(y))
                    let wallSize = CGSize(width: wallLength * tileSize, height: tileSize)
                    addCollisionWallAtPosition(convertMapCoordinateToWorldCoordinate(wallOrigin), size: wallSize)
                    
                    startPointForWall = 0
                    wallLength = 0
                }
            }
        }
    }
    
    func generateRoomAt(position: CGPoint, size: CGSize) -> UInt {
        var numberOfFloorsGenerated = UInt(0)
        for var y = 0; y < Int(size.height); y++ {
            for var x = 0; x < Int(size.width); x++ {
                let tilePosition = CGPoint(x: position.x + CGFloat(x), y: position.y + CGFloat(y))
                if tiles.tileTypeAt(tilePosition) == .Invalid {
                    continue
                }
                
                if !tiles.isEdgeTileAt(tilePosition) {
                    if tiles.tileTypeAt(tilePosition) == .None {
                        tiles.setTileType(.Floor, atTileCoordinate: tilePosition)
                        numberOfFloorsGenerated++
                    }
                }
            }
        }
        return numberOfFloorsGenerated
    }
}
