//
//  conversationVC.swift
//  ChatApp
//
//  Created by Tuan-Vi Phan on 4/7/16.
//  Copyright © 2016 Tuan-Vi Phan. All rights reserved.
//

import UIKit
import Parse

var otherName = ""
var otherProfileName = ""

class conversationVC: UIViewController, UIScrollViewDelegate {
    
    // MARK: IBOutlet
    @IBOutlet weak var resultsScrollView: UIScrollView!
    @IBOutlet weak var frameMessageView: UIView!
    @IBOutlet weak var lineLbl: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    //@IBOutlet weak var blockBtn: UIBarButtonItem!
    
    // MARK: variables
    var scrollViewOriginalY: CGFloat = 0
    var frameMessageOriginalY: CGFloat = 0
    let mLbl = UILabel(frame: CGRectMake(5, 8, 200, 20))
    
    var messageX: CGFloat = 37.0
    var messageY: CGFloat = 26.0
    var frameX: CGFloat = 32.0
    var frameY: CGFloat = 21.0
    var imgX: CGFloat = 3
    var imgY: CGFloat = 3
    
    var messageArray = [String]()
    var senderArray = [String]()
    
    var myImg: UIImage? = UIImage()
    var otherImg: UIImage? = UIImage()
    
    var resultsImageFiles = [PFFile]()
    var resultsImageFiles2 = [PFFile]()
    
    var isBlocked = false
    
    var blockBtn = UIBarButtonItem()
    var reportBtn = UIBarButtonItem()
    
    // MARK: IBAction
    
