//
//  ReservePopupController.swift
//  ShareSpace
//
//  Created by Liubov Kaper  on 6/1/20.
//  Copyright © 2020 Bienbenido Angeles. All rights reserved.
//

import UIKit
import FSCalendar
import FirebaseAuth
import FirebaseFirestore

class ReservePopupController: UIViewController {
    
   private let storageService = StorageService.shared
    
    
    
    @IBOutlet weak var totalPriceLabel: UILabel!
    
    
    @IBOutlet weak var dismissBar: UIView!
    
    
    @IBOutlet weak var pricePerNightLabel: UILabel!
    
    @IBOutlet weak var toDateLAbel: UILabel!
    
    @IBOutlet weak var fromDateLabel: UILabel!
    
    
    @IBOutlet weak var messageTextView: UITextView!
    
    
  private var selectedPost: Post
    
    init?(coder: NSCoder, selectedPost: Post) {
        self.selectedPost = selectedPost
        super.init(coder: coder)
    }
    
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    
    @IBOutlet weak var calendar: FSCalendar!
    
    // first date in the range
       private var firstDate: Date?
       // last date in the range
       private var lastDate: Date?
       
       private var datesRange: [Date]?
       
           override func viewDidLoad() {
               super.viewDidLoad()
            view.backgroundColor = .systemGroupedBackground
               calendar.delegate = self
               calendar.dataSource = self
               calendar.allowsMultipleSelection = true
               setupCalendarAppearance()
            updateUI()
            setupDismissBar()
       }
    
    private func setupDismissBar() {
        dismissBar.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (topGesturePressed(recognizer:)))
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(recognizer:)))
        dismissBar.addGestureRecognizer(tapGesture)
    }
    @objc func topGesturePressed(recognizer: UITapGestureRecognizer) {
        dismiss(animated: true) 
    }
       
       private func setupCalendarAppearance() {
           calendar.scrollDirection = .vertical
           calendar.appearance.todayColor = .yummyOrange
           
           calendar.appearance.selectionColor = .oceanBlue
           calendar.appearance.weekdayTextColor = .oceanBlue
           calendar.appearance.headerTitleColor = .sunnyYellow
           //calendar.appearance.weekdayTextColor = .white
           calendar.appearance.headerTitleFont = UIFont(name: "Verdana", size: 23.0)
        calendar.appearance.titleFont = UIFont(name: "Verdana", size: 18.0)
           
           
       }
    func updateUI() {
        pricePerNightLabel.text = "\(selectedPost.price.description)$/NIGHT"
    }


    @IBAction func sendMessageButtonPressed(_ sender: UIButton) {
        
        guard let user = Auth.auth().currentUser else { return }
        let chatId = UUID().uuidString
        let renterId = user.uid
        let postId = selectedPost.postId
        let status = Status.undetermined
        let reservationId = UUID().uuidString
        guard let checkIn = datesRange?.first,
            
            let checkOut = datesRange?.last,
           
            let message = messageTextView.text,
            !message.isEmpty else { return }
        let messageID = UUID().uuidString
        let dict:[String : Any]
            = [
                "renterId": renterId,
            "postId": postId,
            "checkIn": checkIn,
            "checkOut": checkOut,
            "chatId": chatId,
            "status": status.rawValue,
            "reservationId": reservationId
            ]
        DatabaseService.shared.createReservation(reservation: dict) { (result) in
            switch result {
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
                
            case .success:
                let message = Message(id: messageID, content: message, created: Timestamp(), senderID: renterId, senderName: user.displayName ?? "anonymous")
                self.creatingThread(user1Id: renterId, user2Id: self.selectedPost.userId, messgae: message, chatId: chatId)
            }
        }
       
    }
    
    private func creatingThread(user1Id: String, user2Id: String, messgae: Message, chatId: String){
        DatabaseService.shared.createNewChat(user1ID: user1Id, user2ID: user2Id, chatId: chatId) { (result) in
            switch result{
            case .failure(let error):
            self.showAlert(title: "Error", message: error.localizedDescription)
            case .success(let chatId):
                self.sendMessage(message: messgae, destinationUserId: user2Id, chatId: chatId)
            }
        }
    }
    
    private func sendMessage(message: Message, destinationUserId: String, chatId: String){
        DatabaseService.shared.sendChatMessage(message, user2ID: destinationUserId, chatId: chatId) { (result) in
            switch result {
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            case .success:
                self.showAlert(title: "Your message was successfully sent", message: "Your host will reply shortly!")
            }
        }
    }
    
    
}

extension ReservePopupController: FSCalendarDelegate, FSCalendarDataSource {

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("selected")
         // nothing selected:
        if firstDate == nil {
            firstDate = date
            datesRange = [firstDate!]
//totalPriceLabel.text = (datesRange?.count ?? 1 * Int(selectedPost?.price.total ?? 1)).description
            //print("datesRange contains: \(datesRange!)")
            return
        }

        // only first date is selected:
        if firstDate != nil && lastDate == nil {
            // handle the case of if the last date is less than the first date:
            if date <= firstDate! {
                calendar.deselect(firstDate!)
                firstDate = date
                datesRange = [firstDate!]
                //print("datesRange contains: \(datesRange!)")
                return
            }

            let range = datesRange(from: firstDate!, to: date)
            lastDate = range.last

            for d in range {
                calendar.select(d)
            }

            datesRange = range
            totalPriceLabel.text = "Total for \(datesRange?.count ?? -1) days: \((datesRange?.count ?? 1 * Int(selectedPost.price)).description)$"
            fromDateLabel.text = "From: \(datesRange?.first?.toString(givenFormat: "MMM d, yyyy") ?? "no date")"
            toDateLAbel.text = "To: \(datesRange?.last?.toString(givenFormat: "MMM d, yyyy") ?? "no date")"
            
            print("datesRange contains: \(datesRange!)")

            return
        }

        // both are selected:
        if firstDate != nil && lastDate != nil {
            for d in calendar.selectedDates {
                calendar.deselect(d)
                
            }

            lastDate = nil
            firstDate = nil

            datesRange = []
            
            print("there are:\(datesRange?.count ?? 0) dates")
            print("datesRange contains: \(datesRange!)")
        }
    }
    func datesRange(from: Date, to: Date) -> [Date] {
        // in case of the "from" date is more than "to" date,
        // it should returns an empty array:
        if from > to { return [Date]() }

        var tempDate = from
        var array = [tempDate]

        while tempDate < to {
            tempDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate)!
            array.append(tempDate)
        }

        return array
    }

}
//extension String {
//    func toDouble() -> Double? {
//        return NumberFormatter().number(from: self)?.doubleValue
//    }
//}
