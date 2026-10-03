<p align="center">
  <img src="../Assets/readme-header.png" width="100%" alt="Sons of Mukla">
</p>

# BootyProfiler

BootyProfiler is an optional, on-demand World of Warcraft 1.12 addon integrated with **Mukla Officer Suite > Performance**.

Copy the BootyProfiler folder into Interface/AddOns/, beside MuklaOfficerSuite. Restart the game after first installation and enable both addons in the character addon list. Later updates can use reload.

In Performance, choose **Enable**, select **MOS** or **All Addons**, then **Start**. MOS starts the lighter MOS-only capture; All Addons also intercepts frame callbacks. Changing tabs does not change a recording already in progress. **Stop** keeps the report; **Disable** stops recording and removes owned hooks. Opening the page or enabling the module does not start a recording. Regular profiling always starts disabled and stopped after reload; the separately armed login capture runs once.

- **MOS:** selected MOS entry points, count, total/average/maximum measured time, signed global heap deltas and the last 64 calls lasting at least 5 ms.
- **All Addons:** gradual OnEvent/OnUpdate callback discovery, source-addon ranking, expandable frame families and recent slow calls, alongside shared Lua memory and sampled FPS/network latency. Family and child lists have pages of 50 records. Self time excludes timed nested intercepted callbacks; inclusive times overlap. These are measured callbacks, not total addon CPU or proof of an FPS-drop cause.
- **Live Monitor:** integer FPS, shared Lua memory, change since Start and GC indicators in a movable summary; opening it does not start recording.
- **Export:** after Stop, keep one bounded report in BootyProfiler SavedVariables. Reload or logout writes the report to disk.
- **Refresh memory:** in All Addons, explicitly request native addon memory statistics when supported; up to 256 entries. It never starts a recording.
- **Memory: ON:** before Start in All Addons, enable before/after callback memory readings. Expand **Memory by addon** for growth grouped by identified source, or choose **View: Memory** for frame families. Heap growth accumulates positive shared-memory changes; Net heap delta includes decreases and Peak growth shows the largest positive reading. These values help locate allocation activity, not retained addon-owned RAM. Nested readings overlap and measurement adds overhead. The option stays off by default.
- **Analyze next login:** arm one capture, then reload or restart. **Login memory analysis** records loading stages and the first five seconds in the world, then stops automatically. It starts at BootyProfiler load; earlier addons are already in the baseline. Rows show shared memory changes between stages, not exclusive memory allocated by the named addon. The latest bounded report is saved automatically; clicking the armed button again cancels the pending request.

Expand a report accordion to inspect its table. **Frame callbacks** is the main All Addons ranking. During recording, counters update live while displayed rows stay in place. **Refresh tables** updates row selection/order; **Stop** shows final rankings. Technical details groups timing, coverage, source identification and client support.

**Memory and garbage collection** shows current shared Lua memory, its change since Start and the reported GC threshold. Expand **Heap drop windows** to compare observed memory decreases with the worst frame gap in each interval, or **Slow frame gaps** to inspect gaps of at least 50 ms. These are observations, not exact GC event counts, pause durations or proof of the cause of a stall. Hover a measurement column heading for its meaning.

Discovery is incremental; wait for its status to finish before interpreting coverage. XML callback labels omit their addon file and some functions expose no source, so owners can remain Unknown. Frame names or observed parent/reference context identify their work without proving an addon owner. Source-addon labels identify the implementation source, including shared libraries, rather than exclusive responsibility for all callees. Callback growth remains measurable without native per-addon memory APIs; it does not substitute for an owned-memory snapshot.

If the client refuses to restore a callback when stopping, BootyProfiler disables its retained wrapper and requires reload before another callback capture. MOS/global recording remains available.

Callback timings prefer available debugprofilestop differences, without resetting its shared counter, and fall back to GetTime. Timing resolution and profiler overhead require native verification; interception itself adds cost. Heap changes remain global and do not establish owned memory or a memory leak. Retained frames with callbacks and callback records are capped at 4096; inert frames do not consume frame capacity. Source-addon rows are capped at 256, slow calls at 64, samples at 600 and login stages at 256 with pages of 50. Export retains the 128 highest callback records by heap growth when memory capture was enabled, otherwise by self time. Partial or truncated coverage is shown explicitly.
