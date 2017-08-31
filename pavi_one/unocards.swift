//
//  unocards.swift
//  pavi_one
//
//  Created by masounda on 17/08/17.
//  Copyright © 2017 zorkon. All rights reserved.
//

import UIKit

let index:Int = 0
let mask:Int = 0
var lastCard = (index:0,mask:0)
var lastb4Card = (index:0,mask:0)
var cardType = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "DrawTwo", "Reverse", "Skip", "drawFour", "wild"]
var cardMsk  = [1, 2, 4, 8, 16, 32, 64, 128]
var cardColor = ["blue", "green", "yellow", "red","blue", "green", "yellow", "red"]

var indexMaskArray = [(index:0,mask:0)]

class unocards: UIImageView {
    
    var cardFlag :[Int] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    var name: String = ""
    
    
    //SHOW CARD in Dictionary Format
    func showCard() {
        print(self.cardFlag)
    }
    
    //COUNT CARD from the cardFlag values
    func countCard() -> Int {
        var cardNum = 0
        for cardMask in self.cardFlag {
            for i in  cardMsk {
                if cardMask & i == i {
                    cardNum += 1
                }
            }
            
        }
        return cardNum
    }
    
    //PICK A RANDON CARD from the input object using given for DECK OBJ
    func randomCard() -> (index:Int, mask:Int) {
        let randLarge = Int(arc4random_uniform(60))
        let tempIndex = randLarge % 15
        let tempMask = cardMsk[Int(arc4random_uniform(8))]
        if self.cardFlag[tempIndex] & tempMask == tempMask {
            return (tempIndex, tempMask)
        }
        else {
            //Recurssion
            return randomCard()
        }
    }
    
    //Release the card from the cardFlag array
    func putCard(cardIndex:Int,cardMask:Int) {
        self.cardFlag[cardIndex] = self.cardFlag[cardIndex] ^ cardMask
    }
    
    //Insert the card to the cardFlag array
    func takeCard(cardIndex:Int,cardMask:Int) {
        self.cardFlag[cardIndex] = self.cardFlag[cardIndex] | cardMask
    }
    
    //match a card to the last card of the round
    func matchCard() -> Int {
        var cardIndex:Int = 0
        var bitMask:Int = lastCard.mask
        var flag:Int = 0
        if self.cardFlag[13] != 0 {
            cardIndex = 13
            let currCardFlag = self.cardFlag[13]
            var maskId = 1
            for _ in 0...3 {
                if (currCardFlag & maskId == maskId) {
                    bitMask = maskId
                    break
                }
                maskId <<= 1
            }
            flag = 1
        }
        else if self.cardFlag[14] != 0 {
            cardIndex = 14
            let currCardFlag = self.cardFlag[14]
            var maskId = 1
            for _ in 0...3 {
                if (currCardFlag & maskId == maskId) {
                    bitMask = maskId
                    break
                }
                maskId <<= 1
            }
            flag = 1
        }
        else {
            for flagIndex in 0 ... 13 {
                let currCardFlag = self.cardFlag[flagIndex]
                cardIndex = flagIndex
                var  maskInverse_1:Int = 0
                if lastCard.mask < 16 {
                    maskInverse_1 = lastCard.mask << 4
                } else {
                    maskInverse_1 = lastCard.mask >> 4
                }
                if currCardFlag & lastCard.mask == lastCard.mask {
                    flag = 1
                    break
                }
                else if currCardFlag & maskInverse_1 == maskInverse_1 {
                    bitMask = maskInverse_1
                    flag = 1
                    break
                }
                else if flagIndex == lastCard.index {
                    var maskId_2 = 1
                    for _ in 0...3 {
                        let maskInverse_2 = maskId_2 << 4
                        if (currCardFlag & maskId_2 == maskId_2) || (currCardFlag & maskInverse_2 == maskInverse_2 ) {
                            if currCardFlag & maskId_2 == maskId_2 {
                                bitMask = maskId_2
                            } else {
                                bitMask = maskInverse_2
                            }
                            flag = 1
                            break
                        }
                        maskId_2 <<= 1
                        //maskInverse_2 <<= 1
                    }
                    if flag == 1 {
                        break
                    }
                }
            }
        }
        if flag == 1 {
            //print(cardIndex,bitMask)
            self.putCard(cardIndex: cardIndex, cardMask: bitMask)
            lastb4Card = lastCard
            lastCard = (index: cardIndex, mask: bitMask)
            flag = 1
        }
        else {
            flag = 0
        }
        return (flag)
    }
    
    func matchCardList() -> [String] {
        let bitMask:Int = lastCard.mask
        var cardNames =  [String]()
        indexMaskArray = [(index:0,mask:0)]
        _ = indexMaskArray.popLast()
        for (index,maskValue) in self.cardFlag.enumerated() {
            if index < 13 {
                if lastCard.index == index {
                    for maskId in cardMsk {
                        if (maskValue & maskId == maskId) {
                            cardNames.append(cardColor[cardMsk.index(of: maskId)!] + cardType[index])
                            indexMaskArray.append((index: index, mask: maskId))
                        }
                    }
                } else {
                    var  maskInverse:Int = 0
                    if lastCard.mask < 16 {
                        maskInverse = lastCard.mask << 4
                    } else {
                        maskInverse = lastCard.mask >> 4
                    }
                    if maskValue & bitMask == bitMask {
                        cardNames.append(cardColor[cardMsk.index(of: bitMask)!] + cardType[index])
                        indexMaskArray.append((index: index, mask: bitMask ))
                    }
                    if maskValue & maskInverse == maskInverse {
                        cardNames.append(cardColor[cardMsk.index(of: maskInverse)!] + cardType[index])
                        indexMaskArray.append((index: index, mask: maskInverse ))
                    }
                }
            } else {
                if maskValue != 0 {
                    cardNames.append(cardType[index])
                }
                var maskId = 1
                for _ in 0...3 {
                    if (maskValue & maskId == maskId) {
                        indexMaskArray.append((index: index, mask: maskId))
                    }
                    maskId <<= 1
                }
            }
        }
        return (cardNames)
    }
    
    //Print the card @ hand for each object
    func printCard() {
        var cardNames = [String]()
        for (index,cardMask) in self.cardFlag.enumerated() {
            for (j,i) in  cardMsk.enumerated() {
                if cardMask & i == i {
                    cardNames.append("\(cardType[index])_of_\(cardColor[j])")
                }
            }
            
        }
        self.showCard()
        print(self.countCard())
    }
    
}

