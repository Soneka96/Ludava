typedef void* HANDLE;
typedef unsigned long DWORD;
typedef long long INT_PTR;
typedef int BOOL;

__declspec(dllimport) HANDLE __stdcall CreateToolhelp32Snapshot(
    DWORD flags, DWORD processId);
__declspec(dllimport) BOOL __stdcall Process32FirstW(
    HANDLE snapshot, void* entry);
__declspec(dllimport) BOOL __stdcall Process32NextW(
    HANDLE snapshot, void* entry);
__declspec(dllimport) BOOL __stdcall CloseHandle(HANDLE handle);
__declspec(dllimport) DWORD __stdcall GetLastError(void);

__declspec(dllexport) HANDLE __cdecl ludavaCreateToolhelp32Snapshot(
    DWORD flags, DWORD processId, DWORD* errorCode) {
  HANDLE snapshot = CreateToolhelp32Snapshot(flags, processId);
  *errorCode = snapshot == (HANDLE)(INT_PTR)-1 || snapshot == 0
      ? GetLastError()
      : 0;
  return snapshot;
}

__declspec(dllexport) BOOL __cdecl ludavaProcess32FirstW(
    HANDLE snapshot, void* entry, DWORD* errorCode) {
  BOOL succeeded = Process32FirstW(snapshot, entry);
  *errorCode = succeeded ? 0 : GetLastError();
  return succeeded;
}

__declspec(dllexport) BOOL __cdecl ludavaProcess32NextW(
    HANDLE snapshot, void* entry, DWORD* errorCode) {
  BOOL succeeded = Process32NextW(snapshot, entry);
  *errorCode = succeeded ? 0 : GetLastError();
  return succeeded;
}

__declspec(dllexport) BOOL __cdecl ludavaCloseHandle(
    HANDLE handle, DWORD* errorCode) {
  BOOL succeeded = CloseHandle(handle);
  *errorCode = succeeded ? 0 : GetLastError();
  return succeeded;
}
