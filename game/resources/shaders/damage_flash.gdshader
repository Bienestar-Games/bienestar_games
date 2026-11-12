shader_type canvas_item;

// Damage flash (GDD §4): a brief, even red tint over the whole screen when the player is hit.
// Deliberately flat (no edge falloff) so it never reads as the Death Border vignette,
// which is dark and closes in from the edges. DamageFlash drives 'intensity' from 1 to 0.
uniform vec4 flash_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float max_alpha : hint_range(0.0, 1.0) = 0.4;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR = vec4(flash_color.rgb, max_alpha * intensity);
}
