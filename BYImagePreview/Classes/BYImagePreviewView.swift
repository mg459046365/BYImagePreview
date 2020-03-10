//
//  BYImagePreviewView.swift
//  BYImagePreview
//
//  Created by Beryter on 2020/3/10.
//

import Kingfisher
import UIKit

public enum BYImagePreviewSource {
    /// 图片链接String类型
    case link(String)
    /// 图片链接URL类型
    case url(URL)
    /// 图片UIImage类型
    case image(UIImage)
    /// 不存在图片资源
    case none
}

public protocol BYImagePreviewDelegate {
    /// 图片的个数
    /// - Parameter preview: 预览视图
    func by_numberOfImages(in preview: BYImagePreviewView) -> Int

    /// 返回该索引处的图片源，目前支持图片链接(String)，图片(UIImage)，以及图片链接URL类型(URL)
    /// - Parameters:
    ///   - preview: 预览视图
    ///   - index: 图片的索引
    func by_imagePreview(_ preview: BYImagePreviewView, imageSourceAt index: Int) -> BYImagePreviewSource

    /// 该处图片的占位图
    /// - Parameters:
    ///   - preview: 预览视图
    ///   - index: 图片的索引
    func by_imagePreview(_ preview: BYImagePreviewView, placeholderImageAt index: Int) -> UIImage?

    /// 在该索引下关闭预览视图，预览视图将调整frame并移动到目标视图处关闭，该方法返回目标视图。
    /// 如果不实现或者返回空，则预览视图直接关闭
    /// - Parameters:
    ///   - preview: 预览视图
    ///   - index: 图片的索引
    func by_imagePreview(_ preview: BYImagePreviewView, dismissWithMoveToPositionViewAt index: Int) -> UIView?

    /// 点击保存图片时，返回需要保存的图片。
    /// - Parameters:
    ///   - preview: 预览视图
    ///   - index: 索引
    ///   - image: 该索引下的图片，有可能为空，比如图片还未下载完成或者下载失败
    func by_imagePreview(_ preview: BYImagePreviewView, saveImageAt index: Int, withImage image: UIImage?)

    /// 预览视图消失
    /// - Parameter preview: 预览视图
    func by_imagePreviewDidDismiss(_ preview: BYImagePreviewView)
}

public extension BYImagePreviewDelegate {
    func by_imagePreview(_ preview: BYImagePreviewView, placeholderImageAt index: Int) -> UIImage? {
        nil
    }

    func by_imagePreview(_ preview: BYImagePreviewView, dismissWithMoveToPositionViewAt index: Int) -> UIView? {
        nil
    }

    func by_imagePreview(_ preview: BYImagePreviewView, saveImageAt index: Int, withImage image: UIImage?) {}
}

public class BYImagePreviewView: UIViewController {
    private let animationDuration = 0.3
    /// 当前展示图片的索引
    private var curDisplayIndex = 0
    /// 是否显示索引
    public var showIndexLabel = false
    /// 是否支持保存图片
    public var supportSaveImage = false
    /// 代理
    public var delegate: BYImagePreviewDelegate?
    /// 默认展示图片的索引
    public var defaultDisplayIndex = 0

    private var animationsEnabled = false

