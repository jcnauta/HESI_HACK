extends Node2D

var NNode = preload("res://NNode.tscn")

var left_offset = 40
var top_offset = 40
var nodes = []
var neighbor_dict = {}
var edge_list = []
var init_test_edges = [[[0,0],[0,3]],
                       [[2,2],[2,5]]]
var p_row_connect = 0.7
var p_col_connect = 0.7
var node_spacing = 80
var cols = 10
var rows = 4
var start_time_left = 80.0
var time_left = start_time_left
var defense_bonus_time = 2.0
var hacker_points = 0
var game_over = false
var letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
var nr_of_goals = 0
var goals_reached = 0

func _ready():
  randomize()
  create_everything()
  
func create_everything():
  spawn_nodes()
  create_random_edges()
#  create_grid_edges()
  draw_edges()
  add_nodes_to_tree()
  init_hack()
  init_def()
  set_goal_node([len(nodes) - 2, len(nodes[len(nodes) - 1]) - 2])
  set_goal_node([1, 5])
  set_goal_node([3, 1])

func node_idx_to_node(idx):
  return nodes[idx % len(nodes)][floor(idx / len(nodes))]
  
func spawn_nodes():
  nodes = []
  neighbor_dict = {}
  edge_list = []
  var node_id = 0
  for row in range(rows):
    nodes.append([])
    for col in range(cols):
      var new_node = NNode.instance()
      # node is added to tree later to ensure edges are drawn first.
      new_node.setup([row, col], node_id, self, \
          "press_callback", "hacked_callback", "patched_callback", "defended_callback")
      $right_bar/defender.connect("num_input", new_node, "toggle_defend")
      node_id += 1
      new_node.position = Vector2(left_offset + col * node_spacing, top_offset + row * node_spacing)
      nodes[len(nodes) - 1].append(new_node)
  # Set pairwise letters on the nodes, randomly assigned
  var letter_idx = 0
  var all_node_idxs = []
  for node_idx in node_id:
    all_node_idxs.append(node_idx)
  while len(all_node_idxs) > 0:
    var rand_elem_1 = randi() % len(all_node_idxs)
    var rand_node_idx_1 = all_node_idxs[rand_elem_1]
    all_node_idxs.remove(rand_elem_1)
    var rand_elem_2 = randi() % len(all_node_idxs)
    var rand_node_idx_2 = all_node_idxs[rand_elem_2]
    all_node_idxs.remove(rand_elem_2)
    var n1 = node_idx_to_node(rand_node_idx_1)
    var n2 = node_idx_to_node(rand_node_idx_2)
    n1.set_pairwise(letters[letter_idx])
    n2.set_pairwise(letters[letter_idx])
    n1.set_twin(n2)
    n2.set_twin(n1)
    letter_idx += 1

func add_nodes_to_tree():
  for row in range(rows):
    for col in range(cols):
      self.add_child(nodes[row][col])
      
func set_goal_node(row_and_col):
  var row
  var col
  if row_and_col == null:
    row = randi() % len(nodes)
    col = randi() % len(nodes[row])
  else:
    row = row_and_col[0]
    col = row_and_col[1]   
  if row < len(nodes) and col < len(nodes[row]):
    nodes[row][col].set_goal()
    nr_of_goals += 1
  else:
    print("Warning: trying to set node as goal but out of bounds.")

func create_test_edges():
  for pair in init_test_edges:
    add_edge(pair[0], pair[1])

func create_grid_edges():
  for edge_row in rows:
    for edge_col in cols:
      # connect this edge to the ones on the right and below
      if edge_col < cols - 1:
        add_edge([edge_row, edge_col], [edge_row, edge_col + 1])
      if edge_row < rows - 1:
        add_edge([edge_row, edge_col], [edge_row + 1, edge_col])
# left-top = right-bottom diagonals
#      if edge_row < rows - 1 and edge_col < cols - 1:
#        add_edge([edge_row, edge_col], [edge_row + 1, edge_col + 1])

func create_random_edges():
  # does not guarantee full connectivity
  for edge_row in rows:
    # Add random long edge
    var src_long = randi() % cols
    var tgt_long = randi() % cols
    while abs(src_long - tgt_long) <= 2:
      tgt_long = randi() % cols
    add_edge([edge_row, src_long], [edge_row, tgt_long])
  for edge_row in rows:  
    for edge_col in cols:
      # connect this edge to the ones on the right and below
      if edge_col < cols - 1:
        # add edges between neighboring columns with some probability
        if ((edge_row == 0 or edge_row == rows - 1) and \
            (edge_col == 0 or edge_col == cols - 1)) \
            or randf() < p_col_connect:
          add_edge([edge_row, edge_col], [edge_row, edge_col + 1])
      if edge_row < rows - 1:
        if ((edge_row == 0 or edge_row == rows - 1) and \
            (edge_col == 0 or edge_col == cols - 1)) \
            or randf() < p_row_connect:
          add_edge([edge_row, edge_col], [edge_row + 1, edge_col])

