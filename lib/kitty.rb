# == Synopsis
#
# Helps to keep Group accounting.
# Original idea came from
# {Christian Neukirchen}[http://chneukirchen.org/blog/archive/2005/05/scripting-for-runaways.html].
#
# == Usage
#    ruby kitty.rb [-h | --help] trip_data...
#
# trip_data::
#    A file describing the expenses made for one trip.
#
#   trip 'Neons'
#
#   group 'Car1', 'Bou', 'Fred', 'Sosoph'
#   group 'Car2', 'Gwenn', 'Medo', 'Seb'
#
#   Seb.pay 45, :purpose => 'petrol', :include => Car2
#   Sosoph.pay 40, :purpose => 'toll', :include => Car1
#   Fred.pay 50, :purpose => 'petrol', :include => Car1
#   Medo.pay 37, :purpose => 'restaurant', :exclude => [Fred, Gwenn]
#   Fred.pay 70, :purpose => 'makina', :exclude => Gwenn
#   Sosoph.pay 6, :purpose => 'makina', :exclude => Gwenn
#
#   Bou.pay 57, 'foodstuffs'
#   Gwenn.pay 16, 'foodstuffs'
#   Medo.pay 70, 'foodstuffs'
#   Seb.pay 14, 'foodstuffs'
#
#   Gwenn.prefer_to_pay_back Medo
#   Sosoph.prefer_to_pay_back Fred
#
#   balance
#
# == Author
# El Barto
#
# == Copyright
# Copyright (c) 2005 El Barto.
# Licensed under the same terms as Ruby.
require 'kitty/dsl'
require 'kitty/version'

module Kitty
  module Main
    def self.run
      require 'optparse'
      require 'rdoc/usage'

      opts = OptionParser.new
      opts.on('-h', '--help') { RDoc::usage }
      begin
        opts.parse(ARGV)
      rescue => error
        puts(error.message)
        RDoc::usage('Usage')
      end

      unless ARGV.empty?
        ARGV.each do |arg|
          ctx = Kitty::Trick.new
          File.open(arg) do |file|
            #thr = Thread.new do
              #ctx.taint
              #file.taint
              #$SAFE = 4
              ctx.instance_eval(file.read, arg, 1)
            #end
            #thr.join
          end
        end
      else
        puts('Missing trip data')
        RDoc::usage('Usage')
      end

      at_exit { puts('ByeBye...') }
    end
  end
end

if __FILE__ == $0
  Kitty::Main.run
end
