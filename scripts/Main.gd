extends Node3D

const GAME_NAME := "Crown & Cinder"
const PORT := 37172
const MIN_PLAYERS := 3
const MAX_PLAYERS := 6
const BOARD_R := 5
const HEX_SIZE := 1.05
const TARGET_SCORE := 78
const TURN_LIMIT := 12
const RES := ["gold", "food", "timber", "iron", "population", "influence", "faith"]
const START_RES := {"gold":18, "food":16, "timber":12, "iron":7, "population":8, "influence":3, "faith":4}
const FACTIONS := [
	{"name":"Ashen Crown", "archetype":"fallen human kingdom", "color":"#ad302e"},
	{"name":"Briar Oath", "archetype":"forest-bound wardens", "color":"#3f8f5b"},
	{"name":"Graveforge", "archetype":"dwarven necro-smiths", "color":"#b47c3a"},
	{"name":"Moon Reliquary", "archetype":"silver cult knights", "color":"#7b7fd4"},
	{"name":"Hollow Choir", "archetype":"faith-haunted mages", "color":"#9d55b8"},
	{"name":"Saltwolf March", "archetype":"raiders and privateers", "color":"#378fa3"}
]
const TERRAIN := {
	"field":{"name":"Field", "color":"#536640", "h":0.14, "income":{"food":2, "population":1}},
	"forest":{"name":"Blackwood", "color":"#243525", "h":0.28, "income":{"timber":2, "faith":1}},
	"marsh":{"name":"Marsh", "color":"#273c37", "h":0.06, "income":{"food":1, "faith":1}},
	"stone":{"name":"Ruin-Stone", "color":"#494842", "h":0.36, "income":{"iron":1, "gold":1}},
	"village":{"name":"Village", "color":"#6e523c", "h":0.22, "income":{"gold":1, "population":2, "influence":1}},
	"ash":{"name":"Ashland", "color":"#332f2e", "h":0.10, "income":{"faith":1}},
	"water":{"name":"Drowned Hex", "color":"#203844", "h":-0.05, "income":{"food":1}}
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
	"cleave":{"name":"Cleave", "range":0, "damage":1.00, "skill":0.10, "spread":0.14},
	"brace":{"name":"Brace & Counter", "range":0, "damage":0.78, "skill":0.18, "spread":0.10},
	"woundline":{"name":"Woundline", "range":1, "damage":1.00, "skill":0.16, "spread":0.25},
	"arc":{"name":"Funeral Arc", "range":2, "damage":0.86, "skill":0.05, "spread":0.55},
	"scatter":{"name":"Cinder Scatter", "range":0, "damage":1.25, "skill":-0.05, "spread":0.75},
	"hexbolt":{"name":"Hex Bolt", "range":1, "damage":1.05, "skill":0.20, "spread":0.35}
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
var unit_root: Node3D
var prop_root: Node3D
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
var log_label: RichTextLabel
var hud_status: RichTextLabel
var order_label: RichTextLabel
var attack_option: OptionButton
var pull_slider: HSlider
var breath_slider: HSlider
var lead_slider: HSlider

func _ready() -> void:
	randomize()
	build_world_nodes()
	build_ui_layer()
	wire_multiplayer()
	show_menu()

func wire_multiplayer() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected): multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected): multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server): multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed): multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected): multiplayer.server_disconnected.connect(_on_server_disconnected)

func build_world_nodes() -> void:
	board_root = Node3D.new(); board_root.name = "Board"; add_child(board_root)
	prop_root = Node3D.new(); prop_root.name = "Props"; add_child(prop_root)
	unit_root = Node3D.new(); unit_root.name = "Units"; add_child(unit_root)
	fx_root = Node3D.new(); fx_root.name = "Atmosphere"; add_child(fx_root)
	cam = Camera3D.new(); cam.name = "TableCamera"; add_child(cam); cam.fov = 42.0; cam.current = true
	var sun := DirectionalLight3D.new(); sun.name = "ColdSun"; add_child(sun); sun.light_energy = 1.15; sun.rotation_degrees = Vector3(-55, -35, 0)
	var moon := OmniLight3D.new(); moon.name = "CinderFill"; add_child(moon); moon.position = Vector3(0, 8, 0); moon.light_color = Color(0.45, 0.58, 0.78); moon.light_energy = 0.7; moon.omni_range = 28
	var env := WorldEnvironment.new(); add_child(env); env.environment = Environment.new(); env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.018,0.017,0.016)

func build_ui_layer() -> void:
	ui = CanvasLayer.new(); add_child(ui)

func clear_ui() -> void:
	for c in ui.get_children(): c.queue_free()

func panel(title: String) -> VBoxContainer:
	clear_ui()
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(root)
	var shade := ColorRect.new(); shade.color = Color(0,0,0,0.62); shade.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(shade)
	var p := PanelContainer.new(); p.size = Vector2(560, 620); p.position = Vector2(42, 42); root.add_child(p)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 12); p.add_child(box)
	var t := Label.new(); t.text = title; t.add_theme_font_size_override("font_size", 34); box.add_child(t)
	return box

func mk_label(text: String, size := 16) -> Label:
	var l := Label.new(); l.text = text; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size", size); return l

func mk_button(text: String, callable: Callable) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size = Vector2(0, 38); b.pressed.connect(callable); return b

