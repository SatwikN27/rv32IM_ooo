# ECE 411: mp_setup Documentation

Welcome to ECE 411! In this MP, you will set up your environment for the coming MPs this semester.
This document will go over how you can work on this course's MPs remotely by connecting to EWS.

# Environment Setup

We are using mainly the Synopsys toolchain for all MPs in this course. These tools are not available to be
setup on your own machine. You will need to use EWS to access these tools.

You have two options for your remote work environment setup: FastX or SSH with X-Forwarding.
Once you are able to connect remotely to an EWS machine you can move on to the next section.

FastX pros:

- Easy to setup
- Higher framerate
- Works in browser
- Works well under network with high latency and/or low bandwidth
- Usually performs better than SSH with X-Forwarding

SSH with X-Forwarding pros:

- Sharper image, native resolution
- Sometimes performs better than FastX if you are using Linux

If you prefer to do not work remotely, you can visit any campus
[Linux EWS Lab](https://answers.uillinois.edu/illinois.engineering/page.php?id=104731).

## FastX

EWS has a remote X desktop set up for students. There are two ways to access FastX: either through a web
browser at **fastx.ews.illinois.edu** or by downloading a client and connecting to FastX through there.
The instructions and download for the client can be found [here](https://answers.uillinois.edu/illinois.engineering/81727).
If you have issues with FastX, please contact engineering IT by means listed [here](https://engrit.illinois.edu/contact-us).

## SSH with X-Forwarding

EWS has set up a couple of servers that students can access over SSH. You can reach these using your favorite
SSH client by connecting to the EWS SSH server **linux.ews.illinois.edu**.

Almost all students have found that having a graphical waveform viewer (Verdi) useful. You may be the same,
in which case you may want to set up X-forwarding. Many SSH clients already include a built-in local X server. Some SSH
clients, however, require installing and configuring a local X server separately.

If you are using X-forwarding, please turn on compression (option `-C` in command line) in SSH, as X-forwarding
requires huge amount of bandwidth for graphical application. In real practice, SSH compression can reduce a huge
fraction of bandwidth use (~300 Mbps to ~10 Mbps from our experiences).

### Windows

Here are some SSH clients, X servers, and tools on Windows:

- MobaXterm (SSH client with built-in X server)
- PuTTY (SSH client)
- SecureCRT (SSH client)
- Xming (X server)
- WinSCP (File management for FTP, SFTP, SSH)

We recommend using MobaXterm, as installation is simple and it already includes a built-in X server. If you would
like to use MobaXterm as your SSH client, follow these instructions.

Navigate [here](https://mobaxterm.mobatek.net/download-home-edition.html) and follow the instructions to download and
install MobaXterm.

You can create a saved session by clicking `session` on the menu bar, then select `SSH`.

- In `Remote host`, input `linux.ews.illinois.edu`
- In `Username`, input your NetID
- In `Advanced Settings`, enable X-Forwarding and compression.
- Optionally, supply SSH private key here, detailed in the next section.

Once you are done, you will find this saved session on the side bar. Double click on it to connect.

### Mac

SSH client comes built in in Mac, however, you need to install X-server separately.
We recommend using XQuartz as your local X-server. You can download and install XQuartz [here](https://www.xquartz.org/).

Once installed, start the application XQuartz and open a terminal by selecting Applications -> Terminal.
You can also use MacOS's own terminal.

Now, you can SSH into EWS by running (replacing `NETID` with your NETID):

```
$ ssh -CY NETID@linux.ews.illinois.edu
```

`-X` or `-Y` enables X-forwarding and `-C` turns on compression for X-forwarding.
After that, you should be connected to EWS with X-forwarding enabled.

### Linux and WSL

Make sure you have a X-server running, and simply run (replacing `NETID` with your NETID):

```
$ ssh -CY NETID@linux.ews.illinois.edu
```

And it should be good to go now.

You can read about the difference between `-X` and `-Y` [here](https://man7.org/linux/man-pages/man1/ssh.1.html).
We have observed that some features of Verdi such as zooming the wave window using mouse wheels might not work
if using untrusted X-Forwarding (`-X`). Please consider using trusted X-Forwarding (`-Y`) if you encounter those issues.

## SSH with Keys

Tired of having to type your password every time you SSH? Here is how you can enable PubKey authentication on SSH.

**It is worth noting that the ssh private key is basically your password. Keep it safe and do not share it!!**

### MobaXterm

- On the menu bar, select Tools -> MobaKeygen
- We recommend using EdDSA -> ED25519
- Click Generate
- Save PuTTY formate private key to somewhere safe
- Record the public key
- In the session settings, select saved private key file in advanced setting menu.
- SSH onto EWS, and use your favorite text editor to put the public key into `~/.ssh/authorized_keys`
- Make sure to `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys`.

### Mac, Linux and WSL

- Run `ssh-keygen -t ed25519`
- Read the Public key from `~/.ssh/id_ed25519.pub`
- SSH onto EWS, and use your favorite text editor to put the public key into `~/.ssh/authorized_keys`
- Make sure to `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys`.

### VSCode (with Remote-SSH Plugin) on Windows

- Generate ssh keys, either:
  - Follow steps above for MobaXterm
    - It is OK to re-use key generated for your MobaXterm SSH Session
    - During saving private key, select Conversion -> Export OpenSSH Key
  - Follow steps above for Mac, Linux and WSL
- Save OpenSSH format private key to `C:\Users\[Your User Name]\.ssh\id_ed25519`

# Creating the Github Repository

## SSH Key

We highly recommend setting up public key authentication with GitHub so you do not have to type your password every time you commit your code.

Note that this is a different key from the one in the previous section. Both are SSH keys used in SSH authentication,
However, the last one is used to authenticate your own machine with EWS, and this one is to authenticate EWS with GitHub.
We do not recommend re-using SSH keys.

You can create a public key for your SSH client by running the following on EWS:

```
$ ssh-keygen -t ed25519
> Enter a file in which to save the key (~/.ssh/id_ed25519): [press enter]
> Enter passphrase (empty for no passphrase): [type passphrase, or leave empty and press enter.]
> Enter same passphrase again: [type same passphrase again]
$ eval "$(ssh-agent -s)"
$ ssh-add ~/.ssh/id_ed25519
```

Print your public key to the terminal so you can copy it and add it to your Github:

```
$ cat ~/.ssh/id_ed25519.pub
```

Navigate [here](https://github.com/settings/keys) and you should see the following web page:

![SSH and GPG keys](./doc/figures/ssh_keys.png)
Figure 1: SSH and GPG keys

Select **New SSH Key** and type in a descriptive title. Paste your copied public key into the **key** field:

![Enter your new SSH key](./doc/figures/new_ssh.png)
Figure 2: Enter your new SSH key.

Click **Add SSH key** and type in your GitHub password if prompted.

![Authorize Illinois coursework](./doc/figures/auth_ssh.png)
Figure 3: Authorize Illinois coursework.

Click on configure SSO and authorize illinois-cs-coursework.

## Illinois CS Network GitHub Repository

To create your Git repository, go to https://edu.cs.illinois.edu/create-gh-repo/sp26_ece411.
The page will guide you through the setup of connecting your github.com account and your Illinois NetID.
You will need a github.com account in order to create the course repository. Please follow all the instructions on the link above.

Next, on EWS, create a directory to contain your ECE 411 files (this will include subdirectories for each
MP, so chose a name such as `ece411`) and execute the following commands (replacing `NETID` with
your NetID):

```
$ mkdir ece411
$ cd ece411
$ git init
$ git remote add origin git@github.com:illinois-cs-coursework/sp26_ece411_NETID.git
$ git remote add release git@github.com:illinois-cs-coursework/sp26_ece411_.release.git
$ git pull origin main
$ git branch -m main
$ git fetch release
$ git merge --allow-unrelated-histories --no-ff release/main
$ git push --set-upstream origin main
```

If you have not set up SSH access to your github account, you may encounter errors during cloning.

# Setting up the software environment



### Step 1

For this class we use SCons as the build system which uses python scripts to run.
This is why we need to set up a python virtual environment (venv) and install some dependencies.
To setup the software and environment variables for this class, run the following script:

```
$ ./venv.sh
```

OR Alternatively you can set up the venv manually using the following commands:
```
$ python3.9 -m venv .venv
$ source .venv/bin/activate
$ pip install -U pip setuptools wheel
$ pip install scons rich pyyaml
```


### Step 2

Verify that your project directory tree looks similar to this now:

```
ece411/
├── .venv/
├── mp_setup/
├── mp_verif/
├── .gitignore
└── venv.sh
```

### Step 3
You will need to enter the venv every time you log on to EWS to do 411 work.

If you are using VScode/Cursor:
- Install the python extension. 
- Press `CTRL+SHIFT+P` and Search for `Python: Select Interpreter` 
- Choose the new .venv folder you created, it will auto source in the future if you do this. 


Alternatively you can just run the venv script when you log in:
```
$ ./venv.sh
```
This will auto detect the created .venv folder and put you inside the venv 

### venv troubleshooting

If something went wrong with your venv setup you can execute the fillowing commands to delete and remake it
```
$ ./venv.sh clean
$ ./venv.sh
```

## Audit

To prevent AG manipulation, 411 staff has made a list of banned systemverilog keywords that you cannot use in your designs.
To check if you have used any of these keywords you can run:

```
$ scons audit PROFILE=tb_target
```

tb_target will be explained in the custom testbenches section

## VCS

We use Synopsys VCS to simulate our designs in this course. After cloning mp_setup and setting up the class environment run:

```
$ scons sim PROFILE=tb_target
```

This will invoke the Synopsys VCS compiler, which build a simulation binary using the RTL design in `rtl` and the testbench in `tb`.
This will run the simulation and simulation will dump all signals in a fast signal database (FSDB) file.


## Custom Testbenches

The way VCS compiles files is determined by the `tb/svbuild.yaml` file.
the format for a testbench target is shown below :
```
tb_target:
  tb_top: path/to/main_tb_file.sv           # Required - Main testbench top file 
  scope: directory_or_list_of_directories   # Required - Specifies where to collect .sv files
  ordered_files:                            # Optional - files to compile in specific order
    - path/to/first_file.sv
    - path/to/second_file.sv
  includes:                                 # Optional - parent directories of these files will be added to include path
    - path/to/include_file.sv
    - path/to/another_include.sv
```

You can find more examples for tb_targets in the provided `svbuild.yaml`.
This will be useful for making custom testbench targets in the future (DV is very important!).

For this mp we can use `alu_tb` as the tb_target and for future mps the target names can be found in `svbuild.yaml`

## Verdi

Verdi is Synopsys's waveform viewer and debugger. We use it to inspect signals inside our design.
To view the signal dump from the simulation that you just ran:

```
$ scons verdi PROFILE=tb_target
```

![Verdi](./doc/figures/verdi.png)
Figure 4: Verdi

You can navigate the design hierarchy on the instance window on the left. Double clicking on an instance opens up the block's code in the source browser window.
Select any signal name in the source browser window and press `Ctrl + 4` or `Ctrl + w` to add it to the waveform viewer.

While a signal is selected, you can click on the driver or load buttons on the toolbar (with D and L as their logos respectively) to go to the source or destination
of the selected signal.

If you changed your design and re-ran the simulation, you can reload the waveform by `Shift + L` without closing and reopening Verdi.

A complete user guide to Verdi can be found on EWS:

```
$ xdg-open /class/ece411/docs/verdi.pdf
```

Due to the limited amount of license we have for Verdi,
to prevent you from forgetting to close Verdi,
by default Verdi will close after 1 hour after been opened.

## Spyglass

Spyglass is the linting tool. It will look at your source RTL code and report any potential problems in your design.

To lint the mp_setup design, in the `lint` folder, run:

```
$ scons lint PROFILE=tb_target
```

Generated reports are in `lint/reports`.

The main report to look at is `lint/reports/lint.rpt`. The specific report for this design should show no problems.

## Design Compiler

Synopsys Design Compiler is an RTL synthesis tool. A synthesis tool converts an RTL circuit specification into logic gates and flip-flops. It uses pieces available
in a standard cell library as building blocks. In ECE 411, we will use FreePDK45 as our target technology.
In the real world, the PDK or Process Design Kit is usually supplied by the foundry.

The synthesis tcl scripts have been set up for you.

To synthesize the mp_setup design, in the `syn` folder, run:

```
$ scons syn PROFILE=tb_target
```

Generated reports, including area and timing, are in `syn/reports`.

The area report will be an estimate of how much physical space a design will occupy in square micrometers.
The timing report will show the longest path delay in the design and whether it meets the timing requirement
imposed by the target clock frequency.

You can open the GUI for Design Compiler, called Design Vision, by:

```
$ scons dv PROFILE=tb_target
```

Due to the limited amount of license we have for Design Vision,
to prevent you from forgetting to close Design Vision,
by default Design Vision will close after 1 hour after been opened.

### Important
To exit DV Type exit in the GUI console or Context menu instead of closing using the button as that causes terminal glitches.

# SCons cheatsheet
```
$ scons -c                                                  # Clean build directory
$ scons audit PROFILE=tb_target                             # RTL banned words and patterns check, not spyglass linting
$ scons sim   PROFILE=tb_target                             # Run sim for alu_tb
$ scons verdi PROFILE=tb_target                             # Run verdi for alu_tb
$ scons sim   PROFILE=tb_target PROG=prog.elf DUMP_FSDB=0   # Run cpu testbench, don't dump FSDB
$ scons syn   PROFILE=tb_target                             # Synthesis
$ scons lint  PROFILE=tb_target                             # Spyglass lint
$ scons dv    PROFILE=tb_target                             # Launch DV (Type exit in the GUI console to close)
$ scons target RAW=1|yes|true                               # Native TTY output, no text collapsing
```
## SCons tip
Note that the arguments provided after the scons command can be rearranged. This is helpful for grindy 
debugging sessions as you might want to put the PROFILE argument before the scons target. 
It is more likely that you will be re-simulating with the same testbench multiple times and thus makes changing 
the target in the command line easier. 

For example the commands below are functionally equivalent:

```
$ scons audit PROFILE=tb_target
$ scons PROFILE=tb_target audit
```


# Deliverables

There are no deliverables for this MP. However, it is essential that you go through the steps listed here
to setup your development environment and understand the tools being used.

We encourage you to look at the provided scripts and post any questions about the tools to Campuswire or Piazza.
