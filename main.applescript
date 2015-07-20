# Global variables

--Automatically set/read in from external files/chosen on run
global unwiseQuit
global growlInstalled
global resourcesFolder
global startupDisk
global minecraftPath
global backupOne
global backupTwo
global prefsPath
global savesPath
global systemInfo
global systemVersion
global systemMinimumVersion
global systemMaximumVersion
global supportedSystemVersion
global versionSpecificScript
global availableVersionSpecificScripts
global savesFolderLinked
global savesFolderTarget
global savesFolderTargetDisk
global worldFolderLinked
global worldFolderTarget
global savesFolderFound
global jarList
global versionsList
global doNotBackUpFile
global worldsExemptFromBackup
global chosenWorldPath
global ramDiskSectors
global runningApps
global protectedList
global freshServiceInstall
global jarToUse
global versionToUse
global minecraftType
global chosenWorldFolder
global recoveryChoice
global choiceZero
global choiceOne
global choiceTwo
--User set during initial preferences setup routine
global useMultiJars
global jarListPath
global useMultiVersions
global versionsListPath
global driveTypeToUse
global enableBackups
global disableTwoFingerScroll
global disableMagicMouseScroll
global quitRunningApps
global disableDesktopRotation
global disableTranslucence
global purgeRAM
global remoteSavesPath
global installSynchService
global announceActions
global announcementVoice

--Display growl notification function
on showGrowl(growlName, growlDescription)
  if growlInstalled is true then
    tell application id "com.Growl.GrowlHelperApp"
      notify with name growlName title "" description growlDescription application name "MaximumMinecraft"
    end tell
  end if
end showGrowl

#Check the OS X version to use the correct subscripts, the validity of the path to the saves folder, & if there is a preferences file saved
on run
  set unwiseQuit to false
  tell application "System Events"
    set growlInstalled to (count of (every process whose bundle identifier is "com.Growl.GrowlHelperApp")) > 0
  end tell
  if growlInstalled is true then
    tell application id "com.Growl.GrowlHelperApp"
      set the allNotificationsList to {"Startup Notifications", "Shutdown Notifications"}
      set the enabledNotificationsList to allNotificationsList
      register as application "MaximumMinecraft" all notifications allNotificationsList default notifications enabledNotificationsList icon of application "MaximumMinecraft"
    end tell
  end if
  set resourcesFolder to ((path to me as text) & "Contents:Resources:") as alias
  tell application "Finder"
    set startupDisk to name of startup disk
    set locatedOnDisk to name of disk of (path to me)
    if locatedOnDisk is "MaximumMinecraft" then
      display alert "MaximumMinecraft not on Startup Disk" message "You are attempting to run MaximumMinecraft from the disk image it came on.

That's really not going to work. 

Please copy the \"MaximumMinecraft.app\" file somewhere on the " & startupDisk & " drive and run MaximumMinecraft again." buttons {"Quit"} as warning
      quit
      return
    end if
    set scriptsFolder to ((resourcesFolder as text) & "Scripts:") as alias
    set availableVersionSpecificScripts to name of every item of folder scriptsFolder
  end tell
  set minecraftPath to (path to application support from user domain as text) & "minecraft:"
  set backupOne to minecraftPath & "saves.backup"
  set backupTwo to minecraftPath & "saves.backup.zip"
  set prefsPath to minecraftPath & "MM_Preferences.txt"
  set savesPath to minecraftPath & "saves"
  set doNotBackUpFile to minecraftPath & "MM_WorldsExemptFromBackup.txt"
  set systemInfo to (system info) as list
  set systemVersion to (third item of systemInfo) as text
  repeat with scriptName in availableVersionSpecificScripts
    if (scriptName as text) contains systemVersion then
      set versionSpecificScript to ((scriptsFolder as text) & scriptName) as alias
      exit repeat
    end if
    try
      set scriptMinVersion to first word of scriptName
      set scriptMaxVersion to second word of scriptName
      if systemVersion ≥ scriptMinVersion then
        if systemVersion ≤ scriptMaxVersion then
          set versionSpecificScript to ((scriptsFolder as text) & scriptName) as alias
          exit repeat
        end if
      end if
    end try
    set versionSpecificScript to "None"
  end repeat
  tell application "Finder"
    try
      get kind of alias savesPath
      if result is "Alias" then
        set savesFolderFound to true
        set savesFolderLinked to true
        set worldFolderLinked to false
        set worldFolderTarget to "None"
        try
          set savesFolderTarget to the original item of the alias savesPath as text
          set savesFolderTargetDisk to the name of the disk of the original item of the alias savesPath as text
        on error
          set savesFolderTarget to "Broken"
          set savesFolderTargetDisk to "Broken"
        end try
      else
        set savesFolderFound to true
        set savesFolderLinked to false
        set savesFolderTarget to "None"
        set savesFolderTargetDisk to "None"
        set allWorldsList to {}
        set allWorldsNames to name of every item of folder savesPath
        repeat with worldName in allWorldsNames
          copy (savesPath & ":" & worldName) to end of allWorldsList
        end repeat
        if allWorldsList is {} then
          set worldFolderLinked to false
          set worldFolderTarget to "None"
        else
          repeat with worldFolder in allWorldsList
            if kind of alias worldFolder is "Alias" then
              set worldFolderLinked to true
              set chosenWorldFolder to name of alias worldFolder
              try
                set worldFolderTarget to the original item of the alias worldFolder as text
                exit repeat
              on error
                set worldFolderTarget to "Broken"
                exit repeat
              end try
            else
              set worldFolderLinked to false
              set worldFolderTarget to "None"
            end if
          end repeat
        end if
      end if
    on error
      set savesFolderFound to false
    end try
  end tell
  if savesFolderFound is false then
    beep
    try
      set missingSavesResponse to display alert "Minecraft Saves Folder Not Found!" message "The default Minecraft saves folder \"" & savesPath & "\" cannot be accessed/located.

If this is your first time running MaximumMinecraft, I'd strongly suggest setting Minecraft back to its default setup as far as file location goes before running MaximumMinecraft again.

If you get this message after running MaximumMinecraft successfully, you can attempt to recover your saves from a MaximumMinecraft managed backup (if you enabled that functionality) or quit MaximumMinecraft and restore your saves manually." buttons {"Recover from Backup", "Quit"} default button "Quit" cancel button "Quit" as warning
      if button returned of missingSavesResponse is "Recover from Backup" then
        set savesFolderTargetDisk to "None"
        set worldFolderTarget to "None"
        my readInPrefs()
        return
      end if
    on error
      quit
      return
    end try
  end if
  if savesFolderTargetDisk is "Broken" then
  else if savesFolderTargetDisk is "None" then
    if running of application "Minecraft" is true then
      beep
      display alert "Minecraft Already Running!" message "In order for the optimizations to work, Minecraft must not be running when you launch MaximumMinecraft.

Please quit Minecraft and then run MaximumMinecraft again." buttons {"Quit"} as warning
      quit
      return
    end if
  else
    tell application "Finder"
      if savesFolderTargetDisk is the name of the startup disk then
        set savesFolderTargetDisk to "WTF"
      else
        set savesFolderTargetDisk to "Flash Drive"
      end if
    end tell
  end if
  tell application "System Events"
    if file prefsPath exists then
      my readInPrefs()
    else
      my setPreferences()
    end if
  end tell
end run

#Get user preferences through interactive dialogs & save them to disk
on setPreferences()
  if worldFolderLinked then
    beep
    display alert "RAM Disk In Use But Preferences Not Found!" message "MaximumMinecraft has found that a world folder is linked to the RAM disk, but cannot find your preferences file.

You will need to set your MaximumMinecraft preferences again, but your world folder on the RAM disk has been located and its current settings will be used where applicable.

For MaximumMinecraft to restore any settings it changed when last run you will need to choose the same preferences you used before." as warning
  else if savesFolderTargetDisk is "Broken" then
    try
      beep
      display alert "Preferences Not Found & Broken Saves Link!" message "MaximumMinecraft cannot find your preferences file, and the default location of the Minecraft saves folder is linked to a flash drive that is no longer present.

Generally, this means something bad happened the last time you were running Minecraft through MaximumMinecraft.
        
Check the Finder/Desktop to make sure the flash drive your Minecraft saves is on is showing up/mounted. If not, unplug/replug the drive then quit & restart MaximumMinecraft.

If that fails, MaximumMinecraft can attempt to restore your saves from a backup folder if you created one, but you will first need to set your MaximumMinecraft preferences again. You must choose the same save locations/media options for the automated recovery to work. Click \"OK\" to continue

Alternately, you may quit MaximumMinecraft and recover your saves folder by copying a backup saves folder to " & savesPath & " manually." buttons {"Quit", "OK"} default button "OK" cancel button "Quit" as warning
    on error
      quit
      return
    end try
  else if savesFolderTargetDisk is "Flash Drive" then
    beep
    display alert "Flash Drive In Use But Preferences Not Found!" message "MaximumMinecraft has found that your active saves folder is linked to the flash drive, but cannot find your preferences file.

You will need to set your MaximumMinecraft preferences again, but your saves folder on your flash drive has been located and its current settings will be used where applicable.

For MaximumMinecraft to restore any settings it changed when last run you will need to choose the same preferences you used before." as warning
  else if savesFolderTargetDisk is "WTF" then
    beep
    display alert "Preferences Not Found!" message "MaximumMinecraft cannot find your preferences file, and the default Minecraft saves folder \"" & savesPath & "\" is linked to \"" & savesFolderTarget & "\" for some crazy reason.

If this is your first time running MaximumMinecraft, I'd strongly suggest setting Minecraft back to its default setup as far as file location goes before running MaximumMinecraft again.

If you get this message after running Minecraft through MaximumMinecraft successfully, you should probably contact me for support, because that's kind of crazy and shouldn't even be possible." buttons {"Quit"} as warning
    quit
    return
  else if savesFolderTargetDisk is "None" then
    display alert "Preferences Setup" message "MaximumMinecraft works by changing a few settings that make Minecraft run smoother, running Minecraft, and then changing the settings back to their original values when you're done.

The following dialogs will interactively set & save your MaximumMinecraft preferences.
  
If you later want to change these preferences, delete " & prefsPath
  end if
  
  --useMultiJars
  set defaultChoice to "MM should just use a single minecraft.jar"
  set choiceTwo to "MM should use multiple minecraft.jars"
  choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Multiple jars" with prompt "Minecraft has a truckload of mods, many of which conflict, create worlds that will only work with that mod, work only in singleplayer, and otherwise don't play nice with each-other.

If you have one of these mods installed and want to play multiplayer, or load a world you need to use a different mod with, you would need to do the file renaming/relocating hokey pokey to get everything to work.

MaximumMinecraft can manage this for you, allowing you to keep multiple minecraft.jars each with different mod sets, easily selectable on startup.

How should MaximumMinecraft handle multiple jars?" default items {defaultChoice}
  if result is false then
    set useMultiJars to false
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set useMultiJars to false
  else if (result as text) is choiceTwo then
    set useMultiJars to true
  end if
  
  --jarListPath
  if useMultiJars is true then
    set jarListDialog to display dialog "In the field below, please type in the names you would like to use to identify your multiple copies of minecraft.jar, separated by commas.

The example text shown would be for two copies, named singleplayer & multiplayer.

If you already have a modded minecraft.jar enter a name for it, plus a name for each additional jar you'd like to create, separated by commas, then click the \"I have a modded jar\" button.

