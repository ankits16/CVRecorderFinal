//
//  ExperimentsMenuViewController.swift
//  CVRecorderSampleApp
//
//  Created by Ankit Sachan on 01/08/22.
//

import UIKit
import KUIPopOver

enum Experiment: CaseIterable{
    case videoPlayer
    case audioTranscript
    
    func getDisplayableName() -> String{
        switch self {
        case .videoPlayer:
            return "Video Player"
        case .audioTranscript:
            return "Audio Transcript"
        }
    }
}


class ExperimentsMenuViewController: UIViewController, KUIPopOverUsable {
    var contentSize: CGSize = CGSize(width: 300, height: 400)
    @IBOutlet private weak var menuTable : UITableView?
    var menuItemSelectedCompletion : ((_ selectedExperiment: Experiment) -> Void)!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOnViewDidLoad()
    }
    
    private func setupOnViewDidLoad(){
        setupMenuTable()
    }
    
    private func setupMenuTable(){
        menuTable?.register(
            UINib(nibName: "MenuTableViewCell", bundle: nil),
            forCellReuseIdentifier: "cell"
        )
        menuTable?.dataSource = self
        menuTable?.delegate = self
        menuTable?.reloadData()
    }
}

extension ExperimentsMenuViewController : UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Experiment.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let menuCell = cell as! MenuTableViewCell
        menuCell.menuItemTitleLbl?.text = Experiment.allCases[indexPath.row].getDisplayableName()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismissPopover(animated: true) {[weak self] in
            self?.menuItemSelectedCompletion(Experiment.allCases[indexPath.row])
        }
    }
}
