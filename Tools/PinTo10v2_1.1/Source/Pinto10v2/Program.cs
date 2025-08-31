using System;
//using System.Collections.Generic;
using System.IO;
//using System.Linq;
//using Shell32;
//using IWshRuntimeLibrary;
//using System.Threading;

namespace PinTo10v2
{
    class Program
    {
        
        static readonly string help = "\n\r" + "PinTo10v2 Version 1.1" + "\n\r" + "\n\r" + "This command line tool pins files to the Windows 7 & 10 Taskbar and Start Menu" + "\n\r" + "\n\r" +
            "Please note that pinning a shortcut that already exists in the Start Menu folder" + "\r\n" + "structure to the Start Menu is quicker than pinning a file with no existing" + "\r\n" + "Start Menu shortcut." +
            "\n\r" + "\n\r" + "Syntax: PinTo10v2 [/pintb | /unpintb | /pinsm | /unpinsm] " + "'filename'" + "\n\r" + "\n\r" + "pintb   = Pin to the Task Bar" + "\n\r" +
            "unpintb = Unpin from the Task Bar" + "\n\r" + "pinsm   = Pin to the Start Menu" + "\n\r" + "unpinsm = Unpin from the Start Menu";
        static int Main(string[] args)
        {

            bool pin = true;
            bool taskbar = false;
            bool startmenu = false;
            bool dosomework = false;
            bool needtomakeshortcut = false;
            string fileName = "";
            string osversionfromreg = Microsoft.Win32.Registry.GetValue(@"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion", "ProductName", "nullvalue").ToString();
            string win10 = "Windows 10";
            string win7 = "Windows 7";
            bool iswin10 = osversionfromreg.Contains(win10);
            bool iswin7 = osversionfromreg.Contains(win7);
            var actionIndex = pin ? 51201 : 51394;

            if (args.Length < 1)
            {
                Console.WriteLine(help);
                Environment.Exit(0);
            }

            if (args.Length >= 1)
            {
                if (args[0].ToLower() == "/?")
                {
                    Console.WriteLine(help);
                    Environment.Exit(0);
                }
            }

            if (args.Length >= 1)
            {
                if (args[0].ToLower() == "-help")
                {
                    Console.WriteLine(help);
                    Environment.Exit(0);
                }
            }
            
            if (iswin10)
            {
                actionIndex = pin ? 51201 : 51394;
            }
            if (iswin7)
            {
                actionIndex = pin ? 5381 : 5382;
            }
            if (!iswin10)
            {
                if (!iswin7)
                {
                    Console.WriteLine("\n\r" + "I only work on windows 7 & 10 - Exiting...");
                    Environment.Exit(0);
                }
            }

            if (args.Length >= 2)
            {
                if (args[0].ToLower() == "/pintb")
                {
                    pin = true;
                    taskbar = true;
                    dosomework = true;
                }
                else if (args[0].ToLower() == "/unpintb")
                {
                    pin = false;
                    taskbar = true;
                    dosomework = true;
                }
                if (args[0].ToLower() == "/pinsm")
                {
                    pin = true;
                    startmenu = true;
                    dosomework = true;
                }
                else if (args[0].ToLower() == "/unpinsm")
                {
                    pin = false;
                    startmenu = true;
                    dosomework = true;
                }
                else
                {
                    if (dosomework == false)
                    {
                        Console.WriteLine(help);
                        Environment.Exit(0);
                    }
                }
                fileName = args[1];
            }

            if (!System.IO.File.Exists(fileName))
            {
                Console.WriteLine("\n\r" + "Specified file not found.  Exiting...");
                Environment.Exit(1);
            }

            string pathtofile = Path.GetDirectoryName(fileName);
            string wholefileName = Path.GetFileName(fileName);
            string extension = Path.GetExtension(wholefileName);
            string filenamenoextension = Path.GetFileNameWithoutExtension(wholefileName);
            bool success = true;

            // Check that the verb exists on the file specified before continuing ////////////////////////////////////////////////
            if (!startmenu) Utils.ChangeImagePathName("explorer.exe");
            success = Utils.CheckifVerbExists(fileName, pin, startmenu);
            if (!success)
            {
                Console.WriteLine("\n\r" + "Can't find the pin / unpin verb on the file specified.  Exiting...");
                Environment.Exit(1);
            }
            if (success)
            {
                //Console.WriteLine("Verb found on the file specified.  Continuing...");
            }
            // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            if (startmenu == true)
            {
                if (extension == ".lnk")
                {
                    // Search for files in Start Menu //
                    string allusersprofile = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData).ToString();
                    string[] searchalluserstart = Directory.GetFiles(allusersprofile + @"\Microsoft\Windows\Start Menu", wholefileName, SearchOption.AllDirectories);
                    string appdata = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                    string currentuserstart = appdata + @"\Microsoft\Windows\Start Menu\Programs";
                    string[] searchcurrentuserstart = Directory.GetFiles(currentuserstart, wholefileName, SearchOption.AllDirectories);
                    if (searchalluserstart.Length == 0)
                    {
                        //Console.WriteLine("Not found in all users start");
                        if (searchcurrentuserstart.Length == 0)
                        {
                            needtomakeshortcut = false;
                            //Console.WriteLine("Not found in current user's start");
                            System.IO.File.Copy(args[1], appdata + @"\Microsoft\Windows\Start Menu\Programs\" + wholefileName, true);
                            if (!System.IO.File.Exists(appdata + @"\Microsoft\Windows\Start Menu\Programs\" + wholefileName))
                            {
                                Console.WriteLine("\n\r" + "Shortcut not copied to Start Menu.  Exiting...");
                                Environment.Exit(1);
                            }
                        }
                    }
                }
                if (extension != ".lnk")
                {
                        // Search for files in Start Menu //
                        string allusersprofile = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData).ToString();
                        string[] searchalluserstart = Directory.GetFiles(allusersprofile + @"\Microsoft\Windows\Start Menu\Programs", filenamenoextension + @".lnk", SearchOption.AllDirectories);
                        string appdata = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                        string currentuserstart = appdata + @"\Microsoft\Windows\Start Menu\Programs";
                        string[] searchcurrentuserstart = Directory.GetFiles(currentuserstart, filenamenoextension + @".lnk", SearchOption.AllDirectories); //search for equivalent .lnk file in the Start Menu
                        if (searchalluserstart.Length == 0)
                        {
                            if (searchcurrentuserstart.Length == 0)
                            {
                                needtomakeshortcut = true;
                            }
                        }
                }
            }
            
            try
            {
                if (taskbar)
                { 
                    Utils.ChangeImagePathName("explorer.exe");
                    success = Utils.PinUnpinTaskbar(fileName, pin);
                    if (success) Utils.RestoreImagePathName();
                }
                if (startmenu)
                {
                    if (extension == ".lnk")
                    {
                        Utils.PinUnpinStart(fileName, pin);
                    }
                    if (extension != ".lnk")
                    {
                        if (pin) // only create shortcut if pinning and not unpinning
                        {
                            if (needtomakeshortcut)
                            {
                                Utils.CreateShortcut(args[1]);
                            }
                        }
                        Utils.PinUnpinStart(fileName, pin);
                    }
                }
            }
            finally
            {
            }
            //Console.WriteLine(success ? "OK" : "Failed");
            return success ? 0 : 1;
        }        
    }
}