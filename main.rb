require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'superman'


helpers do
  def calculate_hand_total(cards)
    card_values = cards.map {|card| card[0]}
    total = 0
    card_values.each do |value|
      if value == 'A'
        total += 11
      elsif value.to_i == 0
        total += 10
      else
        total += value.to_i
      end
    end

    card_values.each do |value|
      if value == 'A' && total > 21
        total -= 10
      end
    end
    total
  end

  def card_image(card)
    suit = case card[1]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[0]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[0]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  before do
    @show_hit_or_stay_buttons = true
  end
end


get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do 
  if params[:player_name].empty?
    @error = "Your name is required."
    halt erb(:new_player)
  end
  
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  suits = ['D', 'H', 'S', 'C']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = cards.product(suits).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []

  2.times do
    session[:dealer_cards] << session[:deck].shift
    session[:player_cards] << session[:deck].shift
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].shift
  
  player_total = calculate_hand_total(session[:player_cards])
  if player_total == 21
    @success = "#{session[:player_name]} hit blackjack!"
    @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "#{session[:player_name]} busted!"
    @show_hit_or_stay_buttons = false
  end

  erb :game
end


post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false

  erb :game
end