<p align="center">
  <img src="../Assets/readme-header.png" width="100%" alt="Sons of Mukla">
</p>

# BootyProfiler

BootyProfiler is an optional, on-demand World of Warcraft 1.12 addon integrated with **Mukla Officer Suite > Performance**.

Copy the BootyProfiler folder into Interface/AddOns/, beside MuklaOfficerSuite. Restart the game after first installation and enable both addons in the character addon list. Later updates can use reload.

In Performance, choose **Enable**, then **Start**. **Stop** keeps the report; **Disable** stops recording. Opening the page or enabling the module does not start a recording. Reload always starts disabled and stopped.

- **MOS:** selected MOS entry points, count, total/average/maximum measured time, signed global heap deltas and the last 64 calls lasting at least 5 ms.
- **All Addons:** global Lua heap and sampled FPS/network latency. Profiling other addons' callbacks is planned for package 2. Samples are not per-frame timings or proof of the cause of a drop.
- **Live Monitor:** a movable summary; opening it does not start recording.
- **Export:** after Stop, keep one bounded report in BootyProfiler SavedVariables. Reload or logout writes the report to disk.
- **Refresh memory:** in All Addons, explicitly request native addon memory statistics when supported; up to 256 entries. It never starts a recording.

Only selected MOS operations are timed. Heap changes are global and do not establish memory owned by an addon or a memory leak. The current clock is GetTime; its resolution and profiler overhead require verification on your client.
