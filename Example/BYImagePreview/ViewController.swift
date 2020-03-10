//
//  ViewController.swift
//  BYImagePreview
//
//  Created by mg459046365 on 03/10/2020.
//  Copyright (c) 2020 mg459046365. All rights reserved.
//

import Kingfisher
import UIKit
import BYImagePreview

class ViewController: UIViewController {
    private let link1 = "http://image.wufazhuce.com/FkH8u-UX4C0b7Y8rtmxM6FeOA6Y5"
    private let link2 = "http://image.wufazhuce.com/FnKcs9db0ZDt9X9HotWQ-RDNtWSu"
    private let link3 = "http://image.wufazhuce.com/Fg4tEFwFfutZW2Dm-Sd7Oswg_JUz"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "测试demo"
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(rootScrollView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @objc private func singleTap1() {
        let vc = BYImagePreviewView()
        vc.supportSaveImage = true
        vc.showIndexLabel = true
        vc.delegate = self
        vc.defaultDisplayIndex = 0
        vc.show(in: self, fromView: imageView1)
    }

    @objc private func singleTap2() {
        let vc = BYImagePreviewView()
        vc.delegate = self
        vc.defaultDisplayIndex = 1
        vc.show(in: self, fromView: imageView2)
    }

    @objc private func singleTap3() {
        let vc = BYImagePreviewView()
        vc.delegate = self
        vc.defaultDisplayIndex = 2
        vc.show(in: self, fromView: imageView3)
    }

    // MARK: - View

    private lazy var rootScrollView: UIScrollView = {
        let rs = UIScrollView(frame: view.bounds)
        if #available(iOS 11.0, *) {
            rs.contentInsetAdjustmentBehavior = .never
        }
        rs.addSubview(imageView1)
        rs.addSubview(imageView2)
        rs.addSubview(imageView3)
        rs.contentSize = CGSize(width: view.bounds.width, height: imageView3.frame.maxY + 20)
        return rs
    }()

    private lazy var imageView1: UIImageView = {
        let im = UIImageView(frame: CGRect(x: 18, y: UIApplication.shared.statusBarFrame.height + 44 + 10, width: view.bounds.width - 36, height: (view.bounds.width - 36) * 2 / 3))
        im.contentMode = .scaleToFill
        im.kf.setImage(with: URL(string: link1)!)

        im.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(singleTap1))
        im.addGestureRecognizer(tap)
        return im
    }()

    private lazy var imageView2: UIImageView = {
        let im = UIImageView(frame: CGRect(x: 18, y: imageView1.frame.maxY + 20, width: view.bounds.width - 36, height: (view.bounds.width - 36) * 2 / 3))
        im.contentMode = .scaleToFill
        im.kf.setImage(with: URL(string: link2)!)

        im.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(singleTap2))
        im.addGestureRecognizer(tap)
        return im
    }()

    private lazy var imageView3: UIImageView = {
        let im = UIImageView(frame: CGRect(x: 18, y: imageView2.frame.maxY + 20, width: view.bounds.width - 36, height: (view.bounds.width - 36) * 2 / 3))
        im.contentMode = .scaleToFill
        im.kf.setImage(with: URL(string: link3)!)

        im.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(singleTap3))
        im.addGestureRecognizer(tap)
        return im
    }()
}

extension ViewController: BYImagePreviewDelegate {
    func by_numberOfImages(in preview: BYImagePreviewView) -> Int {
        3
    }

    func by_imagePreview(_ preview: BYImagePreviewView, imageSourceAt index: Int) -> BYImagePreviewSource {
        if index == 0 {
            return .link(link1)
        } else if index == 1 {
            return .link(link2)
        } else if index == 2 {
            return .link(link3)
        }
        return .none
    }

    func by_imagePreview(_ preview: BYImagePreviewView, dismissWithMoveToPositionViewAt index: Int) -> UIView? {
        if index == 0 {
            return imageView1
        } else if index == 1 {
            return imageView2
        } else if index == 2 {
            return imageView3
        }
        return nil
    }
}

