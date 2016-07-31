require 'erb'
require 'json'

HANDLERS = [
  ->(context, config, request) do
    context[:method] = request.request_method.downcase

    paths = request.path.split('/')
    paths.shift() # remove the start ""
    filename = paths.pop()

    context[:path] = paths
    context[:file] = filename
  end,

  ->(context, config, request) do
    path = request.path

    matchers = config.get(:latency)
    match = matchers.find { |m| m[:path] =~ path }

    if match
      context[:latency] = match
      context[:latency_sec] = match[:value].to_i / 1000.0

      ProxyHandler.logger.info { "#{path}, Latency: #{context[:latency_sec]}s" }

      sleep context[:latency_sec]
    end
  end,

  ->(context, config, request) do
    path = request.path

    matchers = config.get(:status)
    match = matchers.find { |m| m[:path] =~ path }

    if match
      context[:status] = match
      context[:status_code] = match[:value]
    else
      context[:status_code] = '200'
    end

    ProxyHandler.logger.info { "#{path}, Status: #{context[:status_code]}" }
  end
]

class ProxyHandler
  HEADER = { 'Content-Type' => 'application/json' }.freeze

  def self.handle(config, request, params)
    content_type = request.content_type || 'application/json'.freeze
    unless content_type.include?('application/json')
      return err(400, HEADER, "Invalid content_type: #{content_type}")
    end

    context = {}
    # Pre-handlers
    HANDLERS.each { |h| h.call(context, config, request) }

    # Resolve to JSON/ERB file
    files = resolve_files(context)
    file = files.find { |f| File.exists?(f) }
    return err(404, HEADER, "Proxy response not found: #{files}") if file.nil?

    # Read file
    content = read_file(file)
    header = { 'Content-Type' => content_type }
    body = content

    # Output
    if content.is_a?(Hash) && content.key?('header') && content.key?('body')
      header = header.merge(content['header'])
      body = content['body']
    end

    [context[:status_code].to_i, header, JSON.generate(body)]
  end

  def self.err(code, header, msg)
    [code, header, JSON.generate({ error: msg })]
  end

  def self.resolve_files(context)
    # Resolve to JSON/ERB file
    extnames = ['.json', '.json.erb']
    status_codes = [context[:status_code]]
    status_codes << nil if context[:status_code] == '200'
    methods = [context[:method]]
    methods << nil if context[:method] == 'get'

    # _get_200.json, _get.json, .json
    suffixs = methods.flat_map do |method|
      status_codes.flat_map do |code|
        extnames.map do |ext|
          suffix = [method, code].compact.join('_')
          "#{suffix.empty? ? '' : '_'}#{suffix}#{ext}"
        end
      end
    end

    suffixs.map { |suffix| path_to(context[:path], "#{context[:file]}#{suffix}") }
  end

  def self.read_file(file)
    text = File.read(file)
    text = file.end_with?('.erb') ? ERB.new(text).result(binding) : text

    JSON.parse(text)
  rescue => e
    logger.info { "Read #{file}, Exception: #{e}" }

    {}
  end

  def self.set_logger(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end

  def self.set_path(path)
    @path = File.join(path, "static")
  end

  def self.path_to(paths, file)
    File.join(@path, paths, file)
  end
end
