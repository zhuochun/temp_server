require 'json'

class ConfigHandler
  KEYS = %w(latency status).freeze
  HEADER = {"Content-Type" => "application/json"}.freeze

  def self.get_all(config, request, params)
    data = {}

    KEYS.each do |key|
      data[key] = config.get(key.to_sym).map do |d|
        { path: d[:path].source, value: d[:value] }
      end
    end

    [200, HEADER, JSON.generate(data)]
  end

  def self.get(config, request, params)
    return err_400("Invalid key: #{params['key']}") unless valid_key?(params['key'])

    data = config.get(params['key'].to_sym)
    data = data.map { |d| { path: d[:path].source, value: d[:value] } }

    [200, HEADER, JSON.generate(data)]
  end

  def self.post(config, request, params)
    return err_400("Invalid key: #{params['key']}") unless valid_key?(params['key'])

    data = parse_body(request)
    return err_400("Missing params: path/value") unless valid_params?(data, %w(path value))

    config.set(params['key'].to_sym, Regexp.new(data['path']), data['value'])

    [204, HEADER, ""]
  end

  def self.delete(config, request, params)
    return [404, {}, "Invalid key: #{params['key']}"] unless valid_key?(params['key'])

    data = parse_body(request)
    return [404, {}, "Missing params: path"] unless valid_params?(data, %w(path))

    config.del(params['key'].to_sym, Regexp.new(data['path']))

    [204, HEADER, ""]
  end

  def self.err_400(msg)
    [400, HEADER, JSON.generate({ error: msg })]
  end

  def self.valid_key?(key)
    KEYS.include?(key)
  end

  def self.valid_params?(params, keys)
    return false if params.nil? || params.empty?
    invalid = keys.any? { |key| params[key].nil? || params[key].empty? }
    return !invalid
  end

  def self.parse_body(request)
    begin
      text = request.body.read
      JSON.parse(text)
    rescue JSON::ParserError
      nil
    end
  end
end
