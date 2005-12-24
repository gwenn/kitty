$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'

class TestTrip < Test::Unit::TestCase
  def setup
    @trip = Kitty::Trip.new('Test')
  end

  def test_initialize_trip
    assert_equal('Test', @trip.name)
    assert_nil(@trip.period)
  end

  def test_no_name
    assert_raise(ArgumentError) {
      Kitty::Trip.new(nil)
    }
    assert_raise(ArgumentError) {
      Kitty::Trip.new('')
    }
  end

  def teardown
    @trip = nil
  end
end