func show_menu() -> void:
	phase = "menu"
	render_empty_title_board()
	var b := panel("Crown & Cinder")
	b.add_child(mk_label("The Black Octagon — peer-hosted dark fantasy strategy for 3–6 players.", 18))
	name_box = LineEdit.new(); name_box.placeholder_text = "Player name"; name_box.text = player_name; b.add_child(name_box)
	max_spin = SpinBox.new(); max_spin.min_value = MIN_PLAYERS; max_spin.max_value = MAX_PLAYERS; max_spin.value = MAX_PLAYERS; max_spin.prefix = "Max players "; b.add_child(max_spin)
	b.add_child(mk_button("Host Direct Game", Callable(self, "host_game")))
	var sep := HSeparator.new(); b.add_child(sep)
	ip_box = LineEdit.new(); ip_box.placeholder_text = "Host IP address"; ip_box.text = "127.0.0.1"; b.add_child(ip_box)
	code_box = LineEdit.new(); code_box.placeholder_text = "Private invite code"; b.add_child(code_box)
	b.add_child(mk_button("Join Game", Callable(self, "join_game")))
	b.add_child(mk_label("Internet hosting usually needs UDP port forwarding on port %d. LAN hosting can use the host machine's local IP." % PORT, 14))

func host_game() -> void:
	reset_net()
	player_name = name_box.text.strip_edges() if name_box else "Host"
	if player_name == "": player_name = "Host"
	is_host = true; local_id = 1; invite_code = make_code(); lobby = {}; sealed_orders = {}; local_orders = []
	lobby[1] = make_lobby_record(1, player_name, 0)
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, int(max_spin.value) - 1)
	if err != OK:
		show_message("Host failed", "Could not open UDP port %d. Error %d." % [PORT, err]); return
	multiplayer.multiplayer_peer = peer
	phase = "lobby"
	show_lobby("Hosting on port %d. Invite code: %s" % [PORT, invite_code])

func join_game() -> void:
	reset_net()
	player_name = name_box.text.strip_edges() if name_box else "Guest"
	if player_name == "": player_name = "Guest"
	invite_code = code_box.text.strip_edges().to_upper()
	is_host = false; local_id = 0; lobby = {}; phase = "lobby"
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip_box.text.strip_edges(), PORT)
	if err != OK:
		show_message("Join failed", "Could not create client. Error %d." % err); return
	multiplayer.multiplayer_peer = peer
	show_lobby("Connecting...")

func _on_connected_to_server() -> void:
	local_id = multiplayer.get_unique_id()
	rpc_join_request.rpc_id(1, invite_code, player_name)

func _on_connection_failed() -> void: show_message("Connection failed", "Check host IP, firewall, invite code, and port forwarding.")
func _on_server_disconnected() -> void: reset_net(); show_message("Disconnected", "The host closed the table.")
func _on_peer_connected(id: int) -> void:
	if is_host: show_lobby("Peer %d connected. Waiting for invite code." % id)
func _on_peer_disconnected(id: int) -> void:
	if is_host:
		if lobby.has(id): lobby.erase(id)
		if state.has("players") and state["players"].has(id): state["players"][id]["alive"] = false; state["events"].push_front("A realm's ruler vanished from the table.")
		broadcast_lobby()
		if phase == "game": broadcast_state(false)

func reset_net() -> void:
	if peer: peer.close()
	peer = null; multiplayer.multiplayer_peer = null
	is_host = false; local_id = 1; lobby = {}; state = {}; sealed_orders = {}; local_orders = []; selected_unit = ""; selected_hex = ""

func make_code() -> String:
	var chars := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; var c := ""
	for i in range(6): c += chars[randi_range(0, chars.length() - 1)]
	return c

func make_lobby_record(id: int, pname: String, index: int) -> Dictionary:
	var f = FACTIONS[index % FACTIONS.size()]
	return {"id":id, "name":pname, "faction":f.name, "archetype":f.archetype, "color":f.color}

@rpc("any_peer", "call_remote", "reliable")
func rpc_join_request(code: String, pname: String) -> void:
	if not is_host: return
	var sender := multiplayer.get_remote_sender_id()
	if phase != "lobby": rpc_join_denied.rpc_id(sender, "Match already started."); return
	if code.strip_edges().to_upper() != invite_code: rpc_join_denied.rpc_id(sender, "Wrong invite code."); return
	if lobby.size() >= MAX_PLAYERS: rpc_join_denied.rpc_id(sender, "Table is full."); return
	lobby[sender] = make_lobby_record(sender, pname if pname != "" else "Guest", lobby.size())
	rpc_join_ok.rpc_id(sender, sender)
	broadcast_lobby()

@rpc("authority", "call_remote", "reliable")
func rpc_join_ok(id: int) -> void:
	local_id = id

@rpc("authority", "call_remote", "reliable")
func rpc_join_denied(reason: String) -> void:
	show_message("Join denied", reason)
	reset_net()

func broadcast_lobby() -> void:
	if not is_host: return
	rpc_lobby.rpc(lobby, invite_code, "Waiting for players. %d/%d seated." % [lobby.size(), MAX_PLAYERS])
	rpc_lobby(lobby, invite_code, "Waiting for players. %d/%d seated." % [lobby.size(), MAX_PLAYERS])

