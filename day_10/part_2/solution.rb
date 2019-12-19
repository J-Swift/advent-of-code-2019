#!/usr/bin/env ruby

FILENAME='input.txt'

def atan2(src, dest)
    result = Math.atan2(dest.inverted_y - src.inverted_y, dest.x  - src.x)
    if result == Math::PI
        result = -result
    end
    result + Math::PI
end

def distance(src, dest)
    squared = (dest.inverted_y - src.inverted_y)**2 + (dest.x - src.x)**2
    Math.sqrt(squared)
end

def get_slope(src, dest)
    case
    when src.x==dest.x
        src.y > dest.y ? :positive_v : :negative_v
    when src.y==dest.y
        src.x > dest.x ? :positive_h : :negative_h
    else
        prefix = src.x > dest.x ? 'L' : 'R'
        rational = (dest.y-src.y).to_r/(dest.x-src.x).to_r
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

Asteroid = Struct.new(:x, :y, :inverted_y)
def main
    lines = read_inputs
    
    asteroids = []
    lines.each_with_index do |line, y|
        line.each_with_index do |char, x|
            asteroids << Asteroid.new(x, y, -y) if char == '#'
        end
    end

    best = asteroids.max_by do |src|
        get_unique_slopes(src, asteroids).keys.count
    end

    puts best
    puts '--------------'
    by_angle = []
    asteroids.each do |it|
        next if best == it
        by_angle << {
            asteroid: it,
            atan2: atan2(best, it),
            distance: distance(best, it),
        }
    end
    sorted = by_angle.sort_by { |it| [it[:atan2], -it[:distance]] }.reverse

    starting_index = sorted.find_index { |it| it[:atan2] <= Math::PI * 1.5}
    
    require 'set'
    destroyed = Set.new
    previously_destroyed_atan = nil
    num_destroyed = 0
    while num_destroyed < sorted.count
        target = sorted[starting_index]
        if previously_destroyed_atan == target[:atan2]
            starting_index = (starting_index + 1) % sorted.count
            next
        end
        previously_destroyed_atan = nil
        if !destroyed.member?(target[:asteroid])
            previously_destroyed_atan = target[:atan2]
            destroyed.add(target[:asteroid])
            num_destroyed += 1
            puts "#{num_destroyed}: #{target[:asteroid]}"
        end
        starting_index = (starting_index + 1) % sorted.count
    end
end

main
