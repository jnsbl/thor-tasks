require "json"
require "tree"

module Dockit
  class Cmd < Thor
    desc "desc_list INPUT_DIR", "Generate JSON files with uuCommand description for uuDocKit"
    def desc_list(input_dir)
      puts "Not implemented!"
      exit 1
    end

    desc "flow INPUT_DIR", "Convert indent-based text file into JSON file with uuCommand flow"
    option :tabs, :alias => "-t", :type => :boolean, :default => false,
      :desc => "Use tabs instead of spaces? (default: use spaces)"
    option :indent, :alias => "-n", :banner => "SIZE", :type => :numeric,
      :desc => "Indent size, i.e. number of spaces/tabs to treat as one indent level (default: 2 spaces or 1 tab)"
    option :output, :alias => "-o", :banner => "OUTPUT_DIR",
      :desc => "Directory to write the converted files to (default: the same as INPUT_DIR)"
    def flow(input_dir)
      opts = options.dup
      opts[:indent] = opts[:tabs] ? 1 : 2 if opts[:indent].nil?
      opts[:header] = "Happy day scenario"
      opts[:input_dir] = input_dir
      opts[:output_dir] = input_dir if opts[:output_dir].nil?

      converter = Converter.new(opts)
      converter.convert
    end

    desc "alt_scenarios INPUT_DIR", "Convert indent-based text file into JSON file with uuCommand alternative scenarios"
    option :tabs, :alias => "-t", :type => :boolean, :default => false,
      :desc => "Use tabs instead of spaces? (default: use spaces)"
    option :indent, :alias => "-n", :banner => "SIZE", :type => :numeric,
      :desc => "Indent size, i.e. number of spaces/tabs to treat as one indent level (default: 2 spaces or 1 tab)"
    option :output, :alias => "-o", :banner => "OUTPUT_DIR",
      :desc => "Directory to write the converted files to (default: the same as INPUT_DIR)"
    option :force, :alias => "-f", :type => :boolean, :default => false,
      :desc => "Overwrite output files? (default: no)"
    def alt_scenarios(input_dir)
      opts = options.dup
      opts[:indent] = opts[:tabs] ? 1 : 2 if opts[:indent].nil?
      opts[:header] = "Alternative scenarios"
      opts[:input_dir] = input_dir
      opts[:output_dir] = input_dir if opts[:output_dir].nil?

      converter = SectionConverter.new(opts)
      converter.convert
    end

    desc "error_list INPUT_DIR", "Extract list of errors from uuCommand alternative scenarios"
    option :tabs, :alias => "-t", :type => :boolean, :default => false,
      :desc => "Use tabs instead of spaces? (default: use spaces)"
    option :indent, :alias => "-n", :banner => "SIZE", :type => :numeric,
      :desc => "Indent size, i.e. number of spaces/tabs to treat as one indent level (default: 2 spaces or 1 tab)"
    option :output, :alias => "-o", :banner => "OUTPUT_DIR",
      :desc => "Directory to write the converted files to (default: the same as INPUT_DIR)"
    option :force, :alias => "-f", :type => :boolean, :default => false,
      :desc => "Overwrite output files? (default: no)"
    def error_list(input_dir)
      opts = options.dup
      opts[:indent] = opts[:tabs] ? 1 : 2 if opts[:indent].nil?
      opts[:input_dir] = input_dir
      opts[:output_dir] = input_dir if opts[:output_dir].nil?

      extractor = ErrorListExtractor.new(opts)
      extractor.extract
    end
  end
end

class Converter
  def initialize(options = {})
    @options = options
    @indent = if @options[:tabs]
                "\t" * @options[:indent]
              else
                " " * @options[:indent]
              end
    @header = @options[:header]
    @regex = Regexp.new("^\s*")
  end

  def convert
    input_dir = File.expand_path(@options[:input_dir])
    Dir.chdir(input_dir) do
      Dir.glob("*.txt").each do |input_file|
        convert_one(input_file)
      end
    end
  end

  protected

  def convert_one(input_file)
    root = read_input_data(input_file)

    uu5 = text_to_uu5(root)

    base_name = File.basename(input_file, ".txt")
    write_to_file(base_name, uu5)
  end

  def text_to_uu5(data)
    uu5 = "<uu5string/>\n"
    uu5 << "<UU5.Bricks.Section header='#{@options[:header]}'>\n"
    uu5 << "<UU5.Bricks.Ol>\n"
    data.children.each do |row|
      uu5 << row.to_uu5
    end
    uu5 << "</UU5.Bricks.Ol>\n"
    uu5 << "</UU5.Bricks.Section>\n"
    return uu5
  end

  def new_node(indent_level=nil, siblings=nil, content=nil)
    if indent_level.nil?
      return TNode.new("ROOT")
    else
      return TNode.new("ROW_#{indent_level}_#{siblings}", content.strip)
    end
  end

  def read_input_data(input_file)
    root = new_node
    lines = File.new(input_file).readlines
    previous_indent_level = 0
    indent_level_last_nodes = {}

    lines.each_with_index do |line, idx|
      indent_level = indent_level_for(line)

      if indent_level == 0
        siblings = root.children.size
        node = new_node(indent_level, siblings, line)
        root << node
      else
        parent = indent_level_last_nodes[(indent_level-1).to_s]
        siblings = parent.children.size
        node = new_node(indent_level, siblings, line)
        parent << node
      end

      indent_level_last_nodes[indent_level.to_s] = node
      previous_indent_level = indent_level
    end

    root
  end

  def indent_level_for(string)
    leading_indent = string.scan(@regex).first.size
    indent_level = leading_indent / @indent.size
    indent_level
  end

  def print_tree(root)
    block = lambda do |node, prefix|
      puts "#{prefix} #{node.content}"
    end
    root.print_tree(root.node_depth, nil, block)
  end

  def write_to_file(base_name, file_data)
    output_file = File.join(@options[:output_dir], "#{base_name}.xml")

    if File.file?(output_file) && !@options[:force]
      puts "WARNING: File #{output_file} already exists, skipping"
      return
    end

    File.open(output_file.to_s, "w") do |f|
      f.write(file_data)
    end

    puts "Converted into #{output_file}"
  end
