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
  def initialize(api_key='386D256B71BD63AA')
    @api_key = api_key
    @search = "http://www.thetvdb.com/api"
    @api = "#{@search}/#{@api_key}"
    @cache = CacheStore.new # we'll be doing caching on all requests
  end
  
  def search(series_name)
    series = []
    doc = Document.new open("#{@search}/GetSeries.php?seriesname=#{URI.escape(series_name)}")
    doc.elements.each("Data/Series") { |s| series << Series.new(s.elements, self) }
    
    series
  end
  
  def url
    @api
  end
  
  class Series 
    attr_accessor :id, :status, :runtime, :airs_time, :airs_day_of_week, 
                  :genre, :name, :overview, :network, :seasons, :banner
    
    def initialize(details, api = Tvdb.new)
      if details.is_a? Fixnum        
        @api           = api
        @id            = details["seriesid"].text.to_i rescue ""
        @name          = details["SeriesName"].text    rescue ""
        @banner        = details["banner"].text        rescue ""
        @overview      = details["overview"].text      rescue ""
      else
        @id = details
        get_meta
      end
    end
    
    def get_meta
      doc = Document.new open("#{@api.url}/series/#{@id}/en.xml")
      series = doc.root.elements.first.elements
      
      @id               = series["seriesid"].text.to_i  rescue ""
      @name             = series["SeriesName"].text     rescue ""
      @banner           = series["banner"].text         rescue ""
      @overview         = series["overview"].text       rescue ""
      @airs_time        = series["Airs_Time"].text      rescue ""
      @airs_day_of_week = series["Airs_DayOfWeek"].text rescue ""
      @genre            = series["Genre"].text          rescue ""
      @network          = series["Network"].text        rescue ""
      @status           = series["Status"].text         rescue ""
      @runtime          = series["Runtime"].text        rescue ""
      @updated_at       = series["lastupdated"].text    rescue ""
      @rating           = series["rating"].text         rescue ""
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
  end
  
  class Episode
    def initialize(details, api = Tvdb.new)
      @api = client
      @deails = details
    end
  end
  
  class Banner
    def initialize(details, client = Tvdb.new)
      @client = client
    end
  end
  
  class CacheStore
  end
end