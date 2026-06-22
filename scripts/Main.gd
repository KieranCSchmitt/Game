extends Node3D

const GAME_NAME := "Crown & Cinder"
const PORT := 37172
const MIN_PLAYERS := 3
const MAX_PLAYERS := 6
const BOARD_R := 5
const HEX_SIZE := 1.05
const TARGET_SCORE := 78
const TURN_LIMIT := 12
const RESOURCES := ["gold", "food", "timber", "iron", "population", "influence", "faith"]
const START_RESOURCES := {"gold":18, "food":16, "timber":12, "iron":7, "population":8, "influence":3, "faith":4}

const FACTIONS := [
	{"name":"Ashen Crown", "archetype":"fallen human kingdom", "color":"#ad302e"},
	{"name":"Briar Oath", "archetype":"forest-bound wardens", "color":"#3f8f5b"},
	{"name":"Graveforge", "archetype":"dwarven necro-smiths", "color":"#b47c3a"},
	{"name":"Moon Reliquary", "archetype":"silver cult knights", "color":"#7b7fd4"},
	{"name":"Hollow Choir", "archetype":"faith-haunted mages", "color":"#9d55b8"},
	{"name":"Saltwolf March", "archetype":"raiders and privateers", "color":"#378fa3"}
]

const TERRAIN := {
	"field":{"name":"Field", "color":"#536640", "height":0.14, "income":{"food":2, "population":1}},
	"forest":{"name":"Blackwood", "color":"#243525", "height":0.28, "income":{"timber":2, "faith":1}},
	"marsh":{"name":"Marsh", "color":"#273c37", "height":0.06, "income":{"food":1, "faith":1}},
	"stone":{"name":"Ruin-Stone", "color":"#494842", "height":0.36, "income":{"iron":1, "gold":1}},
	"village":{"name":"Village", "color":"#6e523c", "height":0.22, "income":{"gold":1, "population":2, "influence":1}},
	"ash":{"name":"Ashland", "color":"#332f2e", "height":0.10, "income":{"faith":1}},
	"water":{"name":"Drowned Hex", "color":"#203844", "height":-0.05, "income":{"food":1}}
}

const STRUCTURES := {
	"keep":{"name":"Keep", "cost":{}, "income":{"gold":2, "influence":1}, "score":9, "hp":12},
	"farm":{"name":"Corpsefield Farm", "cost":{"timber":3, "population":1}, "income":{"food":4}, "score":3, "hp":5},
	"mill":{"name":"Blackwood Mill", "cost":{"gold":2, "population":1}, "income":{"timber":4}, "score":3, "hp":5},
	"mine":{"name":"Grave-Iron Mine", "cost":{"timber":3, "gold":2, "population":1}, "income":{"iron":3, "gold":1}, "score":4, "hp":6},
	"market":{"name":"Cinder Market", "cost":{"timber":4, "gold":4}, "income":{"gold":4, "influence":1}, "score":5, "hp":5},
	"shrine":{"name":"Wound Shrine", "cost":{"timber":2, "gold":2, "population":1}, "income":{"faith":3, "influence":1}, "score":4, "hp":5},
	"tower":{"name":"Bonewatch Tower", "cost":{"timber":4, "iron":2, "gold":2}, "income":{"influence":1}, "score":5, "hp":7},
	"foundry":{"name":"Cinder Foundry", "cost":{"iron":4, "timber":3, "gold":4, "population":1}, "income":{"iron":3, "gold":2}, "score":7, "hp":8}
}

const UNITS := {
	"lord":{"name":"Crownbound Lord", "cost":{}, "hp":11, "armor":4, "skill":4, "attack":4, "range":1, "move":2, "score":8},
	"levy":{"name":"Levy Mob", "cost":{"food":3, "population":1}, "hp":6, "armor":1, "skill":1, "attack":2, "range":1, "move":2, "score":2},
	"arms":{"name":"Men-at-Arms", "cost":{"gold":4, "food":2, "iron":1, "population":1}, "hp":8, "armor":3, "skill":2, "attack":3, "range":1, "move":2, "score":4},
	"longbow":{"name":"Blackwood Longbow", "cost":{"gold":3, "timber":2, "food":2, "population":1}, "hp":5, "armor":1, "skill":3, "attack":2, "range":4, "move":2, "score":4},
	"handcannon":{"name":"Sin-Eater Handcannon", "cost":{"gold":5, "iron":3, "faith":1, "population":1}, "hp":5, "armor":1, "skill":2, "attack":5, "range":3, "move":1, "score":5},
	"hexer":{"name":"Hexer of the Ninth Bell", "cost":{"gold":4, "faith":3, "population":1}, "hp":4, "armor":0, "skill":4, "attack":3, "range":3, "move":2, "score":5},
	"knight":{"name":"Grave Knight", "cost":{"gold":6, "food":3, "iron":4, "population":1}, "hp":10, "armor":5, "skill":3, "attack":5, "range":1, "move":3, "score":7}
}

const ATTACKS := {
	"cleave":{"name":"Cleave", "range_bonus":0, "damage":1.00, "skill_bonus":0.10},
	"brace":{"name":"Brace & Counter", "range_bonus":0, "damage":0.78, "skill_bonus":0.18},
	"woundline":{"name":"Woundline", "range_bonus":1, "damage":1.00, "skill_bonus":0.16},
	"arc":{"name":"Funeral Arc", "range_bonus":2, "damage":0.86, "skill_bonus":0.05},
	"scatter":{"name":"Cinder Scatter", "range_bonus":0, "damage":1.25, "skill_bonus":-0.05},
	"hexbolt":{"name":"Hex Bolt", "range_bonus":1, "damage":1.05, "skill_bonus":0.20}
}

const WEATHER := ["clear", "fog", "rain", "ashfall", "storm"]

var peer: ENetMultiplayerPeer
var is_host := false
var invite_code := ""
var lobby := {}
var state := {}
var sealed_orders := {}
var local_orders := []
var selected_hex := ""
var selected_unit := ""
var local_id := 1
var player_name := "Host"
var phase := "menu"
var attack_kind := "woundline"
var aim_pull := 0.5
var aim_breath := 0.5
var aim_lead := 0.5

var board_root: Node3D
var prop_root: Node3D
var unit_root: Node3D
var fx_root: Node3D
var cam: Camera3D
var ui: CanvasLayer
var mat_cache := {}
var focus := Vector3.ZERO
var yaw := 0.78
var pitch := -0.85
var zoom := 16.0
var right_drag := false
var middle_drag := false
var close_view := false

