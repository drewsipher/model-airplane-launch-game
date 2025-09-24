extends Node

## EconomyManager singleton for handling money, purchases, and progression
## Manages the game's economy system and player progression

signal money_changed(new_amount: int)
signal money_earned(amount: int, reason: String)
signal money_spent(amount: int, item: String)

var current_money: int = 100  # Starting money
var total_earned: int = 0
var total_spent: int = 0

# Distance to money conversion rate (money per meter)
var distance_reward_rate: float = 1.0

func _ready():
	print("EconomyManager initialized with starting money: ", current_money)

func earn_money(distance: float, reason: String = "Flight distance") -> int:
	var earned = calculate_distance_reward(distance)
	current_money += earned
	total_earned += earned
	
	money_earned.emit(earned, reason)
	money_changed.emit(current_money)
	
	print("Earned ", earned, " money for ", reason, ". Total: ", current_money)
	return earned

func spend_money(amount: int, item: String = "Purchase") -> bool:
	if current_money >= amount:
		current_money -= amount
		total_spent += amount
		
		money_spent.emit(amount, item)
		money_changed.emit(current_money)
		
		print("Spent ", amount, " money on ", item, ". Remaining: ", current_money)
		return true
	else:
		print("Insufficient funds. Need ", amount, " but have ", current_money)
		return false

func calculate_distance_reward(distance: float) -> int:
	# Base reward plus bonus for longer distances
	var base_reward = int(distance * distance_reward_rate)
	var bonus = int(distance / 10.0)  # Bonus for every 10 meters
	return base_reward + bonus

func get_money() -> int:
	return current_money

func can_afford(amount: int) -> bool:
	return current_money >= amount

func get_total_earned() -> int:
	return total_earned

func get_total_spent() -> int:
	return total_spent

func reset_economy() -> void:
	current_money = 100
	total_earned = 0
	total_spent = 0
	money_changed.emit(current_money)
	print("Economy reset to starting values")