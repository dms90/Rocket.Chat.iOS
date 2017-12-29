//
//  EmojiPicker.swift
//  Rocket.Chat
//
//  Created by Matheus Cardoso on 12/20/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

import UIKit

fileprivate typealias EmojiCategory = (name: String, emojis: [Emoji])

class EmojiPicker: UIView {
    static let defaults = UserDefaults(suiteName: "EmojiPicker")

    fileprivate func localized(_ string: String) -> String {
        return NSLocalizedString(string, tableName: "EmojiPicker", bundle: Bundle.main, value: "", comment: "")
    }

    var recentEmojis: [Emoji] {
        get {
            if let data = EmojiPicker.defaults?.value(forKey:"recentEmojis") as? Data {
                let emojis = try? PropertyListDecoder().decode(Array<Emoji>.self, from: data)
                return emojis ?? []
            }

            return []
        }

        set {
            let emojis = newValue.count < 31 ? newValue : Array(newValue.dropLast(newValue.count - 30))
            EmojiPicker.defaults?.set(try? PropertyListEncoder().encode(emojis), forKey: "recentEmojis")
        }
    }

    fileprivate let defaultCategories: [EmojiCategory] = [
        (name: "activity", emojis: Emojione.activity),
        (name: "people", emojis: Emojione.people),
        (name: "travel", emojis: Emojione.travel),
        (name: "nature", emojis: Emojione.nature),
        (name: "objects", emojis: Emojione.objects),
        (name: "symbols", emojis: Emojione.symbols),
        (name: "food", emojis: Emojione.food),
        (name: "flags", emojis: Emojione.flags)
    ]
    fileprivate var searchedCategories: [(name: String, emojis: [Emoji])] = []
    fileprivate func searchCategories(string: String) -> [EmojiCategory] {
        return defaultCategories.map {
            let emojis = $0.emojis.filter {
                $0.name.contains(string) || $0.shortname.contains(string) ||
                $0.keywords.joined(separator: " ").contains(string) ||
                $0.alternates.joined(separator: " ").contains(string)
            }

            return (name: $0.name, emojis: emojis)
        }.filter { !$0.emojis.isEmpty }
    }

    var isSearching: Bool {
        return searchBar?.text != nil && searchBar?.text?.isEmpty != true
    }

    fileprivate var currentCategories: [EmojiCategory] {
        let recentCategory = (name: "recent", emojis: recentEmojis)
        let categories = (recentEmojis.count > 0 ? [recentCategory] : []) + defaultCategories
        return isSearching ? searchedCategories : categories
    }

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var categoriesView: UITabBar! {
        didSet {
            let categoryItems = currentCategories.map { category -> UITabBarItem in
                let image = UIImage(named: category.name) ?? UIImage(named: "custom")
                let item = UITabBarItem(title: nil, image: image, selectedImage: image)
                item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                return item
            }

            categoriesView.setItems(categoryItems, animated: false)

            categoriesView.delegate = self
            categoriesView.layoutIfNeeded()
        }
    }

    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.delegate = self
        }
    }

    @IBOutlet weak var emojisCollectionView: UICollectionView! {
        didSet {
            setupCollectionView()
        }
    }

    let skinTones: [(name: String?, color: UIColor)] = [
        (name: nil, color: #colorLiteral(red: 0.999120295, green: 0.8114234805, blue: 0.06628075987, alpha: 1)),
        (name: "tone1", color: #colorLiteral(red: 0.9791174531, green: 0.8912416697, blue: 0.7634990811, alpha: 1)),
        (name: "tone2", color: #colorLiteral(red: 0.8864725232, green: 0.8108071685, blue: 0.6322135925, alpha: 1)),
        (name: "tone3", color: #colorLiteral(red: 0.8586704731, green: 0.6372342706, blue: 0.4515766501, alpha: 1)),
        (name: "tone4", color: #colorLiteral(red: 0.6580494642, green: 0.5000503063, blue: 0.3285613656, alpha: 1)),
        (name: "tone5", color: #colorLiteral(red: 0.3705755472, green: 0.3079021573, blue: 0.2594769299, alpha: 1))
    ]

    var currentSkinToneIndex: Int {
        get {
            return EmojiPicker.defaults?.integer(forKey: "currentSkinToneIndex") ?? 0
        }

        set {
            EmojiPicker.defaults?.set(currentSkinToneIndex, forKey: "currentSkinToneIndex")
        }
    }

    var currentSkinTone: (name: String?, color: UIColor) {
        return skinTones[currentSkinToneIndex]
    }

    @IBOutlet weak var skinToneButton: UIButton! {
        didSet {
            skinToneButton.layer.cornerRadius = skinToneButton.frame.width/2
            skinToneButton.backgroundColor = currentSkinTone.color
            skinToneButton.showsTouchWhenHighlighted = true
            skinToneButton.layer.borderWidth = 1.0
            skinToneButton.layer.borderColor = UIColor.lightGray.cgColor.copy(alpha: 0.5)
        }
    }

    @IBAction func didPressSkinToneButton(_ sender: UIButton) {
        currentSkinToneIndex += 1
        currentSkinToneIndex = currentSkinToneIndex % skinTones.count
        skinToneButton.backgroundColor = currentSkinTone.color
        emojisCollectionView.reloadData()
    }

    var emojiPicked: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("EmojiPicker", owner: self, options: nil)

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "|-0-[view]-0-|", options: [], metrics: nil, views: ["view": contentView]
            )
        )
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": contentView]
            )
        )
    }

    private func setupCollectionView() {
        emojisCollectionView.dataSource = self
        emojisCollectionView.delegate = self

        let emojiCellNib = UINib(nibName: "EmojiCollectionViewCell", bundle: nil)
        emojisCollectionView.register(emojiCellNib, forCellWithReuseIdentifier: "EmojiCollectionViewCell")
        emojisCollectionView.register(EmojiPickerSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "EmojiPickerSectionHeaderView")

        if let layout = emojisCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionHeadersPinToVisibleBounds = true
            layout.headerReferenceSize = CGSize(width: self.frame.width, height: 20)
        }

        emojisCollectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
}