Otherwise click the \"OK\" button." default answer "singleplayer,multiplayer" with title "MaximumMinecraft Setup: Multiple JAR Selection" buttons {"I have a modded jar", "OK"} with icon 1
    set jarListRaw to text returned of jarListDialog
    set jarListPath to minecraftPath & "MM_JarVersions.txt"
    do shell script "echo " & jarListRaw & " > " & quoted form of POSIX path of jarListPath
    set jarListFile to open for access jarListPath as alias
    set jarList to read jarListFile using delimiter ","
    close access jarListFile
    set the last item of jarList to the (characters 1 thru ((length of last item of jarList) - 1) of (last item of jarList)) as string
    if button returned of jarListDialog is "OK" then
      display alert "MaximumMinecraft Setup: JAR duplication" message "Your current minecraft.jar and /mods folder will be duplicated & renamed to each of your chosen names: minecraft.name.jar & /mods.name respectively.

To add mods to a particular minecraft.jar, add the mod files to that jar's named jar file & named /mods folder."
      try
        tell application "Finder"
          if folder (minecraftPath & "mods") exists then
          else
            do shell script "mkdir " & quoted form of POSIX path of minecraftPath & "mods"
          end if
        end tell
        repeat with jarName in jarList
          do shell script "cp -r " & quoted form of POSIX path of minecraftPath & "mods " & quoted form of POSIX path of minecraftPath & "mods." & quoted form of jarName
          do shell script "cp " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar " & quoted form of POSIX path of minecraftPath & "bin/minecraft." & quoted form of jarName & ".jar"
        end repeat
        do shell script "rm -r " & quoted form of POSIX path of minecraftPath & "mods"
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar"
      on error errorText
        beep
        display alert "minecraft.jar Absent from Default Location!" message errorText & "

minecraft.jar was not found in its default location.

You should probably run Minecraft by itself to download the missing minecraft.jar, or re-run MaximumMinecraft choosing the \"I have multiple jars\" button and selecting the relocated/renamed minecraft.jar(s) and /mods folder(s)." buttons {"Quit"} as warning
        quit
        return
      end try
    else if button returned of jarListDialog is "I have a modded jar" then
      repeat with jarName in jarList
        try
          set chosenJar to choose file with prompt "Select the minecraft.jar to use as \"" & jarName & "\"
or click cancel to use the default minecraft.jar." default location (minecraftPath & "bin:") as alias without invisibles
        on error
          set chosenJar to (minecraftPath & "bin:minecraft.jar")
        end try
        try
          try
            do shell script "diff " & quoted form of POSIX path of chosenJar & " " & quoted form of POSIX path of minecraftPath & "bin/minecraft." & quoted form of jarName & ".jar"
          on error
            do shell script "mv -f " & quoted form of POSIX path of chosenJar & " " & quoted form of POSIX path of minecraftPath & "bin/minecraft." & quoted form of jarName & ".jar"
          end try
        on error errorText
          beep
          display alert "minecraft.jar Could Not Be Renamed/Relocated!" message "The move command failed with the following error:

" & errorText buttons {"Quit"} as warning
          quit
          return
        end try
        try
          set chosenMods to choose folder with prompt "Select the /mods folder to use with \"" & jarName & "\"
or click cancel to create a new /mods folder." default location minecraftPath as alias without invisibles
        on error
          set chosenMods to (minecraftPath & "mods")
        end try
        try
          try
            do shell script "diff -r " & quoted form of POSIX path of chosenMods & " " & quoted form of POSIX path of minecraftPath & "mods." & quoted form of jarName
          on error
            do shell script "mv -f " & quoted form of POSIX path of chosenMods & " " & quoted form of POSIX path of minecraftPath & "mods." & quoted form of jarName
          end try
        on error errorText
          try
            do shell script "mkdir " & quoted form of POSIX path of minecraftPath & "mods." & quoted form of jarName
          on error errorText
            beep
            display alert "/mods Folder Could Not Be Renamed/Created!" message "The command failed with the following error:

" & errorText buttons {"Quit"} as warning
            quit
            return
          end try
        end try
      end repeat
      tell application "System Events"
        set defaultMods to exists of folder (minecraftPath & "mods")
        set defaultJar to exists of file (minecraftPath & "bin/minecraft.jar")
      end tell
      if defaultMods then
        do shell script "rm -r " & quoted form of POSIX path of minecraftPath & "mods"
      end if
      if defaultJar then
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar"
      end if
    end if
  else
    set jarListPath to "null"
  end if
  
  --useMultiVersions
  set defaultChoice to "MM should just use a single Minecraft version"
  set choiceTwo to "MM should use multiple Minecraft versions"
  choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Multiple Versions" with prompt "Minecraft updates fairly frequently, and sometimes the servers you play on or the mods you use don't.

Holding on to an old version can be annoying if you want to check out new features, but upgrading to a new version can lock you out of your favorite mods and servers.

MaximumMinecraft can manage multiple Minecraft versions, allowing you to keep multiple versions of Minecraft easily selectable on startup.

How should MaximumMinecraft handle multiple Minecraft versions?" default items {defaultChoice}
  if result is false then
    set useMultiVersions to false
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set useMultiVersions to false
  else if (result as text) is choiceTwo then
    set useMultiVersions to true
  end if
  
  --versionsListPath
  if useMultiVersions is true then
    set versionsListDialog to display dialog "In the field below, please type in the versions of Minecraft you currently have, separated by commas.

The example text shown would be for one version, 1.3.2

If you already have multipe versions of Minecraft, enter each version number separated by commas, then click the \"I have multiple versions\" button.

Otherwise click the \"OK\" button." default answer "1.3.2" with title "MaximumMinecraft Setup: Multiple Version Selection" buttons {"I have multiple versions", "OK"} with icon 1
    set versionsListRaw to text returned of versionsListDialog
    set versionsListPath to minecraftPath & "MM_MinecraftVersions.txt"
    do shell script "echo " & versionsListRaw & " > " & quoted form of POSIX path of versionsListPath
    set versionsListFile to open for access versionsListPath as alias
    set versionsList to read versionsListFile using delimiter ","
    close access versionsListFile
    set the last item of versionsList to the (characters 1 thru ((length of last item of versionsList) - 1) of (last item of versionsList)) as string
    if button returned of versionsListDialog is "OK" then
      try
        repeat with versionsName in versionsList
          do shell script "cp " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar " & quoted form of POSIX path of minecraftPath & "bin/jinput." & quoted form of versionsName & ".jar"
          do shell script "cp " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util." & quoted form of versionsName & ".jar"
          do shell script "cp " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl." & quoted form of versionsName & ".jar"
        end repeat
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar"
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar"
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar"
      on error errorText
        beep
        display alert "jinput.jar, lwjgl_util.jar or lwjgl.jar Absent from Default Location!" message errorText & "

Either jinput.jar, lwjgl_util.jar or lwjgl.jar was not found in its default location.

You should probably run Minecraft by itself to download the missing .jar, or re-run MaximumMinecraft choosing the \"I have multiple versions\" button and selecting the relocated/renamed jinput.jar, lwjgl_util.jar or lwjgl.jar." buttons {"Quit"} as warning
        quit
        return
      end try
    else if button returned of versionsListDialog is "I have multiple versions" then
      repeat with versionsName in versionsList
        try
          set chosenJinput to choose file with prompt "Select the jinput.jar to use for version \"" & versionsName & "\"
or click cancel to use the default jinput.jar." default location (minecraftPath & "bin:") as alias without invisibles
        on error
          set chosenJinput to (minecraftPath & "bin:jinput.jar")
        end try
        try
          try
            do shell script "diff " & quoted form of POSIX path of chosenJinput & " " & quoted form of POSIX path of minecraftPath & "bin/jinput." & quoted form of versionsName & ".jar"
          on error
            do shell script "mv -f " & quoted form of POSIX path of chosenJinput & " " & quoted form of POSIX path of minecraftPath & "bin/jinput." & quoted form of versionsName & ".jar"
          end try
        on error errorText
          beep
          display alert "jinput.jar Could Not Be Renamed/Relocated!" message "The move command failed with the following error:

" & errorText buttons {"Quit"} as warning
          quit
          return
        end try
        try
          set chosenLwjgl_util to choose file with prompt "Select the lwjgl_util.jar to use for version \"" & versionsName & "\"
or click cancel to use the default lwjgl_util.jar." default location (minecraftPath & "bin:") as alias without invisibles
        on error
          set chosenLwjgl_util to (minecraftPath & "bin:lwjgl_util.jar")
        end try
        try
          try
            do shell script "diff " & quoted form of POSIX path of chosenLwjgl_util & " " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util." & quoted form of versionsName & ".jar"
          on error
            do shell script "mv -f " & quoted form of POSIX path of chosenLwjgl_util & " " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util." & quoted form of versionsName & ".jar"
          end try
        on error errorText
          beep
          display alert "lwjgl_util.jar Could Not Be Renamed/Relocated!" message "The move command failed with the following error:

" & errorText buttons {"Quit"} as warning
          quit
          return
        end try
        try
          set chosenLwjgl to choose file with prompt "Select the lwjgl.jar to use for version \"" & versionsName & "\"
or click cancel to use the default lwjgl.jar." default location (minecraftPath & "bin:") as alias without invisibles
        on error
          set chosenLwjgl to (minecraftPath & "bin:lwjgl.jar")
        end try
        try
          try
            do shell script "diff " & quoted form of POSIX path of chosenLwjgl & " " & quoted form of POSIX path of minecraftPath & "bin/lwjgl." & quoted form of versionsName & ".jar"
          on error
            do shell script "mv -f " & quoted form of POSIX path of chosenLwjgl & " " & quoted form of POSIX path of minecraftPath & "bin/lwjgl." & quoted form of versionsName & ".jar"
          end try
        on error errorText
          beep
          display alert "lwjgl.jar Could Not Be Renamed/Relocated!" message "The move command failed with the following error:

" & errorText buttons {"Quit"} as warning
          quit
          return
        end try
      end repeat
      tell application "System Events"
        set defaultJinput to exists of file (minecraftPath & "bin/jinput.jar")
        set defaultLwjgl_util to exists of file (minecraftPath & "bin/lwjgl_util.jar")
        set defaultLwjgl to exists of file (minecraftPath & "bin/lwjgl.jar")
      end tell
      if defaultJinput then
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar"
      end if
      if defaultLwjgl_util then
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar"
      end if
      if defaultLwjgl then
        do shell script "rm " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar"
      end if
    end if
  else
    set versionsListPath to "null"
  end if
  
  --driveTypeToUse
  if savesFolderTargetDisk is "Minemaster" then
    set driveTypeToUse to "RAM Disk"
  else if savesFolderTargetDisk is "Flash Drive" then
    set driveTypeToUse to "Flash Drive"
  else
    set defaultChoice to "MM should leave my saves where they are"
    set choiceTwo to "MM should use an external flash drive"
    set choiceThree to "MM should create and use a RAM disk                                      "
    choose from list {defaultChoice, choiceTwo, choiceThree} with title "MaximumMinecraft Setup: Working saves location" with prompt "MaximumMinecraft can improve singleplayer Minecraft gameplay by redirecting your saves to either a RAM disk or flash drive, both of which have faster read and write speeds than a regular magnetic hard drive.

This was the biggest speed increase with the old pre version 1.3 save system, as it consisted of a billion tiny files, but not quite so important now because Scaevolus' save format rules.
        
