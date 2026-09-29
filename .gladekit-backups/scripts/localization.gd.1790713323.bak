extends RefCounted
class_name Localization

const DEFAULT_LOCALE: String = "en"
const SUPPORTED_LOCALES: Array[String] = ["en", "fr", "ja"]

const STRINGS: Dictionary = {
	"en": {
		"language": "Language",
		"english": "English",
		"version": "v0.0.1",
		"audio": "AUDIO",
		"display": "DISPLAY",
		"accessibility": "ACCESSIBILITY",
		"french": "French",
		"japanese": "Japanese",
		"settings": "SETTINGS",
		"master_volume": "MASTER VOLUME",
		"music_volume": "MUSIC VOLUME",
		"sfx_volume": "SFX VOLUME",
		"fullscreen": "Fullscreen",
		"reduced_motion": "Reduced Motion",
		"haptics": "Haptics",
		"color_safe": "Color-Safe Notes",
		"back": "BACK",
		"play": "PLAY",
		"about": "ABOUT",
		"quit": "QUIT",
		"levels": "SELECT LEVEL",
		"editor": "LEVEL EDITOR",
		"playtest": "PLAYTEST",
		"reset": "RESET",
		"paused": "PAUSED",
		"resume": "RESUME",
		"restart": "RESTART",
		"quit_to_menu": "QUIT TO MENU",
		"drag_prompt": "DRAG ON THE BEAT  •  LONG NOTES NEED %d SLICES",
		"swipe_prompt": "SWIPE ON THE BEAT  •  LONG NOTES NEED %d SLICES",
		"core_integrity": "CORE INTEGRITY",
		"score": "SCORE",
		"beat": "BEAT",
		"combo": "COMBO",
		"perfect": "PERFECT",
		"good": "GOOD",
		"miss": "MISS",
		"core_lost": "CORE LOST",
		"level_clear": "LEVEL CLEAR",
		"tap_return": "TAP TO RETURN TO LEVELS"
	},
	"fr": {
		"language": "Langue",
		"english": "Anglais",
		"version": "v0.0.1",
		"audio": "AUDIO",
		"display": "AFFICHAGE",
		"accessibility": "ACCESSIBILITÉ",
		"french": "Français",
		"japanese": "Japonais",
		"settings": "PARAMÈTRES",
		"master_volume": "VOLUME GÉNÉRAL",
		"music_volume": "VOLUME MUSIQUE",
		"sfx_volume": "VOLUME EFFETS",
		"fullscreen": "Plein écran",
		"reduced_motion": "Mouvements réduits",
		"haptics": "Vibrations",
		"color_safe": "Notes adaptées aux couleurs",
		"back": "RETOUR",
		"play": "JOUER",
		"about": "À PROPOS",
		"quit": "QUITTER",
		"levels": "SÉLECTION DU NIVEAU",
		"editor": "ÉDITEUR DE NIVEAU",
		"playtest": "TESTER",
		"reset": "RÉINITIALISER",
		"paused": "PAUSE",
		"resume": "REPRENDRE",
		"restart": "RECOMMENCER",
		"quit_to_menu": "MENU PRINCIPAL",
		"drag_prompt": "GLISSEZ SUR LE TEMPS  •  NOTES LONGUES : %d COUPES",
		"swipe_prompt": "GLISSEZ SUR LE TEMPS  •  NOTES LONGUES : %d COUPES",
		"core_integrity": "INTÉGRITÉ DU CŒUR",
		"score": "SCORE",
		"beat": "TEMPS",
		"combo": "COMBO",
		"perfect": "PARFAIT",
		"good": "BIEN",
		"miss": "RATÉ",
		"core_lost": "CŒUR PERDU",
		"level_clear": "NIVEAU TERMINÉ",
		"tap_return": "TOUCHEZ POUR REVENIR AUX NIVEAUX"
	},
	"ja": {
		"language": "言語",
		"english": "英語",
		"version": "v0.0.1",
		"audio": "オーディオ",
		"display": "表示",
		"accessibility": "アクセシビリティ",
		"french": "フランス語",
		"japanese": "日本語",
		"settings": "設定",
		"master_volume": "マスター音量",
		"music_volume": "音楽の音量",
		"sfx_volume": "効果音の音量",
		"fullscreen": "フルスクリーン",
		"reduced_motion": "モーションを減らす",
		"haptics": "触覚フィードバック",
		"color_safe": "色覚対応ノート",
		"back": "戻る",
		"play": "プレイ",
		"about": "ゲームについて",
		"quit": "終了",
		"levels": "レベル選択",
		"editor": "レベルエディター",
		"playtest": "テストプレイ",
		"reset": "リセット",
		"paused": "一時停止",
		"resume": "再開",
		"restart": "やり直す",
		"quit_to_menu": "メニューへ戻る",
		"drag_prompt": "ビートに合わせてドラッグ  •  ロングノートは%d回スライス",
		"swipe_prompt": "ビートに合わせてスワイプ  •  ロングノートは%d回スライス",
		"core_integrity": "コア健全性",
		"score": "スコア",
		"beat": "ビート",
		"combo": "コンボ",
		"perfect": "PERFECT",
		"good": "GOOD",
		"miss": "MISS",
		"core_lost": "コア消失",
		"level_clear": "レベルクリア",
		"tap_return": "タップしてレベル選択へ戻る"
	}
}

static func current_locale() -> String:
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return DEFAULT_LOCALE
	var profile: Node = scene_tree.root.get_node_or_null("SaveManager")
	if profile == null:
		return DEFAULT_LOCALE
	var saved_locale: String = String(profile.call("get_value", "locale", DEFAULT_LOCALE))
	return saved_locale if saved_locale in SUPPORTED_LOCALES else DEFAULT_LOCALE


static func set_locale(locale: String) -> void:
	var selected_locale: String = locale if locale in SUPPORTED_LOCALES else DEFAULT_LOCALE
	TranslationServer.set_locale(selected_locale)
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return
	var profile: Node = scene_tree.root.get_node_or_null("SaveManager")
	if profile != null:
		profile.call("set_value", "locale", selected_locale)
		profile.call("save")


static func apply_saved_locale() -> void:
	TranslationServer.set_locale(current_locale())


static func text(key: String) -> String:
	var locale: String = current_locale()
	var table: Dictionary = STRINGS.get(locale, STRINGS[DEFAULT_LOCALE])
	return String(table.get(key, STRINGS[DEFAULT_LOCALE].get(key, key)))


static func locale_index(locale: String) -> int:
	return maxi(SUPPORTED_LOCALES.find(locale), 0)


static func locale_from_index(index: int) -> String:
	if index < 0 or index >= SUPPORTED_LOCALES.size():
		return DEFAULT_LOCALE
	return SUPPORTED_LOCALES[index]
