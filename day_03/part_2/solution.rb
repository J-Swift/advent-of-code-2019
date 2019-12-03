#!/usr/bin/env ruby

FILENAME='input.txt'

require 'set'

def to_command(text)
    dir = text[0]
    amount = text.scan(/\d+/).first.to_i
    {dir: dir, num: amount}
end

def get_all_spaces(cmds)
    curx = cury = steps = 0
    cmds.reduce([Set.new, {}]) do |memo, cmd|
        case cmd[:dir]
        when "L"
            a, b = curx - 1, curx - cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |x|
                steps += 1
                space = "#{x},#{cury}"
                memo[0] << space
                memo[1][space] = steps if memo[1][space].nil?
            end
            curx -= cmd[:num]
        when "R"
            a, b = curx + 1, curx + cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |x|
                steps += 1
                space = "#{x},#{cury}"
                memo[0] << space
                memo[1][space] = steps if memo[1][space].nil?
            end
            curx += cmd[:num]
        when "D"
            a, b = cury - 1, cury - cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |y|
                steps += 1
                space = "#{curx},#{y}"
                memo[0] << space
                memo[1][space] = steps if memo[1][space].nil?
            end
            cury -= cmd[:num]
        when "U"
            a, b = cury + 1, cury + cmd[:num]
            ([a, b].min..[a, b].max).to_a.each do |y|
                steps += 1
                space = "#{curx},#{y}"
                memo[0] << space
                memo[1][space] = steps if memo[1][space].nil?
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
    spaces_1, lookups_1 = get_all_spaces(cmds_1)
    spaces_2, lookups_2 = get_all_spaces(cmds_2)

    shortest = spaces_1.intersection(spaces_2).min_by { |space| lookups_1[space] + lookups_2[space] }
    puts shortest
    puts lookups_1[shortest] + lookups_2[shortest]
end

main
