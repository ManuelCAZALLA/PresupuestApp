import Foundation

public struct ParserConfig: Sendable {
    public var autoMinScore: Double
    public var autoMinAdvantage: Double  // minimum difference between best and second
    public var ambiguousMinScore: Double
    public var minimumCandidateScore: Double
    public var maxTopCandidates: Int
    public var aliasBoost: Double
    public var trigramWeight: Double
    public var tokenOverlapWeight: Double
    public var idfWeight: Double
    public var suggestionOnly: Bool
    
    public init(
        autoMinScore: Double = 0.08,
        autoMinAdvantage: Double = 0.1,
        ambiguousMinScore: Double = 0.02,
        minimumCandidateScore: Double = 0.4,
        maxTopCandidates: Int = 3,
        aliasBoost: Double = 3.0,
        trigramWeight: Double = 0.6,
        tokenOverlapWeight: Double = 1.0,
        idfWeight: Double = 0.8,
        suggestionOnly: Bool = false
    ) {
        self.autoMinScore = autoMinScore
        self.autoMinAdvantage = autoMinAdvantage
        self.ambiguousMinScore = ambiguousMinScore
        self.minimumCandidateScore = minimumCandidateScore
        self.maxTopCandidates = maxTopCandidates
        self.aliasBoost = aliasBoost
        self.trigramWeight = trigramWeight
        self.tokenOverlapWeight = tokenOverlapWeight
        self.idfWeight = idfWeight
        self.suggestionOnly = suggestionOnly
    }
    
    public static let `default` = ParserConfig(suggestionOnly: true)
}
