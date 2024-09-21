  Microsoft Windows Server 2003 with Service Pack 1 (SP1)
                    Deploy.cab
                  Readme Document
                  January 17, 2005

Information in this document, including URL and other Internet Web 
site references, is subject to change without notice and is provided 
for informational purposes only. The entire risk of the use or 
results of the use of this document remain with the user, and 
Microsoft Corporation makes no warranties, either express or implied. 
Unless otherwise noted, the example companies, organizations, 
products, people, and events depicted herein are fictitious. No 
association with any real company, organization, product, person, 
or event is intended or should be inferred. Complying with all 
applicable copyright laws is the responsibility of the user. Without 
limiting the rights under copyright, no part of this document may 
be reproduced, stored in or introduced into a retrieval system, or 
transmitted in any form or by any means (electronic, mechanical, 
photocopying, recording, or otherwise), or for any purpose, without 
the express written permission of Microsoft Corporation.

Microsoft may have patents, patent applications, trademarks, 
copyrights, or other intellectual property rights covering subject 
matter in this document. Except as expressly provided in any written 
license agreement from Microsoft, the furnishing of this document 
does not give you any license to these patents, trademarks, 
copyrights, or other intellectual property.

(c) 2005 Microsoft Corporation. All rights reserved. 

Microsoft, MS-DOS, Windows, and Windows NT are either registered 
trademarks or trademarks of Microsoft Corporation in the United States 
or other countries or regions. 

The names of actual companies and products mentioned herein may be 
the trademarks of their respective owners. 

========================
HOW TO USE THIS DOCUMENT
========================

To view the Readme file in Microsoft Windows Notepad, maximize 
the Notepad window. On the Format menu, click Word Wrap. 

To print the Readme file, open it in Notepad or another word 
processor, and then use the Print command on the File menu. 

========
CONTENTS
========

1. INTRODUCTION 

2. AVAILABILITY OF WINDOWS PE 

3. UPGRADING FROM PREVIOUS VERSIONS OF THE TOOLS

4. KNOWN ISSUES

5. DOCUMENTATION CORRECTIONS

---------------

1. INTRODUCTION
---------------

This document provides current information about the tools included 
in the Deploy.cab for Microsoft Windows Server 2003 with Service
Pack 1 (SP1) and Windows XP with Service Pack 2 (SP2).

NOTE: The Setup Manager tool (Setupmgr.exe) contained in Deploy.cab
      is intended for use only by corporate administrators. If you
      are a system builder, install the tools and documentation
      contained on the Windows OEM Preinstallation Kit (OPK) CD.
      A Windows OPK CD is contained in every multi-pack of Windows
      distributed by an OEM distributor to original computer 
      manufacturers, assemblers, reassemblers, and/or software
      preinstallers of computer hardware under the Microsoft OEM
      System Builder License Agreement.

Setup Manager no longer contains context-sensitive help. For more
information about the individual pages in Setup Manager, see the 
topic "Setup Manager Settings" in the Microsoft Windows Corporate
Deployment Tools User's Guide (Deploy.chm).

-----------------------------

2. AVAILABILITY OF WINDOWS PE
-----------------------------

Windows Preinstallation Environment (Windows PE) is licensed to 
original equipment manufacturers (OEMs) for use in preinstalling 
Windows onto new computers. Windows PE is available for enterprise 
customers. For more information, contact your account manager.

------------------------------------------------

3. UPGRADING FROM PREVIOUS VERSIONS OF THE TOOLS
------------------------------------------------

You can use the Windows Server 2003 with SP1 deployment tools to 
preinstall the following versions of Windows:

   * Original "gold" release of Windows XP 
   * Windows XP with Service Pack 1 (SP1) and Windows XP with
     Service Pack 2 (SP2)
   * Original version of Windows Server 2003
   * Windows Server 2003 with SP1

To preinstall x64 editions of Windows, use the tools located in the 
\tools\amd64 folder. To preinstall Itanium-based editions of Windows, 
use the tools located in the \tools\ia64 folder.

Do not use the original "gold" release of Windows XP corporate
deployment tools to preinstall the Windows Server 2003 family.

If you installed an earlier version of the corporate deployment tools,
you must upgrade those tools to the corporate deployment tools of 
Windows Server 2003 with SP1. Corporate deployment tools for earlier
versions cannot coexist on the technician computer with corporate 
deployment tools for Windows Server 2003 with SP1.

If you set up a distribution share with corporate deployment tools
from the original "gold" Windows XP release or Windows XP with SP1,
the Guest account is enabled. 

Setting up a new distribution share with the corporate deployment
tools for Windows Server 2003 with SP1 does not automatically enable 
the Guest account. Also, upgrading the tools does not change the 
properties of an existing distribution share.


---------------

4. KNOWN ISSUES
---------------

* Creating a Distribution Share on Windows Server 2003

If you install the corporate deployment tools on a computer running
Windows Server 2003, you may need to complete an additional step when 
creating a distribution share. On a computer running Windows Server 
2003, sharing a folder sets default permissions to read-only for
the group Everyone. If you intend to enable Everyone to write to the 
distribution share from across the network, you must add additional 
permissions.