@rpc("authority", "call_remote", "reliable")
func rpc_lobby(new_lobby: Dictionary, code: String, msg: String) -> void:
	lobby = new_lobby.duplicate(true); invite_code = code; phase = "lobby"; show_lobby(msg)

func show_lobby(msg: String) -> void:
	clear_ui(); render_empty_title_board()
	var b := panel("Private Table")
	b.add_child(mk_label(msg, 16))
	b.add_child(mk_label("Invite code: %s\nPort: %d" % [invite_code, PORT], 20))
	var ids := lobby.keys(); ids.sort()
	for id in ids:
		var p = lobby[id]
		b.add_child(mk_label("%s — %s (%s)" % [p.name, p.faction, p.archetype], 15))
	if is_host:
		b.add_child(mk_button("Start Match", Callable(self, "start_match")))
	b.add_child(mk_button("Leave Table", Callable(self, "leave_to_menu")))

func show_message(title: String, msg: String) -> void:
	var b := panel(title); b.add_child(mk_label(msg, 17)); b.add_child(mk_button("Back", Callable(self, "leave_to_menu")))

func leave_to_menu() -> void:
	reset_net(); show_menu()

func start_match() -> void:
	if not is_host: return
	if lobby.size() < MIN_PLAYERS:
		show_lobby("Need at least %d players." % MIN_PLAYERS); return
	state = make_state(lobby)
	sealed_orders = {}; local_orders = []; phase = "game"
	broadcast_state(true)

func broadcast_state(reset_orders: bool) -> void:
	if not is_host: return
	rpc_state.rpc(state, reset_orders)
	rpc_state(state, reset_orders)

@rpc("authority", "call_remote", "reliable")
func rpc_state(new_state: Dictionary, reset_orders: bool) -> void:
	state = new_state.duplicate(true); phase = "game"
	if reset_orders: local_orders = []; selected_unit = ""; selected_hex = ""
	show_game()

func make_state(players: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var s := {"turn":1, "weather":WEATHER.pick_random(), "hexes":{}, "units":{}, "players":{}, "events":["The Black Octagon rises out of the mud."], "next_unit":1, "winner":0}
	for q in range(-BOARD_R, BOARD_R + 1):
		for r in range(-BOARD_R, BOARD_R + 1):
			if abs(q) <= BOARD_R and abs(r) <= BOARD_R and abs(q + r) <= BOARD_R + 2:
				var key := hk(q, r); var roll := rng.randf(); var terr := "field"
				if roll < .12: terr = "forest"
				elif roll < .22: terr = "marsh"
				elif roll < .34: terr = "stone"
				elif roll < .43: terr = "village"
				elif roll < .51: terr = "ash"
				elif roll < .57: terr = "water"
				s.hexes[key] = {"q":q, "r":r, "terrain":terr, "owner":0, "structure":"", "hp":0, "burn":0, "flood":0, "ash":0}
	var starts := [[0,-BOARD_R],[BOARD_R,-BOARD_R],[BOARD_R,0],[0,BOARD_R],[-BOARD_R,BOARD_R],[-BOARD_R,0]]
	var ids := players.keys(); ids.sort()
	for i in range(ids.size()):
		var id = int(ids[i]); var lp = players[id]
		var rec := {"id":id, "name":lp.name, "faction":lp.faction, "archetype":lp.archetype, "color":lp.color, "resources":START_RES.duplicate(true), "alive":true, "score":0, "oaths":{}, "betrayals":0}
		s.players[id] = rec
		var start := nearest_hex(s, starts[i][0], starts[i][1]); claim_start(s, id, start)
		add_unit(s, id, "lord", start); add_unit(s, id, "levy", start); add_unit(s, id, "longbow", start)
	update_scores(s)
	return s

func nearest_hex(s: Dictionary, q: int, r: int) -> String:
	var best := ""; var d := 999
	for key in s.hexes.keys():
		var h = s.hexes[key]; var nd = hex_dist(q, r, h.q, h.r)
		if nd < d: d = nd; best = key
	return best

func claim_start(s: Dictionary, id: int, key: String) -> void:
	var h = s.hexes[key]; h.owner = id; h.terrain = "village"; h.structure = "keep"; h.hp = STRUCTURES.keep.hp
	for n in neighbors(key):
		if s.hexes.has(n): s.hexes[n].owner = id

func add_unit(s: Dictionary, id: int, typ: String, hex: String) -> String:
	var def = UNITS[typ]; var uid := "u%d" % int(s.next_unit); s.next_unit += 1
	s.units[uid] = {"id":uid, "owner":id, "type":typ, "name":def.name, "hex":hex, "hp":def.hp, "max_hp":def.hp, "armor":def.armor, "skill":def.skill, "attack":def.attack, "range":def.range, "move":def.move, "score":def.score, "wounded":false, "captured_by":0}
	return uid

func hk(q: int, r: int) -> String: return "%d,%d" % [q, r]
func parse_hk(key: String) -> Vector2i:
	var p := key.split(","); return Vector2i(int(p[0]), int(p[1]))
func hex_dist(q1:int, r1:int, q2:int, r2:int) -> int:
	return int((abs(q1 - q2) + abs(q1 + r1 - q2 - r2) + abs(r1 - r2)) / 2)
func dist_keys(a:String, b:String) -> int:
	var x := parse_hk(a); var y := parse_hk(b); return hex_dist(x.x, x.y, y.x, y.y)
func neighbors(key:String) -> Array:
	var p := parse_hk(key); return [hk(p.x+1,p.y),hk(p.x-1,p.y),hk(p.x,p.y+1),hk(p.x,p.y-1),hk(p.x+1,p.y-1),hk(p.x-1,p.y+1)]
func axial_pos(q:int, r:int) -> Vector3:
	return Vector3(HEX_SIZE * sqrt(3.0) * (float(q) + float(r) / 2.0), 0, HEX_SIZE * 1.5 * float(r))

func show_game() -> void:
	render_state()
	clear_ui()
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(root)
	var left := PanelContainer.new(); left.position = Vector2(18,18); left.size = Vector2(390,650); root.add_child(left)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 8); left.add_child(box)
	hud_status = RichTextLabel.new(); hud_status.bbcode_enabled = true; hud_status.fit_content = true; hud_status.custom_minimum_size = Vector2(360,220); box.add_child(hud_status)
	attack_option = OptionButton.new(); for k in ATTACKS.keys(): attack_option.add_item(ATTACKS[k].name); attack_option.set_item_metadata(attack_option.item_count-1,k); box.add_child(attack_option); attack_option.item_selected.connect(_attack_changed)
	pull_slider = add_slider(box, "Pull", aim_pull, Callable(self,"_pull")); breath_slider = add_slider(box, "Breath", aim_breath, Callable(self,"_breath")); lead_slider = add_slider(box, "Lead", aim_lead, Callable(self,"_lead"))
	var row := HBoxContainer.new(); box.add_child(row); row.add_child(mk_button("Build Farm", Callable(self,"queue_build").bind("farm"))); row.add_child(mk_button("Build Market", Callable(self,"queue_build").bind("market")))
	var row2 := HBoxContainer.new(); box.add_child(row2); row2.add_child(mk_button("Recruit Levy", Callable(self,"queue_recruit").bind("levy"))); row2.add_child(mk_button("Recruit Cannon", Callable(self,"queue_recruit").bind("handcannon")))
	var row3 := HBoxContainer.new(); box.add_child(row3); row3.add_child(mk_button("Send Tribute", Callable(self,"queue_tribute"))); row3.add_child(mk_button("Blood Oath/Betray", Callable(self,"queue_diplomacy")))
	box.add_child(mk_button("Submit Secret Orders", Callable(self,"submit_orders")))
	box.add_child(mk_button("Clear Orders", Callable(self,"clear_orders")))
	box.add_child(mk_button("Leave", Callable(self,"leave_to_menu")))
	order_label = RichTextLabel.new(); order_label.bbcode_enabled = true; order_label.custom_minimum_size = Vector2(360,160); box.add_child(order_label)
	log_label = RichTextLabel.new(); log_label.bbcode_enabled = true; log_label.custom_minimum_size = Vector2(360,220); box.add_child(log_label)
	update_hud()

