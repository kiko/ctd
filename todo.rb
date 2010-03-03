#! /usr/bin/env ruby
require 'readline'
require 'optparse'
require 'json'
require 'pp'


RC_FILE = 'todo.json'

module User
  class << self
    def name
      `git config --get user.name`
    end

    def email
      `git config --get user.email`
    end
  end
end

class Note < Struct.new(:content, :author, :time, :childs)
  include User

  def initialize(content, author = nil, time = Time.now.to_i, childs = [])
    self.content = content
    self.author  = author || User.name
    self.time    = time
    self.childs  = childs

    unless childs.empty?
      self.childs.map! do |note|
        Note.new(note['content'],
                 note['author'],
                 note['time'],
                 note['childs'],)
      end
    end
  end

  def to_json
    { content: content,
      author:  author,
      time:    time,
      childs:  childs,
    }.to_json
  end
end

class Notes
  attr_reader :notes, :original

  def initialize(file = RC_FILE)
    json = File.read(file || template)
    @original = JSON.parse(json)

    @notes = []
    @original['todo']['notes'].each do |note|
      @notes << Note.new(note['content'],
                         note['author'],
                         note['time'],
                         note['childs'],)
    end
  end

  def add(note)
    @notes << note
  end

  def remove(id)
    parent, child = id
    if child
      @notes[parent].childs.delete_at(child)
    else
      @notes.delete_at(parent)
    end
  end

  def list(list = @notes, parent_id = nil)
    list.each_with_index do |note, i|
      prefix = parent_id ? "#{parent_id}." : ''
      puts "#{prefix}#{i+1}. #{note.content} by #{note.author}"

      unless note.childs.empty?
        self.list(note.childs, i+1)
      end
    end
  end

  def save(file = RC_FILE)
    @original['todo']['notes'] = @notes
    open(file, 'wb+') { |f| f.write @original.to_json }
  end

  def template
    {"todo"=>
      {"version" => "0.0.01",
       "notes"   => []}
    }.to_json
  end
end

notes = Notes.new

options = {}

$0 = "#{__FILE__} #{ARGV.join(' ')}"
op = OptionParser.new{|o|
  o.on('-a', '--add', 'add new item'){ options[:add] = true }
  o.on('-c', '--child Parent_ID', Integer, 'add child item under parent'){ |id| options[:add] = id-1 }
  o.on('-d', '--remove ID', 'remove an item'){ |id| options[:remove] = id }
  o.on_tail('-h', '--help', 'help'){ puts o; exit }
}

op.parse!(ARGV)

if id = options[:remove]
  id = id.to_s.split('.').map!{|s| s.to_i - 1}
  notes.remove(id)
  notes.save
  notes.list
  exit
end

if options[:add]
  while line = Readline.readline('text> ', true)
    break if line.empty? or line == 'q'

    note = Note.new(line)

    if options[:add].kind_of? Integer
      id = options[:add]
      parent = notes.notes[id]
      parent.childs << note
    else
      notes.add(note)
    end

    notes.save

    notes.list
    puts "Added. To finish press 'q' or enter key"
  end
  exit
end

notes.list
