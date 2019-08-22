extends Node2D

signal nnode_hacked
signal nnode_patched
signal nnode_defended

var progress = 0.0
var defend_progress = 0.0
var hacking = false
var defending = false
var hacked = false
var immune = false
var decay_factor = 0.08
var defended = false
var defended_factor = 1.0
var min_hack_time = 2.0
var max_hack_time = 4.0
var hack_time
var simultaneous_hacks = 0
var defend_time
var defended_decay_factor = 0.2
var hacked_neighbors = []
var defended_neighbors = []
var row_and_col
var node_id
var twin = null
var is_goal = false
var goal_style = StyleBoxFlat.new()
var goal_hacked_style = StyleBoxFlat.new()
var normal_style = StyleBoxFlat.new()

var hack_signal_target
var hack_signal_target_method

func _ready():
  pass

func setup(row_and_col, node_id, target, callback_press, callback_hacked, callback_patched, callback_defended):
  set_node_id(node_id)
  hack_time =  min_hack_time + randf() * (max_hack_time - min_hack_time)
  defend_time = hack_time
  goal_style.set_bg_color(Color("#173"))
  goal_hacked_style.set_bg_color(Color("#713"))
  normal_style.set_bg_color(Color("#111"))
#warning-ignore:return_value_discarded
#  $Button.connect("button_up", target, callback_press, [self.hacking])
  hack_signal_target = target
  hack_signal_target_method = callback_press
#warning-ignore:return_value_discarded
  $Button.connect("button_up", self, "toggle_hack")
  $Button.set("custom_styles/normal", normal_style)
#warning-ignore:return_value_discarded
  self.connect("nnode_hacked", target, callback_hacked)
  self.connect("nnode_patched", target, callback_patched)
  self.connect("nnode_defended", target, callback_defended)
  self.row_and_col = row_and_col
  update_hackbar()
  update_defbar()

func set_node_id(node_id):
  self.node_id = node_id
  $ID.text = str(node_id)

func set_pairwise(letter):
  $Pairwise.text = letter

func set_twin(node):
  twin = node

func set_goal():
  is_goal = true
  $Button.set("custom_styles/normal", goal_style)

func update_hackbar():
  $hackbar.set("rect_size", Vector2($hackbar.get("rect_size").x, \
                                        $Button.get("rect_size").y * progress / hack_time))
func update_defbar():
  $defbar.set("rect_size", Vector2($defbar.get("rect_size").x, \
                                        $Button.get("rect_size").y * defend_progress / defend_time))

func finalize_hack():
  hacked = true
  hacking = false
  progress = hack_time
  $hackbar.color = Color(1, 0, 0, 1)
  if is_goal:
    $Button.set("custom_styles/normal", goal_hacked_style)
  emit_signal("nnode_hacked", self)

func set_patched():
  immune = true
  $hackbar.set("color", Color("#666"))
  immune = true
  progress = hack_time
  emit_signal("nnode_patched", self)

func finalize_defense():
  defended = true
  defended_factor = 0.5
  defending = false
  defend_progress = defend_time
  $defbar.color = Color(0.1, 0.3, 1, 1)
  emit_signal("nnode_defended", self)

func set_hacked():
  finalize_hack()
  update_hackbar()

func set_defended():
  finalize_defense()
  update_defbar()
  
func toggle_hack():
  if hacking:
    hacking = false
    hack_signal_target.call(hack_signal_target_method, false)
  elif not hacked and len(hacked_neighbors) != 0:
    hacking = true
    hack_signal_target.call(hack_signal_target_method, true)

func toggle_defend(node_id):
  if node_id == twin.node_id:
#    if defending:
#      defending = false
#    el
    if not defended: # and len(defended_neighbors) != 0:
      defending = true

func _process(delta):
  if hacking:
    progress += defended_factor * delta * pow(float(len(hacked_neighbors)), 1.5) / simultaneous_hacks
    print(simultaneous_hacks)
    if progress >= hack_time:
      finalize_hack()
    update_hackbar()
  elif progress > 0.0 and not immune: #and progress != hack_time  # make hacked-status permanent
    if hacked:
      progress -= decay_factor * hack_time * delta  # previously hacked nodes slowly decay; getting patched/scanned etc.
    else:
      progress -= delta  # manually stop hacking and remove traces
    if progress <= 0.0:
      progress = 0.0
      if hacked:  # make this node unhackable; disallow hacking node twice
        set_patched()
    $hackbar.set("rect_size", Vector2($hackbar.get("rect_size").x, \
                                        $Button.get("rect_size").y * progress / hack_time))
  if defending:
    defend_progress += delta #* pow(float(len(defended_neighbors)), 2.0)
    if defend_progress >= defend_time:
      finalize_defense()
    update_defbar()
  elif defend_progress > 0.0: #and defend_progress != defend_time:
    defend_progress -= defended_decay_factor * delta
    if defend_progress <= 0.0:
      defended = false
      defend_progress = 0.0
    $defbar.set("rect_size", Vector2($defbar.get("rect_size").x, \
                                        $Button.get("rect_size").y * defend_progress / defend_time))