var name_box: LineEdit
var ip_box: LineEdit
var code_box: LineEdit
var max_spin: SpinBox
var hud_status: RichTextLabel
var order_label: RichTextLabel
var log_label: RichTextLabel
var attack_option: OptionButton
var pull_slider: HSlider
var breath_slider: HSlider
var lead_slider: HSlider

func _ready() -> void:
	randomize()
	build_world_nodes()
	ui = CanvasLayer.new()
	add_child(ui)
	wire_multiplayer()
	show_menu()

func wire_multiplayer() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func build_world_nodes() -> void:
	board_root = Node3D.new()
	board_root.name = "Board"
	add_child(board_root)
	prop_root = Node3D.new()
	prop_root.name = "Props"
	add_child(prop_root)
	unit_root = Node3D.new()
	unit_root.name = "Units"
	add_child(unit_root)
	fx_root = Node3D.new()
	fx_root.name = "Atmosphere"
	add_child(fx_root)
	cam = Camera3D.new()
	cam.name = "TableCamera"
	cam.fov = 42.0
	cam.current = true
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.rotation_degrees = Vector3(-55, -35, 0)
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 8, 0)
	fill.light_color = Color(0.45, 0.58, 0.78)
	fill.light_energy = 0.7
	fill.omni_range = 28
	add_child(fill)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.018, 0.017, 0.016)
	add_child(env)

func clear_ui() -> void:
	for c in ui.get_children():
		c.queue_free()

func panel(title: String) -> VBoxContainer:
	clear_ui()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var p := PanelContainer.new()
	p.size = Vector2(570, 640)
	p.position = Vector2(42, 42)
	root.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	p.add_child(box)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 34)
	box.add_child(t)
	return box

func mk_label(text: String, size := 16) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	return l

func mk_button(text: String, callable: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.pressed.connect(callable)
	return b

func show_menu() -> void:
	phase = "menu"
	render_title_board()
	var b := panel("Crown & Cinder")
	b.add_child(mk_label("The Black Octagon — peer-hosted dark fantasy strategy for 3–6 players.", 18))
	name_box = LineEdit.new()
	name_box.placeholder_text = "Player name"
	name_box.text = player_name
	b.add_child(name_box)
	max_spin = SpinBox.new()
	max_spin.min_value = MIN_PLAYERS
	max_spin.max_value = MAX_PLAYERS
	max_spin.value = MAX_PLAYERS
	max_spin.prefix = "Max players "
	b.add_child(max_spin)
	b.add_child(mk_button("Host Direct Game", Callable(self, "host_game")))
	b.add_child(HSeparator.new())
	ip_box = LineEdit.new()
	ip_box.placeholder_text = "Host IP address"
	ip_box.text = "127.0.0.1"
	b.add_child(ip_box)
	code_box = LineEdit.new()
	code_box.placeholder_text = "Private invite code"
	b.add_child(code_box)
	b.add_child(mk_button("Join Game", Callable(self, "join_game")))
	b.add_child(mk_label("Internet hosting usually needs UDP port forwarding on port %d. LAN hosting can use the host machine's local IP." % PORT, 14))

func host_game() -> void:
	reset_net()
	player_name = name_box.text.strip_edges()
	if player_name == "":
		player_name = "Host"
	is_host = true
	local_id = 1
	invite_code = make_code()
	lobby = {}
	lobby[1] = make_lobby_record(1, player_name, 0)
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, int(max_spin.value) - 1)
	if err != OK:
		show_message("Host failed", "Could not open UDP port %d. Error %d." % [PORT, err])
		return
	multiplayer.multiplayer_peer = peer
	phase = "lobby"
	show_lobby("Hosting on port %d. Invite code: %s" % [PORT, invite_code])

func join_game() -> void:
	reset_net()
	player_name = name_box.text.strip_edges()
	if player_name == "":
		player_name = "Guest"
	invite_code = code_box.text.strip_edges().to_upper()
	is_host = false
	local_id = 0
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip_box.text.strip_edges(), PORT)
	if err != OK:
		show_message("Join failed", "Could not create client. Error %d." % err)
		return
	multiplayer.multiplayer_peer = peer
	phase = "lobby"
	show_lobby("Connecting...")

func _on_connected_to_server() -> void:
	local_id = multiplayer.get_unique_id()
	rpc_join_request.rpc_id(1, invite_code, player_name)

func _on_connection_failed() -> void:
	show_message("Connection failed", "Check host IP, firewall, invite code, and port forwarding.")

func _on_server_disconnected() -> void:
	reset_net()
	show_message("Disconnected", "The host closed the table.")

func _on_peer_connected(id: int) -> void:
	if is_host:
		show_lobby("Peer %d connected. Waiting for private code." % id)

func _on_peer_disconnected(id: int) -> void:
	if not is_host:
		return
	if lobby.has(id):
		lobby.erase(id)
	if state.has("players") and state["players"].has(id):
		state["players"][id]["alive"] = false
		state["events"].push_front("A ruler vanished from the table; their realm remains as ruins.")
	if phase == "game":
		broadcast_state(false)
	else:
		broadcast_lobby()

func reset_net() -> void:
	if peer != null:
		peer.close()
	peer = null
	multiplayer.multiplayer_peer = null
	is_host = false
	local_id = 1
	lobby = {}
	sealed_orders = {}
	local_orders = []
	selected_unit = ""
	selected_hex = ""
	state = {}

func make_code() -> String:
	var chars := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var c := ""
	for i in range(6):
		c += chars[randi_range(0, chars.length() - 1)]
	return c

func make_lobby_record(id: int, pname: String, index: int) -> Dictionary:
	var f: Dictionary = FACTIONS[index % FACTIONS.size()]
	return {"id":id, "name":pname, "faction":f["name"], "archetype":f["archetype"], "color":f["color"]}

@rpc("any_peer", "call_remote", "reliable")
func rpc_join_request(code: String, pname: String) -> void:
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	if phase != "lobby":
		rpc_join_denied.rpc_id(sender, "Match already started.")
		return
	if code.strip_edges().to_upper() != invite_code:
		rpc_join_denied.rpc_id(sender, "Wrong invite code.")
		return
	if lobby.size() >= MAX_PLAYERS:
		rpc_join_denied.rpc_id(sender, "The table is full.")
		return
	var join_name := pname
	if join_name == "":
		join_name = "Guest"
	lobby[sender] = make_lobby_record(sender, join_name, lobby.size())
	rpc_join_ok.rpc_id(sender, sender)
	broadcast_lobby()