The RAM disk is faster, but an external flash drive is safer, as data on a RAM disk is lost in the event of power failure/premature ejection/computer reboot. Notably, RAM disks are safer for laptops than desktops, as laptops are insulated from unexpected power outages by their batteries.
      
What drive type should MaximumMinecraft use?" default items {defaultChoice}
    if result is false then
      set driveTypeToUse to "None"
      beep
      display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
    else if (result as text) is defaultChoice then
      set driveTypeToUse to "None"
    else if (result as text) is choiceTwo then
      set driveTypeToUse to "Flash Drive"
    else if (result as text) is choiceThree then
      set driveTypeToUse to "RAM Disk"
    end if
  end if
  
  --enableBackups
  if driveTypeToUse is "RAM Disk" then
    set enableBackups to true
    display alert "MaximumMinecraft Setup: Saves folder backup" message "Since you've chosen the RAM disk option, your saves folder will be backed up upon MaximumMinecraft start & exit to provide as recent a backup as possible in case of catastrophe. While the first backup may take a while due to the files being copied, subsequent backups are incremental, only updating those files that have been changed since the last backup, and will take much less time.

The next screen will let you choose which world folders you do and do not want to have included in the regular backups."
  else
    set defaultChoice to "MM should back up my Minecraft world saves"
    set choiceTwo to "MM should leave my saves alone"
    choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Saves folder backup" with prompt "MaximumMinecraft can back up your world save files automatically to provide protection against corruption due to Minecraft crashing, mod conflicts or other unpleasantness.

If you enable saves backup, your saves folder will be backed up upon MaximumMinecraft start & exit to provide as recent a backup as possible in case of catastrophe. While the first backup may take a while due to the files being copied, subsequent backups are incremental, only updating those files that have been changed since the last backup, and will take much less time.

If you choose to enable backups, the next screen will let you choose which world folders you do and do not want to have included in the backups." default items {defaultChoice}
    if result is false then
      set enableBackups to true
      beep
      display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
    else if (result as text) is defaultChoice then
      set enableBackups to true
    else if (result as text) is choiceTwo then
      set enableBackups to false
    end if
  end if
  
  --worldsExemptFromBackup
  if enableBackups is false then
    do shell script "echo '*' > " & quoted form of POSIX path of doNotBackUpFile
  else
    set defaultChoice to "MM should back up my entire saves folder"
    set choiceTwo to "MM should exclude some world folders from backup"
    choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: World folders to backup" with prompt "By default, MaximumMinecraft includes the entire save folder in its backups. However, you may want to exclude some world folders from being backed up. Some examples would be adventure maps that you have an alternate copy of, extremely large world folders, or worlds you wish to explore, but not mine or build in.
    
If you create more worlds in the future they will be automatically included in the next backup. If you want them to be excluded from backups, add the name of their world folder to the \"MM_WorldsExemptFromBackup.txt\" file in your Minecraft directory." default items {defaultChoice}
    if result is false then
      do shell script "echo '#' > " & quoted form of POSIX path of doNotBackUpFile
      beep
      display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
    else if (result as text) is defaultChoice then
      do shell script "echo '#' > " & quoted form of POSIX path of doNotBackUpFile
    else if (result as text) is choiceTwo then
      try
        do shell script "echo '#' > " & quoted form of POSIX path of doNotBackUpFile
        set worldsExemptFromBackup to choose folder with prompt "Select the world folders you would like to exclude from backups.
Hold down the \"command\" key to select multiple folders:" default location savesPath as alias with multiple selections allowed
        repeat with worldFolderPath in worldsExemptFromBackup
          tell application "Finder"
            set worldFolderName to name of worldFolderPath
          end tell
          do shell script "echo " & worldFolderName & "/ >> " & quoted form of POSIX path of doNotBackUpFile
        end repeat
      on error
        do shell script "echo '#' > " & quoted form of POSIX path of doNotBackUpFile
      end try
    end if
  end if
  
  --disableTwoFingerScroll
  if versionSpecificScript is "None" then
    set disableTwoFingerScroll to false
  else if systemVersion ≥ "10.8.0" then
    set disableTwoFingerScroll to false
  else
    set goToHandler to "checkForTrackpad"
    run script versionSpecificScript with parameters {goToHandler}
    set hasTrackpad to result
    if hasTrackpad is true then
      set defaultChoice to "MM should leave my two-finger scrolling settings alone"
      set choiceTwo to "MM should disable two-finger scrolling"
      choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: two-finger scrolling" with prompt "For MacBook users, having two-finger scrolling enabled on the trackpad can cause inventory scrolling when right-clicking is desired.
        
This is a bad thing when a skeleton is currently pumping you full of arrows and you're trying to return fire.

How should MaximumMinecraft handle your two-finger scrolling settings?" default items {defaultChoice}
      if result is false then
        set disableTwoFingerScroll to false
        beep
        display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
      else if (result as text) is defaultChoice then
        set disableTwoFingerScroll to false
      else if (result as text) is choiceTwo then
        set disableTwoFingerScroll to true
      end if
    else
      set disableTwoFingerScroll to false
    end if
  end if
  
  --disableMagicMouseScroll
  if versionSpecificScript is "None" then
    set disableMagicMouseScroll to false
  else if systemVersion ≥ "10.8.0" then
    set disableMagicMouseScroll to false
  else
    set defaultChoice to "MM should leave my Magic Mouse scrolling settings alone"
    set choiceTwo to "MM should disable Magic Mouse scrolling"
    choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Magic Mouse scrolling" with prompt "For Magic Mouse users, having scrolling enabled can cause inadvertent inventory scrolling.
        
This is a bad thing when a skeleton is currently pumping you full of arrows and you're trying to return fire.

Note - this may or may not work with OS X Lion, if you've got Lion and a Magic Mouse, shoot me an email and you can help me code it!

How should MaximumMinecraft handle your Magic Mouse scrolling settings?" default items {defaultChoice}
    if result is false then
      set disableMagicMouseScroll to false
      beep
      display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
    else if (result as text) is defaultChoice then
      set disableMagicMouseScroll to false
    else if (result as text) is choiceTwo then
      set disableMagicMouseScroll to true
    end if
  end if
  
  --quitRunningApps
  set defaultChoice to "MM should leave all running apps running"
  set choiceTwo to "MM should prompt me to choose which running apps to quit"
  set choiceThree to "MM should quit all running apps"
  choose from list {defaultChoice, choiceTwo, choiceThree} with title "MaximumMinecraft Setup: App handling" with prompt "MaximumMinecraft can free up memory by quitting running applications before launching Minecraft. Any applications that are quit by MaximumMinecraft will be relaunched when you quit Minecraft.
  
How should MaximumMinecraft handle running applications?" default items {defaultChoice}
  if result is false then
    set quitRunningApps to false
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set quitRunningApps to false
  else if (result as text) is choiceTwo then
    set quitRunningApps to "choose"
  else if (result as text) is choiceThree then
    set quitRunningApps to true
  end if
  
  --disableDesktopRotation
  set defaultChoice to "MM should leave my picture rotation settings alone"
  set choiceTwo to "MM should disable picture rotation"
  choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Desktop picture rotation" with prompt "If you have Desktop picture rotation enabled, it can cause a drop in frame rate in Minecraft each time a new picture is loaded.
  
How should MaximumMinecraft handle Desktop picture rotation?" default items {defaultChoice}
  if result is false then
    set disableDesktopRotation to false
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set disableDesktopRotation to false
  else if (result as text) is choiceTwo then
    set disableDesktopRotation to true
  end if
  
  --disableTranslucence
  set defaultChoice to "MM should leave my menu bar alone"
  set choiceTwo to "MM should turn off menu bar translucence"
  choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Menu bar translucence" with prompt "The menu bar uses a bit more memory when it is translucent.
