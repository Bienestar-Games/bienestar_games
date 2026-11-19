extends Node

# Wave lifecycle
signal wave_started(wave_number: int)
signal wave_ended

# Decision phase (B34): short pause between waves so the next-wave preview can show.
signal decision_phase_started

# Run end — only the player's death ends the run (waves escalate forever).
signal run_ended

# Barrier
signal barrier_opened

# Threat (B29): hidden multiplier of the current or upcoming wave. Never shown as a number.
signal threat_changed(multiplier: float)
# Risk level (B30): ThreatManager.RiskLevel derived from the threat multiplier.
signal risk_level_changed(risk_level: int)
