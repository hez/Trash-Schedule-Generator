#!/usr/bin/env ruby

require 'rubygems'
require 'fastercsv'
require 'json'

TRASH_FILE = $*[0] || 'schedule.csv'
STAT_HOLIDAYS = $*[1] || 'stats.csv'
TIME_ZONE = '-08:00'
CITY_STRING = $*[2] || 'cityofnanaimo'
def make_date_time_with_time_zone( str )
  DateTime.strptime( "#{str}T00:00:00#{TIME_ZONE}", '%F' )
end
END_DATE = make_date_time_with_time_zone("2012-12-31")


zone, first_day, has_greenbin = nil
cur_date = nil

@stats = Array.new
FasterCSV.foreach( STAT_HOLIDAYS ) do |row|
  @stats << make_date_time_with_time_zone( row[0] )
end

def isStat?( next_date )
  @stats.include?( next_date )
end

def isWeekend?( next_date )
  next_date.wday == 0 || next_date.wday == 6
end

def getNextPickupDate( cur_date )
  next_date = cur_date
  steps = 5
  while( steps > 0 )
    next_date += 1
    steps -= 1
    steps += 1 if isStat?( next_date )
    steps += 1 if isWeekend?( next_date )
  end
  next_date
end

json = Array.new
FasterCSV.foreach( TRASH_FILE ) do | row |
  first_day = make_date_time_with_time_zone( row[1] )
  if row[2]
    exceptions = row[2].split(' ').collect { |x| make_date_time_with_time_zone(x) }
  else
    exceptions = []
  end
  green_bin = (row[3] == '1')
  cur_date = first_day
  recycling = (row[4] == '1')
  garbage = !recycling

  zone = row[0]
  while( cur_date <= END_DATE )
    is_exception = exceptions.include?( cur_date )
    csv = "#{zone.inspect},#{cur_date.strftime( '%Y-%m-%d' ).inspect},\"#{'G' if garbage || is_exception}#{'R' if recycling}#{'B' if green_bin}\""
#    puts csv
    json << { 'date' => cur_date.strftime("%FT%T#{TIME_ZONE}"), 'zone' => "#{CITY_STRING}-#{zone.downcase}", 'flags' => "#{'G' if garbage || is_exception}#{'R' if recycling}#{'C' if green_bin}" }
    cur_date = getNextPickupDate( cur_date )
    recycling = !recycling
    garbage = !garbage
  end
end

puts json.to_json
