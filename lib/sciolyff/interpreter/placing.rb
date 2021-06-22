# frozen_string_literal: true

require 'sciolyff/interpreter/model'

module SciolyFF
  # Models the result of a team participating (or not) in an event
  class Interpreter::Placing < Interpreter::Model
    require 'sciolyff/interpreter/raw'

    def link_to_other_models(interpreter)
      super
      @event = interpreter.events.find { |e| e.name   == @rep[:event] }
      @team  = interpreter.teams .find { |t| t.number == @rep[:team]  }
    end

    attr_reader :event, :team

    def participated?
      @rep[:participated] || @rep[:participated].nil?
    end

    def disqualified?
      @rep[:disqualified] || false
    end

    def exempt?
      @rep[:exempt] || false
    end

    def unknown?
      @rep[:unknown] || false
    end

    def tie?
      raw? ? @tie ||= event.raws.count(raw) > 1 : @rep[:tie] == true
    end

    def place
      raw? ? @place ||= event.raws.find_index(raw) + 1 : @rep[:place]
    end

    def track_place
      @track_place ||= @team.track.placings.select { |p| p.event == @event }.sort_by!(&:isolated_track_points).find_index(self) + 1
    end

    def raw
      @raw ||= Raw.new(@rep[:raw], event.low_score_wins?) if raw?
    end

    def raw?
      @rep.key? :raw
    end

    def did_not_participate?
      !participated?
    end

    def participation_only?
      participated? && !place && !disqualified? && !unknown?
    end

    def dropped_as_part_of_worst_placings?
      team.worst_placings_to_be_dropped.include?(self)
    end

    def points
      @points ||= if !considered_for_team_points? then 0
                  else isolated_points
                  end
    end

    def track_points
      @track_points ||= if !considered_for_team_points? then 0
                  else isolated_track_points
                  end
    end

    def isolated_points
      max_place = event.maximum_place
      n = max_place + tournament.n_offset

      if    disqualified? then n + 2
      elsif did_not_participate? then n + 1
      elsif participation_only? || unknown? then n
      else  [calculate_points(false), max_place].min
      end
    end

    def isolated_track_points
      max_place = team.track.maximum_place
      n = max_place + tournament.n_offset

      if    disqualified? then n + 2
      elsif did_not_participate? then n + 1
      elsif participation_only? || unknown? then n
      else  [calculate_points(true), max_place].min
      end
    end

    def considered_for_team_points?
      initially_considered_for_team_points? &&
        !dropped_as_part_of_worst_placings?
    end

    def initially_considered_for_team_points?
      !(event.trial? || event.trialed? || exempt?)
    end

    def points_affected_by_exhibition?
      considered_for_team_points? && place && !exhibition_placings_behind(false).zero?
    end

    def points_limited_by_maximum_place?
      tournament.custom_maximum_place? &&
        (unknown? ||
         (place &&
          (calculate_points(false) > event.maximum_place ||
           calculate_points(false) == event.maximum_place && tie?
          )))
    end

    private

    def calculate_points(in_track)
      if in_track
        if event.trial?
          track_place
        else
          track_place - exhibition_placings_behind(true)
        end
      else
        if event.trial?
          place
        else
          place - exhibition_placings_behind(false)
        end
      end
    end

    def exhibition_placings_behind(in_track)
      if in_track
        @track_exhibition_placings_behind ||= event.placings.count do |p|
          (p.exempt? || p.team.exhibition?) &&
            p.team.track == team.track &&
            p.track_place &&
            p.track_place < track_place
        end
      else
        @exhibition_placings_behind ||= event.placings.count do |p|
          (p.exempt? || p.team.exhibition?) &&
            p.place &&
            p.place < place
        end
      end
    end
  end
end