(Yes I know this is pretty ridiculous, but some people don't have a lot of RAM, OK?)
  
How should MaximumMinecraft handle menu bar translucence?" default items {defaultChoice}
  if result is false then
    set disableTranslucence to false
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set disableTranslucence to false
  else if (result as text) is choiceTwo then
    set disableTranslucence to true
  end if
  
  --purgeRAM
  set defaultChoice to "MM should leave my RAM alone"
  set choiceTwo to "MM should purge my inactive RAM"
  choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Purge inactive RAM                                             " with prompt "Inactive RAM is RAM that contains data that is not in use, but is stored in RAM for fast access in case it needs to be used again. For instance, if you open an application and then quit it, some of its data will be stored in inactive RAM so that it will open faster if you open it again.

On systems with less RAM, this can limit the amount of RAM available to make a RAM disk/run Minecraft smoothly. If you have more than 4GB of RAM you don't need to worry about this, in fact, purging your RAM may take an excessively long time.

If you don't currently have the purge application installed, MaximumMinecraft will install it in \"/usr/local/bin\" immediately following this dialog. This requires administrative access privileges, so MaximumMinecraft will ask for your password. Canceling the password dialog will not affect the operation of MaximumMinecraft, but will turn off inactive RAM purging.
  
Should MaximumMinecraft purge your inactive RAM so that more RAM is available for creating the RAM disk and/or running Minecraft?" default items {defaultChoice}
  if result is false then
    set purgeRAM to false
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set purgeRAM to false
  else if (result as text) is choiceTwo then
    set purgeRAM to true
    set purgeLocation to do shell script "whereis purge"
    if purgeLocation is not "" then
    else
      try
        do shell script "ls /usr/local/bin/purge"
      on error
        set purgeFile to ((resourcesFolder as text) & "purge") as alias
        try
          do shell script "ls /usr/local/bin"
          set usrLocalBinExists to true
        on error
          try
            do shell script "mkdir /usr/local/bin" with administrator privileges
            set usrLocalBinExists to true
          on error
            beep
            set usrLocalBinExists to false
            set purgeRAM to false
            display alert "Unable to Install Purge!" message "MaximumMinecraft is unable to install purge into \"/usr/local/bin\" and will turn off purging inactive RAM in your MaximumMinecraft preferences." as warning
          end try
        end try
        if usrLocalBinExists is true then
          try
            do shell script "cp " & purgeFile & " /usr/local/bin/; chmod 755 /usr/local/bin/purge" with administrator privileges
          on error
            beep
            set purgeRAM to false
            display alert "Unable to Install Purge!" message "MaximumMinecraft is unable to install purge into \"/usr/local/bin\" and will turn off purging inactive RAM in your MaximumMinecraft preferences." as warning
          end try
        end if
      end try
    end if
  end if
  
  --remoteSavesPath
  if savesFolderTarget is "Broken" then
    if driveTypeToUse is "Flash Drive" then
      try
        beep
        display alert "Attempted Recovery for Flash Drive Users!" message "MaximumMinecraft has found your saves folder linked to a nonexistent location. According to the preferences you just set, this location was on a flash drive.

You should only see this message if you have previously run MaximumMinecraft and used a flash drive as your working saves location. If that is not the case, quit MaximumMinecraft, re-run it & do not select the \"use flash drive\" option.

If you have not moved/renamed the flash drive/path to the saves folder on the flash drive: make sure the drive is plugged in and showing up in the Finder/Desktop, quit MaximumMinecraft and re-run it.

Otherwise, continue & choose the flash drive/folder on your flash drive where your Minecraft saves folder is located. If the saves folder is no longer on your flash drive, select the flash drive/folder on your flash drive you would like MaximumMinecraft to run your Minecraft saves from.
            
After setting and saving your preferences, MaximumMinecraft will attempt to recover your saves folder to the default saves location from your choice of either your flash drive or your backups. If the thought of this terrifies you, you can quit  MaximumMinecraft, delete the alias at \"" & savesPath & "\" and copy the saves folder of your choice there manually." buttons {"Quit", "OK"} default button "OK" cancel button "Quit" as warning
      on error
        quit
        return
      end try
      try
        choose folder with prompt "Select the flash drive/folder on your flash drive that contains your Minecraft saves folder/that you would like MaximumMinecraft to run your Minecraft saves from:"
        set remoteSavesPath to (result as text)
      on error
        beep
        display alert "Good going, you broke it >=(" message "Run MaximumMinecraft again and don't cancel out of the setup dialogs." as warning buttons {"Quit"}
        quit
        return
      end try
      if remoteSavesPath is (text 1 thru ((length of savesPath) - 5)) then
        beep
        display alert "Saves Folder ≠ Flash Drive Saves Folder" message "You've set your flash drive saves folder to be the same folder as your default Minecraft saves folder.

Thats...really not a very good idea.

You should quit MaximumMinecraft and set it to something different when you run it again." buttons {"Quit"} as warning
        quit
        return
      end if
    else
      try
        beep
        display alert "Attempted Recovery for RAM Disk Users!" message "MaximumMinecraft has found your saves folder linked to a nonexistent location. According to the preferences you just set, this location was on a RAM disk.

You should only see this message if you have previously run MaximumMinecraft and used a RAM disk as your working saves location. If that is not the case, quit MaximumMinecraft, re-run it & do not select the \"use RAM disk\" option.

If you were using a RAM disk, the save data on the RAM disk is likely lost as a RAM disk loses all data when ejected/unmounted. However, MaximumMinecraft does keep a copy of RAM disk data that is updated during gameplay with the \"Synch with RAM disk\" service if you've chosen to install and use it.
            
After setting and saving your preferences, MaximumMinecraft will attempt to recover your saves folder to the default saves location from your choice of either the synched RAM disk data or your backups. If the thought of this terrifies you, you can quit  MaximumMinecraft, delete the alias at \"" & savesPath & "\" and copy the saves folder of your choice there manually." buttons {"Quit", "OK"} default button "OK" cancel button "Quit" as warning
      on error
        quit
        return
      end try
      set remoteSavesPath to "RAM Disk"
    end if
  else if savesFolderTargetDisk is "Flash Drive" then
    if driveTypeToUse is "Flash Drive" then
      set remoteSavesPath to savesFolderTarget
    else
      beep
      display alert "How Did You..." message "Somehow you managed to have your saves folder linked to your flash drive, and yet select some other option in the preferences setup!?
          
That isn't even logically possible in this program.

You should definitely quit MaximumMinecraft and start over with setting your preferences." buttons {"Quit"} as warning
      quit
      return
    end if
  else if savesFolderTargetDisk is "Minemaster" then
    if driveTypeToUse is "Flash Drive" then
      beep
      display alert "How Did You..." message "Somehow you managed to have your saves folder linked to a RAM Disk, and yet select some other option in the preferences setup!?
That isn't even logically possible in this program.

You should definitely quit MaximumMinecraft and start over with setting your preferences." buttons {"Quit"} as warning
      quit
      return
    else
      set remoteSavesPath to "RAM Disk"
    end if
  else if savesFolderTarget is "None" then
    if driveTypeToUse is "Flash Drive" then
      try
        choose folder with prompt "Select the flash drive/folder on your flash drive you'd like 
MaximumMinecraft to run your Minecraft saves from:"
        set remoteSavesPath to (result as text)
        if remoteSavesPath is (text 1 thru ((length of savesPath) - 5) of savesPath) then
          beep
          display alert "Saves Folder ≠ Backup Folder" message "You've set your saves backup folder to be the same folder as your default Minecraft saves folder.

Thats...really not a very good idea.

You should quit MaximumMinecraft and set it to something different when you run it again." buttons {"Quit"} as warning
          quit
          return
        end if
        tell application "Finder"
          set savesBackupDiskName to name of disk of folder remoteSavesPath
        end tell
        if savesBackupDiskName is startupDisk then
          beep
          set theChoice to display alert "Flash Drive = Startup Disk?!?" message "The location you've selected for your flash drive saves is the same disk you have OS X installed on.

Unless you're doing some really crazy things with your OS X install, this probably isn't what you want to do.

It will still work, mind you, but if you did just select a folder on your primary hard drive, there won't really be any performance improvement in Minecraft, and it kind of defeats  the purpose of using the flash drive option. If you know what you're doing, feel free to leave it like this, otherwise you should quit MaximumMinecraft and set it to something different when you run it again." buttons {"I know what I'm doing", "Quit"} as warning
          if button returned of theChoice is "Quit" then
            quit
            return
          end if
        end if
      on error
        beep
        display alert "Good going, you broke it >=(" message "Run MaximumMinecraft again and don't cancel out of the setup dialogs." as warning buttons {"Quit"}
        quit
        return
      end try
    else if driveTypeToUse is "RAM Disk" then
      set remoteSavesPath to "RAM Disk"
    else
      set remoteSavesPath to "None"
    end if
  end if
  
  --installSynchService
  if driveTypeToUse is not "RAM Disk" then
    set installSynchService to false
  else
    tell application "Finder"
      try
        if exists file {(path to library folder from user domain as text) & "Services:Synch with RAM disk.workflow"} then
          set installSynchService to true
          set freshServiceInstall to false
          set serviceInstalled to true
        end if
      on error
        set serviceInstalled to false
      end try
    end tell
    if serviceInstalled is false then
      set defaultChoice to "MM should install the Synch with RAM disk service"
      set choiceTwo to "MM should not install the Synch with RAM disk service"
      choose from list {defaultChoice, choiceTwo} with title "MaximumMinecraft Setup: Synch with RAM disk service" with prompt "MaximumMinecraft can install a service that synchronizes a cache on your hard drive with the current save data on the RAM disk by pressing ⌘S in Minecraft.
          
If you choose not to install this service, the saves on the RAM disk will only be copied to the hard drive when Minecraft exits." default items {defaultChoice}
      if result is false then
        set installSynchService to true
        beep
        display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
      else if (result as text) is defaultChoice then
        set installSynchService to true
      else if (result as text) is choiceTwo then
        set installSynchService to false
      end if
      if installSynchService is true then
        beep
        display alert "DO NOT USE THE SYNCH WITH RAM DISK SERVICE WHILE MINECRAFT IS SAVING!" message "The service attempting to read from the RAM disk while Minecraft is writing save data to the RAM disk can cause data corruption.

Make sure Minecraft does not have the \"Saving level...\" text displayed at the bottom left of its window before pressing ⌘S to synchronize the cache & current RAM disk data.

Pressing the escape key and waiting until the the \"Saving level...\" text disappears before pressing ⌘S is the safest method, and also guarantees you will be synchronizing with up-to-date save information.

The Synch with RAM disk service will announce when it has completed synchronization so you can resume playing." as warning
      end if
    end if
  end if
  
  --announceActions
  set defaultChoice to "MM should just run and be quiet about it"
  set choiceTwo to "MM should verbally announce its actions with text-to-speech"
  set choiceThree to "MM should visually announce its actions with Growl notifications"
  choose from list {defaultChoice, choiceTwo, choiceThree} with title "MaximumMinecraft Setup: Action announcements" with prompt "MaximumMinecraft can announce its actions during execution so that you know it's actually doing something and not frozen or just hanging around being a good-for-nothing freeloader.

MaximumMinecraft can make these announcements audibly using one of your text-to-speech voices, or visually with Growl notifications.

How should MaximumMinecraft handle its actions?" default items {defaultChoice}
  if result is false then
    set announceActions to "None "
    beep
    display alert "Default selection chosen:" message "\"" & defaultChoice & "\"" as warning giving up after 5
  else if (result as text) is defaultChoice then
    set announceActions to "None "
  else if (result as text) is choiceTwo then
    set announceActions to "voice"
  else if (result as text) is choiceThree then
    set announceActions to "growl"
    if growlInstalled is false then
      try
        beep
        set installingGrowl to display alert "Growl Not Installed!" message "You've chosen to use Growl to announce MaximumMinecraft's actions, but you don't have Growl installed.

Click \"Get Growl\" to download the Growl installer disk image, or \"Cancel\" to not use notifications." buttons {"Get Growl", "Cancel"} cancel button "Cancel" as warning
      on error
        set announceActions to "None "
      end try
      if button returned of installingGrowl is "Get Growl" then
        display alert "Twiddling My Thumbs" message "I'll just wait here while you get and install Growl.

click \"Continue\" when you're done to finish the preferences setup." buttons {"Continue"}
        delay 0.5
        open location "http://growl.info/"
      end if
    end if
  end if
  
  --announcementVoice
  if announceActions is "None " then
    set announcementVoice to "Trinoids"
  else if announceActions is "growl" then
    set announcementVoice to "Trinoids"
    if growlInstalled is true then
      tell application id "com.Growl.GrowlHelperApp"
        set the allNotificationsList to {"Startup Notifications", "Shutdown Notifications"}
        set the enabledNotificationsList to allNotificationsList
        register as application "MaximumMinecraft" all notifications allNotificationsList default notifications enabledNotificationsList icon of application "MaximumMinecraft"
      end tell
    end if
    showGrowl("Startup Notifications", "Here's an example Growl message from MaximumMinecraft.")
    delay 0.5
    showGrowl("Startup Notifications", "You can change the visual style, duration, and other options for these notifications by going to the \"Growl\" tab in System Preferences and looking for MaximumMinecraft under the preferences tab")
  else if announceActions is "voice" then
    if versionSpecificScript is "None " then
      set announcementVoice to "Trinoids"
      say "I am happy to Maximize your Minecraft" using announcementVoice
    else
      set goToHandler to "loadSystemVoices"
      run script versionSpecificScript with parameters {goToHandler}
      if result is false then
        set announcementVoice to "Trinoids"
        beep
        display alert "Default selection chosen:" message "Using \"Trinoids\" as the announcement voice." as warning giving up after 5
        say "I am happy to Maximize your Minecraft" using announcementVoice
      else
        set announcementVoice to (result as text)
        say "I am happy to Maximize your Minecraft" using announcementVoice
      end if
    end if
  end if
  do shell script "echo " & useMultiJars & "," & jarListPath & "," & useMultiVersions & "," & versionsListPath & "," & driveTypeToUse & "," & enableBackups & "," & disableTwoFingerScroll & "," & disableMagicMouseScroll & "," & quitRunningApps & "," & disableDesktopRotation & "," & disableTranslucence & "," & purgeRAM & "," & remoteSavesPath & "," & installSynchService & "," & announceActions & "," & announcementVoice & " > " & quoted form of POSIX path of prefsPath
  if savesFolderTarget is "None" then
    try
      display alert "Proceed to running MaximumMinecraft?" message "Click \"Run\" to launch MaximumMinecraft & start playing Minecraft now.

Click \"Quit\" to only save settings & quit MaximumMinecraft" buttons {"Quit", "Run"} default button "Run" cancel button "Quit"
    on error
      quit
      return
    end try
  end if
  readInPrefs()
end setPreferences

#Set up everything according to the user preferences & fire up Minecraft! / recover saves according to user preferences
on readInPrefs()
  try
    set preferencesFile to open for access file prefsPath
    set preferencesList to read preferencesFile using delimiter ","
    close access preferencesFile
    set useMultiJars to item 1 of preferencesList as boolean
    set jarListPath to item 2 of preferencesList as text
    set useMultiVersions to item 3 of preferencesList as boolean
    set versionsListPath to item 4 of preferencesList as text
    set driveTypeToUse to item 5 of preferencesList as text
    set enableBackups to item 6 of preferencesList as boolean
    set disableTwoFingerScroll to item 7 of preferencesList as boolean
    set disableMagicMouseScroll to item 8 of preferencesList as boolean
    set quitRunningApps to item 9 of preferencesList as text
    set disableDesktopRotation to item 10 of preferencesList as boolean
    set disableTranslucence to item 11 of preferencesList as boolean
    set purgeRAM to item 12 of preferencesList as boolean
    set remoteSavesPath to (item 13 of preferencesList as text)
    set installSynchService to item 14 of preferencesList as boolean
    set announceActions to item 15 of preferencesList as text
    set announcementVoice to item 16 of preferencesList as text
  on error
    set useMultiJars to ""
    set jarListPath to ""
    set useMultiVersions to ""
    set versionsListPath to ""
    set driveTypeToUse to ""
    set enableBackups to ""
    set disableTwoFingerScroll to ""
    set disableMagicMouseScroll to ""
    set quitRunningApps to ""
    set disableDesktopRotation to ""
    set disableTranslucence to ""
    set purgeRAM to ""
    set remoteSavesPath to ""
    set installSynchService to ""
    set announceActions to ""
    set announcementVoice to ""
    display alert "Preferences Corrupted/Missing/Out of Date!" message "Your MM_Preferences.txt file is either corrupted, missing, or from an older version of MaximumMinecraft.

In any case, MaximumMinecraft can't read it properly, so you'll have to set your preferences again." as warning
    setPreferences()
    return
  end try
  if savesFolderTargetDisk is "Broken" or worldFolderTarget is "Broken" or savesFolderFound is false then
    set unwiseQuit to true
    savesRecovery()
    return
  else
    sizeSanityCheck()
    return
  end if
end readInPrefs

--Something bad happened the last time MaximumMinecraft was run, we'll try to recover as best we can

on savesRecovery()
  set listOfChoices to {}
  try
    do shell script "ls /Volumes/MineMaster/"
    set chosenWorldFolder to result
  end try
  tell application "System Events"
    set hiddenSaves to exists of folder (minecraftPath & ".saves")
    set hiddenWorld to exists of folder (savesPath & ":." & chosenWorldFolder)
    if backupOne exists then
      set choiceOne to "Backup 1 created on Minecraft startup, " & modification date of (backupOne as alias)
      copy choiceOne to the end of listOfChoices
    end if
    if backupTwo exists then
      set choiceTwo to "Backup 2 created on Minecraft startup, " & modification date of (backupTwo as alias)
      copy choiceTwo to the end of listOfChoices
    end if
  end tell
  if hiddenSaves then
    do shell script "mv -f " & quoted form of POSIX path of minecraftPath & ".saves " & quoted form of POSIX path of savesPath
  end if
  if hiddenWorld then
    do shell script "mv -f " & quoted form of POSIX path of savesPath & "/." & quoted form of chosenWorldFolder & " " & quoted form of POSIX path of savesPath & "/" & quoted form of chosenWorldFolder
  end if
  if driveTypeToUse is "Flash Drive" then
    set choiceZero to {"Select saves folder on flash drive to back up from"}
    beep
    choose from list (choiceZero & listOfChoices) with title "Attempting Saves Folder Recovery!" with prompt "MaximumMinecraft has found your saves folder linked to a nonexistent location. According to the preferences you've set, this location was on a flash drive.

MaximumMinecraft will attempt to recover your saves folder to the default saves folder location \"" & savesPath & "\".

You can choose to recover the saves from either your flash drive or your MaximumMinecraft managed backups (if you have that option enabled).

If the idea of this terrifies you, you may quit MaximumMinecraft & copy your flash drive/backup saves folder to the default location by hand." default items {first item of listOfChoices} cancel button name "Quit"
    set recoveryChoice to result
    if recoveryChoice is false then
      set unwiseQuit to false
      quit
      return
    else if recoveryChoice is choiceZero then
      try
        choose folder with prompt "Select the Minecraft saves folder
on your flash drive:"
        set chosenPath to result as text
        set pathLength to length of chosenPath
        if text (pathLength - 7) thru (pathLength) of chosenPath is "saves:" then
          set remoteSavesPath to text 1 thru (pathLength - 7) of chosenPath
          if remoteSavesPath is (text 1 thru ((length of savesPath) - 5)) then
            beep
            display alert "Saves Folder ≠ Flash Drive Saves Folder" message "You've set your flash drive saves folder to be the same folder as your default Minecraft saves folder.

Thats...really not a very good idea.

You should quit MaximumMinecraft and set it to something different when you run it again." buttons {"Quit"} as warning
            set unwiseQuit to false
            quit
            return
          else
            do shell script "echo " & useMultiJars & "," & jarListPath & "," & useMultiVersions & "," & versionsListPath & "," & driveTypeToUse & "," & enableBackups & "," & disableTwoFingerScroll & "," & disableMagicMouseScroll & "," & quitRunningApps & "," & disableDesktopRotation & "," & disableTranslucence & "," & purgeRAM & "," & remoteSavesPath & "," & installSynchService & "," & announceActions & "," & announcementVoice & " > " & quoted form of POSIX path of prefsPath
          end if
        else
          set remoteSavesPath to chosenPath
          if remoteSavesPath is (text 1 thru ((length of savesPath) - 5)) then
            beep
            display alert "Saves Folder ≠ Flash Drive Saves Folder" message "You've set your flash drive saves folder to be the same folder as your default Minecraft saves folder.

Thats...really not a very good idea.

You should quit MaximumMinecraft and set it to something different when you run it again." buttons {"Quit"} as warning
            set unwiseQuit to false
            quit
            return
          else
            choose from list listOfChoices with title "Saves Folder Not Found!" with prompt "The folder you chose does not contain the \"saves\" folder.

You may choose one of the other recovery options, or quit MaximumMinecraft & copy your flash drive/backup saves folder to the default location by hand." cancel button name "Quit"
            if result is false then
              set unwiseQuit to false
              quit
              return
            else
              set recoveryChoice to result
            end if
          end if
        end if
      on error
        beep
        display alert "Good going, you broke it >=(" message "Run MaximumMinecraft again and don't cancel out of the setup dialogs." as warning buttons {"Quit"}
        set unwiseQuit to false
        quit
        return
      end try
    end if
  end if
  if driveTypeToUse is "RAM Disk" then
    beep
    choose from list listOfChoices with title "Attempting World Folder Recovery!" with prompt "MaximumMinecraft has found one of your world folders linked to a nonexistent location. According to the preferences you've set, this location was on the RAM disk.

MaximumMinecraft will attempt to recover your world folder \"" & chosenWorldFolder & "\" from your MaximumMinecraft managed backups.

If the idea of this terrifies you, you may quit MaximumMinecraft & copy the world folder to the default location by hand." default items {first item of listOfChoices} cancel button name "Quit"
    set recoveryChoice to result
    if recoveryChoice is false then
      set unwiseQuit to false
      quit
      return
    end if
  else
    beep
    choose from list listOfChoices with title "Attempting World Folder Recovery!" with prompt "MaximumMinecraft has found your saves folder missing. According to the preferences you've set, this location was on a flash drive.

MaximumMinecraft will attempt to recover your saves folder to the default saves folder location \"" & savesPath & "\" from your MaximumMinecraft managed backups (if you have that option enabled).

If the idea of this terrifies you, you may quit MaximumMinecraft & copy a backup saves folder to the default location by hand." default items {first item of listOfChoices} cancel button name "Quit"
    set recoveryChoice to result
    if recoveryChoice is false then
      set unwiseQuit to false
      quit
      return
    end if
  end if
  try
    try
      if recoveryChoice is choiceOne as list then
        try
          do shell script "rsync -qrtu " & quoted form of POSIX path of backupOne & "/ " & quoted form of POSIX path of savesPath
        on error errorText
          beep
          display alert "Saves Not Restored from Backup!" message "The rsync command returned the error:

" & errorText & "

Please quit and re-launch MaximumMinecraft to attempt to recover from a different backup, or copy your backup saves folder to the default location by hand." as warning buttons {"Quit"}
          set unwiseQuit to false
          quit
          return
        end try
      end if
    end try
    try
      if recoveryChoice is choiceTwo as list then
        try
          do shell script "unzip -oqqu " & quoted form of POSIX path of backupTwo & " -d " & quoted form of POSIX path of savesPath
        on error errorText
          beep
          display alert "Saves Not Restored from Backup!" message "The unzip command returned the error:

" & errorText & "

Please quit and re-launch MaximumMinecraft to attempt to recover from a different backup, or copy your backup saves folder to the default location by hand." as warning buttons {"Quit"}
          set unwiseQuit to false
          quit
          return
        end try
      end if
    end try
  on error errorText
    beep
    display alert "Saves Not Restored from Backup!" message "The backup function returned the error:

" & errorText & "

Please quit and re-launch MaximumMinecraft to attempt to recover from a different backup, or copy your backup saves folder to the default location by hand." as warning buttons {"Quit"}
    set unwiseQuit to false
    quit
    return
  end try
  try
    set postRecoveryChoice to display alert "Saves Successfully Recovered!" message "Your saves have been successfully recovered.

Would you like to quit MaximumMinecraft, have MaximumMinecraft restore the settings it changes to their normal states, or continue on to play Minecraft?" buttons {"Quit", "Restore Settings", "Continue to Minecraft"} cancel button "Quit" default button "Continue to Minecraft"
    if button returned of postRecoveryChoice is "Revert Settings" then
      my postPlayCleanup()
    end if
  on error
    set unwiseQuit to false
    quit
    return
  end try
  set unwiseQuit to false
  my sizeSanityCheck()
end savesRecovery

--Make sure our flash drive is large enough to safely work with the saves folder

on sizeSanityCheck()
  say "MaximumMinecraft" using "Trinoids"
  if savesFolderTarget is "RAM Disk" then
  else if savesFolderTarget is "Flash Drive" then
  else if savesFolderTarget is "Broken" then
  else if savesFolderTarget is "None" then
    set typeSetter to display alert "Which Type of Minecraft?" message "Please choose which type of Minecraft you plan on playing.

Choosing multiplayer disables save file backup & save file optimization (flash drive/RAM disk) since the world files are server side." buttons {"Multiplayer", "Singleplayer"}
    set minecraftType to the button returned of typeSetter as text
    if minecraftType is "Singleplayer" then
      if driveTypeToUse is "Flash Drive" then
        tell application "System Events"
          set currentSavesSize to size of folder savesPath
        end tell
        tell application "Finder"
          try
            if currentSavesSize > ((free space of disk of (remoteSavesPath as alias)) + (1048576 * 30)) then
              set flashDriveTooFull to true
              set flashDriveInaccessible to false
            else
              set flashDriveTooFull to false
              set flashDriveInaccessible to false
            end if
          on error
            set flashDriveInaccessible to true
            set flashDriveTooFull to false
          end try
        end tell
        if flashDriveTooFull is true then
          try
            beep
            display alert "Flash Drive Free Space Less Than Recommended Minimum!" message "Your current saves folder is within 30 MB of the free space available on your flash drive.

Please free up some space on your flash drive to use it with MaximumMinecraft." buttons {"Quit"} default button "Quit" cancel button "Quit" as warning
          on error
            quit
            return
          end try
        end if
        if flashDriveInaccessible is true then
          try
            repeat
              beep
              set flashDriveCheck to display alert "Flash Drive Inaccessible!" message "MaximumMinecraft is unable to access the \"saves\" folder on your flash drive.

Is it plugged in/has its name changed/has the path to the saves folder location on it changed?" buttons {"Retry", "Quit"} default button "Retry" cancel button "Quit" as warning
              tell application "Finder"
                try
                  if remoteSavesPath as alias exists then
                    exit repeat
                  end if
                end try
              end tell
            end repeat
          on error
            quit
            return
          end try
        end if
      else if driveTypeToUse is "RAM Disk" then
        if savesFolderTarget is "RAM Disk" then
          tell application "System Events"
            set ramDiskSectors to (((capacity of disk "Minemaster") / 1048576) * 2048)
          end tell
        else
          try
            display alert "Choose World Folder to Run from RAM Disk" message "In order to not gobble up all of your memory, MaximumMinecraft only copies a single world folder to the RAM disk at a time. While you will still be able to use all of your worlds, only the selected world will make use of the RAM disk optimizations.

Please select the world you would like to optimize for mining this session. To choose a different world, you will need to quit and re-launch MaximumMinecraft.

Or, click \"Cancel\" to run Minecraft without using the RAM disk." buttons {"Choose World Folder", "Cancel"} default button "Choose World Folder" cancel button "Cancel"
            choose folder with prompt "Select the world folder of the world
you would like to mine optimized:" default location savesPath as alias
            set chosenWorldPath to result
            tell application "System Events"
              set chosenSavesSize to size of chosenWorldPath
            end tell
            set systemMemory to last item of systemInfo
            set systemMemorySectors to ((systemMemory as integer) * 2048)
            set ramDiskSize to ((round (chosenSavesSize / 1048576) rounding up) + 30)
            set ramDiskSectors to (ramDiskSize * 2048)
            if ramDiskSectors > systemMemorySectors then
              beep
              display alert "Impossibly Large RAM Disk!" message "The world folder you selected is larger than all the RAM on your computer.

That's just not going to work.

MaximumMinecraft will run this time without using the RAM disk." as warning
              set driveTypeToUse to "None"
            else if ramDiskSectors > (systemMemorySectors / 2) then
              beep
              display alert "Very Large RAM Disk!" message "The world folder you selected larger than half your computer's total RAM.
            
This is quite possibly a bad idea, so if bad things happen when you run Minecraft, you should probably choose not to use the RAM disk for this world." as warning
            end if
          on error
            set driveTypeToUse to "None"
          end try
        end if
      end if
    end if
  end if
  set unwiseQuit to true
  my itsGoTime()
end sizeSanityCheck

#Setup and/or recovery is complete, now, set everything according to the preferences & fire up Minecraft

on itsGoTime()
  --SSP/SMP/multiple jars routine
  if useMultiJars is true then
    set jarToUse to ""
    set jarListFile to open for access jarListPath as alias
    set jarList to read jarListFile using delimiter ","
    close access jarListFile
    set the last item of jarList to the (characters 1 thru ((length of last item of jarList) - 1) of (last item of jarList)) as string
    set minecraftJarFile to minecraftPath & "bin:minecraft.jar"
    tell application "Finder"
      try
        set minecraftJarState to kind of alias minecraftJarFile
      on error
        set minecraftJarState to "missing"
      end try
    end tell
    if minecraftJarState is "Java JAR file" then
      set newJarChosen to false
      beep
      set useItOrLoseIt to display alert "New minecraft.jar Detected!" message "There's a new \"minecraft.jar\" file in your /bin directory, likely because you downloaded the new version the last time you played.

Would you like to use the new version of Minecraft, or select one of your older named versions to play?

Either way, you will be able to rename the new minecraft.jar, and it will be added to the list of your selectable jars." buttons {"Use New", "Select Old"} as warning
      if button returned of useItOrLoseIt is "Use New" then
        set newJarChosen to true
      end if
      set nameChooser to display dialog "Type a name to use for the new minecraft.jar.

The new jar will be saved as \"minecraft..jar\" and the mods folder as \"mods.\", where  is the name you type below.

Use those folders for adding mods to this new jar." with title "Name New minecraft.jar" buttons {"OK"} default button "OK" default answer "new" with icon 1
      set newJarName to text returned of nameChooser
      repeat
        if jarList contains newJarName then
          set nameChooser to display dialog "\"" & newJarName & "\" is already in use for a different minecraft.jar/mods set.

Please type in a different name to use for the new jar." with title "Rename New minecraft.jar" buttons {"OK"} default button "OK" default answer "new" with icon 2
          set newJarName to text returned of nameChooser
        else
          exit repeat
        end if
      end repeat
      do shell script "mv -f " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar " & quoted form of POSIX path of minecraftPath & "bin/minecraft." & quoted form of newJarName & ".jar"
      try
        do shell script "mv -f " & quoted form of POSIX path of minecraftPath & "mods " & quoted form of POSIX path of minecraftPath & "mods." & quoted form of newJarName
      on error
        do shell script "mkdir " & quoted form of POSIX path of minecraftPath & "mods." & quoted form of newJarName
      end try
      do shell script "echo '," & newJarName & "' >> " & quoted form of POSIX path of jarListPath
      if newJarChosen is true then
        set jarToUse to newJarName
      end if
    else if minecraftJarState is "Alias" then
      do shell script "rm -r " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar;
              rm -r " & quoted form of POSIX path of minecraftPath & "mods"
    end if
    if jarToUse is "" then
      choose from list jarList with title "Which Minecraft JAR?" with prompt "Select the minecraft.jar you would like to use." cancel button name "Download New Jar"
      if result is false then
        tell application "System Events"
          set modsChecker to exists of folder (minecraftPath & "mods")
        end tell
        if modsChecker is false then
          do shell script "mkdir " & quoted form of POSIX path of minecraftPath & "mods"
        end if
      else
        set jarToUse to result as text
        do shell script "ln -s " & quoted form of POSIX path of minecraftPath & "bin/minecraft.'" & jarToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar;
            ln -s " & quoted form of POSIX path of minecraftPath & "mods.'" & jarToUse & "' " & quoted form of POSIX path of minecraftPath & "mods"
        set jarToUse to ""
      end if
    else
      do shell script "ln -s " & quoted form of POSIX path of minecraftPath & "bin/minecraft.'" & jarToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/minecraft.jar;
            ln -s " & quoted form of POSIX path of minecraftPath & "mods.'" & jarToUse & "' " & quoted form of POSIX path of minecraftPath & "mods"
      set jarToUse to ""
    end if
  end if
  
  --multiple versions routine
  if useMultiVersions is true then
    set versionToUse to ""
    set versionsListFile to open for access versionsListPath as alias
    set versionsList to read versionsListFile using delimiter ","
    close access versionsListFile
    set the last item of versionsList to the (characters 1 thru ((length of last item of versionsList) - 1) of (last item of versionsList)) as string
    set minecraftJinputFile to minecraftPath & "bin:jinput.jar"
    set minecraftLwjgl_utilFile to minecraftPath & "bin:lwjgl_util.jar"
    set minecraftLwjglFile to minecraftPath & "bin:lwjgl.jar"
    tell application "Finder"
      try
        set minecraftJinputState to kind of alias minecraftJinputFile
      on error
        set minecraftJinputState to "missing"
      end try
      try
        set minecraftLwjgl_utilState to kind of alias minecraftLwjgl_utilFile
      on error
        set minecraftLwjgl_utilState to "missing"
      end try
      try
        set minecraftLwjglState to kind of alias minecraftLwjglFile
      on error
        set minecraftLwjglState to "missing"
      end try
    end tell
    if ((minecraftJinputState is "Java JAR file") or (minecraftLwjgl_utilState is "Java JAR file") or (minecraftLwjglState is "Java JAR file")) then
      set newVersionChosen to false
      beep
      set useItOrLoseIt to display alert "New Minecraft Version Detected!" message "There are new \"jinput.jar\", \"lwjgl_util.jar\", and \"lwjgl.jar\" files in your /bin directory, likely because you downloaded the new version of Minecraft the last time you played.

Would you like to use the new version of Minecraft, or select one of your older versions to play?

Either way, you will be able to name the new version, and it will be added to the list of your selectable versions." buttons {"Use New", "Select Old"} as warning
      if button returned of useItOrLoseIt is "Use New" then
        set newVersionChosen to true
      end if
      set nameChooser to display dialog "Type a name to use for the new Minecraft version.

The new version files will be saved as \"jinput..jar\", \"lwjgl_util..jar\", and \"lwjgl..jar\", where  is the name you type below." with title "Name New Minecraft Version" buttons {"OK"} default button "OK" default answer "current" with icon 1
      set newVersionName to text returned of nameChooser
      repeat
        if versionsList contains newVersionName then
          set nameChooser to display dialog "\"" & newVersionName & "\" is already in use for a different Minecraft version.

Please type in a different name to use for the new version." with title "Rename New Minecraft Version" buttons {"OK"} default button "OK" default answer "current" with icon 2
          set newVersionName to text returned of nameChooser
        else
          exit repeat
        end if
      end repeat
      do shell script "mv -f " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar " & quoted form of POSIX path of minecraftPath & "bin/jinput." & quoted form of newJarName & ".jar"
      do shell script "mv -f " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util." & quoted form of newJarName & ".jar"
      do shell script "mv -f " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl." & quoted form of newJarName & ".jar"
      do shell script "echo '," & newVersionName & "' >> " & quoted form of POSIX path of versionsListPath
      if newVersionChosen is true then
        set versionToUse to newVersionName
      end if
    else if minecraftJinputState is "Alias" then
      do shell script "rm -r " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar"
    else if minecraftLwjgl_utilState is "Alias" then
      do shell script "rm -r " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar"
    else if minecraftLwjglState is "Alias" then
      do shell script "rm -r " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar"
    end if
    if versionToUse is "" then
      choose from list versionsList with title "Which Minecraft Version?" with prompt "Select the Minecraft version you would like to use." cancel button name "Download New Version"
      if result is false then
        tell application "System Events"
          set modsChecker to exists of folder (minecraftPath & "mods")
        end tell
        if modsChecker is false then
          do shell script "mkdir " & quoted form of POSIX path of minecraftPath & "mods"
        end if
      else
        set versionToUse to result as text
        do shell script "ln -s " & quoted form of POSIX path of minecraftPath & "bin/jinput.'" & versionToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar;
            ln -s " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.'" & versionToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar;
            ln -s " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.'" & versionToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar"
        set versionToUse to ""
      end if
    else
      do shell script "ln -s " & quoted form of POSIX path of minecraftPath & "bin/jinput.'" & versionToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/jinput.jar;
            ln -s " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.'" & versionToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl_util.jar;
            ln -s " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.'" & versionToUse & "'.jar " & quoted form of POSIX path of minecraftPath & "bin/lwjgl.jar"
      set versionToUse to ""
    end if
  end if
  
  --install the Synch with RAM disk service if it's not already installed
  if installSynchService is true then
    try
      set serviceFile to ((resourcesFolder as text) & "Synch with RAM disk.workflow") as alias
      set onDiskServiceDate to do shell script "stat -f %m ~/Library/Services/Synch\\ with\\ RAM\\ disk.workflow"
      set inBundleServiceDate to do shell script "stat -f %m " & quoted form of POSIX path of serviceFile
      if onDiskServiceDate > inBundleServiceDate then
        set freshServiceInstall to false
        set copyService to false
      else
        if announceActions is "voice" then
          say "Updating Synch with RAM disk service" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Updating Synch with RAM disk service")
        end if
        set freshServiceInstall to false
        set copyService to true
        set servicesFolder to ((path to library folder from user domain) & "Services:") as text
      end if
    on error
      if announceActions is "voice" then
        say "Installing Synch with RAM disk service" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Startup Notifications", "Installing Synch with RAM disk service")
      end if
      set freshServiceInstall to true
      set copyService to true
      set servicesFolder to ((path to library folder from user domain) & "Services:") as text
      tell application "Finder"
        if exists folder servicesFolder then
        else
          do shell script "mkdir ~/Library/Services"
        end if
      end tell
    end try
    if copyService is true then
      do shell script "cp -r " & quoted form of POSIX path of serviceFile & " " & quoted form of POSIX path of servicesFolder
    end if
  else
    set freshServiceInstall to false
  end if
  
  --disable two-finger scrolling, Magic Mouse scrolling & enable the Synch with RAM disk service if it was freshly installed
  if freshServiceInstall or disableTwoFingerScroll or disableMagicMouseScroll is true then
    if freshServiceInstall is true then
      if announceActions is "voice" then
        say "Enabling Synch with RAM disk service" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Startup Notifications", "Enabling Synch with RAM disk service")
      end if
      set goToHandler to "enableServiceShortcut"
      run script versionSpecificScript with parameters {goToHandler}
    end if
    if disableTwoFingerScroll is true then
      if savesFolderTarget is "None" then
        set goToHandler to "disableTwoFingerScrolling"
        run script versionSpecificScript with parameters {goToHandler}
        if result is true then
          if announceActions is "voice" then
            say "Disabling two finger scrolling" using announcementVoice
          else if announceActions is "growl" then
            showGrowl("Startup Notifications", "Disabling two finger scrolling")
          end if
        end if
      end if
    end if
    if disableMagicMouseScroll is true then
      if savesFolderTarget is "None" then
        set goToHandler to "disableMagicMouseScrolling"
        run script versionSpecificScript with parameters {goToHandler}
        if result is true then
          if announceActions is "voice" then
            say "Disabling Magic Mouse scrolling" using announcementVoice
          else if announceActions is "growl" then
            showGrowl("Startup Notifications", "Disabling Magic Mouse scrolling")
          end if
        end if
      end if
    end if
    tell application "System Preferences" to quit
  end if
  
  --changing OSX UI settings
  if savesFolderTarget is "None" then
    if disableDesktopRotation is true then
      tell application "System Events"
        if random order of desktop 1 = true then
          set random order of desktop 1 to false
        end if
        delay 0.5
        if picture rotation of desktop 1 = 1 then
          set picture rotation of desktop 1 to 0
        end if
      end tell
      if announceActions is "voice" then
        say "Disabling desktop rotation" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Startup Notifications", "Disabling desktop rotation")
      end if
    end if
    if disableTranslucence is true then
      tell application "System Events"
        if translucent menu bar of desktop 1 is true then
          set translucent menu bar of desktop 1 to false
        end if
      end tell
      if announceActions is "voice" then
        say "Disabling menu bar translucence" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Startup Notifications", "Disabling menu bar translucence")
      end if
    end if
  end if
  
  --Quitting out of other apps
  if savesFolderTarget is "RAM Disk" then
    set quitRunningApps to false
  else if savesFolderTarget is "Flash Drive" then
    set quitRunningApps to false
  else if savesFolderTarget is "Broken" then
    set quitRunningApps to false
  else if savesFolderTarget is "None" then
    try
      if (quitRunningApps as boolean) is false then
      else if (quitRunningApps as boolean) is true then
        if announceActions is "voice" then
          say "Quitting running applications" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Quitting running applications")
        end if
        tell application "System Events"
          set runningApps to displayed name of every process whose visible is true
          set invisibleApps to the displayed name of every process whose visible is false
          repeat with theApp in invisibleApps
            set theAppPath to the file of process theApp as text
            if theAppPath is not "" then
              if theAppPath does not contain "Library" then
                if theAppPath does not contain "Contents" then
                  copy theApp to the end of runningApps
                end if
              end if
            end if
          end repeat
        end tell
        set tempAppList to {}
        repeat with theApp in runningApps
          set theAppName to (theApp as text)
          if theAppName is not my name then
            if theAppName is not "System Preferences" then
              copy theAppName to the end of tempAppList
            end if
          end if
        end repeat
        set runningApps to tempAppList
        repeat with AppName in runningApps
          tell application AppName to quit
        end repeat
      end if
    on error
      tell application "System Events"
        set runningApps to displayed name of every process whose visible is true
        set invisibleApps to the displayed name of every process whose visible is false
        repeat with theApp in invisibleApps
          set theAppPath to the file of process theApp as text
          if theAppPath is not "" then
            if theAppPath does not contain "Library" then
              if theAppPath does not contain "Contents" then
                copy theApp to the end of runningApps
              end if
            end if
          end if
        end repeat
      end tell
      set tempAppList to {}
      repeat with theApp in runningApps
        set theAppName to (theApp as text)
        if theAppName is not my name then
          if theAppName is not "System Preferences" then
            copy theAppName to the end of tempAppList
          end if
        end if
      end repeat
      set runningApps to tempAppList
      choose from list runningApps with title "Currently Running Applications" with prompt "Select any applications you would like to quit, holding down ⌘ to select multiple apps.

All apps quit by MaximumMinecraft will be relaunched when Minecraft quits." OK button name "Quit selected apps" cancel button name "Leave all apps running" with multiple selections allowed and empty selection allowed
      if result is false then
        set runningApps to {}
      else
        set runningApps to result
        if announceActions is "voice" then
          say "Quitting selected applications" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Quitting selected applications")
        end if
        repeat with AppName in runningApps
          tell application AppName to quit
        end repeat
      end if
    end try
  end if
  
  --Things to only do if MaximumMinecraft exited cleanly
  if worldFolderTarget is "Broken" then
  else if savesFolderTarget is "Flash Drive" then
  else if savesFolderTarget is "Broken" then
  else
    if minecraftType is "Singleplayer" then
      --Back up saves folder
      if enableBackups then
        if announceActions is "voice" then
          say "Backing up saves" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Backing up saves")
        end if
        tell application "Finder"
          set backupOneExists to exists of backupOne
        end tell
        if backupOneExists then
          try
            do shell script "cd " & quoted form of POSIX path of backupOne & ";
                  zip -qru9 " & quoted form of POSIX path of backupTwo & " *"
          end try
        end if
        do shell script "rsync -qrtu --exclude-from=" & quoted form of POSIX path of doNotBackUpFile & " " & quoted form of POSIX path of savesPath & "/* " & quoted form of POSIX path of backupOne
      end if
      --Flash drive utilization function
      if driveTypeToUse is "Flash Drive" then
        if announceActions is "voice" then
          say "Syncing flash drive with saves" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Syncing flash drive with saves")
        end if
        do shell script "rsync -qrtu " & quoted form of POSIX path of savesPath & " " & quoted form of POSIX path of remoteSavesPath
        if announceActions is "voice" then
          say "Linking to flash drive" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Linking to flash drive")
        end if
        do shell script "mv -f " & quoted form of POSIX path of savesPath & " " & quoted form of POSIX path of minecraftPath & ".saves;
                ln -s " & quoted form of POSIX path of remoteSavesPath & "saves " & quoted form of POSIX path of savesPath
      end if
    end if
    --Purge inactive RAM
    if purgeRAM is true then
      set purgeLocation to do shell script "whereis purge"
      if purgeLocation is not "" then
        if announceActions is "voice" then
          say "Purging inactive RAM" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Purging inactive RAM")
        end if
        do shell script "purge"
      else
        try
          do shell script "ls /usr/local/bin/purge"
          if announceActions is "voice" then
            say "Purging inactive RAM" using announcementVoice
          else if announceActions is "growl" then
            showGrowl("Startup Notifications", "Purging inactive RAM")
          end if
          do shell script "/usr/local/bin/purge"
        on error
          set purgeFile to ((resourcesFolder as text) & "purge") as alias
          try
            do shell script "ls /usr/local/bin"
            set usrLocalBinExists to true
          on error
            try
              beep
              display alert "Installing Purge" message "MaximumMinecraft's preferences show you've opted to enable purging inactive RAM, but the purge application is not installed. MaximumMinecraft needs to request an administrative password to create the \"/usr/local/bin\" directory to install purge in." as warning
              do shell script "mkdir /usr/local/bin" with administrator privileges
              set usrLocalBinExists to true
            on error
              beep
              set usrLocalBinExists to false
              set purgeRAM to false
              do shell script "echo " & useMultiJars & "," & jarListPath & "," & useMultiVersions & "," & versionsListPath & "," & driveTypeToUse & "," & enableBackups & "," & disableTwoFingerScroll & "," & disableMagicMouseScroll & "," & quitRunningApps & "," & disableDesktopRotation & "," & disableTranslucence & "," & purgeRAM & "," & remoteSavesPath & "," & installSynchService & "," & announceActions & "," & announcementVoice & " > " & quoted form of POSIX path of prefsPath
              display alert "Unable to Install Purge!" message "MaximumMinecraft is unable to install purge into \"/usr/local/bin\" and will turn off purging inactive RAM in your MaximumMinecraft preferences." as warning
            end try
          end try
          if usrLocalBinExists is true then
            try
              beep
              display alert "Installing Purge" message "MaximumMinecraft's preferences show you've opted to enable purging inactive RAM, but the purge application is not installed. MaximumMinecraft needs to request an administrative password to copy purge to the \"/usr/local/bin\" directory. If you just supplied a password to create \"/usr/local/bin\" then the script will not ask again." as warning
              do shell script "cp " & purgeFile & " /usr/local/bin/; chmod 755 /usr/local/bin/purge" with administrator privileges
              try
                if announceActions is "voice" then
                  say "Purging inactive RAM" using announcementVoice
                else if announceActions is "growl" then
                  showGrowl("Startup Notifications", "Purging inactive RAM")
                end if
                do shell script "/usr/local/bin/purge"
              on error
                beep
                set purgeRAM to false
                do shell script "echo " & useMultiJars & "," & jarListPath & "," & useMultiVersions & "," & versionsListPath & "," & driveTypeToUse & "," & enableBackups & "," & disableTwoFingerScroll & "," & disableMagicMouseScroll & "," & quitRunningApps & "," & disableDesktopRotation & "," & disableTranslucence & "," & purgeRAM & "," & remoteSavesPath & "," & installSynchService & "," & announceActions & "," & announcementVoice & " > " & quoted form of POSIX path of prefsPath
                display alert "Unable to Purge Inactive RAM!" message "MaximumMinecraft is unable to run the purge command and will turn off purging inactive RAM in your MaximumMinecraft preferences." as warning
              end try
            on error
              beep
              set purgeRAM to false
              do shell script "echo " & useMultiJars & "," & jarListPath & "," & useMultiVersions & "," & versionsListPath & "," & driveTypeToUse & "," & enableBackups & "," & disableTwoFingerScroll & "," & disableMagicMouseScroll & "," & quitRunningApps & "," & disableDesktopRotation & "," & disableTranslucence & "," & purgeRAM & "," & remoteSavesPath & "," & installSynchService & "," & announceActions & "," & announcementVoice & " > " & quoted form of POSIX path of prefsPath
              display alert "Unable to Install Purge!" message "MaximumMinecraft is unable to install purge into \"/usr/local/bin\" and will turn off purging inactive RAM in your MaximumMinecraft preferences." as warning
            end try
          end if
        end try
      end if
    end if
    if minecraftType is "Singleplayer" then
      --RAM disk utilization function
      if driveTypeToUse is "RAM Disk" then
        if announceActions is "voice" then
          say "Creating RAM disk" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Creating RAM disk")
        end if
        do shell script "if ! test -e /Volumes/Minemaster ;
                then
                  diskutil erasevolume HFS+ Minemaster `hdiutil attach ram://" & ramDiskSectors & " -nomount`
                  fi"
        if announceActions is "voice" then
          say "Copying world folder to RAM disk" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Copying world folder to RAM disk")
        end if
        tell application "Finder"
          set chosenWorldFolder to the name of chosenWorldPath
        end tell
        do shell script "cp -r " & quoted form of POSIX path of savesPath & "/" & quoted form of chosenWorldFolder & " /Volumes/Minemaster/"
        if announceActions is "voice" then
          say "Linking to RAM disk" using announcementVoice
        else if announceActions is "growl" then
          showGrowl("Startup Notifications", "Linking to RAM disk")
        end if
        do shell script "mv -f " & quoted form of POSIX path of savesPath & "/" & quoted form of chosenWorldFolder & " " & quoted form of POSIX path of savesPath & "/." & quoted form of chosenWorldFolder & ";
                  ln -s /Volumes/Minemaster/" & quoted form of chosenWorldFolder & " " & quoted form of POSIX path of savesPath & "/" & quoted form of chosenWorldFolder
      end if
    end if
  end if
  --fire that sucker up
  if announceActions is "voice" then
    say "Launching Minecraft" using announcementVoice
  else if announceActions is "growl" then
    showGrowl("Startup Notifications", "Launching Minecraft")
  end if
  
  ######################  Diamonds
  launch application "Minecraft" ##         Or
  #####################         Bust
  
end itsGoTime

#Check if Minecraft is still running
on idle
  tell application "System Events"
    set stillRunning to (exists process "Minecraft")
  end tell
  if stillRunning is false then
    activate me
    set defaultChoice to "Reopen Minecraft"
    set choiceTwo to "Quit"
    set doWhatNext to display alert "Minecraft seems to have quit" message "It appears Minecraft is no longer running.

If you're done playing Minecraft, click \"Quit\" and MaximumMinecraft will change all your settings back to normal and then quit.

If Minecraft crashed and you want to keep playing with your MaximumMinecraft optimizations enabled, click \"Reopen Minecraft\"." buttons {choiceTwo, defaultChoice} default button defaultChoice
    if button returned of doWhatNext is "Quit" then
      my postPlayCleanup()
    else
      launch application "Minecraft"
    end if
  end if
  return 5
end idle

#Reset everything to the way it was before once Minecraft exits
on postPlayCleanup()
  if announceActions is "voice" then
    say "Restoring Settings to Default States" using announcementVoice
  else if announceActions is "growl" then
    showGrowl("Shutdown Notifications", "Restoring Settings to Default States")
  end if
  
  --unlink minecraft.jar and the other jars as running a modded Minecraft without MaximumMinecraft could possibly screw up worlds if the user doesn't realize they're using a modded client/different version
  if useMultiJars is true then
    set minecraftJarFile to minecraftPath & "bin:minecraft.jar"
    set minecraftJinputFile to minecraftPath & "bin:jinput.jar"
    set minecraftLwjgl_utilFile to minecraftPath & "bin:lwjgl_util.jar"
    set minecraftLwjglFile to minecraftPath & "bin:lwjgl.jar"
    set minecraftModsFolder to minecraftPath & "mods"
    tell application "Finder"
      try
        set minecraftJarState to kind of alias minecraftJarFile
      on error
        set minecraftJarState to "missing"
      end try
      try
        set minecraftJinputState to kind of alias minecraftJinputFile
      on error
        set minecraftJinputState to "missing"
      end try
      try
        set minecraftLwjgl_utilState to kind of alias minecraftLwjgl_utilFile
      on error
        set minecraftLwjgl_utilState to "missing"
      end try
      try
        set minecraftLwjglState to kind of alias minecraftLwjglFile
      on error
        set minecraftLwjglState to "missing"
      end try
      try
        set minecraftModsState to kind of alias minecraftModsFolder
      on error
        set minecraftModsState to "missing"
      end try
    end tell
    if minecraftJarState is "Alias" then
      do shell script "rm " & quoted form of POSIX path of minecraftJarFile
    end if
    if minecraftJinputState is "Alias" then
      do shell script "rm " & quoted form of POSIX path of minecraftJinputFile
    end if
    if minecraftLwjgl_utilState is "Alias" then
      do shell script "rm " & quoted form of POSIX path of minecraftLwjgl_utilFile
    end if
    if minecraftLwjglState is "Alias" then
      do shell script "rm " & quoted form of POSIX path of minecraftLwjglFile
    end if
    if minecraftModsState is "Alias" then
      do shell script "rm -r " & quoted form of POSIX path of minecraftModsFolder
    end if
  end if
  
  --Sync up the local world folder with the world folder on the RAM disk & eject the RAM disk
  --or
  --Sync up the default location saves with the current saves folder on the flash drive
  if savesFolderTarget is "Broken" then
  else
    if minecraftType is "Singleplayer" then
      if driveTypeToUse is "Flash Drive" then
        tell application "Finder"
          set flashDriveMounted to exists of disk of alias remoteSavesPath
        end tell
        if flashDriveMounted is true then
          if announceActions is "voice" then
            say "Syncing saves with flash drive" using announcementVoice
          else if announceActions is "growl" then
            showGrowl("Shutdown Notifications", "Syncing saves with flash drive")
          end if
          do shell script "rm " & quoted form of POSIX path of savesPath & ";
                  mv -f " & quoted form of POSIX path of minecraftPath & ".saves " & quoted form of POSIX path of savesPath & ";
                  rsync -qrtu " & quoted form of POSIX path of remoteSavesPath & "saves " & quoted form of POSIX path of minecraftPath
        else
          beep
          display alert "Unable to Sync with Flash Drive!" message "MaximumMinecraft was unable to sync your saves folder with the saves folder on the flash drive because the flash drive could not be found.

Make sure your flash drive is plugged in and accessible and then re-run MaximumMinecraft once it quits to sync your saves.

MaximumMinecraft will now continue & restore the settings changed by your preferences to their original state." as warning
        end if
      else if driveTypeToUse is "RAM Disk" then
        tell application "Finder"
          set minemasterMounted to exists of disk "Minemaster"
        end tell
        if minemasterMounted is true then
          if announceActions is "voice" then
            say "Syncing saves with RAM disk" using announcementVoice
          else if announceActions is "growl" then
            showGrowl("Shutdown Notifications", "Syncing saves with RAM disk")
          end if
          try
            do shell script "rm " & quoted form of POSIX path of savesPath & "/" & quoted form of chosenWorldFolder & ";
                    mv -f " & quoted form of POSIX path of savesPath & "/." & quoted form of chosenWorldFolder & " " & quoted form of POSIX path of savesPath & "/" & quoted form of chosenWorldFolder & ";
                    rsync -qrtu /Volumes/Minemaster/" & quoted form of chosenWorldFolder & " " & quoted form of POSIX path of savesPath
            if announceActions is "voice" then
              say "Unmounting RAM disk" using announcementVoice
            else if announceActions is "growl" then
              showGrowl("Shutdown Notifications", "Unmounting RAM disk")
            end if
            do shell script "umount /Volumes/Minemaster"
          end try
        else
          beep
          display alert "Unable to Sync with RAM Disk!" message "MaximumMinecraft was unable to sync your chosen world folder with the world folder on the RAM disk because the RAM disk is not mounted.

If Minecraft just quit, any changes to your chosen world on RAM disk since your last use of the \"Synch with RAM disk service\" are likely lost, though your backups should still be intact.

If MaximumMinecraft has not yet launched Minecraft, this just means it never managed to mount the RAM disk, and you've got nothing to worry about, other than MaximumMinecraft apparently not working correctly.

In either case, MaximumMinecraft will now continue & restore the settings changed by your preferences to their original state." as warning
        end if
      end if
    end if
  end if
  
  --re-enable two-finger scrolling
  if disableTwoFingerScroll is true then
    set goToHandler to "enableTwoFingerScrolling"
    run script versionSpecificScript with parameters {goToHandler}
    if result is true then
      if announceActions is "voice" then
        say "Re-enabling two finger scrolling" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Shutdown Notifications", "Re-enabling two finger scrolling")
      end if
    end if
  end if
  tell application "System Preferences" to quit
  
  --re-enable Magic Mouse scrolling
  if disableMagicMouseScroll is true then
    set goToHandler to "enableMagicMouseScrolling"
    run script versionSpecificScript with parameters {goToHandler}
    if result is true then
      if announceActions is "voice" then
        say "Re-enabling Magic Mouse scrolling" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Shutdown Notifications", "Re-enabling Magic Mouse scrolling")
      end if
    end if
  end if
  
  --reset desktop settings
  if disableDesktopRotation is true then
    tell application "System Events"
      if picture rotation of desktop 1 = 0 then
        set picture rotation of desktop 1 to 1
      end if
      delay 0.5
      if random order of desktop 1 = false then
        set random order of desktop 1 to true
      end if
    end tell
    if announceActions is "voice" then
      say "Re-enabling desktop rotation" using announcementVoice
    else if announceActions is "growl" then
      showGrowl("Shutdown Notifications", "Re-enabling desktop rotation")
    end if
  end if
  if disableTranslucence is true then
    tell application "System Events"
      if translucent menu bar of desktop 1 is false then
        set translucent menu bar of desktop 1 to true
      end if
    end tell
    if announceActions is "voice" then
      say "Re-enabling menu bar translucence" using announcementVoice
    else if announceActions is "growl" then
      showGrowl("Shutdown Notifications", "Re-enabling menu bar translucence")
    end if
  end if
  
  --re-launch all the apps that were quit by MaximumMinecraft
  if (quitRunningApps as text) is not "false" then
    if runningApps is not {} then
      if announceActions is "voice" then
        say "Re-launching applications" using announcementVoice
      else if announceActions is "growl" then
        showGrowl("Shutdown Notifications", "Re-launching applications")
      end if
      repeat with AppName in runningApps
        activate application AppName
      end repeat
    end if
  end if
  set unwiseQuit to false
  quit
end postPlayCleanup

#ABORT!!!
on quit
  if unwiseQuit is false then
    continue quit
  else
    beep
    display alert "You Probably Shouldn't Quit!" message "Well, it looks like you're quitting out of MaximumMinecraft while it's doing something you should probably let it complete.

If you've finished playing Minecraft, just quit out of Minecraft and MaximumMinecraft will restore your system settings & quit itself when it is finished.

If you're sure you know what you're doing and want to quit MaximumMinecraft anyway, you can use the \"Force Quit...\" option under the Apple menu." as warning
  end if
end quit
        