@rpc("authority", "call_remote", "reliable")
func rpc_join_ok(id: int) -> void:
	local_id = id

@rpc("authority", "call_remote", "reliable")
func rpc_join_denied(reason: String) -> void:
	show_message("Join denied", reason)
	if peer != null:
		peer.close()

func broadcast_lobby() -> void:
	if not is_host:
		return
	var msg := "Waiting for players. %d/%d seated." % [lobby.size(), MAX_PLAYERS]
	rpc_lobby.rpc(lobby, invite_code, msg)
	rpc_lobby(lobby, invite_code, msg)

@rpc("authority", "call_remote", "reliable")
func rpc_lobby(new_lobby: Dictionary, code: String, msg: String) -> void:
	lobby = new_lobby.duplicate(true)
	invite_code = code
	phase = "lobby"
	show_lobby(msg)

func show_lobby(msg: String) -> void:
	render_title_board()
	var b := panel("Private Table")
	b.add_child(mk_label(msg, 16))
	b.add_child(mk_label("Invite code: %s\nPort: %d" % [invite_code, PORT], 20))
	var ids := lobby.keys()
	ids.sort()
	for id in ids:
		var p: Dictionary = lobby[id]
		b.add_child(mk_label("%s — %s (%s)" % [p.get("name", "Player"), p.get("faction", "Faction"), p.get("archetype", "")], 15))
	if is_host:
		b.add_child(mk_button("Start Match", Callable(self, "start_match")))
	b.add_child(mk_button("Leave Table", Callable(self, "leave_to_menu")))

func show_message(title: String, msg: String) -> void:
	var b := panel(title)
	b.add_child(mk_label(msg, 17))
	b.add_child(mk_button("Back", Callable(self, "leave_to_menu")))

func leave_to_menu() -> void:
	reset_net()
	show_menu()

func start_match() -> void:
	if not is_host:
		return
	if lobby.size() < MIN_PLAYERS:
		show_lobby("Need at least %d players." % MIN_PLAYERS)
		return
	state = make_state(lobby)
	sealed_orders = {}
	local_orders = []
	phase = "game"
	broadcast_state(true)

func broadcast_state(reset_orders: bool) -> void:
	if not is_host:
		return
	rpc_state.rpc(state, reset_orders)
	rpc_state(state, reset_orders)

@rpc("authority", "call_remote", "reliable")
func rpc_state(new_state: Dictionary, reset_orders: bool) -> void:
	state = new_state.duplicate(true)
	phase = "game"
	if reset_orders:
		local_orders = []
		selected_unit = ""
		selected_hex = ""
	show_game()

func make_state(players: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := {"turn":1, "weather":WEATHER.pick_random(), "hexes":{}, "units":{}, "players":{}, "events":["The Black Octagon rises out of the mud."], "next_unit":1, "winner":0}
	for q in range(-BOARD_R, BOARD_R + 1):
		for r in range(-BOARD_R, BOARD_R + 1):
			if abs(q) <= BOARD_R and abs(r) <= BOARD_R and abs(q + r) <= BOARD_R + 2:
				var key := hex_key(q, r)
				var roll := rng.randf()
				var terr := "field"
				if roll < 0.12:
					terr = "forest"
				elif roll < 0.22:
					terr = "marsh"
				elif roll < 0.34:
					terr = "stone"
				elif roll < 0.43:
					terr = "village"
				elif roll < 0.51:
					terr = "ash"
				elif roll < 0.57:
					terr = "water"
				s["hexes"][key] = {"q":q, "r":r, "terrain":terr, "owner":0, "structure":"", "hp":0, "burn":0, "flood":0, "ash":0}
	var starts := [[0,-BOARD_R], [BOARD_R,-BOARD_R], [BOARD_R,0], [0,BOARD_R], [-BOARD_R,BOARD_R], [-BOARD_R,0]]
	var ids := players.keys()
	ids.sort()
	for i in range(ids.size()):
		var pid := int(ids[i])
		var lp: Dictionary = players[pid]
		var rec := {"id":pid, "name":lp.get("name", "Player"), "faction":lp.get("faction", "Realm"), "archetype":lp.get("archetype", ""), "color":lp.get("color", "#ad302e"), "resources":START_RESOURCES.duplicate(true), "alive":true, "score":0, "oaths":{}, "betrayals":0}
		s["players"][pid] = rec
		var start := nearest_hex(s, int(starts[i][0]), int(starts[i][1]))
		claim_start(s, pid, start)
		add_unit_to_state(s, pid, "lord", start)
		add_unit_to_state(s, pid, "levy", start)
		add_unit_to_state(s, pid, "longbow", start)
	update_scores(s)
	return s

func nearest_hex(s: Dictionary, q: int, r: int) -> String:
	var best := ""
	var best_dist := 999
	for key in s["hexes"].keys():
		var h: Dictionary = s["hexes"][key]
		var d := hex_distance(q, r, int(h["q"]), int(h["r"]))
		if d < best_dist:
			best_dist = d
			best = key
	return best

func claim_start(s: Dictionary, pid: int, key: String) -> void:
	var h: Dictionary = s["hexes"][key]
	h["owner"] = pid
	h["terrain"] = "village"
	h["structure"] = "keep"
	h["hp"] = STRUCTURES["keep"]["hp"]
	for n in neighbors(key):
		if s["hexes"].has(n):
			s["hexes"][n]["owner"] = pid

func add_unit_to_state(s: Dictionary, pid: int, unit_type: String, hex: String) -> String:
	var unit_def: Dictionary = UNITS[unit_type]
	var uid := "u%d" % int(s["next_unit"])
	s["next_unit"] = int(s["next_unit"]) + 1
	s["units"][uid] = {"id":uid, "owner":pid, "type":unit_type, "name":unit_def["name"], "hex":hex, "hp":unit_def["hp"], "max_hp":unit_def["hp"], "armor":unit_def["armor"], "skill":unit_def["skill"], "attack":unit_def["attack"], "range":unit_def["range"], "move":unit_def["move"], "score":unit_def["score"], "wounded":false, "captured_by":0}
	return uid

func hex_key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]

func parse_hex(key: String) -> Vector2i:
	var p := key.split(",")
	return Vector2i(int(p[0]), int(p[1]))

func hex_distance(q1: int, r1: int, q2: int, r2: int) -> int:
	return int((abs(q1 - q2) + abs(q1 + r1 - q2 - r2) + abs(r1 - r2)) / 2)

func distance_keys(a: String, b: String) -> int:
	var x := parse_hex(a)
	var y := parse_hex(b)
	return hex_distance(x.x, x.y, y.x, y.y)

