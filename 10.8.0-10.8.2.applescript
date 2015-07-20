on run (goToHandler)
  if (goToHandler as text) is "checkForTrackpad" then
    checkForTrackpad()
  else if (goToHandler as text) is "loadSystemVoices" then
    loadSystemVoices()
  else if (goToHandler as text) is "enableServiceShortcut" then
    enableServiceShortcut()
  end if
end run

on checkForTrackpad()
  tell application "System Preferences"
    set hasTrackpad to exists of (pane id "com.apple.preference.trackpad")
    quit
  end tell
  return hasTrackpad
end checkForTrackpad

on loadSystemVoices()
  set listOfVoices to {"Kathy", "Vicki", "Victoria", "Alex", "Bruce", "Fred", "Albert", "Bad News", "Bahh", "Bells", "Boing", "Bubbles", "Cellos", "Deranged", "Good News", "Hysterical", "Pipe Organ", "Trinoids", "Whisper", "Zarvox"}
  choose from list listOfVoices with title "MaximumMinecraft Setup: Announcement voice" with prompt "MaximumMinecraft can make its announcements in any of your system's text-to-speech voices.

I'd recommend going to the \"Speech\" preference pane in your System Preferences and checking them out since some are really annoying.

What voice should MaximumMinecraft make its announcements in?" default items {"Trinoids"}
  return result
end loadSystemVoices

on enableServiceShortcut()
  tell application "System Preferences"
    reveal (pane id "com.apple.preference.keyboard")
  end tell
  tell application "System Events"
    click radio button "Keyboard Shortcuts" of tab group 1 of window "Keyboard" of process "System Preferences"
    select row 5 of table 1 of scroll area 1 of splitter group 1 of tab group 1 of window "Keyboard" of process "System Preferences"
    click static text of last row of outline 1 of scroll area 2 of splitter group 1 of tab group 1 of window "Keyboard" of process "System Preferences"
    click button of last row of outline 1 of scroll area 2 of splitter group 1 of tab group 1 of window "Keyboard" of process "System Preferences"
  end tell
  activate application "System Preferences"
  activate me
  display alert "Manual shortcut settting required!" message "OS X 10.8 prevents scripts from setting service shortcut hotkeys.

Please click the open System Preferences window, scroll to the bottom of the right-hand list of services, click the highlighted \"add shortcut\" button, and then hold down the \"command ⌘\" key and press the \"S\" key to enable the Synch with RAM disk shortcut before clicking OK." as warning buttons {"OK"}
end enableServiceShortcut
        