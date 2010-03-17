require 'ctd/note'
require 'ctd/user'

RC_FILE = 'todo.json'

class Ctd
  include User
  attr_reader :notes, :original

  def initialize(file = RC_FILE, options)
    @options = options
    begin
      json = File.read(file)
    rescue Errno::ENOENT
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
    # p '------------------'
    # p @target = get(id)
    # p @notes.find{|n| n == @target}
    # p '------------------'
    @notes = sort(@notes)
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

  # TODO: make this recursive
  def get(id)
    # @notes = sort_by(@options[:sort_by])
    @notes = sort(@notes)
    parent, child = id
    return child ? @notes[parent].childs[child] : @notes[parent]
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

  # private?
  def sort(list)
    way = @options[:sort_by]
    list.sort_by{ |note| note[way] }
  end

  def list(list = @notes, parent_id = nil, level = 0)
    indent = '  ' * level
    sorted = sort(list)

    i = 0
    sorted.each do |note|
      if note.done && !@options[:all]
        p "item(#{note.content}) is exluded..."
        next # unless @options[:all]
      else
        i += 1
      end

      prefix = parent_id ? "  #{indent}#{parent_id}." : '  '

      # id = note.done ? '*  ' : "#{i}. "
      id = "#{i}. "

      puts "#{prefix}#{id}#{note.content}#{author} [#{note.priority}]"

      unless note.childs.empty? # check this earlier so we can add '+' to parent.
        self.list(note.childs, i, level + 1)
      end
    end
  end

  def author
    @options[:user] ? " by #{User.name}" : ''
  end
  # mark = parent_id ? "\s+" : "\s\s"

  def save(file = RC_FILE)
    @original['todo']['notes'] = @notes
    json = @original.to_json
    open(file, 'wb+') { |f| f.write(json)  }
  end

  def template
    {"todo"=>
      {"version" => "0.0.01",
       "notes"   => []}
    }.to_json
  end
end
