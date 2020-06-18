//
//  ReservationDetailViewController.swift
//  ShareSpace
//
//  Created by Liubov Kaper  on 6/14/20.
//  Copyright © 2020 Bienbenido Angeles. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseAuth
import FirebaseFirestore

class ReservationDetailViewController: UIViewController {
    
    private var reservationDetailView = ReservationDetailView()
    
    private var selectedReservation: Reservation?
    private var selectedPost: Post?
    private var userWhoIsrequesting: UserModel?
    
    init(_ selectedReservation: Reservation) {
        self.selectedReservation = selectedReservation
       // self.selectedPost = selectedPost
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var reservationStatus: Int?
    private var selectedStatus: Status.RawValue = 2 {
      didSet {
        reservationStatus = selectedStatus
      }
    }
    
    override func loadView() {
        super.loadView()
        view = reservationDetailView
    }
    
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
       buttonsPressed()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        guard let reservation = selectedReservation else {
            return
        }
        DatabaseService.shared.loadPost(postId: reservation.postId) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let post):
                self.selectedPost = post
            }
        }
        
        DatabaseService.shared.loadUser(userId: reservation.renterId) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let userRequesting):
                self.userWhoIsrequesting = userRequesting
            }
        }
        
        listener = DatabaseService.shared.db.collection(DatabaseService.reservationCollection).document(reservation.reservationId).addSnapshotListener({ [weak self] (snapshot , error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            } else if let data = snapshot?.data() {
                
                let reservation = Reservation(dict: data)
                self?.selectedStatus = reservation.status
                if self?.selectedStatus == 0 {
                    self?.reservationDetailView.postLocationLabel.text = self?.selectedPost?.fullAddress ?? ""
                    self?.reservationDetailView.reservationStatusLabel.text = "Accepted"
                    self?.reservationDetailView.reservationStatusLabel.textColor = .systemGreen
                    self?.reservationDetailView.profileImageView.kf.setImage(with: URL(string: self?.userWhoIsrequesting?.profileImage ?? ""))
                    self?.reservationDetailView.acceptButton.setTitleColor(.systemGray, for: .disabled)
                    self?.reservationDetailView.declineButton.isHidden = true//setTitleColor(.systemGray, for: .disabled)
                } else if self?.selectedStatus == 1 {
                    self?.reservationDetailView.postLocationLabel.text = "\(self?.selectedPost?.state ?? ""), \(self?.selectedPost?.country ?? "") "
                    self?.reservationDetailView.reservationStatusLabel.text = "Declined"
                    self?.reservationDetailView.reservationStatusLabel.textColor = .systemRed
                    self?.reservationDetailView.profileImageView.image = UIImage(named: "person.fill")
                    self?.reservationDetailView.acceptButton.setTitleColor(.systemGray, for: .disabled)
                    self?.reservationDetailView.declineButton.setTitleColor(.systemGray, for: .disabled)
                } else if self?.selectedStatus == 2 {
                    self?.reservationDetailView.postLocationLabel.text = "\(self?.selectedPost?.state ?? ""), \(self?.selectedPost?.country ?? "") "
                    self?.reservationDetailView.reservationStatusLabel.text = "Pending"
                    self?.reservationDetailView.reservationStatusLabel.textColor = .systemRed
                    self?.reservationDetailView.profileImageView.image = UIImage(named: "person.fill")
                    self?.reservationDetailView.acceptButton.setTitleColor(.systemGray, for: .disabled)
                    self?.reservationDetailView.declineButton.setTitleColor(.systemGray, for: .disabled)
                }
            }
        })
    }
   
    private func updateUI() {
        guard let reservation = selectedReservation else {
            return
        }
        DatabaseService.shared.loadUser(userId: reservation.renterId) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let userRequesting):
                self.userWhoIsrequesting = userRequesting
            }
        }
        
        DatabaseService.shared.loadPost(postId: reservation.postId) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let post):
                self.selectedPost = post
            }
        }
        //FIX: Add if statement for status 1,2,3?
        reservationDetailView.reservationStatusLabel.text = selectedReservation?.status.description
        
        reservationDetailView.userNameLabel.text = userWhoIsrequesting?.firstName
        
        //ADD LOCATION(STATE, COUNTRY) TO USERMODEL
       // reservationDetailView.userLocationLabel.text = "From: \(userWhoIsrequesting.)"
        // ADD RATING TO USERMODEL
       // reservationDetailView.userRatingLabel.text = "Rating: \(userWhoIsrequesting.rating)"
        
        reservationDetailView.postTitelLabel.text = selectedPost?.postTitle
        
        reservationDetailView.postDescriptionLabel.text = "Description: \(selectedPost?.description ?? "no description")"
        
        // will need to fix this one after changing Post Model. If resewrvation is pending, do not show full address, if reservation is confirmed, show full address
        reservationDetailView.postLocationLabel.text = selectedPost?.city
        
        reservationDetailView.checkInDateLabel.text = "check-in    \(selectedReservation?.checkIn.toString(givenFormat: "EEEE, MMM d, yyyy") ?? "no date")"
        reservationDetailView.checkOutDateLabel.text = "check-out    \(selectedReservation?.checkOut.toString(givenFormat: "EEEE, MMM d, yyyy") ?? "no date")"
        // DO NOT HAVE CHECKIN< CHECKOUT TIMES NOW
        
        // NEED TO ADD NUMBER OF GUESTS TO RESERVEPOPUP VC and to RESERVATION MODEL
        
        if selectedStatus == 0 {
           
            reservationDetailView.acceptButton.isHidden = true
            reservationDetailView.declineButton.setTitleColor(.systemGray, for: .disabled)
            reservationDetailView.reservationStatusLabel.text = "Accepted"
        }
        
    }
    
    private func buttonsPressed() {
        reservationDetailView.viewProfileButton.addTarget(self, action: #selector(viewProfileButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        
        reservationDetailView.viewPostButton.addTarget(self, action: #selector(viewPostButtonPressed(_:)), for: .touchUpInside)
        
        reservationDetailView.acceptButton.addTarget(self, action: #selector(acceptButtonPressed(_:)), for: .touchUpInside)
        reservationDetailView.declineButton.addTarget(self, action: #selector(declineButtonPressed(_:)), for: .touchUpInside)
    }
    
    
    @objc func viewProfileButtonPressed(_ sender: UIButton) {
        print("view profile button pressed")
        
        
       let storyboard = UIStoryboard(name: "FirstProfileStoryboard", bundle: nil)
        let firstProfilelVC = storyboard.instantiateViewController(identifier: "FirstProfileViewController")
        { (coder) in
            return FirstProfileViewController(coder: coder, userId: self.selectedReservation?.renterId ?? "no id")
        }
        navigationController?.pushViewController(firstProfilelVC, animated: true)
    }
    
    @objc func viewPostButtonPressed(_ sender: UIButton) {
        print("view post button pressed")
        
        guard let reservation = selectedReservation else {
            return
        }
        
        DatabaseService.shared.loadPost(postId: reservation.postId) { (result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let post):
                self.selectedPost = post
            }
        }
        
        guard let post = selectedPost else {
            return
        }
        
        let storyboard = UIStoryboard(name: "ListingDetail", bundle: nil)
        let listingDetailVC = storyboard.instantiateViewController(identifier: "ListingDetailViewController") { (coder) in
            return ListingDetailViewController(coder: coder, selectedPost: post)
        }
        navigationController?.pushViewController(listingDetailVC, animated: true)
    }
    
    

    @objc func acceptButtonPressed(_ sender: UIButton) {
        print("accept button pressed")
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        guard var reservation = selectedReservation else {
            return
        }
        reservation.status = 0
        
        // Create Firebase function to accept reservation and add it in the closure here
        let acceptAction = UIAlertAction(title: "Accept this reservation request", style: .default)
        { (alertAction) in
            
            DatabaseService.shared.updateReservation(reservation: reservation) { [weak self](result) in
                switch result {
                case .failure(let error):
                    self?.showAlert(title: "Error accepting reservation", message: error.localizedDescription)
                case .success:
                    self?.updateUI()
                    self?.showAlert(title: "Success!", message: "Reservation was Successfully Accepted")
                }
            }
        }

        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @objc func declineButtonPressed(_ sender: UIButton) {
        print("decline button pressed")
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
       
        // Create Firebase function to decline reservation and add it in the closure here
        let acceptAction = UIAlertAction(title: "Decline this reservation request", style: .default) { (alertAction) in
            DatabaseService.shared.updateReservation(reservation: self.selectedReservation!) { [weak self](result) in
                switch result {
                case .failure(let error):
                    self?.showAlert(title: "Error declining reservation", message: error.localizedDescription)
                case .success:
                    self?.selectedStatus = 1
                    self?.showAlert(title: nil, message: "Reservation was Successfully Accepted")
                }
            }
        }
        
        alertController.addAction(acceptAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

}
