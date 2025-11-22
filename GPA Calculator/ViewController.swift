//
//  ViewController.swift
//  GPA Calculator
//
//  Created by LegitMichel777 on 2020/11/10.
//  Modified by willuhd on 2025/11/25.
//
//  - adds support for the pie chart
//  - adapts to new memory model
//

import UIKit

// MARK: - memory models
// for view and pies

struct PieSlice: Equatable {
    var value: Double
    var color: UIColor
    var label: String
    var subGPA: Double
    
    // include the difference as well for easier animations
    static func == (lhs: PieSlice, rhs: PieSlice) -> Bool {
        return lhs.label == rhs.label &&
               abs(lhs.value - rhs.value) < 0.001 &&
               lhs.color == rhs.color
    }
}

struct subjectView {
    var masterView: UIView!
    var separatorView: UIView!
    var levelSelect: UISegmentedControl
    var scoreSelect: UISegmentedControl
    var subjectLabel: UILabel
}

var subjectViews = [subjectView]()
var currentPreset: Preset?
var activeSubjects: [Subject] = []

enum ScoreDisplay {
    case percentage
    case letter
}
var scoreDisplay = ScoreDisplay.percentage
var autosave = true
var bottomPadding: UIView? = nil

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mainSubjectsStack: UIStackView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var editButtonRoundedRectMask: UIView!
    @IBOutlet weak var calculationResultDisplayView: UILabel!
    @IBOutlet weak var resetButtonRoundedRectMask: UIView!
    
    var pieChartView = PieChartView()

    let userData = UserDefaults.standard

    @IBAction func editWeight(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    @IBAction func reset(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        for i in 0..<subjectViews.count {
            subjectViews[i].scoreSelect.selectedSegmentIndex = 0
            subjectViews[i].levelSelect.selectedSegmentIndex = 0
        }
        recomputeGPA(segment: nil)
    }

    @objc func updatePreset() {
        if currentPreset != nil {
            activeSubjects = getActiveSubjects(for: currentPreset!)
        }
        drawUI(doSave: true)
    }

    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
            updatePreset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePreset), name: Notification.Name("updatePreset"), object: nil)
        initPresets()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        calculationResultDisplayView.text = ""
        
        mainScrollView.layer.masksToBounds = true
        mainScrollView.layer.cornerRadius = mainScrollView.layer.bounds.width / 35
        mainScrollView.layer.cornerCurve = .continuous
        mainScrollView.showsVerticalScrollIndicator = false
        
        editButtonRoundedRectMask.layer.masksToBounds = true
        editButtonRoundedRectMask.layer.cornerCurve = .continuous
        editButtonRoundedRectMask.layer.cornerRadius = editButtonRoundedRectMask.layer.bounds.height / 2
        
        mainSubjectsStack.layer.masksToBounds = true
        mainSubjectsStack.layer.cornerCurve = .continuous
        mainSubjectsStack.layer.cornerRadius = mainSubjectsStack.layer.bounds.width / 35
        
        resetButtonRoundedRectMask.clipsToBounds = true
        resetButtonRoundedRectMask.layer.masksToBounds = true
        resetButtonRoundedRectMask.layer.cornerCurve = .continuous
        resetButtonRoundedRectMask.layer.cornerRadius = editButtonRoundedRectMask.layer.bounds.height / 2

        if let id = userData.string(forKey: "preset"), let p = presets.first(where: { $0.id == id }) {
            currentPreset = p
        } else {
            currentPreset = presets.first
        }
        
        if let mode = userData.string(forKey: "scoreDisplayMode") {
            scoreDisplay = (mode == "letter") ? .letter : .percentage
        }
        
        // init pie chart
        pieChartView.backgroundColor = .clear
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        
        updatePreset()
    }

    let subjectCellHeight = 108

    func drawUI(doSave: Bool) {
            if bottomPadding != nil { bottomPadding!.removeFromSuperview() }
            for i in subjectViews { i.masterView.removeFromSuperview() }
            subjectViews.removeAll()
            pieChartView.removeFromSuperview()
            
            // remove the pie to animate fresh
            pieChartView.reset()
            
            guard let _ = currentPreset else { return }
            
            for i in 0..<activeSubjects.count {
                let mstr = UIView()
                mainSubjectsStack.addArrangedSubview(mstr)
                mstr.translatesAutoresizingMaskIntoConstraints = false
                mstr.heightAnchor.constraint(equalToConstant: CGFloat(subjectCellHeight)).isActive = true
                
                var nv = subjectView(masterView: mstr, separatorView: UIView(), levelSelect: UISegmentedControl(), scoreSelect: UISegmentedControl(), subjectLabel: UILabel())
                
                // separator
                let sep = UIView()
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.heightAnchor.constraint(equalToConstant: 2).isActive = true
                sep.backgroundColor = UIColor(named: "sep")
                mstr.addSubview(sep)
                nv.separatorView = sep
                sep.topAnchor.constraint(equalTo: mstr.topAnchor).isActive = true
                sep.trailingAnchor.constraint(equalTo: mstr.trailingAnchor).isActive = true
                sep.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: (i == 0 ? 0 : 20)).isActive = true
                if i != 0 {
                    sep.layer.cornerRadius = 1
                    sep.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                }

                // LEVEL SELECTION
                let lvl = UISegmentedControl()
                lvl.apportionsSegmentWidthsByContent = true
                lvl.translatesAutoresizingMaskIntoConstraints = false
                for (k, level) in activeSubjects[i].levels.enumerated() {
                    lvl.insertSegment(withTitle: level.name, at: k, animated: false)
                }
                mstr.addSubview(lvl)
                lvl.selectedSegmentIndex = 0
                
                lvl.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive = true
                lvl.trailingAnchor.constraint(equalTo: mstr.trailingAnchor, constant: -10).isActive = true
                
                // stretch the thing to fill the space without disruption
                lvl.setContentHuggingPriority(.defaultLow, for: .horizontal)
                lvl.setContentCompressionResistancePriority(.required, for: .horizontal)

                lvl.addTarget(self, action: #selector(recomputeGPA), for: .valueChanged)
                nv.levelSelect = lvl
                
                // SUBJECT LABEL
                let lbl = UILabel()
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = activeSubjects[i].name
                lbl.font = UIFont.systemFont(ofSize: 25)
                lbl.lineBreakMode = .byTruncatingTail
                mstr.addSubview(lbl)
                
                lbl.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive = true
                lbl.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: 10).isActive = true
                lbl.trailingAnchor.constraint(equalTo: lvl.leadingAnchor, constant: -20).isActive = true
                
                // hugged tightly but give space via shrinking if necessary
                lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                
                nv.subjectLabel = lbl
                
                // SCORE SELECTION
                let sc = UISegmentedControl()
                sc.apportionsSegmentWidthsByContent = true
                sc.translatesAutoresizingMaskIntoConstraints = false
                let map = activeSubjects[i].customScoreToBaseGPAMap ?? commonScoreMap
                for (k, item) in map.enumerated() {
                    sc.insertSegment(withTitle: (scoreDisplay == .percentage ? item.percentageName : item.letterName), at: k, animated: false)
                }
                mstr.addSubview(sc)
                sc.selectedSegmentIndex = 0
                sc.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 60).isActive = true
                sc.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: 10).isActive = true
                sc.trailingAnchor.constraint(equalTo: mstr.trailingAnchor, constant: -10).isActive = true
                sc.addTarget(self, action: #selector(recomputeGPA), for: .valueChanged)
                nv.scoreSelect = sc
                
                subjectViews.append(nv)
            }
            
            // restore
            if !doSave {
                for i in 0..<subjectViews.count {
                    if let l = userData.value(forKey: "sellvlseg\(i)") as? Int, l < subjectViews[i].levelSelect.numberOfSegments {
                        subjectViews[i].levelSelect.selectedSegmentIndex = l
                    }
                    if let s = userData.value(forKey: "selscseg\(i)") as? Int, s < subjectViews[i].scoreSelect.numberOfSegments {
                        subjectViews[i].scoreSelect.selectedSegmentIndex = s
                    }
                }
            }
            
            // add pie chart
            mainSubjectsStack.addArrangedSubview(pieChartView)
            pieChartView.heightAnchor.constraint(equalToConstant: 350).isActive = true
            
            let botBuf = UIView()
            botBuf.heightAnchor.constraint(equalToConstant: 50).isActive = true
            bottomPadding = botBuf
            mainSubjectsStack.addArrangedSubview(botBuf)
            
            if doSave { recomputeGPA(segment: nil) }
    }

    @objc func recomputeGPA(segment: UISegmentedControl?) {
        if segment != nil {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        if autosave {
            userData.setValue(currentPreset?.id, forKey: "preset")
            userData.setValue(scoreDisplay == .percentage ? "percentage" : "letter", forKey: "scoreDisplayMode")
            for i in 0..<subjectViews.count {
                userData.setValue(subjectViews[i].levelSelect.selectedSegmentIndex, forKey: "sellvlseg\(i)")
                userData.setValue(subjectViews[i].scoreSelect.selectedSegmentIndex, forKey: "selscseg\(i)")
            }
        }
        
        var totalWeightedPoints = 0.0
        var totalWeight = 0.0
        var slices: [PieSlice] = []
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemTeal, .systemPink, .systemYellow]
        
        for i in 0..<activeSubjects.count {
            let subj = activeSubjects[i]
            let lvlIdx = subjectViews[i].levelSelect.selectedSegmentIndex
            let scrIdx = subjectViews[i].scoreSelect.selectedSegmentIndex
            
            let map = subj.customScoreToBaseGPAMap ?? commonScoreMap
            let level = subj.levels[lvlIdx]
            
            let base = map[scrIdx].baseGPA
            let offset = level.offset
            let weight = level.weightOverride ?? subj.weight
            
            let subjectGPA = max(0, base - offset)
            let points = subjectGPA * weight
            
            totalWeightedPoints += points
            totalWeight += weight
            
            slices.append(PieSlice(value: points, color: colors[i % colors.count], label: subj.name, subGPA: subjectGPA))
        }
        
        let finalGPA = totalWeight > 0 ? totalWeightedPoints / totalWeight : 0.0
        let gpaDisp = String(format: "%.3f", finalGPA)
        calculationResultDisplayView.text = "Your GPA: \(gpaDisp)"
        
        // add to Pie Chart
        pieChartView.totalGPA = finalGPA
        pieChartView.slices = slices
    }
}