end

class TNode < Tree::TreeNode
  def to_uu5
    if has_children?
      uu5 = "<UU5.Bricks.Li>\n"
      uu5 << "#{content}\n"
      uu5 << "<UU5.Bricks.Ol>\n"
      children.each do |child|
        uu5 << child.to_uu5
      end
      uu5 << "</UU5.Bricks.Ol>\n"
      uu5 << "</UU5.Bricks.Li>\n"
    else
      uu5 = "<UU5.Bricks.Li>#{content}</UU5.Bricks.Li>\n"
    end
    uu5
  end
end

class SectionConverter < Converter
  def new_node(indent_level=nil, siblings=nil, content=nil)
    if indent_level.nil?
      return SectionNode.new("ROOT")
    else
      return SectionNode.new("ROW_#{indent_level}_#{siblings}", content.strip)
    end
  end

  def text_to_uu5(data)
    uu5 = "<uu5string/>\n"
    uu5 << "<UU5.Bricks.Section header='#{@options[:header]}'>\n"
    data.children.each do |row|
      uu5 << row.to_uu5
    end
    uu5 << "</UU5.Bricks.Section>\n"
    return uu5
  end
end

class SectionNode < Tree::TreeNode
  def to_uu5
    if has_children?
      uu5 = "<UU5.Bricks.Section header='#{content.strip}'>\n"
      uu5 << "<UU5.Bricks.Ol>\n"
      children.each do |child|
        uu5 << child.to_uu5
      end
      uu5 << "</UU5.Bricks.Ol>\n"
      uu5 << "</UU5.Bricks.Section>\n"
    else
      text = content.sub(/(\S+\/E\d{3}-\S+)/, "<UU5.Bricks.Code>\\1</UU5.Bricks.Code>")
      text = text.gsub(/({[^}]+})/, "<UU5.Bricks.Code>\\1</UU5.Bricks.Code>")
      uu5 = "<UU5.Bricks.Li>#{text}</UU5.Bricks.Li>\n"
    end
    uu5
  end
end

class ErrorListExtractor < Converter
  def initialize(options)
    super(options)
  end

  def extract
    input_dir = File.expand_path(@options[:input_dir])
    Dir.chdir(input_dir) do
      Dir.glob("*.txt").each do |input_file|
        extract_one(input_file)
      end
    end
  end

  protected

  def extract_one(input_file)
    data = File.new(input_file).read

    uu5 = text_to_uu5(data)

    base_name = File.basename(input_file, ".txt")
    write_to_file("#{base_name}-errors", uu5)
  end

  def text_to_uu5(data)
    uu5 = "<uu5string/>\n"
    uu5 << "<UU5.Bricks.Section header='Seznam chyb'>\n"
    uu5 << "<UuApp.DesignKit.UuCmdErrorList data='<uu5json/>[\n"
    errors = find_errors(data)
    errors.each_with_index do |error, idx|
      error_uu5 = error.to_uu5
      error_uu5 += "," unless (idx+1)==errors.size
      error_uu5 += "\n"
      uu5 << error_uu5
    end
    uu5 << "]'/>\n"
    uu5 << "</UU5.Bricks.Section>\n"
    return uu5
  end

  def find_errors(data)
    errors = Hash.new { |hash, key| hash[key] = [] }
    data.scan(/(\S+\/E\d{3}-\S+) (?:- )?\("([^"]+)"\)/) do |code, msg|
      messages = errors[code]
      messages << msg
      errors[code] = messages
    end
    result = errors.collect do |code, messages|
      CmdError.new(code, messages)
    end
    return result
  end
end

class CmdError
  attr_reader :code, :messages

  def initialize(code, messages)
    @code = code
    @messages = messages || []
  end

  def <<(msg)
    @messages << msg
  end

  def to_uu5
    messages_uu5 = "<uu5string/><UU5.Bricks.Ul>"
    messages.each do |msg|
      text = msg.gsub(/({[^}]+})/, "<UU5.Bricks.Code>\\1</UU5.Bricks.Code>")
      messages_uu5 << "<UU5.Bricks.Li>#{text}</UU5.Bricks.Li>"
    end
    messages_uu5 << "</UU5.Bricks.Ul>"
    return %Q(  ["<uu5string/><UU5.Bricks.Code>#{code}</UU5.Bricks.Code>", "Error", "#{messages_uu5}", null])
  end
end
