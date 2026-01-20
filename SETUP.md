# ECE 411: Staff Documentation

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


# SCons cheatsheet
```
$ scons -c                                            # Clean build directory
$ scons audit PROFILE=alu_tb                          # RTL banned words and patterns check, not spyglass linting
$ scons sim PROFILE=alu_tb                            # Run sim for alu_tb
$ scons verdi PROFILE=alu_tb                          # Run verdi for alu_tb
$ scons sim PROFILE=cpu_tb PROG=prog.elf DUMP_FSDB=0  # Run cpu testbench, don't dump FSDB
$ scons syn PROFILE=alu_tb                            # Synthesis
$ scons lint PROFILE=alu_tb                           # Spyglass lint
$ scons dv PROFILE=tree_tb                            # Launch DV (Type exit in the GUI console to close)
$ scons target RAW=1|yes|true                         # Native TTY output, no text collapsing
```
