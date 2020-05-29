import NVActivityIndicatorView

final class PathVC : BaseVC {

    // MARK: Components
    private lazy var pathStackView: UIStackView = {
        let result = UIStackView()
        result.axis = .vertical
        return result
    }()

    private lazy var spinner: NVActivityIndicatorView = {
        let result = NVActivityIndicatorView(frame: CGRect.zero, type: .circleStrokeSpin, color: Colors.text, padding: nil)
        result.set(.width, to: 64)
        result.set(.height, to: 64)
        return result
    }()

    private lazy var rebuildPathButton: Button = {
        let result = Button(style: .prominentOutline, size: .large)
        result.setTitle(NSLocalizedString("Rebuild Path", comment: ""), for: UIControl.State.normal)
        result.addTarget(self, action: #selector(rebuildPath), for: UIControl.Event.touchUpInside)
        return result
    }()

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBackground()
        setUpNavBar()
        setUpViewHierarchy()
        registerObservers()
    }

    private func setUpBackground() {
        view.backgroundColor = .clear
        let gradient = Gradients.defaultLokiBackground
        view.setGradient(gradient)
    }

    private func setUpNavBar() {
        // Set up navigation bar style
        let navigationBar = navigationController!.navigationBar
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = Colors.navigationBarBackground
        // Set up close button
        let closeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "X"), style: .plain, target: self, action: #selector(close))
        closeButton.tintColor = Colors.text
        navigationItem.leftBarButtonItem = closeButton
        let learnMoreButton = UIBarButtonItem(image: #imageLiteral(resourceName: "QuestionMark").scaled(to: CGSize(width: 24, height: 24)), style: .plain, target: self, action: #selector(learnMore))
        learnMoreButton.tintColor = Colors.text
        navigationItem.rightBarButtonItem = learnMoreButton
        // Customize title
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("Path", comment: "")
        titleLabel.textColor = Colors.text
        titleLabel.font = .boldSystemFont(ofSize: Values.veryLargeFontSize)
        navigationItem.titleView = titleLabel
    }

