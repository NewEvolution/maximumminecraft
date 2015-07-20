on run
  set prefsPath to (path to application support from user domain as text) & "minecraft:MM_Preferences.txt"
  set savesFolder to (path to application support from user domain as text) & "minecraft:saves:"
  try
    set preferencesFile to open for access alias prefsPath
    set preferencesList to read preferencesFile using delimiter ","
    close access preferencesFile
    set driveTypeToUse to item 3 of preferencesList as text
    set announceActions to item 13 of preferencesList as text
    set announcementVoice to item 14 of preferencesList as text
    if driveTypeToUse is not "RAM Disk" then
      activate me
      beep
      display alert "Synchronization works with RAM disk only!" message "This synch service only works when you're running Minecraft using the RAM disk option in MaximumMinecraft." as warning
    else
      try
        do shell script "ls /Volumes/Minemaster/"
        set chosenSavesFolder to (result as text)
        do shell script "rsync -qrtu /Volumes/Minemaster/" & quoted form of chosenSavesFolder & "/* " & quoted form of POSIX path of savesFolder & "." & quoted form of chosenSavesFolder
        if announceActions is "growl" then
          tell application "GrowlHelperApp"
            notify with name "Startup Notifications" title "" description "Saves synchronized with RAM disk" application name "MaximumMinecraft"
          end tell
        else
          say "Synchronized" using announcementVoice
        end if
      on error
        activate me
        beep
        display alert "Synchronization works with MaximumMinecraft only!" message "This synch service only works when you're running Minecraft using the RAM disk option in MaximumMinecraft." as warning
      end try
    end if
  on error
    activate me
    beep
    display alert "Preferences File Not Found!" message "The Synch with RAM disk service could not read/find the MaximumMinecraft preferences file. This service will be unable to synchronize the working save & backup save until MaximumMinecraft is run again and a new preferences file is generated." as warning
  end try
end run
        