extension EmojiPicker: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "EmojiPickerSectionHeaderView",
            for: indexPath
        ) as? EmojiPickerSectionHeaderView else { return UICollectionReusableView() }

        headerView.textLabel.text = self.localized("categories.\(currentCategories[indexPath.section].name)")

        return headerView
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentCategories[section].emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCollectionViewCell", for: indexPath) as? EmojiCollectionViewCell else { return UICollectionViewCell() }

        let emoji = currentCategories[indexPath.section].emojis[indexPath.row]

        if emoji.supportsTones, let currentTone = currentSkinTone.name {
            let shortname = String(emoji.shortname.dropLast()) + "_\(currentTone):"
            cell.emojiView.emojiLabel.text = Emojione.transform(string: shortname)
        } else {
            cell.emojiView.emojiLabel.text = Emojione.transform(string: emoji.shortname)
        }

        return cell
    }
}

extension EmojiPicker: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchedCategories = searchCategories(string: searchText.lowercased())
        emojisCollectionView.reloadData()
    }
}

extension EmojiPicker: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 36.0, height: 36.0)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let emoji = currentCategories[indexPath.section].emojis[indexPath.row]

        if emoji.supportsTones, let currentTone = currentSkinTone.name {
            let shortname = String(emoji.shortname.dropLast()) + "_\(currentTone):"
            emojiPicked?(shortname)
        } else {
            emojiPicked?(emoji.shortname)
        }

        if !recentEmojis.contains { $0.shortname == emoji.shortname  } {
            recentEmojis = [emoji] + recentEmojis
        }

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 20.0)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let item = categoriesView.items?[indexPath.section] {
            categoriesView.selectedItem = item
        }
    }
}

extension EmojiPicker: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.index(of: item) else { return }

        searchBar.resignFirstResponder()
        searchBar.text = ""

        emojisCollectionView.reloadData()
        emojisCollectionView.layoutIfNeeded()

        let indexPath = IndexPath(row: 1, section: index)
        emojisCollectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        emojisCollectionView.setContentOffset(emojisCollectionView.contentOffset.applying(CGAffineTransform(translationX: 0.0, y: -20.0)), animated: false)
    }
}

private class EmojiPickerSectionHeaderView: UICollectionReusableView {
    var textLabel: UILabel
    let screenWidth = UIScreen.main.bounds.width

    override init(frame: CGRect) {
        textLabel = UILabel()

        super.init(frame: frame)

        addSubview(textLabel)

        textLabel.font = .systemFont(ofSize: UIFont.systemFontSize + 4)
        textLabel.textColor = .gray
        textLabel.textAlignment = .left
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: textLabel, attribute: .leading, relatedBy: .equal,
                               toItem: self, attribute: .leadingMargin,
                               multiplier: 1.0, constant: -8.0),

            NSLayoutConstraint(item: textLabel, attribute: .trailing, relatedBy: .equal,
                               toItem: self, attribute: .trailingMargin,
                               multiplier: 1.0, constant: 0.0),

            NSLayoutConstraint(item: textLabel, attribute: .height, relatedBy: .equal,
                               toItem: nil, attribute: .height,
                               multiplier: 1.0, constant: 20.0)
        ])

        backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}