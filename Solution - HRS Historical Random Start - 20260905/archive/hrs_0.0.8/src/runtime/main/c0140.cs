using System;
using System.IO;
using System.Text;

namespace main
{
    internal sealed class AtomicResultWriter
    {
        private static readonly UTF8Encoding StrictUtf8 = new UTF8Encoding(false, true);
        private readonly OwnedBridgePaths paths;
        private readonly object sync = new object();

        internal AtomicResultWriter(OwnedBridgePaths paths)
        {
            this.paths = paths;
        }

        internal bool TryWrite(ResultV1 result)
        {
            lock (sync)
            {
                return TryWriteCore(result);
            }
        }

        private bool TryWriteCore(ResultV1 result)
        {
            string temporary = null;
            string backup = null;
            FileStream stream = null;
            bool destinationExisted = false;
            try
            {
                if (result == null || !paths.RevalidateForResultWrite()) return false;

                string json = ResultContract.Serialize(result);
                byte[] bytes = StrictUtf8.GetBytes(json);
                if (bytes.Length < 1 || bytes.Length > PolicyV1Codec.MaximumBytes)
                    return false;

                string operationId = Guid.NewGuid().ToString("N");
                temporary = Path.Combine(paths.BridgeRoot,
                    ".result.v1.json." + operationId + ".tmp");
                backup = Path.Combine(paths.BridgeRoot,
                    ".result.v1.json." + operationId + ".rollback");
                destinationExisted = File.Exists(paths.ResultPath);

                stream = new FileStream(temporary, FileMode.CreateNew,
                    FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough);
                stream.Write(bytes, 0, bytes.Length);
                stream.Flush();
                stream.Dispose();
                stream = null;

                if (destinationExisted)
                    File.Replace(temporary, paths.ResultPath, backup, true);
                else
                    File.Move(temporary, paths.ResultPath);

                byte[] readback = File.ReadAllBytes(paths.ResultPath);
                if (!BytesEqual(bytes, readback)) throw new IOException("Result readback mismatch.");
                if (File.Exists(backup)) File.Delete(backup);
                return true;
            }
            catch
            {
                if (stream != null)
                {
                    try { stream.Dispose(); } catch { }
                }
                try
                {
                    if (!string.IsNullOrEmpty(backup) && File.Exists(backup))
                    {
                        if (File.Exists(paths.ResultPath)) File.Delete(paths.ResultPath);
                        File.Move(backup, paths.ResultPath);
                    }
                    else if (!destinationExisted && File.Exists(paths.ResultPath))
                    {
                        File.Delete(paths.ResultPath);
                    }
                }
                catch { }
                return false;
            }
            finally
            {
                try
                {
                    if (!string.IsNullOrEmpty(temporary) && File.Exists(temporary))
                        File.Delete(temporary);
                }
                catch { }
            }
        }

        private static bool BytesEqual(byte[] left, byte[] right)
        {
            if (left == null || right == null || left.Length != right.Length) return false;
            int difference = 0;
            for (int i = 0; i < left.Length; i++) difference |= left[i] ^ right[i];
            return difference == 0;
        }
    }
}
