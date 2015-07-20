on run (goToHandler)
  if (goToHandler as text) is "checkForTrackpad" then
    checkForTrackpad()
  else if (goToHandler as text) is "loadSystemVoices" then
    loadSystemVoices()
  else if (goToHandler as text) is "enableServiceShortcut" then
    enableServiceShortcut()
  else if (goToHandler as text) is "disableTwoFingerScrolling" then
    disableTwoFingerScrolling()
  else if (goToHandler as text) is "enableTwoFingerScrolling" then
    enableTwoFingerScrolling()
  else if (goToHandler as text) is "disableMagicMouseScrolling" then
    disableMagicMouseScrolling()
  else if (goToHandler as text) is "enableMagicMouseScrolling" then
    enableMagicMouseScrolling()
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
  tell application "System Preferences"
    reveal (pane id "com.apple.preference.speech")
  end tell
  tell application "System Events"
    click radio button "Text to Speech" of tab group 1 of window "Speech" of process "System Preferences"
    repeat until (exists pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences")
      delay 0.2
    end repeat
    click pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences"
    set listOfVoices to name of every menu item of menu 1 of pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences"
    click menu item "Show More Voices" of menu 1 of pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences"
    click pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences"
    set listOfVoices to name of every menu item of menu 1 of pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences"
    click menu item "Show Fewer Voices" of menu 1 of pop up button "System Voice:" of tab group 1 of window "Speech" of process "System Preferences"
  end tell
  tell application "System Preferences" to quit
  set tempList to {}
  repeat with eachVoice in listOfVoices
    set voiceName to (eachVoice as text)
    if voiceName is not "Male" then
      if voiceName is not "missing value" then
        if voiceName is not "Female" then
          if voiceName is not "Novelty" then
            if voiceName is not "Show Fewer Voices" then
              copy voiceName to the end of tempList
            end if
          end if
        end if
      end if
    end if
  end repeat
  set listOfVoices to tempList
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
    select row 6 of table 1 of scroll area 1 of tab group 1 of window "Keyboard" of process "System Preferences"
    set focused of text field of last row of outline 1 of scroll area 2 of tab group 1 of window "Keyboard" of process "System Preferences" to true
  end tell
  activate application "System Preferences"
  tell application "System Events"
    keystroke "s" using command down
    keystroke "h" using command down
  end tell
end enableServiceShortcut

on disableTwoFingerScrolling()
  tell application "System Preferences"
    reveal (pane id "com.apple.preference.trackpad")
  end tell
  tell application "System Events"
    if value of checkbox "Scroll" of group 1 of window "Trackpad" of process "System Preferences" is 1 then
      set announceIt to true
      click checkbox "Scroll" of group 1 of window "Trackpad" of process "System Preferences"
    else
      set announceIt to false
    end if
  end tell
  return announceIt
end disableTwoFingerScrolling

on disableMagicMouseScrolling()
  tell application "System Preferences"
    reveal (pane id "com.apple.preference.mouse")
  end tell
  tell application "System Events"
    if value of checkbox "Scroll" of group 1 of window "Mouse" of process "System Preferences" is 1 then
      set announceIt to true
      click checkbox "Scroll" of group 1 of window "Mouse" of process "System Preferences"
    else
      set announceIt to false
    end if
  end tell
  return announceIt
end disableMagicMouseScrolling

on enableTwoFingerScrolling()
  tell application "System Preferences"
    reveal (pane id "com.apple.preference.trackpad")
  end tell
  tell application "System Events"
    if value of checkbox "Scroll" of group 1 of window "Trackpad" of process "System Preferences" is 0 then
      set announceIt to true
      click checkbox "Scroll" of group 1 of window "Trackpad" of process "System Preferences"
    else
      set announceIt to false
    end if
  end tell
  return announceIt
end enableTwoFingerScrolling

on enableMagicMouseScrolling()
  tell application "System Preferences"
    reveal (pane id "com.apple.preference.mouse")
  end tell
  tell application "System Events"
    if value of checkbox "Scroll" of group 1 of window "Mouse" of process "System Preferences" is 0 then
      set announceIt to true
      click checkbox "Scroll" of group 1 of window "Mouse" of process "System Preferences"
    else
      set announceIt to false
    end if
  end tell
  return announceIt
end enableMagicMouseScrolling
        