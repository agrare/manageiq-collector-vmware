#!/usr/bin/env ruby
$LOAD_PATH.unshift(".")

require 'optimist'
require 'rbvmomi'
require 'manageiq/providers/vmware/collector'

def main args
  collector = ManageIQ::Providers::Vmware::Collector.new(args[:ems_id], args[:hostname], args[:port], args[:user], args[:password])
  collector.run
end

def parse_args
  args = Optimist.options do
    opt :hostname, "hostname", :type => :string
    opt :port,     "port",     :type => :int, :default => 443, :short => 'o'
    opt :user,     "username", :type => :string
    opt :password, "password", :type => :string
    opt :ems_id,   "ems-id",   :type => :int
  end

  args[:hostname] ||= ENV["EMS_HOSTNAME"]
  args[:user]     ||= ENV["EMS_USER"]
  args[:password] ||= ENV["EMS_PASSWORD"]
  args[:ems_id]   ||= ENV["EMS_ID"]

  raise Optimist::CommandlineError, "--hostname required" if args[:hostname].nil?
  raise Optimist::CommandlineError, "--user required"     if args[:user].nil?
  raise Optimist::CommandlineError, "--password required" if args[:password].nil?
  raise Optimist::CommandlineError, "--ems-id required"   if args[:ems_id].nil?

  args
end

args = parse_args

main args
