package v1beta1

import (
	"reflect"

	"k8s.io/apimachinery/pkg/runtime/schema"
	"sigs.k8s.io/controller-runtime/pkg/scheme"
)

const (
	Group   = "grafana.kanopy-platform.github.io"
	Version = "v1beta1"
)

var (
	SchemeGroupVersion = schema.GroupVersion{Group: Group, Version: Version}
	SchemeBuilder      = &scheme.Builder{GroupVersion: SchemeGroupVersion}
	AddToScheme        = SchemeBuilder.AddToScheme
)

// ProvisionedDashboard type metadata

var (
	ProvisionedDashboardKind             = reflect.TypeOf(ProvisionedDashboard{}).Name()
	ProvisionedDashboardGroupKind        = schema.GroupKind{Group: Group, Kind: ProvisionedDashboardKind}.String()
	ProvisionedDashboardKindAPIVersion   = ProvisionedDashboardKind + "." + SchemeGroupVersion.String()
	ProvisionedDashboardGroupVersionKind = SchemeGroupVersion.WithKind(ProvisionedDashboardKind)
)

func init() {
	SchemeBuilder.Register(&ProvisionedDashboard{}, &ProvisionedDashboardList{})
}
