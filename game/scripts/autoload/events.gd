extends Node

# Wave lifecycle
signal wave_started(wave_number: int)
signal wave_ended

# Decision phase
signal decision_phase_started

# Extraction
signal extraction_started
signal extraction_progress_updated(progress: float)
signal extraction_cancelled
signal extraction_completed

# Run end — extracted=true means successful extraction, false means death
signal run_ended(extracted: bool)

# Threat (B29): hidden multiplier of the current or upcoming wave. Never shown as a number.
signal threat_changed(multiplier: float)
# Risk level (B30): ThreatManager.RiskLevel derived from the threat multiplier.
signal risk_level_changed(risk_level: int)
