
final class ConversationTitleView : UIView {
    private let thread: TSThread
    var delegate: ConversationTitleViewDelegate?

    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }

    // MARK: UI Components
    private lazy var titleLabel: UILabel = {
        let result = UILabel()
        result.textColor = Colors.text
        result.font = .boldSystemFont(ofSize: Values.mediumFontSize)
        result.lineBreakMode = .byTruncatingTail
        return result
    }()

    private lazy var subtitleLabel: UILabel = {
        let result = UILabel()
        result.textColor = Colors.text
        result.font = .systemFont(ofSize: 13)
        result.lineBreakMode = .byTruncatingTail
        return result
    }()

    // MARK: Lifecycle
    init(thread: TSThread) {
        self.thread = thread
        super.init(frame: CGRect.zero)
        initialize()
    }

    override init(frame: CGRect) {
        preconditionFailure("Use init(thread:) instead.")
    }

    required init?(coder: NSCoder) {
        preconditionFailure("Use init(coder:) instead.")
    }

    private func initialize() {
        let stackView = UIStackView(arrangedSubviews: [ titleLabel, subtitleLabel ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        addSubview(stackView)
        stackView.pin(to: self)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGestureRecognizer)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(update), name: Notification.Name.groupThreadUpdated, object: nil)
        notificationCenter.addObserver(self, selector: #selector(update), name: Notification.Name.muteSettingUpdated, object: nil)
        notificationCenter.addObserver(self, selector: #selector(update), name: Notification.Name.contactUpdated, object: nil)
        update()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Updating
    @objc private func update() {
        titleLabel.text = getTitle()
        let subtitle = getSubtitle()
        subtitleLabel.attributedText = subtitle
        let titleFontSize = (subtitle != nil) ? Values.mediumFontSize : Values.veryLargeFontSize
        titleLabel.font = .boldSystemFont(ofSize: titleFontSize)
    }

    // MARK: General
    private func getTitle() -> String {
        if let thread = thread as? TSGroupThread {
            return thread.groupModel.groupName!
        } else if thread.isNoteToSelf() {
            return "Note to Self"
        } else {
            let sessionID = thread.contactIdentifier()!
            var result = sessionID
            Storage.read { transaction in
                result = Storage.shared.getContact(with: sessionID)?.displayName(for: .regular) ?? "Anonymous"
            }
            return result
        }
    }

    private func getSubtitle() -> NSAttributedString? {
        if let muteEndDate = thread.mutedUntilDate, thread.isMuted {
            let result = NSMutableAttributedString()
            result.append(NSAttributedString(string: "\u{e067}  ", attributes: [ .font : UIFont.ows_elegantIconsFont(10), .foregroundColor : Colors.text ]))
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.timeStyle = .medium
            formatter.dateStyle = .medium
            result.append(NSAttributedString(string: "Muted until " + formatter.string(from: muteEndDate)))
            return result
        } else if let thread = self.thread as? TSGroupThread {
            var userCount: Int?
            switch thread.groupModel.groupType {
            case .closedGroup: userCount = thread.groupModel.groupMemberIds.count
            case .openGroup:
                if let openGroup = Storage.shared.getOpenGroup(for: self.thread.uniqueId!) {
                    userCount = Storage.shared.getUserCount(forOpenGroupWithID: openGroup.id)
                }
            default: break
            }
            if let userCount = userCount {
                return NSAttributedString(string: "\(userCount) members")
            }
        }
        return nil
    }
    
    // MARK: Interaction
    @objc private func handleTap() {
        delegate?.handleTitleViewTapped()
    }
}

// MARK: Delegate
protocol ConversationTitleViewDelegate {
    
    func handleTitleViewTapped()
}
