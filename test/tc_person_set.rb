$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'

class TestPersonSet < Test::Unit::TestCase
  def setup
    @set = Object.new
    @set.extend(Kitty::PersonSet)
  end

  def test_initial_state
    assert_nil(@set.persons, 'No persons expected')
  end

  def test_add_with_one_person
    person = Kitty::Person.new('Test')
    @set.add(person)
    assert_same(1, @set.persons.length)
    assert(@set.persons.include?(person))
  end

  def test_add_with_many_persons
    person0 = Kitty::Person.new('Test0')
    person1 = Kitty::Person.new('Test1')
    @set.add(person0, person1)
    assert_same(2, @set.persons.length)
    assert(@set.persons.include?(person0))
    assert(@set.persons.include?(person1))
  end

  def teardown
    @set = nil
  end
end
