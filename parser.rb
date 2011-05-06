#!/usr/bin/env ruby

require 'rubygems'
require 'fastercsv'
require 'json'

TRASH_FILE = $*[0] || 'schedule.csv'
STAT_HOLIDAYS = $*[1] || 'stats.csv'
END_DATE = DateTime.strptime("2012-12-31", '%F')

zone, first_day, has_greenbin = nil
cur_date = nil

@stats = Array.new
FasterCSV.foreach( STAT_HOLIDAYS ) do |row|
  @stats << DateTime.strptime( row[0], '%F' )
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
  first_day = DateTime.strptime( row[1], '%F' )
  if row[2]
    exceptions = row[2].split(' ').collect { |x| DateTime.strptime(x, '%F') }
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
    json << { 'date' => cur_date, 'zone' => "cityofnanaimo-#{zone.downcase}", 'flags' => "#{'G' if garbage || is_exception}#{'R' if recycling}#{'C' if green_bin}" }
    cur_date = getNextPickupDate( cur_date )
    recycling = !recycling
    garbage = !garbage
  end
end

puts ',', json.to_json