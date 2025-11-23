//
//  customViewController.swift
//  GPA Calculator
//
//  Created by LegitMichel777 on 2020/11/15.
//  Modified by willuhd on 2025/11/22. 
//
//  - added module selection logic (fifo)
//

import UIKit
import SwiftUI

@IBDesignable
public class Gradient: UIView {
    @IBInspectable var startColor: UIColor = UIColor(named: "grad1")! { didSet { updateColors() }}
    @IBInspectable var endColor: UIColor = UIColor(named: "grad2")! { didSet { updateColors() }}
    override public class var layerClass: AnyClass { CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
    func updateColors() { gradientLayer.colors = [startColor.cgColor, endColor.cgColor] }
    func updt() { updateColors() }
}

class customViewController: UIViewController {
    @IBOutlet weak var scoreSelectionControl: UISegmentedControl!
    @IBOutlet weak var mainStk: UIStackView!
    @IBOutlet var masterStack: UIStackView!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    
    var grads: [Gradient] = []
    var selP: Preset?
    var dynamicViews: [UIView] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selP = currentPreset
        scoreSelectionControl.selectedSegmentIndex = (scoreDisplay == .percentage) ? 0 : 1
        lastUpdateLabel.text = "Last course auto-update at \(rootData?.lastUpdated ?? "i forgor")"
        
        let swiftuiview = tfPromotionView()
        let hostingController = UIHostingController(rootView: swiftuiview)
        hostingController.view.backgroundColor = .clear
        addChild(hostingController)
        masterStack.addArrangedSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        redrawContent()
    }
    
    func redrawContent() {
        for view in dynamicViews { view.removeFromSuperview() }
        dynamicViews.removeAll()
        grads.removeAll()
        
        var insertIndex = 1
        
        // draw presets grid
        let prPrR = 2
        let mstrGrps = Int(ceil(Double(presets.count) / Double(prPrR)))
        
        for i in 0..<mstrGrps {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 13
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            
            for j in 0..<prPrR {
                let idx = i * prPrR + j
                if idx >= presets.count {
                    let vw = UIView()
                    vw.heightAnchor.constraint(equalToConstant: 70).isActive = true
                    rowStack.addArrangedSubview(vw)
                } else {
                    let p = presets[idx]
                    let container = UIView()
                    container.backgroundColor = UIColor(named: "presetFloat")
                    container.heightAnchor.constraint(equalToConstant: 70).isActive = true
                    container.layer.cornerRadius = 8
                    container.clipsToBounds = true
                    
                    let grd = Gradient()
                    grd.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(grd)
                    NSLayoutConstraint.activate([
                        grd.topAnchor.constraint(equalTo: container.topAnchor),
                        grd.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                        grd.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                        grd.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                    ])
                    grd.updt()
                    grd.alpha = (selP?.id == p.id) ? 1 : 0
                    grads.append(grd)
                    
                    let lbl = UILabel()
                    lbl.text = p.name
                    lbl.font = .systemFont(ofSize: 24, weight: .semibold)
                    lbl.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(lbl)
                    
                    let sub = UILabel()
                    sub.text = p.subtitle ?? "\(p.modules.reduce(0){$0+$1.subjects.count}) items"
                    sub.font = .systemFont(ofSize: 14)
                    sub.textColor = UIColor(named: "subttl")
                    sub.translatesAutoresizingMaskIntoConstraints = false
                    container.addSubview(sub)
                    
                    NSLayoutConstraint.activate([
                        lbl.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
                        lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
                        sub.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 2),
                        sub.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15)
                    ])
                    
                    let btn = UIButton()
                    btn.translatesAutoresizingMaskIntoConstraints = false
                    btn.tag = idx
                    btn.addTarget(self, action: #selector(itmSel), for: .touchUpInside)
                    container.addSubview(btn)
                    NSLayoutConstraint.activate([
                        btn.topAnchor.constraint(equalTo: container.topAnchor),
                        btn.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                        btn.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                        btn.trailingAnchor.constraint(equalTo: container.trailingAnchor)
                    ])
                    
                    rowStack.addArrangedSubview(container)
                }
            }
            
            mainStk.insertArrangedSubview(rowStack, at: insertIndex)
            dynamicViews.append(rowStack)
            insertIndex += 1
            
            let spc = UIView()
            spc.translatesAutoresizingMaskIntoConstraints = false
            spc.heightAnchor.constraint(equalToConstant: 13).isActive = true
            mainStk.insertArrangedSubview(spc, at: insertIndex)
            dynamicViews.append(spc)
            insertIndex += 1
        }
        
