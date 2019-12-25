# frozen_string_literal: true

module SciolyFF
  # Models the raw score representation for a Placing
  class Interpreter::Placing::Raw
    def initialize(rep)
      @rep = rep
    end

    def score
      @rep[:score]
    end

    def tiered?
      tier > 1
    end

    def tier
      @rep[:tier] || 1
    end

    def lost_tiebreaker?
      tiebreaker_rank > 1
    end

    def tiebreaker_rank
      @rep[:'tiebreaker rank'] || 1
    end

    def ==(other)
      score == other.score &&
        tier == other.tier &&
        tiebreaker_rank == other.tiebreaker_rank
    end

    def <=>(other)
      [tier, -score, tiebreaker_rank] <=>
        [other.tier, -other.score, other.tiebreaker_rank]
    end
  end
end
