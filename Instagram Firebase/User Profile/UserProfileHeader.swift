//
//  UserProfileHeader.swift
//  Instagram Firebase
//
//  Created by Vyacheslav Nagornyak on 4/6/17.
//  Copyright © 2017 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit
import Firebase

class UserProfileHeader: UICollectionViewCell {
  
  // MARK: - Variables
  var user: User? {
    didSet {
      guard let profileImageUrl = user?.profileImageUrl else { return }
      profileImageView.loadImage(url: profileImageUrl)
      
      usernameLabel.text = user?.username
      
      setupEditFollowButton()
    }
  }
  
  // MARK: - UI
  let profileImageView: CustomImageView = {
    let imageView = CustomImageView()
    return imageView
  }()
  
  let postsLabel: UILabel = {
    let label = UILabel()
    let attributedText = NSMutableAttributedString(string: "11\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
    attributedText.append(NSAttributedString(string: "posts", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray]))
    label.attributedText = attributedText
    label.textAlignment = .center
    label.numberOfLines = 2
    return label
  }()
  
  let followersLabel: UILabel = {
    let label = UILabel()
    let attributedText = NSMutableAttributedString(string: "0\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
    attributedText.append(NSAttributedString(string: "followers", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray]))
    label.attributedText = attributedText
    label.textAlignment = .center
    label.numberOfLines = 2
    return label
  }()
  
  let followingLabel: UILabel = {
    let label = UILabel()
    let attributedText = NSMutableAttributedString(string: "0\n", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
    attributedText.append(NSAttributedString(string: "following", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.lightGray]))
    label.attributedText = attributedText
    label.textAlignment = .center
    label.numberOfLines = 2
    return label
  }()
  
  lazy var editProfileFollowButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitleColor(.black, for: .normal)
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    button.layer.borderColor = UIColor.lightGray.cgColor
    button.layer.borderWidth = 0.5
    button.layer.cornerRadius = 4
    button.addTarget(self, action: #selector(handleEditFollow), for: .touchUpInside)
    return button
  }()
  
  let usernameLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.boldSystemFont(ofSize: 14)
    return label
  }()
  
  let gridButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
    button.tintColor = UIColor(white: 0, alpha: 0.2)
    return button
  }()
  
  let listButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(#imageLiteral(resourceName: "list"), for: .normal)
    button.tintColor = UIColor(white: 0, alpha: 0.2)
    return button
  }()
  
  let bookmarkButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(#imageLiteral(resourceName: "ribbon"), for: .normal)
    button.tintColor = UIColor(white: 0, alpha: 0.2)
    return button
  }()
  
  // MARK: - Initializers
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(profileImageView)
    
    let profileImageHeight: CGFloat = 80
    profileImageView.anchor(top: topAnchor, leading: leadingAnchor, width: profileImageView.heightAnchor, topConstant: 12, leadingConstant: 12, heightConstant: profileImageHeight)
    profileImageView.layer.cornerRadius = profileImageHeight * 0.5
    profileImageView.clipsToBounds = true
    
    let statsView = setupUserStats()
    
    addSubview(editProfileFollowButton)
    editProfileFollowButton.anchor(top: postsLabel.bottomAnchor, leading: statsView.leadingAnchor, trailing: statsView.trailingAnchor, topConstant: 6, leadingConstant: 4, trailingConstant: 4, heightConstant: 28)
    
    addSubview(usernameLabel)
    usernameLabel.anchor(top: profileImageView.bottomAnchor, leading: leadingAnchor, trailing: trailingAnchor, topConstant: 12, leadingConstant: 12, trailingConstant: 12)
    
    setupBottomToolbar()
  }
  
  // MARK: - Handlers
  func handleEditFollow() {
    guard let currentUid = FIRAuth.auth()?.currentUser?.uid,
      let userId = user?.uid else { return }
    
    if editProfileFollowButton.titleLabel?.text == "Follow" {
      let values = [userId: 1]
      FIRDatabase.database().reference().child("following").child(currentUid).updateChildValues(values) { (error, ref) in
        if let error = error {
          print("Failed to follow user:", error)
          return
        }
        
        print("Successfully followed user:", self.user?.uid ?? "")
        
        self.setupFollowStyle(isFollow: false)
      }
    } else {
      FIRDatabase.database().reference().child("following").child(currentUid).child(userId).removeValue(completionBlock: { (error, ref) in
        if let error = error {
          print("Failed to check for unfollow:", error)
          return
        }
        
        print("Successfully unfollow user:", self.user?.username ?? "")
        
        self.setupFollowStyle(isFollow: true)
      })
    }
  }
  
  // MARK: - Functions
  private func setupUserStats() -> UIView {
    let stackView = UIStackView(arrangedSubviews: [postsLabel, followersLabel, followingLabel])
    stackView.distribution = .fillEqually
    
    addSubview(stackView)
    stackView.anchor(top: profileImageView.topAnchor, leading: profileImageView.trailingAnchor, trailing: trailingAnchor, leadingConstant: 12, trailingConstant: 12)
    
    return stackView
  }
  
  private func setupEditFollowButton() {
    guard let currentUserId = FIRAuth.auth()?.currentUser?.uid,
      let userId = user?.uid else { return }
    
    if userId == currentUserId {
      editProfileFollowButton.setTitle("Edit Profile", for: .normal)
    } else {
      FIRDatabase.database().reference().child("following").child(currentUserId).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
        if let isFollowing = snapshot.value as? Int, isFollowing == 1 {
          self.editProfileFollowButton.setTitle("Unfollow", for: .normal)
        } else {
          self.setupFollowStyle(isFollow: true)
        }
      }, withCancel: { (error) in
        print("Failed to fetch following user", error)
      })
    }
  }
  
  private func setupFollowStyle(isFollow: Bool) {
    if isFollow {
      editProfileFollowButton.setTitle("Follow", for: .normal)
      editProfileFollowButton.setTitleColor(.white, for: .normal)
      UIView.animate(withDuration: 0.15) {
        self.editProfileFollowButton.backgroundColor = #colorLiteral(red: 0.06666666667, green: 0.6039215686, blue: 0.9294117647, alpha: 1)
      }
      editProfileFollowButton.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
    } else {
      editProfileFollowButton.setTitle("Unfollow", for: .normal)
      editProfileFollowButton.setTitleColor(.black, for: .normal)
      UIView.animate(withDuration: 0.15) {
        self.editProfileFollowButton.backgroundColor = .white
      }
      editProfileFollowButton.layer.borderColor = UIColor.lightGray.cgColor
    }
  }
  
  private func setupBottomToolbar() {
    let stackView = UIStackView(arrangedSubviews: [gridButton, listButton, bookmarkButton])
    stackView.distribution = .fillEqually
    
    addSubview(stackView)
    stackView.anchor(leading: leadingAnchor, trailing: trailingAnchor, bottom: bottomAnchor, heightConstant: 50)
    [stackView.topAnchor, stackView.bottomAnchor].forEach { [unowned self] (anchor) in
      let v = UIView()
      v.backgroundColor = .lightGray
      self.addSubview(v)
      v.anchor(top: anchor, leading: self.leadingAnchor, trailing: self.trailingAnchor, heightConstant: 0.5)
    }
  }
}
