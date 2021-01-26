//
//  CreateTaskViewController.swift
//  DiaryApp
//
//  Created by Пользователь on 23.01.2021.
//

import UIKit
import Network

class CreateTaskViewController: UIViewController {
    
    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addTarget(self, action: #selector(CreateTaskViewController.dateChanged(datePicker: )), for: .valueChanged)
        return datePicker
    }()
    private var datePickerTextField: UITextField!
    private var textFieldTaskName: UITextField!
    private var textFieldTaskDescription: UITextField!
    private var taskImage: UIImageView = {
        let taskImage = UIImageView()
        taskImage.contentMode = .scaleAspectFill
        taskImage.clipsToBounds = true
        return taskImage
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        monitorNetwork()
        initInterfaceObjects()
    }
    
    private func initInterfaceObjects() {
        let centrX = Int(self.view.center.x / 2) - 50
        let centrY = 0
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.saveTask)),
                                              animated: true)
        self.navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelTask)), animated: true)
        self.view.addSubview(createChooseImageButton(centrX: centrX, centrY: centrY))
        self.view.addSubview(taskNameTextField(centrX: centrX, centrY: centrY))
        self.view.addSubview(createDateField())
        self.view.addSubview(taskDescriptionTextField(centrX: centrX, centrY: centrY))
    }
    
    private func createChooseImageButton(centrX: Int, centrY: Int) -> UIButton {
        let saveImageButton: UIButton = UIButton(frame: CGRect(x: centrX, y: centrY + 100, width: 300, height: 50))
        saveImageButton.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        saveImageButton.setTitle("Upload new image", for: .normal)
        saveImageButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        saveImageButton.addTarget(self, action: #selector(self.onTapped), for: .touchUpInside)
        return saveImageButton
    }
    
    private func taskNameTextField(centrX: Int, centrY: Int) -> UITextField {
        textFieldTaskName = UITextField(frame: CGRect(x: centrX, y: centrY + 180, width: 300, height: 50))
        configureTextField(textField: textFieldTaskName, placeholderName: "task name")
        return textFieldTaskName
    }
    
    private func taskDescriptionTextField(centrX: Int, centrY: Int) -> UITextField {
        textFieldTaskDescription = UITextField(frame: CGRect(x: centrX, y: centrY + 340, width: 300, height: 50))
        configureTextField(textField: textFieldTaskDescription, placeholderName: "description")
        return textFieldTaskDescription
    }
    
    private func createDateField() -> UITextField {
        let centrX = Int(self.view.center.x / 2) - 50
        let centrY = 0
        datePickerTextField = UITextField(frame: CGRect(x: centrX, y: centrY + 260, width: 300, height: 50))
        configureTextField(textField: datePickerTextField, placeholderName: "date")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CreateTaskViewController.viewTapped(gestureRecognizer:)))
        self.view.addGestureRecognizer(tapGesture)
        datePickerTextField?.inputView = datePicker
        return datePickerTextField!
    }
    private func configureTextField(textField: UITextField, placeholderName: String) {
        textField.placeholder = "Enter \(placeholderName)"
        textField.font = UIFont.systemFont(ofSize: 20)
        textField.keyboardType = .default
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.textColor = .black
        textField.returnKeyType = UIReturnKeyType.done
        textField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
    }
    
    @objc private func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc private func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        datePickerTextField?.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }
    
    @objc private func onTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        // не проверял работоспособность из за отсутствия реального устройства
        let camera = UIAlertAction(title: "Camera", style: .default) { _ in
            self.chooseImagePicker(source: .camera)
        }
        let photo = UIAlertAction(title: "Photo", style: .default) { _ in
            self.chooseImagePicker(source: .photoLibrary)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(camera)
        actionSheet.addAction(photo)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true)
    }
    
    @objc func saveTask() {
        
        if (textFieldTaskName.text == "" &&
            datePickerTextField.text == "") {
            alertFields()
            return
        }
        
        let task = DataTask(name: textFieldTaskName.text!,
                            date: datePickerTextField.text!,
                            descriptionTask: textFieldTaskDescription.text!,
                            imageData: taskImage.image?.pngData())
        let taskFir = DataTaskFir(name: textFieldTaskName.text!,
                                  date: datePickerTextField.text!,
                                  descriptionTask: textFieldTaskDescription.text)
        //к сожалению не удалось реализовать сохранение image в бд
        //                                  imageData: taskImage.image?.pngData())
        if checkIfExists(date: task.date) {
            StorageManager.saveObjectIntoRealm(task)
            StorageManager.saveObjectIntoFire(taskFir)
            
        }
        dismiss(animated: true)
        print("----------task \(task) saved----------")
    }
    
    private func checkIfExists(date: String) -> Bool {
        let object = realm.objects(DataTask.self).first(where: { $0.date == date })
        return object == nil
    }
    
    @objc private func cancelTask(){
        dismiss(animated: true)
    }
    
    private func monitorNetwork() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    print("internet active")
                }
            } else {
                DispatchQueue.main.async {
                    self.alertConnection()
                    print("internet inactive")
                }
            }
        }
        
        let queue = DispatchQueue(label: "Network")
        monitor.start(queue: queue)
        
        
    }
    
    private func alertConnection() {
        let alert = UIAlertController(title: "internet connection", message: "No internet connection, the task will be saved when connected to the internet", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
    }
    
    private func alertFields() {
        let alert = UIAlertController(title: "", message: "Enter name and date feilds.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true)
        return
    }
    
}

extension CreateTaskViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func chooseImagePicker(source: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(source) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = source
            present(imagePicker, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        taskImage.image = info[.editedImage] as? UIImage
        dismiss(animated: true)
    }
}
