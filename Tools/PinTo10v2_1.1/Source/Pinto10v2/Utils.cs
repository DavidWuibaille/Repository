using System;
//using System.Collections.Generic;
using System.IO;
//using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
//using Shell32;
using IWshRuntimeLibrary;
//using System.Threading.Tasks;

namespace PinTo10v2
{
    static public class Utils
    {

        // /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        static string originalImagePathName;
        static int unicodeSize = IntPtr.Size * 2;

        static void GetPointers(out IntPtr imageOffset, out IntPtr imageBuffer)
        {
            IntPtr pebBaseAddress = GetBasicInformation().PebBaseAddress;
            var processParameters = Marshal.ReadIntPtr(pebBaseAddress, 4 * IntPtr.Size);
            imageOffset = processParameters.Increment(4 * 4 + 5 * IntPtr.Size + unicodeSize + IntPtr.Size + unicodeSize);
            imageBuffer = Marshal.ReadIntPtr(imageOffset, IntPtr.Size);
        }

        internal static void ChangeImagePathName(string newFileName)
        {
            IntPtr imageOffset, imageBuffer;
            GetPointers(out imageOffset, out imageBuffer);

            //Read original data
            var imageLen = Marshal.ReadInt16(imageOffset);
            originalImagePathName = Marshal.PtrToStringUni(imageBuffer, imageLen / 2);

            var newImagePathName = Path.Combine(Path.GetDirectoryName(originalImagePathName), newFileName);
            if (newImagePathName.Length > originalImagePathName.Length) throw new Exception("new ImagePathName cannot be longer than the original one");

            //Write the string, char by char
            var ptr = imageBuffer;
            foreach (var unicodeChar in newImagePathName)
            {
                Marshal.WriteInt16(ptr, unicodeChar);
                ptr = ptr.Increment(2);
            }
            Marshal.WriteInt16(ptr, 0);

            //Write the new length
            Marshal.WriteInt16(imageOffset, (short)(newImagePathName.Length * 2));
        }

        internal static void RestoreImagePathName()
        {
            IntPtr imageOffset, ptr;
            GetPointers(out imageOffset, out ptr);

            foreach (var unicodeChar in originalImagePathName)
            {
                Marshal.WriteInt16(ptr, unicodeChar);
                ptr = ptr.Increment(2);
            }
            Marshal.WriteInt16(ptr, 0);
            Marshal.WriteInt16(imageOffset, (short)(originalImagePathName.Length * 2));
        }

        public static ProcessBasicInformation GetBasicInformation()
        {
            uint status;
            ProcessBasicInformation pbi;
            int retLen;
            var handle = System.Diagnostics.Process.GetCurrentProcess().Handle;
            if ((status = NtQueryInformationProcess(handle, 0,
                out pbi, Marshal.SizeOf(typeof(ProcessBasicInformation)), out retLen)) >= 0xc0000000)
                throw new Exception("Windows exception. status=" + status);
            return pbi;
        }

        [DllImport("ntdll.dll")]
        public static extern uint NtQueryInformationProcess(
            [In] IntPtr ProcessHandle,
            [In] int ProcessInformationClass,
            [Out] out ProcessBasicInformation ProcessInformation,
            [In] int ProcessInformationLength,
            [Out] [Optional] out int ReturnLength
            );

        public static IntPtr Increment(this IntPtr ptr, int value)
        {
            unchecked
            {
                if (IntPtr.Size == sizeof(Int32))
                    return new IntPtr(ptr.ToInt32() + value);
                else
                    return new IntPtr(ptr.ToInt64() + value);
            }
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct ProcessBasicInformation
        {
            public uint ExitStatus;
            public IntPtr PebBaseAddress;
            public IntPtr AffinityMask;
            public int BasePriority;
            public IntPtr UniqueProcessId;
            public IntPtr InheritedFromUniqueProcessId;
        }

        // /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true, BestFitMapping = false, ThrowOnUnmappableChar = true)]
        internal static extern IntPtr LoadLibrary(string lpLibFileName);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true, BestFitMapping = false, ThrowOnUnmappableChar = true)]
        internal static extern int LoadString(IntPtr hInstance, uint wID, StringBuilder lpBuffer, int nBufferMax);

