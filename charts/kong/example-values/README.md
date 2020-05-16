# Example values.yaml configurations

The YAML files in this directory provide basic example configurations for
common Kong deployment scenarios on Kubernetes. All examples assume Helm 3
and disable legacy CRD templates (`ingressController.installCRDs: false`;
you must change this value to `true` if you use Helm 2).

* minimal-kong-controller.yaml installs Kong open source with the ingress
  controller in DB-less mode.

* minimal-kong-standalone.yaml installs Kong open source and Postgres with no
  controller.

* minimal-k4k8s-enterprise.yaml installs Kong for Kubernetes Enterprise with
  the ingress controller in DB-less mode.

* minimal-k4k8s-with-kong-enterprise.yaml installs Kong for Kubernetes with
  Kong Enterprise with the ingress controller and PostgreSQL. It does not
  enable Enterprise services (Kong Manager, the Dev Portal, etc.) and does not
  expose the admin API outside the Pod.

* full-k4k8s-with-kong-enterprise.yaml installs Kong for Kubernetes with Kong 
  Enterprise with the ingress controller in PostgreSQL. It enables all Enterprise
  services.

All Enterprise examples require some level of additional user configuration to
install properly. Read the comments at the top of each file for instructions.
