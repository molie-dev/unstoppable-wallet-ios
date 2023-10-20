import Foundation
import SwiftUI
import WidgetKit

struct TopCoinsWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: AppWidgetConstants.topCoinsWidgetKind,
            intent: CoinPriceListIntent.self,
            provider: CoinPriceListProvider(mode: .topCoins)
        ) { entry in
            if #available(iOS 17.0, *) {
                CoinPriceListView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                CoinPriceListView(entry: entry)
                    .background()
            }
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Top Coins")
        .description("Displays price for top coins.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
        ])
    }
}