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

  def blackjack_check

    @dealer_total = calculate_hand_total(session[:dealer_cards])
    @player_total = calculate_hand_total(session[:player_cards])

    if @player_total == 21 && @dealer_total == 21
      @success = "Both players get Blackjack. Keep your money."
      @show_hit_or_stay_buttons = false
    elsif @player_total == 21
      @success = "Blackjack! #{session[:player_name]} wins!"
      @show_hit_or_stay_buttons = false
    elsif @dealer_total == 21
      @error =  "Dealer got Blackjack. Dealer wins."
      @show_hit_or_stay_buttons = false
    end
  end

  def compare_total

    blackjack_check

    if @player_total > 21
      @error = "#{session[:player_name]} busted." 
    elsif @dealer_total > 21
      @success = "Dealer busted! #{session[:player_name]} wins!"
    elsif @player_total > @dealer_total
      @success = "#{session[:player_name]} wins with #{@player_total} over #{@dealer_total}!"
    else
      @error = "#{session[:player_name]} loses with #{@player_total} compared to Dealer's #{@dealer_total}."
    end
  end

  before do
    @show_hit_or_stay_buttons = true
    @show_dealer_hit_button = false
    @show_dealer_hand = true
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

  @show_dealer_hand = false

  blackjack_check

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].shift
  @show_dealer_hand = false

  if calculate_hand_total(session[:player_cards]) == 21
    @show_hit_or_stay_buttons = false
    @show_dealer_hit_button = true
  elsif calculate_hand_total(session[:player_cards]) > 21
    @show_hit_or_stay_buttons = false
    compare_total
  end

  erb :game
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false
 
  if calculate_hand_total(session[:dealer_cards]) < 17
    @show_dealer_hit_button = true
  elsif (17..20).include?(calculate_hand_total(session[:dealer_cards]))
    @show_hit_or_stay_buttons = false
    compare_total
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].shift
  
  if calculate_hand_total(session[:dealer_cards]) < 17
    @show_hit_or_stay_buttons = false
    @show_dealer_hit_button = true
  elsif (17..21).include?(calculate_hand_total(session[:dealer_cards]))
    @show_hit_or_stay_buttons = false
    compare_total
  else
    @show_hit_or_stay_buttons = false
    compare_total
  end

  erb :game
end