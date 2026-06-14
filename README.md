<p>Launcher is a powerful utility that support Terminal UI and Graphical UI and allows you to:</p>

<ul>
    <li>Save and organize multiple scripts and applications</li>
    <li>Enable or disable scripts on demand</li>
    <li>Run scripts and applications using GUI or terminal</li>
    <li>Run everything silently on system startup</li>
    <li>Run multiple scripts simultaneously or sequentially</li>
    <li>Load multiple scripts from external file</li>
    <li>Use AutoHotkey built-in and environment variables</li>
</ul>

![](/Images/Dual_UI.png)
![](/Images/frame_fast.gif)

## Quick Start

[Download and run `launcher.ahk`](https://github.com/JoyHak/Launcher/releases/latest). Add path to your script and click `Run` button. Create `.lnk` file in `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup` to run this script on system startup: `"path\to\launcher.exe" -autorun`.
If you prefer command line, add `launcher.exe` to PATH. Then open powershell or cmd and type:
```powershell
launcher --add=myscript.ahk
launcher --run=myscript.ahk
launcher -scripts
```
> `launcher.ahk` supports GUI mode only.

`launcher -scripts` and `launcher.ahk` displays the same scripts. You can manage them from terminal and GUI simultaneously!
![](/Images/frame_rainbow.gif)

## Usage Syntax

```fsharp
launcher --param=script1[;script2;script3...]
launcher --param=@file
launcher -switch
launcher variable=value
```

<table>
    <thead>
        <tr>
            <th>Pattern</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>--param=value</code></td>
            <td>Execute a parameter with a value</td>
            <td><code>launcher --run=script</code></td>
        </tr>
        <tr>
            <td><code>--param=val1;val2</code></td>
            <td>Multiple values separated by semicolon</td>
            <td><code>launcher --run=script1;script2</code></td>
        </tr>
        <tr>
            <td><code>--param=@file</code></td>
            <td>Load values from external file</td>
            <td><code>launcher --add=@list.ini</code></td>
        </tr>
        <tr>
            <td><code>-switch</code></td>
            <td>Execute a switch (no value)</td>
            <td><code>launcher -autorun</code></td>
        </tr>
        <tr>
            <td><code>variable=value</code></td>
            <td>Set a custom variable</td>
            <td><code>launcher myvar=C:\path</code></td>
        </tr>
    </tbody>
</table>

#### Parameters

Parameters perform specific actions on your scripts.

<table>
    <thead>
        <tr>
            <th>Parameter</th>
            <th>Description</th>
            <th>Usage Example</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>--add</code></td>
            <td>Add script(s) to the saved list</td>
            <td><code>launcher --add=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--enable</code></td>
            <td>Enable script(s). Can add and enable simultaneously</td>
            <td><code>launcher --enable=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--disable</code></td>
            <td>Disable script(s). Can add and disable simultaneously</td>
            <td><code>launcher --disable=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--run</code></td>
            <td>Run enabled script(s) immediately</td>
            <td><code>launcher --run=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--close</code></td>
            <td>Close running script(s)</td>
            <td><code>launcher --close=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--remove</code></td>
            <td>Remove script(s) from the saved list</td>
            <td><code>launcher --remove=script.ahk</code></td>
        </tr>
        <tr>
            <td><code>--sep</code></td>
            <td>Set custom separator for multiple scripts</td>
            <td><code>launcher --sep=^ --run=s1^s2</code></td>
        </tr>
    </tbody>
</table>

> [!tip]
> Parameters can be combined in a single command. They execute in left-to-right order:
> `launcher --add=script1.ahk --add=script2.ahk --enable --run`

#### Switches

<p>Switches control global behavior and data management. They don't require values.</p>

<table>
    <thead>
        <tr>
            <th>Switch</th>
            <th>Description</th>
            <th>Use Case</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>-autorun</code></td>
            <td>Run all enabled scripts automatically</td>
            <td>Launch all your enabled scripts with one command</td>
        </tr>
        <tr>
            <td><code>-autoclose</code></td>
            <td>Close all running scripts</td>
            <td>Shut down all active scripts</td>
        </tr>
        <tr>
            <td><code>-vars</code></td>
            <td>Display all saved variables</td>
            <td>View your configured variables</td>
        </tr>
        <tr>
            <td><code>-scripts</code></td>
            <td>Display all saved scripts</td>
            <td>See what scripts are registered</td>
        </tr>
        <tr>
            <td><code>-vars-clear</code></td>
            <td>Clear all saved variables</td>
            <td>Reset all custom variables</td>
        </tr>
        <tr>
            <td><code>-scripts-clear</code></td>
            <td>Clear all saved scripts</td>
            <td>Reset script registry</td>
        </tr>
        <tr>
            <td><code>-save</code></td>
            <td>Write all data to disk immediately</td>
            <td>Force save without processing remaining parameters</td>
        </tr>
        <tr>
            <td><code>-restore</code></td>
            <td>Restore data from disk</td>
            <td>Reload configuration from disk</td>
        </tr>
        <tr>
            <td><code>-verbose</code></td>
            <td>Show additional messages</td>
            <td>Debug and see detailed output</td>
        </tr>
        <tr>
            <td><code>-help, -h, -?</code></td>
            <td>Show help message</td>
            <td>Display built-in documentation</td>
        </tr>
    </tbody>
</table>

### Script Management
#### Adding Scripts
```fsharp
launcher --add=quickswitch.ahk
launcher --add=C:\Ahk\radify.ahk
```

In GUI you can specify path to the script in the input field and click `Add` at the bottom:
![](/Images/frame_fast.gif)

You can insert an absolute path *(C:\AutoHotkey\QuickSwitch)*, a path relative to the current working dir *(QuickSwitch)* or just filename *(script.ahk)*.

#### Enabling/Disabling Scripts
```fsharp
launcher --enable=quickswitch
launcher --disable=radify
```
In GUI use buttons at the bottom to manage scripts:
![](/Images/frame_rainbow.gif)

#### Running Scripts
By filename:
```fsharp
launcher --run=quickswitch
```
By full path:
```fsharp
launcher --run=C:\Ahk\quickswitch.ahk
```
You can run all scripts at once:
```fsharp
launcher -autorun
```
> [!tip]
> This switch runs all scripts and applications silently. You can create shortcut in `%AppData%\Microsoft\Windows\Start Menu\Programs\Startup` with this switch: `"path\to\launcher.exe" -autorun`.

#### Closing Scripts</h3>
```fsharp
launcher --close=quickswitch
launcher -autoclose
```

#### Removing Scripts
```fsharp
launcher --remove=quickswitch
launcher --remove=script1;script2;script3

launcher -scripts-clear
```

#### Viewing Saved Scripts
```fsharp
launcher -scripts
launcher -scripts -verbose
```
Terminal switch `-scripts` and Graphical List View displays the same information, which means you can use both TUI and GUI to query required information.
![](/Images/TUI_scrips.png)
![](/Images/GUI_scripts.png)

### Custom Separators
By default, multiple scripts are separated by semicolon `;`
```fsharp
launcher --run=quickswitch;radify;arrows
```
You can change this for batch operations:
```fsharp
launcher --sep=^ --run=quickswitch^radify^arrows
```
Separator is saved:
```fsharp
launcher --run=script1^script2
launcher --run=script3^script4
```
Separator can be changed in GUI. You can use it in the input field.
<img width="568" height="354" alt="separator" src="https://github.com/user-attachments/assets/9de6bc50-d21e-4df0-9544-61458d458690" />

#### Escaped values
For batch/PowerShell special characters, use quotes to escape them:
```fsharp
launcher --sep='|'
launcher --sep"|"
launcher --sep='&'
```
> [!tip]
> If you need quotes inside quotes, escape them with backticks:
> ```fsharp
> launcher --sep="`""
> launcher --sep='`''
> ```

### File References
Load multiple scripts from external files using the `@file`, where *file* can be any path with `@` prefix:
```fsharp
launcher --add=@list.in
launcher --remove=@list.ini
launcher --run=@scripts.ini
```
`list.ini` simply lists file paths:
```
AutoHotKey\MarkdownToBBCode\MarkdownToBBCode.exe
AutoHotKey\ChangeLogSorter\ChangeLogSorter-1.0.ahk
AutoHotKey\QuickSwitch\QuickSwitch.ahk
```
Paths can be on individual lines or on asingle line:
```
AutoHotKey\MarkdownToBBCode\MarkdownToBBCode.exe;AutoHotKey\ChangeLogSorter\ChangeLogSorter-1.0.ahk
AutoHotKey\QuickSwitch\QuickSwitch.ahk
```
`;` separator [can be changed](#custom-separators).
![](/Images/load_script.gif)

You can pass simple filename relative to current working directory:
```fsharp
launcher --add=@list.ini
```
...or pass quoted full path:
```fsharp
launcher --run=@'C:\Temp files\My scripts'
launcher --run='@C:\Temp files\My scripts'
launcher --run="@C:\Temp files\My scripts"
```

`@file` can be passed to *any* [parameter](#parameters). Use it to organize your scripts into logical groups and version control them easily.

## Variables
Save and reuse custom variables that persist across sessions. For any [parameter](#parameters) or GUI input field you can pass a path that contains [environment variables](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-recognized-environment-variables); built-in [AutoHotkey variables](https://www.autohotkey.com/docs/v2/Variables.htm#BuiltIn) or manually defined variables *(see below)*. Enclose the variables in percent signs `%`
```fsharp
launcher --run=%A_Temp%\DarkTheme.ahk
launcher --add=%TEMP%\scripts.ini
```

#### Define Variables
To define a new variable with *any* value, simply write `name=value` without any prefix like `--` or `@`
```fsharp
launcher mainDir=C:\Scripts\DarkGui
launcher projectPath=C:\MyProject
```
Values with spaces must be [escaped with quotes](#escaped-values):
```fsharp
launcher mainDir="C:\My Scripts\Dark Gui"
launcher projectPath='C:\Temp Scripts'

launcher --run=%mainDir%\DarkTheme.ahk
launcher --add=@'%projectPath%\scripts.ini'
```

#### Variables in Variables
New variable can hold literals and other [variables](#variables), including env. vars:
```fsharp
launcher mainDir=%A_ScriptDir%\DarkGui
launcher projectPath=%A_Temp%\myproject
launcher dataPath=%AppData%\Data

launcher --run=%mainDir%\DarkTheme.ahk
launcher --add=%projectPath%\project.ahk --add=@%dataPath%\data.ini

```

#### Modify On The Fly
Change variable values within a single command to control different execution paths:
```fsharp
launcher AhkDir=C:\Ahk --run=%AhkDir%\quickswitch AhkDir=C:\Scripts --run=%AhkDir%\radify
```
First part runs script from `C:\Ahk`, second part runs script from `C:\Scripts`. In the end `AhkDir` variable holds last path, i.e.  `C:\Scripts`. So you can reuse it later.

#### Removing Variables
Pass empty value or `unset` to remove existing variable:
```fsharp
launcher mainDir=
launcher mainDir=unset
```
Non-existing variable cannot be initialized with empty value!

You can remove all variables:
```fsharp
launcher -vars-clear
```


#### Variables in Paths
Variables can be passed to *any* [parameter](#parameters) and [file list](#file-references) *(@file)*
```fsharp
launcher listfile=C:\config\scripts.ini --add=@%listfile%
launcher --run=%A_ScriptFullPath%

launcher projectPath=C:\Long Long Path
launcher --add=@'%projectPath%\My Scripts\scripts.ini'
```

#### Variables in List
[File list](#file-references) *(@file)* can contain scripts, variables, and AutoHotkey variables separated by your chosen separator:
```
C:\s1.ahk;C:\s2.ahk
C:\%A_Temp%\s3.ahk
C:\%myvar%\s4.ahk
%A_ScriptDir%\local.ahk
```
Newline "`n" serves as separator too, so you can group scripts on individual lines:
```
C:\s1.ahk;C:\s2.ahk
C:\%A_Temp%\s1.ahk;C:\%A_Temp%\s2.ahk
```

## Examples
#### GUI
![](/Images/frames.gif)
![](/Images/vars_expand.gif)

#### Command line
Basic workflow:
```fsharp
launcher --add=quickswitch.ahk
launcher --enable=quickswitch
launcher --run=quickswitch
```
Multiple scripts:
```fsharp
launcher --add=script1.ahk --add=script2.ahk --add=script3.ahk
launcher --run=script1.ahk;script2.ahk;script3.ahk
```
Project setup with variables:
```fsharp
launcher projectDir=C:\MyProject
launcher scriptsFile=%projectDir%\scripts.ini
launcher --add=@%scriptsFile%
launcher --enable
launcher -autorun
```
Development and Production:
```fsharp
launcher env=dev --run=%env%\test.ahk env=release --run=%env%\public.ahk
```
Custom separator for readable scripts list:
```fsharp
launcher --sep=| --run=cleanup|optimize|backup|report
```
Load from external file:
```fsharp
launcher --add=@'C:\Scripts\utilities.ini'
launcher --enable
launcher -autorun -verbose

launcher -autoclose -save -vars-clear
```

## Disk Usage
Each parameter can modify some internal data: variables, scripts paths, etc. Data is normally written to disk **after all parameters are processed** to reduce disk I/O operations. Use `-save` if you need to save data immediately:
```fsharp
launcher --add=script1 --add=script2 -save
launcher -restore -verbose
```

Backup your `.ini` configuration: `-save` and `-restore` aren't magical switches, they can fail to restore previous version.

## Debugging
If something doesn't working as expexted, please [report about it](https://github.com/JoyHak/Launcher/issues/new?template=bug-report.yaml). You can pass `-verbose` swith to each command to get additional information.
![](/Images/TUI2.png)
If you're using terminal, attach this information to report please. In GUI mode use *ShareX* or *IceCream screen recorder* to record a video/gif with unexpected behavior.
