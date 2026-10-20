extends Node3D

const SAVE_PATH := "user://anti_nationals_save.json"
const NPC_COUNT := 12

var game_seconds := 0.0
var clock_speed := 1.0
var incident_started := false
var incident_outcome := "No public incident yet."
var reputation := 0
var recorded := false
var pressure := 0.0
var npcs: Array[Node3D] = []
var people: Array[Dictionary] = []
var notes: Array[String] = []
var headline: Label
var stats: Label
var journal: Label

func _ready() -> void:
    _make_world()
    _make_player()
    _make_people()
    _make_ui()
    _note("You arrive at a university courtyard in a city that never minds its own business.")
    _note("Explore. A public argument will develop without your input.")

func _process(delta: float) -> void:
    game_seconds += delta * clock_speed
    if not incident_started and game_seconds >= 12.0:
        _begin_incident()
    if incident_started and incident_outcome == "The argument is still unfolding.":
        pressure += delta * 0.06
        if pressure > 0.75:
            incident_outcome = "The argument attracts a crowd. Tempers are rising."
    _move_people(delta)
    _refresh_ui()

func _make_world() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.10, 0.15, 0.21)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.60, 0.68)
    env.ambient_light_energy = 0.8
    env_node.environment = env
    add_child(env_node)

    var sun := DirectionalLight3D.new()
    sun.rotation = Vector3(-0.9, -0.6, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    var ground := StaticBody3D.new()
    var ground_mesh := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(34, 0.2, 34)
    ground_mesh.mesh = plane
    ground_mesh.position.y = -0.1
    ground_mesh.material_override = _mat(Color(0.28, 0.30, 0.28))
    ground.add_child(ground_mesh)
    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(34, 0.2, 34)
    ground_collision.shape = ground_shape
    ground_collision.position.y = -0.1
    ground.add_child(ground_collision)
    add_child(ground)

    _building(Vector3(-9, 1.5, -9), Vector3(5, 3, 5), Color(0.58, 0.46, 0.35), "ADMIN BLOCK")
    _building(Vector3(8, 1.7, -10), Vector3(6, 3.4, 5), Color(0.34, 0.46, 0.53), "STUDENT UNION")
    _building(Vector3(-11, 1.3, 8), Vector3(4, 2.6, 5), Color(0.49, 0.42, 0.33), "CANTEEN")
    _building(Vector3(11, 1.3, 7), Vector3(4, 2.6, 5), Color(0.47, 0.40, 0.37), "NOTICE BOARD")

func _building(pos: Vector3, size: Vector3, colour: Color, sign_text: String) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh_instance.mesh = box
    mesh_instance.material_override = _mat(colour)
    body.add_child(mesh_instance)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    var sign := Label3D.new()
    sign.text = sign_text
    sign.position = pos + Vector3(0, size.y / 2 + 0.3, 0)
    sign.font_size = 48
    sign.modulate = Color(1.0, 0.85, 0.55)
    add_child(sign)

func _make_player() -> void:
    var player := CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.0, 5)
    player.set_script(load("res://scripts/player.gd"))
    add_child(player)

