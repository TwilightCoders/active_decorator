# frozen_string_literal: true
require 'test_helper'

class DecoratorTest < Test::Unit::TestCase

  test 'it returns the object on decoration' do
    book = Book.new title: 'Boek'
    assert_equal book, ActiveDecorator.decorate(book)
  end

  test 'it returns the object when it already is decorated on decorate' do
    book = Book.new title: 'Boek'
    assert_equal book, ActiveDecorator.decorate(ActiveDecorator.decorate(book))
  end
end
