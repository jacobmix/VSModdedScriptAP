1. Download [VSModdedScriptAP](<https://github.com/jacobmix/VSModdedScriptAP/releases/{{VERSION}}>)'s [VSAPSetup.zip](https://github.com/jacobmix/VSModdedScriptAP/releases/download/{{VERSION}}/VSAPSetup.zip), and extract to a safe location. (Install [PowerShell 7](<https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6#msi>) if it's missing.)
2. Run the bat file. (If it does not work run as admin using Shift+RightClick.) Linux: Run the sh file.
3. Select & download/downgrade DLCs you own. (Will ask for steam password, and 2FA.)
4. Once done you should have a "Vampire Survivors AP" folder in your "Archipelago" directory. (Will fallback to Steam library location if it can't install to AP)
5. Run the shortcut or "Browse files" in Archipelago Launcher, and manually run the ``VampireSurvivors.exe``
6. Enjoy. This version should now run with Archipelago. (First launch will be slow.)
   - Bonus: Add as none-steam game:
Steam>Library>Add a game>Add None-Steam Game>Browse...>"VampireSurvivors.exe">Add. (If you can't add browse again.)
Search "VampireSurvivors" in your Steam library. Right click the item you added. Go to properties.
Rename to "Vampire Survivors AP" or such. Then start it.
Linux: Add this to launch options: ``WINEDLLOVERRIDES="version=n,b" %command%``

If problems with user login temporarily move or delete:
``C:\Program Files (x86)\Steam\config\loginusers.vdf`` ``~/.config/Steam/config/loginusers.vdf``

If shortcut doesn't work. Check that install directories are not hidden or locked. Make sure [Show hidden files](<https://support.microsoft.com/en-us/windows/experience/fileexplorer/file-explorer-in-windows>) is enabled.
Path should be mentioned at the end of the script, and in the shortcut. But here's some examples:
``C:\ProgramData\Archipelago\Vampire Survivors AP`` 
``C:\Program Files (x86)\Steam\steamapps\common\Vampire Survivors AP``
``D:\SteamLibrary\steamapps\common\Vampire Survivors AP``
Note: Stuff is temporarily stored at ``%TEMP%\VSModSetup``, and is automatically deleted once done.

Get apworld here: https://github.com/SWCreeperKing/ArchipelagoSurvivors/releases/latest Also: [README](https://github.com/SWCreeperKing/ArchipelagoSurvivors/blob/master/README.md)
Archipelago Discord: https://discord.gg/8Z65BR2 (Might have pre-release apworlds, and cool people.)

> How to use an .apworld (After installing [Archipelago](https://github.com/ArchipelagoMW/Archipelago/releases/latest)):
> * Place the .apworld in your `Archipelago/custom_worlds` folder, or double-click the .apworld to do so automatically.
> * Use `ArchipelagoLauncher.exe` to open the Launcher, and click on Options Creator to create player yamls for your custom .apworlds.
> * Save/move the desired player yamls into the `Players` folder.
> * Click Generate in the Launcher, or use `ArchipelagoGenerate.exe` to generate the game.
> * Upload the generated game (zip file in the `output` folder) on the website at https://archipelago.gg/uploads and create a new room.
> * Refer to the individual game's setup guide for further instruction (usually in the pins for the game's [future-game-design](https://discord.com/channels/731205301247803413/1009608126321922180) post or its github).
> * If your game needs additional files or patches but doesn’t display in your room page, you can find them inside the zipped file in your `output` folder.

Bonus:
[Universal Tracker](https://github.com/FarisTheAncient/Archipelago/releases?q=tracker&expanded=true) (apworld client to track what is in logic using your yaml)
[Apworld Manager](https://github.com/silasary/Archipelago/releases?q=Manager) (apworld client to install & update apworlds)
<br/>

Note: It's recommended having a save file with most characters & stages unlocked or change your yaml to what you have unlocked.
Save file is stored at `%PROGRAMFILES%\Steam\userdata\<user-id>\1794680\remote\SaveData` or `%APPDATA%\Vampire_Survivors\saves`.

__**Quick guide to save editing! (By [stafliix](<https://discord.com/channels/904353235006017556/937659884470693908/1407470634174382283>))**__ 
Kinda hard to make an extensive guide since there are so many things you can edit. 
As always, make a backup of your save before doing anything. All you have to do is copy the save file somwhere else.
- To make things easier to read and manage, install [notepad++](<https://notepad-plus-plus.org/downloads>) and the [jstool plugin](<https://www.sunjw.us/jstool/vsc/?redirect_src=jstool>) (for the jsmin/jsformat options).
- Open the save file with Notepad ++, press "jsformat" in the jstool tab of "Plugins" and it will become much easier to read.
- Some notable things to edit include:
* `"BoughtCharacters":` through `"Secrets":` to manage unlocked characters, weapons, achievements (unlocks) and secrets.
* `"EggData":` to remove (or add) Golden Eggs.
* `"StageCompletionLog":` to give/remove checkmarks for clearing stages.
* And of course, `"Coins":` to..... give you more coins.
 ** Make sure to follow how things are listed if you're unlocking stuff. For example, if you want to add Greatest Jubilee to your save, make sure you put `, "JUBILEE"` at the end of `"UnlockedWeapons":` (and `"GreatestJubilee"` at the end of `"Achievements"` to avoid unlocks messing up).
- After you've edited whatever you wanted to, go back to the plugins menu and press "jsmin".
- search for `"checksum":` and delete the string in between the quotes (bunch of random letters/numbers)
- Go to <https://emn178.github.io/online-tools/sha256.html> and copy paste in the ENTIRE savefile **as a single line. No line breaks.**
- Replace the deleted checksum from earlier with the new checksum.
- Save the file, and enjoy!
**Note that save editing is not the exact same as modding. You can NOT add things that don't exist in the game to your save. This is just for editing value and some stuff that already exists.**