class_name ButtonHoverScaleAnimation;

extends Button

enum AnimationState {
	HoverGrowing,
	UnhoverShrinking
}

func _init():
	pass

var animation_state: AnimationState = AnimationState.UnhoverShrinking;
var animation_player: AnimationPlayer = null;

func _ready() -> void:
	animation_player = self.get_child(0);
	pass

func _process(_delta: float) -> void:
	var is_selected = is_hovered() || self.has_focus();
	
	if is_selected && animation_state == AnimationState.UnhoverShrinking:
		animation_state = AnimationState.HoverGrowing;
		if animation_player != null:
			animation_player.play("Select");
	elif !is_selected && animation_state == AnimationState.HoverGrowing:
		animation_state = AnimationState.UnhoverShrinking;
		if animation_player != null:
			animation_player.play_backwards("Select");
	pass