func add_slider(parent: Node, label_text: String, value: float, cb: Callable) -> HSlider:
	var label := mk_label(label_text, 13); parent.add_child(label)
	var s := HSlider.new(); s.min_value = 0; s.max_value = 1; s.step = .01; s.value = value; parent.add_child(s); s.value_changed.connect(cb); return s
func _attack_changed(i:int)->void: attack_kind = str(attack_option.get_item_metadata(i))
func _pull(v:float)->void: aim_pull = v
func _breath(v:float)->void: aim_breath = v
func _lead(v:float)->void: aim_lead = v

func update_hud() -> void:
	if not hud_status or state.is_empty(): return
	var me = state.players.get(local_id, {})
	var res_txt := ""
	if not me.is_empty(): for r in RES: res_txt += "%s:%d  " % [r.substr(0,3), int(me.resources.get(r,0))]
	var sel := describe_selection()
	var waiting := ""
	if is_host: waiting = "\nSealed orders: %d/%d" % [sealed_orders.size(), alive_ids().size()]
	hud_status.text = "[b]%s[/b]\nTurn %d/%d • Weather: %s%s\nScore: %d • %s\n%s\n\n%s" % [GAME_NAME, int(state.turn), TURN_LIMIT, state.weather, waiting, int(me.get("score",0)), str(me.get("faction","")), res_txt, sel]
	var ot := "[b]Secret Orders[/b]\n"
	for o in local_orders: ot += "• %s\n" % order_text(o)
	if local_orders.is_empty(): ot += "No orders queued."
	order_label.text = ot
	var lg := "[b]Table Log[/b]\n"
	for e in state.get("events",[]): lg += "• %s\n" % e
	log_label.text = lg

func describe_selection() -> String:
	if selected_unit != "" and state.units.has(selected_unit):
		var u = state.units[selected_unit]; return "%s\nHP %d/%d • Skill %d • Armor %d • Range %d" % [u.name, u.hp, u.max_hp, u.skill, u.armor, u.range]
	if selected_hex != "" and state.hexes.has(selected_hex):
		var h = state.hexes[selected_hex]; return "Hex %s • %s • Owner %s • Structure %s" % [selected_hex, TERRAIN[h.terrain].name, owner_name(h.owner), h.structure if h.structure != "" else "none"]
	return "Select one of your units, then choose a destination or target."

