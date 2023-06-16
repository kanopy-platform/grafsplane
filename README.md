# Grafsplane

Library that provides the Crossplane Composite Resource Definition (XRD) for
grafana resources and corresponding go types for programmatically generating
the XRs.

## XRs

ProvisionedDashboard - A Composite Resource managing a grafana dashboard within an org and optionally a specific folder.

The current package expects a grafana.crossplane.io/ProviderConfig named provisioneddashboards.

## XRD Generation

XRDs are defined using go structs and struct markers. The [kanopy-platform/controller-tools](https://github.com/kanopy-platform/controller-tools)
fork provides an xrd plugin used to emit the xrd definition in config. For more details on
the available markers pass the plusin the -w flag or consulte the marker documentation.


## Configfuration Package

Packaging into a [Crossplane Configuration package](https://docs.crossplane.io/latest/concepts/packages/) is done via the [crossplane-package](https://github.com/10gen/kanopy-container-images/tree/main/crossplane-package)
image. All yaml files in the config directory will be included in the configuration package that is published.
The tool currently only supports amd64 arch but the packages and package installer doesn't care about the image
architecture. 
