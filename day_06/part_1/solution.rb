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

def number_of_orbits(orbital, previous=0)
    previous + orbital.children.reduce(0) do |memo, child|
        memo + number_of_orbits(child, previous + 1)
    end
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

    puts number_of_orbits(orbitals['COM'])
end

main