func order_text(o: Dictionary) -> String:
	match str(o.get("type","")):
		"move": return "Move %s to %s" % [o.unit, o.to]
		"attack": return "%s attacks %s with %s" % [o.unit, o.target, ATTACKS[o.attack].name]
		"build": return "Build %s at %s" % [o.structure, o.hex]
		"recruit": return "Recruit %s at %s" % [o.unit, o.hex]
		"tribute": return "Send tribute to %s" % owner_name(o.target)
		"diplomacy": return "Diplomacy with %s" % owner_name(o.target)
		_: return str(o)

func owner_name(id:int)->String:
	if state.has("players") and state.players.has(id): return state.players[id].faction
	return "Unclaimed"

func render_empty_title_board() -> void:
	var fake := {"hexes":{}, "units":{}, "weather":"ashfall", "players":{}}
	for q in range(-3,4): for r in range(-3,4): if abs(q+r)<=4: fake.hexes[hk(q,r)]={"q":q,"r":r,"terrain":"ash","owner":0,"structure":"","burn":0,"flood":0,"ash":1}
	state = fake; render_state()

func render_state() -> void:
	for root in [board_root, unit_root, prop_root, fx_root]: for c in root.get_children(): c.queue_free()
	if state.is_empty(): return
	for key in state.get("hexes",{}).keys():
		var h = state.hexes[key]; var def = TERRAIN[h.terrain]; var pos = axial_pos(h.q,h.r); var y = float(def.h) + float(h.get("flood",0))*.04
		var tile := MeshInstance3D.new(); var mesh := CylinderMesh.new(); mesh.radial_segments=6; mesh.top_radius=HEX_SIZE*.98; mesh.bottom_radius=HEX_SIZE*.98; mesh.height=.18+y; tile.mesh=mesh; tile.position=pos+Vector3(0,(.18+y)/2,0); tile.rotation_degrees.y=30; tile.material_override=mat("t"+h.terrain, Color(def.color)); board_root.add_child(tile)
		if int(h.owner)!=0:
			var ring := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius=HEX_SIZE*.72; tor.outer_radius=HEX_SIZE*.79; ring.mesh=tor; ring.position=pos+Vector3(0,.22+y,0); ring.material_override=mat("owner"+str(h.owner), Color(state.players[h.owner].color)); board_root.add_child(ring)
		if h.structure != "": add_structure(h.structure, pos, y, h.owner)
		if h.terrain in ["forest","stone","village"] and randi()%3==0: add_prop(pos, h.terrain)
		if int(h.get("burn",0))>0: add_fire(pos)
	for uid in state.get("units",{}).keys():
		var u = state.units[uid]
		if int(u.get("captured_by",0)) != 0: continue
		if not state.hexes.has(u.hex): continue
		var h = state.hexes[u.hex]; add_unit_mesh(uid, u, axial_pos(h.q,h.r), h)
	add_weather_fx()
	update_camera()

func mat(key:String, color:Color) -> StandardMaterial3D:
	if mat_cache.has(key): return mat_cache[key]
	var m := StandardMaterial3D.new(); m.albedo_color=color; m.roughness=.92; m.metallic=.02; mat_cache[key]=m; return m

func add_structure(kind:String, pos:Vector3, y:float, owner:int)->void:
	var base := MeshInstance3D.new(); var bm := CylinderMesh.new(); bm.radial_segments=8; bm.top_radius=.42; bm.bottom_radius=.55; bm.height=.7; base.mesh=bm; base.position=pos+Vector3(0,.55+y,0); base.material_override=mat("stonework",Color("#2d2926")); prop_root.add_child(base)
	var roof := MeshInstance3D.new(); var rm := CylinderMesh.new(); rm.radial_segments=6; rm.top_radius=.05; rm.bottom_radius=.5; rm.height=.38; roof.mesh=rm; roof.position=pos+Vector3(0,1.08+y,0); roof.material_override=mat("roof"+str(owner), Color(state.players.get(owner,{"color":"#772222"}).color)); prop_root.add_child(roof)

func add_prop(pos:Vector3, terr:String)->void:
	var p := MeshInstance3D.new(); p.position=pos+Vector3(randf_range(-.35,.35),.35,randf_range(-.35,.35))
	if terr=="forest": var cm:=CylinderMesh.new(); cm.top_radius=.08; cm.bottom_radius=.14; cm.height=.9; p.mesh=cm; p.material_override=mat("bark",Color("#241815"))
	elif terr=="stone": var bm:=BoxMesh.new(); bm.size=Vector3(.55,.45,.35); p.mesh=bm; p.material_override=mat("ruin",Color("#55504b"))
	else: var bm2:=BoxMesh.new(); bm2.size=Vector3(.42,.28,.42); p.mesh=bm2; p.material_override=mat("crate",Color("#4b3124"))
	prop_root.add_child(p)

func add_fire(pos:Vector3)->void:
	var f := OmniLight3D.new(); f.position=pos+Vector3(0,.5,0); f.light_color=Color(1,.28,.08); f.light_energy=1.5; f.omni_range=3; fx_root.add_child(f)

