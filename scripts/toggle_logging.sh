#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/shared.sh"


start_pipe_pane() {
	# local file=$(expand_tmux_format_path "${logging_full_filename}")
	local pane_unique_id="$(pane_unique_id)"
	local file="$(get_tmux_option "@${pane_unique_id}_file")"
	"$CURRENT_DIR/start_logging.sh" "${file}"
	display_message "Started logging to $file"
}

stop_pipe_pane() {
	local pane_unique_id="$(pane_unique_id)"
	local file="$(get_tmux_option "@${pane_unique_id}_file")"
	tmux pipe-pane
	display_message "Ended logging to $file"
}

# returns a string unique to current pane
pane_unique_id() {
	tmux display-message -p "#{session_name}_#{window_index}_#{pane_index}"
}

# saving 'logging' 'not logging' status in a variable unique to pane
set_logging_variable() {
	local value="$1"
	local file="$2"
	local pane_unique_id="$(pane_unique_id)"
	tmux set-option -gq "@${pane_unique_id}" "$value"
	tmux set-option -gq "@${pane_unique_id}_file" "$file"
}

# this function checks if logging is happening for the current pane
is_logging() {
	local pane_unique_id="$(pane_unique_id)"
	local current_pane_logging="$(get_tmux_option "@${pane_unique_id}" "not logging")"
	if [ "$current_pane_logging" == "logging" ]; then
		return 0
	else
		return 1
	fi
}

# starts/stop logging
toggle_pipe_pane() {
	if is_logging; then
		stop_pipe_pane
		set_logging_variable "not logging"
	else
		local file=$(expand_tmux_format_path "${logging_full_filename}")
		set_logging_variable "logging" $file
		start_pipe_pane
	fi
}

main() {
	if supported_tmux_version_ok; then
		toggle_pipe_pane
	fi
}
main
