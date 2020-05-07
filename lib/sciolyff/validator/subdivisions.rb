# frozen_string_literal: true

require 'sciolyff/validator/checker'
require 'sciolyff/validator/sections'
require 'sciolyff/validator/range'

module SciolyFF
  # Checks for one subdivision in the Subdivisions section of a SciolyFF file
  class Validator::Subdivisions < Validator::Checker
    include Validator::Sections

    REQUIRED = {
      name: String
    }.freeze

    OPTIONAL = {
      medals: Integer,
      trophies: Integer
    }.freeze

    def initialize(rep)
      @teams = rep[:Teams].group_by { |t| t[:subdivision] }
    end

    def matching_teams?(subdivision, logger)
      name = subdivision[:name]
      return true if @teams[name]

      logger.error "subdivision with 'name: #{name}' has no teams"
    end

    include Validator::Range

    def medals_within_range?(subdivision, logger)
      max = [@maximum_place, subdivision[:'maximum place']].compact.min
      within_range?(subdivision, :medals, logger, 1, max)
    end

    def trophies_within_range?(subdivision, logger)
      within_range?(subdivision, :trophies, logger, 1, @maximum_place)
    end
  end
end