    @IBAction func sendBtn_click(sender: UIButton) {
        
        if isBlocked == true {
            
            print("you are blocked!!!!")
            return
        }
        
        if blockBtn.title == "Unblock" {
            
            print("you have blocked this user!!! unblock to send message")
            return
        }
        
        if messageTextView.text == "" {
            
            print("no text")
        } else {
            
            let messageDBTable = PFObject(className: "Message")
            messageDBTable["sender"] = userName
            messageDBTable["other"] = otherName
            messageDBTable["message"] = self.messageTextView.text
            messageDBTable.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                
                if success == true {
                    
                    let uQuery: PFQuery = PFUser.query()!
                    uQuery.whereKey("username", equalTo: otherName)

                    let pushQuery: PFQuery = PFInstallation.query()!
                    pushQuery.whereKey("user", matchesQuery: uQuery)
                    
                    let push: PFPush = PFPush()
                    push.setQuery(pushQuery)
                    push.setMessage("New Message")
                    do {
                        try push.sendPush()
                    } catch {}
                    print("push sent")
                    
                    print("message sent")
                    self.messageTextView.text = ""
                    self.mLbl.hidden = false
                    self.refreshResults()
                }
            })
        }
    }
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        let theWidth = view.frame.size.width
        let theHeight = view.frame.size.height
        
        messageTextView.delegate = self
        
        resultsScrollView.frame = CGRectMake(0, 64, theWidth, theHeight-114)
        resultsScrollView.layer.zPosition = 20
        frameMessageView.frame = CGRectMake(0, resultsScrollView.frame.maxY, theWidth, 50)
        lineLbl.frame = CGRectMake(0, 0, theWidth, 1)
        messageTextView.frame = CGRectMake(2, 1, self.frameMessageView.frame.size.width-52, 48)
        sendBtn.center = CGPointMake(frameMessageView.frame.size.width-30, 24)
        
        scrollViewOriginalY = self.resultsScrollView.frame.origin.y
        frameMessageOriginalY = self.frameMessageView.frame.origin.y
        
        self.title = otherProfileName
        
        mLbl.text = "Type a message..."
        mLbl.backgroundColor = UIColor.clearColor()
        mLbl.textColor = UIColor.lightGrayColor()
        messageTextView.addSubview(mLbl)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        let tapScrollViewGesture = UITapGestureRecognizer(target: self, action: "didTapScrollView")
        tapScrollViewGesture.numberOfTapsRequired = 1
        resultsScrollView.addGestureRecognizer(tapScrollViewGesture)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "getMessageFunc", name: "getMessage", object: nil)
        
        blockBtn.title = ""
        blockBtn = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("blockBtn_click"))
        reportBtn = UIBarButtonItem(title: "Report", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("reportBtn_click"))
        let buttonArray = NSArray(objects: blockBtn, reportBtn)
        self.navigationItem.rightBarButtonItems = buttonArray as? [UIBarButtonItem]
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let checkQuery = PFQuery(className: "Block")
        checkQuery.whereKey("user", equalTo: otherName)
        checkQuery.whereKey("blocked", equalTo: userName)
        let objects2 = try! checkQuery.findObjects()
        
        if objects2.count > 0 {
            
            isBlocked = true
        } else {
            
            isBlocked = false
        }
        
        let blockQuery = PFQuery(className: "Block")
        blockQuery.whereKey("user", equalTo: userName)
        blockQuery.whereKey("blocked", equalTo: otherName)
        let objects0 = try! blockQuery.findObjects()
        if objects0.count > 0 {
            self.blockBtn.title = "Unblock"
        } else {
            self.blockBtn.title = "Block"
        }
        
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: userName)
        let objects = try! query.findObjects()
        
        self.resultsImageFiles.removeAll(keepCapacity: false)
        
        for object in objects {
            
            self.resultsImageFiles.append(object["photo"] as! PFFile)
            self.resultsImageFiles[0].getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                
                if error == nil {
                    self.myImg = UIImage(data: imageData!)
                    let query2 = PFQuery(className: "_User")
                    query2.whereKey("username", equalTo: otherName)
                    let objects2 = try! query2.findObjects()
                    
                    self.resultsImageFiles2.removeAll(keepCapacity: false)
                    
                    for object in objects2 {
                        self.resultsImageFiles2.append(object["photo"] as! PFFile)
                        self.resultsImageFiles2[0].getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                            if error == nil {
                                self.otherImg = UIImage(data: imageData!)
                                self.refreshResults()
                            }
                        })
                    }

                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: my function
    func reportBtn_click() {
        
        print("report pressed")
        
        let addReport = PFObject(className: "Report")
        addReport.setObject(userName, forKey: "user")
        addReport.setObject(otherName, forKey: "reported")
        addReport.saveInBackground()
        
        print("report sent")
    }
    
    func blockBtn_click() {
        
        if blockBtn.title == "Block" {
            
            let addBlock = PFObject(className: "Block")
            addBlock.setObject(userName, forKey: "user")
            addBlock.setObject(otherName, forKey: "blocked")
            addBlock.saveInBackground()
            self.blockBtn.title = "Unblock"
        } else {
            
            let query: PFQuery = PFQuery(className: "Block")
            query.whereKey("user", equalTo: userName)
            query.whereKey("blocked", equalTo: otherName)
            let objects = try! query.findObjects()
            
            for object in objects {
                
                object.deleteInBackground()
            }
            self.blockBtn.title = "Block"
        }
    }
    
    func getMessageFunc() {
        
        refreshResults()
    }
    
    func keyboardWasShow(notification: NSNotification) {
        
        let dict: NSDictionary = notification.userInfo!
        let s: NSValue = dict.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let rect: CGRect = s.CGRectValue()
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveLinear, animations: { () -> Void in
            
            self.resultsScrollView.frame.origin.y = self.scrollViewOriginalY - rect.height
            self.frameMessageView.frame.origin.y = self.frameMessageOriginalY - rect.height
            
            let bottomOffset: CGPoint = CGPointMake(0, self.resultsScrollView.contentSize.height - self.resultsScrollView.bounds.size.height)
            self.resultsScrollView.setContentOffset(bottomOffset, animated: false)
            }) { (finished: Bool) -> Void in
                
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveLinear, animations: { () -> Void in
            
            self.resultsScrollView.frame.origin.y = self.scrollViewOriginalY
            self.frameMessageView.frame.origin.y = self.frameMessageOriginalY
            
            let bottomOffset: CGPoint = CGPointMake(0, self.resultsScrollView.contentSize.height - self.resultsScrollView.bounds.size.height)
            self.resultsScrollView.setContentOffset(bottomOffset, animated: false)
            }) { (finished: Bool) -> Void in
                
        }
    }
    
    func didTapScrollView() {
        
        self.view.endEditing(true)
    }
    
    func refreshResults() {
        
        let theWidth = view.frame.size.width
//        let theHeight = view.frame.size.height
        
        messageX = 37.0
        messageY = 26.0
        frameX = 32.0
        frameY = 21.0
        imgX = 3
        imgY = 3
        
        messageArray.removeAll(keepCapacity: false)
        senderArray.removeAll(keepCapacity: false)
        
        let innerP1 = NSPredicate(format: "sender = %@ AND other = %@", userName, otherName)
        let innerQ1: PFQuery = PFQuery(className: "Message", predicate: innerP1)
        
        let innerP2 = NSPredicate(format: "sender = %@ AND other = %@", otherName, userName)
        let innerQ2: PFQuery = PFQuery(className: "Message", predicate: innerP2)
        
        let query = PFQuery.orQueryWithSubqueries([innerQ1, innerQ2])
        query.addAscendingOrder("createdAt")
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                for object in objects! {
                    self.senderArray.append(object.objectForKey("sender") as! String)
                    self.messageArray.append(object.objectForKey("message") as! String)
                }
                
                for subView in self.resultsScrollView.subviews {
                    subView.removeFromSuperview()
                }
                
                for var i=0; i<=self.messageArray.count-1; i++ {
                    
                    if self.senderArray[i] == userName {
                        
                        let messageLbl: UILabel = UILabel()
                        messageLbl.frame = CGRectMake(0, 0, self.resultsScrollView.frame.size.width-94, CGFloat.max)
                        messageLbl.backgroundColor = UIColor.blueColor()
                        messageLbl.lineBreakMode = NSLineBreakMode.ByWordWrapping
                        messageLbl.textAlignment = NSTextAlignment.Left
                        messageLbl.numberOfLines = 0
                        messageLbl.font = UIFont(name: "Helvetica Neuse", size: 17)
                        messageLbl.textColor = UIColor.whiteColor()
                        messageLbl.text = self.messageArray[i]
                        messageLbl.sizeToFit()
                        messageLbl.layer.zPosition = 20
                        messageLbl.frame.origin.x = (self.resultsScrollView.frame.size.width - self.messageX) - messageLbl.frame.size.width
                        messageLbl.frame.origin.y = self.messageY
                        self.resultsScrollView.addSubview(messageLbl)
                        self.messageY += messageLbl.frame.size.height + 30
                        
                        let frameLbl: UILabel = UILabel()
                        frameLbl.frame.size = CGSizeMake(messageLbl.frame.size.width+10, messageLbl.frame.size.height+10)
                        frameLbl.frame.origin.x = (self.resultsScrollView.frame.size.width - self.frameX) - frameLbl.frame.size.width
                        frameLbl.frame.origin.y = self.frameY
                        frameLbl.backgroundColor = UIColor.blueColor()
                        frameLbl.layer.masksToBounds = true
                        frameLbl.layer.cornerRadius = 10
                        self.resultsScrollView.addSubview(frameLbl)
                        self.frameY += frameLbl.frame.size.height + 20
                        
                        let img: UIImageView = UIImageView()
                        img.image = self.myImg
                        img.frame.size = CGSizeMake(34, 34)
                        img.frame.origin.x = (self.resultsScrollView.frame.size.width - self.imgX) - img.frame.size.width
                        img.frame.origin.y = self.imgY
                        img.layer.zPosition = 30
                        img.layer.cornerRadius = img.frame.size.width/2
                        img.clipsToBounds = true
                        self.resultsScrollView.addSubview(img)
                        self.imgY += frameLbl.frame.size.height + 20
                        
                        
                        self.resultsScrollView.contentSize = CGSizeMake(theWidth, self.messageY)
                    } else {
                        
                        let messageLbl: UILabel = UILabel()
                        messageLbl.frame = CGRectMake(0, 0, self.resultsScrollView.frame.size.width-94, CGFloat.max)
                        messageLbl.backgroundColor = UIColor.groupTableViewBackgroundColor()
                        messageLbl.lineBreakMode = NSLineBreakMode.ByWordWrapping
                        messageLbl.textAlignment = NSTextAlignment.Left
                        messageLbl.numberOfLines = 0
                        messageLbl.font = UIFont(name: "Helvetica Neuse", size: 17)
                        messageLbl.textColor = UIColor.blackColor()
                        messageLbl.text = self.messageArray[i]
                        messageLbl.sizeToFit()
                        messageLbl.layer.zPosition = 20
                        messageLbl.frame.origin.x = self.messageX
                        messageLbl.frame.origin.y = self.messageY
                        self.resultsScrollView.addSubview(messageLbl)
                        self.messageY += messageLbl.frame.size.height + 30
                        
                        let frameLbl: UILabel = UILabel()
                        frameLbl.frame = CGRectMake(self.frameX, self.frameY, messageLbl.frame.size.width+10, messageLbl.frame.size.height+10)
                        frameLbl.backgroundColor = UIColor.groupTableViewBackgroundColor()
                        frameLbl.layer.masksToBounds = true
                        frameLbl.layer.cornerRadius = 10
                        self.resultsScrollView.addSubview(frameLbl)
                        self.frameY += frameLbl.frame.size.height + 20
                        
                        let img: UIImageView = UIImageView()
                        img.image = self.otherImg
                        img.frame = CGRectMake(self.imgX, self.imgY, 34, 34)
                        img.layer.zPosition = 30
                        img.layer.cornerRadius = img.frame.size.width/2
                        img.clipsToBounds = true
                        self.resultsScrollView.addSubview(img)
                        self.imgY += frameLbl.frame.size.height + 20
                        
                        self.resultsScrollView.contentSize = CGSizeMake(theWidth, self.messageY)
                    }
                    
                    let bottomOffset: CGPoint = CGPointMake(0, self.resultsScrollView.contentSize.height - self.resultsScrollView.bounds.size.height)
                    self.resultsScrollView.setContentOffset(bottomOffset, animated: false)
                }
            }
        }
    }
}

extension conversationVC: UITextViewDelegate {
    
    func textViewDidChange(textView: UITextView) {
        
        if !messageTextView.hasText() {
            
            self.mLbl.hidden = false
        } else {
            
            self.mLbl.hidden = true
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        if !messageTextView.hasText() {
            
            self.mLbl.hidden = false
        }
    }
}
