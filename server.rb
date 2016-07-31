require 'sinatra'
require 'logger'

require './lib/memory_config'
require './lib/config_handler'
require './lib/proxy_handler'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

config = MemoryConfig.new

# Initialize
ProxyHandler.set_path(File.dirname(__FILE__))
ProxyHandler.set_logger(logger)

# Config routes
get '/cfg' do ConfigHandler.get_all(config, request, params) end
get '/cfg/:key' do ConfigHandler.get(config, request, params) end
post '/cfg/:key' do ConfigHandler.post(config, request, params) end
delete '/cfg/:key' do ConfigHandler.delete(config, request, params) end

# Proxy routes
get '*' do ProxyHandler.handle(config, request, params) end
post '*' do ProxyHandler.handle(config, request, params) end
put '*' do ProxyHandler.handle(config, request, params) end
patch '*' do ProxyHandler.handle(config, request, params) end
delete '*' do ProxyHandler.handle(config, request, params) end
options '*' do ProxyHandler.handle(config, request, params) end
