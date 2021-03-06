//
//  HomeViewController.swift
//  ComicBox
//
//  Created by Joshua Okoro on 1/31/19.
//  Copyright © 2019 Joshua Okoro. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON
import ProgressHUD

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    //MARK: - Recent Release UI Elements
    @IBOutlet weak var recentReleaseDate: UILabel!
    @IBOutlet weak var recentReleaseTitle: UILabel!
    @IBOutlet weak var recentReleaseDescription: UIButton!
    @IBOutlet weak var recentReleaseBookmark: UIImageView!
    
    
    
    @IBOutlet weak var comicShelfTable: UITableView!
    
    //MARK: - Bookmark UI Elements
    @IBOutlet weak var newBookmarkDate: UILabel!
    @IBOutlet weak var newBookmarkTitle: UILabel!
    @IBOutlet weak var newBookmarkDescription: UILabel!
    
    
    //MARK: - Other Constants And Variable
    var randomComicID = [Int]()
    
    fileprivate var lastID: Int = 1
    var firstID: Int = 1
    private var comicShelf = [ComicShelf]()
    
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Arrays
//    var comics = [Comic]()
    var comic = [Comics]()
    
    var loadedID = [LatestComic]()
    
    var recentContent: Recent?
    
    var passID: Int = 0
    
    
    // ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ProgressHUD.show("Updating")
        getRecentRelease()
//        print(dataFilePath)
        
        comicShelfTable.separatorStyle = .none
    }
    
    
    //MARK: - View All Bookmarks Button Pressed
    @IBAction func viewAllBookmarks(_ sender: UIButton) {
    }
    
    
    //MARK: - Network To Get Recent Release
    func getRecentRelease() {
        Alamofire.request("https://xkcd.com/info.0.json").validate().responseJSON { (response) in
            switch response.result {
            case .success:
                ProgressHUD.showSuccess("Got New Release!")
                let resultInJSON = JSON(response.result.value!)
                self.updateWithRecentRelease(resultInJSON)
            case .failure(let error):
                ProgressHUD.showError("Unable To Get New Release\n😞")
                self.handleErrors(error)
            }
        }
    }
    
    //MARK: - Unwrap with JSON and Update Recent Release View
    func updateWithRecentRelease(_ result: JSON) {
        let year = result["year"].string!
        let month = result["month"].string!
        let day = result["day"].string!
        let title = result["safe_title"].string
        let content = result["alt"].string
        
        recentReleaseTitle.text = title
        recentReleaseDate.text = "\(month)-\(day)-\(year)"
        recentReleaseDescription.setTitle(content, for: .normal)

        lastID = result["num"].int!
        
        let newComicID = LatestComic(context: context)
        newComicID.comicID = result["num"].int32!
//        save()
        
        for _ in 1 ... 2 {
            randomComicID.append(Int.random(in: 1 ... lastID))
        }
        // Get 2 Random Comis for Home Comic Shelf
        getComics(comicID: randomComicID)

    }
    
    //MARK: - Network To Get Random Comics For Shelf
    func getComics(comicID: [Int]) {
        // Get First Comic and Add To Array
        for id in randomComicID {
            
            Alamofire.request("https://xkcd.com/\(id)/info.0.json").validate().responseJSON { (response) in
                switch response.result {
                case .success:
                    let result = JSON(response.result.value!)
                    
                    self.updateShelf(result["safe_title"].string!, result["num"].int!)
                    
                case .failure(let error):
                    self.handleErrors(error)
                }
            }
        }
    }
    
    func updateShelf(_ title: String, _ id: Int) {
        let shelf = ComicShelf()
        shelf.title = title
        shelf.comicID = id
        comicShelf.append(shelf)
        comicShelfTable.reloadData()
    }
    
    //MARK: - TableView Display Content to Comic Shelf Cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comicShelf.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "HomeComicShelfCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        cell.textLabel?.text = comicShelf[indexPath.row].title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        passID = comicShelf[indexPath.row].comicID
        if passID != 0 {
            performSegue(withIdentifier: "ToRead", sender: self)
        }
    }
    
    
    @IBAction func recentReleaseTapped(_ sender: UIButton) {
        passID = lastID
        if passID != 0 {
            performSegue(withIdentifier: "ToRead", sender: self)
        }
    }
    
    
    
    
    //MARK: - Dislay Error Message
    func handleErrors(_ error: Error) {
        // NEEDS TO BE REFRACTORED
        print(error)
    }
    
    
    
    
    
    
    //MARK: - PROTOCOL AND SEGUE TO COMIC SHELF
    @IBAction func viewAllComics(_ sender: UIButton) {
        performSegue(withIdentifier: "ToComicShelf", sender: self)
    }
    //MARK: - Multiple Segue Performance
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ToRead" {
            let comicView = segue.destination as! ViewController
            comicView.comicID = passID
        } else if segue.identifier == "ToComicShelf" {
            let comicShelf = segue.destination as! ComicShelfViewController
            comicShelf.endingID = lastID
        }
    }
    
    //End of HomeViewController
}