    /// 拖动手势消失时的过渡视图
    private var transitionView: UIImageView?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.setAnimationsEnabled(true)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIView.setAnimationsEnabled(animationsEnabled)
    }
    deinit {
//        print("预览视图释放！")
    }

    private func setupView() {
        view.backgroundColor = .black
        view.isUserInteractionEnabled = true
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(collectionView)
        view.addSubview(countLabel)
        view.addSubview(tipLabel)
        view.addSubview(saveButton)
        countLabel.isHidden = !showIndexLabel
        saveButton.isHidden = !supportSaveImage

        let pan = UIPanGestureRecognizer(target: self, action: #selector(dismissWithPanGesture(_:)))
        view.addGestureRecognizer(pan)
        animationsEnabled = UIView.areAnimationsEnabled
    }

    @objc private func dismissWithPanGesture(_ gesture: UIPanGestureRecognizer) {
        let cl = collectionView.cellForItem(at: IndexPath(item: curDisplayIndex, section: 0)) as! BYImagePreviewCell
        guard let im = cl.image else { return }
        if cl.scale > 1 { return }
        // 当前手指点击的点
        let translatedPoint = gesture.translation(in: view)
        gesture.setTranslation(.zero, in: view)
        // 将cell中图片的frame转换成当前根视图坐标体系中的frame,作为过渡视图的起始frame
        var originalFrame = cl.imageView.superview!.convert(cl.imageView.frame, to: view)
        // 过渡视图消失时的frame
        var destinationFrame = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: 10, height: 10)
        // 移动距离参数
        var y_delta: CGFloat = 0
        if let vm = transitionView {
            // 移动距离和主视图高度的比
            y_delta = abs(vm.frame.minY - originalFrame.minY) / view.bounds.height
        }

        if gesture.state == .began {
            transitionView = UIImageView(frame: originalFrame)
            transitionView?.image = im
            view.addSubview(transitionView!)
            collectionView.isHidden = true
            countLabel.isHidden = true
            saveButton.isHidden = true
        } else if gesture.state == .ended || gesture.state == .failed {
            // 手势结束
            // 满足视图移除的条件后, 缩小视图, 并逐渐移除
            if y_delta > 0.2 {
                if let dismissToView = delegate?.by_imagePreview(self, dismissWithMoveToPositionViewAt: curDisplayIndex), let disSuper = dismissToView.superview {
                    destinationFrame = disSuper.convert(dismissToView.frame, to: view)
                }
                UIView.animate(withDuration: animationDuration, animations: {
                    self.transitionView?.frame = destinationFrame
                    self.view.backgroundColor = UIColor(white: 0, alpha: 0)
                }) { _ in
                    self.transitionView?.removeFromSuperview()
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                    self.delegate?.by_imagePreviewDidDismiss(self)
                }
                return
            }
            // 失败后还原
            originalFrame = cl.imageView.superview!.convert(cl.imageView.frame, to: view)
            UIView.animate(withDuration: animationDuration, animations: {
                self.transitionView?.frame = originalFrame
                self.view.backgroundColor = UIColor(white: 0, alpha: 1)
            }) { _ in
                self.transitionView?.removeFromSuperview()
                self.collectionView.isHidden = false
                self.countLabel.isHidden = !self.showIndexLabel
                self.saveButton.isHidden = !self.supportSaveImage
            }
            return
        }
        view.backgroundColor = UIColor(white: 0, alpha: 1 - y_delta)
        guard let imv = transitionView else { return }
        let hwrate = originalFrame.height / originalFrame.width
        let h = originalFrame.height - (originalFrame.height - destinationFrame.height) * y_delta
        let w = h / hwrate
        let tmpFrame = imv.frame
        originalFrame = imv.frame
        originalFrame.size = CGSize(width: w, height: h)
        imv.frame = originalFrame
        let x = tmpFrame.midX + translatedPoint.x
        let y = tmpFrame.midY + translatedPoint.y
        imv.center = CGPoint(x: x, y: y)
    }

    public func show(in controller: UIViewController, fromView: UIImageView) {
        view.bounds = UIScreen.main.bounds
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        collectionView.isHidden = true

        UIApplication.shared.keyWindow?.addSubview(view)
        collectionView.frame = view.bounds
        controller.addChild(self)

        // 默认展示第几个cell
        collectionView.reloadData()
        if defaultDisplayIndex > 0, defaultDisplayIndex < (delegate?.by_numberOfImages(in: self) ?? 0) {
            collectionView.setContentOffset(CGPoint(x: view.bounds.width * CGFloat(defaultDisplayIndex), y: 0), animated: false)
            curDisplayIndex = defaultDisplayIndex
        }

        // 图片起始位置
        let originalFrame = fromView.superview!.convert(fromView.frame, to: view)
        // 过渡视图
        let transitionView = UIImageView(frame: originalFrame)
        transitionView.image = fromView.image
        view.addSubview(transitionView)

        // 过渡视图最终移动到的目标位置, 默认直接将转换后的视图移动到中心位置
        var destinationFrame = originalFrame
        destinationFrame.origin.x = (view.bounds.width - destinationFrame.width) / 2
        destinationFrame.origin.y = (view.bounds.height - destinationFrame.height) / 2
        if let im = fromView.image {
            // 如果存在图片，根据图片计算最终位置的的frame
            destinationFrame = calculateDestinationFrame(withImageSize: im.size)
        }
        UIView.animate(withDuration: animationDuration, animations: {
            transitionView.frame = destinationFrame
            self.view.backgroundColor = UIColor(white: 0, alpha: 1)
        }) { _ in
            self.collectionView.isHidden = false
            transitionView.removeFromSuperview()
        }
    }

    private func dismiss() {
        let cl = collectionView.cellForItem(at: IndexPath(item: curDisplayIndex, section: 0)) as! BYImagePreviewCell
        guard let im = cl.image, let dismissToView = delegate?.by_imagePreview(self, dismissWithMoveToPositionViewAt: curDisplayIndex) else {
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.alpha = 0
            }) { _ in
                self.view.removeFromSuperview()
                self.removeFromParent()
                self.delegate?.by_imagePreviewDidDismiss(self)
            }
            return
        }
        // 将cell中图片的位置转换到当前controller跟视图的坐标系中，获取过渡图片的起始位置
        let originalFrame = cl.imageView.superview!.convert(cl.imageView.frame, to: view)
        // 图片将要移动到的最终位置
        let destinationFrame = dismissToView.superview!.convert(dismissToView.frame, to: view)
        // 过渡视图
        let transitionView = UIImageView(frame: originalFrame)
        transitionView.image = im
        view.addSubview(transitionView)
        collectionView.isHidden = true
        countLabel.isHidden = true
        saveButton.isHidden = true

        UIView.animate(withDuration: animationDuration, animations: {
            transitionView.frame = destinationFrame
            self.view.backgroundColor = UIColor(white: 0, alpha: 0)
        }) { _ in
            transitionView.removeFromSuperview()
            self.view.removeFromSuperview()
            self.removeFromParent()
            self.delegate?.by_imagePreviewDidDismiss(self)
        }
    }

    private func calculateDestinationFrame(withImageSize size: CGSize) -> CGRect {
        // 一开始进入无法拿到colleoionCell中的图片大小，所以重新计算
        var imh: CGFloat = 0
        let vw = view.bounds.width
        let vh = view.bounds.height
        if (size.height / size.width) > (vh / vw) {
            // 长图片
            imh = floor(size.height * vw / size.width)
        } else {
            imh = size.height * vw / size.width
            if imh < 1 { imh = vh }
            imh = floor(imh)
        }
        if imh > vh, imh - vh <= 1 {
            imh = vh
        }
        return CGRect(x: 0, y: (vh - imh) / 2, width: vw, height: imh)
    }

    /// 保存图片
    private func saveImage() {
        let cl = collectionView.cellForItem(at: IndexPath(item: curDisplayIndex, section: 0)) as! BYImagePreviewCell
        delegate?.by_imagePreview(self, saveImageAt: curDisplayIndex, withImage: cl.image)
    }

    @objc private func didClickedSaveButton(_ sender: UIButton) {
        saveImage()
    }

    // MARK: - 视图

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = view.frame.size
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cl = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        cl.backgroundColor = .clear
        cl.dataSource = self
        cl.delegate = self
        cl.isPagingEnabled = true
        cl.scrollsToTop = false
        cl.register(BYImagePreviewCell.self, forCellWithReuseIdentifier: String(describing: BYImagePreviewCell.self))
        cl.showsVerticalScrollIndicator = false
        cl.contentOffset = .zero
        cl.contentSize = cl.bounds.size
        if #available(iOS 11.0, *) {
            cl.contentInsetAdjustmentBehavior = .never
        }
        return cl
    }()

    private lazy var tipLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 10, y: UIApplication.shared.statusBarFrame.height + 20, width: 100, height: 25))
        lb.center = CGPoint(x: view.bounds.width / 2, y: lb.center.y)
        lb.font = UIFont.systemFont(ofSize: 18)
        lb.textAlignment = .center
        lb.textColor = .white
        lb.alpha = 0
        lb.layer.backgroundColor = UIColor(white: 0, alpha: 0.35).cgColor
        lb.layer.cornerRadius = lb.bounds.height / 2
        return lb
    }()

    private lazy var countLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 10, y: UIApplication.shared.statusBarFrame.height + 20, width: 100, height: 25))
        lb.center = CGPoint(x: view.bounds.width / 2, y: lb.center.y)
        lb.font = UIFont.systemFont(ofSize: 18)
        lb.textAlignment = .center
        lb.textColor = .white
        lb.text = "\(self.curDisplayIndex + 1)/\(delegate?.by_numberOfImages(in: self) ?? 0)"
        lb.layer.backgroundColor = UIColor(white: 0, alpha: 0.35).cgColor
        lb.layer.cornerRadius = lb.bounds.height / 2
        return lb
    }()

    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "save"), for: .normal)
        btn.sizeToFit()
        var fm = btn.frame
        fm.origin.x = 25
        fm.origin.y = view.bounds.height - 30 - fm.height
        fm.size.width = fm.width + 10
        fm.size.height = fm.height + 15
        btn.frame = fm
        btn.layer.cornerRadius = 3
        btn.layer.masksToBounds = true
        btn.backgroundColor = UIColor(white: 0, alpha: 0.35)
        btn.addTarget(self, action: #selector(didClickedSaveButton(_:)), for: .touchUpInside)
        return btn
    }()
}