        // //////////////////////////////////////////////////////////////////////

        public static void CreateShortcut(string targetFileLocation)
        {
            string currentuserstart = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + @"\Microsoft\Windows\Start Menu\Programs";
            string wholefileName = Path.GetFileName(targetFileLocation);
            string extension = Path.GetExtension(wholefileName);
            string filenamenoextension = Path.GetFileNameWithoutExtension(wholefileName);
            string DirectoryName = Path.GetDirectoryName(targetFileLocation);

            string shortcutLocation = currentuserstart + @"\" + filenamenoextension + ".lnk"; //System.IO.Path.Combine(Environment.SpecialFolder.StartMenu.ToString(), "Dummy.lnk");
            WshShell shell = new WshShell();
            IWshShortcut shortcut = (IWshShortcut)shell.CreateShortcut(shortcutLocation);

            //shortcut.Description = ""; // The description of the shortcut
            shortcut.WorkingDirectory = DirectoryName; // The "Start in" path of the new shortcut
            shortcut.TargetPath = targetFileLocation; // The path of the file that will launch when the shortcut is run
            shortcut.Save(); // Save the shortcut
        }

        public static bool PinUnpinTaskbar(string filePath, bool pin)
        {
            if (!System.IO.File.Exists(filePath))
            {
                Console.WriteLine("\n\r" + "Specified file not found.  Exiting...");
                Environment.Exit(1);
            };
            //throw new FileNotFoundException(filePath);
            int MAX_PATH = 255;
            var actionIndex = pin ? 5386 : 5387; // 5386 is the DLL index for"Pin to Tas&kbar", ref. http://www.win7dll.info/shell32_dll.html
            StringBuilder szPinToStartLocalized = new StringBuilder(MAX_PATH);
            IntPtr hShell32 = LoadLibrary("Shell32.dll");
            LoadString(hShell32, (uint)actionIndex, szPinToStartLocalized, MAX_PATH);
            string localizedVerb = szPinToStartLocalized.ToString();
            string path = Path.GetDirectoryName(filePath);
            string fileName = Path.GetFileName(filePath);
            // create the shell application object
            dynamic shellApplication = Activator.CreateInstance(Type.GetTypeFromProgID("Shell.Application"));
            dynamic directory = shellApplication.NameSpace(path);
            dynamic link = directory.ParseName(fileName);
            dynamic verbs = link.Verbs();
            for (int i = 0; i < verbs.Count(); i++)
            {
                dynamic verb = verbs.Item(i);
                var name = verb.Name;
                //Console.WriteLine("Verb Name = " + name);
                if (verb.Name.Equals(localizedVerb))
                {
                    //Console.WriteLine("Trying to do it...");
                    verb.DoIt();
                    return true;
                }
            }
            return false;
        }