func neighbors(key: String) -> Array:
	var p := parse_hex(key)
	return [hex_key(p.x + 1, p.y), hex_key(p.x - 1, p.y), hex_key(p.x, p.y + 1), hex_key(p.x, p.y - 1), hex_key(p.x + 1, p.y - 1), hex_key(p.x - 1, p.y + 1)]

func axial_position(q: int, r: int) -> Vector3:
	return Vector3(HEX_SIZE * sqrt(3.0) * (float(q) + float(r) / 2.0), 0.0, HEX_SIZE * 1.5 * float(r))

func show_game() -> void:
	render_state()
	clear_ui()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var left := PanelContainer.new()
	left.position = Vector2(18, 18)
	left.size = Vector2(400, 760)
	root.add_child(left)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	left.add_child(box)
	hud_status = RichTextLabel.new()
	hud_status.bbcode_enabled = true
	hud_status.custom_minimum_size = Vector2(370, 210)
	box.add_child(hud_status)
	attack_option = OptionButton.new()
	var attack_keys := ATTACKS.keys()
	for k in attack_keys:
		attack_option.add_item(ATTACKS[k]["name"])
		attack_option.set_item_metadata(attack_option.item_count - 1, k)
	box.add_child(attack_option)
	attack_option.item_selected.connect(_attack_changed)
	pull_slider = add_slider(box, "Pull", aim_pull, Callable(self, "_pull"))
	breath_slider = add_slider(box, "Breath", aim_breath, Callable(self, "_breath"))
	lead_slider = add_slider(box, "Lead", aim_lead, Callable(self, "_lead"))
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(mk_button("Build Farm", Callable(self, "queue_build").bind("farm")))
	row.add_child(mk_button("Build Market", Callable(self, "queue_build").bind("market")))
	var row2 := HBoxContainer.new()
	box.add_child(row2)
	row2.add_child(mk_button("Recruit Levy", Callable(self, "queue_recruit").bind("levy")))
	row2.add_child(mk_button("Recruit Cannon", Callable(self, "queue_recruit").bind("handcannon")))
	var row3 := HBoxContainer.new()
	box.add_child(row3)
	row3.add_child(mk_button("Send Tribute", Callable(self, "queue_tribute")))
	row3.add_child(mk_button("Blood Oath/Betray", Callable(self, "queue_diplomacy")))
	box.add_child(mk_button("Submit Secret Orders", Callable(self, "submit_orders")))
	box.add_child(mk_button("Clear Orders", Callable(self, "clear_orders")))
	box.add_child(mk_button("Leave", Callable(self, "leave_to_menu")))
	order_label = RichTextLabel.new()
	order_label.bbcode_enabled = true
	order_label.custom_minimum_size = Vector2(370, 150)
	box.add_child(order_label)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.custom_minimum_size = Vector2(370, 220)
	box.add_child(log_label)
	update_hud()

func add_slider(parent: Node, label_text: String, value: float, cb: Callable) -> HSlider:
	parent.add_child(mk_label(label_text, 13))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = value
	s.value_changed.connect(cb)
	parent.add_child(s)
	return s

func _attack_changed(i: int) -> void:
	attack_kind = str(attack_option.get_item_metadata(i))

func _pull(v: float) -> void:
	aim_pull = v

func _breath(v: float) -> void:
	aim_breath = v

func _lead(v: float) -> void:
	aim_lead = v

func update_hud() -> void:
	if hud_status == null or state.is_empty() or not state.has("players"):
		return
	var me: Dictionary = state["players"].get(local_id, {})
	var res_text := ""
	if not me.is_empty():
		var bag: Dictionary = me.get("resources", {})
		for r in RESOURCES:
			res_text += "%s:%d  " % [r.substr(0, 3), int(bag.get(r, 0))]
	var waiting := ""
	if is_host:
		waiting = "\nSealed orders: %d/%d" % [sealed_orders.size(), alive_ids().size()]
	hud_status.text = "[b]%s[/b]\nTurn %d/%d • Weather: %s%s\nScore: %d • %s\n%s\n\n%s" % [GAME_NAME, int(state.get("turn", 1)), TURN_LIMIT, str(state.get("weather", "clear")), waiting, int(me.get("score", 0)), str(me.get("faction", "")), res_text, describe_selection()]
	var ot := "[b]Secret Orders[/b]\n"
	for o in local_orders:
		ot += "• %s\n" % order_text(o)
	if local_orders.is_empty():
		ot += "No orders queued."
	order_label.text = ot
	var lg := "[b]Table Log[/b]\n"
	for e in state.get("events", []):
		lg += "• %s\n" % str(e)
	log_label.text = lg

func describe_selection() -> String:
	if selected_unit != "" and state.get("units", {}).has(selected_unit):
		var u: Dictionary = state["units"][selected_unit]
		return "%s\nHP %d/%d • Skill %d • Armor %d • Range %d" % [u.get("name", "Unit"), int(u.get("hp", 0)), int(u.get("max_hp", 0)), int(u.get("skill", 0)), int(u.get("armor", 0)), int(u.get("range", 1))]
	if selected_hex != "" and state.get("hexes", {}).has(selected_hex):
		var h: Dictionary = state["hexes"][selected_hex]
		var structure := str(h.get("structure", ""))
		if structure == "":
			structure = "none"
		return "Hex %s • %s • Owner %s • Structure %s" % [selected_hex, TERRAIN[h.get("terrain", "field")]["name"], owner_name(int(h.get("owner", 0))), structure]
	return "Select one of your units, then choose a destination or enemy."

func order_text(o: Dictionary) -> String:
	var t := str(o.get("type", ""))
	if t == "move":
		return "Move %s to %s" % [o.get("unit", "?"), o.get("to", "?")]
	if t == "attack":
		return "%s attacks %s with %s" % [o.get("unit", "?"), o.get("target", "?"), ATTACKS[o.get("attack", "woundline")]["name"]]
	if t == "build":
		return "Build %s at %s" % [o.get("structure", "?"), o.get("hex", "?")]
	if t == "recruit":
		return "Recruit %s at %s" % [o.get("unit", "?"), o.get("hex", "?")]
	if t == "tribute":
		return "Send tribute to %s" % owner_name(int(o.get("target", 0)))
	if t == "diplomacy":
		return "Blood oath/betrayal with %s" % owner_name(int(o.get("target", 0)))
	return str(o)

