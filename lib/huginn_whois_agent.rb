require 'huginn_agent'
require 'whois-parser'

#HuginnAgent.load 'huginn_whois_agent/concerns/my_agent_concern'
HuginnAgent.register 'huginn_whois_agent/whois_agent'
