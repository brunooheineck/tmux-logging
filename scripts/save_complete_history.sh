#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/shared.sh"

main() {
	if supported_tmux_version_ok; then
		local custom_filename
		tmux command-prompt -p "Custom filename" "set-option -gq @custom_filename '%1'"
		custom_filename="$(get_tmux_option "@custom_filename")"
		
		local file
		if [ -n "$custom_filename" ];then
			local template
			custom_filename=$(echo "${save_complete_history_full_filename_custom}" | sed 's/custom_name/'"$custom_filename"'/')
			file=$(expand_tmux_format_path "${custom_filename}")
		else
			file=$(expand_tmux_format_path "${save_complete_history_full_filename}")
		fi

		local cursor_y scroll default_line_start history_size selection_start_y selection_end_y selection_active

		cursor_y="$(tmux display-message -p "#{copy_cursor_y}")"
		scroll="$(tmux display-message -p "#{scroll_position}")"
		history_size="$(tmux display-message -p "#{history_size}")"
		selection_start_y="$(tmux display-message -p -F "#{selection_start_y}")"
		selection_end_y="$(tmux display-message -p -F "#{selection_end_y}")"
		selection_active="$(tmux display-message -p -F "#{selection_active}")"

		if [ "$selection_active" -eq 1 ];then
			line_start=$((selection_start_y - history_size))
			line_end=$((selection_end_y - history_size))
		else
			custom_line_start=$((cursor_y - scroll))
			custom_line_end="-"
			tmux command-prompt -p "Line Start" -I "${custom_line_start}" "set-option -gq @line_start '%1'"
			tmux command-prompt -p "Line End" -I "${custom_line_end}" "set-option -gq @line_end '%1'"
			line_start="$(get_tmux_option "@line_start")"
			line_end="$(get_tmux_option "@line_end")"
		fi

		local history_limit
		if [ -n "$line_start" ];then
			history_limit="$line_start"
		else
			history_limit="$(tmux display-message -p -F "#{history_limit}")"
		fi


		tmux capture-pane -J -S "${history_limit}" -E "$line_end" -p > "${file}"
		remove_empty_lines_from_end_of_file "${file}"
		sed -i -e '/^>/d' -e '/\+S ──/d' -e '/▌ \d*\s*\w*/d' -e 's/\$ $/$\n/' "${file}"
		display_message "History saved to ${file}"
	fi
}
main