func owner_name(id: int) -> String:
	if state.has("players") and state["players"].has(id):
		return str(state["players"][id].get("faction", "Realm"))
	return "Unclaimed"

func render_title_board() -> void:
	var fake := {"hexes":{}, "units":{}, "weather":"ashfall", "players":{}, "events":[]}
	for q in range(-3, 4):
		for r in range(-3, 4):
			if abs(q + r) <= 4:
				fake["hexes"][hex_key(q, r)] = {"q":q, "r":r, "terrain":"ash", "owner":0, "structure":"", "burn":0, "flood":0, "ash":1}
	var old := state
	state = fake
	render_state()
	state = old

func render_state() -> void:
	for root in [board_root, prop_root, unit_root, fx_root]:
		for c in root.get_children():
			c.queue_free()
	if state.is_empty() or not state.has("hexes"):
		return
	for key in state["hexes"].keys():
		var h: Dictionary = state["hexes"][key]
		var terrain_key := str(h.get("terrain", "field"))
		var terrain: Dictionary = TERRAIN[terrain_key]
		var pos := axial_position(int(h.get("q", 0)), int(h.get("r", 0)))
		var y := float(terrain.get("height", 0.0)) + float(h.get("flood", 0)) * 0.04
		var tile := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.radial_segments = 6
		mesh.top_radius = HEX_SIZE * 0.98
		mesh.bottom_radius = HEX_SIZE * 0.98
		mesh.height = 0.18 + y
		tile.mesh = mesh
		tile.position = pos + Vector3(0, (0.18 + y) / 2.0, 0)
		tile.rotation_degrees.y = 30
		tile.material_override = mat("terrain_" + terrain_key, Color(terrain["color"]))
		board_root.add_child(tile)
		var owner := int(h.get("owner", 0))
		if owner != 0 and state.has("players") and state["players"].has(owner):
			var ring := MeshInstance3D.new()
			var tor := TorusMesh.new()
			tor.inner_radius = HEX_SIZE * 0.72
			tor.outer_radius = HEX_SIZE * 0.79
			ring.mesh = tor
			ring.position = pos + Vector3(0, 0.24 + y, 0)
			ring.material_override = mat("owner_" + str(owner), Color(state["players"][owner]["color"]))
			board_root.add_child(ring)
		if str(h.get("structure", "")) != "":
			add_structure(str(h["structure"]), pos, y, owner)
		if terrain_key in ["forest", "stone", "village"] and randi() % 4 == 0:
			add_prop(pos, terrain_key)
		if int(h.get("burn", 0)) > 0:
			add_fire(pos)
	for uid in state.get("units", {}).keys():
		var u: Dictionary = state["units"][uid]
		if int(u.get("captured_by", 0)) != 0:
			continue
		var hkey := str(u.get("hex", ""))
		if not state["hexes"].has(hkey):
			continue
		var uh: Dictionary = state["hexes"][hkey]
		add_unit_mesh(uid, u, axial_position(int(uh["q"]), int(uh["r"])), uh)
	add_weather_fx()
	update_camera()

func mat(key: String, color: Color) -> StandardMaterial3D:
	if mat_cache.has(key):
		return mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.92
	m.metallic = 0.02
	mat_cache[key] = m
	return m

func add_structure(kind: String, pos: Vector3, y: float, owner: int) -> void:
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.radial_segments = 8
	bm.top_radius = 0.42
	bm.bottom_radius = 0.55
	bm.height = 0.7
	base.mesh = bm
	base.position = pos + Vector3(0, 0.55 + y, 0)
	base.material_override = mat("stonework", Color("#2d2926"))
	prop_root.add_child(base)
	var roof := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.radial_segments = 6
	rm.top_radius = 0.05
	rm.bottom_radius = 0.5
	rm.height = 0.38
	roof.mesh = rm
	roof.position = pos + Vector3(0, 1.08 + y, 0)
	var roof_color := "#772222"
	if state.has("players") and state["players"].has(owner):
		roof_color = state["players"][owner].get("color", "#772222")
	roof.material_override = mat("roof_" + str(owner), Color(roof_color))
	prop_root.add_child(roof)

func add_prop(pos: Vector3, terrain_key: String) -> void:
	var p := MeshInstance3D.new()
	p.position = pos + Vector3(randf_range(-0.35, 0.35), 0.35, randf_range(-0.35, 0.35))
	if terrain_key == "forest":
		var cm := CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.14
		cm.height = 0.9
		p.mesh = cm
		p.material_override = mat("bark", Color("#241815"))
	elif terrain_key == "stone":
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 0.45, 0.35)
		p.mesh = bm
		p.material_override = mat("ruin", Color("#55504b"))
	else:
		var box := BoxMesh.new()
		box.size = Vector3(0.42, 0.28, 0.42)
		p.mesh = box
		p.material_override = mat("crate", Color("#4b3124"))
	prop_root.add_child(p)

func add_fire(pos: Vector3) -> void:
	var f := OmniLight3D.new()
	f.position = pos + Vector3(0, 0.55, 0)
	f.light_color = Color(1.0, 0.28, 0.08)
	f.light_energy = 1.4
	f.omni_range = 3.0
	fx_root.add_child(f)

func add_unit_mesh(uid: String, u: Dictionary, pos: Vector3, h: Dictionary) -> void:
	var terrain_key := str(h.get("terrain", "field"))
	var y := float(TERRAIN[terrain_key]["height"])
	var group := Node3D.new()
	group.name = uid
	group.position = pos + Vector3(0, 0.55 + y, 0)
	unit_root.add_child(group)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.19
	cap.height = 0.75
	body.mesh = cap
	body.material_override = mat("unit_" + str(u.get("owner", 0)), Color(state["players"][int(u["owner"])]["color"]))
	group.add_child(body)
	var head := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.16
	head.mesh = sp
	head.position = Vector3(0, 0.55, 0)
	head.material_override = mat("skin", Color("#8b6f58"))
	group.add_child(head)
	var weapon := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 0.025
	wm.bottom_radius = 0.025
	wm.height = 0.85
	weapon.mesh = wm
	weapon.position = Vector3(0.25, 0.25, 0)
	weapon.rotation_degrees.z = 80
	weapon.material_override = mat("iron", Color("#90877a"))
	group.add_child(weapon)
	if uid == selected_unit:
		var ring := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 0.38
		tor.outer_radius = 0.45
		ring.mesh = tor
		ring.position = Vector3(0, -0.36, 0)
		ring.material_override = mat("selected", Color("#f0c678"))
		group.add_child(ring)

