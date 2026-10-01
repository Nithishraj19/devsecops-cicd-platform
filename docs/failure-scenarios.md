# Pipeline failure scenarios

| Scenario | Detection | Pipeline behavior | Deployment allowed? | Recovery / operator action |
|---|---|---|---|---|
| Unit test failure | node --test nonzero | Stops before static/security stages | No | Inspect test output, fix source, rerun |
| Secret detected | Gitleaks nonzero | Stops and redacts finding output | No | Revoke/rotate real credential, identify exposure, remove safely from code/history, rerun |
| SAST/lint finding | ESLint exits nonzero | Stops before build | No | Review finding, fix or document narrowly justified suppression |
| Dependency vulnerability | npm audit HIGH+ | Stops before image build | No | Upgrade/replace dependency, assess transitive path, rerun tests and audit |
| Critical/high image finding | Trivy HIGH/CRITICAL gate exit | Stops before push | No | Update base/dependencies or document reviewed exception outside this sample policy |
| Docker build failure | Docker build exit | Stops before image scan/push | No | Correct Dockerfile/build context and rerun |
| Registry push failure | docker push exit | Job fails | No new image deployed | Check registry availability/tag/network; retry same immutable build |
| Deployment command failure | Compose pull/up exit | Script tries prior image if present | No | Inspect registry, daemon and Compose logs; verify restored version |
| Health check failure | Repeated /health failure | Script starts prior image and validates it | New release no; old version may resume | Inspect logs/config; if rollback unhealthy, operator intervention |
| Rollback failure | Prior image not available or still unhealthy | Script exits nonzero and reports recovery failure | No | Restore prior artifact, inspect container, manually recover |
| Scanner outage/feed unavailable | Scanner errors/nonzero | Fail-closed by default | No | Restore scanner/feed connectivity; rerun. Do not silently bypass gate |

These are designed behaviors. They are not claims of production incident testing. scripts/test-rollback.sh exercises rollback branching with fake Docker/curl commands. No actual Docker behavior should be inferred from that stub test.