extension BYImagePreviewView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        max(delegate?.by_numberOfImages(in: self) ?? 0, 0)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BYImagePreviewCell.self), for: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let dl = delegate else { return }
        let cl = cell as! BYImagePreviewCell
        let placeholderImage = dl.by_imagePreview(self, placeholderImageAt: indexPath.item)
        let source = dl.by_imagePreview(self, imageSourceAt: indexPath.item)
        cl.setImageSouce(source: source, withPlaceholderImage: placeholderImage)
        cl.singeTapHandler = { [weak self] in
            guard let self = self else { return }
            self.dismiss()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cl = cell as! BYImagePreviewCell
        cl.resetZoom()
    }
}

extension BYImagePreviewView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let idx = offsetX / scrollView.frame.width
        curDisplayIndex = Int(idx)
        countLabel.text = "\(curDisplayIndex)/\(delegate?.by_numberOfImages(in: self) ?? 0)"
    }
}

class BYImagePreviewCell: UICollectionViewCell {
    /// 点击图片
    var singeTapHandler: (() -> Void)?
    /// 图片
    private(set) var image: UIImage?
    var scale: CGFloat {
        scrollView.zoomScale
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .clear
        contentView.addSubview(scrollView)
        contentView.addSubview(loadingView)

        // 单击
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        contentView.addGestureRecognizer(singleTap)

        // 双击
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        contentView.addGestureRecognizer(doubleTap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resizeSubviews()
    }

    @objc private func singleTap(_ gesture: UITapGestureRecognizer) {
        guard let bl = singeTapHandler else { return }
        bl()
    }

    @objc private func doubleTap(gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            // 还原
            scrollView.setZoomScale(1, animated: true)
            return
        }
        // 放大
        let touchPoint = gesture.location(in: imageView)
        let zoomScale = scrollView.maximumZoomScale
        let dW = frame.width / zoomScale
        let dH = frame.height / zoomScale
        scrollView.zoom(to: CGRect(x: touchPoint.x - dW / 2, y: touchPoint.y - dH / 2, width: dW, height: dH), animated: true)
    }