func add_unit_mesh(uid:String, u:Dictionary, pos:Vector3, h:Dictionary)->void:
	var group := Node3D.new(); group.name=uid; group.position=pos+Vector3(0,.55+float(TERRAIN[h.terrain].h),0); unit_root.add_child(group)
	var body := MeshInstance3D.new(); var cap:=CapsuleMesh.new(); cap.radius=.19; cap.height=.75; body.mesh=cap; body.material_override=mat("unit"+str(u.owner), Color(state.players[u.owner].color)); group.add_child(body)
	var head := MeshInstance3D.new(); var sp:=SphereMesh.new(); sp.radius=.16; head.mesh=sp; head.position=Vector3(0,.55,0); head.material_override=mat("skin",Color("#8b6f58")); group.add_child(head)
	var weapon := MeshInstance3D.new(); var wm:=CylinderMesh.new(); wm.top_radius=.025; wm.bottom_radius=.025; wm.height=.85; weapon.mesh=wm; weapon.position=Vector3(.25,.25,0); weapon.rotation_degrees.z=80; weapon.material_override=mat("iron",Color("#90877a")); group.add_child(weapon)
	if uid==selected_unit:
		var r := MeshInstance3D.new(); var tm:=TorusMesh.new(); tm.inner_radius=.38; tm.outer_radius=.45; r.mesh=tm; r.position=Vector3(0,-.36,0); r.material_override=mat("select",Color("#f0c678")); group.add_child(r)

func add_weather_fx()->void:
	var weather := str(state.get("weather","clear"))
	if weather in ["fog","ashfall","storm"]:
		for i in range(24):
			var w := MeshInstance3D.new(); var sm:=SphereMesh.new(); sm.radius=randf_range(.04,.12); w.mesh=sm; w.position=Vector3(randf_range(-12,12),randf_range(1,5),randf_range(-12,12)); w.material_override=mat("mist",Color(0.45,0.45,0.42,.45)); fx_root.add_child(w)

func _process(_delta: float) -> void:
	update_camera()

