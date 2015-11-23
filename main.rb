require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'superman'

BLACKJACK_AMT = 21
MIN_DEALER_HIT = 17
INITIAL_PLAYER_POT = 500

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
      if value == 'A' && total > BLACKJACK_AMT
        total -= 10
      end
    end
    total
  end

  def generate_deck
    suits = ['D', 'H', 'S', 'C']
    cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    session[:deck] = cards.product(suits).shuffle!
  end

  def deal_opening_cards
    session[:dealer_cards] = []
    session[:player_cards] = []

    2.times do
      session[:dealer_cards] << session[:deck].shift
      session[:player_cards] << session[:deck].shift
    end
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

    if @player_total == BLACKJACK_AMT && @dealer_total == BLACKJACK_AMT
      @success = "Both players get Blackjack. Keep your money."
      @show_hit_or_stay_buttons = false
    elsif @player_total == BLACKJACK_AMT
      winner!("#{session[:player_name]} got blackjack!")
    elsif @dealer_total == BLACKJACK_AMT
      loser!("Dealer got Blackjack.")
      @show_dealer_hand = true
    end
  end

  def winner!(message)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "#{session[:player_name]} wins! #{message}"
    session[:player_pot] += session[:player_bet]
  end

  def loser!(message)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @error = "#{session[:player_name]} loses. #{message}"
    session[:player_pot] -= session[:player_bet]
  end

  def tie!
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "It's a tie!"
  end

  def compare_total
    blackjack_check

    if @player_total > BLACKJACK_AMT
      loser!("Looks like #{session[:player_name]} busted.")
    elsif @dealer_total > BLACKJACK_AMT
      winner!("The dealer busted!")
    elsif @player_total > @dealer_total
      winner!("#{session[:player_name]} won with #{@player_total} over #{@dealer_total}!")
    elsif @dealer_total > @player_total
      loser!("The dealer won with #{@dealer_total} over #{@player_total}.")
    else
      tie!
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
    redirect '/make_bet'
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
  session[:player_pot] = INITIAL_PLAYER_POT
  redirect '/make_bet'
end

get '/make_bet' do
  erb :make_bet
end

post '/make_bet' do
  current_bet = params[:player_bet].to_i
  if current_bet <= 0 || current_bet > session[:player_pot]
    @error = "Please place a bet between $0 and $500."
    halt erb(:make_bet)
  else
    session[:player_bet] = current_bet
    redirect '/game'
  end
end

get '/game' do
  @show_dealer_hand = false

  generate_deck
  deal_opening_cards
  blackjack_check

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].shift
  
  @show_dealer_hand = false

  if calculate_hand_total(session[:player_cards]) == BLACKJACK_AMT
    @show_dealer_hand = true
    @show_dealer_hit_button = true
    @show_hit_or_stay_buttons = false
  elsif calculate_hand_total(session[:player_cards]) > BLACKJACK_AMT
    compare_total
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false
 
  if calculate_hand_total(session[:dealer_cards]) < MIN_DEALER_HIT
    @show_dealer_hit_button = true
  elsif (MIN_DEALER_HIT..BLACKJACK_AMT).include?(calculate_hand_total(session[:dealer_cards]))
    compare_total
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].shift
  
  if calculate_hand_total(session[:dealer_cards]) < MIN_DEALER_HIT
    @show_dealer_hit_button = true
  else
    compare_total
  end

  erb :game
end