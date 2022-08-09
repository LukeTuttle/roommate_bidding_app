=begin
# description: an app for roommates to bid on the rooms in the house to figure out what each one will pay for rent. 
The outcome should be that the highest bidder for each room wins that room but only pays the average of all the bids placed for that room. 
The program should function such that each roommate accesses the interface (i.e. sits at the computer) one at a time and enters their bid,
thus preventing each from knowing the bids of the other roommates and thereby gaming the system. 
At the end of the program, the winner of each room should be displayed along with their bid and the average of all bids for that room (i.e. what each roommate will pay)

challenges: 
- what if all the room averages dont add up to the overall rent amount for the house?
  - potential solution: add all the room averages up and see what the difference is between that and the total rent and display to the user what multiplier would need to 
    be applied across the board (i.e. to all room averages) in order to meet the total rent requirement.

nouns: roommate, room, rent total, house?

verbs: place bid, compute bids average, display bid winners 

attributes:
Roommate
- name

Room 
- nickname
- reicieved bids

House
- roommates
- rent total
- rooms


flow: 

greeting
get basic info (# and names of rooms and roommates, total rent amount)
solicit bids (for each and all rooms, one roommate at a time)
determine bid winners (compute bid averages)
display bid winners with rent amounts and wininng bid
notify of multiplier if total is less or more than total rent amount (raise a warning if the multiplier results in any one roommate paying more than their submitted winning bid)


=end

require 'pry-byebug'

class Auction
  attr_accessor :roommates, :house

  def initialize
    @house = House.new
    @roommates = []
  end

  def start
    clear_screen
    display_greeting
    solicit_auction_info
    solicit_bids
    determine_winning_and_avg_bids
    display_bid_winners
    display_goodbye_message
  end

  def display_greeting
    puts '===Welcome to the shared-home room auction! Lets get started with some basic information!==='
    2.times { puts '' }
  end

  def solicit_auction_info
    solicit_total_rent_amount
    solicit_room_info
    clear_screen
    solicit_roommates_info
    display_auction_info
  end

  def solicit_total_rent_amount
    puts 'What is the total rent amount for the house?:'
    usr_input = nil
    loop do
      usr_input = gets.chomp
      break if usr_input.to_i.to_s == usr_input
      puts 'Oops! Please enter intergers only with no decimals'
    end
    @house.total_rent = usr_input.to_i
    puts "House total rent = $#{@house.total_rent}"
    2.times { puts '' }
  end

  def solicit_room_info
    puts 'How many bedrooms are in the house?'
    n_rooms = nil
    loop do
      n_rooms = gets.chomp
      break if n_rooms.to_i.to_s == n_rooms
      puts 'Oops! Please enter intergers only with no decimals'
    end

    1.upto(n_rooms.to_i) do |i|
      puts "Please give a nickname to room ##{i}:"
      @house.rooms.push(Room.new(i, gets.chomp))
    end
    2.times { puts '' }
  end

  def solicit_roommates_info
    puts 'Next, lets get the name of each person who will be living at the house.'
    usr_input = nil
    loop do
      puts "Please enter a name. Type 'done' when all names have been entered:"
      usr_input = gets.chomp
      break if usr_input.downcase == 'done'
      @roommates.push(Roommate.new(usr_input))
    end
  end

  def display_auction_info
    puts '==Auction Information=='
    puts "Total house rent: $#{@house.total_rent}"
    puts ''
    puts "Rooms:"
    puts @house.rooms
    puts ''
    puts "Roommates:"
    puts @roommates
    puts "Press 'Enter' to continue."
    gets.chomp
  end

  def solicit_bids
    loop do
      if group_ready_to_begin_bid_process?
        clear_screen
        roommates_place_bids
        break
      else
        puts "I'll ask again..."
      end
    end
    display_bidding_finished_message
  end

  def display_bidding_finished_message
    clear_screen
    puts 'All bids have now been submitted!'
    puts 'The next step is to compute the bids and determine who has won each room and the corresponding rent amount.'
    puts "Press 'Enter' to compute the bids:"
    gets.chomp
  end

  def group_ready_to_begin_bid_process?
    puts "Im going to assume you're ready to begin bidding"
    true
  end

  def clear_screen
    system('clear')
  end

  def roommates_place_bids
    roommates.each_with_index do |roommate, i|
      individual_bid_turn(roommate)
      # might need to include something that assigns a roommates bids to the roommate object itself as an attribute
      display_next_bidders_turn_msg(roommate.name, roommates[i + 1].name) unless i + 1 == roommates.size
    end
  end

  def individual_bid_turn(person)
    display_bidding_instructions(person.name)
    house.rooms.each do |room|
      puts "You are now bidding on #{room}"
      room.recieve_bid(person)
    end
  end

  def display_bidding_instructions(name)
    puts "It is now #{name}'s turn. Please ensure that ONLY #{name} can see the bids being placed."
    puts ''
  end

  def display_next_bidders_turn_msg(current_bidder, next_bidder)
    puts "Thank you #{current_bidder}, you are now finshed bidding. Please notify #{next_bidder} they are next."
    puts "Press 'Enter' to clear the screen"
    system('clear') if gets.chomp
  end

  def determine_winning_and_avg_bids
    puts "Determining winning bids...."
    sleep(1)
    house.rooms.each do |room|
      room.winning_bid = room.bids.max_by(&:amount)
      room.bids_average = room.bids.map(&:amount).sum / room.bids.length
    end
    house.bid_avg_sum_total = house.rooms.map(&:bids_average).sum
  end

  def display_bid_winners
    handle_bid_sum_total_rent_discrepancy
    rent_multiplier = (house.total_rent / house.bid_avg_sum_total.to_f).round(3)
    puts '=======AUCTION RESULTS======='
    puts "The 'modified rent obligation' is what each winning bidder is now obliged to pay."
    puts ''
    house.rooms.each { |room| puts winning_bid_info_text(room, rent_multiplier) }
  end

  def winning_bid_info_text(room, rent_multiplier)
    puts "==#{room.nickname}=="
    puts "Highest bidder: #{room.winning_bid.bidder.name} | Amount: $#{room.winning_bid.amount}"
    puts "Resulting rent obligation (i.e. avg of all bids): $#{room.bids_average}"
    puts "Modified rent obligation: $#{ (room.bids_average * rent_multiplier).round(2) }"
  end

  def handle_bid_sum_total_rent_discrepancy
    dollar_amount = house.total_rent - house.bid_avg_sum_total
    multiplier = (house.total_rent / house.bid_avg_sum_total.to_f).round(3)
    display_bid_rent_discrepancy_msg(dollar_amount, multiplier)
  end

  def display_bid_rent_discrepancy_msg(dollar_amount, multiplier)
    puts 'When totaled, the average of the bids for each room does not equal the total rent amount.'
    puts 'Therefore, a multiplier will be applied to the rent amount for all rooms.'
    puts 'A multiplier less than 0 means that overall the bids were higher needed. Greater than 0 means the bids were too low to meet the total rent.'
    puts '==============='
    puts "Total rent: $#{house.total_rent}"
    puts "Shortfall/Excess: $#{dollar_amount * -1}"
    puts "Req'd multiplier to rid shortfall/excess: #{multiplier}"
    puts "Press 'Enter' to continue"
    gets.chomp
  end

  def display_goodbye_message
    puts 'That is all, more features will be added in the future such as handling a single person winning multiple rooms.'
    puts "Press 'Enter' to end the program"
    gets.chomp
  end
end

class House
  attr_accessor :rooms, :total_rent, :roommates, :bid_avg_sum_total

  def initialize
    @rooms = []
    @roommates = []
    @total_rent = nil
    @bid_avg_sum_total = nil
  end
end

class Roommate
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def to_s
    @name
  end
end

class Room
  attr_accessor :bids, :bids_average, :winning_bid, :nickname

  def initialize(room_num, nickname)
    @nickname = "Bedroom ##{room_num}: #{nickname}"
    @bids = []
    @bids_average = nil
    @winning_bid = nil
  end

  def to_s
    @nickname
  end

  def recieve_bid(bidder)
    bid = Bid.new(bidder)
    bids.push(bid)
  end
end

class Bid
  attr_accessor :amount, :bidder

  def initialize(bidder)
    @bidder = bidder
    @amount = solicit_bid
  end

  def solicit_bid
    # binding.pry
    usr_input = nil
    loop do
      puts 'Enter your bid amount:'
      usr_input = gets.chomp
      break if usr_input.to_i.to_s == usr_input

      puts 'Please enter only integers with no decimals.'
    end
    usr_input.to_i
  end

  def to_s
    puts "#{bidder}: $#{amount}"
  end
end

Auction.new.start
