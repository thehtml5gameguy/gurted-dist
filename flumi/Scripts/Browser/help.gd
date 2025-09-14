extends PopupPanel

@onready var shortcuts_tab: Button = $HSplitContainer/Sidebar/VBoxContainer/TabShortcuts
@onready var browser_tab: Button = $HSplitContainer/Sidebar/VBoxContainer/TabBrowser
@onready var protocol_tab: Button = $HSplitContainer/Sidebar/VBoxContainer/TabProtocol
@onready var scripting_tab: Button = $HSplitContainer/Sidebar/VBoxContainer/TabScripting

@onready var shortcuts_panel: VBoxContainer = $HSplitContainer/Content/ScrollContainer/ContentStack/ShortcutsPanel
@onready var browser_panel: VBoxContainer = $HSplitContainer/Content/ScrollContainer/ContentStack/BrowserPanel
@onready var protocol_panel: VBoxContainer = $HSplitContainer/Content/ScrollContainer/ContentStack/ProtocolPanel
@onready var scripting_panel: VBoxContainer = $HSplitContainer/Content/ScrollContainer/ContentStack/ScriptingPanel

func _ready() -> void:
	shortcuts_tab.pressed.connect(_on_shortcuts_tab_pressed)
	browser_tab.pressed.connect(_on_browser_tab_pressed)
	protocol_tab.pressed.connect(_on_protocol_tab_pressed)
	scripting_tab.pressed.connect(_on_scripting_tab_pressed)
	
	show_shortcuts_panel()

func _on_shortcuts_tab_pressed() -> void:
	show_shortcuts_panel()

func _on_browser_tab_pressed() -> void:
	show_browser_panel()

func _on_protocol_tab_pressed() -> void:
	show_protocol_panel()

func _on_scripting_tab_pressed() -> void:
	show_scripting_panel()

func show_shortcuts_panel() -> void:
	shortcuts_panel.visible = true
	browser_panel.visible = false
	protocol_panel.visible = false
	scripting_panel.visible = false
	
	update_tab_colors(shortcuts_tab)

func show_browser_panel() -> void:
	shortcuts_panel.visible = false
	browser_panel.visible = true
	protocol_panel.visible = false
	scripting_panel.visible = false
	
	update_tab_colors(browser_tab)

func show_protocol_panel() -> void:
	shortcuts_panel.visible = false
	browser_panel.visible = false
	protocol_panel.visible = true
	scripting_panel.visible = false
	
	update_tab_colors(protocol_tab)

func show_scripting_panel() -> void:
	shortcuts_panel.visible = false
	browser_panel.visible = false
	protocol_panel.visible = false
	scripting_panel.visible = true
	
	update_tab_colors(scripting_tab)

func update_tab_colors(active_tab: Button) -> void:
	var tabs = [shortcuts_tab, browser_tab, protocol_tab, scripting_tab]
	
	for tab in tabs:
		if tab == active_tab:
			tab.modulate = Color.WHITE
			tab.add_theme_color_override("font_color", Color.WHITE)
		else:
			tab.modulate = Color(0.8, 0.8, 0.8)
			tab.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