        // //////////////////////////////////////////////////////////////////////
        public static bool PinUnpinStart(string filePath, bool pin)
        {
            //Console.WriteLine("Pinning to Start...");
            if (!System.IO.File.Exists(filePath)) throw new FileNotFoundException(filePath);
            int MAX_PATH = 255;
            StringBuilder szPinToStartLocalized = new StringBuilder(MAX_PATH);
            StringBuilder szInvPinToStartLocalized = new StringBuilder(MAX_PATH);
            IntPtr hShell32 = LoadLibrary("Shell32.dll");
            string osversionfromreg = Microsoft.Win32.Registry.GetValue(@"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion", "ProductName", "nullvalue").ToString();
            string win10 = "Windows 10";
            string win7 = "Windows 7";
            bool iswin10 = osversionfromreg.Contains(win10);
            bool iswin7 = osversionfromreg.Contains(win7);
            var actionIndex = pin ? 51201 : 51394;
            var invActionIndex = pin ? 51394 : 51201;
            if (iswin10)
            {
                actionIndex = pin ? 51201 : 51394;
                invActionIndex = pin ? 51394 : 51201;
            }
            if (iswin7)
            {
                actionIndex = pin ? 5381 : 5382;
                invActionIndex = pin ? 5382 : 5381;
            }
            LoadString(hShell32, (uint)actionIndex, szPinToStartLocalized, MAX_PATH);
            string localizedVerb = szPinToStartLocalized.ToString();

            LoadString(hShell32, (uint)invActionIndex, szInvPinToStartLocalized, MAX_PATH);
            string invLocalizedVerb = szInvPinToStartLocalized.ToString();

            string path = Path.GetDirectoryName(filePath);
            string fileName = Path.GetFileName(filePath);

            // create the shell application object
            dynamic shellApplication = Activator.CreateInstance(Type.GetTypeFromProgID("Shell.Application"));
            dynamic directory = shellApplication.NameSpace(path);
            dynamic link = directory.ParseName(fileName);

            dynamic verbs = link.Verbs();

            int counter = 0;

            while (1 == 1) // setup a loop to keep trying to pin to start - will try 20 times at 500ms interval and then fail if not successful
            {
                shellApplication = Activator.CreateInstance(Type.GetTypeFromProgID("Shell.Application"));
                directory = shellApplication.NameSpace(path);
                link = directory.ParseName(fileName);

                verbs = link.Verbs();

                for (int i = 0; i < verbs.Count(); i++)
                {
                    dynamic verb = verbs.Item(i);
                    if (verb.Name.Equals(localizedVerb))
                    {
                        verb.DoIt();
                        System.Threading.Thread.Sleep(500);
                        counter = counter = + 1;
                    }
                    if (verb.Name.Equals(invLocalizedVerb)) // check for the existance of the opposite verb to confirm if it's been successful
                    {
                        //Console.WriteLine("I think it's done!  Exiting...");
                        return true;
                    }
                    if (counter == 20) // Try 20 times (10 seconds) and then fail...
                    {
                        return false;
                    }
                }
            }
        }
        public static bool CheckifVerbExists(string filePath, bool pin, bool startmenu)
        {
            //Console.WriteLine("Pinning to Start...");
            if (!System.IO.File.Exists(filePath)) throw new FileNotFoundException(filePath);
            int MAX_PATH = 255;
            StringBuilder szPinToStartLocalized = new StringBuilder(MAX_PATH);
            StringBuilder szInvPinToStartLocalized = new StringBuilder(MAX_PATH);
            IntPtr hShell32 = LoadLibrary("Shell32.dll");
            string osversionfromreg = Microsoft.Win32.Registry.GetValue(@"HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion", "ProductName", "nullvalue").ToString();
            string win10 = "Windows 10";
            string win7 = "Windows 7";
            bool iswin10 = osversionfromreg.Contains(win10);
            bool iswin7 = osversionfromreg.Contains(win7);
            var actionIndex = pin ? 51201 : 51394;
            var invActionIndex = pin ? 51394 : 51201;

            if (iswin10)
            {
                if (startmenu)
                {
                    actionIndex = pin ? 51201 : 51394;
                }
                if (!startmenu)
                {
                    actionIndex = pin ? 5386 : 5387;
                }
            }
            if (iswin7)
            {
                if (startmenu)
                {
                    actionIndex = pin ? 5381 : 5382;
                }
                if (!startmenu)
                {
                    actionIndex = pin ? 5386 : 5387;
                }
            }
            LoadString(hShell32, (uint)actionIndex, szPinToStartLocalized, MAX_PATH);
            string localizedVerb = szPinToStartLocalized.ToString();

            string path = Path.GetDirectoryName(filePath);
            string fileName = Path.GetFileName(filePath);

            // create the shell application object
            dynamic shellApplication = Activator.CreateInstance(Type.GetTypeFromProgID("Shell.Application"));
            dynamic directory = shellApplication.NameSpace(path);
            dynamic link = directory.ParseName(fileName);

            dynamic verbs = link.Verbs();

                for (int i = 0; i < verbs.Count(); i++)
                {
                    dynamic verb = verbs.Item(i);
                    var name = verb.Name;
                    //Console.WriteLine("Verb name = " + name);
                    if (verb.Name.Equals(localizedVerb))
                    {
                        // verb.DoIt();
                        return true;
                    }
                }
            return false;
        }
    }
}