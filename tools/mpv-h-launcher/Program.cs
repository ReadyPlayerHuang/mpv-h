using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Windows.Forms;

internal static class Program
{
    private static string QuoteArgument(string value)
    {
        if (value.Length == 0)
        {
            return "\"\"";
        }

        bool needsQuotes = value.Any(char.IsWhiteSpace) || value.Contains('"');
        if (!needsQuotes)
        {
            return value;
        }

        var result = new StringBuilder();
        result.Append('"');
        int backslashes = 0;

        foreach (char ch in value)
        {
            if (ch == '\\')
            {
                backslashes++;
                continue;
            }

            if (ch == '"')
            {
                result.Append('\\', backslashes * 2 + 1);
                result.Append('"');
                backslashes = 0;
                continue;
            }

            result.Append('\\', backslashes);
            backslashes = 0;
            result.Append(ch);
        }

        result.Append('\\', backslashes * 2);
        result.Append('"');
        return result.ToString();
    }

    private static void Fail(string message)
    {
        MessageBox.Show(message, "mpv-h", MessageBoxButtons.OK, MessageBoxIcon.Error);
        Environment.Exit(1);
    }

    [STAThread]
    private static void Main(string[] args)
    {
        string launcherPath = Assembly.GetExecutingAssembly().Location;
        string root = Path.GetDirectoryName(launcherPath);
        if (string.IsNullOrWhiteSpace(root))
        {
            Fail("Cannot determine launcher directory.");
            return;
        }

        string mpvPath = Path.Combine(root, "mpv.exe");
        string vsRoot = Path.Combine(root, "VapourSynth");
        string vsPackage = Path.Combine(vsRoot, "Lib", "site-packages", "vapoursynth");
        string vsCuda = Path.Combine(vsPackage, "plugins", "vsmlrt-cuda");
        string vsscript = Path.Combine(vsPackage, "vsscript.dll");

        if (!File.Exists(mpvPath))
        {
            Fail("mpv.exe was not found next to this launcher:\n" + mpvPath);
        }

        if (!File.Exists(vsscript))
        {
            Fail("VSScript.dll was not found:\n" + vsscript);
        }

        string inheritedPath = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        string localPath = string.Join(Path.PathSeparator.ToString(), new[] { vsRoot, vsPackage, vsCuda, inheritedPath }.Where(p => !string.IsNullOrWhiteSpace(p)));

        var psi = new ProcessStartInfo
        {
            FileName = mpvPath,
            Arguments = string.Join(" ", args.Select(QuoteArgument).ToArray()),
            UseShellExecute = false,
            WorkingDirectory = root,
        };

        psi.EnvironmentVariables["VSSCRIPT_PATH"] = vsscript;
        psi.EnvironmentVariables["PATH"] = localPath;

        try
        {
            Process.Start(psi);
        }
        catch (Exception ex)
        {
            Fail("Failed to start mpv.exe:\n" + ex.Message);
        }
    }
}
