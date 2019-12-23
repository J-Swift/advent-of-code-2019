#!/usr/bin/env ruby

FILENAME='input.txt'

def get_offset(numbers)
    numbers[0...7].join.to_i
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split('').map(&:to_i)
end

def main
    lines = read_inputs
    offset = get_offset(lines)

    lines = lines * 10000
    lines = lines[offset..].reverse
    100.times do
        print '.'
        sum = 0
        lines.each_with_index do |item, idx|
            sum = (sum + item) % 10
            lines[idx] = sum
        end
    end
    puts
    p lines[-8..].reverse.join
end

main
