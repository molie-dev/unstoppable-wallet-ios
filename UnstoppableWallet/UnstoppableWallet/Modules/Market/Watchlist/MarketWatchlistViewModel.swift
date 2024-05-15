import Combine
import Foundation
import HsExtensions
import MarketKit
import RxSwift

class MarketWatchlistViewModel: ObservableObject {
    private let marketKit = App.shared.marketKit
    private let currencyManager = App.shared.currencyManager
    private let favoritesManager = App.shared.favoritesManager

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var coinUids = [String]()

    private var internalState: State = .loading {
        didSet {
            syncState()
        }
    }

    @Published var state: State = .loading

    var sortBy: MarketModule.SortBy = .gainers {
        didSet {
            syncState()
        }
    }

    var timePeriod: HsTimePeriod = .day1 {
        didSet {
            syncState()
        }
    }

    var showSignals: Bool = false {
        didSet {
            syncState()
        }
    }

    private func syncCoinUids() {
        coinUids = favoritesManager.allCoinUids

        if case let .loaded(marketInfos, signals) = internalState {
            let newMarketInfos = marketInfos.filter { marketInfo in
                coinUids.contains(marketInfo.fullCoin.coin.uid)
            }

            if newMarketInfos.count == coinUids.count {
                internalState = .loaded(marketInfos: newMarketInfos, signals: signals)
                return
            }
        }

        syncMarketInfos()
    }

    private func syncMarketInfos() {
        tasks = Set()

        Task { [weak self] in
            await self?._syncMarketInfos()
        }.store(in: &tasks)
    }

    private func _syncMarketInfos() async {
        if coinUids.isEmpty {
            await MainActor.run { [weak self] in
                self?.internalState = .loaded(marketInfos: [], signals: [:])
            }
            return
        }

        if case .failed = internalState {
            await MainActor.run { [weak self] in
                self?.internalState = .loading
            }
        }

        do {
            async let _marketInfos = try marketKit.marketInfos(coinUids: coinUids, currencyCode: currency.code)
            async let _signals = try marketKit.signals(coinUids: coinUids)

            let (marketInfos, signals) = try await (_marketInfos, _signals)

            await MainActor.run { [weak self] in
                self?.internalState = .loaded(marketInfos: marketInfos, signals: signals)
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.internalState = .failed(error: error)
            }
        }
    }

    private func syncState() {
        switch internalState {
        case .loading:
            state = .loading
        case let .loaded(marketInfos, signals):
            state = .loaded(marketInfos: marketInfos.sorted(sortBy: sortBy, timePeriod: timePeriod), signals: signals)
        case let .failed(error):
            state = .failed(error: error)
        }
    }
}

extension MarketWatchlistViewModel {
    var currency: Currency {
        currencyManager.baseCurrency
    }

    var sortBys: [MarketModule.SortBy] {
        [.manual, .highestCap, .lowestCap, .gainers, .losers, .highestVolume, .lowestVolume]
    }

    var timePeriods: [HsTimePeriod] {
        [.day1, .week1, .month1, .month3]
    }

    func load() {
        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.syncMarketInfos()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, favoritesManager.coinUidsUpdatedObservable) { [weak self] in self?.syncCoinUids() }

        syncCoinUids()
    }

    func refresh() async {
        await _syncMarketInfos()
    }
}

extension MarketWatchlistViewModel {
    enum State {
        case loading
        case loaded(marketInfos: [MarketInfo], signals: [String: TechnicalAdvice.Advice])
        case failed(error: Error)
    }
}