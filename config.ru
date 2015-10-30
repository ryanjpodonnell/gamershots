require 'rubygems'
require 'bundler'

Bundler.require

require './gamershots'
run Sinatra::Application
