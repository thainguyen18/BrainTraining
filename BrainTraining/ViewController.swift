//
//  ViewController.swift
//  BrainTraining
//
//  Created by Thai Nguyen on 1/17/20.
//  Copyright © 2020 Thai Nguyen. All rights reserved.
//

import UIKit
import LBTATools
import Vision

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var drawView: DrawingImageView = {
        let iv = DrawingImageView()
        iv.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        iv.isUserInteractionEnabled = true
        
        iv.delegate = self
        
        return iv
    }()
    
    
    lazy var tableView: UITableView = {
       let tv = UITableView()
        
        tv.allowsSelection = false
        
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tv.delegate = self
        tv.dataSource = self
        
        return tv
    }()
    
    var questions = [Question]()
    
    var score = 0
    
    var digitsModel = Digits()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        title = "BrainTraining"
        tableView.layer.borderColor = UIColor.lightGray.cgColor
        tableView.layer.borderWidth = 1
        
        askQuestion()
        
        setupViews()
    }
    
    
    private func setupViews() {
        view.addSubview(drawView)
        
        drawView.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 16, bottom: 16, right: 16))
        
        drawView.widthAnchor.constraint(equalTo: drawView.heightAnchor, multiplier: 1.0 / 1.0).isActive = true
        
        
        view.addSubview(tableView)
        
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: drawView.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 16, left: 16, bottom: 16, right: 16))
    }
    
    
    func numberDrawn(_ image: UIImage) {
        // start by defining our target size
        let modelSize = 299
        
        // render our input image at this new size
        UIGraphicsBeginImageContextWithOptions(CGSize(width: modelSize, height: modelSize), true, 1.0)
        
        image.draw(in: CGRect(x: 0, y: 0, width: modelSize, height: modelSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        // attempt to pull out a CIImage for Vision; this should always succeed
        guard let ciImage = CIImage(image: newImage) else { fatalError("Failed to convert UIImage to CIImage.") }
        // attempt to convert our Core ML model into a Vision Core ML model; again, this should always succeed
        
        guard let model = try? VNCoreMLModel(for: digitsModel.model) else { fatalError("Failed to prepare model for Vision.") }
        
        // create a request with a closure that will run
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            // typecast Vision's results to be a series of observations and find the first one
            guard let results = request.results as? [VNClassificationObservation],
                let prediction = results.first else { fatalError("Failed to make a prediction: \(error?.localizedDescription ?? "Unknown error").") }
            // push our work back to the main thread so we can manipulate the UI
            DispatchQueue.main.async {
                // convert the predicted digit into an integer, or default to 0 if something went wrong
                
                let result = Int(prediction.identifier) ?? 0 // assign this answer to the current question
                
                self?.questions[0].actual = result
                // if they were correct, add to their score
                if self?.questions[0].correct == result {
                    self?.score += 1
                }
                // call askQuestion() again
                self?.askQuestion()
                
            }
        }
        
            // now that we know what work to do when a prediction is made, send our CIImage into Vision
            let handler = VNImageRequestHandler(ciImage: ciImage)
            
            // run the prediction on a background thread so the UI doesn't freeze
            DispatchQueue.global(qos: .userInteractive).async { do {
                // run our single request
                try handler.perform([request]) } catch {
                    print(error.localizedDescription) }
            }
        }
    
    
    func setText(for cell: UITableViewCell, at indexPath: IndexPath, to question: Question) {
        if indexPath.row == 0 {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 48)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        }
        
        if let actual = question.actual {
            cell.textLabel?.text = "\(question.text) = \(actual)"
        } else {
            cell.textLabel?.text = "\(question.text) = ?"
        }
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let currentQuestion = questions[indexPath.row]
        
        setText(for: cell, at: indexPath, to: currentQuestion)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    
    func createQuestion() -> Question { var question = ""
        var correctAnswer = 0
        while true {
            let firstNumber = Int.random(in: 0...9)
            let secondNumber = Int.random(in: 0...9)
            
            if Bool.random() == true {
                let result = firstNumber + secondNumber
                if result < 10 {
                    question = "\(firstNumber) + \(secondNumber)"
                    correctAnswer = result
                    break
                }
            } else {
                let result = firstNumber - secondNumber
                if result >= 0 {
                    question = "\(firstNumber) - \(secondNumber)"
                    correctAnswer = result
                    break
                } }
        }
        return Question(text: question, correct: correctAnswer, actual: nil)
    }
    
    
    func askQuestion() {
        
        if questions.count == 20 {
            let ac = UIAlertController(title: "Game over!", message: "You scored \(score)/20", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Play Again", style: .default, handler: restartGame))
            present(ac, animated: true)
            
            return
        }
        
        // clear any previous image
        drawView.image = nil
        
        // create a question and insert it into our array so that it appears at the top of the table
        questions.insert(createQuestion(), at: 0)
        
        let newIndexPath = IndexPath(row: 0, section: 0)
        
        tableView.insertRows(at: [newIndexPath], with: .right)
        
        // try to find the second cell in our table; this was the
        //top cell a moment ago, and needs to be changed
        
        let secondIndexPath = IndexPath(row: 1, section: 0)
        
        if let cell = tableView.cellForRow(at: secondIndexPath) {
            // update this cell so that it shows the user's answer in the correct font
            setText(for: cell, at: secondIndexPath, to: questions[1])
        }
    }
    
    
    func restartGame(action: UIAlertAction) {
        score = 0
        questions.removeAll()
        tableView.reloadData()
        askQuestion()
    }
}

