#!/usr/bin/env ruby

FILENAME='input.txt'

require 'set'

def to_command(text)
    dir = text[0]
    amount = text.scan(/\d+/).first.to_i
    {dir: dir, num: amount}
end

def get_all_spaces(cmds)
    curx = cury = 0
    cmds.reduce(Set.new) do |memo, cmd|
        case cmd[:dir]
        when "L"
            a, b = curx - 1, curx - cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |x|
                memo << "#{x},#{cury}"
            end
            curx -= cmd[:num]
        when "R"
            a, b = curx + 1, curx + cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |x|
                memo << "#{x},#{cury}"
            end
            curx += cmd[:num]
        when "D"
            a, b = cury - 1, cury - cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |y|
                memo << "#{curx},#{y}"
            end
            cury -= cmd[:num]
        when "U"
            a, b = cury + 1, cury + cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |y|
                memo << "#{curx},#{y}"
            end
            cury += cmd[:num]
        end
        memo
    end
end

def read_inputs
    File.readlines(FILENAME).map(&:strip).map {|it| it.split(',').map {|it| to_command(it)}}
end

def main
    cmds_1, cmds_2 = read_inputs
    spaces_1 = get_all_spaces(cmds_1)
    spaces_2 = get_all_spaces(cmds_2)

    puts spaces_1.intersection(spaces_2).min_by { |space| space.split(",").map(&:to_i).map(&:abs).reduce(&:+)}
end

main