func add_edge(node_idxs1, node_idxs2):
  if not neighbor_dict.has(node_idxs1):
    neighbor_dict[node_idxs1] = []
  if not neighbor_dict[node_idxs1].has(node_idxs2):
    neighbor_dict[node_idxs1].append(node_idxs2)
  if not neighbor_dict.has(node_idxs2):
    neighbor_dict[node_idxs2] = []
  if not neighbor_dict[node_idxs2].has(node_idxs1):
    neighbor_dict[node_idxs2].append(node_idxs1)

func draw_edges():
  var src_offset = Vector2(25, 25)
  var tgt_offset = Vector2(25, 25)
  var right_offset = Vector2(15, 0)
  var left_offset = Vector2(-15, 0)
  
  for src in neighbor_dict.keys():
    var src_row = src[0]
    var src_col = src[1]
    var src_node = nodes[src_row][src_col]
    var tgts = neighbor_dict[src]
    for tgt in tgts:
      var tgt_row = tgt[0]
      var tgt_col = tgt[1]
      var tgt_node = nodes[tgt_row][tgt_col]
      var line = Line2D.new()
      edge_list.append(line)
      line.width = 3
      line.default_color = Color("#2c3")
      self.add_child(line)
      if abs(tgt_col - src_col) <= 1:
        line.add_point(src_node.position + src_offset)
        line.add_point(tgt_node.position + tgt_offset)
      else:
        var vert_around_offset = Vector2(0, -35)
        var side_offset = Vector2(15, 0)
        if tgt_col > src_col: # from left to right
          pass
        elif src_col > tgt_col:
          side_offset *= -1   
        line.add_point(src_node.position + src_offset + side_offset)
        line.add_point(src_node.position + src_offset + side_offset + vert_around_offset)
        side_offset *= -1
        line.add_point(tgt_node.position + tgt_offset + side_offset + vert_around_offset)     
        line.add_point(tgt_node.position + tgt_offset + side_offset)

 
func press_callback(hack_not_cancel):
  for node_row in nodes:
    for node in node_row:
      if hack_not_cancel:
      # inform all nodes that hacking slows down
        node.simultaneous_hacks += 1
      else:
      # inform all nodes that hacking speeds up
        node.simultaneous_hacks -= 1

# Inform neighbors that they have a new compromised neighbor
func hacked_callback(nnode):
  # Let all nodes know there is one less simultaneous hack going on
  for node_row in nodes:
    for node in node_row:
      node.simultaneous_hacks -= 1
  var idxs = nnode.row_and_col
  if neighbor_dict.has(idxs):
    var neigh_idxs = neighbor_dict[idxs]
    for idx in neigh_idxs:
      var neigh = nodes[idx[0]][idx[1]]
      neigh.hacked_neighbors.append(nnode)
  if nnode.is_goal:
    goals_reached += 1
    if goals_reached == nr_of_goals:
      print("All goald reached, hackers win!")
      game_over = true
  
func patched_callback(nnode):
  var idxs = nnode.row_and_col
  if neighbor_dict.has(idxs):
    var neigh_idxs = neighbor_dict[idxs]
    for idx in neigh_idxs:
      var neigh = nodes[idx[0]][idx[1]]
      var idx_in_neighbors = neigh.hacked_neighbors.find(nnode)
      if idx_in_neighbors == -1:
        print("Bug detected: trying to patch neighbor that was not considered hacked")
      else:
        neigh.hacked_neighbors.remove(idx_in_neighbors)
  
func defended_callback(nnode):
  # hackers get a biiiit more time to disincentivize defending everything
  time_left += defense_bonus_time
#  var idxs = nnode.row_and_col
#  if neighbor_dict.has(idxs):
#    var neigh_idxs = neighbor_dict[idxs]
#    for idx in neigh_idxs:
#      var neigh = nodes[idx[0]][idx[1]]
#      neigh.defended_neighbors.append(nnode)

func init_hack():
  var node = nodes[0][0]
  node.set_hacked()
  for node_row in nodes:
    for node in node_row:
      node.simultaneous_hacks += 1
  
func init_def():
  var node = nodes[3][5]
  node.set_defended()

func remove_nodes_and_edges():
  for node_row in nodes:
    for node in node_row:
      node.queue_free()
    node_row.clear()
  nodes.clear()
  for edge in edge_list:
    edge.queue_free()
  edge_list.clear()

func _process(delta):
  if not game_over:
    if time_left <= 0.0:
      print("TIME UP, DEFENSE WINS!")
      game_over = true
      time_left = 0.0
    else:
      time_left -= delta
    $right_bar/countdown.set("text", "%10.3f" % time_left)
    
func _input(event):
  if event.is_action_pressed("reset_game"):
    remove_nodes_and_edges()
    time_left = start_time_left
    create_everything()