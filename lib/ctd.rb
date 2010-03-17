require 'ctd/note'
require 'ctd/user'

RC_FILE = 'todo.json'
class Ctd
  include User
  attr_reader :notes, :original

  def initialize(file = RC_FILE, options)
    @options = options
    # expensive ?
    begin
      json = File.read(file)
    rescue
      puts "No todo entry found. Create your first one with 'ctd -a'"
      json = template
    end

    @original = JSON.parse(json)

    @notes = []
    @original['todo']['notes'].each do |note|
      @notes << Note.new(note)
    end
  end

  def add(note)
    @notes << note
  end

  def remove(id)
    p '------------------'
    p @target = get(id)
    p @notes.find{|n| n == @target}
    p '------------------'
    parent, child = id
    @notes = sort_by(@options[:sort_by])
    if child
      @notes[parent].childs.delete_at(child)
    else
      @notes.delete_at(parent)
    end
  end

  def archive(id)
    get(id).archive
  end

  # TODO: make this recursive
  def get(id)
    @notes = sort_by(@options[:sort_by])
    # @notes.sort_by(@options[:sort_by])
    parent, child = id
    return child ? @notes[parent].childs[child] : @notes[parent]
  end

  def sort_by(attr)
    @notes.sort_by{ |n| n[attr] }
    # self.sort_by{ |n| n[attr] }
  end

  def edit(id)
    note = get(id)
    p note
    data = {}
    puts note.content
    # data[:content] = input
    puts note.priority
    # data[:priority] = input
    puts data
    # note.update(data)
  end

  # TODO: Mess!
  def list(list = @notes, parent_id = nil)
    # list = @notes = sort_by(options[:sort_by])
    way = @options[:sort_by]
    sorted = list.sort_by{ |note| note[way] }

    sorted.each_with_index do |note, i|
      next if note.done && !@options[:all]

      prefix = parent_id ? "\s\s#{parent_id}." : ''
      # mark = parent_id ? "\s+" : "\s\s"
      author = @options[:user] ? " by #{User.name}" : ''
      puts "\s\s#{prefix}#{i+1}. #{note.content}#{author} [#{note.priority}]"

      unless note.childs.empty? # check this earlier so we can add '+' to parent.
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
