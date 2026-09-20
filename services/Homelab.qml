pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

Singleton {
  id: root

  // Liveness, not auth: any HTTP status (307/401 included) means the
  // target answered; only a timeout or DNS failure is DOWN. Read-only:
  // no secrets, no mutations, no notifications.
  readonly property bool enabled: GlobalConfig.dashboard.homelab.enabled
  readonly property var targets: GlobalConfig.dashboard.homelab.targets.values
  property var batchTargets: []
  property var status: targets.map(() => ({ up: false, ms: 0, checked: false }))
  property int lineIndex

  function refresh(): void {
    if (!enabled || probe.running)
      return;

    lineIndex = 0;
    batchTargets = [];
    status = targets.map((target, index) => {
      const valid = /^https?:\/\//.test(target.url);
      if (valid)
        batchTargets.push({ index: index, url: target.url });
      return { up: false, ms: 0, checked: !valid };
    });
    if (batchTargets.length)
      probe.running = true;
  }

  onEnabledChanged: {
    if (!enabled && probe.running)
      probe.running = false;
    if (enabled)
      refresh();
  }

  onTargetsChanged: {
    if (probe.running)
      probe.running = false;
    refresh();
  }

  Timer {
    interval: 30000
    running: root.enabled
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // One curl, sequential URLs: probes never overlap and each stays
  // bounded by --max-time, so a dead target cannot stall the rest.
  Process {
    id: probe

    command: {
      const args = ["curl", "--disable", "--globoff", "--proto", "=http,https",
                    "--connect-timeout", "3", "--max-time", "5", "-sS",
                    "-w", "%{http_code} %{time_total}\\n"];
      for (let i = 0; i < root.batchTargets.length; ++i)
        args.push("-o", "/dev/null", "--url", root.batchTargets[i].url);
      return args;
    }
    stdout: SplitParser {
      onRead: data => { // qmllint disable signal-handler-parameters
        const target = root.batchTargets[root.lineIndex];
        if (!target)
          return;
        const [code, seconds] = data.trim().split(" ");
        const ms = Math.round(Number(seconds) * 1000);
        root.status[target.index] = {
          up: /^\d{3}$/.test(code) && code !== "000" && Number.isFinite(ms),
          ms: Number.isFinite(ms) ? ms : 0,
          checked: true
        };
        root.statusChanged();
        root.lineIndex++;
      }
    }
  }
}
