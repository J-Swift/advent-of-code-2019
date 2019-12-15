#!/usr/bin/env ruby

FILENAME='input.txt'

WIDTH=25
HEIGHT=6

WHITE=0
BLACK=1
TRANSPARENT=2

def print_row(row)
    row.each { |el| print (el == BLACK ? 'X' : ' ') }
    puts
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)[0].split('').map(&:to_i)
end

def main
    digits = read_inputs
    layers = digits.each_slice(WIDTH * HEIGHT).to_a

    result = layers.transpose.map do |layer|
        layer.find { |it| it != TRANSPARENT }
    end

    result.each_slice(WIDTH).map { |row| print_row(row) }
end

main
