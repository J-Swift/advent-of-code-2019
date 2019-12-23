#!/usr/bin/env ruby

FILENAME='input.txt'

PATTERN = [0, 1, 0, -1]
def pattern_generator(iteration)
    is_first = true
    Enumerator.new do |y|
        idx = 0
        loop do
            iteration.times do |i|
                if is_first
                    is_first = false
                    next
                end
                y << PATTERN[idx]
            end
            idx = (idx + 1) % PATTERN.size
        end
    end
end

def get_number(numbers, iter)
    numbers.map { |it| it * iter.next }.sum.to_s[-1].to_i
end

def do_iteration(numbers)
    numbers.each_with_index.map do |_, idx|
        iter = pattern_generator(idx+1)
        get_number(numbers, iter)
    end
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split('').map(&:to_i)
end

def main
    lines = read_inputs

    100.times do
        lines = do_iteration(lines)
    end
    p lines[0...8].join
end

main
