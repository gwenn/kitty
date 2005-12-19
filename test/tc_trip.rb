$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'

class TestTrip < Test::Unit::TestCase
  def setup
    @trip = Account::Trip.new('test')
  end
  
  def test_initialize_trip
    assert_equal('test', @trip.name)
    assert_nil(@trip.period)
  end
  
  def teardown
    @trip = nil
  end
end