    private func setUpViewHierarchy() {
        // Set up explanation label
        let explanationLabel = UILabel()
        explanationLabel.textColor = Colors.text.withAlphaComponent(Values.unimportantElementOpacity)
        explanationLabel.font = .systemFont(ofSize: Values.smallFontSize)
        explanationLabel.text = NSLocalizedString("Session hides your IP by bouncing your messages through several Service Nodes in Session’s decentralized network. These are the Service Nodes currently being used by your device:", comment: "")
        explanationLabel.numberOfLines = 0
        explanationLabel.textAlignment = .center
        explanationLabel.lineBreakMode = .byWordWrapping
        // Set up path stack view
        let pathStackViewContainer = UIView()
        pathStackViewContainer.addSubview(pathStackView)
        pathStackView.pin([ UIView.VerticalEdge.top, UIView.VerticalEdge.bottom ], to: pathStackViewContainer)
        pathStackView.center(in: pathStackViewContainer)
        pathStackView.leadingAnchor.constraint(greaterThanOrEqualTo: pathStackViewContainer.leadingAnchor).isActive = true
        pathStackViewContainer.trailingAnchor.constraint(greaterThanOrEqualTo: pathStackView.trailingAnchor).isActive = true
        pathStackViewContainer.addSubview(spinner)
        spinner.leadingAnchor.constraint(greaterThanOrEqualTo: pathStackViewContainer.leadingAnchor).isActive = true
        spinner.topAnchor.constraint(greaterThanOrEqualTo: pathStackViewContainer.topAnchor).isActive = true
        pathStackViewContainer.trailingAnchor.constraint(greaterThanOrEqualTo: spinner.trailingAnchor).isActive = true
        pathStackViewContainer.bottomAnchor.constraint(greaterThanOrEqualTo: spinner.bottomAnchor).isActive = true
        spinner.center(in: pathStackViewContainer)
        // Set up rebuild path button
        let rebuildPathButtonContainer = UIView()
        rebuildPathButtonContainer.addSubview(rebuildPathButton)
        rebuildPathButton.pin(.leading, to: .leading, of: rebuildPathButtonContainer, withInset: 80)
        rebuildPathButton.pin(.top, to: .top, of: rebuildPathButtonContainer)
        rebuildPathButtonContainer.pin(.trailing, to: .trailing, of: rebuildPathButton, withInset: 80)
        rebuildPathButtonContainer.pin(.bottom, to: .bottom, of: rebuildPathButton)
        // Set up spacers
        let topSpacer = UIView.vStretchingSpacer()
        let bottomSpacer = UIView.vStretchingSpacer()
        // Set up main stack view
        let mainStackView = UIStackView(arrangedSubviews: [ explanationLabel, topSpacer, pathStackViewContainer, bottomSpacer, rebuildPathButtonContainer ])
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.layoutMargins = UIEdgeInsets(top: Values.largeSpacing, left: Values.largeSpacing, bottom: Values.largeSpacing, right: Values.largeSpacing)
        mainStackView.isLayoutMarginsRelativeArrangement = true
        view.addSubview(mainStackView)
        mainStackView.pin(to: view)
        // Set up spacer constraints
        topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor).isActive = true
        // Perform initial update
        update()
    }

    private func registerObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleBuildingPathsNotification), name: .buildingPaths, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handlePathsBuiltNotification), name: .pathsBuilt, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Updating
    @objc private func handleBuildingPathsNotification() { update() }
    @objc private func handlePathsBuiltNotification() { update() }

    private func update() {
        pathStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if OnionRequestAPI.paths.count >= OnionRequestAPI.pathCount {
            let pathToDisplay = OnionRequestAPI.paths.first!
            let dotAnimationRepeatInterval = Double(pathToDisplay.count) + 2
            let snodeRows: [UIStackView] = pathToDisplay.enumerated().map { index, snode in
                let isGuardSnode = (snode == pathToDisplay.first!)
                return getPathRow(snode: snode, location: .middle, dotAnimationStartDelay: Double(index) + 2, dotAnimationRepeatInterval: dotAnimationRepeatInterval, isGuardSnode: isGuardSnode)
            }
            let youRow = getPathRow(title: NSLocalizedString("You", comment: ""), subtitle: nil, location: .top, dotAnimationStartDelay: 1, dotAnimationRepeatInterval: dotAnimationRepeatInterval)
            let destinationRow = getPathRow(title: NSLocalizedString("Destination", comment: ""), subtitle: nil, location: .bottom, dotAnimationStartDelay: Double(pathToDisplay.count) + 2, dotAnimationRepeatInterval: dotAnimationRepeatInterval)
            let rows = [ youRow ] + snodeRows + [ destinationRow ]
            rows.forEach { pathStackView.addArrangedSubview($0) }
            spinner.stopAnimating()
            UIView.animate(withDuration: 0.25) {
                self.spinner.alpha = 0
                self.rebuildPathButton.layer.borderColor = Colors.accent.cgColor
                self.rebuildPathButton.setTitleColor(Colors.accent, for: UIControl.State.normal)
            }
            rebuildPathButton.isEnabled = true
        } else {
            spinner.startAnimating()
            UIView.animate(withDuration: 0.25) {
                self.spinner.alpha = 1
                self.rebuildPathButton.layer.borderColor = Colors.text.withAlphaComponent(Values.unimportantElementOpacity).cgColor
                self.rebuildPathButton.setTitleColor(Colors.text.withAlphaComponent(Values.unimportantElementOpacity), for: UIControl.State.normal)
            }
            rebuildPathButton.isEnabled = false
        }
    }

    // MARK: General
    private func getPathRow(title: String, subtitle: String?, location: LineView.Location, dotAnimationStartDelay: Double, dotAnimationRepeatInterval: Double) -> UIStackView {
        let lineView = LineView(location: location, dotAnimationStartDelay: dotAnimationStartDelay, dotAnimationRepeatInterval: dotAnimationRepeatInterval)
        lineView.set(.width, to: Values.pathRowDotSize)
        lineView.set(.height, to: Values.pathRowHeight)
        let titleLabel = UILabel()
        titleLabel.textColor = Colors.text
        titleLabel.font = .systemFont(ofSize: Values.mediumFontSize)
        titleLabel.text = title
        titleLabel.lineBreakMode = .byTruncatingTail
        let titleStackView = UIStackView(arrangedSubviews: [ titleLabel ])
        titleStackView.axis = .vertical
        if let subtitle = subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.textColor = Colors.text
            subtitleLabel.font = .systemFont(ofSize: Values.verySmallFontSize)
            subtitleLabel.text = subtitle
            subtitleLabel.lineBreakMode = .byTruncatingTail
            titleStackView.addArrangedSubview(subtitleLabel)
        }
        let stackView = UIStackView(arrangedSubviews: [ lineView, titleStackView ])
        stackView.axis = .horizontal
        stackView.spacing = Values.largeSpacing
        stackView.alignment = .center
        return stackView
    }

    private func getPathRow(snode: LokiAPITarget, location: LineView.Location, dotAnimationStartDelay: Double, dotAnimationRepeatInterval: Double, isGuardSnode: Bool) -> UIStackView {
        var snodeIP = snode.description
        if snodeIP.hasPrefix("https://") { snodeIP.removeFirst(8) }
        if let colonIndex = snodeIP.lastIndex(of: ":") {
            snodeIP = String(snodeIP[snodeIP.startIndex..<colonIndex])
        }
        let title = isGuardSnode ? NSLocalizedString("Guard Node", comment: "") : NSLocalizedString("Service Node", comment: "")
        return getPathRow(title: title, subtitle: snodeIP, location: location, dotAnimationStartDelay: dotAnimationStartDelay, dotAnimationRepeatInterval: dotAnimationRepeatInterval)
    }
    
    // MARK: Interaction
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func learnMore() {
        let urlAsString = "https://getsession.org/faq/#onion-routing"
        let url = URL(string: urlAsString)!
        UIApplication.shared.open(url)
    }

    @objc private func rebuildPath() {
        OnionRequestAPI.guardSnodes = []
        OnionRequestAPI.paths = []
        let _ = OnionRequestAPI.buildPaths()
    }
}