func _make_people() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 204
    var names := ["Aarav", "Meher", "Kabir", "Zoya", "Rafi", "Ishita", "Dev", "Sana", "Manav", "Noor", "Tara", "Imran"]
    var traits := ["curious", "nervous", "loyal", "cynical", "attention-seeking", "calm"]
    for i in range(NPC_COUNT):
        var npc := Node3D.new()
        npc.name = "NPC_%02d" % i
        npc.position = Vector3(rng.randf_range(-10, 10), 0.9, rng.randf_range(-6, 11))
        var mesh_instance := MeshInstance3D.new()
        var capsule := CapsuleMesh.new()
        capsule.radius = 0.32
        capsule.height = 1.8
        mesh_instance.mesh = capsule
        mesh_instance.material_override = _mat(Color.from_hsv(rng.randf(), 0.4, rng.randf_range(0.45, 0.85)))
        npc.add_child(mesh_instance)
        var label := Label3D.new()
        label.text = names[i]
        label.position.y = 1.25
        label.font_size = 28
        label.modulate = Color(0.95, 0.92, 0.82)
        npc.add_child(label)
        add_child(npc)
        npcs.append(npc)
        people.append({"name": names[i], "trait": traits[rng.randi_range(0, traits.size()-1)], "target": npc.position, "speed": rng.randf_range(0.4, 1.0), "cooldown": rng.randf_range(1.0, 4.0), "witnessed": false, "reaction": "wandering"})

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    var title := Label.new()
    title.text = "ANTI-NATIONALS  |  UNIVERSITY BLOCK"
    title.position = Vector2(18, 12)
    title.add_theme_font_size_override("font_size", 20)
    root.add_child(title)

    headline = Label.new()
    headline.position = Vector2(18, 48)
    headline.size = Vector2(550, 80)
    headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    headline.add_theme_font_size_override("font_size", 18)
    headline.add_theme_color_override("font_color", Color(1.0, 0.78, 0.52))
    root.add_child(headline)

    stats = Label.new()
    stats.anchor_left = 1.0
    stats.anchor_right = 1.0
    stats.offset_left = -290
    stats.offset_right = -18
    stats.offset_top = 15
    stats.offset_bottom = 100
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    root.add_child(stats)

    var buttons := VBoxContainer.new()
    buttons.anchor_left = 1.0
    buttons.anchor_top = 1.0
    buttons.anchor_right = 1.0
    buttons.anchor_bottom = 1.0
    buttons.offset_left = -220
    buttons.offset_top = -300
    buttons.offset_right = -18
    buttons.offset_bottom = -18
    buttons.add_theme_constant_override("separation", 7)
    root.add_child(buttons)
    _button(buttons, "E  Interact", _interact)
    _button(buttons, "Record incident", _record)
    _button(buttons, "Try to calm them", _calm)
    _button(buttons, "Provoke argument", _provoke)
    _button(buttons, "Walk away", _walk_away)
    _button(buttons, "Save game", _save_game)
    _button(buttons, "Load game", _load_game)

    var journal_panel := PanelContainer.new()
    journal_panel.anchor_top = 1.0
    journal_panel.anchor_bottom = 1.0
    journal_panel.offset_left = 18
    journal_panel.offset_top = -190
    journal_panel.offset_right = 480
    journal_panel.offset_bottom = -18
    root.add_child(journal_panel)
    journal = Label.new()
    journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    journal.add_theme_font_size_override("font_size", 14)
    journal_panel.add_child(journal)

    var speed_row := HBoxContainer.new()
    speed_row.position = Vector2(18, 132)
    root.add_child(speed_row)
    var speed_label := Label.new()
    speed_label.text = "Clock speed"
    speed_row.add_child(speed_label)
    var slider := HSlider.new()
    slider.custom_minimum_size = Vector2(150, 24)
    slider.min_value = 0.25
    slider.max_value = 3.0
    slider.step = 0.25
    slider.value = 1.0
    slider.value_changed.connect(func(value: float): clock_speed = value)
    speed_row.add_child(slider)

func _button(parent: VBoxContainer, text_value: String, action: Callable) -> void:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(190, 36)
    button.pressed.connect(action)
    parent.add_child(button)

func _begin_incident() -> void:
    incident_started = true
    incident_outcome = "The argument is still unfolding."
    pressure = 0.15
    _note("An argument erupts near the student union. Nobody agrees on what started it.")
    _note("Record it, intervene, provoke, or walk away.")
    if npcs.size() >= 2:
        npcs[0].position = Vector3(-1.2, 0.9, -1.0)
        npcs[1].position = Vector3(1.2, 0.9, -1.0)
        people[0]["reaction"] = "arguing"
        people[1]["reaction"] = "arguing"
    for i in range(2, people.size()):
        if people[i]["trait"] in ["curious", "attention-seeking", "cynical"]:
            people[i]["witnessed"] = true
            people[i]["reaction"] = "watching"

func _move_people(delta: float) -> void:
    for i in range(npcs.size()):
        var npc := npcs[i]
        var person: Dictionary = people[i]
        if person["reaction"] in ["arguing", "watching", "backing away", "taking sides", "getting a better view"]:
            if person["reaction"] == "backing away":
                npc.position = npc.position.move_toward(npc.position + Vector3(1, 0, 1), float(person["speed"]) * delta)
            elif person["reaction"] == "getting a better view":
                npc.look_at(Vector3(0, npc.position.y, -1), Vector3.UP)
            continue
        person["cooldown"] = float(person["cooldown"]) - delta
        if float(person["cooldown"]) <= 0:
            var rng := RandomNumberGenerator.new()
            rng.randomize()
            person["target"] = Vector3(rng.randf_range(-12, 12), 0.9, rng.randf_range(-12, 12))
            person["cooldown"] = rng.randf_range(2.0, 6.0)
        var target: Vector3 = person["target"]
        npc.position = npc.position.move_toward(target, float(person["speed"]) * delta)
        if npc.position.distance_to(target) > 0.2:
            npc.look_at(Vector3(target.x, npc.position.y, target.z), Vector3.UP)

