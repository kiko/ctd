#! /usr/bin/env ruby
#
# CTD: Collaborative ToDo
#
require 'readline'
require 'optparse'
require 'json'
require 'pp'

RC_FILE = 'todo.json'

module User
  class << self
    def name
      `git config --get user.name`.chomp
    end

    def email
      `git config --get user.email`.chomp
    end
  end
end

class Note < Struct.new(:content, :author, :time, :childs, :done, :priority)
  include User

  def initialize(content, author = nil, time = Time.now.to_i,
                 childs = [], done = nil, priority = nil)
    self.content  = content
    self.author   = author || User.name
    self.time     = time
    self.childs   = childs
    self.done     = done
    self.priority = priority

    unless childs.empty?
      self.childs.map! do |note|
        self.class.new(note['content'],
                       note['author'],
                       note['time'],
                       note['childs'],
                       note['done'],
                       note['priority'],
                       )
      end
    end
  end

  def archive
    self.done = Time.now.to_i
  end

  def to_json
    { content:  content,
      author:   author,
      time:     time,
      childs:   childs,
      done:     done,
      priority: priority,
    }.to_json
  end
end

class Notes
  include User
  attr_reader :notes, :original

  def initialize(file = RC_FILE, options)
    @options = options
    begin
      json = File.read(file)
    rescue
      puts "No todo entry found. Create your first one with 'ctd -a'"
      json = template
    end

    @original = JSON.parse(json)

    @notes = []
    @original['todo']['notes'].each do |note|
      @notes << Note.new(note['content'],
                         note['author'],
                         note['time'],
                         note['childs'],
                         note['done'],
                         note['priority'],
                         )
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

  def archive(id)
    get(id).archive
  end

  def get(id)
    parent, child = id
    return child ? @notes[parent].childs[child] : @notes[parent]
  end

  # TODO: Add indents for child items
  def list(list = @notes, parent_id = nil, options)
    sorted = list.sort_by{ |n| n.priority }
    sorted.each_with_index do |note, i|
    # self.sort_by(:priority).each_with_index do |note, i|
      next if note.done && !options[:all]

      prefix = parent_id ? "#{parent_id}." : ''
      author = options[:user] ? " by #{User.name}" : ''
      puts "#{prefix}#{i+1}. #{note.content}#{author} [#{note.priority}]"

      unless note.childs.empty?
        self.list(note.childs, i+1, options)
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

options = {:user => false,
           :all  => false,
          }
$0 = "#{__FILE__} #{ARGV.join(' ')}"
op = OptionParser.new{|o|
  o.on('-a', '--add', 'add new item'){ options[:add] = true }
  o.on('-c', '--child Parent_ID', Integer, 'add child item under parent'){ |id| options[:add] = id-1 }
  o.on('-D', '--remove ID', 'remove an item'){ |id| options[:remove] = id }
  o.on('-d', '--done ID', 'archive an item'){ |id| options[:archive] = id }
  o.on('-u', '--user', 'show username with list'){ options[:user] = true }
  o.on('-A', '--all', 'show all includes archived'){ options[:all] = true }
  o.on('-p', '--priority Num', Integer, 'give priority an item'){ |p| options[:priority] = p }
  o.on_tail('-h', '--help', 'Show this help'){ puts o; exit }
}
op.parse!(ARGV)

@notes = Notes.new

def remove_or_archive(meth, id, options)
  id = id.to_s.split('.').map!{|s| s.to_i - 1}
  @notes.send(meth, id)
  @notes.save
  @notes.list(options)
  exit
end

if id = options[:remove]
  remove_or_archive(:remove, id, options)
end

if id = options[:archive]
  remove_or_archive(:archive, id, options)
end

if options[:add]
  while line = Readline.readline('text> ', true)
    break if line.empty? or line == 'q'

    note = Note.new(line)

    if options[:add].kind_of? Integer
      id = options[:add]
      parent = @notes.notes[id]
      parent.childs << note
    else
      @notes.add(note)
    end

    line = Readline.readline('Priority> ', true)

    priority = line.empty? ? 3 : line.to_i
    note.priority = priority

    @notes.save

    @notes.list(options)
    puts "Added. To finish press 'q' or enter key"
  end
  exit
end

@notes.list(options)
