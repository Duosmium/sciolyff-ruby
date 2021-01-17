# frozen_string_literal: true

require 'sciolyff/validator/checker'
require 'sciolyff/validator/sections'
require 'sciolyff/validator/range'

module SciolyFF
  # Checks for one track in the Tracks section of a SciolyFF file
  class Validator::Tracks < Validator::Checker
    include Validator::Sections

    REQUIRED = {
      name: String
    }.freeze

    OPTIONAL = {
      medals: Integer,
      trophies: Integer,
      'maximum place': Integer
    }.freeze

    def initialize(rep)
      @names = rep[:Tracks].map { |s| s[:name] }
      @teams = rep[:Teams].group_by { |t| t[:track] }
    end

    def unique_name?(track, logger)
      return true if @names.count(track[:name]) == 1

      logger.error "duplicate track name: #{track[:name]}"
    end

    def matching_teams?(track, logger)
      name = track[:name]
      return true if @teams[name]

      logger.error "track with 'name: #{name}' has no teams"
    end

    include Validator::Range

    def maximum_place_within_range?(track, logger)
      max = team_count(track)
      within_range?(track, :'maximum place', logger, 1, max)
    end

    def medals_within_range?(track, logger)
      max = [team_count(track), track[:'maximum place']].compact.min
      within_range?(track, :medals, logger, 1, max)
    end

    def trophies_within_range?(track, logger)
      within_range?(track, :trophies, logger, 1, team_count(track))
    end

    private

    def team_count(track)
      @teams[track[:name]].count do |t|
        t[:track] == track[:name] && !t[:exhibition]
      end
    end
  end
end
