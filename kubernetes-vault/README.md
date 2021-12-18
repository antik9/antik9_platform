### Kubernetes Vault

**Deploy consul and vault through helm**

```bash
$ helm status vault

NAME: vault
LAST DEPLOYED: Sat Dec 18 04:15:43 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
...
```

**After keys unsealing:**

```bash
$ kubectl exec -it vault-2 -- vault status

Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.9.0
Storage Type           consul
Cluster Name           vault-cluster-7aa9edca
Cluster ID             1a827406-ba42-6384-dca9-bab208edcc8d
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.112.138.6:8200
```

**Vault login:**

```bash
$ kubectl exec -it vault-0 -- vault login

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.kHba4cMvQlsoExSujo7NcLZ5
token_accessor       DYnU1RnjjLO1Lsj4yRgojaa3
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]

$ kubectl exec -it vault-0 -- vault auth list

Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_80d10212    token based credentials
```

**Add some secrets to Vault:**

```bash
$ kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
$ kubectl exec -it vault-0 -- vault secrets list --detailed

Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_28043838    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           d8380c5e-7455-d145-b2f6-7c68d1e1b338
identity/     identity     identity_05230a19     system         system     false             replicated     false        false                      map[]      identity store                                             798f8074-a984-5513-d519-5b561daa8733
otus/         kv           kv_34113ac4           system         system     false             replicated     false        false                      map[]      n/a                                                        934f6fcb-2384-6335-3d72-80aacb09825d
sys/          system       system_1444145d       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    0d32f92c-f21e-347f-356a-fbe8d379c79d

$ kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asahskjkahs'
$ kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asahskjkahs'
$ kubectl exec -it vault-0 -- vault read otus/otus-ro/config

Key                 Value
---                 -----
refresh_interval    768h
password            asahskjkahs
username            otus

$ kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config

Key                 Value
---                 -----
refresh_interval    768h
password            asahskjkahs
username            otus
```

**Add kubernetes authorization:**

```bash
$ kubectl exec -it vault-0 -- vault auth enable kubernetes
$ kubectl exec -it vault-0 -- vault auth list

Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_2cf23faa    n/a
token/         token         auth_token_80d10212         token based credentials
```

**Vault role with update policy:**

```hcl
path "otus/otus-ro/*" {
    capabilities = ["read", "list"]
}

path "otus/otus-rw/*" {
    capabilities = ["read", "update", "create", "list"]
}
```

**NGINX html file after applying vault init container:**

```html
<html>
  <body>
    <p>Some secrets:</p>
    <ul>
      <li><pre>username: otus</pre></li>
      <li><pre>password: asahskjkahs</pre></li>
    </ul>
  </body>
</html>
```

**Issue and revoke certificate for gitlab.devlab.ru:**

