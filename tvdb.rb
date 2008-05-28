# 
#  tvdb.rb
#  tvdb
#  
#  Created by Bodaniel Jeanes on 2008-05-27.
#  Copyright 2008 Bodaniel Jeanes. All rights reserved.
# 

# use std-lib requires
require 'open-uri'
require 'rexml/document'

include REXML

class Tvdb
  attr_accessor :cache
  
  def initialize(api_key='386D256B71BD63AA')
    @api_key = api_key
    @search = "http://www.thetvdb.com/api"
    @api = "#{@search}/#{@api_key}"
    @cache = CacheStore.new # we'll be doing caching on all requests
  end
  
  def search(series_name)
    @cache.get(:search, series_name) || begin
      doc = Document.new open("#{@search}/GetSeries.php?seriesname=#{URI.escape(series_name)}")
      s = doc.elements.collect("Data/Series") { |s| Series.new(s.elements, self) }
      @cache.set(:search, series_name, s)
    end
  end
  
  def url
    @api
  end
  
  class Series 
    attr_accessor :id, :status, :runtime, :airs_time, :airs_day_of_week, 
                  :genre, :name, :overview, :network, :seasons, :banner,
                  :first_aired
    
    def initialize(details, api = Tvdb.new)
      @api = api
      
      case details
        when Fixnum:
          @id = details
          get_info
        when Document: # Must come before Element or causes weird shit
          set_data_from_rexml_elements details.elements["Data/Series"].elements
          @episodes ||= details.elements.collect('Data/Episode') {|e| Episode.new(e) }
        when Elements:
          set_data_from_rexml_elements details
        when Element:
          set_data_from_rexml_elements details.elements
      else
        raise ArgumentError, "Can't make Tvdb::Series object with #{details.class}"
      end
    end
    
    def get_info
      doc = Document.new open("#{@api.url}/series/#{@id}/en.xml")
      set_data_from_rexml_elements doc.elements["*/Series"].elements
    ensure                                               
      nil
    end
    
    def episodes
      @episodes ||= begin
        doc = Document.new open("#{@api.url}/series/#{@id}/all/en.xml")
        
        doc.elements.collect("Data/Episode") do |episode|
          Episode.new(episode.elements, @api)
        end
      end
    end
    
    def episode(season, number)
      doc = Document.new open("#{@api.url}/series/#{@id}/default/#{season}/#{number}")
      
      Episode.new(doc.elements["Episode"], @api)
    end
    
    private
    def set_data_from_rexml_elements(data)
      @id               = data["seriesid"].text.to_i  rescue nil
      @name             = data["SeriesName"].text     rescue ""
      @banner           = data["banner"].text         rescue ""
      @overview         = data["overview"].text       rescue ""
      @airs_time        = data["Airs_Time"].text      rescue ""
      @first_aired      = data["FirstAired"].text     rescue ""
      @airs_day_of_week = data["Airs_DayOfWeek"].text rescue ""
      @genre            = data["Genre"].text          rescue ""
      @network          = data["Network"].text        rescue ""
      @status           = data["Status"].text         rescue ""
      @runtime          = data["Runtime"].text        rescue ""
      @updated_at       = data["lastupdated"].text    rescue ""
      @rating           = data["rating"].text         rescue ""
    end
  end
  
  class Episode
    def initialize(details, api = Tvdb.new)
      @api = api
      @deails = details
    end
  end
  
  class Banner
    def initialize(details, client = Tvdb.new)
      @client = client
    end
  end
  
  class CacheStore
    def initialize
      @cache = {}
    end
    
    # returns value that was set
    def set(type, key, value)
      type = type.to_sym
      
      @cache[type] = {} if @cache[type].nil?
      @cache[type][key] = value
    end
    
    def get(type, key)
      @cache[type.to_sym][key]
    rescue
      nil
    end
  end
end