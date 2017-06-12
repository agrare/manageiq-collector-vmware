$LOAD_PATH.unshift(".")

require 'trollop'
require 'rbvmomi'
require 'collector'

def main args
  collector = ManageIQ::Providers::Vmware::Collector.new(args[:hostname], args[:user], args[:password])
  collector.run
end

def parse_args
  args = Trollop.options do
    opt :hostname, "hostname", :type => :string, :short => 'o'
    opt :user,     "username", :type => :string, :short => 'u'
    opt :password, "password", :type => :string, :short => 'p'
  end

  args[:hostname] ||= ENV["COLLECTOR_HOSTNAME"]
  args[:user]     ||= ENV["COLLECTOR_USER"]
  args[:password] ||= ENV["COLLECTOR_PASSWORD"]

  raise Trollop::CommandlineError, "--hostname required" if args[:hostname].nil?
  raise Trollop::CommandlineError, "--user required"     if args[:user].nil?
  raise Trollop::CommandlineError, "--password required" if args[:password].nil?

  args
end

args = parse_args

main args
