# Cloudflare Tunnel

The [cloudflare tunnel](https://developers.cloudflare.com/cloudflare-one/tutorials/many-cfd-one-tunnel/) can be used to securely proxy traffic into your K8S cluster.

# Pre-requisite

As a pre-requisite it is first necessary to have a valid domain which is registered at cloudflare. Free domains can be obtained from [Freenom](https://www.freenom.com/de/freeandpaiddomains.html). The second thing that is necessary is an application called cloudflared. To install cloudflared just run `brew install cloudflared`.

# Setup

Once installed, you can use the `tunnel login` command in cloudflared to obtain a certificate.

```
cloudflared tunnel login
```

Create a new tunnel by running the following.

```
cloudflared tunnel create homelab
```

Next, you will upload the generated Tunnel credential file as a secret to your Kubernetes cluster. You will also need to provide the filepath that the Tunnel credentials file was created under. You can find that path in the output of `cloudflared tunnel create homelab` above such as `/Users/kevinhertwig/.cloudflared/2ff1e3d0-f4d2-41b8-8a9a-0e5bab2d4295.json`.

```
kubectl -n cloudflare create secret generic tunnel-credentials --from-file=credentials.json=/Users/kevinhertwig/.cloudflared/2ff1e3d0-f4d2-41b8-8a9a-0e5bab2d4295.json
```

Now you associate your tunnel with a DNS record.

```
cloudflared tunnel route dns homelab argocd.amrap030-homelab.ml
```

Now, we’ll deploy cloudflared by applying its manifest. This will start a Deployment for running cloudflared and a ConfigMap with cloudflared’s config. When Cloudflare receives traffic for the DNS or Load Balancing hostname you configured in the previous step, it will send that traffic to the cloudflared instances running in this deployment. Then, those cloudflared instances will proxy the request to your application’s Service.

```
kubectl apply -f tunnel.yaml
```

The content of `tunnel.yaml` is the following.

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: cloudflare
spec:
  selector:
    matchLabels:
      app: cloudflared
  replicas: 1
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
        - name: cloudflared
          image: cloudflare/cloudflared:latest
          args:
            - tunnel
            - --config
            - /etc/cloudflared/config/config.yaml
            - run
          volumeMounts:
            - name: config
              mountPath: /etc/cloudflared/config
              readOnly: true
            - name: creds
              mountPath: /etc/cloudflared/creds
              readOnly: true
          livenessProbe:
            httpGet:
              # Cloudflared has a /ready endpoint which returns 200 if and only if
              # it has an active connection to the edge.
              path: /ready
              port: 2000
            failureThreshold: 1
            initialDelaySeconds: 10
            periodSeconds: 10
      volumes:
        - name: creds
          secret:
            secretName: tunnel-credentials
        - name: config
          configMap:
            name: cloudflared
            items:
              - key: config.yaml
                path: config.yaml

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflared
  namespace: cloudflare
data:
  config.yaml: |
    tunnel: homelab
    credentials-file: /etc/cloudflared/creds/credentials.json
    metrics: 0.0.0.0:2000
    no-autoupdate: true
    ingress:
      - hostname: argocd.amrap030-homelab.ml
        service: https://argocd-server.argocd
        originRequest:
          noTLSVerify: true
      - service: http_status:404
```

> Make sure to set `noTLSVerify` to `true` and route the traffic to the correct namespace by specifying `service: <protocol>://<kubernetes-svc>.<namespace>`
