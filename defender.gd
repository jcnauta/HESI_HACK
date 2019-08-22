extends TextEdit

signal num_input

var numkey_actions = []
var num_so_far = 0

func _ready():
  self.text = str(num_so_far)
  for num in 10:
    numkey_actions.append("p" + str(num))
  
func _input(event):
  for numkey_idx in len(numkey_actions):
    if event.is_action_pressed(numkey_actions[numkey_idx]):
      if num_so_far < 10:
        num_so_far = num_so_far * 10 + numkey_idx
  if event.is_action_pressed("reset_num_input"):
    num_so_far = 0
  elif event.is_action_pressed("confirm_num_input"):
    emit_signal("num_input", num_so_far)
    num_so_far = 0
  self.text = str(num_so_far)
  