#!/usr/bin/env ruby

FILENAME='input.txt'

def get_mass_recursive(num)
    total = (num / 3).to_i - 2

    if total > 0 && get_mass_recursive(total) > 0
        total += get_mass_recursive(total)
    end

    total
end

def read_inputs
    File.readlines(FILENAME).map(&:strip).map(&:to_i)
end

def main
    lines = read_inputs
    masses = lines.map do |line|
        get_mass_recursive(line)
    end
    puts masses.reduce(&:+)
end

main
