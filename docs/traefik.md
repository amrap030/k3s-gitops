# Self-signed Certificate

In order to use HTTPS locally, we can create self-signed certificates for traefik and use cert-manager to renew the certificate.

# Pre-requisites

As a pre-requisite, we first need to deploy traefik and cert-manager via helm.

```
helm install traefik traefik/traefik --values values.yaml --namespace traefik --create-namespace
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.12.2 --create-namespace
```

# Setup

In the first step, it is necessary to create a new RSA private key.

```
openssl genrsa -out ca.key 4096
```

Then, we need to create a certificate signing request (CSR) by running the following.

```
openssl req -x509 -new -nodes -key ca.key -sha256 -days 10950 -out ca.crt -extensions v3_ca -config openssl-with-ca.cnf
```

Notice, that the command uses an extension with `-extensions v3_ca -config openssl-with-ca.cnf`. This is a modification of the default openssl config found in `/etc/ssl/openssl.cnf`. To keep the default config safe, we copy the config via `cp /etc/ssl/openssl.cnf openssl-with-ca.cnf` and add the folloing entry to the end of the file.

```
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
```

After this, we can create the CSR. This creates a `ca.crt` file that can be added to the Apple KeyChain with a double click. It may be necessary to trust the root certificate by double clicking the `.crt` in the Apple KeyChain, enfold "Trust" and set the first option to "Trust always". To create a wildcard certificate, the following values can be set.

```
Country Name (2 letter code) []:DE
State or Province Name (full name) []:Berlin
Locality Name (eg, city) []:Berlin
Organization Name (eg, company) []:
Organizational Unit Name (eg, section) []:
Common Name (eg, fully qualified host name) []:*.amrap030.home
Email Address []:kevin.hertwig@gmail.com
```

Next, we need to apply a secret to the K8S cluster which contains the key and the root certificate from a file `ca-secret.yaml`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: traefik-ca-secret
  namespace: cert-manager
