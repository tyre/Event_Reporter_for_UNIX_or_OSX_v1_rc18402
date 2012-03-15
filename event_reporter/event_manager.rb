require "csv"
require "json"
require "xmlsimple"
require "sunlight"
require "./attendee"
require "ap"
class EventManager
  DEFAULT_HEADERS=[" ",'regdate','first_name','last_name','email_address',
    'homephone','street','city','state','zipcode']
  VALID_EXTENTIONS = ["txt","csv","json","xml"]
  CSV_OPTIONS = {
                headers: true,
                header_converters: :symbol,
                return_headers: :true}
  OUTPUT_PATH = "output/thanks_"
  Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  attr_accessor :attendees, :file_out,:headers, :options, :output_filename,
                :input_filename, :output_type

  def initialize(file_in='event_attendees.csv', options = CSV_OPTIONS)
    self.options = options
    self.headers = DEFAULT_HEADERS
    self.input_filename
  end

  def open_and_read_file
    @file = CSV.open(self.input_filename, self.options)
    set_headers()
    self.attendees = @file.collect do |line|
      if not line.header_row?
        Attendee.new(line.to_hash)
      end
    end
  end

  def set_headers
    @file.rewind
    headers = @file.shift
    self.headers = headers.fields.collect { |field| field.downcase }
  end

  def output_filename=(filename)
    self.output_type = parse_filename(filename)
    @output_filename = filename
    open_output_file(self.output_type)
  end

  def parse_filename(filename)
    puts "parsing #{filename}"
    if filename_is_valid?(filename)
      filename.split(".").last
    else
      raise "Unsupported filename! Valid formats: #{VALID_EXTENTIONS}"
    end
  end

  def filename_is_valid?(filename)
    match = filename.match(/\.(?<extention>\w+)/)
    VALID_EXTENTIONS.include?(match[:extention])
  end

  def open_output_file(type)
    case type
      when "csv"
        self.file_out = CSV.open(self.output_filename, 'w')
      when "json"
        self.file_out = File.open(self.output_filename, 'w')
      when "txt"
      when "xml"
        self.file_out = XmlSimple.new({"OutputFile" => @output_filename,
          "KeyAttr" => "email_address"})
    end
  end

  def output_data(queue)
    self.send("output_#{self.output_type}",queue)
  end

  def output_xml(queue)
    attendee_hash = hashify_all_attendees(queue)
    self.file_out.xml_out(attendee_hash)
  end

  def output_json(queue)
    attendee_hash = hashify_all_attendees(queue)
    ap attendee_hash.to_json
    self.file_out << JSON[attendee_hash]
    self.file_out.close
  end

  def output_txt(queue)
    puts "Stop being lazy. Type 'print queue', press enter,"
    " then copy and paste that sheeeeeeet into your own file."
  end

  def hashify_all_attendees(queue)
    hash = {"headers" => self.headers}
    hash["attendees"] = queue.collect do |attendee|
      attendee.attr_hash
    end
  end

  def output_csv(queue)
    if self.file_out
      self.file_out << self.headers
      queue.each do |attendee|
        self.file_out << attendee.attr_array
      end
    end
    self.file_out.close
  end

end

#script
e =EventManager.new