        // draw module configs
        guard let p = selP else { return }
        for (modIndex, module) in p.modules.enumerated() where module.type == "choice" {
            let configView = ModuleConfigView(presetId: p.id, modIndex: modIndex, module: module)
            configView.translatesAutoresizingMaskIntoConstraints = false
            mainStk.insertArrangedSubview(configView, at: insertIndex)
            dynamicViews.append(configView)
            insertIndex += 1
            
            let spc = UIView()
            spc.translatesAutoresizingMaskIntoConstraints = false
            spc.heightAnchor.constraint(equalToConstant: 13).isActive = true
            mainStk.insertArrangedSubview(spc, at: insertIndex)
            dynamicViews.append(spc)
            insertIndex += 1
        }
    }

    @objc func itmSel(button: UIButton) {
        let tg = button.tag
        if selP?.id != presets[tg].id {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            UIView.animate(withDuration: 0.3) {
                if let oldID = self.selP?.id, let oldIdx = presets.firstIndex(where: {$0.id == oldID}) {
                    if oldIdx < self.grads.count { self.grads[oldIdx].alpha = 0 }
                }
                if tg < self.grads.count { self.grads[tg].alpha = 1 }
            }
            
            selP = presets[tg]
            currentPreset = selP
            redrawContent()
        }
    }
    
    @IBAction func scoreSelectionChanged(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        scoreDisplay = (scoreSelectionControl.selectedSegmentIndex == 0) ? .percentage : .letter
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NotificationCenter.default.post(name: Notification.Name("updatePreset"), object: nil)
    }
}

// MARK: - module selectors view
class ModuleConfigView: UIView {
    let presetId: String
    let modIndex: Int
    let module: Module
    
    var isExpanded: Bool = false
    var itemsStack: UIStackView!
    var headerLabel: UILabel!
    var statusLabel: UILabel!
    var arrowImg: UIImageView!
    
    init(presetId: String, modIndex: Int, module: Module) {
        self.presetId = presetId
        self.modIndex = modIndex
        self.module = module
        super.init(frame: .zero)
        setupUI()
        refreshList()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setupUI() {
        backgroundColor = UIColor(named: "presetFloat")
        layer.cornerRadius = 8
        clipsToBounds = true
        
        // main vstack
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // header
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        mainStack.addArrangedSubview(headerView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleExpand))
        headerView.addGestureRecognizer(tap)
        
        headerLabel = UILabel()
        headerLabel.text = module.name
        headerLabel.font = .boldSystemFont(ofSize: 18)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerLabel)
        
        statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = UIColor(named: "subttl")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(statusLabel)
        
        arrowImg = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImg.tintColor = .systemGray
        arrowImg.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(arrowImg)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            statusLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            arrowImg.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            arrowImg.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15)
        ])
        
        itemsStack = UIStackView()
        itemsStack.axis = .vertical
        itemsStack.isHidden = true
        mainStack.addArrangedSubview(itemsStack)
    }
    
    @objc func toggleExpand() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        isExpanded.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.itemsStack.isHidden = !self.isExpanded
            self.itemsStack.alpha = self.isExpanded ? 1 : 0
            self.arrowImg.transform = self.isExpanded ? CGAffineTransform(rotationAngle: .pi / 2) : .identity
            self.layoutIfNeeded()
        }
    }
    
    func refreshList() {
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let key = "config_\(presetId)_mod_\(modIndex)"
        let selected = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        let limit = module.selectionLimit ?? 1
        
        statusLabel.text = "\(selected.count) / \(limit) selected"
        
        // populate
        for (i, subj) in module.subjects.enumerated() {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            let btn = UIButton()
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.tag = i
            btn.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            row.addSubview(btn)
            btn.frame = row.bounds
            btn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            let lbl = UILabel()
            lbl.text = subj.name
            lbl.font = .systemFont(ofSize: 16)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(lbl)
            
            let icon = UIImageView(image: UIImage(systemName: selected.contains(i) ? "checkmark.circle.fill" : "circle"))
            icon.tintColor = selected.contains(i) ? .systemBlue : .systemGray4
            icon.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(icon)
            
            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 15),
                lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                icon.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -15),
                icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                btn.topAnchor.constraint(equalTo: row.topAnchor),
                btn.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                btn.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                btn.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])
            
            // separator
            if i > 0 {
                let sep = UIView()
                sep.backgroundColor = .systemGray5
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
                row.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: row.topAnchor),
                    sep.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 15),
                    sep.trailingAnchor.constraint(equalTo: row.trailingAnchor)
                ])
            }
            
            itemsStack.addArrangedSubview(row)
        }
    }
    
    // FIFO selection logic
    @objc func itemTapped(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        let idx = sender.tag
        let key = "config_\(presetId)_mod_\(modIndex)"
        let limit = module.selectionLimit ?? 1
        var selected = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        
        if let existingIdx = selected.firstIndex(of: idx) {
            selected.remove(at: existingIdx)
        } else {
            selected.append(idx)
            if selected.count > limit {
                selected.removeFirst() // keep size
            }
        }
        
        UserDefaults.standard.set(selected, forKey: key)
        refreshList()
    }
}
