# frozen_string_literal: true

require 'sciolyff/interpreter/model'

module SciolyFF
  # Track logic, to be used in the Interpreter class
  class Interpreter::Track < Interpreter::Model
    def link_to_other_models(interpreter)
      super
      @teams = interpreter.teams.find { |t| t.track == @rep[:name] }
      @placings = interpreter.placings.find { |p| p.team.track == @rep[:name] }
      @penalties = interpreter.penalties.find { |p| p.team.track == @rep[:name] }
    end

    attr_reader :teams, :placings, :penalties

    def medals
      @rep[:medals] || @tournament.medals
    end

    def trophies
      @rep[:trophies] || @tournament.trophies
    end

    def maximum_place
      [@teams.count { |t| !t.exhibition? }, @tournament.maximum_place].min
    end
  end
end
