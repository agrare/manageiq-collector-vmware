require 'trollop'
require 'rbvmomi'

def connect hostname, user, password
  vim_opts = {
    :ns       => 'urn:vim25',
    :rev      => '4.1',
    :host     => hostname,
    :ssl      => true,
    :insecure => true,
    :path     => '/sdk',
    :port     => 443,
  }

  RbVmomi::VIM.new(vim_opts).tap do |vim|
    vim.rev = vim.serviceContent.about.apiVersion
    vim.serviceContent.sessionManager.Login(:userName => user, :password => password)
  end
end

def main args
  vim = connect args[:hostname], args[:user], args[:password]
ensure
  vim.serviceContent.sessionManager.Logout unless vim.nil?
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
