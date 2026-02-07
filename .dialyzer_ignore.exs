[
  # Splode generates t() types via macros that dialyzer can't resolve
  {"lib/xdk/errors.ex", :unknown_type},
  # Auto-generated patterns - Finch response types
  {"lib/xdk.ex", :pattern_match},
  {"lib/xdk/streaming.ex", :pattern_match}
]
