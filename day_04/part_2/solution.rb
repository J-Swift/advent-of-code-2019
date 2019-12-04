#!/usr/bin/env ruby

def good_pw(pw)
    pw = pw.to_s.split('')
    for i in 0..4 do
        return false if pw[i] > pw[i+1]
    end

    count = pw.reduce({}) do |memo, digit|
        d = memo[digit] || 0
        d += 1
        memo[digit] = d
        memo
    end
    count.values.member?(2)
end

def main
    total = 0
    for pw in 136818..685979 do
        total += 1 if good_pw(pw)
    end
    puts total
end

main
