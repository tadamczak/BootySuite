<p align="center">
  <img src="../Assets/readme-header.png" width="100%" alt="Sons of Mukla">
</p>

# BootyProfiler

BootyProfiler is an optional, on-demand World of Warcraft 1.12 addon integrated with **Mukla Officer Suite > Performance**.

Copy the BootyProfiler folder into Interface/AddOns/, beside MuklaOfficerSuite. Restart the game after first installation and enable both addons in the character addon list. Later updates can use reload.

In Performance, choose **Enable**, select **MOS** or **All Addons**, then **Start**. MOS starts the lighter MOS-only capture; All Addons also intercepts frame callbacks. Changing tabs does not change a recording already in progress. **Stop** keeps the report; **Disable** stops recording and removes owned hooks. Opening the page or enabling the module does not start a recording. Reload always starts disabled and stopped.

- **MOS:** selected MOS entry points, count, total/average/maximum measured time, signed global heap deltas and the last 64 calls lasting at least 5 ms.
- **All Addons:** gradual OnEvent/OnUpdate callback discovery, source-addon ranking, top frame/script callbacks and recent slow calls, alongside global Lua heap and sampled FPS/network latency. Self time excludes timed nested intercepted callbacks; inclusive times overlap. These are measured callbacks, not total addon CPU or proof of an FPS-drop cause.
- **Live Monitor:** a movable summary; opening it does not start recording.
- **Export:** after Stop, keep one bounded report in BootyProfiler SavedVariables. Reload or logout writes the report to disk.
- **Refresh memory:** in All Addons, explicitly request native addon memory statistics when supported; up to 256 entries. It never starts a recording.

Discovery is incremental; wait for its status to finish before interpreting coverage. Unknown sources stay unattributed; the frame/script table still identifies their work. Source-addon labels identify the implementation source, including shared libraries, rather than exclusive responsibility for all callees. Some Lua 5.0 closures cannot expose source metadata.

If the client refuses to restore a callback when stopping, BootyProfiler disables its retained wrapper and requires reload before another callback capture. MOS/global recording remains available.

Callback timings prefer available debugprofilestop differences, without resetting its shared counter, and fall back to GetTime. Timing resolution and profiler overhead require native verification; interception itself adds cost. Heap changes remain global and do not establish owned memory or a memory leak. Frames/callback records are capped at 4096, source-addon rows at 256, slow calls at 64, samples at 600; Export retains the 128 highest measured callback self-time records. Partial or truncated coverage is shown explicitly.