type: Opaque
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUdRVENDQkNtZ0F3SUJBZ0lKQU5kdHlycU5SM0MxTUEwR0NTcUdTSWIzRFFFQkN3VUFNSEV4Q3pBSkJnTlYKQkFZVEFrUkZNUTh3RFFZRFZRUUlEQVpDWlhKc2FXNHhEekFOQmdOVkJBY01Ca0psY214cGJqRVlNQllHQTFVRQpBd3dQS2k1aGJYSmhjREF6TUM1b2IyMWxNU1l3SkFZSktvWklodmNOQVFrQkZoZHJaWFpwYmk1b1pYSjBkMmxuClFHZHRZV2xzTG1OdmJUQWdGdzB5TXpBM01UVXlNVFUwTXpKYUdBOHlNRFV6TURjd056SXhOVFF6TWxvd2NURUwKTUFrR0ExVUVCaE1DUkVVeER6QU5CZ05WQkFnTUJrSmxjbXhwYmpFUE1BMEdBMVVFQnd3R1FtVnliR2x1TVJndwpGZ1lEVlFRRERBOHFMbUZ0Y21Gd01ETXdMbWh2YldVeEpqQWtCZ2txaGtpRzl3MEJDUUVXRjJ0bGRtbHVMbWhsCmNuUjNhV2RBWjIxaGFXd3VZMjl0TUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUEKMnlmdWZEODhiV1cwb2NtdzEwb0pNbzg3NXBvWXRmajBLRWo3R1RVMnJCdE9mRUVTVEJyOHdUZWdLc25ZMUZ4ZApXM0U1bTdCWktNUHVmV0RNZkNBTEQrL1VLWnhZVzQrVTc4ZXd4OGt3aHZGTWFPd0xYOG40Ni9FOUVKWVVreU44CmNSbmFEQUdSRlZRcEtxc1ZEcDlPNkRxWTM1QllJdVBVQnp6Qyt4ZVczZTN3RTRoK2puMFlXajFrK3dNdzF5RVUKNDU3Um9Lb3V2RFlUVXl0cmdQL1JFVVk5L0FObnk4THNYb0o0bzBmelViYi94SWlBSXU1Z1pqTVgwcTJPZ1N0RApUVTZ2Sy9tSHE0ajN5Ylk5ZE1FYzMzUkN0NCtsWHVCNTNlQTA5Ni9PcGU5bDJVazBDT1ViUk5HMWJGL2tyajFxCjJsdmEvM281YzV2QzBSSU5wbU4yMmhYQTJidmZiVGJudlZydnZmaXZrSHd6dE81cERrRGJOQUNtOWtqSi9CTHMKOVd0TWs5ZUZXU1lnbG1oMlFxeFBPa2lKY0NBVE1CMlBQMlI0TlpRWU5LeHlGR1FQMGVXcVVvUklJVEs4UFhKRgp5clNmSTZYd1htb1RDV3YyR3ZJK04xQjdsRERFTGdBRXo4QnIxYkRveThLbUlTbUdZZkZjYnBqY1VyTjhRSWxHCm5OU3h5QkoxeEtKRkZZWktveEhvaEprbEZkZDR3NU5OOFA0RDJ5bjNzc0hjK2tLU1VnbEE4Z3BDVE9GSlBBWmcKMkVPS3Jud3lMbHNNbWRyaXZoUDR6elc2TGhnQWtqbWFyRVZXZU81d21xZ3BqWlRjVWxKNTU5VklSalFQOGlzSwpGYkl5czVrN05tNDFjRVBxRnREWExsT2FUM3p6OW4wRDB4UDZubFVvQTVrQ0F3RUFBYU9CMlRDQjFqQVBCZ05WCkhSTUJBZjhFQlRBREFRSC9NQjBHQTFVZERnUVdCQlJkeFpIU0I1WUMzRXFlWjNreFlvb2pzcjdxZURDQm93WUQKVlIwakJJR2JNSUdZZ0JSZHhaSFNCNVlDM0VxZVoza3hZb29qc3I3cWVLRjFwSE13Y1RFTE1Ba0dBMVVFQmhNQwpSRVV4RHpBTkJnTlZCQWdNQmtKbGNteHBiakVQTUEwR0ExVUVCd3dHUW1WeWJHbHVNUmd3RmdZRFZRUUREQThxCkxtRnRjbUZ3TURNd0xtaHZiV1V4SmpBa0Jna3Foa2lHOXcwQkNRRVdGMnRsZG1sdUxtaGxjblIzYVdkQVoyMWgKYVd3dVkyOXRnZ2tBMTIzS3VvMUhjTFV3RFFZSktvWklodmNOQVFFTEJRQURnZ0lCQUdJMUEwbkgxcjREaTFqagppZWlNellpMVV3cnl1UVlrd21sbm9jSlp2OEo0VUw5U3M2MXdhZUNFZ0xLRStnRzdGY28zVFZST3AxTWErT2MrCnVpaWtKdGpORm5uZytCanEzbHpVa3pVWFRMZjZ0cmh0SUFPSEU5N1lOdjRVaFhuWWZBak9JNmRhYzdSSlBoUk0Kc255QkJudnRnTzh3dmFIb0JhZlJGajhKYUI3L3hjcmNhWVYwdEhZbjZRV2hXd01OY1JwOTlOSDZnRnlTZVVaaApQcDhqNGpReVBzc1pZRUp4WmpHaFd2VUEyVHNBMjFxYjlFMDNxcDRmZlY0c3paV0tJd0IrdzJEZGt0aUk1QTl0CjRkRFh0Sy9XNHNnTEVaZlBTaTdJREd1S2pTMy9LNFlkM1l3Mm9RNmlGOHI5U0ovUWs0V0tZQng5SmV6TU5Tbk8KcmtJNnRDQkgrb0RDellFMTlhall0YnpWUVF3WDNqdjd1Qk0ybjdlUXVxK0ZIbDJYUkNVTzNMNWlNeWxjTFF1aQpOcUdzQ0d2ZEJhUS9nYzFST2pUd2tnWHRqUmIwRVZqZkdxdm1qS0gySThGT0daNGc4d1d1dGdRNjdoQTFlQlE2CjN3Qmsyak1NS25ranZQMmVjd0lQdERldm1nSUxsa3oyOE5UcFdZcm9GUnlLcERSNE9hOU4wcFNIcThyaWR3VzAKVENTSlN0dTd6WjVjMk5JT3VxSmhsOTNJOEl4aGluTkRkdXNoME4rTXU1NnYyQXcyN0VUM21LVXo5NWd6VTFFbApHNUxaYjU2WThWSTNabG5CeEh5NkdwNjRxMklTUUJIaHhMc3lYL000K01odVVWdCt0UXdBNUhkcjN2WHdYSmdZClFGbUlxQk90b1hjd2EwSW12S0VMVW9IWm9rQ04KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlKS2dJQkFBS0NBZ0VBMnlmdWZEODhiV1cwb2NtdzEwb0pNbzg3NXBvWXRmajBLRWo3R1RVMnJCdE9mRUVTClRCcjh3VGVnS3NuWTFGeGRXM0U1bTdCWktNUHVmV0RNZkNBTEQrL1VLWnhZVzQrVTc4ZXd4OGt3aHZGTWFPd0wKWDhuNDYvRTlFSllVa3lOOGNSbmFEQUdSRlZRcEtxc1ZEcDlPNkRxWTM1QllJdVBVQnp6Qyt4ZVczZTN3RTRoKwpqbjBZV2oxayt3TXcxeUVVNDU3Um9Lb3V2RFlUVXl0cmdQL1JFVVk5L0FObnk4THNYb0o0bzBmelViYi94SWlBCkl1NWdaak1YMHEyT2dTdERUVTZ2Sy9tSHE0ajN5Ylk5ZE1FYzMzUkN0NCtsWHVCNTNlQTA5Ni9PcGU5bDJVazAKQ09VYlJORzFiRi9rcmoxcTJsdmEvM281YzV2QzBSSU5wbU4yMmhYQTJidmZiVGJudlZydnZmaXZrSHd6dE81cApEa0RiTkFDbTlrakovQkxzOVd0TWs5ZUZXU1lnbG1oMlFxeFBPa2lKY0NBVE1CMlBQMlI0TlpRWU5LeHlGR1FQCjBlV3FVb1JJSVRLOFBYSkZ5clNmSTZYd1htb1RDV3YyR3ZJK04xQjdsRERFTGdBRXo4QnIxYkRveThLbUlTbUcKWWZGY2JwamNVck44UUlsR25OU3h5QkoxeEtKRkZZWktveEhvaEprbEZkZDR3NU5OOFA0RDJ5bjNzc0hjK2tLUwpVZ2xBOGdwQ1RPRkpQQVpnMkVPS3Jud3lMbHNNbWRyaXZoUDR6elc2TGhnQWtqbWFyRVZXZU81d21xZ3BqWlRjClVsSjU1OVZJUmpRUDhpc0tGYkl5czVrN05tNDFjRVBxRnREWExsT2FUM3p6OW4wRDB4UDZubFVvQTVrQ0F3RUEKQVFLQ0FnRUF3a1E5WlNudytOQ0ZORDFEWXpRZnZ3KzArNDl4aEMxdzBSMFFhS0lCR3NNQjZhY00veVdWRS9tcApJd1RXRGpqcUVKcm5oQmpvai9oT3VobEthbVZGS1JWaExwbUd3WE1maFFXd3NRaW8yWldnTkFtNWMybm9HODQyCllUT0lmWDJoVytpY25yUHMxY2xLektYbS9wVTlMeUp5VFFyNDljU2JPT2NsdDhxTFU2TU5nMk1sUEUycmZxS1oKbHVDWE5Md0FkbDFjV1YxQ0hGaWEvTWlxZlNsSFBGYlZyMFdkaHNQOUh6SHNtbUMzVWFJMFN4VHM4UW41cmQ1dwpxYkpyZGhqUmlmL0x5K0ZmNERDRDVleUR3YkZGVk5jTUpRZFNnaTNlR1U0YjVjdVVGUWVIY3ZzdkF3dUVCcGNXCmlVRGZ4NHh0NGE0M0RPeGRiUnVQc0NDZXRQWEtiWmJEMDVVQldzUWZham5qL3d1TElkODkwYkt4VmwraC9lMXgKWUNDZ281SFZpbUVpZzdCL3BPSEVTOU5MSW5NODRVVUtHam84b2JlMFVLZUF2Y3AzN2xKNGczYkQ3dlBiZWp0ZgpVZWMzY0Fjbm1ZS29Md0NsaGdxODk2dHd0bzg5WEw2cnhSZmk1WHZSTVJkQ25iakxXcFZFRnRnVm1VNW5zcFROClVrdWNscm5qVlpXOFJpQy80MGNuZzE5Y3QwUk0rSmY1dEFmaW9lZlRlcGF5bXBnQ0VYR2lBNkh3MXhVRXpuSkkKcTdGNklhTlUzN29aN0ZJcUViYUd6R3JCNWNaMlpLQ003UFhHeU1hRVFTejBOUWZmdmRFUHExM2hHVWwrY0pFdwpDdFZFZDFDZWZJNlE1bnA1ZStpcGxBK1dVMWxEbVlTb2N5UkIyVTU3dmErc0RGR2pHQUVDZ2dFQkFQdzlNZGM0CmdZWnB3NDFTbmNBOSsvVG1CUlNpMlE4VjJRZVEranpjb2VVeGdKaG01U1NKWVZwREV3RWZIWElxdHV5cHV0TWYKTVhDQ0F0SzF0N200c0FLVitDYllxOGRrQVhUSFJNbVMraEtrb2pnYWZiVnU3Nms3T0dkYnArM2VTWmZYL0daeApqV0VRTE5KaTB4WUczRkErY05uMCtxOG9CTVVQU1BqMmh4UTA3cVJXWndMb0FIeTFVM1lyNmUwVjdNWEdLSzg5CkF6L1ZKbGYyRU0vQVgwYTFSNFMwdDA1YWRaWFgvM2V4czJiU1hYZlFndmlBRDFJSUpkTlZaMjM4RVkwcVNicXQKaU5Sd2NiN3dYYWRWOWlNL21xSW45bU9oWkpWQkVsdmhNTUlrSVRNWXh0WkVZdzlwOTR4RHJLQ1REUmVBSG5UYwp1Z2ZTaHJFdlhBdC9EQmtDZ2dFQkFONXNkU3RBVTNXbEZuTVFucnpLMFVTbVdubFZvN3hDOUtjdG1PZmVXZVQvCi94ZStKckFVTEFrUFJtWlpYaFNCQStzNzJzRnhqS0ZmdWo5MGVIWjNmS2FFRU5IOGs3SHB5UThKeWFMV25ZZngKZGtmQkYyRnlITEVFeWZsdlo3VzNZaERGRVIva0kwaW5IRkovMDZpOXU2ZytGdVdhaTZHUGJJeG5vSmN4MndacQo4K042cUh6eHhVZHZ1Q2xwN3VSRjREMkxHVUIrVmpHNmVhNFlYRmVSdDc0Vjd3OWkrTHUvTlNaN3JHdFI4cCtMCnBWd1pkMk5GR2VsOWJlVzc3Rmw4c0FVbDFiMTh5R3J6Wk1NSFBYL2J2QkxZZGlkWUpqSVhxeVpLWlNHcGgvTjQKZjFxdjVXNkJwcStxL2NqSUN0QVMxV1VwNDQ4L1NTWEE3OVRKVWU3SG80RUNnZ0VBQmloNFR3alNJTFgwVUQ3MApHdjFvYVZJMFRZeXNQL0lJbW1hdnRVeXRweXJPT09wS0xkb3N4a2RjNzJvVERmWjlBTW9rQllOOWNZRzdEK25mCjBtanY0eUJHTHF5YmhRS3NCbTNYQUJUV2hoMysxOS9Oc2VCRGVaNDRnazE2akJRaE45UE9GYkl3QVc2anFYOUEKS0FtQzEzS3V6cU5zZTFvK3c1RGI5emdObERDMm9zeDVOMWp5cWhqRE1OOWhscWd5WDZHMjNKQmd3KzR3UVhXQQpjNUgrd1hzcmc5SGxwOFFObXRyckljRDA0RTNDZW1wY3lEUllLMmlIZytGUjVSMkNVQy80SE5hZndJLytOdXNuClhpNTdFK0U1cFR2VWlCb29tbnc4Tm9JSTdyUnpHd3cvem50Yzc4Tm1oOFlmTU14bVJXeWJVYjhSeTU4WUtyczkKUkFxV0FRS0NBUUVBcjFBOWFrSGhockVBNk9FSXZUWC9qR1N5bTBCdE5rNXdGL1ZRdURJQ0dRWE9ReUNWemVPWQpjZXVnU2J2Vzg4SmRIR1NwSUNBb0FHbzdteGhxZXJYamdqeEdKYjAzak53QXBlSEpGSmlrd2lvSVdMWlJmM1U2Ck9DeldKYzB4cVlGSnduNFI2VmtnbG50aFQ0V0JoMWRGT203MkRUT3JLMFNwQW1JTHFpQ1p5bzB5ZnZLSEt6UkYKa3ZEejczQ1g0MFZRWWpIcFRYUkc3QnRYSFdvR0h0KzBQQmQ5dmxyOFFyK0xYVEhOelNsaVcyN3VmNUZ6RU1PKwprTk5VYytlVGUxVlVTRHB5SmxEY2g3QWdrN2g1T1BZeFg0bE9WK1NhOXBEQlRnVUZnV3JteFhrTXFLWkw2TFk0CmMrNEs2dDhCNXM5eGM3TjRzY2ZvRitIako0MG5EMVk4QVFLQ0FRRUF6ZGRVYkVWYVBIV29kK2NPRkR1RWlVRlAKLzJWNzBRa0JHaHl1VTk2RzJLODdya1lncEpmNjBmZlhUaGgzd2ljUlJTVnlkMGVnckxEaXJ0Y0FNN1JZRUZFeApFM0hQZHZxRkdLU01VUkFuTTZGUmlkd0QxdkRsRVpRUk9NZnFtejBsT295Wm1uLytxbXptM0lacEMrZndKaDBBCkhaakFPRnVJQllxWHFKSUxRL3hEL0Vndm9CNXh0VDB4Zzk3bWpKNzcwZ203L0IrYWpqVDNXMW9GeEtwOHNjT2wKMVdUQ0VFa2tXRm9QVWNkY0pQYng2eUxrQ3ZmN0xRUHFyY1Y0ampRM3RseFhTV1pPcS95ZTBCWFRxMmJIckE5cgpGUmM0cGhPQVc0Y0k1aEFVVm84WmtPc0dUMVBGejloU293OGpzTTV2djE2R1MrUHpESzg3UGJTYmdmKzYvQT09Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
```

> The `tls.crt` and `tls.key` values need to be the base64 encoded values, created by running `cat ca.crt | base64` for example. It is also best to encrypt the secret with [sops](./sops.md)!

Then we need to add a cluster issuer `cluster-issuer.yaml` with the following content.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: traefik-ca-issuer
spec:
  ca:
    secretName: traefik-ca-secret
```

Next, we need to create the certificate by applying `cert.yaml`.

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: traefik-cert
  namespace: argocd
spec:
  secretName: traefik-cert
  dnsNames:
    - "*.amrap030.home"
  issuerRef:
    name: traefik-ca-issuer
    kind: ClusterIssuer
```

The last step is to create an ingress object for each service we want to expose. For example, if we want to expose ArgoCD, the following `ingress.yaml` object needs to be applied.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: traefik-ca-issuer
    traefik.ingress.kubernetes.io/router.entrypoints: web, websecure
  name: argocd-ingress
  namespace: argocd
spec:
  rules:
    - host: argocd.amrap030.home
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
    - host: argocd.amrap030-homelab.ml
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
  tls:
    - hosts:
        - argocd.amrap030.home
      secretName: traefik-cert
```
