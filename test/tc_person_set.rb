$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit'
require 'kitty'

module TestKitty
  class TestPersonSet < Test::Unit::TestCase
    def setup
      @set = Object.new
      @set.extend(Kitty::PersonSet)
    end

    def test_initial_state
      assert_not_nil(@set.persons)
      assert(@set.persons.empty?, 'No persons expected')
    end

    def test_add_with_one_person
      person = Kitty::Person.new('Test')
      @set.add(person)
      assert_equal(1, @set.persons.length)
      assert(@set.persons.include?(person))
    end

    def test_add_with_many_persons
      person0 = Kitty::Person.new('Test0')
      person1 = Kitty::Person.new('Test1')
      @set.add(person0, person1)
      assert_equal(2, @set.persons.length)
      assert(@set.persons.include?(person0))
      assert(@set.persons.include?(person1))
    end

    def test_add_other_set
      person0 = Kitty::Person.new('Test0')
      person1 = Kitty::Person.new('Test1')
      person2 = Kitty::Person.new('Test2')
      group = Kitty::Group.new('Group')
      @set.add(person0)
      group.add(person1, person2)
      @set.add(group)
      assert_equal(3, @set.persons.length)
      assert(@set.persons.include?(person0))
      assert(@set.persons.include?(person1))
      assert(@set.persons.include?(person2))
    end

    def teardown
      @set = nil
    end
  end
end