```bash
$ kubectl exec -it vault-0 -- vault write pki_int/issue/devlab-dot-ru \
	common_name="gitlab.devlab.ru" ttl="24h"

Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUMDNAIH/PDeefqfbSCxHtnRuHG9MwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMTEyMTgwMjQxMjFaFw0yNjEy
MTcwMjQxNTFaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALqGITKhT8px
0L0s3Wmy7H8a0m3IZiDnM0/7ass7it7rnzAlVjRbpKThJ9HSZSR/xTzbK05Z2VoM
zdnBDq0HxjhitU7Xbx4AUAdF8fDcnn+79L6W3UORxa+nNUxyAUx/5pKXYenSaITb
oNJZMAM0JuukIkqMzNWgPEfN+fpb9drhh6o/HPI8F6CBr/C7ly7y4FGAzrVsudwc
motqpo4tC5SMnK0zsqQ+4XvNCvkhQBfnOxkYXBC0IjNC5YSnKpW8vvRQgTveAkT8
tox5eAIiBXqLuYvlQkcF+ZEQ7SYGP59vXyFcMzjdlG8gBvsqSHS8u6lzB4TlyU6t
i48Bi0J2xJ8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUEeUAC/skH+8xfib6S5qHEwa+ICYwHwYDVR0jBBgwFoAU
mChAcQ102X4h7rsQFNX1VC/EjcMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
dhv5VinmjCg9Bom2+IQdy/IM7CoIF0jq31BMbZlfEcyVBvDNGp73Lt5iMxcZuuFY
+g4uaI82ZZT1wvHSZF7B1CIeE9jkpxB3h4RWMU5x3ATrNLaFjlorxnpXyo9+iOBR
wrqhvogpHBB+mhkz6HXFTtrhHDob4JwEP7c4RY6qgKrE/hoj+HPLHPKOAUDRRW0o
jIklZh0AQi+PcWLPbA6/XF11+B5c/DmvljSDserzplqWTG4a5+thqyslcUdqg1Hq
kLBYDS3MgqWGubXWD7a0tjgcTGntyDaUGJeh3c4ycIAylKDx+zFZzdoNQQXgsqRy
5XJQ/4aK0vtFuytNooDgow==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZTCCAk2gAwIBAgIUXJWlCyyvKqbucTU6UiXM4dN0kUowDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIxMTIxODAyNTk0MVoXDTIxMTIxOTAzMDAxMVowGzEZMBcGA1UEAxMQZ2l0
bGFiLmRldmxhYi5ydTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANfE
bUDCKc0HBbI5uef6kiMeETSk2tBXWY50G4LW+eQy3KNEODuOX4MT4s3xLTmTskSr
oVy8Iynk1ChURcJf+sWoULuGVANvAPuyb8OJGUL5K+aMbyc4HtIdVieDnMbf9bFN
6Vznq+vIPwtXZCJEkuVsUvtFlgW8ckXv5RjVoyMtSnqMqfV637WQ50vX9/Rg0pHv
rrfsGrPClj2aw+XlCY4ZS6xdK48IkFH6TY6e6QLihjrU6+hHIO+xElmoux9kyirK
kcOH3Gn+G+yV6VpjHEd7WpKS8j11pm9PC5JgC/g7JXxqURnoKQpjJd7VBWx9+5kE
5QxNgiNZyqVJfCPDYekCAwEAAaOBjzCBjDAOBgNVHQ8BAf8EBAMCA6gwHQYDVR0l
BBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMB0GA1UdDgQWBBRjIllykH4/YigAVRz0
N21XM5msAzAfBgNVHSMEGDAWgBQR5QAL+yQf7zF+JvpLmocTBr4gJjAbBgNVHREE
FDASghBnaXRsYWIuZGV2bGFiLnJ1MA0GCSqGSIb3DQEBCwUAA4IBAQBOocwOkGr3
V0TOWKDtmMSQOj+OVI4hEyL+MUMhthbCfS+CVaQly2AUB1SiE+mtGUkCESBApvW3
Nnr1GQ1A89s8fFJbzsabFcLJZBpAykeBQ+MZQF2AK+WDz4y2TuG95Tw6qbQIyfU4
ggvhitHfaOz0+1cl4fcNgGqPgeNv0SUA67bUhdDtf/uakb3sExs5DQ4/NPiPkYEY
Z8dHFdV5x9iCHs4tBbOdLHDnieqOgY2WEyStDuq+nDqwAyG0vJ34puPFZSpUPmhk
0xhZQ5/yaLH/fEM59mlnC2w7EsaqpWk+AU7o10XG3Xegz7SVFky+lytkesnsmqUF
L9NYxKSbYNY2
-----END CERTIFICATE-----
expiration          1639882811
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUMDNAIH/PDeefqfbSCxHtnRuHG9MwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhtYXBsZS5ydTAeFw0yMTEyMTgwMjQxMjFaFw0yNjEy
MTcwMjQxNTFaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALqGITKhT8px
0L0s3Wmy7H8a0m3IZiDnM0/7ass7it7rnzAlVjRbpKThJ9HSZSR/xTzbK05Z2VoM
zdnBDq0HxjhitU7Xbx4AUAdF8fDcnn+79L6W3UORxa+nNUxyAUx/5pKXYenSaITb
oNJZMAM0JuukIkqMzNWgPEfN+fpb9drhh6o/HPI8F6CBr/C7ly7y4FGAzrVsudwc
motqpo4tC5SMnK0zsqQ+4XvNCvkhQBfnOxkYXBC0IjNC5YSnKpW8vvRQgTveAkT8
tox5eAIiBXqLuYvlQkcF+ZEQ7SYGP59vXyFcMzjdlG8gBvsqSHS8u6lzB4TlyU6t
i48Bi0J2xJ8CAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUEeUAC/skH+8xfib6S5qHEwa+ICYwHwYDVR0jBBgwFoAU
mChAcQ102X4h7rsQFNX1VC/EjcMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
dhv5VinmjCg9Bom2+IQdy/IM7CoIF0jq31BMbZlfEcyVBvDNGp73Lt5iMxcZuuFY
+g4uaI82ZZT1wvHSZF7B1CIeE9jkpxB3h4RWMU5x3ATrNLaFjlorxnpXyo9+iOBR
wrqhvogpHBB+mhkz6HXFTtrhHDob4JwEP7c4RY6qgKrE/hoj+HPLHPKOAUDRRW0o
jIklZh0AQi+PcWLPbA6/XF11+B5c/DmvljSDserzplqWTG4a5+thqyslcUdqg1Hq
kLBYDS3MgqWGubXWD7a0tjgcTGntyDaUGJeh3c4ycIAylKDx+zFZzdoNQQXgsqRy
5XJQ/4aK0vtFuytNooDgow==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA18RtQMIpzQcFsjm55/qSIx4RNKTa0FdZjnQbgtb55DLco0Q4
O45fgxPizfEtOZOyRKuhXLwjKeTUKFRFwl/6xahQu4ZUA28A+7Jvw4kZQvkr5oxv
Jzge0h1WJ4Ocxt/1sU3pXOer68g/C1dkIkSS5WxS+0WWBbxyRe/lGNWjIy1Keoyp
9XrftZDnS9f39GDSke+ut+was8KWPZrD5eUJjhlLrF0rjwiQUfpNjp7pAuKGOtTr
6Ecg77ESWai7H2TKKsqRw4fcaf4b7JXpWmMcR3takpLyPXWmb08LkmAL+DslfGpR
GegpCmMl3tUFbH37mQTlDE2CI1nKpUl8I8Nh6QIDAQABAoIBAQCo7YLUBrAPc4YE
Kanhc45irDGwU7l1EE5vd3vqjkELZr7TnJ+iES+6QiF6N26++2HA3dbx8eJd9Gge
QwxyyA5gHg1HJD42ifvtE6DpKDd89fRnBmAoBooq2wkO2r4t/j4v2N3x/PffG+Iw
EPW21pVjxdGaJLr2NroJA28MaIbXDDeIagTkzZUJSkBv+N6zc2nGBvw2J6s98zTy
dHE7zeRYgv2dFyEmgCH4mI0VCNbEXdODikqLsgphVoMe8K/ouwNk1r5dfv/OcDcO
5LRnFx+KXJAKn/x41Qj6jVS1yRJUQwM8NG9EQRB6kQ1N5pjhjGq9lPkfUqlIJ5EQ
VX0239nhAoGBANno36F0g3rmj2OkvMBjoc98nmoQob3tiXVXzKlF9HAvMT2U02PU
tpyLIXNzlAdT3OCixV65jABqzwyqo2WK9V4DWEavdZW0WH0qoKf/oMFGaxhhCW6W
gX+Xm6vHgbEZoTbG00o3gzqEXOzAs0O/kuTxq5l2OgokbXedNy71SFZdAoGBAP17
r3YiVlm/fihoXVTmmeK8Tg3LrtHQlCN0MTZvDJuxl5ZZSxBQT7wSobO6617J84Qy
60TeM3fVp6fCGc5ab2v+w1+A2dIsONs44jrMtO5hTmSfo/ZDB+Z2hJahCh7P2KZ1
XpxZi+8sifXyfwCW7ddUax0LdHeh6zDQxwuhbaj9AoGAPrB2FZbVdHf77GiqPJbt
KCnr0Quz3FYH45A8ur37UoLhIZw9LE03s9V67CHmBi2kL6PkMBolIsGXi0dT9pSB
fmhr7vnvVAAsLOYkjfBGqRO/H6Za9kuqObC+Ai9FKlP7Qyz0ADf0MtN9gEb3y5fD
hMXZ3i5bCCvuqii6hXHfO6kCgYEA4Zay6ArVGJhgmWuQLF/x8iStvn9X/SiIvijJ
J22bJfDePJMJR+KBo5pdSIwAruJCE5QRZ7/sxChkRdtrhgdcBBu+Gn+c2vw6OXed
dsD6APCeiNS+Ygrzu/ocM8XsMNG/OR1ZbwIOlHPp7/W5a3fnAe0CSt4H7/QtUMtt
aX9oDa0CgYBELi31wW5GLkvQejnmfuFPUp/WgmAsu0cev+eN+64qZa7eNPjwXgwG
+to8ESP2a0tygFAZoX5PNSuf4HWJrRmVnT5muS/GFQUbJrV4WIKVd53dgB1loG3v
M2/CQ2Q5ILBmj6OvVnjdFdyidNYP1EuFoY3/8bE4AM/PmeFga5RJpg==
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       5c:95:a5:0b:2c:af:2a:a6:ee:71:35:3a:52:25:cc:e1:d3:74:91:4a

$ kubectl exec -it vault-0 -- vault write pki_int/revoke \
    serial_number=5c:95:a5:0b:2c:af:2a:a6:ee:71:35:3a:52:25:cc:e1:d3:74:91:4a

Key                        Value
---                        -----
revocation_time            1639796546
revocation_time_rfc3339    2021-12-18T03:02:26.423070616Z

```