func _interact() -> void:
    if not incident_started:
        _note("You scan the courtyard. Everyone seems busy.")
    else:
        _note("You step closer. What happens next depends on what you do.")
        reputation += 1

func _record() -> void:
    if not incident_started:
        _note("Nothing worth recording has happened yet.")
        return
    recorded = true
    reputation += 2
    pressure += 0.1
    _note("You record the argument. People notice the phone.")
    _witness_reactions("recording")

func _calm() -> void:
    if not incident_started:
        _note("There is nobody to calm down yet.")
        return
    if pressure < 0.65 or _has_trait("calm"):
        incident_outcome = "Your intervention helps break up the argument."
        pressure = 0.0
        reputation += 2
        _note("You try to calm things down. At least a few people listen.")
        for person in people:
            if person["reaction"] in ["arguing", "watching"]:
                person["reaction"] = "wandering"
    else:
        pressure += 0.2
        reputation -= 1
        incident_outcome = "Your attempt is interpreted as taking sides."
        _note("Your words are interpreted as taking sides. The situation gets worse.")

func _provoke() -> void:
    if not incident_started:
        _note("You cannot provoke an argument that has not started.")
        return
    pressure += 0.35
    reputation -= 1
    incident_outcome = "Your comment makes the argument louder. More people turn to look."
    _note("You provoke the situation. It works, which may not be a good thing.")
    _witness_reactions("provoking")

func _walk_away() -> void:
    if not incident_started:
        _note("You keep exploring the courtyard.")
        return
    incident_outcome = "You walk away. The city continues without you."
    _note("You leave the argument behind. Other people decide what happens next.")
    for person in people:
        if person["reaction"] == "watching":
            person["reaction"] = "wandering"

func _witness_reactions(action_name: String) -> void:
    for person in people:
        if not person["witnessed"]:
            continue
        if person["trait"] == "nervous":
            person["reaction"] = "backing away"
        elif person["trait"] == "attention-seeking":
            person["reaction"] = "getting a better view"
        elif person["trait"] == "loyal" and action_name == "provoking":
            person["reaction"] = "taking sides"
    _note("Witnesses react according to temperament and what they saw.")

func _has_trait(trait_name: String) -> bool:
    for person in people:
        if person["trait"] == trait_name:
            return true
    return false

func _save_game() -> void:
    var player := get_node_or_null("Player") as Node3D
    var data := {"game_seconds": game_seconds, "incident_started": incident_started, "incident_outcome": incident_outcome, "reputation": reputation, "recorded": recorded, "pressure": pressure, "notes": notes, "people": people, "player_position": player.position if player else Vector3(0, 1, 5)}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))
        file.close()
        _note("Game saved on this device.")
    else:
        _note("Save failed.")

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        _note("No save found on this device yet.")
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        _note("Load failed.")
        return
    var data = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(data) != TYPE_DICTIONARY:
        _note("Save file is invalid.")
        return
    game_seconds = float(data.get("game_seconds", 0))
    incident_started = bool(data.get("incident_started", false))
    incident_outcome = str(data.get("incident_outcome", "Loaded state."))
    reputation = int(data.get("reputation", 0))
    recorded = bool(data.get("recorded", false))
    pressure = float(data.get("pressure", 0))
    notes.clear()
    for line in data.get("notes", []):
        notes.append(str(line))
    var saved_people: Array = data.get("people", [])
    for i in range(min(saved_people.size(), people.size())):
        people[i] = saved_people[i]
    var player := get_node_or_null("Player") as Node3D
    if player:
        player.position = data.get("player_position", Vector3(0, 1, 5))
    _note("Saved state loaded.")

func _note(message: String) -> void:
    notes.append(message)
    while notes.size() > 7:
        notes.pop_front()
    _refresh_ui()

func _refresh_ui() -> void:
    if not is_instance_valid(headline):
        return
    var game_minutes := int(game_seconds * 2.0) % 1440
    headline.text = "TIME %02d:%02d\nPUBLIC INCIDENT: %s" % [int(game_minutes / 60), game_minutes % 60, incident_outcome]
    stats.text = "REPUTATION %d\nEVIDENCE %s\nNPCs %d" % [reputation, "RECORDED" if recorded else "NONE", npcs.size()]
    journal.text = "FIELD NOTES\n" + "\n".join(notes)

func _mat(colour: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = 0.88
    return material
