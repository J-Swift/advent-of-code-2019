#!/usr/bin/env ruby

FILENAME='input.txt'

def get_slope(src, dest)
    case
    when src.x==dest.x
        src.y > dest.y ? :positive_v : :negative_v
    when src.y==dest.y
        src.x > dest.x ? :positive_h : :negative_h
    else
        prefix = src.x < dest.x ? 'L' : 'R'
        rational = (src.y-dest.y).to_r/(src.x-dest.x).to_r
        "#{prefix}_#{rational}"
    end
end

def get_unique_slopes(src, others)
    res = others.group_by { |dest| src == dest ? :invalid : get_slope(src, dest) }
    res.delete(:invalid)
    res
end

def read_inputs
    File.readlines(FILENAME).map(&:strip).map(&:chars)
end

Asteroid = Struct.new(:x, :y)
def main
    lines = read_inputs
    
    asteroids = []

    lines.each_with_index do |line, y|
        line.each_with_index do |char, x|
            asteroids << Asteroid.new(x, y) if char == '#'
        end
    end

    best = asteroids.max_by do |src|
        get_unique_slopes(src, asteroids).keys.count
    end
    puts best
    puts get_unique_slopes(best, asteroids).keys.count
    pp get_unique_slopes(best,asteroids)
end

main
