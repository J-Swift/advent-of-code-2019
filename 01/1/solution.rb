#!/usr/bin/env ruby

FILENAME='input.txt'

def get_mass(num)
    (num / 3).to_i - 2
end

def read_inputs
    File.readlines(FILENAME).map(&:strip).map(&:to_i)
end

def main
    lines = read_inputs
    total = 0
    lines.each do |line|
        total += get_mass(line)
    end
    puts total
end

main