func add_weather_fx() -> void:
	var weather := str(state.get("weather", "clear"))
	if weather in ["fog", "ashfall", "storm"]:
		for i in range(24):
			var w := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = randf_range(0.04, 0.12)
			w.mesh = sm
			w.position = Vector3(randf_range(-12, 12), randf_range(1, 5), randf_range(-12, 12))
			w.material_override = mat("mist", Color(0.45, 0.45, 0.42, 0.45))
			fx_root.add_child(w)

func _process(_delta: float) -> void:
	update_camera()

func update_camera() -> void:
	if cam == null:
		return
	var p := pitch
	var z := zoom
	if close_view:
		p = -0.42
		z = max(7.0, zoom * 0.5)
	var dir := Vector3(cos(p) * sin(yaw), sin(p), cos(p) * cos(yaw)).normalized()
	cam.position = focus - dir * z
	cam.look_at(focus, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom = max(6.0, zoom - 1.0)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom = min(34.0, zoom + 1.0)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			right_drag = e.pressed
		elif e.button_index == MOUSE_BUTTON_MIDDLE:
			middle_drag = e.pressed
		elif e.button_index == MOUSE_BUTTON_LEFT and e.pressed and phase == "game":
			click_world(e.position)
	elif event is InputEventMouseMotion:
		var m := event as InputEventMouseMotion
		if right_drag:
			yaw -= m.relative.x * 0.008
			pitch = clamp(pitch - m.relative.y * 0.006, -1.35, -0.35)
		elif middle_drag:
			focus += (-cam.global_transform.basis.x * m.relative.x + cam.global_transform.basis.z * m.relative.y) * 0.018
			focus.y = 0
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_F:
				close_view = not close_view
			elif k.keycode == KEY_SPACE:
				focus = Vector3.ZERO

func click_world(screen: Vector2) -> void:
	if state.is_empty() or not state.has("hexes"):
		return
	var origin := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	if abs(dir.y) < 0.001:
		return
	var hit := origin + dir * (-origin.y / dir.y)
	var best := ""
	var best_distance := 999.0
	for key in state["hexes"].keys():
		var h: Dictionary = state["hexes"][key]
		var p := axial_position(int(h["q"]), int(h["r"]))
		var d := Vector2(p.x, p.z).distance_to(Vector2(hit.x, hit.z))
		if d < best_distance:
			best_distance = d
			best = key
	if best_distance > HEX_SIZE * 1.05:
		return
	var clicked_unit := unit_on_hex(best)
	if clicked_unit != "" and int(state["units"][clicked_unit]["owner"]) == local_id:
		selected_unit = clicked_unit
		selected_hex = best
		show_game()
		return
	if selected_unit != "" and state["units"].has(selected_unit):
		var u: Dictionary = state["units"][selected_unit]
		if int(u["owner"]) == local_id:
			if clicked_unit != "" and int(state["units"][clicked_unit]["owner"]) != local_id:
				add_or_replace({"type":"attack", "unit":selected_unit, "target":best, "attack":attack_kind, "pull":aim_pull, "breath":aim_breath, "lead":aim_lead})
			elif distance_keys(str(u["hex"]), best) <= int(u["move"]):
				add_or_replace({"type":"move", "unit":selected_unit, "to":best})
	selected_hex = best
	show_game()

func unit_on_hex(hex: String) -> String:
	for uid in state.get("units", {}).keys():
		var u: Dictionary = state["units"][uid]
		if str(u.get("hex", "")) == hex and int(u.get("captured_by", 0)) == 0:
			return uid
	return ""

func add_or_replace(o: Dictionary) -> void:
	var t := str(o.get("type", ""))
	if t in ["move", "attack"]:
		for i in range(local_orders.size() - 1, -1, -1):
			var existing: Dictionary = local_orders[i]
			if existing.get("unit", "") == o.get("unit", "") and str(existing.get("type", "")) in ["move", "attack"]:
				local_orders.remove_at(i)
	if local_orders.size() < 10:
		local_orders.append(o)

func queue_build(kind: String) -> void:
	if selected_hex != "" and state.get("hexes", {}).has(selected_hex) and int(state["hexes"][selected_hex].get("owner", 0)) == local_id:
		add_or_replace({"type":"build", "hex":selected_hex, "structure":kind})
		show_game()

func queue_recruit(kind: String) -> void:
	if selected_hex != "" and state.get("hexes", {}).has(selected_hex) and int(state["hexes"][selected_hex].get("owner", 0)) == local_id:
		add_or_replace({"type":"recruit", "hex":selected_hex, "unit":kind})
		show_game()

func queue_tribute() -> void:
	var t := next_other_player()
	if t != 0:
		local_orders.append({"type":"tribute", "target":t, "give":{"gold":2, "food":1}})
		show_game()

func queue_diplomacy() -> void:
	var t := next_other_player()
	if t != 0:
		local_orders.append({"type":"diplomacy", "target":t, "stance":"oath"})
		show_game()

func clear_orders() -> void:
	local_orders = []
	show_game()

func next_other_player() -> int:
	if not state.has("players"):
		return 0
	var ids := state["players"].keys()
	ids.sort()
	for id in ids:
		if int(id) != local_id and bool(state["players"][id].get("alive", true)):
			return int(id)
	return 0

func submit_orders() -> void:
	if phase != "game":
		return
	if is_host:
		sealed_orders[local_id] = local_orders.duplicate(true)
		try_resolve()
	else:
		rpc_submit_orders.rpc_id(1, local_id, local_orders.duplicate(true))
	local_orders = []
	update_hud()

@rpc("any_peer", "call_remote", "reliable")
func rpc_submit_orders(pid: int, orders: Array) -> void:
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	var effective := sender
	if sender == 1:
		effective = pid
	if not state.get("players", {}).has(effective):
		return
	sealed_orders[effective] = orders.duplicate(true)
	state["events"] = ["%d / %d realms have sealed orders." % [sealed_orders.size(), alive_ids().size()]]
	broadcast_state(false)
	try_resolve()

func alive_ids() -> Array:
	var a := []
	if not state.has("players"):
		return a
	for id in state["players"].keys():
		if bool(state["players"][id].get("alive", true)):
			a.append(id)
	return a

func try_resolve() -> void:
	if not is_host or state.is_empty():
		return
	for id in alive_ids():
		if not sealed_orders.has(id):
			return
	resolve_turn()
	sealed_orders = {}
	broadcast_state(true)

func can_pay(p: Dictionary, cost: Dictionary) -> bool:
	var bag: Dictionary = p.get("resources", {})
	for r in cost.keys():
		if int(bag.get(r, 0)) < int(cost[r]):
			return false
	return true

func pay(p: Dictionary, cost: Dictionary) -> void:
	var bag: Dictionary = p.get("resources", {})
	for r in cost.keys():
		bag[r] = int(bag.get(r, 0)) - int(cost[r])

func gain(p: Dictionary, inc: Dictionary) -> void:
	var bag: Dictionary = p.get("resources", {})
	for r in inc.keys():
		bag[r] = int(bag.get(r, 0)) + int(inc[r])

func resolve_turn() -> void:
	var events := []
	for id in alive_ids():
		income_for(int(id), events)
	for id in alive_ids():
		for o in sealed_orders.get(id, []):
			var typ := str(o.get("type", ""))
			if typ in ["build", "recruit", "tribute", "diplomacy"]:
				resolve_order(int(id), o, events)
	var move_claims := {}
	for id in alive_ids():
		for o in sealed_orders.get(id, []):
			if str(o.get("type", "")) == "move":
				var target := str(o.get("to", ""))
				move_claims[target] = int(move_claims.get(target, 0)) + 1
	for id in alive_ids():
		for o in sealed_orders.get(id, []):
			if str(o.get("type", "")) == "move" and int(move_claims.get(str(o.get("to", "")), 0)) == 1:
				resolve_order(int(id), o, events)
	for id in alive_ids():
		for o in sealed_orders.get(id, []):
			if str(o.get("type", "")) == "attack":
				resolve_order(int(id), o, events)
	capture_territory(events)
	environment_step(events)
	update_scores(state)
	var win := winner_id()
	if win != 0:
		state["winner"] = win
		events.push_front("%s wins the Black Octagon." % owner_name(win))
	state["turn"] = int(state.get("turn", 1)) + 1
	state["weather"] = WEATHER.pick_random()
	state["events"] = events.slice(0, 18)

func income_for(id: int, events: Array) -> void:
	var p: Dictionary = state["players"][id]
	for key in state["hexes"].keys():
		var h: Dictionary = state["hexes"][key]
		if int(h.get("owner", 0)) == id:
			gain(p, TERRAIN[h.get("terrain", "field")]["income"])
			var structure := str(h.get("structure", ""))
			if structure != "" and STRUCTURES.has(structure):
				gain(p, STRUCTURES[structure]["income"])
	events.append("%s collects grain, taxes, relics, and iron." % p.get("faction", "A realm"))

func resolve_order(id: int, o: Dictionary, events: Array) -> void:
	var typ := str(o.get("type", ""))
	if typ == "build":
		resolve_build(id, o, events)
	elif typ == "recruit":
		resolve_recruit(id, o, events)
	elif typ == "tribute":
		resolve_tribute(id, o, events)
	elif typ == "diplomacy":
		resolve_diplomacy(id, o, events)
	elif typ == "move":
		resolve_move(id, o, events)
	elif typ == "attack":
		resolve_attack(id, o, events)

func resolve_build(id: int, o: Dictionary, events: Array) -> void:
	var hex := str(o.get("hex", ""))
	var structure := str(o.get("structure", ""))
	if not state["hexes"].has(hex) or not STRUCTURES.has(structure):
		return
	var h: Dictionary = state["hexes"][hex]
	var p: Dictionary = state["players"][id]
	var st: Dictionary = STRUCTURES[structure]
	if int(h.get("owner", 0)) == id and str(h.get("structure", "")) == "" and can_pay(p, st["cost"]):
		pay(p, st["cost"])
		h["structure"] = structure
		h["hp"] = st["hp"]
		events.append("%s raises a %s." % [p.get("faction", "A realm"), st["name"]])

func resolve_recruit(id: int, o: Dictionary, events: Array) -> void:
	var hex := str(o.get("hex", ""))
	var unit_type := str(o.get("unit", ""))
	if not state["hexes"].has(hex) or not UNITS.has(unit_type):
		return
	var h: Dictionary = state["hexes"][hex]
	var p: Dictionary = state["players"][id]
	var udef: Dictionary = UNITS[unit_type]
	if int(h.get("owner", 0)) == id and can_pay(p, udef["cost"]) and unit_on_hex(hex) == "":
		pay(p, udef["cost"])
		add_unit_to_state(state, id, unit_type, hex)
		events.append("%s recruits %s." % [p.get("faction", "A realm"), udef["name"]])

func resolve_tribute(id: int, o: Dictionary, events: Array) -> void:
	var target := int(o.get("target", 0))
	var give: Dictionary = o.get("give", {})
	if not state["players"].has(target):
		return
	if can_pay(state["players"][id], give):
		pay(state["players"][id], give)
		gain(state["players"][target], give)
		events.append("%s sends tribute to %s." % [owner_name(id), owner_name(target)])

func resolve_diplomacy(id: int, o: Dictionary, events: Array) -> void:
	var target := int(o.get("target", 0))
	if not state["players"].has(target):
		return
	var oaths: Dictionary = state["players"][id].get("oaths", {})
	if oaths.has(target):
		oaths.erase(target)
		state["players"][id]["betrayals"] = int(state["players"][id].get("betrayals", 0)) + 1
		events.append("%s betrays the blood oath with %s." % [owner_name(id), owner_name(target)])
	else:
		oaths[target] = true
		events.append("%s offers a blood oath to %s." % [owner_name(id), owner_name(target)])

func resolve_move(id: int, o: Dictionary, events: Array) -> void:
	var uid := str(o.get("unit", ""))
	var target := str(o.get("to", ""))
	if not state["units"].has(uid) or not state["hexes"].has(target):
		return
	var u: Dictionary = state["units"][uid]
	if int(u.get("owner", 0)) == id and int(u.get("captured_by", 0)) == 0 and distance_keys(str(u.get("hex", "")), target) <= int(u.get("move", 1)) and unit_on_hex(target) == "":
		u["hex"] = target
		events.append("%s moves through the mud." % u.get("name", "A unit"))

func resolve_attack(id: int, o: Dictionary, events: Array) -> void:
	var attacker_id := str(o.get("unit", ""))
	var target_hex := str(o.get("target", ""))
	if not state["units"].has(attacker_id) or not state["hexes"].has(target_hex):
		return
	var attacker: Dictionary = state["units"][attacker_id]
	if int(attacker.get("owner", 0)) != id or int(attacker.get("captured_by", 0)) != 0:
		return
	var target_id := ""
	for uid in state["units"].keys():
		var u: Dictionary = state["units"][uid]
		if str(u.get("hex", "")) == target_hex and int(u.get("owner", 0)) != id and int(u.get("captured_by", 0)) == 0:
			target_id = uid
			break
	if target_id == "":
		return
	var target: Dictionary = state["units"][target_id]
	var attack_type := str(o.get("attack", "woundline"))
	if not ATTACKS.has(attack_type):
		attack_type = "woundline"
	var atk: Dictionary = ATTACKS[attack_type]
	var distance := distance_keys(str(attacker.get("hex", "")), str(target.get("hex", "")))
	if distance > int(attacker.get("range", 1)) + int(atk.get("range_bonus", 0)):
		events.append("%s's attack dies before reaching %s." % [attacker.get("name", "Attacker"), target.get("name", "target")])
		return
	var ideal_pull := 0.31 + 0.06 * float(attacker.get("skill", 1))
	var ideal_breath := 0.55
	var ideal_lead := clamp(0.26 + 0.08 * distance, 0.0, 1.0)
	var aim := 1.0 - (abs(float(o.get("pull", 0.5)) - ideal_pull) + abs(float(o.get("breath", 0.5)) - ideal_breath) + abs(float(o.get("lead", 0.5)) - ideal_lead)) / 3.0
	var target_tile: Dictionary = state["hexes"][target.get("hex", "")]
	var cover := 0.0
	if str(target_tile.get("terrain", "field")) in ["forest", "stone", "village"]:
		cover += 0.12
	if int(target_tile.get("flood", 0)) > 0:
		cover += 0.06
	var weather_penalties := {"clear":0.0, "fog":0.10, "rain":0.08, "ashfall":0.12, "storm":0.18}
	var weather_penalty := float(weather_penalties.get(str(state.get("weather", "clear")), 0.0))
	var chance := clamp(0.20 + aim * 0.48 + float(attacker.get("skill", 1)) * 0.06 + float(atk.get("skill_bonus", 0.0)) - cover - weather_penalty - float(distance) * 0.04, 0.05, 0.93)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(state.get("turn", 1)) + attacker_id + target_id + str(o.get("pull", 0.5)) + str(state.get("weather", "clear")))
	if rng.randf() <= chance:
		var damage := max(1, int(round(float(attacker.get("attack", 1)) * float(atk.get("damage", 1.0)) + aim * 3.0 - float(target.get("armor", 0)) * 0.45)))
		if bool(attacker.get("wounded", false)):
			damage = max(1, damage - 1)
		target["hp"] = int(target.get("hp", 1)) - damage
		events.append("%s lands %s on %s for %d." % [attacker.get("name", "Attacker"), atk.get("name", attack_type), target.get("name", "target"), damage])
		if int(target.get("hp", 0)) <= 0:
			casualty(target_id, id, rng, events)
	else:
		events.append("%s misses %s; mud, fear, weather, and breath timing spoil the line." % [attacker.get("name", "Attacker"), target.get("name", "target")])

