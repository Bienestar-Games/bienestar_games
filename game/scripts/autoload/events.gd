extends Node

# Wave lifecycle
signal wave_started(wave_number: int)
signal wave_ended

# Decision phase
signal decision_phase_started

# Extraction
signal extraction_started
signal extraction_cancelled
signal extraction_completed

# Run end — extracted=true means successful extraction, false means death
signal run_ended(extracted: bool)

# Barrier
signal barrier_opened