func update_camera()->void:
	if not cam: return
	var p := pitch; var z := zoom
	if close_view: p=-0.42; z=max(7.0,zoom*.5)
	var dir := Vector3(cos(p)*sin(yaw), sin(p), cos(p)*cos(yaw)).normalized()
	cam.position = focus - dir*z; cam.look_at(focus, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e:=event as InputEventMouseButton
		if e.button_index==MOUSE_BUTTON_WHEEL_UP and e.pressed: zoom=max(6.0,zoom-1.0)
		elif e.button_index==MOUSE_BUTTON_WHEEL_DOWN and e.pressed: zoom=min(34.0,zoom+1.0)
		elif e.button_index==MOUSE_BUTTON_RIGHT: right_drag=e.pressed
		elif e.button_index==MOUSE_BUTTON_MIDDLE: middle_drag=e.pressed
		elif e.button_index==MOUSE_BUTTON_LEFT and e.pressed and phase=="game": click_world(e.position)
	elif event is InputEventMouseMotion:
		var m:=event as InputEventMouseMotion
		if right_drag: yaw-=m.relative.x*.008; pitch=clamp(pitch-m.relative.y*.006,-1.35,-.35)
		elif middle_drag: focus += (-cam.global_transform.basis.x*m.relative.x + cam.global_transform.basis.z*m.relative.y)*.018; focus.y=0
	elif event is InputEventKey:
		var k:=event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode==KEY_F: close_view=!close_view
			elif k.keycode==KEY_SPACE: focus=Vector3.ZERO

func click_world(screen:Vector2)->void:
	if state.is_empty(): return
	var o:=cam.project_ray_origin(screen); var d:=cam.project_ray_normal(screen)
	if abs(d.y)<.001: return
	var hit:=o+d*(-o.y/d.y); var best:=""; var bd:=999.0
	for key in state.hexes.keys():
		var h=state.hexes[key]; var p=axial_pos(h.q,h.r); var dd=Vector2(p.x,p.z).distance_to(Vector2(hit.x,hit.z))
		if dd<bd: bd=dd; best=key
	if bd>HEX_SIZE*1.05: return
	var unit := unit_on_hex(best)
	if unit!="" and state.units[unit].owner==local_id:
		selected_unit=unit; selected_hex=best; show_game(); return
	if selected_unit!="" and state.units.has(selected_unit):
		var u=state.units[selected_unit]
		if u.owner==local_id:
			if unit!="" and state.units[unit].owner!=local_id: add_or_replace({"type":"attack","unit":selected_unit,"target":best,"attack":attack_kind,"pull":aim_pull,"breath":aim_breath,"lead":aim_lead})
			elif dist_keys(u.hex,best)<=int(u.move): add_or_replace({"type":"move","unit":selected_unit,"to":best})
	selected_hex=best; show_game()

func unit_on_hex(hex:String)->String:
	for uid in state.get("units",{}).keys():
		var u=state.units[uid]
		if u.hex==hex and int(u.get("captured_by",0))==0: return uid
	return ""

func add_or_replace(o:Dictionary)->void:
	if o.type in ["move","attack"]:
		for i in range(local_orders.size()-1,-1,-1): if local_orders[i].get("unit","")==o.unit and local_orders[i].type in ["move","attack"]: local_orders.remove_at(i)
	if local_orders.size()<10: local_orders.append(o)

func queue_build(kind:String)->void:
	if selected_hex!="" and state.hexes.has(selected_hex) and state.hexes[selected_hex].owner==local_id: add_or_replace({"type":"build","hex":selected_hex,"structure":kind}); show_game()
func queue_recruit(kind:String)->void:
	if selected_hex!="" and state.hexes.has(selected_hex) and state.hexes[selected_hex].owner==local_id: add_or_replace({"type":"recruit","hex":selected_hex,"unit":kind}); show_game()
func queue_tribute()->void:
	var t:=next_enemy_id(); if t!=0: local_orders.append({"type":"tribute","target":t,"give":{"gold":2,"food":1}}); show_game()
func queue_diplomacy()->void:
	var t:=next_enemy_id(); if t!=0: local_orders.append({"type":"diplomacy","target":t,"stance":"oath"}); show_game()
func clear_orders()->void: local_orders=[]; show_game()
func next_enemy_id()->int:
	var ids=state.get("players",{}).keys(); ids.sort(); for id in ids: if int(id)!=local_id and bool(state.players[id].alive): return int(id); return 0

func submit_orders()->void:
	if phase!="game": return
	if is_host:
		sealed_orders[local_id]=local_orders.duplicate(true); try_resolve()
	else:
		rpc_submit_orders.rpc_id(1, local_id, local_orders.duplicate(true))
	local_orders=[]; update_hud()

@rpc("any_peer", "call_remote", "reliable")
func rpc_submit_orders(pid:int, orders:Array)->void:
	if not is_host: return
	var sender:=multiplayer.get_remote_sender_id(); var effective:=sender
	if sender==1: effective=pid
	if not state.players.has(effective): return
	sealed_orders[effective]=orders.duplicate(true); state.events=["%d / %d realms have sealed orders." % [sealed_orders.size(), alive_ids().size()]]; broadcast_state(false); try_resolve()

func alive_ids()->Array:
	var a:=[]; for id in state.get("players",{}).keys(): if bool(state.players[id].alive): a.append(id); return a

func try_resolve()->void:
	if not is_host: return
	for id in alive_ids(): if not sealed_orders.has(id): return
	resolve_turn(); sealed_orders={}; broadcast_state(true)

func can_pay(p:Dictionary, cost:Dictionary)->bool:
	for r in cost.keys(): if int(p.resources.get(r,0)) < int(cost[r]): return false
	return true
func pay(p:Dictionary, cost:Dictionary)->void:
	for r in cost.keys(): p.resources[r]=int(p.resources.get(r,0))-int(cost[r])
func gain(p:Dictionary, inc:Dictionary)->void:
	for r in inc.keys(): p.resources[r]=int(p.resources.get(r,0))+int(inc[r])

func resolve_turn()->void:
	var events:=[]
	for id in alive_ids(): income_for(id, events)
	for id in alive_ids(): for o in sealed_orders.get(id,[]): if o.type in ["build","recruit","tribute","diplomacy"]: resolve_order(id,o,events)
	var moves:=[]; for id in alive_ids(): for o in sealed_orders.get(id,[]): if o.type=="move": moves.append([id,o])
	var claims:={}; for x in moves: claims[str(x[1].to)]=claims.get(str(x[1].to),0)+1
	for x in moves: if claims[str(x[1].to)]==1: resolve_order(x[0],x[1],events)
	for id in alive_ids(): for o in sealed_orders.get(id,[]): if o.type=="attack": resolve_order(id,o,events)
	capture_territory(events); environment_step(events); update_scores(state)
	var win:=winner_id(); if win!=0: state.winner=win; events.push_front("%s wins the Black Octagon." % owner_name(win))
	state.turn += 1; state.weather = WEATHER.pick_random(); state.events = events.slice(0,18)

func income_for(id:int, events:Array)->void:
	var p=state.players[id]
	for key in state.hexes.keys():
		var h=state.hexes[key]
		if int(h.owner)==id:
			gain(p, TERRAIN[h.terrain].income)
			if h.structure!="" and STRUCTURES.has(h.structure): gain(p, STRUCTURES[h.structure].income)
	events.append("%s collects taxes, grain, relics, and iron." % p.faction)

func resolve_order(id:int, o:Dictionary, events:Array)->void:
	match str(o.type):
		"build":
			if not state.hexes.has(o.hex) or not STRUCTURES.has(o.structure): return
			var h=state.hexes[o.hex]; var p=state.players[id]; var st=STRUCTURES[o.structure]
			if h.owner==id and h.structure=="" and can_pay(p,st.cost): pay(p,st.cost); h.structure=o.structure; h.hp=st.hp; events.append("%s raises a %s." % [p.faction, st.name])
		"recruit":
			if not state.hexes.has(o.hex) or not UNITS.has(o.unit): return
			var h2=state.hexes[o.hex]; var p2=state.players[id]; var ud=UNITS[o.unit]
			if h2.owner==id and can_pay(p2,ud.cost) and unit_on_hex(o.hex)=="": pay(p2,ud.cost); add_unit(state,id,o.unit,o.hex); events.append("%s recruits %s." % [p2.faction, ud.name])
		"tribute":
			var t=int(o.target); if not state.players.has(t): return
			if can_pay(state.players[id], o.give): pay(state.players[id], o.give); gain(state.players[t], o.give); events.append("%s sends tribute to %s." % [owner_name(id), owner_name(t)])
		"diplomacy":
			var d=int(o.target); if not state.players.has(d): return
			if state.players[id].oaths.has(d): state.players[id].oaths.erase(d); state.players[id].betrayals+=1; events.append("%s betrays the blood oath with %s." % [owner_name(id),owner_name(d)])
			else: state.players[id].oaths[d]=true; events.append("%s offers a blood oath to %s." % [owner_name(id),owner_name(d)])
		"move":
			if not state.units.has(o.unit) or not state.hexes.has(o.to): return
			var u=state.units[o.unit]
			if u.owner==id and int(u.captured_by)==0 and dist_keys(u.hex,o.to)<=int(u.move) and unit_on_hex(o.to)=="": u.hex=o.to; events.append("%s moves through the mud." % u.name)
		"attack": resolve_attack(id,o,events)

func resolve_attack(id:int, o:Dictionary, events:Array)->void:
	if not state.units.has(o.unit) or not state.hexes.has(o.target): return
	var a=state.units[o.unit]
	if a.owner!=id or int(a.captured_by)!=0: return
	var target_uid:=""
	for uid in state.units.keys():
		var u=state.units[uid]
		if u.hex==o.target and u.owner!=id and int(u.captured_by)==0: target_uid=uid; break
	if target_uid=="": return
	var t=state.units[target_uid]; var dist=dist_keys(a.hex,t.hex); var atk=ATTACKS.get(o.get("attack","woundline"), ATTACKS.woundline)
	if dist > int(a.range)+int(atk.range): events.append("%s's shot dies in the rain before reaching %s." % [a.name,t.name]); return
	var ideal_pull=.31+.06*float(a.skill); var ideal_breath=.55; var ideal_lead=clamp(.26+.08*dist,0,1)
	var aim=1.0-(abs(float(o.get("pull",.5))-ideal_pull)+abs(float(o.get("breath",.5))-ideal_breath)+abs(float(o.get("lead",.5))-ideal_lead))/3.0
	var cover=.0; var th=state.hexes[t.hex]; if th.terrain in ["forest","stone","village"]: cover=.12; if int(th.get("flood",0))>0: cover+=.06
	var weather_pen={"clear":0.0,"fog":.10,"rain":.08,"ashfall":.12,"storm":.18}.get(state.weather,0)
	var chance=clamp(.20+aim*.48+float(a.skill)*.06+float(atk.skill)-cover-weather_pen-float(dist)*.04, .05,.93)
	var rng:=RandomNumberGenerator.new(); rng.seed=hash(str(state.turn)+o.unit+t.id+str(o.get("pull",0))+state.weather)
	if rng.randf()<=chance:
		var dmg=max(1,int(round(float(a.attack)*float(atk.damage)+aim*3.0-float(t.armor)*.45)))
		if bool(a.wounded): dmg=max(1,dmg-1)
		t.hp -= dmg; events.append("%s lands %s on %s for %d." % [a.name, atk.name, t.name, dmg])
		if t.hp<=0: casualty(target_uid,id,rng,events)
	else:
		events.append("%s misses %s; mud, fear, and bad breath timing spoil the line." % [a.name,t.name])

func casualty(uid:String, killer:int, rng:RandomNumberGenerator, events:Array)->void:
	var u=state.units[uid]; var roll=rng.randf()
	if roll<.18:
		u.hp=max(1,int(u.max_hp*.35)); u.wounded=true; events.append("%s is left wounded in the muck." % u.name)
	elif roll<.32:
		u.hp=1; u.captured_by=killer; events.append("%s is captured for ransom by %s." % [u.name, owner_name(killer)])
	else:
		events.append("%s dies permanently." % u.name); state.units.erase(uid)

func capture_territory(events:Array)->void:
	for uid in state.units.keys():
		var u=state.units[uid]
		if int(u.captured_by)!=0: continue
		var enemies:=false
		for vid in state.units.keys(): if vid!=uid and state.units[vid].hex==u.hex and state.units[vid].owner!=u.owner and int(state.units[vid].captured_by)==0: enemies=true
		if not enemies and state.hexes.has(u.hex) and int(state.hexes[u.hex].owner)!=int(u.owner): state.hexes[u.hex].owner=u.owner; events.append("%s claims %s." % [owner_name(u.owner), u.hex])

func environment_step(events:Array)->void:
	for key in state.hexes.keys():
		var h=state.hexes[key]
		if int(h.burn)>0: h.burn=max(0,int(h.burn)-1)
		if int(h.flood)>0: h.flood=max(0,int(h.flood)-1)
		if randf()<.015 and h.terrain in ["forest","village"]: h.burn=3; events.append("Fire crawls across %s." % key)
		if state.weather=="storm" and randf()<.025: h.flood=2
		if state.weather=="ashfall" and randf()<.025: h.ash=2

func update_scores(s:Dictionary)->void:
	for id in s.players.keys():
		var score:=0; var p=s.players[id]
		for key in s.hexes.keys():
			var h=s.hexes[key]
			if int(h.owner)==int(id): score+=1; if h.structure!="": score+=int(STRUCTURES[h.structure].score)
		for uid in s.units.keys(): if int(s.units[uid].owner)==int(id) and int(s.units[uid].captured_by)==0: score+=int(s.units[uid].score)
		for r in RES: score += int(p.resources.get(r,0))/10
		p.score=score

func winner_id()->int:
	var best:=0; var bs:=-1
	for id in state.players.keys():
		if int(state.players[id].score)>bs: bs=int(state.players[id].score); best=int(id)
	if bs>=TARGET_SCORE or int(state.turn)>=TURN_LIMIT: return best
	return 0
