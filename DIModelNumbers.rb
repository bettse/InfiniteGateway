#!/usr/bin/env ruby

require 'scrapify'

module DisneyInfinity
  class ModelNumber
    include Scrapify::Base
    html "http://disneyinfinity.wikia.com/wiki/Disney_Infinity/Model_Numbers"

    attribute :model, css: '#mw-content-text li'

    key :model

    def parts
      @path ||= model.gsub(/[[:space:]]/,' ').split('-', 3).map(&:strip)
    end

    def name
      parts[2]
    end

    def model_number
      parts[1]
    end

    def real?
      parts[0] == 'INF' && !name.empty?
    end

    def inspect
      "#<#{self.class.name} #{model_number} #{name}>"
    end

    def swift
      "#{model_number} : \"#{name}\","
    end

  end
end


all = DisneyInfinity::ModelNumber.all()


puts "    static let names : [Int:String] = ["

all.each do |token|
  puts "        #{token.swift}" if token.real?
end

puts "    ]"


