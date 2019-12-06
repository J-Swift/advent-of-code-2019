#!/usr/bin/env ruby

FILENAME='input.txt'

class Orbital
    attr_accessor :children, :parent, :name

    def initialize(name)
        self.name = name
        self.parent = nil
        self.children = []
    end

    def add_child(child)
        child.parent = self
        self.children << child
    end
end

def read_inputs
    File.readlines(FILENAME).map(&:strip)
end

def parents_with_distances(orbital, parents={}, total=0)
    parent = orbital.parent
    if parent.nil?
        return parents
    end

    parents[parent.name] = total
    parents_with_distances(parent, parents, total+1)
end

def main
    lines = read_inputs

    orbitals = lines.reduce({}) do |memo, line|
        orbitee, orbiter = line.split(')')
        orbitee_orb = memo[orbitee] || Orbital.new(orbitee)
        orbiter_orb = memo[orbiter] || Orbital.new(orbiter)

        orbitee_orb.add_child(orbiter_orb)

        memo[orbitee] = orbitee_orb
        memo[orbiter] = orbiter_orb
        memo
    end

    you_parents = parents_with_distances(orbitals['YOU'])
    san_parents = parents_with_distances(orbitals['SAN'])

    require 'set'
    common = you_parents.keys.to_set & san_parents.keys.to_set
    best = common.min_by { |it| you_parents[it] + san_parents[it] }

    puts "#{best}: #{you_parents[best] + san_parents[best]}"
end

main