Workaround: Add read-write permissions for the user(s) who need to
write remotely to the distribution share.

* Mini-Setup and MUI

If you preinstall the Multilingual User Interface (MUI) Pack during
Sysprep in Factory mode (Sysprep -factory) and restart the computer
into Mini-Setup, then all pages in Mini-Setup are truncated. 

Workaround: Set the default user interface for MUI to English.

* No Manual Modifications During Factory Mode

Do not manually modify the Windows installation when Sysprep is 
running in Factory mode. 

Workaround: Use the Winbom.ini file to modify the Windows
installation when you run the Sysprep -factory command.

-OR-

Use the Sysprep -audit command if you want to modify the Windows
installation manually.

* Changing User Locale Prevents Help From Opening 

If the corporate deployment tools are installed into a localized 
directory, and the User Locale is changed to another language, the 
corporate deployment help files cannot be opened.

Workaround: Change the User Locale to match the language of the 
localized directory.

* Using Sysprep to Install Test Certificates

You can use Sysprep to install Test Certificates to enable the
testing of drivers that are test signed by Windows Hardware Quality
Lab (WHQL) on an operating system image, even if the image has had
Sysprep run against it. See Microsoft Knowledge Base article KB321559
for details.

* Update.exe Requires a Windows Product CD

You cannot run Update.exe within an I386 directory to update a
Windows installation to the latest service pack. You must run 
Update.exe against the entire contents of a Windows product CD. If
the entire contents of a Windows product CD is not present in your
installation share, Update.exe fails to complete the installation
process. 

* Running Sysprep on Upgraded Windows Installations

Microsoft recommends that you run Sysprep only on integrated
("slipstreamed") Windows installations. However, if this is not 
practical,you can run Sysprep.exe on an installation of Windows that
was upgraded to the latest service pack using Update.exe. To do so,
use the following procedure:

1. Install the service pack on the computer that you want to image 
(the master installation) by using the /n option to ensure that the
update cannot be uninstalled.
For example, at the command prompt, type: update /n

2. Restart the computer after the installation of the service pack
completes before performing other actions such as installing 
applications or configuring settings. 

3. Delete the %WINDIR%\platform or C:\platform folder on the master 
computer, where platform equals i386, amd64, or ia64. 
For example, type: rd /s /q %WINDIR%\i386

4. Copy the platform folder of a distribution folder that has been
updated to the same service pack version as the master installation
to the %WINDIR%\platform or c:\platform folder.
For example, type: xcopy \\tech\XP\i386\*.* %WINDIR%\i386\ /cherky 

5. Install any additional applications and perform any further
customizations. At the end of your preinstallation process, you must
use the Sysprep tool to prepare the computer for imaging. 

* RA_AllowUnsolicited RA_MaxTicketExpiry Entries in Unattend.txt 

The RA_AllowUnsolicited and RA_MaxTicketExpiry entries in the
[PCHealth] section of Unattend.txt do not work. To configure these
settings, use Group Policy.

----------------------------

5. DOCUMENTATION CORRECTIONS
----------------------------

* The "Adding Hotfixes to a Windows PE Image" topic instructs you
to extract files from a hotfix. To do so, use the /x option.
For example, to extract the WindowsXP-KB884020-x86-enu.exe hotfix, 
at a command prompt navigate to the directory in which the hotfix 
is located, and then type: WindowsXP-KB884020-x86-enu.exe /x

* In the "Using Sysprep in Factory Mode" topic, the description of 
the search algorithm used by Factory.exe to search for Winbom.ini 
has been updated to include the CD-boot scenario.

  Locating a Winbom.ini File

  Factory.exe searches for a Winbom.ini file in the following 
  locations in consecutive order:

    - The path and file name specified by the registry key 
      HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Factory\Winbom. 

    - The root of all removable media drives that are not
      CD-ROM drives, such as a floppy disk drive. 

    - The root of all CD-ROM drives, or when booting from CD,
      the root of all fixed drives. 

    - The location of Factory.exe, usually the
      %SYSTEMDRIVE%\Sysprep folder. 

    - The root of %SYSTEMDRIVE%. 

    - When booting from CD, the root of all CD-ROM drives.

* The F6 behavior during Setup for loading bootable mass-storage 
drivers has changed for x64 computers. To add mass-storage drivers 
on a floppy disk to x64 computers during Setup by pressing F6, the 
drivers must be in a directory on the floppy disk named A:\AMD64.

* The DefaultThemesOff entry in the [Shell] section of Winbom.ini 
is not supported by the Windows Server 2003 family. 

* The -noreboot command-line option of Sysprep.exe does not modify 
any security ID (SID) registry data.

* In the comments for the DisableVirtualOemDevices entry of the 
“[Unattended] (Unattend.txt)” topic, replace: 

“An example of a virtual OEM device is a RAM disk that has 
mass-storage drivers, related .inf files, and so on.”

with: 

“An example of a virtual OEM device is a flash memory device 
containing mass-storage drivers, related .inf files, and so on.”