# External inference + computer-use learning loop

A third-party model does not need PMCR-O tools or an API. A registered computer-use adapter may open its UI, submit a bounded prompt, and capture the response. `model-gateway-agent` normalizes that response into provider-neutral evidence and may bridge it to a loopback Aspire/orchestration API. The external model is a reasoning coprocessor, not an authority source.

The reusable flywheel is:

`trail -> procedure candidate -> replay -> normalized model response -> local orchestration -> CHECK -> eval score -> procedure promotion`

Five successful distinct trails are the default minimum promotion corpus. Five trails alone do not earn promotion: safety, replayability, outcome evidence, and score thresholds must also PASS. This is operational learning (procedures, routing, prompts, policies, score history), not a claim that foundation-model weights were trained.
