/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Account
import Shared
import SnapKit
import Storage
import Sync
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()


private struct RemoteTabsPanelUX {
    static let HeaderHeight: CGFloat = SiteTableViewControllerUX.RowHeight // Not HeaderHeight!
    static let RowHeight: CGFloat = SiteTableViewControllerUX.RowHeight
    static let HeaderBackgroundColor = UIColor(rgb: 0xf8f8f8)

    static let EmptyStateTopPadding: CGFloat = 20
}

private let RemoteClientIdentifier = "RemoteClient"
private let RemoteTabIdentifier = "RemoteTab"

/**
 * Display a tree hierarchy of remote clients and tabs, like:
 * client
 *   tab
 *   tab
 * client
 *   tab
 *   tab
 * This is not a SiteTableViewController because it is inherently tree-like and not list-like;
 * a technical detail is that STVC is backed by a Cursor and this is backed by a richer data
 * structure.  However, the styling here should agree with STVC where possible.
 */
class RemoteTabsPanel: UITableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!

    private var clientAndTabs: [ClientAndTabs]?

    private func tabAtIndexPath(indexPath: NSIndexPath) -> RemoteTab? {
        return self.clientAndTabs?[indexPath.section].tabs[indexPath.item]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(TwoLineHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: RemoteClientIdentifier)
        tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: RemoteTabIdentifier)
        tableView.rowHeight = RemoteTabsPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "SELrefresh", forControlEvents: UIControlEvents.ValueChanged)

        view.backgroundColor = AppConstants.PanelBackgroundColor
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if profile.getAccount() == nil {
            setupNoAccountOverlayView()
        } else {
            removeNoAccountOverlayView()
            self.SELrefresh()
        }
    }

    var noAccountOverlayView: UIView?

    private func setupNoAccountOverlayView() {
        if noAccountOverlayView == nil {
            tableView.scrollEnabled = false

            let overlayView = UIView(frame: tableView.bounds)
            view.addSubview(overlayView)
            overlayView.backgroundColor = UIColor.whiteColor()
            // Unknown why this does not work with autolayout
            overlayView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth

            let containerView = UIView()
            //containerView.backgroundColor = UIColor.yellowColor()
            overlayView.addSubview(containerView)

            let imageView = UIImageView()
            imageView.image = UIImage(named: "emptySync")
            containerView.addSubview(imageView)
            imageView.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(containerView)
                make.centerX.equalTo(containerView)
            }

            let titleLabel = UILabel()
            titleLabel.font = UIFont.boldSystemFontOfSize(15)
            titleLabel.text = NSLocalizedString("Welcome to Sync", comment: "See http://mzl.la/1Qtkf0j")
            titleLabel.textAlignment = NSTextAlignment.Center
            titleLabel.textColor = UIColor.darkGrayColor()
            containerView.addSubview(titleLabel)
            titleLabel.snp_makeConstraints({ (make) -> Void in
                make.top.equalTo(imageView.snp_bottom).offset(8)
                make.centerX.equalTo(containerView)
            })

            let instructionsLabel = UILabel()
            instructionsLabel.font = UIFont.systemFontOfSize(15)
            instructionsLabel.text = NSLocalizedString("Sign in to sync your tabs, bookmarks, passwords, & more.", comment: "See http://mzl.la/1Qtkf0j")
            instructionsLabel.textAlignment = NSTextAlignment.Center
            instructionsLabel.textColor = UIColor.grayColor()
            instructionsLabel.numberOfLines = 0
            containerView.addSubview(instructionsLabel)
            instructionsLabel.snp_makeConstraints({ (make) -> Void in
                make.top.equalTo(titleLabel.snp_bottom).offset(8)
                make.centerX.equalTo(containerView)
                make.width.equalTo(256)
            })

            let signInButton = UIButton()
            signInButton.backgroundColor = IntroViewControllerUX.SignInButtonColor
            signInButton.setTitle(NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: "See http://mzl.la/1Qtkf0j"), forState: .Normal)
            signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            signInButton.titleLabel?.font = IntroViewControllerUX.SignInButtonFont
            signInButton.layer.cornerRadius = 6
            signInButton.clipsToBounds = true
            signInButton.addTarget(self, action: "SELsignIn", forControlEvents: UIControlEvents.TouchUpInside)
            containerView.addSubview(signInButton)
            signInButton.snp_makeConstraints { (make) -> Void in
                make.centerX.equalTo(containerView)
                make.top.equalTo(instructionsLabel.snp_bottom).offset(8)
                make.height.equalTo(56)
                make.width.equalTo(272)
            }

            let createAnAccountButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            createAnAccountButton.setTitle(NSLocalizedString("Create an account", comment: "See http://mzl.la/1Qtkf0j"), forState: .Normal)
            createAnAccountButton.titleLabel?.font = UIFont.systemFontOfSize(12)
            createAnAccountButton.addTarget(self, action: "SELcreateAnAccount", forControlEvents: UIControlEvents.TouchUpInside)
            containerView.addSubview(createAnAccountButton)
            createAnAccountButton.snp_makeConstraints({ (make) -> Void in
                make.centerX.equalTo(containerView)
                make.top.equalTo(signInButton.snp_bottom).offset(8)
            })

            containerView.snp_makeConstraints({ (make) -> Void in
                // Let the container wrap around the content
                make.top.equalTo(imageView.snp_top)
                make.bottom.equalTo(createAnAccountButton)
                make.left.equalTo(signInButton)
                make.right.equalTo(signInButton)
                // And then center it in the overlay view that sits on top of the UITableView
                make.center.equalTo(overlayView)
            })

            noAccountOverlayView = overlayView
        }
    }

    private func removeNoAccountOverlayView() {
        if let overlayView = noAccountOverlayView {
            tableView.scrollEnabled = true
            overlayView.removeFromSuperview()
            noAccountOverlayView = nil
        }
    }

    @objc private func SELsignIn() {
        homePanelDelegate?.homePanelDidRequestToSignIn(self)
    }

    @objc private func SELcreateAnAccount() {
        homePanelDelegate?.homePanelDidRequestToCreateAccount(self)
    }

    @objc private func SELrefresh() {
        self.refreshControl?.beginRefreshing()

        self.profile.getClientsAndTabs().upon({ tabs in
            if let tabs = tabs.successValue {
                log.info("\(tabs.count) tabs fetched.")
                self.clientAndTabs = tabs.filter { $0.tabs.count > 0 }

                // Maybe show a background view.
                let tableView = self.tableView
                if let clientAndTabs = self.clientAndTabs where clientAndTabs.count > 0 {
                    tableView.backgroundView = nil
                    // Show dividing lines.
                    tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
                } else {
                    // TODO: Bug 1144760 - Populate background view with UX-approved content.
                    tableView.backgroundView = UIView()
                    tableView.backgroundView?.frame = tableView.frame
                    tableView.backgroundView?.backgroundColor = UIColor.redColor()

                    // Hide dividing lines.
                    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
                }
                tableView.reloadData()
            } else {
                log.error("Failed to fetch tabs.")
            }

            // Always end refreshing, even if we failed!
            self.refreshControl?.endRefreshing()
        })
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        log.debug("We have \(self.clientAndTabs?.count) sections.")
        return self.clientAndTabs?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        log.debug("Section \(section) has \(self.clientAndTabs?[section].tabs.count) tabs.")
        return self.clientAndTabs?[section].tabs.count ?? 0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let clientTabs = self.clientAndTabs?[section] {
            let client = clientTabs.client
            let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(RemoteClientIdentifier) as! TwoLineHeaderFooterView
            view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: RemoteTabsPanelUX.HeaderHeight)
            view.textLabel.text = client.name
            view.contentView.backgroundColor = RemoteTabsPanelUX.HeaderBackgroundColor

            /*
             * A note on timestamps.
             * We have access to two timestamps here: the timestamp of the remote client record,
             * and the set of timestamps of the client's tabs.
             * Neither is "last synced". The client record timestamp changes whenever the remote
             * client uploads its record (i.e., infrequently), but also whenever another device
             * sends a command to that client -- which can be much later than when that client
             * last synced.
             * The client's tabs haven't necessarily changed, but it can still have synced.
             * Ideally, we should save and use the modified time of the tabs record itself.
             * This will be the real time that the other client uploaded tabs.
             */

            let timestamp = clientTabs.approximateLastSyncTime()
            let label = NSLocalizedString("Last synced: %@", comment: "Remote tabs last synced time. Argument is the relative date string.")
            view.detailTextLabel.text = String(format: label, NSDate.fromTimestamp(timestamp).toRelativeTimeString())

            let image: UIImage?
            if client.type == "desktop" {
                image = UIImage(named: "deviceTypeDesktop")
                image?.accessibilityLabel = NSLocalizedString("computer", comment: "Accessibility label for Desktop Computer (PC) image in remote tabs list")
            } else {
                image = UIImage(named: "deviceTypeMobile")
                image?.accessibilityLabel = NSLocalizedString("mobile device", comment: "Accessibility label for Mobile Device image in remote tabs list")
            }
            view.imageView.image = image

            view.mergeAccessibilityLabels()
            return view
        }

        return nil
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(RemoteTabIdentifier, forIndexPath: indexPath) as! TwoLineTableViewCell
        let tab = tabAtIndexPath(indexPath)
        cell.setLines(tab?.title, detailText: tab?.URL.absoluteString)
        // TODO: Bug 1144765 - Populate image with cached favicons.
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        if let tab = tabAtIndexPath(indexPath) {
            // It's not a bookmark, so let's call it Typed (which means History, too).
            let visitType = VisitType.Typed
            homePanelDelegate?.homePanel(self, didSelectURL: tab.URL, visitType: visitType)
        }
    }
}
