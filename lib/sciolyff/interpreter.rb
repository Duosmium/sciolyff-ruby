# frozen_string_literal: true

module SciolyFF
  class Interpreter
    require 'sciolyff/interpreter/tournament'
    require 'sciolyff/interpreter/event'
    require 'sciolyff/interpreter/team'
    require 'sciolyff/interpreter/placing'
    require 'sciolyff/interpreter/penalty'

    attr_reader :tournament, :events, :teams, :placings, :penalties

    def initialize(rep)
      create_models(rep)
      link_models(self)

      sort_events_naturally
      sort_teams_by_rank

      freeze_models
    end

    private

    def create_models(rep)
      @tournament = Tournament.new(rep)
      @events    = map_array_to_models rep[:Events],    Event,   rep
      @teams     = map_array_to_models rep[:Teams],     Team,    rep
      @placings  = map_array_to_models rep[:Placings],  Placing, rep
      @penalties = map_array_to_models rep[:Penalties], Penalty, rep
    end

    def map_array_to_models(arr, object_class, rep)
      return [] if arr.nil?

      arr.map.with_index { |_, index| object_class.new(rep, index) }
    end

    def link_models(interpreter)
      # models have to linked in reverse order because reasons
      @penalties.each { |m| m.link_to_other_models(interpreter) }
      @placings .each { |m| m.link_to_other_models(interpreter) }
      @teams    .each { |m| m.link_to_other_models(interpreter) }
      @events   .each { |m| m.link_to_other_models(interpreter) }
      @tournament.link_to_other_models(interpreter)
    end

    def freeze_models
      @events.freeze
      @teams.freeze
      @placings.freeze
      @penalties.freeze
    end

    def sort_events_naturally
      @events.sort! do |a, b|
        next  1 if  a.trial? && !b.trial?
        next -1 if !a.trial? &&  b.trial?

        a.name <=> b.name
      end
    end

    def sort_teams_by_rank
      @teams.sort! do |team_a, team_b|
        next  1 if  team_a.exhibition? && !team_b.exhibition?
        next -1 if !team_a.exhibition? &&  team_b.exhibition?

        cmp = team_a.points <=> team_b.points
        cmp.zero? ? break_tie(team_a, team_b) : cmp
      end
    end

    def break_tie(team_a, team_b)
      team_a.medal_counts
            .zip(team_b.medal_counts)
            .map { |counts| counts.last - counts.first }
            .find(proc { break_second_tie(team_a, team_b) }, &:nonzero?)
    end

    def break_second_tie(team_a, team_b)
      cmp = team_a.trial_event_points <=> team_b.trial_event_points
      cmp.zero? ? break_third_tie(team_a, team_b) : cmp
    end

    def break_third_tie(team_a, team_b)
      team_a.trial_event_medal_counts
            .zip(team_b.trial_event_medal_counts)
            .map { |counts| counts.last - counts.first }
            .find(proc { team_a.number <=> team_b.number }, &:nonzero?)
    end
  end
end
