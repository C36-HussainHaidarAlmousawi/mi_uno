//
//  ViewController.swift
//  pavi_one
//
//  Created by masounda on 15/08/17.
//  Copyright © 2017 zorkon. All rights reserved.
//

import UIKit
import MultipeerConnectivity

var touchCardNames = [String]()
var cardObj = [unocards]()
var gameOverFlag:Bool = false
var firstTimeFlag:Bool = true
var mpcGameFlag:Bool = false

var winner = String()
var takeCardCount:Int = 1
class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {

    let serviceType = "UNO-GAME"
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    var message:String = "red"

    
    @IBOutlet var playerCards: [UIImageView]!
    @IBOutlet var touchCards: [UIImageView]!
    @IBOutlet weak var cpuCardNum: UILabel!
    @IBOutlet var deckCardImage: [UIImageView]!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var deck: unocards!
    @IBOutlet var lastCardImage: [UIImageView]!
    var p1: unocards!
    var c2: unocards!
    var us: unocards!
    
    @IBAction func newGameButton(_ sender: Any) {
        if mpcGameFlag {
            self.startMPCGame()
        } else {
            self.startGame()
        }
    }
    @IBAction func aboutGameButton(_ sender: Any) {
        print("uno")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mpcSetting()
        self.startGame()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //super.viewDidAppear(true)
        if gameOverFlag {
            print("GAME OVER")
            let alert = UIAlertController(title: "Uno Game", message: "The winner is \(winner)", preferredStyle: UIAlertControllerStyle.alert)
            if mpcGameFlag {
                if winner == UIDevice.current.name {
                    enemyTurn()
                }
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alert:UIAlertAction!) -> Void in
                    self.resetMPCDeck()
                }))
                self.present(alert, animated: true)
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alert:UIAlertAction!) -> Void in
                    self.startGame()
                }))
                self.present(alert, animated: true)
            }
            // do something
        }
        gameOverFlag = false
    }
    

    
    func startGame() {
        //DECK INITIALISATION
        gameOverFlag = false
        mpcGameFlag = false
        winner = String()
        activityIndicator.hidesWhenStopped = true
        self.resetCardView()
        self.deck = unocards()
        self.deck.name = "DEALER"
        self.p1 = unocards()
        self.p1.name = "PLAYER"
        self.c2 = unocards()
        self.c2.name = "SYSTEM"
        self.us = unocards()
        self.us.name = "SHUFFLE"
        //setupField()
        cardObj = [self.p1 , self.c2]
        self.resetDeck(objName1: self.deck,objName2: self.us)
        //deck.printCard()
        self.dealCard(objName: self.p1,count: 7)
        self.dealCard(objName: self.c2,count: 7)
        self.updateCardView()
        for index in 0 ... touchCards.count - 1 {
            self.touchCards[index].image = nil
        }
        lastCard = self.deck.randomCard()
        self.deck.putCard(cardIndex: lastCard.index, cardMask: lastCard.mask)
        self.us.takeCard(cardIndex: lastCard.index, cardMask: lastCard.mask)
        self.updateCardView()
        print(self.deck.name + " Turn ")
        determineTurn()
    }

    func startMPCGame() {
        mpcGameFlag = true
        gameOverFlag = false
        winner = String()
        activityIndicator.hidesWhenStopped = true
        self.resetCardView()
        self.deck = unocards()
        self.deck.name = "DEALER"
        self.p1 = unocards()
        self.p1.name = "PLAYER"
        self.c2 = unocards()
        self.c2.name = "ENEMY"
        self.us = unocards()
        self.us.name = "SHUFFLE"
        //setupField()
        cardObj = [self.p1 , self.c2]
        self.resetDeck(objName1: self.deck,objName2: self.us)
        //deck.printCard()
        self.dealCard(objName: self.p1,count: 7)
        self.dealCard(objName: self.c2,count: 7)
        self.updateCardView()
        for index in 0 ... touchCards.count - 1 {
            self.touchCards[index].image = nil
        }
        lastCard = self.deck.randomCard()
        self.deck.putCard(cardIndex: lastCard.index, cardMask: lastCard.mask)
        self.us.takeCard(cardIndex: lastCard.index, cardMask: lastCard.mask)
        self.updateCardView()
        determineMPCTurn()
    }
    
    func determineMPCTurn() {
        //cardObj[0].showCard()DEALER
        //print(cardObj[0].cardFlag)
        print("\(cardObj[0].name) Turn")
        if !gameOverFlag {
            swapDeckUnShuttfleCards()
            if cardObj[0].name != "PLAYER" {
                self.activityIndicator.startAnimating()
                enemyTurn()
            } else {
                self.activityIndicator.stopAnimating()
                playerTurn()
            }
        }
    }
    
    func enemyTurn() {
        var tempString = String()
        let tempObjArr : [unocards] = [deck,p1,c2,us]
        for tempObj in tempObjArr {
            let tempFlag:[String] = tempObj.cardFlag.map { String($0) }
            tempString.append(tempFlag.flatMap({$0}).joined(separator: ":"))
            tempString.append("_")
        }
        let strr = [String(lastCard.index), String(lastCard.mask), String(lastb4Card.index), String(lastb4Card.mask), String(takeCardCount) ,String(firstTimeFlag) , String(gameOverFlag), winner]
        message = tempString + strr.flatMap({$0}).joined(separator: "_")
        //print(message as String)
        self.view.backgroundColor = UIColor.yellow
        let msg = self.message.data(using: String.Encoding.utf8,allowLossyConversion: false)
        do {
            try self.session.send(msg!, toPeers: self.session.connectedPeers,with: MCSessionSendDataMode.unreliable)
        } catch let error as NSError {
            print("Error sending data: \(error.description)")
        } catch {
            print("other error")
        }
    }
    
    func deckTapped (recognizer:UITapGestureRecognizer) {
        self.deckCardImage[4].stopAnimating()
        self.dealCard(objName: p1, count: takeCardCount)
        self.resetField()
        self.updateCardView()
        for index in 0 ... self.deckCardImage.count - 1 {
            self.deckCardImage[index].removeGestureRecognizer(recognizer)
        }
        if (p1.matchCardList() != [String]()) && (takeCardCount == 1) {
            self.setupCardField()
        } else {
            takeCardCount = 1
            cardObj = cardObj.reversed()
            if mpcGameFlag {
                determineMPCTurn()
            } else {
                determineTurn()
            }
        }
    }
    
    func setupCardDeck() {
        for index in 0 ... self.deckCardImage.count - 1 {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.deckTapped(recognizer:)))
            gestureRecognizer.numberOfTapsRequired = 1
            self.deckCardImage[index].addGestureRecognizer(gestureRecognizer)
        }
        let imageArray = [UIImage(named: "uno_green")!, UIImage(named: "uno_red")!, UIImage(named: "uno_blue")!, UIImage(named: "uno_yellow")!]
        self.deckCardImage[4].animationDuration = 4.0
        self.deckCardImage[4].animationImages = imageArray
        self.deckCardImage[4].startAnimating()
        
    }
    
    func fieldTappedTurn (recognizer:UITapGestureRecognizer) {
        var cardNum  = 0
        var cflag = 0
        let tappedField  = recognizer.view as! UIImageView
        p1.putCard(cardIndex: indexMaskArray[tappedField.tag - 1].index, cardMask: indexMaskArray[tappedField.tag - 1].mask)
        cardNum = p1.countCard()
        self.us.takeCard(cardIndex: indexMaskArray[tappedField.tag - 1].index, cardMask: indexMaskArray[tappedField.tag - 1].mask)
        lastb4Card = lastCard
        lastCard = (index: indexMaskArray[tappedField.tag - 1].index, mask : indexMaskArray[tappedField.tag - 1].mask)
        self.resetField()
        self.updateCardView()
        for index in 0 ... self.touchCards.count - 1 {
            self.touchCards[index].removeGestureRecognizer(recognizer)
            self.touchCards[index].isUserInteractionEnabled = false
        }
        if  cardNum < 1 {
            print(" WINNER",terminator:"")
            gameOverFlag = true
            winner = UIDevice.current.name
            viewDidAppear(true)
        }
        else if cardNum < 2 {
            print(" UNO ",terminator:"")
        }
        if !gameOverFlag {
            cflag = self.specialCardHandle()
            if cflag != 0 {
                firstTimeFlag = true
            }
            if  cflag > 3 {
                setupColorField()
            } else {
                cardObj = cardObj.reversed()
                if mpcGameFlag {
                    determineMPCTurn()
                } else {
                    determineTurn()
                }
            }
        }
    }
    
    func colorTapped (recognizer:UITapGestureRecognizer) {
        let tappedField  = recognizer.view as! UIImageView
        var maskId = 1
        maskId <<= (tappedField.tag - 1)
        self.resetField()
        self.updateCardView()
        for index in 0 ... self.touchCards.count - 1 {
            self.touchCards[index].removeGestureRecognizer(recognizer)
            self.touchCards[index].isUserInteractionEnabled = false
        }
        lastCard.mask = maskId
        cardObj = cardObj.reversed()
        if mpcGameFlag {
            determineMPCTurn()
        } else {
            determineTurn()
        }
    }
    
    func setupColorField() {
        self.resetField()
        touchCardNames = ["blue", "green", "yellow", "red"]
        if touchCardNames != [String]() {
            var cardIndex:Int = 0
            for index in 0 ... touchCardNames.count - 1 {
                self.touchCards[index].isUserInteractionEnabled = true
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.colorTapped(recognizer:)))
                gestureRecognizer.numberOfTapsRequired = 1
                self.touchCards[index].addGestureRecognizer(gestureRecognizer)
                self.touchCards[index].image = UIImage(named: touchCardNames[index])
                cardIndex = cardIndex + 1
                if cardIndex > 7 {
                    print("No more image:space to show player cards")
                    break
                }
            }
        } else {
            print("no matching cards found.should have caught earlier")
        }
    }
    
    func setupCardField() {
        self.resetField()
        touchCardNames =  p1.matchCardList()
        if touchCardNames != [String]() {
            var cardIndex:Int = 0
            for index in 0 ... touchCardNames.count - 1 {
                self.touchCards[index].isUserInteractionEnabled = true
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.fieldTappedTurn(recognizer:)))
                gestureRecognizer.numberOfTapsRequired = 1
                self.touchCards[index].addGestureRecognizer(gestureRecognizer)
                self.touchCards[index].image = UIImage(named: touchCardNames[index])
                //self.touchCards[index].highlightedImage = UIImage(named: "highlight")
                cardIndex = cardIndex + 1
                if cardIndex > 7 {
                    print("No more image:space to show player cards")
                    break
                }
            }
        } else {
            print("no matching cards found.should have caught earlier")
        }
        
    }
    

    //UNO GAME FUNCTIONS

    func dealCard(objName:unocards,count:Int) {
        for _ in 1...count {
            if deck.countCard() == 0 {
                deck.cardFlag = us.cardFlag
                us.cardFlag = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            }
            let tempTuple = deck.randomCard()
            objName.takeCard(cardIndex: tempTuple.index, cardMask: tempTuple.mask)
            deck.putCard(cardIndex: tempTuple.index, cardMask: tempTuple.mask)
        }
    }
    
    //FUNCTION TO MAKE CPU PLAY GAME
    func botGamePlay(objName:unocards) {
        var cflag = 0
        if objName.matchCard() == 1 {
            us.takeCard(cardIndex: lastCard.index, cardMask: lastCard.mask)
            cflag = self.specialCardHandle()
            if cflag != 0 {
                firstTimeFlag = true
            }
        }
        else {
            //print("no match card @ hand taking from deck")
            swapDeckUnShuttfleCards()
            let tempCard = deck.randomCard()
            deck.putCard(cardIndex: tempCard.index, cardMask: tempCard.mask)
            objName.takeCard(cardIndex: tempCard.index, cardMask: tempCard.mask)
            if objName.matchCard() == 1 {
                us.takeCard(cardIndex: lastCard.index, cardMask: lastCard.mask)
                cflag = self.specialCardHandle()
                if cflag != 0 {
                    firstTimeFlag = true
                }
            }
            else {
                //print(" ^ ",terminator:"")
            }
        }
        let cardNum = objName.countCard()
        if  cardNum < 1 {
            print(" WINNER",terminator:"")
            gameOverFlag = true
            winner = c2.name
            viewDidAppear(true)
        }
        else if cardNum < 2 {
            print(" UNO ",terminator:"")
        }
    }
    
    func swapDeckUnShuttfleCards() {
        if self.deck.countCard() == 0 {
            self.deck.cardFlag = self.us.cardFlag
            self.us.cardFlag = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        }
    }
    

    func specialCardHandle() -> Int {
        var flag = 0
        if ((lastCard.index == 11) || (lastCard.index == 12)) {
            print("        play again ")
            flag = 1
        } else if lastCard.index == 10 {
            //self.dealCard(objName: cardObj[0],count: 2)
            print("        deal two ")
            flag = 2
        } else if lastCard.index == 13 {
            //self.dealCard(objName: cardObj[0],count: 4)
            print("        deal four ")
            flag = 4
        } else if lastCard.index == 14 {
            print("        wild card ")
            flag = 5
        }
        return flag
    }
    
    func determineTurn() {
        //cardObj[0].showCard()DEALER
        //print(cardObj[0].cardFlag)
        print("\(cardObj[0].name) Turn")
        if !gameOverFlag {
            swapDeckUnShuttfleCards()
            if cardObj[0].name != "PLAYER" {
                computerTurn()
            } else {
                playerTurn()
            }
        }
    }

    
    func playerTurn() {
        var cflag:Int = 0
        if firstTimeFlag {
            cflag = self.specialCardHandle()
            if cflag != 0 {
                firstTimeFlag = false
            }
        }
        switch  cflag {
        case 1:
            cardObj = cardObj.reversed()
            if mpcGameFlag {
                determineMPCTurn()
            } else {
                determineTurn()
            }
        case 2:
            takeCardCount = 2
            self.setupCardDeck()
        case 4:
            takeCardCount = 4
            self.setupCardDeck()
        default:
            if p1.matchCardList() != [String]() {
                self.setupCardField()
            } else {
                self.setupCardDeck()
            }
        }
    }
    
    func computerTurn() {
        activityIndicator.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            var cflag = 0
            sleep(1)
            self.activityIndicator.stopAnimating()
            if firstTimeFlag {
                cflag = self.specialCardHandle()
                if cflag != 0 {
                    firstTimeFlag = false
                }
            }
            switch  cflag {
            case 1:
                cardObj = cardObj.reversed()
            case 2:
                self.dealCard(objName: self.c2,count: 2)
                cardObj = cardObj.reversed()
            case 4:
                self.dealCard(objName: self.c2,count: 4)
                cardObj = cardObj.reversed()
            case 5:
                 self.botGamePlay(objName: self.c2)
                 cardObj = cardObj.reversed()
            default:
                self.botGamePlay(objName: self.c2)
                cardObj = cardObj.reversed()
            }
            self.updateCardView()
            self.determineTurn()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //DISPLAY AND PRINT FUNCTIONS
    
    func resetCardView() {
        for i in 0 ... playerCards.count - 1 {
            playerCards[i].image = nil
        }
        cpuCardNum.text = ""
        lastCardImage[0].image = nil
    }
    
    func resetDeck(objName1: unocards,objName2: unocards) {
        objName1.cardFlag = [15,255,255,255,255,255,255,255,255,255,255,255,255,15,15]
        objName2.cardFlag = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        lastCardImage[1].image = UIImage(named: "card_back_alt_large")
    }
    
    func resetField() {
        for index in 0 ... touchCards.count - 1{
            touchCards[index].image = nil
        }
    }
    
    func resetMPCDeck() {
        gameOverFlag = false
        mpcGameFlag = true
        resetCardView()
        resetField()
        lastCardImage[1].image = nil
        if self.deckCardImage[4].isAnimating {
            self.deckCardImage[4].stopAnimating()
        }
        if self.activityIndicator.isAnimating {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func showPlayerCards(objName:unocards) {
        var cardIndex:Int = 0
        var cardName:String!
        for (index,cardMask) in objName.cardFlag.enumerated() {
            for (j,i) in  cardMsk.enumerated() {
                if cardMask & i == i {
                    //print(i,j)
                    if index < 13 {
                        cardName = cardColor[j] + cardType[index]
                    } else {
                        cardName = cardType[index]
                    }
                    playerCards[cardIndex].image = UIImage(named: cardName)
                    cardIndex = cardIndex + 1
                    if cardIndex > 22 {
                        print("No more image:space to show player cards")
                        break
                    }
                }
            }
        }
    }
    
    func displayCard() {
        let cardKey:String = cardType[lastCard.index]
        //VIBGYR
        if (lastCard.mask & 1 == 1)  {
            print("*   " + cardKey + " bluee *")
        }
        if (lastCard.mask & 2 == 2)  {
            print("*   " + cardKey + " green *")
        }
        if (lastCard.mask & 4 == 4)  {
            print("*   " + cardKey + " yelow *")
        }
        if (lastCard.mask & 8 == 8)  {
            print("*   " + cardKey + " redd *")
        }
        if (lastCard.mask & 16 == 16) {
            print("*   " + cardKey + " BLUEE *")
        }
        if (lastCard.mask & 32 == 32) {
            print("*   " + cardKey + " GREEN *")
        }
        if (lastCard.mask & 64 == 64) {
            print("*   " + cardKey + " YELOW *")
        }
        if (lastCard.mask & 128 == 128) {
            print("*   " + cardKey + " REEDD *")
        }
        let tot = deck.countCard() + p1.countCard() + c2.countCard() + us.countCard()
        if tot > 108 {
            print("helo@#######!@!@#!@#!@#!$@#!@#!@#@$!@#!#!@#@")
        }
        print("Print Total Card\(tot, deck.countCard(), p1.countCard(), c2.countCard(),  us.countCard()) ")
    }
    
    func updateCardView() {
        resetCardView()
        showPlayerCards(objName: p1)
        cpuCardNum.text = "\(c2.countCard())"
        var cardName:String!
        displayCard()
        if lastCard.mask != 0 {
            if lastCard.index < 13 {
                cardName = cardColor[cardMsk.index(of: lastCard.mask)!] + cardType[lastCard.index]
            }
            else {
                cardName = cardType[lastCard.index]
            }
            lastCardImage[0].image = UIImage(named: cardName)
        }
        if us.countCard() > 1 {
            if lastb4Card.mask != 0 {
                if lastb4Card.index < 13 {
                    cardName = cardColor[cardMsk.index(of: lastb4Card.mask)!] + cardType[lastb4Card.index]
                }
                else {
                    cardName = cardType[lastb4Card.index]
                }
                lastCardImage[1].image = UIImage(named: cardName)
            }
        }
    }
    
    // CONNECT FUNCTIONS
    
    
    func mpcSetting() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        // create the browser viewcontroller with a unique service name
        self.browser = MCBrowserViewController(serviceType:serviceType,session:self.session)
        self.browser.delegate = self;
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,discoveryInfo:nil, session:self.session)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.peerChangedStateWithNotification(_:)), name: NSNotification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil)
        
        // tell the assistant to start advertising our fabulous chat
        self.assistant.start()
    }
    

    
    func peerChangedStateWithNotification(_ notification: Notification) {
        let userInfo = notification.userInfo!
        
        let state = userInfo["state"] as! Int
        print(state)
        print("joker")
        
        if state != MCSessionState.connecting.rawValue {
            self.navigationItem.title = "Connected"
            resetMPCDeck()
        }
        if state == 0 {
            self.navigationItem.title = "Disconnected"
            mpcGameFlag = false
            self.startGame()
        }
    }
    
    @IBAction func sendRed(_ sender: UIButton) {
        message = "red"
        self.view.backgroundColor = UIColor.red
        let msg = self.message.data(using: String.Encoding.utf8,allowLossyConversion: false)
        do {
            try self.session.send(msg!, toPeers: self.session.connectedPeers,with: MCSessionSendDataMode.unreliable)
        } catch let error as NSError {
            print("Error sending data: \(error.description)")
        } catch {
            print("other error")
        }
        /* to do
         updateColor()
         */
    }
    
    func updateColor(_ colorName:UIColor) {
        self.view.backgroundColor = colorName
    }
    
    @IBAction func sendYellow(_ sender: UIButton) {
        message = "yellow"
        print(message as String)
        self.view.backgroundColor = UIColor.yellow
        let msg = self.message.data(using: String.Encoding.utf8,allowLossyConversion: false)
        do {
            try self.session.send(msg!, toPeers: self.session.connectedPeers,with: MCSessionSendDataMode.unreliable)
        } catch let error as NSError {
            print("Error sending data: \(error.description)")
        } catch {
            print("other error")
        }
        /* to do
         updateColor()
         */
    }
    
    @IBAction func showBrowser(_ sender: UIButton) {
        // Show the browser view controller
        self.present(self.browser, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is dismissed (ie the Done
        // button was tapped)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController)  {
        // Called when the browser view controller is cancelled
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func session(_ didReceivesession: MCSession, didReceive data: Data,fromPeer peerID: MCPeerID)  {
        // Called when a peer sends an NSData to us
        
        // This needs to run on the main queue
        DispatchQueue.main.async() {
            let msg = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
            print(msg! as String)
            if (msg?.isEqual(to: "red"))! {
                self.updateColor(UIColor.red)
                print("red")
            }
            if (msg?.isEqual(to: "yellow"))! {
                self.updateColor(UIColor.yellow)
                print("yellow")
            }
            if ((msg?.length)! > 10) {
                cardObj = [self.p1 , self.c2]
                let msgString = msg! as String
                let msgStringArr : [String] = msgString.components(separatedBy: "_")
                for (index,strElement) in msgStringArr.enumerated() {
                    if index < 4 {
                        let strArr : [String] = strElement.components(separatedBy: ":")
                        switch index {
                        case 0:
                            self.deck.cardFlag = strArr.map { Int($0)!}
                        case 1:
                            self.c2.cardFlag = strArr.map { Int($0)!}
                        case 2:
                            self.p1.cardFlag = strArr.map { Int($0)!}
                        case 3:
                            self.us.cardFlag = strArr.map { Int($0)!}
                        default:
                            print("meh")
                        }
                    } else {
                        switch index {
                        case 4:
                            lastCard.index = Int(strElement)!
                        case 5:
                            lastCard.mask =  Int(strElement)!
                        case 6:
                            lastb4Card.index = Int(strElement)!
                        case 7:
                            lastb4Card.mask =  Int(strElement)!
                        case 8:
                            takeCardCount = Int(strElement)!
                        case 9:
                            if strElement != "false" {
                                firstTimeFlag = true
                            } else {
                                firstTimeFlag = false
                            }
                        case 10:
                            if strElement != "false" {
                                gameOverFlag = true
                            } else {
                                gameOverFlag = false
                            }
                        case 11:
                            winner = strElement
                        default:
                            print("meh")
                        }
                    }
                    
                }
                let tot = self.deck.countCard() + self.p1.countCard() + self.c2.countCard() + self.us.countCard()
                if tot > 108 {
                    print("helo@#######!@!@#!@#!@#!$@#!@#!@#@$!@#!#!@#@")
                }
                self.updateCardView()
                if gameOverFlag {
                    self.viewDidAppear(true)
                } else {
                    self.determineMPCTurn()
                }
            }
            
        }
    }
    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(_ session: MCSession,didStartReceivingResourceWithName resourceName: String,fromPeer peerID: MCPeerID, with progress: Progress)  {
        
        // Called when a peer starts sending a file to us
    }
    
    func session(_ session: MCSession,didFinishReceivingResourceWithName resourceName: String,fromPeer peerID: MCPeerID,at localURL: URL, withError error: Error?)  {
        // Called when a file has finished transferring from another peer
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream,withName streamName: String, fromPeer peerID: MCPeerID)  {
        // Called when a peer establishes a stream with us
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID,didChange state: MCSessionState)  {
        // Called when a connected peer changes state (for example, goes offline)
        let userInfo = ["peerID":peerID,"state":state.rawValue] as [String : Any]
        DispatchQueue.main.async(execute: { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: "MPC_DidChangeStateNotification"), object: nil, userInfo: userInfo)
        })
    }
    
}