func casualty(uid: String, killer: int, rng: RandomNumberGenerator, events: Array) -> void:
	if not state["units"].has(uid):
		return
	var u: Dictionary = state["units"][uid]
	var roll := rng.randf()
	if roll < 0.18:
		u["hp"] = max(1, int(float(u.get("max_hp", 1)) * 0.35))
		u["wounded"] = true
		events.append("%s is left wounded in the muck." % u.get("name", "A unit"))
	elif roll < 0.32:
		u["hp"] = 1
		u["captured_by"] = killer
		events.append("%s is captured for ransom by %s." % [u.get("name", "A unit"), owner_name(killer)])
	else:
		events.append("%s dies permanently." % u.get("name", "A unit"))
		state["units"].erase(uid)

func capture_territory(events: Array) -> void:
	for uid in state["units"].keys():
		var u: Dictionary = state["units"][uid]
		if int(u.get("captured_by", 0)) != 0:
			continue
		var enemy_present := false
		for vid in state["units"].keys():
			if vid == uid:
				continue
			var other: Dictionary = state["units"][vid]
			if str(other.get("hex", "")) == str(u.get("hex", "")) and int(other.get("owner", 0)) != int(u.get("owner", 0)) and int(other.get("captured_by", 0)) == 0:
				enemy_present = true
		if not enemy_present and state["hexes"].has(str(u.get("hex", ""))):
			var h: Dictionary = state["hexes"][u.get("hex", "")]
			if int(h.get("owner", 0)) != int(u.get("owner", 0)):
				h["owner"] = int(u.get("owner", 0))
				events.append("%s claims %s." % [owner_name(int(u.get("owner", 0))), u.get("hex", "")])

