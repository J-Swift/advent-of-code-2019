#!/usr/bin/env ruby

FILENAME='input.txt'

WIDTH=25
HEIGHT=6

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split('').map(&:to_i)
end

def main
    digits = read_inputs
    layers = digits.each_slice(WIDTH * HEIGHT).to_a
    least_0s = layers.min_by do |layer|
        layer.group_by { |it| it }[0].size
    end
    buckets = least_0s.group_by { |it| it }
    puts buckets[1].size * buckets[2].size
end

main
