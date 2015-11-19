require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'superman'

get '/form' do
  erb :form
end

post '/myaction' do
  params['username']
  params['favcolor']
end

get '/message' do
  "Hello, world!"
end

get '/nested' do
  redirect '/form'
end



