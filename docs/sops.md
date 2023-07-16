# What is KSOPS

In order to use sops in ArgoCD, we have to make use of an extensions called KSOPS. KSOPS, or kustomize-SOPS, is a kustomize plugin for managing SOPS encrypted resources. KSOPS is used to decrypt any Kubernetes resources but is most commonly used to decrypt encrypted Kubernetes Secrets and ConfigMaps. The main goal of KSOPS is to manage encrypted resources the same way we manage the Kubernetes manifests.

# Setup

The first step is to install [sops](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age). Sops can be installed via homebrew with `brew install sops`, and age via homebrew with `brew install age`. Then it is necessary to create a public-private key-pair by running `age-keygen -o age.agekey`, which should usually be stored under `~/.sops/age.agekey`.

In the next step, we create a secret in the K8S cluster from the age key in the argocd namespace.

```
cat ~/.sops/age.agekey | kubectl create secret generic sops-age --namespace=argocd --from-file=keys.txt=/dev/stdin
```

To enable Kustomize plugins in ArgoCD, we need to apply the following ConfigMap.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  kustomize.buildOptions: "--enable-alpha-plugins --enable-exec"
```

In addition, it is necessary to patch the ArgoCD repo-server by creating a strategic merge patch by executing `kubectl patch deployment -n argocd argocd-repo-server --patch "$(cat cluster/repo-server-deployment.yaml)"` from the following.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-repo-server
spec:
  template:
    spec:
      volumes:
        - name: custom-tools
          emptyDir: {}
        - name: sops-age
          secret:
            secretName: sops-age
      initContainers:
        - name: install-ksops
          image: viaductoss/ksops:v3.0.2
          command: ["/bin/sh", "-c"]
          args:
            - 'echo "Installing KSOPS..."; cp ksops /custom-tools/; cp $GOPATH/bin/kustomize /custom-tools/; echo "Done.";'
          volumeMounts:
            - mountPath: /custom-tools
              name: custom-tools
      containers:
        - name: argocd-repo-server
          env:
            - name: XDG_CONFIG_HOME
              value: /.config
            - name: SOPS_AGE_KEY_FILE
              value: /.config/sops/age/keys.txt
          volumeMounts:
            - mountPath: /usr/local/bin/kustomize
              name: custom-tools
              subPath: kustomize
            - mountPath: /.config/kustomize/plugin/viaduct.ai/v1/ksops/ksops
              name: custom-tools
              subPath: ksops
            - mountPath: /.config/sops/age/keys.txt
              name: sops-age
              subPath: keys.txt
```

The last step is to apply a secret generator `secret-generator.yaml` that includes all encrypted secrets.

```yaml
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: secret-generator
files:
  - ./secrets.sops.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
generators:
  - ./secret-generator.yaml
```
