set output to "["

tell application "Mail"
	set selectedMessages to selection
	repeat with i from 1 to count of selectedMessages
		set msg to item i of selectedMessages
		set theID to message id of msg
		set theHeaders to all headers of msg
		set theSubject to subject of msg
		set theContent to content of msg
		
		set jsonItem to "{"
		set jsonItem to jsonItem & "\"id\": " & quoted form of theID & ", "
		set jsonItem to jsonItem & "\"headers\": " & quoted form of theHeaders & ", "
		set jsonItem to jsonItem & "\"subject\": " & quoted form of theSubject & ", "
		set jsonItem to jsonItem & "\"content\": " & quoted form of theContent & "}"
		
		set output to output & jsonItem
		if i < (count of selectedMessages) then
			set output to output & ", "
		end if
	end repeat
end tell

set output to output & "]"
return output