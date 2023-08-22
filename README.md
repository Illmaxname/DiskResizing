# Info
Since the program uses direct access to sectors
hard disk, you need to execute it in a real mode operating environment, that is, 16-bit. The utility has a number of restrictions and requirements, the result of non-execution of which is unpredictable. The user assumes all responsibility for improper use of the program.<br/>
The development, debugging and testing of the utility was carried out in MSDOS using the tools of the TASM software package.
## General operation of the program
After starting the utility, the boot sector is read
hard disk, which checks for the presence of a system code
extended section. If an extended partition on a hard drive
is present, then 1 sector of this section is read, which
corresponds to the EPR of the 1st logical disk, then the presence is checked
second logical drive. If the second logical drive is present, then
the EPR sector of this disk is read and the user is shown
the size of the logical disk in sectors.<br/>
Next, a prompt is displayed on the screen, the user
it is proposed to enter a new (less than the current) size of the 2nd logical disk
in sectors. The entered size will be written to the EPR table.<br/>
If you enter a size larger than the current one, a message will be displayed about
error and again prompted to enter a new size, similarly when entering
size less than 64.
