# encoding: utf-8
require 'runner-tool'
require_relative '../../rspec/helpers'
require_relative '../../rspec/matchers'
require_relative 'config_helper'
require_relative "../../platform_config"


# This is a non obvious hack,
# EllipticalCurve are not completely implemented in JRuby 9k and the new version of SSH from the standard library
# use them.
#
# Details: https://github.com/jruby/jruby-openssl/issues/105
Net::SSH::Transport::Algorithms::ALGORITHMS.values.each { |algs| algs.reject! { |a| a =~ /^ecd(sa|h)-sha2/ } }
Net::SSH::KnownHosts::SUPPORTED_TYPE.reject! { |t| t =~ /^ecd(sa|h)-sha2/ }

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
$LOAD_PATH.unshift File.join(ROOT, 'logstash-core/lib')

RunnerTool.configure

RSpec.configure do |c|
  c.include ServiceTester
end

platform = ENV['LS_TEST_PLATFORM'] || 'all'
experimental = (ENV['LS_QA_EXPERIMENTAL_OS'].to_s.downcase || "false") == "true"

config                  = PlatformConfig.new
LOGSTASH_LATEST_VERSION = config.latest

default_vagrant_boxes = ( platform == 'all' ? config.platforms : config.filter_type(platform, {"experimental" => experimental}) )

selected_boxes = if ENV.include?('LS_VAGRANT_HOST') then
                   config.platforms.select { |p| p.name  == ENV['LS_VAGRANT_HOST'] }
                 else
                   default_vagrant_boxes
                 end

SpecsHelper.configure(selected_boxes)

puts "[Acceptance specs] running on #{ServiceTester.configuration.hosts}" if !selected_boxes.empty?
