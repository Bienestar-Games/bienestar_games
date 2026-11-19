shader_type canvas_item;

// Hit flash: turns a sprite white for an instant when it takes damage, keeping its shape
// (alpha) intact. Applied after the modulate tint, so tinted enemies flash white too.
// Enemy drives 'flash_amount' from 1 to 0 every time it is hit.
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash_amount), base.a);
}
