require "./event_manager"
require "./string_formatter"
require "./Stack"

class EventReporter < EventManager
  DEFAULT_FILE = 'event_attendees.csv'
  attr_accessor :searches, :operators

  def initialize
    puts "Welcome to Event Reporter!"
    @queue = [Array.new]
    super
    run
  end

  def run
    while true
      print "Command: ".bold
      input = gets.chomp.downcase
      command = find_command(input)
      command_handler = "handle_#{command}".downcase
      if command
        args = args_from_input(command,input)
        execute(command_handler,args)
      end
    end
  end

  def args_from_input(command,input)
    command = command.gsub("_"," ")
    input.gsub(command,"").split
  end

  def execute(command, args)
    self.send(command, args)
  end
  def find_command(command)
    until respond_to?("handle_#{command.to_method_name}") || command.length < 1
      input_array = command.split(" ").to_a
      input_array.pop
      command = input_array.join(" ")
    end
    if command?(command)
      command.to_method_name
    end
  end

  def command?(command)
    if command.length > 0
      command.downcase
    else
      command_not_found
    end
  end

  def command_not_found
    puts "Looks like you don't know what the hell you're doing."
  end

  def handle_exit(args)
    exit
  end

  def handle_quit(args)
    exit
  end

#                                                   #
  ################# QUEUE HANDLER #################
#                                                   #
    #count, clear, print, print by

    def handle_queue_clear(args)
      @queue = [[]]
    end

    def handle_queue_count(args)
      puts self.queue.first.length
    end

    def handle_queue_print(args)
      args << "first_name"
      handle_queue_print_by(args)
    end

    def lines_format_for(lines)
      max_column_lengths = find_longest_values(lines)
      format_string = create_format_for_columns(max_column_lengths)
    end

    def create_format_for_columns(max_lengths)
      format_array = []
      max_lengths.each do |length|
        format_array << "%-#{length}s"
      end
      format_array.join(" ")
    end

    def find_longest_values(lines)
      max_column_lengths = []
      self.headers.each_with_index do |attribute, index|
        max_length = max_length_for(lines,attribute,index)
        max_column_lengths << max_length
      end
      max_column_lengths
    end

    def max_length_for(lines,attribute,index)
      max_length = @headers[index].length
      lines.each do |line|
        value = line[index]
        if value and value.length > max_length
          max_length = value.length
        end
      end
      max_length
    end

    def print_lines(lines,format)
      print_headers(format)
      lines.each_slice(10) do |line_chunks|
        line_chunks.each do |line|
          puts sprintf(format, *line)
        end
        get_input()
      end
    end

    def get_input()
      begin
        system("stty raw -echo")
        input = STDIN.getc
      ensure
        system("stty -raw echo")
      end
    end

    def print_headers(format)
      uppers = @headers.collect {|h| h.capitalize}
      puts sprintf(format, *uppers)
    end

    def handle_queue_print_by(args)
      temp_queue = self.queue.first
      sort_by = check_sort_params(args.first)
      sorted_queue = sort_queue_by(temp_queue,sort_by)
      self.queue = sorted_queue
      sorted_lines = collect_lines_from(sorted_queue)
      format = lines_format_for(sorted_lines)
      print_lines(sorted_lines, format)
    end

    def collect_lines_from(queue_instance)
      if queue_instance
        queue_instance.collect do |attendee|
          attributes = attendee.attr_array
          attributes
        end
      end
    end

    def check_sort_params(param)
      param_setter = "#{param.to_method_name}="
      if self.attendees.first.respond_to?(param_setter)
        param
      else
        "first_name"
      end
    end

    def sort_queue_by(queue, criteria)
      attribute_index = headers.index(criteria.downcase)
      queue.sort do |a,b|
        a.attr_array[attribute_index].casecmp(b.attr_array[attribute_index])
      end
    end

    def handle_queue_save_to(args)
      begin
        self.output_filename = args.first
        self.output_data(queue.first)
      end
    end

  #                                                    #
    ################## LOAD HANDLER ##################
  #                                                    #

  def handle_load(args)
    self.input_filename =  args.any? ? args.first : DEFAULT_FILE
    open_and_read_file()
  end

  #                                                    #
    ################## HELP HANDLER ##################
  #                                                    #

  def handle_help(args)
    if !args.any?
      handle_help_all
    else
      method = "handle_help_#{args.join('_')}"
      if respond_to? (method)
        self.send(method)
      else
        puts "I don't know how to do #{args.join(" ")}"
      end
    end
  end

  def handle_help_all

    help_methods = self.methods.select do |method|
      method.to_s.start_with?('handle_help_') &&
      method.to_s != 'handle_help_all'
    end

    help_methods.each do |method|
      self.send(method,nil)
    end
  end

  def handle_help_help(args)
    puts "help [command]".bold
    puts "\tOutput a description of how to use the specific command."
  end

  def handle_help_load(args)
    puts "load [filename]".bold
    puts "\tLoads given CSV file, or event_attendees.csv if no filename"
  end

  def handle_help_queue_count(args)
    puts "queue count".bold
    puts "\tOutputs the number of attendees in the current queue"
  end

  def handle_help_queue_clear(args)
    puts "queue clear".bold
    puts "\tEmpties the queue of past searches."
  end

  def handle_help_queue_print(args)
    puts "queue print".bold
    puts "\tPrints out a data table of the most recent search."
  end

  def handle_help_queue_print_by_attribute(args)
    puts "queue print by <attribute>".bold
    puts "\tPrints the most recent data sorted by specified attribute."
  end

  def handle_help_queue_save_to_filename(args)
    puts "queue save to filename.csv".bold
    puts "\tExports current queue to specified filename as a CSV"
  end

  #                                                    #
    ################## FIND HANDLER ##################
  #                                                    #

  def handle_find(input)
    self.searches = parse_search_params(input)
    self.operators = parse_operators(input[1..-1])
    self.queue = combine_searches().to_a.first
  end

  def parse_search_params(input)
    input = input.join(" ").gsub(/[\(\)]/, "")
    input.split(/ and | or /).collect do |search|
      search = search.split
      attribute = search.first
      search_params = search[1..-1]
      search_params = clean_params(attribute, search_params)
      find_attributes(attribute, search_params)
    end
  end

  def clean_params(attribute, params)
    params.collect do |param|
      AttendeeCleaner.clean_attribute(attribute,param)
    end
  end

  def parse_operators(input)
    input.select do |word|
      word == 'and' || word == 'or'
    end
  end

  def find_attributes(attr_name, attributes)
    attendees.select do |attendee|
      attendee.respond_to?(attr_name) &&
      attributes.include?(attendee.send(attr_name))
    end
  end



  def combine_searches
    found = [searches.first]
    operators.each_with_index do |operator, index|
      if operator == "or"
        found << searches[index+1]
        ap searches[index]
      else
        subtract(found, searches[index])
      end
    end
    found
  end

  def subtract(set, to_subtract)
    set = Set[set.to_a]
    to_subtract = Set[to_subtract.to_a]
    (set - to_subtract).to_a
  end

  #                                                    #
    ################## RANDOM STUFF ##################
  #                                                    #

  def queue=(val)
    @queue.unshift val
  end

  def queue
    @queue
  end

end

class String
  def to_method_name
    temp = self.gsub(" ","_")
    temp.downcase
  end
end

e = EventReporter.new















