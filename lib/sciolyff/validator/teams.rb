# frozen_string_literal: true

require 'sciolyff/validator/checker'
require 'sciolyff/validator/sections'
require 'sciolyff/validator/canonical'

module SciolyFF
  # Checks for one team in the Teams section of a SciolyFF file
  class Validator::Teams < Validator::Checker
    include Validator::Sections

    REQUIRED = {
      number: Integer,
      school: String,
      state: String
    }.freeze

    OPTIONAL = {
      'school abbreviation': String,
      track: String,
      suffix: String,
      city: String,
      disqualified: [true, false],
      exhibition: [true, false]
    }.freeze

    def initialize(rep)
      initialize_teams_info(rep[:Teams])
      @tracks = rep[:Track]&.map { |s| s[:name] } || []
      @placings = rep[:Placings].group_by { |p| p[:team] }
      @exempt = rep[:Tournament][:'exempt placings'] || 0
    end

    def unique_number?(team, logger)
      return true if @numbers.count(team[:number]) == 1

      logger.error "duplicate team number: #{team[:number]}"
    end

    def unique_suffix_per_school?(team, logger)
      full_school = [team[:school], team[:city], team[:state]]
      return true if @schools[full_school].count do |other|
        !other[:suffix].nil? && other[:suffix] == team[:suffix]
      end <= 1

      logger.error "team number #{team[:number]} has the same suffix "\
        'as another team from the same school'
    end

    def suffix_needed?(team, logger)
      rep = [team[:school], team[:city], team[:state]]
      return true unless team[:suffix] && @schools[rep].count == 1

      logger.warn "team number #{team[:number]} may have unnecessary "\
        "suffix: #{team[:suffix]}"
    end

    def unambiguous_cities_per_school?(team, logger)
      return true unless @schools.keys.find do |other|
        team[:city].nil? && !other[1].nil? &&
        team[:school] == other[0] &&
        team[:state] == other[2]
      end

      logger.error "city for team number #{team[:number]} is ambiguous, "\
        'value is required for unambiguity'
    end

    def correct_number_of_exempt_placings?(team, logger)
      count = @placings[team[:number]].count { |p| p[:exempt] }
      return true if count == @exempt || team[:exhibition]

      logger.error "'team: #{team[:number]}' has incorrect number of "\
        "exempt placings (#{count} insteand of #{@exempt})"
    end

    def matching_track?(team, logger)
      sub = team[:track]
      return true if sub.nil? || @tracks.include?(sub)

      logger.error "'track: #{sub}' does not match any name in "\
        'section Track'
    end

    def in_a_track_if_possible?(team, logger)
      return true unless !@tracks.empty? && !team[:track]

      logger.warn "missing track for 'team: #{team[:number]}'"
    end

    include Validator::Canonical

    def in_canonical_list?(team, logger)
      rep = [team[:school], team[:city], team[:state]]
      return true if canonical?(rep, 'schools.csv', logger)

      location = rep[1..-1].compact.join ', '
      logger.warn "non-canonical school: #{team[:school]} in #{location}"
    end

    private

    def initialize_teams_info(teams)
      @numbers = teams.map { |t| t[:number] }
      @schools = teams.group_by { |t| [t[:school], t[:city], t[:state]] }
    end
  end
end
