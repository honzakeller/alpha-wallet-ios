// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

struct SetSellTicketsExpiryDateViewControllerViewModel {

    var ticketHolder: TicketHolder
    var ethCost: String = "0"
    var dollarCost: String = "0"

    var headerTitle: String {
		return R.string.localizable.aWalletTicketTokenSellEnterLinkExpiryDateTitle()
    }

    var backgroundColor: UIColor {
        return Colors.appBackground
    }

    var buttonTitleColor: UIColor {
        return Colors.appWhite
    }

    var buttonBackgroundColor: UIColor {
        return Colors.appHighlightGreen
    }

    var buttonFont: UIFont {
        return Fonts.regular(size: 20)!
    }

    var choiceLabelColor: UIColor {
        return UIColor(red: 155, green: 155, blue: 155)
    }

    var choiceLabelFont: UIFont {
        return Fonts.regular(size: 10)!
    }

    var ticketCountString: String {
        return "x\(ticketHolder.tickets.count)"
    }

    var title: String {
        return ticketHolder.name
    }

    var seatRange: String {
        return ticketHolder.seatRange
    }

    var zoneName: String {
        return ticketHolder.zone
    }

	var venue: String {
        return ticketHolder.venue
    }

    var date: String {
        //TODO Should format be localized?
        return ticketHolder.date.format("dd MMM yyyy")
    }

    var linkExpiryDateLabelText: String {
        return R.string.localizable.aWalletTicketTokenSellLinkExpiryDateTitle()
    }

    var linkExpiryTimeLabelText: String {
        return R.string.localizable.aWalletTicketTokenSellLinkExpiryTimeTitle()
    }

    var ticketSaleDetailsLabelFont: UIFont {
        return Fonts.semibold(size: 21)!
    }

    var ticketSaleDetailsLabelColor: UIColor {
        return Colors.appBackground
    }

    var descriptionLabelText: String {
        return R.string.localizable.aWalletTicketTokenSellMagicLinkDescriptionTitle()
    }

    var descriptionLabelFont: UIFont {
        return Fonts.light(size: 21)!
    }

    var descriptionLabelColor: UIColor {
        return Colors.appText
    }

    var ticketCountLabelText: String {
        if ticketCount == 1 {
            return R.string.localizable.aWalletTicketTokenSellSingleTicketSelectedTitle()
        } else {
            return R.string.localizable.aWalletTicketTokenSellMultipleTicketSelectedTitle(ticketHolder.ticketCount)
        }
    }

    var perTicketPriceLabelText: String {
        let amount = Double(ethCost)! / Double(ticketCount)
        return R.string.localizable.aWalletTicketTokenSellPerTicketEthPriceTitle(String(amount))
    }

    var totalEthLabelText: String {
        return R.string.localizable.aWalletTicketTokenSellTotalEthPriceTitle(ethCost)
    }

    var noteTitleLabelText: String {
        return R.string.localizable.aWalletTicketTokenSellNoteTitleLabelTitle()
    }

    var noteTitleLabelFont: UIFont {
        return Fonts.semibold(size: 21)!
    }

    var noteTitleLabelColor: UIColor {
        return Colors.appRed
    }

    var noteLabelText: String {
        return R.string.localizable.aWalletTicketTokenSellNoteLabelTitle()
    }

    var noteLabelFont: UIFont {
        return Fonts.light(size: 21)!
    }

    var noteLabelColor: UIColor {
        return Colors.appRed
    }

    var noteBorderColor: UIColor {
        return Colors.appRed
    }

    private var ticketCount: Int {
        return Int(ticketHolder.ticketCount)!
    }

    init(ticketHolder: TicketHolder, ethCost: String, dollarCost: String) {
        self.ticketHolder = ticketHolder
        self.ethCost = ethCost
        self.dollarCost = dollarCost
    }
}