// MARK: Line View
private final class LineView : UIView {
    private let location: Location
    private let dotAnimationStartDelay: Double
    private let dotAnimationRepeatInterval: Double
    private var dotViewWidthConstraint: NSLayoutConstraint!
    private var dotViewHeightConstraint: NSLayoutConstraint!
    private var dotViewAnimationTimer: Timer!

    enum Location {
        case top, middle, bottom
    }

    private lazy var dotView: UIView = {
        let result = UIView()
        result.layer.cornerRadius = Values.pathRowDotSize / 2
        let glowConfiguration = UIView.CircularGlowConfiguration(size: Values.pathRowDotSize, color: Colors.accent, isAnimated: true, radius: isLightMode ? 2 : 4)
        result.setCircularGlow(with: glowConfiguration)
        result.backgroundColor = Colors.accent
        return result
    }()
    
    init(location: Location, dotAnimationStartDelay: Double, dotAnimationRepeatInterval: Double) {
        self.location = location
        self.dotAnimationStartDelay = dotAnimationStartDelay
        self.dotAnimationRepeatInterval = dotAnimationRepeatInterval
        super.init(frame: CGRect.zero)
        setUpViewHierarchy()
    }
    
    override init(frame: CGRect) {
        preconditionFailure("Use init(location:dotAnimationStartDelay:dotAnimationRepeatInterval:) instead.")
    }
    
    required init?(coder: NSCoder) {
        preconditionFailure("Use init(location:dotAnimationStartDelay:dotAnimationRepeatInterval:) instead.")
    }
    
    private func setUpViewHierarchy() {
        let lineView = UIView()
        lineView.set(.width, to: Values.pathRowLineThickness)
        lineView.backgroundColor = Colors.text
        addSubview(lineView)
        lineView.center(.horizontal, in: self)
        switch location {
        case .top: lineView.topAnchor.constraint(equalTo: centerYAnchor).isActive = true
        case .middle, .bottom: lineView.pin(.top, to: .top, of: self)
        }
        switch location {
        case .top, .middle: lineView.pin(.bottom, to: .bottom, of: self)
        case .bottom: lineView.bottomAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
        let dotSize = Values.pathRowDotSize
        dotViewWidthConstraint = dotView.set(.width, to: dotSize)
        dotViewHeightConstraint = dotView.set(.height, to: dotSize)
        addSubview(dotView)
        dotView.center(in: self)
        Timer.scheduledTimer(withTimeInterval: dotAnimationStartDelay, repeats: false) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.animate()
            strongSelf.dotViewAnimationTimer = Timer.scheduledTimer(withTimeInterval: strongSelf.dotAnimationRepeatInterval, repeats: true) { _ in
                guard let strongSelf = self else { return }
                strongSelf.animate()
            }
        }
    }

    deinit {
        dotViewAnimationTimer?.invalidate()
    }

    private func animate() {
        expandDot()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.collapseDot()
        }
    }

    private func expandDot() {
        let newSize = Values.pathRowExpandedDotSize
        let newGlowRadius: CGFloat = isLightMode ? 6 : 8
        updateDotView(size: newSize, glowRadius: newGlowRadius)
    }

    private func collapseDot() {
        let newSize = Values.pathRowDotSize
        let newGlowRadius: CGFloat = isLightMode ? 2 : 4
        updateDotView(size: newSize, glowRadius: newGlowRadius)
    }

    private func updateDotView(size: CGFloat, glowRadius: CGFloat) {
        let frame = CGRect(center: dotView.center, size: CGSize(width: size, height: size))
        dotViewWidthConstraint.constant = size
        dotViewHeightConstraint.constant = size
        UIView.animate(withDuration: 0.5) {
            self.layoutIfNeeded()
            self.dotView.frame = frame
            self.dotView.layer.cornerRadius = size / 2
            let glowColor = Colors.accent
            let glowConfiguration = UIView.CircularGlowConfiguration(size: size, color: glowColor, isAnimated: true, radius: glowRadius)
            self.dotView.setCircularGlow(with: glowConfiguration)
            self.dotView.backgroundColor = Colors.accent
        }
    }
}