    func resetZoom(animated: Bool = false) {
        scrollView.setZoomScale(1, animated: animated)
    }

    private func resizeSubviews() {
        guard let image = imageView.image else { return }
        guard image.size.width > 0, image.size.height > 0 else { return }
        let vw = bounds.width
        let vh = bounds.height
        var imvFrame = imageView.frame
        if (image.size.height / image.size.width) > (vh / vw) {
            // 长图片
            let desH = floor(image.size.height * vw / image.size.width)
            imvFrame.size.height = desH
        } else {
            var desH = image.size.height * vw / image.size.width
            if desH < 1 { desH = vh }
            desH = floor(desH)
            imvFrame.size.height = desH
            imvFrame.origin.y = (vh - desH) / 2
        }
        if imageView.frame.height > vh, imageView.frame.height - vh <= 1 {
            imvFrame.size.height = vh
            imvFrame.origin.y = 0
        }
        imageView.frame = imvFrame
        scrollView.contentSize = CGSize(width: vw, height: max(imageView.frame.height, vh))
        scrollView.scrollRectToVisible(bounds, animated: false)
        scrollView.alwaysBounceVertical = (vh > imageView.bounds.height) ? false : true
    }

    func setImageSouce(source: BYImagePreviewSource, withPlaceholderImage placeholderImage: UIImage?) {
        switch source {
        case let .image(im):
            imageView.image = im
            image = im
            resizeSubviews()
            resetZoom()
        case let .link(link):
            if let url = URL(string: link) {
                loadingView.startAnimating()
                imageView.kf.setImage(with: url, placeholder: placeholderImage, options: nil, progressBlock: nil) { [weak self] in
                    guard let self = self else { return }
                    switch $0 {
                    case let .success(im):
                        self.image = im.image
                    case .failure:
                        break
                    }
                    if let _ = self.imageView.image { self.resizeSubviews() }
                    self.loadingView.stopAnimating()
                }
            } else {
                imageView.image = placeholderImage
                if let _ = placeholderImage { resizeSubviews() }
            }
            resetZoom()
        case let .url(url):
            loadingView.startAnimating()
            imageView.kf.setImage(with: url, placeholder: placeholderImage, options: nil, progressBlock: nil) { [weak self] in
                guard let self = self else { return }
                switch $0 {
                case let .success(im):
                    self.image = im.image
                case .failure:
                    break
                }
                if let _ = self.imageView.image { self.resizeSubviews() }
                self.loadingView.stopAnimating()
            }
            resetZoom()
        case .none:
            imageView.image = placeholderImage
            if let _ = imageView.image { resizeSubviews() }
            resetZoom()
        }
    }

    // MARK: - 视图

    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView(frame: bounds)
        v.maximumZoomScale = 2.5
        v.minimumZoomScale = 1
        v.delegate = self
        v.bouncesZoom = true
        v.isMultipleTouchEnabled = true
        v.scrollsToTop = false
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.delaysContentTouches = false
        v.canCancelContentTouches = true
        v.isDirectionalLockEnabled = true
        v.alwaysBounceHorizontal = true
        v.alwaysBounceVertical = false
        if #available(iOS 11.0, *) {
            v.contentInsetAdjustmentBehavior = .never
        }
        v.addSubview(imageView)
        return v
    }()

    private lazy var sourceView: UIView = {
        let v = UIView(frame: bounds)
        v.clipsToBounds = true
        return v
    }()

    private lazy var loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .whiteLarge)
        v.hidesWhenStopped = true
        v.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        return v
    }()

    lazy var imageView: UIImageView = {
        let v = UIImageView(frame: bounds)
        v.backgroundColor = .black
        v.clipsToBounds = true
        return v
    }()
}

extension BYImagePreviewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
}
