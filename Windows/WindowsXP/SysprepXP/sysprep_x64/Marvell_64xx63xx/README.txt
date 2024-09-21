63xx\64xx Windows Drivers:
--------------------------

There are two driver packages for the 6320, 6340, 6440, 6445, 6480, and 6485 SAS controllers.
(1) Miniport Driver: basic Windows driver for the SAS controller 
(2) Optional Marvell Removable Disk Driver (MRDD): provides Hot Plug Port functionality


Installing Drivers:
-------------------

(1) Windows (Miniport) Driver
Use the Windows Control Panel 'Add Hardware Wizard' to install the driver. When prompted, browse to the  file labeled mv64xx.inf. 
For 64-bit OS, the driver is located in the folder: ..\amd64
For 32-bit OS, the driver is located in the folder: ..\i386

(2) Optional Hot Plug Port Functionality
To enable the optional Hot Plug port functionality, you will need to install the Marvell Removable Disk Driver (MRDD). This driver can be installed by executing mrddinst.cmd
For 64-bit OS, the installation file is located in the folder: ..mrdd\amd64
For 32-bit OS, the installation file is located in the folder: ..mrdd\i386

Upon installation and after reboot, you can access the "Hot Plug" tab under Driver Properties in the System Device Manager (My Computer > Properties > Hardware > Device Manager > SCSI and RAID Controllers > Marvell 64xx/63xx SAS Controller). 

Using Hot Plug Port Functionality:
----------------------------------

MRDD (Marvell Removable Disk Driver) is an enhancement feature that provides "Safely Remove Hardware" functionality for ports. Disks connected to such ports will be listed in the Windows "Safely Remove Hardware" icon. This allows you to unplug HDDs to ports without power down the system.

When MRDD is installed, a tab titled "Hot Plug" appears in the device driver's Properties. This tab allows you to enable and disable ports with Hot Plug functionality. Changes to port settings will be effective only after you restart the system. Upon restart, when a HDD is connected to a port enabled with Hot Plug functionality, Windows will list the HDD in the "Safely Remove Hardware" dialog box. This dialog can be accessed by clicking the "Safely Remove Hardware" icon in the Windows System Task Bar.  When you safely remove a HDD through this dialog, the SAS controller will stop all I/O to the HDD and logically remove the device from the Device Manager. 