func environment_step(events: Array) -> void:
	for key in state["hexes"].keys():
		var h: Dictionary = state["hexes"][key]
		if int(h.get("burn", 0)) > 0:
			h["burn"] = max(0, int(h.get("burn", 0)) - 1)
		if int(h.get("flood", 0)) > 0:
			h["flood"] = max(0, int(h.get("flood", 0)) - 1)
		if randf() < 0.015 and str(h.get("terrain", "field")) in ["forest", "village"]:
			h["burn"] = 3
			events.append("Fire crawls across %s." % key)
		if str(state.get("weather", "clear")) == "storm" and randf() < 0.025:
			h["flood"] = 2
		if str(state.get("weather", "clear")) == "ashfall" and randf() < 0.025:
			h["ash"] = 2

func update_scores(s: Dictionary) -> void:
	for id in s.get("players", {}).keys():
		var score := 0
		var p: Dictionary = s["players"][id]
		for key in s.get("hexes", {}).keys():
			var h: Dictionary = s["hexes"][key]
			if int(h.get("owner", 0)) == int(id):
				score += 1
				var structure := str(h.get("structure", ""))
				if structure != "" and STRUCTURES.has(structure):
					score += int(STRUCTURES[structure]["score"])
		for uid in s.get("units", {}).keys():
			var u: Dictionary = s["units"][uid]
			if int(u.get("owner", 0)) == int(id) and int(u.get("captured_by", 0)) == 0:
				score += int(u.get("score", 0))
		var bag: Dictionary = p.get("resources", {})
		for r in RESOURCES:
			score += int(bag.get(r, 0)) / 10
		p["score"] = score

func winner_id() -> int:
	var best := 0
	var best_score := -1
	for id in state.get("players", {}).keys():
		var sc := int(state["players"][id].get("score", 0))
		if sc > best_score:
			best_score = sc
			best = int(id)
	if best_score >= TARGET_SCORE or int(state.get("turn", 1)) >= TURN_LIMIT:
		return best
	return 0
