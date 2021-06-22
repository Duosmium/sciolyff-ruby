# frozen_string_literal: true

module SciolyFF
  # Interprets the YAML representation of a SciolyFF file through objects that
  # respond to idiomatic Ruby method calls
  class Interpreter
    require 'sciolyff/interpreter/tournament'
    require 'sciolyff/interpreter/event'
    require 'sciolyff/interpreter/team'
    require 'sciolyff/interpreter/placing'
    require 'sciolyff/interpreter/penalty'

    require 'sciolyff/interpreter/tiebreaks'
    require 'sciolyff/interpreter/track'

    attr_reader :tournament, :events, :teams, :placings, :penalties, :tracks

    def initialize(rep)
      if rep.instance_of? String
        rep = Psych.safe_load(rep,
                              permitted_classes: [Date],
                              symbolize_names: true)
      end
      create_models(@rep = rep)
      link_models(self)

      sort_events_naturally
      sort_teams_by_rank
    end

    def raws?
      placings.any?(&:raw?)
    end

    private

    def create_models(rep)
      @tournament = Tournament.new(rep)
      @events     = map_array_to_models rep[:Events],    Event,   rep
      @tracks     = map_array_to_models rep[:Tracks],    Track,   rep
      @teams      = map_array_to_models rep[:Teams],     Team,    rep
      @placings   = map_array_to_models rep[:Placings],  Placing, rep
      @penalties  = map_array_to_models rep[:Penalties], Penalty, rep
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
      @tracks   .each { |m| m.link_to_other_models(interpreter) }
      @events   .each { |m| m.link_to_other_models(interpreter) }
      @tournament.link_to_other_models(interpreter)
    end

    def sort_events_naturally
      @events.sort_by! { |e| [e.trial?.to_s, e.name] }
    end

    def sort_teams_by_rank
      sorted =
        @teams
        .group_by { |t| [t.disqualified?.to_s, t.exhibition?.to_s] }
        .map { |key, teams| [key, sort_teams_by_points(teams)] }
        .sort_by(&:first)
        .map(&:last)
        .flatten
      @teams.map!.with_index { |_, i| sorted[i] }
    end

    include Interpreter::Tiebreaks
  end
end
