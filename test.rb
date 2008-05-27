#!/usr/bin/env ruby
#
#  Created by Bodaniel Jeanes (me@bjeanes.com) on 2008-05-27.
#  Copyright (c) 2008. All rights reserved.

require 'test/unit'
require 'tvdb'

class TestTvdb < Test::Unit::TestCase
  def test_search_returns_array
    assert_equal(Array, api.search("My Name Is Earl").class)
  end
  
  def test_sucessfull_search_results_contain_series_objects
    assert_equal(Tvdb::Series, api.search("My Name Is Earl").first.class)
  end
  
  private
  def api
    @api ||= Tvdb.new
  end
end
