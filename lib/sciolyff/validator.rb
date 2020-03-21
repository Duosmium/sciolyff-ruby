# frozen_string_literal: true

require 'psych'
require 'date'

module SciolyFF
  # Checks if SciolyFF YAML files and/or representations (i.e. hashes that can
  # be directly converted to YAML) comply with spec (i.e. safe for interpreting)
  class Validator
    require 'sciolyff/validator/logger'
    require 'sciolyff/validator/checker'
    require 'sciolyff/validator/sections'

    require 'sciolyff/validator/top_level'
    require 'sciolyff/validator/tournament'
    require 'sciolyff/validator/events'
    require 'sciolyff/validator/teams'
    require 'sciolyff/validator/placings'
    require 'sciolyff/validator/penalties'
    require 'sciolyff/validator/raws'

    def initialize(loglevel = Logger::WARN)
      @logger = Logger.new loglevel
      @checkers = {}
    end

    def valid?(rep_or_file)
      @logger.flush

      if rep_or_file.instance_of? String
        valid_file?(rep_or_file, @logger)
      else
        valid_rep?(rep_or_file, @logger)
      end
    end

    def last_log
      @logger.log
    end

    private

    def valid_rep?(rep, logger)
      unless rep.instance_of? Hash
        logger.error 'improper file structure'
        return false
      end

      result = check_all(rep, logger)

      @checkers.clear # aka this method is not thread-safe
      result
    end

    def valid_file?(path, logger)
      rep = Psych.safe_load(
        File.read(path),
        permitted_classes: [Date],
        symbolize_names: true
      )
    rescue StandardError => e
      logger.error "could not read file as YAML:\n#{e.message}"
    else
      valid_rep?(rep, logger)
    end

    def check_all(rep, logger)
      check(TopLevel, rep, rep, logger) &&
        check(Tournament, rep, rep[:Tournament], logger) &&
        [Events, Teams, Placings, Penalties].all? do |klass|
          check_list(klass, rep, logger)
        end &&
        rep[:Placings].map { |p| p[:raw] }.compact.all? do |r|
          check(Raws, rep, r, logger)
        end
    end

    def check_list(klass, rep, logger)
      key = klass.to_s.split('::').last.to_sym
      return true unless rep.has_key? key # ignore optional sections

      rep[key].map { |e| check(klass, rep, e, logger) }.all?
    end

    def check(klass, top_level_rep, rep, logger)
      @checkers[klass] ||= klass.new top_level_rep
      checks = klass.instance_methods - Checker.instance_methods
      checks.all? { |im| @checkers[klass].send im, rep, logger }
    end
  end
end