const HEALTH_TIMEOUT_MS = 5000;
const FAILURE_THRESHOLD = 2; // consecutive failures before failover

async function checkHealth(lbIp) {
  try {
    const resp = await fetch(`http://${lbIp}/healthz`, {
      signal: AbortSignal.timeout(HEALTH_TIMEOUT_MS),
      cf: { cacheTtl: 0 },
    });
    return resp.ok;
  } catch {
    return false;
  }
}

export default {
  // Cron trigger — runs every minute, checks cluster health and fails over if needed
  async scheduled(_event, env, _ctx) {
    const clusters = JSON.parse(env.CLUSTERS_JSON);
    const now = Date.now();

    // Check all clusters in parallel
    const healthResults = await Promise.all(
      clusters.map(async (c) => ({
        name: c.name,
        healthy: await checkHealth(c.lb_ip),
      }))
    );

    // Update per-cluster failure counters and health flags
    for (const { name, healthy } of healthResults) {
      await env.STATE.put(`health_${name}`, healthy ? "1" : "0");
      if (healthy) {
        await env.STATE.put(`failures_${name}`, "0");
      } else {
        const prev = parseInt((await env.STATE.get(`failures_${name}`)) || "0");
        await env.STATE.put(`failures_${name}`, String(prev + 1));
      }
    }

    await env.STATE.put("last_check", String(now));

    // Failover logic
    let primary = await env.STATE.get("primary");
    if (!primary) {
      // Bootstrap — set first cluster as primary
      primary = clusters[0].name;
      await env.STATE.put("primary", primary);
      return;
    }

    const primaryFailures = parseInt(
      (await env.STATE.get(`failures_${primary}`)) || "0"
    );

    if (primaryFailures >= FAILURE_THRESHOLD) {
      // Find the first healthy cluster that isn't the current primary
      const target = clusters.find((c) => {
        const failures = parseInt(0); // we check health result directly
        const result = healthResults.find((r) => r.name === c.name);
        return result?.healthy && c.name !== primary;
      });

      if (target) {
        await env.STATE.put("primary", target.name);
        await env.STATE.put("failover_at", String(now));
        await env.STATE.put("failover_from", primary);
      }
    }
  },

  // HTTP handler — status.dieu.dev status API
  async fetch(_request, env, _ctx) {
    const clusters = JSON.parse(env.CLUSTERS_JSON);
    const primary = (await env.STATE.get("primary")) || "unknown";
    const lastCheck = await env.STATE.get("last_check");
    const failoverAt = await env.STATE.get("failover_at");
    const failoverFrom = await env.STATE.get("failover_from");

    const health = {};
    for (const c of clusters) {
      health[c.name] = (await env.STATE.get(`health_${c.name}`)) === "1";
    }

    const primaryCluster = clusters.find((c) => c.name === primary);

    return Response.json(
      {
        primary,
        primary_lb_ip: primaryCluster?.lb_ip ?? null,
        clusters: clusters.map((c) => ({
          name: c.name,
          lb_ip: c.lb_ip,
          healthy: health[c.name] ?? null,
        })),
        last_check_ms: lastCheck ? parseInt(lastCheck) : null,
        last_failover:
          failoverAt
            ? { at_ms: parseInt(failoverAt), from: failoverFrom }
            : null,
      },
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Cache-Control": "no-store",
        },
      }
    );
  },
};
